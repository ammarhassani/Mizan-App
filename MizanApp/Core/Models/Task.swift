//
//  Task.swift
//  Mizan
//
//  SwiftData model for tasks
//

import Foundation
import SwiftData

@Model
final class Task {
    // MARK: - Identity
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Core Properties
    var title: String
    var notes: String?
    var duration: Int // minutes
    var category: TaskCategory

    // MARK: - Scheduling
    var scheduledDate: Date? // nil = inbox, non-nil = on timeline
    var scheduledStartTime: Date? // exact time on timeline
    var completedAt: Date?
    var isCompleted: Bool
    var dueDate: Date? // deadline for task completion

    // MARK: - Recurrence (Pro Feature)
    var recurrenceRule: RecurrenceRule?
    var isRecurring: Bool
    var parentTaskId: UUID? // for recurring instances

    // MARK: - Metadata
    var order: Int // for inbox ordering
    var colorHex: String // derived from category but customizable (Pro)

    // MARK: - Custom Category (Pro Feature)
    var userCategory: UserCategory?

    // MARK: - Initialization
    init(
        title: String,
        duration: Int = 30,
        category: TaskCategory = .personal,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.title = title
        self.duration = duration
        self.category = category
        self.notes = notes
        self.scheduledDate = nil
        self.scheduledStartTime = nil
        self.completedAt = nil
        self.isCompleted = false
        self.dueDate = nil
        self.recurrenceRule = nil
        self.isRecurring = false
        self.parentTaskId = nil
        self.order = 0
        self.colorHex = category.defaultColorHex
    }

    // MARK: - Computed Properties

    var endTime: Date? {
        guard let startTime = scheduledStartTime else { return nil }
        return startTime.addingTimeInterval(TimeInterval(duration * 60))
    }

    var isScheduled: Bool {
        return scheduledStartTime != nil
    }

    var isInInbox: Bool {
        return scheduledStartTime == nil
    }

    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return Date() > due
    }

    var isDueSoon: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        let hoursUntilDue = due.timeIntervalSince(Date()) / 3600
        return hoursUntilDue > 0 && hoursUntilDue <= 24
    }

    // MARK: - Methods
    func markComplete() {
        isCompleted = true
        completedAt = Date()
        updatedAt = Date()
    }

    func unmarkComplete() {
        isCompleted = false
        completedAt = nil
        updatedAt = Date()
    }

    func scheduleAt(time: Date) {
        scheduledStartTime = time
        scheduledDate = Calendar.current.startOfDay(for: time)
        updatedAt = Date()
    }

    func moveToInbox() {
        scheduledStartTime = nil
        scheduledDate = nil
        updatedAt = Date()
    }

    func updateDuration(_ newDuration: Int) {
        duration = newDuration
        updatedAt = Date()
    }

    func updateTitle(_ newTitle: String) {
        title = newTitle
        updatedAt = Date()
    }

    func setDueDate(_ date: Date?) {
        dueDate = date
        updatedAt = Date()
    }

    func complete() {
        markComplete()
    }

    func uncomplete() {
        unmarkComplete()
    }
}

// MARK: - Task Category

enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case work
    case personal
    case study
    case health
    case social
    case worship

    var id: String { rawValue }

    var nameArabic: String {
        switch self {
        case .work: return "عمل"
        case .personal: return "شخصي"
        case .study: return "دراسة"
        case .health: return "صحة"
        case .social: return "اجتماعي"
        case .worship: return "عبادة"
        }
    }

    var nameEnglish: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        case .study: return "Study"
        case .health: return "Health"
        case .social: return "Social"
        case .worship: return "Worship"
        }
    }

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "house.fill"
        case .study: return "book.fill"
        case .health: return "heart.fill"
        case .social: return "person.2.fill"
        case .worship: return "moon.stars.fill"
        }
    }

    var defaultColorHex: String {
        // These will be overridden by theme-specific colors from ThemeConfig.json
        switch self {
        case .work: return "#3B82F6" // blue
        case .personal: return "#10B981" // green
        case .study: return "#8B5CF6" // purple
        case .health: return "#EF4444" // red
        case .social: return "#F59E0B" // amber
        case .worship: return "#6366F1" // indigo
        }
    }

    /// Hint text to help users understand what each category is for (Arabic)
    var hintArabic: String {
        switch self {
        case .work: return "اجتماعات، مشاريع، مهام وظيفية"
        case .personal: return "مهام شخصية، أعمال منزلية، مشتريات"
        case .study: return "دراسة، قراءة، تعلم مهارات جديدة"
        case .health: return "رياضة، مواعيد طبية، عناية ذاتية"
        case .social: return "لقاءات عائلية، مناسبات، زيارات"
        case .worship: return "قرآن، أذكار، صدقات، عبادات إضافية"
        }
    }

    /// Hint text to help users understand what each category is for (English)
    var hintEnglish: String {
        switch self {
        case .work: return "Meetings, projects, work tasks"
        case .personal: return "Personal errands, chores, shopping"
        case .study: return "Studying, reading, learning new skills"
        case .health: return "Exercise, doctor visits, self-care"
        case .social: return "Family gatherings, events, visits"
        case .worship: return "Quran, dhikr, charity, extra worship"
        }
    }

    func colorHex(for theme: Theme) -> String {
        theme.colors.taskColors?[rawValue] ?? defaultColorHex
    }
}

