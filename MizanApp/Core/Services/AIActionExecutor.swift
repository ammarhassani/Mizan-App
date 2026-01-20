//
//  AIActionExecutor.swift
//  Mizan
//
//  Executes AI intents against app state (SwiftData, Settings)
//

import Foundation
import SwiftData
import os.log

// MARK: - AI Action Executor

@MainActor
final class AIActionExecutor {
    private let modelContext: ModelContext
    private let userSettings: UserSettings
    private let prayerTimeService: PrayerTimeService
    private let contextBuilder: AIContextBuilder

    init(
        modelContext: ModelContext,
        userSettings: UserSettings,
        prayerTimeService: PrayerTimeService
    ) {
        self.modelContext = modelContext
        self.userSettings = userSettings
        self.prayerTimeService = prayerTimeService
        self.contextBuilder = AIContextBuilder(
            modelContext: modelContext,
            prayerTimeService: prayerTimeService,
            userSettings: userSettings
        )
    }

    // MARK: - Execute Intent

    func execute(_ intent: AIIntent) async throws -> AIActionResult {
        switch intent {
        case .createTask(let data):
            return try await executeCreateTask(data)

        case .editTask(let query, let changes):
            return try await executeEditTask(query: query, changes: changes)

        case .deleteTask(let query, let deleteAllRecurring):
            return try await executeDeleteTask(query: query, deleteAllRecurring: deleteAllRecurring)

        case .completeTask(let query):
            return try await executeCompleteTask(query: query)

        case .uncompleteTask(let query):
            return try await executeUncompleteTask(query: query)

        case .rescheduleTask(let query, let newTime):
            return try await executeRescheduleTask(query: query, newTime: newTime)

        case .moveToInbox(let query):
            return try await executeMoveToInbox(query: query)

        case .rearrangeSchedule(let date, let strategy):
            return try await executeRearrangeSchedule(date: date, strategy: strategy)

        case .queryTasks(let filter):
            return try await executeQueryTasks(filter: filter)

        case .queryPrayers(let date):
            return try await executeQueryPrayers(date: date)

        case .querySchedule(let date):
            return try await executeQuerySchedule(date: date)

        case .queryAvailableTime(let date):
            return try await executeQueryAvailableTime(date: date)

        case .analyzeSchedule(let date, let focusArea, let suggestHabits, let habitCategories):
            return try await executeAnalyzeSchedule(
                date: date,
                focusArea: focusArea,
                suggestHabits: suggestHabits,
                habitCategories: habitCategories
            )

        case .findAvailableSlot(let duration, let date, let preferredTime, let afterPrayer):
            return try await executeFindAvailableSlot(
                duration: duration,
                date: date,
                preferredTime: preferredTime,
                afterPrayer: afterPrayer
            )

        case .toggleNawafil(let type, let enabled):
            return try await executeToggleNawafil(type: type, enabled: enabled)

        case .changeSetting(let key, let value):
            return try await executeChangeSetting(key: key, value: value)

        case .clarify(let request):
            return .needsClarification(request: request)

        case .suggest(let suggestions):
            return .suggestions(suggestions)

        case .explain(let topic):
            return .explanation(topic)

        case .cannotFulfill(let reason, let alternative, let manualSteps):
            return .cannotFulfill(
                reason: reason,
                alternative: alternative,
                manualAction: manualSteps != nil ? .openTimeline : nil
            )
        }
    }

    // MARK: - Task CRUD Operations

    private func executeCreateTask(_ data: ExtractedTaskData) async throws -> AIActionResult {
        // Determine category from string
        let taskCategory: TaskCategory
        if let categoryStr = data.category?.lowercased() {
            switch categoryStr {
            case "work": taskCategory = .work
            case "personal": taskCategory = .personal
            case "study": taskCategory = .study
            case "health": taskCategory = .health
            case "social": taskCategory = .social
            case "worship": taskCategory = .worship
            default: taskCategory = .personal
            }
        } else {
            taskCategory = .personal
        }

        // Create the task
        let task = Task(
            title: data.title,
            duration: data.duration,
            category: taskCategory,
            notes: data.notes
        )

        // Handle scheduling
        if let dateStr = data.scheduledDate, let timeStr = data.scheduledTime {
            if let scheduledTime = parseDateTime(dateStr: dateStr, timeStr: timeStr) {
                // Check for prayer conflict
                let context = try await contextBuilder.buildContext(for: scheduledTime)
                if let conflict = context.checksPrayerConflict(at: scheduledTime, duration: data.duration) {
                    // Return with prayer conflict warning
                    let suggestedTime = conflict.adhanTime.addingTimeInterval(Double(conflict.duration + 15) * 60)
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "h:mm a"
                    let suggested = timeFormatter.string(from: suggestedTime)

                    return .prayerConflict(
                        prayerName: conflict.nameArabic,
                        suggestedTime: suggested,
                        pendingTask: data
                    )
                }

                task.scheduleAt(time: scheduledTime)
            }
        } else if let dateStr = data.scheduledDate {
            // Date only, no time - suggest scheduling
            let clarification = ClarificationRequest.whenToSchedule(taskTitle: data.title)
            return .needsClarification(request: clarification)
        }

        // Handle recurrence
        if let recurrence = data.recurrence {
            let frequency: RecurrenceRule.Frequency
            switch recurrence.frequency.lowercased() {
            case "daily": frequency = .daily
            case "weekly": frequency = .weekly
            case "monthly": frequency = .monthly
            default: frequency = .daily
            }

            task.recurrenceRule = RecurrenceRule(
                frequency: frequency,
                interval: recurrence.interval,
                daysOfWeek: recurrence.daysOfWeek
            )
            task.isRecurring = true
        }

        // Insert into context
        modelContext.insert(task)
        try modelContext.save()

        MizanLogger.shared.lifecycle.info("AI created task: \(task.title)")

        // Convert to TaskContext for result
        let taskContext = TaskContext(
            id: task.id.uuidString,
            title: task.title,
            duration: task.duration,
            category: task.category.rawValue,
            icon: task.icon,
            scheduledDate: formatDate(task.scheduledDate),
            scheduledTime: formatTime(task.scheduledStartTime),
            isCompleted: task.isCompleted,
            isRecurring: task.isRecurring
        )

        return .taskCreated(task: taskContext, showInTimeline: task.isScheduled)
    }

