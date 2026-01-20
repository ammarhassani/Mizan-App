//
//  AIActionResult.swift
//  Mizan
//
//  Result types for AI action execution with UI hints
//

import Foundation
import SwiftUI

// MARK: - AI Action Result

/// Result of executing an AI intent
enum AIActionResult {
    // MARK: - Success Results

    /// Task was created successfully
    case taskCreated(task: TaskContext, showInTimeline: Bool)

    /// Task was edited successfully
    case taskEdited(task: TaskContext, changes: [String])

    /// Task was deleted successfully
    case taskDeleted(taskTitle: String, wasRecurring: Bool)

    /// Task was completed
    case taskCompleted(task: TaskContext)

    /// Task was uncompleted
    case taskUncompleted(task: TaskContext)

    /// Task was already completed (no change needed)
    case taskAlreadyCompleted(taskTitle: String)

    /// Task was rescheduled
    case taskRescheduled(task: TaskContext, oldTime: String?, newTime: String?)

    /// Task was moved to inbox
    case taskMovedToInbox(task: TaskContext)

    /// Schedule was rearranged
    case scheduleRearranged(tasksAffected: Int, changes: [ScheduleChange])

    /// Available slot found
    case slotFound(slot: TimeSlot)

    // MARK: - Query Results

    /// Tasks query result
    case taskList(tasks: [TaskContext])

    /// Prayers query result
    case prayerList(prayers: [PrayerContext])

    /// Schedule query result
    case schedule(tasks: [TaskContext], prayers: [PrayerContext])

    /// Available time query result
    case availableSlots(slots: [TimeSlot])

    /// Schedule analysis with habit suggestions
    case scheduleAnalysis(analysis: ScheduleAnalysis)

    // MARK: - Settings Results

    /// Nawafil toggled
    case nawafilToggled(type: String?, enabled: Bool)

    /// Setting changed
    case settingChanged(key: String, oldValue: String?, newValue: String)

    // MARK: - Clarification

    /// Need more information from user
    case needsClarification(request: ClarificationRequest)

    // MARK: - Prayer Conflict

    /// Scheduling conflicts with prayer time
    case prayerConflict(prayerName: String, suggestedTime: String, pendingTask: ExtractedTaskData?)

    // MARK: - Cannot Fulfill

    /// Cannot fulfill the request
    case cannotFulfill(reason: String, alternative: String?, manualAction: ManualAction?)

    // MARK: - Confirmation Required

    /// Action needs user confirmation before executing
    case confirmationRequired(action: PendingAction)

    // MARK: - Suggestions & Explanations

    /// Suggestions for the user
    case suggestions(_ suggestions: [String])

    /// Explanation text for the user
    case explanation(_ text: String)
}

// MARK: - Schedule Change

/// A single change in schedule rearrangement
struct ScheduleChange: Identifiable {
    let id = UUID()
    let taskTitle: String
    let oldTime: String?
    let newTime: String
    let reason: String?

    var formattedChange: String {
        if let old = oldTime {
            return "\(taskTitle): \(old) ← \(newTime)"
        }
        return "\(taskTitle) ← \(newTime)"
    }
}

// MARK: - Manual Action

/// Action user can take manually if AI cannot fulfill
enum ManualAction: String, Codable {
    case openTimeline = "open_timeline"
    case openInbox = "open_inbox"
    case openSettings = "open_settings"
    case openAddTask = "open_add_task"
    case openPaywall = "open_paywall"

    var buttonTitle: String {
        switch self {
        case .openTimeline: return "فتح الجدول"
        case .openInbox: return "فتح صندوق الوارد"
        case .openSettings: return "فتح الإعدادات"
        case .openAddTask: return "إضافة يدوية"
        case .openPaywall: return "الترقية للنسخة المدفوعة"
        }
    }

    var icon: String {
        switch self {
        case .openTimeline: return "calendar"
        case .openInbox: return "tray.fill"
        case .openSettings: return "gearshape.fill"
        case .openAddTask: return "plus.circle.fill"
        case .openPaywall: return "star.fill"
        }
    }
}

// MARK: - Pending Action

/// An action waiting for user confirmation
struct PendingAction: Identifiable {
    let id = UUID()
    let type: PendingActionType
    let task: TaskContext?
    let description: String
    let affectedItems: [String]
    let isDestructive: Bool

    /// Callback to execute if user confirms
    var confirmCallback: (() -> Void)?

