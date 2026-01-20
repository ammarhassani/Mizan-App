//
//  AIIntent.swift
//  Mizan
//
//  AI Intent types for the conversational AI agent
//  Represents all actions the AI can perform
//

import Foundation

// MARK: - AI Intent Enum

/// All possible intents the AI can detect and execute
enum AIIntent: Codable {
    // MARK: - Task CRUD
    case createTask(ExtractedTaskData)
    case editTask(taskQuery: TaskQuery, changes: TaskChanges)
    case deleteTask(taskQuery: TaskQuery, deleteAllRecurring: Bool)
    case completeTask(taskQuery: TaskQuery)
    case uncompleteTask(taskQuery: TaskQuery)

    // MARK: - Scheduling
    case rescheduleTask(taskQuery: TaskQuery, newTime: TimeSpec)
    case moveToInbox(taskQuery: TaskQuery)
    case rearrangeSchedule(date: String, strategy: RearrangeStrategy)
    case findAvailableSlot(duration: Int, date: String?, preferredTime: TimeSpec?, afterPrayer: String?)

    // MARK: - Queries (read-only)
    case queryTasks(filter: AITaskFilter)
    case queryPrayers(date: String?)
    case querySchedule(date: String?)
    case queryAvailableTime(date: String?)
    case analyzeSchedule(date: String?, focusArea: String?, suggestHabits: Bool, habitCategories: [String]?)

    // MARK: - Settings
    case toggleNawafil(type: String?, enabled: Bool)
    case changeSetting(key: SettingKey, value: SettingValue)

    // MARK: - Conversation
    case clarify(ClarificationRequest)
    case suggest(suggestions: [String])
    case explain(topic: String)

    // MARK: - Fallback
    case cannotFulfill(reason: String, alternative: String?, manualSteps: [String]?)
}

// MARK: - Task Query

/// Query parameters for finding tasks
struct TaskQuery: Codable, CustomStringConvertible {
    var titleContains: String?
    var date: String?           // "today", "tomorrow", "2026-01-20"
    var category: String?
    var isCompleted: Bool?
    var taskId: String?         // Direct ID if known

    var description: String {
        var parts: [String] = []
        if let title = titleContains { parts.append("title contains '\(title)'") }
        if let date = date { parts.append("date: \(date)") }
        if let category = category { parts.append("category: \(category)") }
        if let completed = isCompleted { parts.append("completed: \(completed)") }
        if let id = taskId { parts.append("id: \(id)") }
        return parts.isEmpty ? "any task" : parts.joined(separator: ", ")
    }

    /// Create query from task title
    static func byTitle(_ title: String) -> TaskQuery {
        TaskQuery(titleContains: title)
    }

    /// Create query for today's tasks
    static func today() -> TaskQuery {
        TaskQuery(date: "today")
    }

    /// Create query for tomorrow's tasks
    static func tomorrow() -> TaskQuery {
        TaskQuery(date: "tomorrow")
    }

    /// Create query by task ID
    static func byId(_ id: String) -> TaskQuery {
        TaskQuery(taskId: id)
    }
}

// MARK: - Task Changes

/// Changes to apply when editing a task
struct TaskChanges: Codable {
    var title: String?
    var duration: Int?
    var notes: String?
    var category: String?
    var scheduledDate: String?
    var scheduledTime: String?

    var hasChanges: Bool {
        title != nil || duration != nil || notes != nil ||
        category != nil || scheduledDate != nil || scheduledTime != nil
    }
}

// MARK: - Time Specification

/// Flexible time specification for scheduling
struct TimeSpec: Codable {
    var date: String?           // ISO8601 date or "today", "tomorrow"
    var time: String?           // HH:mm format
    var afterPrayer: String?    // "fajr", "dhuhr", "asr", "maghrib", "isha"
    var relativeMinutes: Int?   // e.g., +30 = 30 minutes from now

    /// Create time spec for after a prayer
    static func afterPrayer(_ prayer: String) -> TimeSpec {
        TimeSpec(afterPrayer: prayer)
    }

    /// Create time spec for specific time
    static func at(_ time: String, on date: String? = nil) -> TimeSpec {
        TimeSpec(date: date, time: time)
    }
}