    private func executeEditTask(query: TaskQuery, changes: TaskChanges) async throws -> AIActionResult {
        guard let task = try contextBuilder.findTaskModel(matching: query) else {
            // No task found - ask for clarification
            let tasks = try contextBuilder.findTasks(matching: query)
            if tasks.isEmpty {
                throw AIActionError.taskNotFound(query: query.description)
            } else {
                throw AIActionError.multipleMatches(count: tasks.count, tasks: tasks.map { $0.toSummary() })
            }
        }

        var changesApplied: [String] = []

        // Apply changes
        if let newTitle = changes.title {
            task.updateTitle(newTitle)
            changesApplied.append("العنوان")
        }

        if let newDuration = changes.duration {
            task.updateDuration(newDuration)
            changesApplied.append("المدة")
        }

        if let newNotes = changes.notes {
            task.notes = newNotes
            task.updatedAt = Date()
            changesApplied.append("الملاحظات")
        }

        if let newCategory = changes.category {
            if let category = TaskCategory(rawValue: newCategory) {
                task.category = category
                task.colorHex = category.defaultColorHex
                task.updatedAt = Date()
                changesApplied.append("الفئة")
            }
        }

        if let dateStr = changes.scheduledDate, let timeStr = changes.scheduledTime {
            if let newTime = parseDateTime(dateStr: dateStr, timeStr: timeStr) {
                task.scheduleAt(time: newTime)
                changesApplied.append("الوقت")
            }
        } else if let timeStr = changes.scheduledTime {
            // Time only - use today or keep existing date
            let date = task.scheduledDate ?? Date()
            if let newTime = parseDateTime(dateStr: formatDate(date) ?? "today", timeStr: timeStr) {
                task.scheduleAt(time: newTime)
                changesApplied.append("الوقت")
            }
        }

        try modelContext.save()

        MizanLogger.shared.lifecycle.info("AI edited task: \(task.title), changes: \(changesApplied.joined(separator: ", "))")

        let taskContext = TaskContext(
            id: task.id.uuidString,
            title: task.title,
            duration: task.duration,
            category: task.category.rawValue,
            icon: task.icon,
            scheduledDate: formatDate(task.scheduledDate),
            scheduledTime: formatTime(task.scheduledStartTime),
            isCompleted: task.isCompleted,
            isRecurring: task.isRecurring
        )

        return .taskEdited(task: taskContext, changes: changesApplied)
    }

    private func executeDeleteTask(query: TaskQuery, deleteAllRecurring: Bool) async throws -> AIActionResult {
        guard let task = try contextBuilder.findTaskModel(matching: query) else {
            let tasks = try contextBuilder.findTasks(matching: query)
            if tasks.isEmpty {
                throw AIActionError.taskNotFound(query: query.description)
            } else {
                // Multiple matches - need clarification
                let clarification = ClarificationRequest.whichTask(
                    action: "حذف",
                    matchingTasks: tasks.map { $0.toSummary() }
                )
                return .needsClarification(request: clarification)
            }
        }

        let taskTitle = task.title
        let wasRecurring = task.isRecurring

        // Request confirmation before deletion
        let taskContext = TaskContext(
            id: task.id.uuidString,
            title: task.title,
            duration: task.duration,
            category: task.category.rawValue,
            icon: task.icon,
            scheduledDate: formatDate(task.scheduledDate),
            scheduledTime: formatTime(task.scheduledStartTime),
            isCompleted: task.isCompleted,
            isRecurring: task.isRecurring
        )

        return .confirmationRequired(action: PendingAction(
            type: .delete,
            task: taskContext,
            description: "حذف مهمة \"\(taskTitle)\"",
            confirmCallback: { [weak self] in
                guard let self = self else { return }
                self.modelContext.delete(task)
                try? self.modelContext.save()
                MizanLogger.shared.lifecycle.info("AI deleted task: \(taskTitle)")
            }
        ))
    }

