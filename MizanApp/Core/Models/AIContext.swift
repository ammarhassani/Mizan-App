//
//  AIContext.swift
//  Mizan
//
//  Context snapshot for AI prompts - contains all relevant app state
//  that the AI needs to make informed decisions
//

import Foundation

// MARK: - AI Context

/// Complete context snapshot for AI decision making
struct AIContext: Codable {
    let currentDate: Date
    let currentTime: Date
    let timezone: String
    let location: LocationInfo?
    let tasks: TasksContext
    let prayers: [PrayerContext]
    let nawafil: [NawafilContext]
    let availableSlots: [TimeSlot]
    let userPreferences: UserPreferencesContext

    // MARK: - Initialization

    init(
        currentDate: Date = Date(),
        currentTime: Date = Date(),
        timezone: TimeZone = .current,
        location: LocationInfo? = nil,
        tasks: TasksContext = TasksContext(),
        prayers: [PrayerContext] = [],
        nawafil: [NawafilContext] = [],
        availableSlots: [TimeSlot] = [],
        userPreferences: UserPreferencesContext = UserPreferencesContext()
    ) {
        self.currentDate = currentDate
        self.currentTime = currentTime
        self.timezone = timezone.identifier
        self.location = location
        self.tasks = tasks
        self.prayers = prayers
        self.nawafil = nawafil
        self.availableSlots = availableSlots
        self.userPreferences = userPreferences
    }

    // MARK: - Convert to Prompt String

    /// Generate Arabic prompt string for AI consumption
    func toPromptString() -> String {
        var parts: [String] = []

        // Date and time header
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ar")
        dateFormatter.dateFormat = "EEEE d MMMM yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ar")
        timeFormatter.dateFormat = "h:mm a"

        parts.append("اليوم: \(dateFormatter.string(from: currentDate))")
        parts.append("الوقت الحالي: \(timeFormatter.string(from: currentTime))")

        if let location = location, let city = location.city {
            parts.append("الموقع: \(city)")
        }

        parts.append("")

        // Prayer times
        if !prayers.isEmpty {
            parts.append("📿 أوقات الصلاة اليوم:")
            for prayer in prayers {
                parts.append("- \(prayer.nameArabic): \(prayer.formattedTime)")
            }
            parts.append("")
        }

        // Today's scheduled tasks
        let todayTasks = tasks.today
        if !todayTasks.isEmpty {
            parts.append("📋 المهام المجدولة اليوم (\(todayTasks.count) مهام):")
            for (index, task) in todayTasks.enumerated() {
                let time = task.scheduledTime ?? "غير محدد"
                parts.append("\(index + 1). [\(task.category)] \(task.title) • \(time) • \(task.duration) د")
            }
            parts.append("")
        }

        // Tomorrow's tasks
        let tomorrowTasks = tasks.tomorrow
        if !tomorrowTasks.isEmpty {
            parts.append("📅 مهام الغد (\(tomorrowTasks.count) مهام):")
            for task in tomorrowTasks {
                let time = task.scheduledTime ?? "غير محدد"
                parts.append("- \(task.title) • \(time)")
            }
            parts.append("")
        }

        // Inbox tasks
        let inboxTasks = tasks.inbox
        if !inboxTasks.isEmpty {
            parts.append("📥 المهام في صندوق الوارد (\(inboxTasks.count)):")
            for task in inboxTasks {
                parts.append("- \(task.title) (\(task.duration) د)")
            }
            parts.append("")
        }

        // Overdue tasks
        let overdueTasks = tasks.overdue
        if !overdueTasks.isEmpty {
            parts.append("⚠️ مهام متأخرة (\(overdueTasks.count)):")
            for task in overdueTasks {
                parts.append("- \(task.title)")
            }
            parts.append("")
        }

        // Available time slots
        if !availableSlots.isEmpty {
            parts.append("⏰ الأوقات المتاحة:")
            for slot in availableSlots {
                parts.append("- \(slot.formattedRange) (\(slot.durationMinutes) دقيقة)")
            }
            parts.append("")
        }

        // User preferences
        parts.append("⚙️ الإعدادات:")
        parts.append("- Pro: \(userPreferences.isPro ? "نعم" : "لا")")
        if userPreferences.nawafilEnabled {
            parts.append("- النوافل: مفعلة")
        }
        parts.append("- اللغة: \(userPreferences.language == "ar" ? "العربية" : "English")")

        return parts.joined(separator: "\n")
    }

    /// Generate English prompt string (fallback)
    func toEnglishPromptString() -> String {
        var parts: [String] = []

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        parts.append("Today: \(dateFormatter.string(from: currentDate))")
        parts.append("Current time: \(timeFormatter.string(from: currentTime))")

        if let location = location, let city = location.city {
            parts.append("Location: \(city)")
        }

        parts.append("")

        // Prayer times
        if !prayers.isEmpty {
            parts.append("Prayer times today:")
            for prayer in prayers {
                parts.append("- \(prayer.name): \(prayer.formattedTime)")
            }
            parts.append("")
        }

        // Tasks
        if !tasks.today.isEmpty {
            parts.append("Today's tasks (\(tasks.today.count)):")
            for task in tasks.today {
                let time = task.scheduledTime ?? "unscheduled"
                parts.append("- \(task.title) at \(time) (\(task.duration) min)")
            }
            parts.append("")
        }

        return parts.joined(separator: "\n")
    }
}