// MARK: - Rearrange Strategy

/// Strategies for rearranging the schedule
enum RearrangeStrategy: String, Codable, CaseIterable {
    case afterPrayer = "after_prayer"       // Schedule after specific prayer
    case optimizeGaps = "optimize_gaps"     // Minimize gaps between tasks
    case prioritizeUrgent = "prioritize_urgent"  // Put urgent/overdue first
    case spreadEvenly = "spread_evenly"     // Distribute throughout day

    var arabicDescription: String {
        switch self {
        case .afterPrayer: return "بعد الصلاة"
        case .optimizeGaps: return "تقليل الفجوات"
        case .prioritizeUrgent: return "الأولوية للمستعجل"
        case .spreadEvenly: return "توزيع متساوي"
        }
    }
}

// MARK: - AI Task Filter

/// Filter parameters for querying tasks (renamed to avoid conflict with InboxView.TaskFilter)
struct AITaskFilter: Codable {
    var date: String?
    var category: String?
    var isCompleted: Bool?
    var inInbox: Bool?
    var isOverdue: Bool?
    var limit: Int?

    static var today: AITaskFilter {
        AITaskFilter(date: "today")
    }

    static var tomorrow: AITaskFilter {
        AITaskFilter(date: "tomorrow")
    }

    static var inbox: AITaskFilter {
        AITaskFilter(inInbox: true)
    }

    static var overdue: AITaskFilter {
        AITaskFilter(isOverdue: true)
    }
}

// MARK: - Setting Key & Value

/// Keys for settings that can be modified by AI
enum SettingKey: String, Codable {
    case nawafilEnabled = "nawafil_enabled"
    case nawafilType = "nawafil_type"
    // Add more as needed
}

/// Values for settings
enum SettingValue: Codable {
    case bool(Bool)
    case string(String)
    case int(Int)

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }
}

// MARK: - Clarification Request

/// Request for clarifying incomplete user input
struct ClarificationRequest: Codable {
    var question: String           // "متى تريد جدولة المهمة؟"
    var options: [ClarificationOption]?  // Quick select options
    var freeTextAllowed: Bool      // Can user type custom answer
    var partialData: PartialTaskData?  // What we know so far

    init(
        question: String,
        options: [ClarificationOption]? = nil,
        freeTextAllowed: Bool = true,
        partialData: PartialTaskData? = nil
    ) {
        self.question = question
        self.options = options
        self.freeTextAllowed = freeTextAllowed
        self.partialData = partialData
    }

    // MARK: - Common Clarifications

    /// Ask when to schedule
    static func whenToSchedule(taskTitle: String) -> ClarificationRequest {
        ClarificationRequest(
            question: "متى تريد جدولة \"\(taskTitle)\"؟",
            options: [
                ClarificationOption(label: "الآن", value: "now", icon: "clock.fill"),
                ClarificationOption(label: "بعد صلاة الظهر", value: "after_dhuhr", icon: "sun.max.fill"),
                ClarificationOption(label: "غداً", value: "tomorrow", icon: "calendar"),
                ClarificationOption(label: "اختيار وقت محدد", value: "custom", icon: "calendar.badge.clock")
            ],
            freeTextAllowed: true,
            partialData: PartialTaskData(title: taskTitle)
        )
    }

    /// Ask which task
    static func whichTask(action: String, matchingTasks: [TaskSummary]) -> ClarificationRequest {
        ClarificationRequest(
            question: "أي مهمة تقصد؟",
            options: matchingTasks.prefix(4).map { task in
                ClarificationOption(
                    label: task.title,
                    value: task.id,
                    icon: task.icon,
                    subtitle: task.scheduledTime
                )
            },
            freeTextAllowed: false
        )
    }

    /// Ask for new time
    static func newTime(forTask taskTitle: String) -> ClarificationRequest {
        ClarificationRequest(
            question: "إلى أي وقت تريد نقل \"\(taskTitle)\"؟",
            options: [
                ClarificationOption(label: "بعد صلاة الفجر", value: "after_fajr", icon: "sunrise.fill"),
                ClarificationOption(label: "بعد صلاة الظهر", value: "after_dhuhr", icon: "sun.max.fill"),
                ClarificationOption(label: "بعد صلاة العصر", value: "after_asr", icon: "sun.haze.fill"),
                ClarificationOption(label: "بعد صلاة المغرب", value: "after_maghrib", icon: "sunset.fill")
            ],
            freeTextAllowed: true
        )
    }