    private func executeCompleteTask(query: TaskQuery) async throws -> AIActionResult {
        guard let task = try contextBuilder.findTaskModel(matching: query) else {
            let tasks = try contextBuilder.findTasks(matching: query)
            if tasks.isEmpty {
                throw AIActionError.taskNotFound(query: query.description)
            } else {
                let clarification = ClarificationRequest.whichTask(
                    action: "إكمال",
                    matchingTasks: tasks.map { $0.toSummary() }
                )
                return .needsClarification(request: clarification)
            }
        }

        if task.isCompleted {
            return .taskAlreadyCompleted(taskTitle: task.title)
        }

        task.markComplete()
        try modelContext.save()

        MizanLogger.shared.lifecycle.info("AI completed task: \(task.title)")

        let taskContext = TaskContext(
            id: task.id.uuidString,
            title: task.title,
            duration: task.duration,
            category: task.category.rawValue,
            icon: task.icon,
            scheduledDate: formatDate(task.scheduledDate),
            scheduledTime: formatTime(task.scheduledStartTime),
            isCompleted: true,
            isRecurring: task.isRecurring
        )

        return .taskCompleted(task: taskContext)
    }

    private func executeUncompleteTask(query: TaskQuery) async throws -> AIActionResult {
        guard let task = try contextBuilder.findTaskModel(matching: query) else {
            throw AIActionError.taskNotFound(query: query.description)
        }

        if !task.isCompleted {
            return .cannotFulfill(
                reason: "المهمة ليست مكتملة",
                alternative: nil,
                manualAction: nil
            )
        }

        task.unmarkComplete()
        try modelContext.save()

        MizanLogger.shared.lifecycle.info("AI uncompleted task: \(task.title)")

        let taskContext = TaskContext(
            id: task.id.uuidString,
            title: task.title,
            duration: task.duration,
            category: task.category.rawValue,
            icon: task.icon,
            scheduledDate: formatDate(task.scheduledDate),
            scheduledTime: formatTime(task.scheduledStartTime),
            isCompleted: false,
            isRecurring: task.isRecurring
        )

        return .taskUncompleted(task: taskContext)
    }

    // MARK: - Scheduling Operations

    private func executeRescheduleTask(query: TaskQuery, newTime: TimeSpec) async throws -> AIActionResult {
        guard let task = try contextBuilder.findTaskModel(matching: query) else {
            let tasks = try contextBuilder.findTasks(matching: query)
            if tasks.isEmpty {
                throw AIActionError.taskNotFound(query: query.description)
            } else {
                let clarification = ClarificationRequest.whichTask(
                    action: "نقل",
                    matchingTasks: tasks.map { $0.toSummary() }
                )
                return .needsClarification(request: clarification)
            }
        }

        // Parse the new time
        var targetTime: Date?

        if let afterPrayer = newTime.afterPrayer {
            // Schedule after a prayer
            let context = try await contextBuilder.buildContext()
            if let prayer = context.prayers.first(where: { $0.name.lowercased() == afterPrayer.lowercased() }) {
                // Schedule 15 minutes after prayer ends
                targetTime = prayer.adhanTime.addingTimeInterval(Double(prayer.duration + 15) * 60)
            }
        } else if let dateStr = newTime.date, let timeStr = newTime.time {
            targetTime = parseDateTime(dateStr: dateStr, timeStr: timeStr)
        } else if let timeStr = newTime.time {
            // Time only - use today or tomorrow if time has passed
            targetTime = parseTimeForToday(timeStr)
        } else if let relativeMinutes = newTime.relativeMinutes {
            targetTime = Date().addingTimeInterval(Double(relativeMinutes * 60))
        }

        guard let scheduledTime = targetTime else {
            // Need clarification for the new time
            let clarification = ClarificationRequest.newTime(forTask: task.title)
            return .needsClarification(request: clarification)
        }

        // Check for prayer conflict
        let context = try await contextBuilder.buildContext(for: scheduledTime)
        if let conflict = context.checksPrayerConflict(at: scheduledTime, duration: task.duration) {
            let suggestedTime = conflict.adhanTime.addingTimeInterval(Double(conflict.duration + 15) * 60)
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let suggested = timeFormatter.string(from: suggestedTime)

            return .prayerConflict(
                prayerName: conflict.nameArabic,
                suggestedTime: suggested,
                pendingTask: nil
            )
        }

        let oldTime = task.scheduledStartTime
        task.scheduleAt(time: scheduledTime)
        try modelContext.save()

        MizanLogger.shared.lifecycle.info("AI rescheduled task: \(task.title)")

        let taskContext = TaskContext(
            id: task.id.uuidString,
            title: task.title,
            duration: task.duration,
            category: task.category.rawValue,
            icon: task.icon,
            scheduledDate: formatDate(task.scheduledDate),
            scheduledTime: formatTime(task.scheduledStartTime),
            isCompleted: task.isCompleted,
            isRecurring: task.isRecurring
        )

        return .taskRescheduled(
            task: taskContext,
            oldTime: formatTime(oldTime),
            newTime: formatTime(scheduledTime)
        )
    }