    init(
        type: PendingActionType,
        task: TaskContext? = nil,
        description: String,
        affectedItems: [String] = [],
        isDestructive: Bool = false,
        confirmCallback: (() -> Void)? = nil
    ) {
        self.type = type
        self.task = task
        self.description = description
        self.affectedItems = affectedItems
        self.isDestructive = isDestructive
        self.confirmCallback = confirmCallback
    }
}

enum PendingActionType: String {
    case delete = "delete"
    case edit = "edit"
    case reschedule = "reschedule"
    case rearrange = "rearrange"
    case toggleSetting = "toggle_setting"

    var title: String {
        switch self {
        case .delete: return "حذف المهمة"
        case .edit: return "تعديل المهمة"
        case .reschedule: return "إعادة جدولة"
        case .rearrange: return "إعادة ترتيب الجدول"
        case .toggleSetting: return "تغيير الإعداد"
        }
    }

    var icon: String {
        switch self {
        case .delete: return "trash.fill"
        case .edit: return "pencil"
        case .reschedule: return "calendar.badge.clock"
        case .rearrange: return "arrow.up.arrow.down"
        case .toggleSetting: return "gearshape.fill"
        }
    }

    var confirmButtonTitle: String {
        switch self {
        case .delete: return "حذف"
        case .edit: return "تعديل"
        case .reschedule: return "نقل"
        case .rearrange: return "تطبيق"
        case .toggleSetting: return "تغيير"
        }
    }
}

// MARK: - Result Properties

extension AIActionResult {
    /// Title for the result card
    var title: String {
        switch self {
        case .taskCreated: return "تم إنشاء المهمة"
        case .taskEdited: return "تم تعديل المهمة"
        case .taskDeleted: return "تم حذف المهمة"
        case .taskCompleted: return "تم إكمال المهمة"
        case .taskUncompleted: return "تم إلغاء الإكمال"
        case .taskAlreadyCompleted: return "المهمة مكتملة بالفعل"
        case .taskRescheduled: return "تم نقل المهمة"
        case .taskMovedToInbox: return "تم النقل لصندوق الوارد"
        case .scheduleRearranged: return "تم إعادة ترتيب الجدول"
        case .slotFound: return "وقت متاح"
        case .taskList: return "المهام"
        case .prayerList: return "أوقات الصلاة"
        case .schedule: return "الجدول"
        case .availableSlots: return "الأوقات المتاحة"
        case .scheduleAnalysis: return "تحليل الجدول"
        case .nawafilToggled(_, let enabled): return enabled ? "تم تفعيل النوافل" : "تم تعطيل النوافل"
        case .settingChanged: return "تم تغيير الإعداد"
        case .needsClarification: return "أحتاج توضيح"
        case .prayerConflict: return "تعارض مع وقت الصلاة"
        case .cannotFulfill: return "لا يمكن تنفيذ الطلب"
        case .confirmationRequired(let action): return action.type.title
        case .suggestions: return "اقتراحات"
        case .explanation: return "توضيح"
        }
    }

    /// Icon for the result card
    var icon: String {
        switch self {
        case .taskCreated: return "checkmark.circle.fill"
        case .taskEdited: return "pencil.circle.fill"
        case .taskDeleted: return "trash.circle.fill"
        case .taskCompleted: return "checkmark.circle.fill"
        case .taskUncompleted: return "circle"
        case .taskAlreadyCompleted: return "checkmark.circle"
        case .taskRescheduled: return "calendar.badge.clock"
        case .taskMovedToInbox: return "tray.and.arrow.down.fill"
        case .scheduleRearranged: return "arrow.up.arrow.down.circle.fill"
        case .slotFound: return "clock.fill"
        case .taskList: return "list.bullet"
        case .prayerList: return "moon.stars.fill"
        case .schedule: return "calendar"
        case .availableSlots: return "clock"
        case .scheduleAnalysis: return "chart.bar.doc.horizontal.fill"
        case .nawafilToggled: return "sparkles"
        case .settingChanged: return "gearshape.fill"
        case .needsClarification: return "questionmark.circle.fill"
        case .prayerConflict: return "exclamationmark.circle.fill"
        case .cannotFulfill: return "exclamationmark.triangle.fill"
        case .confirmationRequired(let action): return action.type.icon
        case .suggestions: return "lightbulb.fill"
        case .explanation: return "info.circle.fill"
        }
    }