// MARK: - Location Info

struct LocationInfo: Codable {
    let latitude: Double?
    let longitude: Double?
    let city: String?

    init(latitude: Double? = nil, longitude: Double? = nil, city: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.city = city
    }
}

// MARK: - Tasks Context

struct TasksContext: Codable {
    var today: [TaskContext] = []
    var tomorrow: [TaskContext] = []
    var inbox: [TaskContext] = []
    var overdue: [TaskContext] = []
    var completed: [TaskContext] = []

    var totalCount: Int {
        today.count + tomorrow.count + inbox.count + overdue.count
    }
}

// MARK: - Task Context

struct TaskContext: Codable, Identifiable {
    let id: String
    let title: String
    let duration: Int
    let category: String
    let icon: String
    let scheduledDate: String?
    let scheduledTime: String?
    let isCompleted: Bool
    let isRecurring: Bool
    let notes: String?

    init(
        id: String,
        title: String,
        duration: Int,
        category: String,
        icon: String,
        scheduledDate: String? = nil,
        scheduledTime: String? = nil,
        isCompleted: Bool = false,
        isRecurring: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.category = category
        self.icon = icon
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.isCompleted = isCompleted
        self.isRecurring = isRecurring
        self.notes = notes
    }

    /// Convert to TaskSummary for disambiguation
    func toSummary() -> TaskSummary {
        TaskSummary(
            id: id,
            title: title,
            icon: icon,
            scheduledTime: scheduledTime,
            duration: duration,
            category: category
        )
    }
}

// MARK: - Prayer Context

struct PrayerContext: Codable, Identifiable {
    let id: String
    let name: String
    let nameArabic: String
    let adhanTime: Date
    let iqamaTime: Date?
    let duration: Int
    let isPassed: Bool

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: adhanTime)
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        nameArabic: String,
        adhanTime: Date,
        iqamaTime: Date? = nil,
        duration: Int = 15,
        isPassed: Bool = false
    ) {
        self.id = id
        self.name = name
        self.nameArabic = nameArabic
        self.adhanTime = adhanTime
        self.iqamaTime = iqamaTime
        self.duration = duration
        self.isPassed = isPassed
    }
}

// MARK: - Nawafil Context

struct NawafilContext: Codable, Identifiable {
    let id: String
    let type: String
    let nameArabic: String
    let suggestedTime: Date
    let duration: Int
    let rakaat: Int
    let isCompleted: Bool

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: suggestedTime)
    }
}

// MARK: - Time Slot

struct TimeSlot: Codable, Identifiable {
    let id: String
    let startTime: Date
    let endTime: Date

    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    var formattedRange: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    init(id: String = UUID().uuidString, startTime: Date, endTime: Date) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
    }

    /// Check if a task of given duration fits in this slot
    func canFit(duration: Int) -> Bool {
        durationMinutes >= duration
    }
}

// MARK: - User Preferences Context

struct UserPreferencesContext: Codable {
    let language: String
    let isPro: Bool
    let nawafilEnabled: Bool
    let enabledNawafilTypes: [String]
    let theme: String
    let calculationMethod: String?

    init(
        language: String = "ar",
        isPro: Bool = false,
        nawafilEnabled: Bool = false,
        enabledNawafilTypes: [String] = [],
        theme: String = "darkMatter",
        calculationMethod: String? = nil
    ) {
        self.language = language
        self.isPro = isPro
        self.nawafilEnabled = nawafilEnabled
        self.enabledNawafilTypes = enabledNawafilTypes
        self.theme = theme
        self.calculationMethod = calculationMethod
    }
}

// MARK: - Context Extensions

extension AIContext {
    /// Find the next prayer from current time
    var nextPrayer: PrayerContext? {
        prayers.first { !$0.isPassed }
    }

    /// Get time until next prayer in minutes
    var minutesUntilNextPrayer: Int? {
        guard let next = nextPrayer else { return nil }
        return Int(next.adhanTime.timeIntervalSince(currentTime) / 60)
    }

    /// Check if scheduling at given time would conflict with prayer
    func checksPrayerConflict(at time: Date, duration: Int) -> PrayerContext? {
        let taskEndTime = time.addingTimeInterval(Double(duration * 60))
        let buffer: TimeInterval = 15 * 60 // 15 minutes buffer

        for prayer in prayers {
            let prayerStart = prayer.adhanTime.addingTimeInterval(-buffer)
            let prayerEnd = prayer.adhanTime.addingTimeInterval(Double(prayer.duration * 60) + buffer)

            // Check if task overlaps with prayer window
            if time < prayerEnd && taskEndTime > prayerStart {
                return prayer
            }
        }
        return nil
    }

    /// Find first available slot that can fit a task of given duration
    func findSlot(forDuration duration: Int, afterPrayer: String? = nil) -> TimeSlot? {
        var slots = availableSlots.filter { $0.canFit(duration: duration) }

        if let prayerName = afterPrayer?.lowercased() {
            // Find the prayer
            if let prayer = prayers.first(where: { $0.name.lowercased() == prayerName }) {
                // Filter to slots that start after this prayer
                let prayerEndTime = prayer.adhanTime.addingTimeInterval(Double(prayer.duration * 60))
                slots = slots.filter { $0.startTime >= prayerEndTime }
            }
        }

        return slots.first
    }
}