    private func executeMoveToInbox(query: TaskQuery) async throws -> AIActionResult {
        guard let task = try contextBuilder.findTaskModel(matching: query) else {
            throw AIActionError.taskNotFound(query: query.description)
        }

        if task.isInInbox {
            return .cannotFulfill(
                reason: "المهمة موجودة بالفعل في صندوق الوارد",
                alternative: nil,
                manualAction: nil
            )
        }

        task.moveToInbox()
        try modelContext.save()

        MizanLogger.shared.lifecycle.info("AI moved task to inbox: \(task.title)")

        let taskContext = TaskContext(
            id: task.id.uuidString,
            title: task.title,
            duration: task.duration,
            category: task.category.rawValue,
            icon: task.icon,
            scheduledDate: nil,
            scheduledTime: nil,
            isCompleted: task.isCompleted,
            isRecurring: task.isRecurring
        )

        return .taskMovedToInbox(task: taskContext)
    }

    private func executeRearrangeSchedule(date: String, strategy: RearrangeStrategy) async throws -> AIActionResult {
        let targetDate = parseDate(date)
        let context = try await contextBuilder.buildContext(for: targetDate)

        // Get tasks for the day
        var tasksToRearrange: [Task] = []
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { task in
                task.scheduledDate != nil && !task.isCompleted
            }
        )

        let allTasks = try modelContext.fetch(descriptor)
        let calendar = Calendar.current

        for task in allTasks {
            if let scheduledDate = task.scheduledDate,
               calendar.isDate(scheduledDate, inSameDayAs: targetDate) {
                tasksToRearrange.append(task)
            }
        }

        if tasksToRearrange.isEmpty {
            return .cannotFulfill(
                reason: "لا توجد مهام مجدولة في هذا اليوم",
                alternative: "يمكنك إضافة مهام أولاً",
                manualAction: .openTimeline
            )
        }

        // Calculate new arrangement based on strategy
        var changes: [ScheduleChange] = []

        switch strategy {
        case .afterPrayer:
            changes = try await rearrangeAfterPrayers(tasks: tasksToRearrange, context: context)
        case .optimizeGaps:
            changes = try await rearrangeOptimizeGaps(tasks: tasksToRearrange, context: context)
        case .prioritizeUrgent:
            changes = try await rearrangePrioritizeUrgent(tasks: tasksToRearrange, context: context)
        case .spreadEvenly:
            changes = try await rearrangeSpreadEvenly(tasks: tasksToRearrange, context: context)
        }

