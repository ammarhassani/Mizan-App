//
//  AIContextBuilder.swift
//  Mizan
//
//  Builds context from app state for AI consumption
//

import Foundation
import SwiftData
import os.log

// MARK: - AI Context Builder

@MainActor
final class AIContextBuilder {
    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let prayerTimeService: PrayerTimeService
    private let userSettings: UserSettings

    private let logger = Logger(subsystem: "com.mizanapp.mizan", category: "AIContextBuilder")

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        prayerTimeService: PrayerTimeService,
        userSettings: UserSettings
    ) {
        self.modelContext = modelContext
        self.prayerTimeService = prayerTimeService
        self.userSettings = userSettings
    }

    // MARK: - Build Context

    /// Build complete context for AI consumption
    func buildContext(for date: Date = Date()) async throws -> AIContext {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // Fetch tasks
        let allTasks = try fetchAllTasks()
        let todayTasks = filterTasks(allTasks, for: today)
        let tomorrowTasks = filterTasks(allTasks, for: tomorrow)
        let inboxTasks = allTasks.filter { $0.isInInbox && !$0.isCompleted }
        let overdueTasks = allTasks.filter { $0.isOverdue }
        let completedToday = allTasks.filter {
            $0.isCompleted && $0.completedAt != nil && calendar.isDateInToday($0.completedAt!)
        }

        // Fetch prayers
        let prayers = try await fetchPrayers(for: today)

        // Fetch nawafil if enabled
        let nawafil = userSettings.nawafilEnabled ? try fetchNawafil(for: today) : []

        // Calculate available slots
        let availableSlots = calculateAvailableSlots(
            tasks: todayTasks,
            prayers: prayers,
            date: today
        )

        // Build location info
        let location = buildLocationInfo()

        // Build user preferences
        let preferences = buildUserPreferences()

        return AIContext(
            currentDate: date,
            currentTime: Date(),
            timezone: TimeZone.current,
            location: location,
            tasks: TasksContext(
                today: todayTasks.map { convertTask($0) },
                tomorrow: tomorrowTasks.map { convertTask($0) },
                inbox: inboxTasks.map { convertTask($0) },
                overdue: overdueTasks.map { convertTask($0) },
                completed: completedToday.map { convertTask($0) }
            ),
            prayers: prayers.map { convertPrayer($0) },
            nawafil: nawafil.map { convertNawafil($0) },
            availableSlots: availableSlots,
            userPreferences: preferences
        )
    }

    /// Build context and convert to prompt string
    func buildContextPrompt(for date: Date = Date()) async throws -> String {
        let context = try await buildContext(for: date)
        return context.toPromptString()
    }

    // MARK: - Fetch Tasks

    private func fetchAllTasks() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>()
        return try modelContext.fetch(descriptor)
    }

    private func filterTasks(_ tasks: [Task], for date: Date) -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let scheduledDate = task.scheduledDate else { return false }
            return calendar.isDate(scheduledDate, inSameDayAs: date) && !task.isCompleted
        }.sorted { t1, t2 in
            guard let time1 = t1.scheduledStartTime, let time2 = t2.scheduledStartTime else {
                return false
            }
            return time1 < time2
        }
    }

    // MARK: - Fetch Prayers

    private func fetchPrayers(for date: Date) async throws -> [PrayerTime] {
        // Try to get from cache first
        let descriptor = FetchDescriptor<PrayerTime>(
            predicate: #Predicate { prayer in
                prayer.date >= date
            }
        )
        let cachedPrayers = try modelContext.fetch(descriptor)

        let calendar = Calendar.current
        let todayPrayers = cachedPrayers.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }

        if !todayPrayers.isEmpty {
            return todayPrayers.sorted { $0.adhanTime < $1.adhanTime }
        }

        // Fetch from service if not cached
        guard let lat = userSettings.lastKnownLatitude,
              let lon = userSettings.lastKnownLongitude else {
            logger.warning("No location available for prayer times")
            return []
        }

        do {
            let prayers = try await prayerTimeService.fetchPrayerTimes(
                for: date,
                latitude: lat,
                longitude: lon,
                method: userSettings.calculationMethod
            )
            return prayers.sorted { $0.adhanTime < $1.adhanTime }
        } catch {
            logger.error("Failed to fetch prayer times: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Fetch Nawafil

    private func fetchNawafil(for date: Date) throws -> [NawafilPrayer] {
        let descriptor = FetchDescriptor<NawafilPrayer>()
        let allNawafil = try modelContext.fetch(descriptor)

        let calendar = Calendar.current
        return allNawafil.filter {
            calendar.isDate($0.date, inSameDayAs: date) && !$0.isDismissed
        }
    }

    // MARK: - Calculate Available Slots

    private func calculateAvailableSlots(
        tasks: [Task],
        prayers: [PrayerTime],
        date: Date,
        futureOnly: Bool = false
    ) -> [TimeSlot] {
        var slots: [TimeSlot] = []
        let calendar = Calendar.current

        // Define day boundaries (6 AM to 11 PM)
        var dayStart = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: date)!
        let dayEnd = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: date)!

        // Only filter by current time if futureOnly is true and we're analyzing today
        let now = Date()
        if futureOnly && calendar.isDateInToday(date) && now > dayStart {
            let minute = calendar.component(.minute, from: now)
            let roundedMinute = ((minute / 15) + 1) * 15
            // Use 'date' as base, not 'now', to ensure correct day
            dayStart = calendar.date(bySettingHour: calendar.component(.hour, from: now), minute: roundedMinute % 60, second: 0, of: date)!
            if roundedMinute >= 60 {
                dayStart = calendar.date(byAdding: .hour, value: 1, to: dayStart)!
            }
        }

        // Safety check: ensure dayStart is before dayEnd
        guard dayStart < dayEnd else {
            logger.warning("calculateAvailableSlots: dayStart >= dayEnd, returning empty slots")
            return []
        }

        // Collect all blocked time ranges
        var blockedRanges: [(start: Date, end: Date)] = []

        // Add prayer times with buffers
        for prayer in prayers {
            // Cap buffer values to reasonable limits (max 30 min each)
            let bufferBefore = TimeInterval(min(prayer.bufferBefore, 30) * 60)
            let bufferAfter = TimeInterval(min(prayer.bufferAfter, 30) * 60)
            let duration = TimeInterval(prayer.duration * 60)

            let start = prayer.adhanTime.addingTimeInterval(-bufferBefore)
            let end = prayer.adhanTime.addingTimeInterval(duration + bufferAfter)

            // Only include if within day bounds
            if end > dayStart && start < dayEnd {
                blockedRanges.append((start: max(start, dayStart), end: min(end, dayEnd)))
            }
        }

        // Add task times
        for task in tasks {
            guard let startTime = task.scheduledStartTime,
                  let endTime = task.endTime else { continue }

            // Only include if within day bounds
            if endTime > dayStart && startTime < dayEnd {
                blockedRanges.append((start: max(startTime, dayStart), end: min(endTime, dayEnd)))
            }
        }

        // Sort blocked ranges by start time
        blockedRanges.sort { $0.start < $1.start }

        // Merge overlapping ranges to avoid double-counting
        var mergedRanges: [(start: Date, end: Date)] = []
        for range in blockedRanges {
            if let last = mergedRanges.last, range.start <= last.end {
                // Overlapping - extend the last range
                mergedRanges[mergedRanges.count - 1].end = max(last.end, range.end)
            } else {
                mergedRanges.append(range)
            }
        }

        // Find gaps
        var currentTime = dayStart

        for blocked in mergedRanges {
            if blocked.start > currentTime {
                // There's a gap before this blocked range
                let gap = TimeSlot(startTime: currentTime, endTime: blocked.start)
                if gap.durationMinutes >= 15 { // Minimum 15 minutes
                    slots.append(gap)
                }
            }
            // Move current time to end of blocked range
            currentTime = max(currentTime, blocked.end)
        }

        // Check for gap after last blocked range
        if currentTime < dayEnd {
            let gap = TimeSlot(startTime: currentTime, endTime: dayEnd)
            if gap.durationMinutes >= 15 {
                slots.append(gap)
            }
        }

        logger.debug("calculateAvailableSlots: found \(slots.count) slots, total \(slots.reduce(0) { $0 + $1.durationMinutes }) minutes")
        return slots
    }

    // MARK: - Conversion Helpers

    private func convertTask(_ task: Task) -> TaskContext {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ar")
        timeFormatter.dateFormat = "h:mm a"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return TaskContext(
            id: task.id.uuidString,
            title: task.title,
            duration: task.duration,
            category: task.category.rawValue,
            icon: task.icon,
            scheduledDate: task.scheduledDate.map { dateFormatter.string(from: $0) },
            scheduledTime: task.scheduledStartTime.map { timeFormatter.string(from: $0) },
            isCompleted: task.isCompleted,
            isRecurring: task.isRecurring,
            notes: task.notes
        )
    }

    private func convertPrayer(_ prayer: PrayerTime) -> PrayerContext {
        PrayerContext(
            id: prayer.id.uuidString,
            name: prayer.prayerType.rawValue,
            nameArabic: prayer.prayerType.arabicName,
            adhanTime: prayer.adhanTime,
            iqamaTime: prayer.iqamaTime,
            duration: prayer.duration,
            isPassed: prayer.adhanTime < Date()
        )
    }

    private func convertNawafil(_ nawafil: NawafilPrayer) -> NawafilContext {
        NawafilContext(
            id: nawafil.id.uuidString,
            type: nawafil.nawafilType,
            nameArabic: nawafil.arabicName,
            suggestedTime: nawafil.suggestedTime,
            duration: nawafil.duration,
            rakaat: nawafil.rakaat,
            isCompleted: nawafil.isCompleted
        )
    }

    private func buildLocationInfo() -> LocationInfo? {
        guard let lat = userSettings.lastKnownLatitude,
              let lon = userSettings.lastKnownLongitude else {
            return nil
        }
        return LocationInfo(
            latitude: lat,
            longitude: lon,
            city: userSettings.manualLocationName
        )
    }

    private func buildUserPreferences() -> UserPreferencesContext {
        UserPreferencesContext(
            language: userSettings.language.rawValue,
            isPro: userSettings.isPro,
            nawafilEnabled: userSettings.nawafilEnabled,
            enabledNawafilTypes: userSettings.enabledNawafil,
            theme: userSettings.selectedTheme,
            calculationMethod: userSettings.calculationMethod.rawValue
        )
    }
}