    /// Ask what to do
    static func whatToDo() -> ClarificationRequest {
        ClarificationRequest(
            question: "ماذا تريد أن تفعل؟",
            options: nil,
            freeTextAllowed: true
        )
    }
}

// MARK: - Clarification Option

/// An option in a clarification question
struct ClarificationOption: Codable, Identifiable {
    var id: String { value }
    var label: String      // "بعد صلاة الظهر"
    var value: String      // "after_dhuhr"
    var icon: String?      // "sun.max.fill"
    var subtitle: String?  // Optional additional info
}

// MARK: - Partial Task Data

/// Partially extracted task data (for clarification context)
struct PartialTaskData: Codable {
    var title: String?
    var duration: Int?
    var category: String?
    var scheduledDate: String?
    var scheduledTime: String?
    var notes: String?
}

// MARK: - Task Summary

/// Summary of a task for disambiguation
struct TaskSummary: Codable, Identifiable {
    var id: String
    var title: String
    var icon: String
    var scheduledTime: String?
    var duration: Int
    var category: String
}

// MARK: - AI Action Error

/// Errors that can occur during AI action execution
enum AIActionError: LocalizedError {
    case taskNotFound(query: String)
    case multipleMatches(count: Int, tasks: [TaskSummary])
    case prayerConflict(prayerName: String, suggestedTime: String)
    case invalidTime(reason: String)
    case settingNotModifiable(key: String)
    case networkError(underlying: Error)
    case insufficientPermission(action: String)
    case unknown(message: String)

    var errorDescription: String? {
        switch self {
        case .taskNotFound(let query):
            return "لم أجد مهمة: \(query)"
        case .multipleMatches(let count, _):
            return "وجدت \(count) مهام متشابهة"
        case .prayerConflict(let prayer, let suggested):
            return "هذا وقت صلاة \(prayer). هل تريد الجدولة في \(suggested)؟"
        case .invalidTime(let reason):
            return "وقت غير صالح: \(reason)"
        case .settingNotModifiable(let key):
            return "لا يمكن تغيير هذا الإعداد: \(key)"
        case .networkError:
            return "خطأ في الاتصال"
        case .insufficientPermission(let action):
            return "لا يمكن تنفيذ: \(action)"
        case .unknown(let message):
            return message
        }
    }

    var arabicDescription: String {
        errorDescription ?? "حدث خطأ غير معروف"
    }
}

// MARK: - Schedule Analysis

/// Result of schedule analysis with habit suggestions
struct ScheduleAnalysis: Codable {
    var date: String
    var freeSlots: [FreeTimeSlot]
    var suggestions: [HabitSuggestion]
    var summary: ScheduleSummary
}

/// A free time slot in the schedule
struct FreeTimeSlot: Codable, Identifiable {
    var id: String { "\(startTime)-\(endTime)" }
    var startTime: String       // HH:mm
    var endTime: String         // HH:mm
    var durationMinutes: Int
    var timeOfDay: String       // morning, afternoon, evening, night
    var afterPrayer: String?    // If this slot is right after a prayer
}

/// A habit suggestion for a time slot
struct HabitSuggestion: Codable, Identifiable {
    var id: String { "\(slotStartTime)-\(title)" }
    var title: String           // Arabic title
    var titleEnglish: String?   // English fallback
    var category: String        // worship, health, study, personal, social
    var duration: Int           // Suggested duration in minutes
    var icon: String            // SF Symbol
    var slotStartTime: String   // Which slot this fits
    var reason: String          // Why this is suggested (Arabic)
    var isRecurringRecommended: Bool
}

/// Summary of the schedule analysis
struct ScheduleSummary: Codable {
    var totalFreeMinutes: Int
    var totalScheduledMinutes: Int
    var prayerCount: Int
    var taskCount: Int
    var busiestPeriod: String?  // morning, afternoon, evening
    var freestPeriod: String?   // morning, afternoon, evening
}