    /// Whether this result needs user confirmation
    var needsConfirmation: Bool {
        switch self {
        case .confirmationRequired: return true
        case .needsClarification: return true
        case .prayerConflict: return true
        default: return false
        }
    }

    /// Whether this result is a success
    var isSuccess: Bool {
        switch self {
        case .cannotFulfill, .needsClarification, .confirmationRequired, .prayerConflict:
            return false
        default:
            return true
        }
    }

    /// Whether this result should auto-dismiss
    var shouldAutoDismiss: Bool {
        switch self {
        case .taskCreated, .taskCompleted, .taskUncompleted, .taskAlreadyCompleted,
             .settingChanged, .nawafilToggled, .taskMovedToInbox:
            return true
        default:
            return false
        }
    }

    /// Auto-dismiss delay in seconds
    var autoDismissDelay: Double {
        2.0
    }

    /// Confirm button text for confirmation results
    var confirmButtonText: String {
        switch self {
        case .confirmationRequired(let action):
            return action.type.confirmButtonTitle
        default:
            return "تأكيد"
        }
    }
}

// MARK: - Color Properties

extension AIActionResult {
    /// Icon color type for the result
    enum ColorType {
        case success
        case warning
        case error
        case info
        case primary
    }

    var colorType: ColorType {
        switch self {
        case .taskCreated, .taskEdited, .taskCompleted, .taskRescheduled,
             .taskMovedToInbox, .scheduleRearranged, .nawafilToggled, .settingChanged,
             .taskUncompleted, .taskAlreadyCompleted, .slotFound:
            return .success
        case .taskDeleted:
            return .error
        case .needsClarification, .prayerConflict:
            return .warning
        case .cannotFulfill:
            return .error
        case .confirmationRequired(let action):
            return action.isDestructive ? .error : .warning
        case .taskList, .prayerList, .schedule, .availableSlots, .scheduleAnalysis, .suggestions, .explanation:
            return .info
        }
    }
}

// MARK: - Result Builder Helpers

extension AIActionResult {
    /// Create a task created result
    static func created(_ task: TaskContext, showInTimeline: Bool = true) -> AIActionResult {
        .taskCreated(task: task, showInTimeline: showInTimeline)
    }

    /// Create a cannot fulfill result with manual action
    static func cannotDo(_ reason: String, suggest action: ManualAction? = nil, alternative: String? = nil) -> AIActionResult {
        .cannotFulfill(reason: reason, alternative: alternative, manualAction: action)
    }

    /// Create a clarification result
    static func askUser(_ request: ClarificationRequest) -> AIActionResult {
        .needsClarification(request: request)
    }

    /// Create a confirmation required result
    static func confirmBefore(_ action: PendingAction) -> AIActionResult {
        .confirmationRequired(action: action)
    }
}

// MARK: - Pending Action Builders

extension PendingAction {
    /// Create a delete confirmation
    static func deleteTask(title: String, task: TaskContext?, isRecurring: Bool, onConfirm: @escaping () -> Void) -> PendingAction {
        PendingAction(
            type: .delete,
            task: task,
            description: isRecurring
                ? "هل تريد حذف المهمة المتكررة \"\(title)\"؟"
                : "هل تريد حذف المهمة \"\(title)\"؟",
            affectedItems: [title],
            isDestructive: true,
            confirmCallback: onConfirm
        )
    }

    /// Create a reschedule confirmation
    static func rescheduleTask(title: String, task: TaskContext?, from oldTime: String?, to newTime: String, onConfirm: @escaping () -> Void) -> PendingAction {
        let desc = oldTime != nil
            ? "نقل \"\(title)\" من \(oldTime!) إلى \(newTime)؟"
            : "جدولة \"\(title)\" في \(newTime)؟"
        return PendingAction(
            type: .reschedule,
            task: task,
            description: desc,
            affectedItems: [title],
            isDestructive: false,
            confirmCallback: onConfirm
        )
    }

    /// Create a rearrange confirmation
    static func rearrangeSchedule(changes: [ScheduleChange], onConfirm: @escaping () -> Void) -> PendingAction {
        PendingAction(
            type: .rearrange,
            description: "إعادة ترتيب \(changes.count) مهام؟",
            affectedItems: changes.map { $0.taskTitle },
            isDestructive: false,
            confirmCallback: onConfirm
        )
    }
}