// MARK: - Quick Context Builder

extension AIContextBuilder {
    /// Build a minimal context for simple operations
    func buildQuickContext() async throws -> AIContext {
        try await buildContext(for: Date())
    }

    /// Get just today's tasks
    func getTodayTasks() throws -> [TaskContext] {
        let allTasks = try fetchAllTasks()
        let today = Calendar.current.startOfDay(for: Date())
        let todayTasks = filterTasks(allTasks, for: today)
        return todayTasks.map { convertTask($0) }
    }

    /// Get just inbox tasks
    func getInboxTasks() throws -> [TaskContext] {
        let allTasks = try fetchAllTasks()
        let inboxTasks = allTasks.filter { $0.isInInbox && !$0.isCompleted }
        return inboxTasks.map { convertTask($0) }
    }

    /// Find tasks matching a query with fuzzy matching
    func findTasks(matching query: TaskQuery) throws -> [TaskContext] {
        let allTasks = try fetchAllTasks()
        var filtered = allTasks

        // Filter by title with fuzzy matching
        if let titleQuery = query.titleContains?.lowercased() {
            filtered = filtered.filter { fuzzyMatch(title: $0.title, query: titleQuery) }
        }

        // Filter by date
        if let dateQuery = query.date {
            let calendar = Calendar.current
            let targetDate: Date

            switch dateQuery.lowercased() {
            case "today":
                targetDate = calendar.startOfDay(for: Date())
            case "tomorrow":
                targetDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
            default:
                // Try to parse as ISO date
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateQuery) {
                    targetDate = date
                } else {
                    targetDate = Date()
                }
            }

            filtered = filtered.filter { task in
                guard let scheduledDate = task.scheduledDate else { return false }
                return calendar.isDate(scheduledDate, inSameDayAs: targetDate)
            }
        }