        // Return confirmation required with preview
        return .scheduleRearranged(tasksAffected: changes.count, changes: changes)
    }

    // MARK: - Query Operations

    private func executeQueryTasks(filter: AITaskFilter) async throws -> AIActionResult {
        let tasks = try contextBuilder.findTasks(matching: TaskQuery(
            date: filter.date,
            category: filter.category,
            isCompleted: filter.isCompleted
        ))

        // Apply additional filters
        var filteredTasks = tasks

        if let inInbox = filter.inInbox, inInbox {
            filteredTasks = filteredTasks.filter { $0.scheduledTime == nil }
        }

        if let limit = filter.limit {
            filteredTasks = Array(filteredTasks.prefix(limit))
        }

        return .taskList(tasks: filteredTasks)
    }

    private func executeQueryPrayers(date: String?) async throws -> AIActionResult {
        let targetDate = date != nil ? parseDate(date!) : Date()
        let context = try await contextBuilder.buildContext(for: targetDate)

        return .prayerList(prayers: context.prayers)
    }

    private func executeQuerySchedule(date: String?) async throws -> AIActionResult {
        let targetDate = date != nil ? parseDate(date!) : Date()
        let context = try await contextBuilder.buildContext(for: targetDate)

        return .schedule(tasks: context.tasks.today, prayers: context.prayers)
    }

    private func executeQueryAvailableTime(date: String?) async throws -> AIActionResult {
        let targetDate = date != nil ? parseDate(date!) : Date()
        let context = try await contextBuilder.buildContext(for: targetDate)

        return .availableSlots(slots: context.availableSlots)
    }

    private func executeFindAvailableSlot(
        duration: Int,
        date: String?,
        preferredTime: TimeSpec?,
        afterPrayer: String?
    ) async throws -> AIActionResult {
        let targetDate = date != nil ? parseDate(date!) : Date()
        let context = try await contextBuilder.buildContext(for: targetDate)

        if let slot = context.findSlot(forDuration: duration, afterPrayer: afterPrayer) {
            return .slotFound(slot: slot)
        }

        return .cannotFulfill(
            reason: "لا يوجد وقت فارغ كافي لمهمة بمدة \(duration) دقيقة",
            alternative: "جرب يوم آخر أو مدة أقصر",
            manualAction: .openTimeline
        )
    }

    // MARK: - Schedule Analysis

    private func executeAnalyzeSchedule(
        date: String?,
        focusArea: String?,
        suggestHabits: Bool,
        habitCategories: [String]?
    ) async throws -> AIActionResult {
        let targetDate = date != nil ? parseDate(date!) : Date()
        let context = try await contextBuilder.buildContext(for: targetDate)

        // Convert available slots to FreeTimeSlot format
        var freeSlots: [FreeTimeSlot] = []
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for slot in context.availableSlots {
            let startTimeStr = timeFormatter.string(from: slot.startTime)
            let endTimeStr = timeFormatter.string(from: slot.endTime)
            let timeOfDay = getTimeOfDay(from: slot.startTime)

            // Find if this is after a prayer
            var afterPrayer: String? = nil
            for prayer in context.prayers {
                let prayerEnd = prayer.adhanTime.addingTimeInterval(Double(prayer.duration + 10) * 60)
                if abs(slot.startTime.timeIntervalSince(prayerEnd)) < 300 { // Within 5 min
                    afterPrayer = prayer.nameArabic
                    break
                }
            }

            // Apply focus area filter if specified
            if let focus = focusArea, focus != "all" {
                if focus != timeOfDay && focus != "after_prayers" {
                    continue
                }
                if focus == "after_prayers" && afterPrayer == nil {
                    continue
                }
            }

            freeSlots.append(FreeTimeSlot(
                startTime: startTimeStr,
                endTime: endTimeStr,
                durationMinutes: slot.durationMinutes,
                timeOfDay: timeOfDay,
                afterPrayer: afterPrayer
            ))
        }

        // Generate habit suggestions if requested
        var suggestions: [HabitSuggestion] = []
        if suggestHabits {
            suggestions = generateHabitSuggestions(
                forSlots: freeSlots,
                categories: habitCategories,
                prayers: context.prayers
            )
        }

        // Build summary
        let totalFreeMinutes = freeSlots.reduce(0) { $0 + $1.durationMinutes }
        let totalScheduledMinutes = context.tasks.today.reduce(0) { $0 + $1.duration }

        // Calculate busiest/freest periods
        let morningFree = freeSlots.filter { $0.timeOfDay == "morning" }.reduce(0) { $0 + $1.durationMinutes }
        let afternoonFree = freeSlots.filter { $0.timeOfDay == "afternoon" }.reduce(0) { $0 + $1.durationMinutes }
        let eveningFree = freeSlots.filter { $0.timeOfDay == "evening" }.reduce(0) { $0 + $1.durationMinutes }

        let freestPeriod: String?
        let busiestPeriod: String?

        let maxFree = max(morningFree, max(afternoonFree, eveningFree))
        let minFree = min(morningFree, min(afternoonFree, eveningFree))

        if maxFree == morningFree { freestPeriod = "morning" }
        else if maxFree == afternoonFree { freestPeriod = "afternoon" }
        else { freestPeriod = "evening" }

        if minFree == morningFree { busiestPeriod = "morning" }
        else if minFree == afternoonFree { busiestPeriod = "afternoon" }
        else { busiestPeriod = "evening" }

        let summary = ScheduleSummary(
            totalFreeMinutes: totalFreeMinutes,
            totalScheduledMinutes: totalScheduledMinutes,
            prayerCount: context.prayers.count,
            taskCount: context.tasks.today.count,
            busiestPeriod: busiestPeriod,
            freestPeriod: freestPeriod
        )

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let analysis = ScheduleAnalysis(
            date: dateFormatter.string(from: targetDate),
            freeSlots: freeSlots,
            suggestions: suggestions,
            summary: summary
        )

        return .scheduleAnalysis(analysis: analysis)
    }

    /// Determine time of day from a date
    private func getTimeOfDay(from date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }

    /// Generate smart habit suggestions based on available slots
    private func generateHabitSuggestions(
        forSlots slots: [FreeTimeSlot],
        categories: [String]?,
        prayers: [PrayerContext]
    ) -> [HabitSuggestion] {
        var suggestions: [HabitSuggestion] = []
        let allowedCategories = Set(categories ?? ["worship", "health", "study", "personal", "social"])

        // Habit templates by time of day and duration
        let habitTemplates: [String: [(title: String, titleEn: String, category: String, duration: Int, icon: String, reason: String, recurring: Bool)]] = [
            "morning": [
                ("صلاة الضحى", "Duha Prayer", "worship", 15, "sun.max.fill", "أفضل وقت لصلاة الضحى", true),
                ("قراءة القرآن", "Quran Reading", "worship", 30, "book.fill", "وقت البركة الصباحية", true),
                ("تمارين رياضية", "Morning Exercise", "health", 45, "figure.run", "الرياضة الصباحية تزيد النشاط", true),
                ("مراجعة الأهداف", "Review Goals", "personal", 15, "target", "ابدأ يومك بوضوح", true),
                ("تعلم شيء جديد", "Learn Something New", "study", 30, "lightbulb.fill", "العقل أنشط في الصباح", true)
            ],
            "afternoon": [
                ("قيلولة قصيرة", "Power Nap", "health", 20, "bed.double.fill", "القيلولة سنة وتجدد النشاط", false),
                ("قراءة كتاب", "Book Reading", "study", 30, "book.closed.fill", "استثمر وقت ما بعد الغداء", false),
                ("مشي خفيف", "Light Walk", "health", 20, "figure.walk", "المشي بعد الأكل مفيد للهضم", false),
                ("أذكار المساء", "Evening Adhkar", "worship", 15, "sparkles", "لا تنس أذكار المساء", true)
            ],
            "evening": [
                ("قراءة القرآن", "Quran Reading", "worship", 30, "book.fill", "ختم يومك بالقرآن", true),
                ("وقت عائلي", "Family Time", "social", 60, "person.3.fill", "قضاء وقت مع الأهل", false),
                ("مراجعة اليوم", "Day Review", "personal", 15, "checklist", "راجع إنجازاتك اليومية", true),
                ("تحضير للغد", "Prepare for Tomorrow", "personal", 15, "calendar.badge.clock", "خطط ليومك القادم", true),
                ("استرخاء", "Relaxation", "health", 30, "leaf.fill", "وقت للراحة والاسترخاء", false)
            ],
            "night": [
                ("صلاة الوتر", "Witr Prayer", "worship", 15, "moon.stars.fill", "لا تنم قبل الوتر", true),
                ("قراءة قبل النوم", "Bedtime Reading", "study", 20, "book.closed.fill", "القراءة تساعد على النوم", false),
                ("أذكار النوم", "Sleep Adhkar", "worship", 10, "moon.fill", "أذكار قبل النوم", true)
            ]
        ]

        // Special habits for after specific prayers
        let afterPrayerHabits: [String: (title: String, titleEn: String, category: String, duration: Int, icon: String, reason: String, recurring: Bool)] = [
            "الفجر": ("أذكار الصباح", "Morning Adhkar", "worship", 15, "sunrise.fill", "أفضل وقت لأذكار الصباح", true),
            "الظهر": ("راحة قصيرة", "Short Rest", "health", 15, "bed.double.fill", "استراحة منتصف اليوم", false),
            "العصر": ("قراءة", "Reading", "study", 30, "book.fill", "وقت هادئ للقراءة", false),
            "المغرب": ("أذكار المساء", "Evening Adhkar", "worship", 15, "sunset.fill", "وقت أذكار المساء", true),
            "العشاء": ("صلاة الوتر", "Witr Prayer", "worship", 15, "moon.stars.fill", "ختم صلاة الليل", true)
        ]

        for slot in slots {
            // Get time-of-day appropriate habits
            let timeHabits = habitTemplates[slot.timeOfDay] ?? habitTemplates["afternoon"]!

            // Check for after-prayer specific habits first
            if let prayerName = slot.afterPrayer,
               let prayerHabit = afterPrayerHabits[prayerName],
               allowedCategories.contains(prayerHabit.category),
               prayerHabit.duration <= slot.durationMinutes {

                suggestions.append(HabitSuggestion(
                    title: prayerHabit.title,
                    titleEnglish: prayerHabit.titleEn,
                    category: prayerHabit.category,
                    duration: prayerHabit.duration,
                    icon: prayerHabit.icon,
                    slotStartTime: slot.startTime,
                    reason: prayerHabit.reason,
                    isRecurringRecommended: prayerHabit.recurring
                ))
            }

            // Add time-of-day habits that fit the slot
            for habit in timeHabits {
                guard allowedCategories.contains(habit.category),
                      habit.duration <= slot.durationMinutes else { continue }

                // Avoid duplicates
                if suggestions.contains(where: { $0.title == habit.title && $0.slotStartTime == slot.startTime }) {
                    continue
                }

                suggestions.append(HabitSuggestion(
                    title: habit.title,
                    titleEnglish: habit.titleEn,
                    category: habit.category,
                    duration: habit.duration,
                    icon: habit.icon,
                    slotStartTime: slot.startTime,
                    reason: habit.reason,
                    isRecurringRecommended: habit.recurring
                ))

                // Limit suggestions per slot
                let slotSuggestions = suggestions.filter { $0.slotStartTime == slot.startTime }
                if slotSuggestions.count >= 3 { break }
            }
        }

        // Limit total suggestions
        return Array(suggestions.prefix(10))
    }

    // MARK: - Settings Operations

    private func executeToggleNawafil(type: String?, enabled: Bool) async throws -> AIActionResult {
        if !userSettings.isProActive() {
            return .cannotFulfill(
                reason: "النوافل متاحة للاشتراك المدفوع فقط",
                alternative: "اشترك في Pro لتفعيل النوافل",
                manualAction: .openPaywall
            )
        }

        if enabled {
            if let type = type {
                // Enable specific nawafil type
                var currentTypes = userSettings.enabledNawafil
                if !currentTypes.contains(type) {
                    currentTypes.append(type)
                }
                userSettings.enableNawafil(types: currentTypes)
            } else {
                // Enable all nawafil
                userSettings.nawafilEnabled = true
            }
        } else {
            if let type = type {
                // Disable specific nawafil type
                var currentTypes = userSettings.enabledNawafil
                currentTypes.removeAll { $0 == type }
                if currentTypes.isEmpty {
                    userSettings.nawafilEnabled = false
                }
                userSettings.enabledNawafil = currentTypes
            } else {
                // Disable all nawafil
                userSettings.nawafilEnabled = false
            }
        }

        try modelContext.save()

        MizanLogger.shared.lifecycle.info("AI toggled nawafil: \(type ?? "all") = \(enabled)")

        return .settingChanged(
            key: "nawafil",
            oldValue: nil,
            newValue: enabled ? "مفعّل" : "معطّل"
        )
    }

    private func executeChangeSetting(key: SettingKey, value: SettingValue) async throws -> AIActionResult {
        // For now, only nawafil is supported
        switch key {
        case .nawafilEnabled:
            if let enabled = value.boolValue {
                return try await executeToggleNawafil(type: nil, enabled: enabled)
            }
        case .nawafilType:
            if let type = value.stringValue {
                return try await executeToggleNawafil(type: type, enabled: true)
            }
        }

        return .cannotFulfill(
            reason: "لا يمكن تغيير هذا الإعداد",
            alternative: "يمكنك تغيير الإعدادات يدوياً",
            manualAction: .openSettings
        )
    }

    // MARK: - Rearrangement Strategies

    private func rearrangeAfterPrayers(tasks: [Task], context: AIContext) async throws -> [ScheduleChange] {
        var changes: [ScheduleChange] = []
        var currentPrayerIndex = 0
        let prayers = context.prayers.filter { !$0.isPassed }

        // Sort tasks by priority (overdue first, then by current time)
        let sortedTasks = tasks.sorted { t1, t2 in
            if t1.isOverdue != t2.isOverdue { return t1.isOverdue }
            return (t1.scheduledStartTime ?? Date()) < (t2.scheduledStartTime ?? Date())
        }

        for task in sortedTasks {
            guard currentPrayerIndex < prayers.count else { break }

            let prayer = prayers[currentPrayerIndex]
            let newTime = prayer.adhanTime.addingTimeInterval(Double(prayer.duration + 15) * 60)

            if task.scheduledStartTime != newTime {
                let oldTime = formatTime(task.scheduledStartTime)
                task.scheduleAt(time: newTime)

                changes.append(ScheduleChange(
                    taskTitle: task.title,
                    oldTime: oldTime,
                    newTime: formatTime(newTime) ?? "غير محدد",
                    reason: "بعد \(prayer.nameArabic)"
                ))
            }

            currentPrayerIndex += 1
        }

        try modelContext.save()
        return changes
    }

    private func rearrangeOptimizeGaps(tasks: [Task], context: AIContext) async throws -> [ScheduleChange] {
        var changes: [ScheduleChange] = []

        // Sort by current scheduled time
        let sortedTasks = tasks.sorted { t1, t2 in
            (t1.scheduledStartTime ?? Date()) < (t2.scheduledStartTime ?? Date())
        }

        // Find earliest reasonable start time (now or next prayer end)
        var nextStart = Date()
        if let nextPrayer = context.nextPrayer {
            if nextPrayer.adhanTime > Date() {
                // Wait for prayer to finish
                nextStart = nextPrayer.adhanTime.addingTimeInterval(Double(nextPrayer.duration + 15) * 60)
            }
        }

        for task in sortedTasks {
            // Check if this time conflicts with a prayer
            if let conflict = context.checksPrayerConflict(at: nextStart, duration: task.duration) {
                // Skip past the prayer
                nextStart = conflict.adhanTime.addingTimeInterval(Double(conflict.duration + 15) * 60)
            }

            if task.scheduledStartTime != nextStart {
                let oldTime = formatTime(task.scheduledStartTime)
                task.scheduleAt(time: nextStart)

                changes.append(ScheduleChange(
                    taskTitle: task.title,
                    oldTime: oldTime,
                    newTime: formatTime(nextStart) ?? "غير محدد",
                    reason: "تقليل الفجوات"
                ))
            }

            // Move to end of this task
            nextStart = nextStart.addingTimeInterval(Double(task.duration * 60))
        }

        try modelContext.save()
        return changes
    }

    private func rearrangePrioritizeUrgent(tasks: [Task], context: AIContext) async throws -> [ScheduleChange] {
        // Sort by urgency: overdue first, then due soon, then by scheduled time
        let sortedTasks = tasks.sorted { t1, t2 in
            if t1.isOverdue != t2.isOverdue { return t1.isOverdue }
            if t1.isDueSoon != t2.isDueSoon { return t1.isDueSoon }
            return (t1.scheduledStartTime ?? Date()) < (t2.scheduledStartTime ?? Date())
        }

        // Then apply optimize gaps with new order
        return try await rearrangeOptimizeGaps(tasks: sortedTasks, context: context)
    }

    private func rearrangeSpreadEvenly(tasks: [Task], context: AIContext) async throws -> [ScheduleChange] {
        var changes: [ScheduleChange] = []

        // Calculate available time windows (between prayers)
        let availableSlots = context.availableSlots
        guard !availableSlots.isEmpty else {
            return changes
        }

        // Calculate total task duration
        let totalDuration = tasks.reduce(0) { $0 + $1.duration }

        // Calculate total available time
        let totalAvailable = availableSlots.reduce(0) { $0 + $1.durationMinutes }

        guard totalDuration <= totalAvailable else {
            // Not enough time
            return changes
        }

        // Distribute tasks evenly
        var slotIndex = 0
        var currentSlotOffset = 0

        for task in tasks {
            guard slotIndex < availableSlots.count else { break }

            let slot = availableSlots[slotIndex]
            let newTime = slot.startTime.addingTimeInterval(Double(currentSlotOffset * 60))

            if task.scheduledStartTime != newTime {
                let oldTime = formatTime(task.scheduledStartTime)
                task.scheduleAt(time: newTime)

                changes.append(ScheduleChange(
                    taskTitle: task.title,
                    oldTime: oldTime,
                    newTime: formatTime(newTime) ?? "غير محدد",
                    reason: "توزيع متساوي"
                ))
            }

            currentSlotOffset += task.duration + 15 // 15 min gap

            // Check if we need to move to next slot
            if currentSlotOffset >= slot.durationMinutes {
                slotIndex += 1
                currentSlotOffset = 0
            }
        }

        try modelContext.save()
        return changes
    }

    // MARK: - Helper Methods

    private func parseDate(_ dateStr: String) -> Date {
        let calendar = Calendar.current

        switch dateStr.lowercased() {
        case "today", "اليوم":
            return Date()
        case "tomorrow", "غدا", "غداً", "بكرة":
            return calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        default:
            // Try ISO8601 format
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            if let date = formatter.date(from: dateStr) {
                return date
            }

            // Try other formats
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateStr) {
                return date
            }

            return Date()
        }
    }

    private func parseDateTime(dateStr: String, timeStr: String) -> Date? {
        let date = parseDate(dateStr)
        let calendar = Calendar.current

        // Parse time (HH:mm format)
        let components = timeStr.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }

        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = hour
        dateComponents.minute = minute

        return calendar.date(from: dateComponents)
    }

    private func parseTimeForToday(_ timeStr: String) -> Date? {
        let calendar = Calendar.current

        // Parse time (HH:mm format)
        let components = timeStr.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }

        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = hour
        dateComponents.minute = minute

        if let time = calendar.date(from: dateComponents) {
            // If time has passed, use tomorrow
            if time < Date() {
                return calendar.date(byAdding: .day, value: 1, to: time)
            }
            return time
        }

        return nil
    }

    private func formatDate(_ date: Date?) -> String? {
        guard let date = date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date?) -> String? {
        guard let date = date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Convenience Extensions

extension AIActionExecutor {
    /// Execute with automatic error handling
    func executeWithErrorHandling(_ intent: AIIntent) async -> AIActionResult {
        do {
            return try await execute(intent)
        } catch let error as AIActionError {
            switch error {
            case .taskNotFound(let query):
                return .cannotFulfill(
                    reason: "لم أجد مهمة: \(query)",
                    alternative: "تأكد من اسم المهمة",
                    manualAction: .openTimeline
                )
            case .multipleMatches(let count, let tasks):
                let clarification = ClarificationRequest.whichTask(
                    action: "تنفيذ",
                    matchingTasks: tasks
                )
                return .needsClarification(request: clarification)
            case .prayerConflict(let prayer, let suggested):
                return .cannotFulfill(
                    reason: "هذا وقت صلاة \(prayer)",
                    alternative: "جرب الوقت: \(suggested)",
                    manualAction: nil
                )
            default:
                return .cannotFulfill(
                    reason: error.arabicDescription,
                    alternative: nil,
                    manualAction: nil
                )
            }
        } catch {
            MizanLogger.shared.lifecycle.error("AI action error: \(error.localizedDescription)")
            return .cannotFulfill(
                reason: "حدث خطأ غير متوقع",
                alternative: "حاول مرة أخرى",
                manualAction: nil
            )
        }
    }
}