// MARK: - Recurrence Rule

struct RecurrenceRule: Codable {
    enum Frequency: String, Codable {
        case daily
        case weekly
        case monthly
    }

    var frequency: Frequency
    var interval: Int // every N days/weeks/months
    var daysOfWeek: [Int]? // 1 = Sunday, 7 = Saturday (for weekly)
    var endDate: Date?
    var occurrences: Int? // end after N occurrences

    init(
        frequency: Frequency,
        interval: Int = 1,
        daysOfWeek: [Int]? = nil,
        endDate: Date? = nil,
        occurrences: Int? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.endDate = endDate
        self.occurrences = occurrences
    }

    // MARK: - Next Occurrence Calculation

    func nextOccurrence(after date: Date) -> Date? {
        let calendar = Calendar.current

        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: date)

        case .weekly:
            guard let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty else {
                return calendar.date(byAdding: .weekOfYear, value: interval, to: date)
            }

            // Find next matching day of week
            var currentDate = date
            for _ in 0..<14 { // Search up to 2 weeks
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                let weekday = calendar.component(.weekday, from: currentDate)
                if daysOfWeek.contains(weekday) {
                    return currentDate
                }
            }
            return nil

        case .monthly:
            return calendar.date(byAdding: .month, value: interval, to: date)
        }
    }

    func shouldEndBefore(date: Date) -> Bool {
        if let endDate = endDate, date > endDate {
            return true
        }
        return false
    }

    // MARK: - Display Text

    var displayText: String {
        switch frequency {
        case .daily:
            return interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly:
            if let days = daysOfWeek, !days.isEmpty {
                let dayNames = days.map { dayNumber in
                    DateFormatter().weekdaySymbols[dayNumber - 1]
                }.joined(separator: ", ")
                return "Weekly on \(dayNames)"
            }
            return interval == 1 ? "Weekly" : "Every \(interval) weeks"
        case .monthly:
            return interval == 1 ? "Monthly" : "Every \(interval) months"
        }
    }
}

// MARK: - Task Extensions

extension Task {
    /// Creates a new instance of a recurring task
    func createRecurringInstance(for date: Date) -> Task {
        let newTask = Task(
            title: title,
            duration: duration,
            category: category,
            notes: notes
        )
        newTask.parentTaskId = id
        newTask.isRecurring = true
        newTask.recurrenceRule = recurrenceRule
        newTask.scheduledDate = date
        newTask.colorHex = colorHex

        // Calculate start time based on original task's time
        if let originalStartTime = scheduledStartTime {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: originalStartTime)
            var newDateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            newDateComponents.hour = timeComponents.hour
            newDateComponents.minute = timeComponents.minute
            if let newStartTime = calendar.date(from: newDateComponents) {
                newTask.scheduledStartTime = newStartTime
            }
        }

        // Calculate due date relative to new instance date
        if let originalDueDate = dueDate, let originalScheduled = scheduledDate {
            let calendar = Calendar.current
            let daysDifference = calendar.dateComponents([.day], from: originalScheduled, to: originalDueDate).day ?? 0
            newTask.dueDate = calendar.date(byAdding: .day, value: daysDifference, to: date)
        }

        return newTask
    }
}