        // Filter by category
        if let categoryQuery = query.category {
            filtered = filtered.filter { $0.category.rawValue == categoryQuery }
        }

        // Filter by completion status
        if let isCompleted = query.isCompleted {
            filtered = filtered.filter { $0.isCompleted == isCompleted }
        }

        // Filter by task ID
        if let taskId = query.taskId {
            filtered = filtered.filter { $0.id.uuidString == taskId }
        }

        return filtered.map { convertTask($0) }
    }

    /// Find the actual Task model by query with fuzzy matching
    func findTaskModel(matching query: TaskQuery) throws -> Task? {
        let allTasks = try fetchAllTasks()
        var filtered = allTasks

        // Apply same filters as findTasks with fuzzy matching
        if let titleQuery = query.titleContains?.lowercased() {
            filtered = filtered.filter { fuzzyMatch(title: $0.title, query: titleQuery) }
        }

        if let taskId = query.taskId {
            filtered = filtered.filter { $0.id.uuidString == taskId }
        }

        // Return first match or nil (or return nil if multiple matches for disambiguation)
        if filtered.count == 1 {
            return filtered.first
        } else if filtered.count > 1 {
            // Multiple matches - return nil to trigger disambiguation
            return nil
        }
        return nil
    }

    /// Find multiple Task models by query with fuzzy matching
    func findTaskModels(matching query: TaskQuery) throws -> [Task] {
        let allTasks = try fetchAllTasks()
        var filtered = allTasks

        if let titleQuery = query.titleContains?.lowercased() {
            filtered = filtered.filter { fuzzyMatch(title: $0.title, query: titleQuery) }
        }

        if let dateQuery = query.date {
            let calendar = Calendar.current
            let targetDate: Date

            switch dateQuery.lowercased() {
            case "today":
                targetDate = calendar.startOfDay(for: Date())
            case "tomorrow":
                targetDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
            default:
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                targetDate = formatter.date(from: dateQuery) ?? Date()
            }

            filtered = filtered.filter { task in
                guard let scheduledDate = task.scheduledDate else { return false }
                return calendar.isDate(scheduledDate, inSameDayAs: targetDate)
            }
        }

        if let categoryQuery = query.category {
            filtered = filtered.filter { $0.category.rawValue == categoryQuery }
        }

        if let isCompleted = query.isCompleted {
            filtered = filtered.filter { $0.isCompleted == isCompleted }
        }

        if let taskId = query.taskId {
            filtered = filtered.filter { $0.id.uuidString == taskId }
        }

        return filtered
    }

    // MARK: - Fuzzy Matching Helpers

    /// Fuzzy match a task title against a search query
    /// Supports: word matching, synonym matching, partial word matching
    private func fuzzyMatch(title: String, query: String) -> Bool {
        let titleLower = title.lowercased()
        let queryLower = query.lowercased()

        // Direct contains match (existing behavior)
        if titleLower.contains(queryLower) {
            return true
        }

        // Split into words
        let titleWords = titleLower.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        let queryWords = queryLower.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }

        // Check if ANY query word matches ANY title word (partial or full)
        for queryWord in queryWords {
            // Skip common words
            if isCommonWord(queryWord) { continue }

            for titleWord in titleWords {
                // Direct word match
                if titleWord.contains(queryWord) || queryWord.contains(titleWord) {
                    return true
                }

                // Synonym match
                if areSynonyms(titleWord, queryWord) {
                    return true
                }
            }
        }

        return false
    }

    /// Check if two words are synonyms (for task context)
    private func areSynonyms(_ word1: String, _ word2: String) -> Bool {
        // Synonym groups for common task-related terms
        let synonymGroups: [[String]] = [
            // Exercise/Fitness
            ["gym", "workout", "exercise", "training", "fitness", "sport", "تمارين", "رياضة", "جيم", "تمرين"],
            // Study/Learning
            ["study", "studying", "homework", "learning", "read", "reading", "دراسة", "مذاكرة", "قراءة"],
            // Work
            ["work", "job", "meeting", "office", "عمل", "اجتماع", "مكتب"],
            // Clean/Organize
            ["clean", "cleaning", "organize", "tidy", "تنظيف", "ترتيب"],
            // Shop/Buy
            ["shop", "shopping", "buy", "purchase", "store", "تسوق", "شراء"],
            // Cook/Food
            ["cook", "cooking", "food", "meal", "طبخ", "طعام", "أكل"],
            // Sleep/Rest
            ["sleep", "rest", "nap", "نوم", "راحة"],
            // Prayer/Worship
            ["prayer", "pray", "salah", "صلاة", "عبادة", "quran", "قرآن"],
            // Call/Contact
            ["call", "phone", "contact", "اتصال", "هاتف"],
            // Walk/Run
            ["walk", "walking", "run", "running", "jog", "مشي", "جري"],
        ]

        for group in synonymGroups {
            let groupLower = group.map { $0.lowercased() }
            if groupLower.contains(word1.lowercased()) && groupLower.contains(word2.lowercased()) {
                return true
            }
        }

        return false
    }

    /// Check if a word is too common to be useful for matching
    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = Set([
            "the", "a", "an", "to", "for", "of", "in", "on", "at", "is", "it", "my",
            "task", "مهمة", "do", "add", "delete", "remove", "edit", "change",
            "احذف", "أضف", "عدل", "غير"
        ])
        return commonWords.contains(word.lowercased())
    }
}
