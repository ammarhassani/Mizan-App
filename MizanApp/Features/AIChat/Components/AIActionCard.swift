//
//  AIActionCard.swift
//  Mizan
//
//  Visual cards for AI action results and confirmations
//

import SwiftUI

// MARK: - AI Action Card

struct AIActionCard: View {
    let result: AIActionResult
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?
    var onManualAction: ((ManualAction) -> Void)?

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: MZSpacing.md) {
            // Header
            header

            // Content based on result type
            content

            // Action buttons (if needed)
            if result.needsConfirmation || hasManualAction {
                actionButtons
            }
        }
        .padding(MZSpacing.md)
        .background(themeManager.surfaceColor)
        .cornerRadius(themeManager.cornerRadius(.large))
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                .stroke(borderColor, lineWidth: 1)
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: MZSpacing.sm) {
            // Icon
            Image(systemName: result.icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)

            // Title
            Text(result.title)
                .font(MZTypography.titleMedium)
                .foregroundColor(themeManager.textPrimaryColor)

            Spacer()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch result {
        case .taskCreated(let task, _):
            taskPreview(task)

        case .taskEdited(let task, let changes):
            VStack(alignment: .leading, spacing: MZSpacing.xs) {
                taskPreview(task)
                if !changes.isEmpty {
                    Text("التغييرات: \(changes.joined(separator: "، "))")
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

        case .taskCompleted(let task):
            HStack(spacing: MZSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(themeManager.successColor)
                Text(task.title)
                    .font(MZTypography.bodyLarge)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .strikethrough()
            }

        case .taskRescheduled(let task, let oldTime, let newTime):
            VStack(alignment: .leading, spacing: MZSpacing.xs) {
                taskPreview(task)
                HStack(spacing: MZSpacing.xs) {
                    if let old = oldTime {
                        Text(old)
                            .font(MZTypography.labelMedium)
                            .foregroundColor(themeManager.textSecondaryColor)
                            .strikethrough()
                    }
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondaryColor)
                    if let new = newTime {
                        Text(new)
                            .font(MZTypography.labelMedium)
                            .foregroundColor(themeManager.primaryColor)
                    }
                }
            }

        case .taskMovedToInbox(let task):
            HStack(spacing: MZSpacing.sm) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .foregroundColor(themeManager.primaryColor)
                Text(task.title)
                    .font(MZTypography.bodyLarge)
                    .foregroundColor(themeManager.textPrimaryColor)
            }

        case .scheduleRearranged(let count, let changes):
            scheduleChangesView(count: count, changes: changes)

        case .slotFound(let slot):
            slotView(slot)

        case .taskList(let tasks):
            taskListView(tasks)

        case .prayerList(let prayers):
            prayerListView(prayers)

        case .prayerConflict(let prayerName, let suggestedTime, _):
            prayerConflictView(prayerName: prayerName, suggestedTime: suggestedTime)

        case .confirmationRequired(let action):
            confirmationView(action)

        case .cannotFulfill(let reason, let alternative, _):
            cannotFulfillView(reason: reason, alternative: alternative)

        case .needsClarification:
            EmptyView() // Handled by AIClarificationCard

        case .suggestions(let suggestions):
            suggestionsView(suggestions)

        case .explanation(let text):
            Text(text)
                .font(MZTypography.bodyMedium)
                .foregroundColor(themeManager.textSecondaryColor)
                .multilineTextAlignment(.leading)

        default:
            EmptyView()
        }
    }

    // MARK: - Task Preview

    private func taskPreview(_ task: TaskContext) -> some View {
        HStack(spacing: MZSpacing.sm) {
            // Category color indicator
            Circle()
                .fill(categoryColor(for: task.category))
                .frame(width: 10, height: 10)

            // Task title
            Text(task.title)
                .font(MZTypography.bodyLarge)
                .foregroundColor(themeManager.textPrimaryColor)
                .lineLimit(1)

            Spacer()

            // Time if scheduled
            if let time = task.scheduledTime {
                Text(time)
                    .font(MZTypography.labelMedium)
                    .foregroundColor(themeManager.textSecondaryColor)
            }

            // Duration
            Text("\(task.duration) د")
                .font(MZTypography.labelSmall)
                .foregroundColor(themeManager.textTertiaryColor)
        }
        .padding(MZSpacing.sm)
        .background(themeManager.surfaceSecondaryColor)
        .cornerRadius(themeManager.cornerRadius(.medium))
    }

    // MARK: - Schedule Changes View

    private func scheduleChangesView(count: Int, changes: [ScheduleChange]) -> some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("\(count) مهام سيتم تغييرها")
                .font(MZTypography.labelMedium)
                .foregroundColor(themeManager.textSecondaryColor)

            ForEach(changes.prefix(5)) { change in
                HStack(spacing: MZSpacing.xs) {
                    Text("•")
                        .foregroundColor(themeManager.textSecondaryColor)
                    Text(change.taskTitle)
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(themeManager.textPrimaryColor)
                        .lineLimit(1)
                    Spacer()
                    if let oldTime = change.oldTime {
                        Text(oldTime)
                            .font(MZTypography.labelSmall)
                            .foregroundColor(themeManager.textTertiaryColor)
                            .strikethrough()
                    }
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(themeManager.textTertiaryColor)
                    Text(change.newTime)
                        .font(MZTypography.labelSmall)
                        .foregroundColor(themeManager.primaryColor)
                }
            }

            if changes.count > 5 {
                Text("... و\(changes.count - 5) أخرى")
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textTertiaryColor)
            }
        }
    }

    // MARK: - Slot View

    private func slotView(_ slot: TimeSlot) -> some View {
        HStack(spacing: MZSpacing.md) {
            VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                Text("وقت متاح")
                    .font(MZTypography.labelMedium)
                    .foregroundColor(themeManager.textSecondaryColor)
                Text(slot.formattedRange)
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.primaryColor)
            }

            Spacer()

            Text("\(slot.durationMinutes) دقيقة")
                .font(MZTypography.labelMedium)
                .foregroundColor(themeManager.textSecondaryColor)
                .padding(.horizontal, MZSpacing.sm)
                .padding(.vertical, MZSpacing.xxs)
                .background(themeManager.surfaceSecondaryColor)
                .cornerRadius(themeManager.cornerRadius(.small))
        }
    }

    // MARK: - Task List View

    private func taskListView(_ tasks: [TaskContext]) -> some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            ForEach(tasks.prefix(5), id: \.id) { task in
                HStack(spacing: MZSpacing.xs) {
                    Circle()
                        .fill(categoryColor(for: task.category))
                        .frame(width: 8, height: 8)
                    Text(task.title)
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(themeManager.textPrimaryColor)
                        .lineLimit(1)
                    Spacer()
                    if let time = task.scheduledTime {
                        Text(time)
                            .font(MZTypography.labelSmall)
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }
            }

            if tasks.count > 5 {
                Text("... و\(tasks.count - 5) أخرى")
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textTertiaryColor)
            }

            if tasks.isEmpty {
                Text("لا توجد مهام")
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
        }
    }

    // MARK: - Prayer List View

    private func prayerListView(_ prayers: [PrayerContext]) -> some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            ForEach(prayers, id: \.id) { prayer in
                HStack {
                    Text(prayer.nameArabic)
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(prayer.isPassed ? themeManager.textTertiaryColor : themeManager.textPrimaryColor)
                    Spacer()
                    Text(prayer.formattedTime)
                        .font(MZTypography.labelMedium)
                        .foregroundColor(prayer.isPassed ? themeManager.textTertiaryColor : themeManager.primaryColor)
                }
            }
        }
    }

    // MARK: - Prayer Conflict View

    private func prayerConflictView(prayerName: String, suggestedTime: String) -> some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            HStack(spacing: MZSpacing.xs) {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(themeManager.warningColor)
                Text("هذا الوقت قريب من صلاة \(prayerName)")
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
            }

            HStack(spacing: MZSpacing.xs) {
                Text("الوقت المقترح:")
                    .font(MZTypography.labelMedium)
                    .foregroundColor(themeManager.textSecondaryColor)
                Text(suggestedTime)
                    .font(MZTypography.labelMedium)
                    .foregroundColor(themeManager.primaryColor)
            }
        }
    }

    // MARK: - Confirmation View

    private func confirmationView(_ action: PendingAction) -> some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text(action.description)
                .font(MZTypography.bodyMedium)
                .foregroundColor(themeManager.textPrimaryColor)

            if let task = action.task {
                taskPreview(task)
            }

            if !action.affectedItems.isEmpty && action.task == nil {
                ForEach(action.affectedItems, id: \.self) { item in
                    HStack(spacing: MZSpacing.xs) {
                        Text("•")
                            .foregroundColor(themeManager.textSecondaryColor)
                        Text(item)
                            .font(MZTypography.bodyMedium)
                            .foregroundColor(themeManager.textPrimaryColor)
                    }
                }
            }
        }
    }

    // MARK: - Cannot Fulfill View

    private func cannotFulfillView(reason: String, alternative: String?) -> some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text(reason)
                .font(MZTypography.bodyMedium)
                .foregroundColor(themeManager.textPrimaryColor)

            if let alt = alternative {
                HStack(spacing: MZSpacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.warningColor)
                    Text(alt)
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }
        }
    }

    // MARK: - Suggestions View

    private func suggestionsView(_ suggestions: [String]) -> some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            ForEach(suggestions, id: \.self) { suggestion in
                HStack(spacing: MZSpacing.xs) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.primaryColor)
                    Text(suggestion)
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(themeManager.textPrimaryColor)
                }
            }
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: MZSpacing.sm) {
            // Cancel button
            if result.needsConfirmation {
                Button {
                    onCancel?()
                } label: {
                    Text("إلغاء")
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textSecondaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MZSpacing.sm)
                        .background(themeManager.surfaceSecondaryColor)
                        .cornerRadius(themeManager.cornerRadius(.medium))
                }
            }

            // Confirm/Action button
            if let manualAction = manualActionFromResult {
                Button {
                    onManualAction?(manualAction)
                } label: {
                    HStack(spacing: MZSpacing.xs) {
                        Image(systemName: manualAction.icon)
                        Text(manualAction.buttonTitle)
                    }
                    .font(MZTypography.labelMedium)
                    .foregroundColor(themeManager.textOnPrimaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MZSpacing.sm)
                    .background(themeManager.primaryColor)
                    .cornerRadius(themeManager.cornerRadius(.medium))
                }
            } else if result.needsConfirmation {
                Button {
                    onConfirm?()
                } label: {
                    Text(result.confirmButtonText)
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MZSpacing.sm)
                        .background(confirmButtonColor)
                        .cornerRadius(themeManager.cornerRadius(.medium))
                }
            }
        }
    }

    // MARK: - Helpers

    private var iconColor: Color {
        switch result.colorType {
        case .success: return themeManager.successColor
        case .warning: return themeManager.warningColor
        case .error: return themeManager.errorColor
        case .info: return themeManager.primaryColor
        case .primary: return themeManager.primaryColor
        }
    }

    private var borderColor: Color {
        switch result.colorType {
        case .success: return themeManager.successColor.opacity(0.3)
        case .warning: return themeManager.warningColor.opacity(0.3)
        case .error: return themeManager.errorColor.opacity(0.3)
        case .info, .primary: return themeManager.primaryColor.opacity(0.2)
        }
    }

    private var confirmButtonColor: Color {
        switch result.colorType {
        case .error: return themeManager.errorColor
        case .warning: return themeManager.warningColor
        default: return themeManager.primaryColor
        }
    }

    private var hasManualAction: Bool {
        manualActionFromResult != nil
    }

    private var manualActionFromResult: ManualAction? {
        if case .cannotFulfill(_, _, let action) = result {
            return action
        }
        return nil
    }

    private func categoryColor(for category: String) -> Color {
        let taskCategory = TaskCategory(rawValue: category) ?? .personal
        return Color(hex: taskCategory.defaultColorHex)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AIActionCard(
            result: .taskCreated(
                task: TaskContext(
                    id: "1",
                    title: "دراسة الفصل الخامس",
                    duration: 45,
                    category: "study",
                    icon: "book.fill",
                    scheduledTime: "2:00 م"
                ),
                showInTimeline: true
            )
        )

        AIActionCard(
            result: .cannotFulfill(
                reason: "لم أجد مهمة بهذا الاسم",
                alternative: "تأكد من اسم المهمة",
                manualAction: .openTimeline
            )
        )
    }
    .padding()
    .background(ThemeManager().surfaceSecondaryColor)
    .environmentObject(ThemeManager())
}
