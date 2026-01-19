//
//  InboxView.swift
//  Mizan
//
//  Comprehensive task viewer with filter chips
//

import SwiftUI
import SwiftData

// MARK: - Task Filter

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "الكل"
    case inbox = "صندوق الوارد"
    case scheduled = "مجدولة"
    case overdue = "متأخرة"
    case completed = "مكتملة"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "tray.full.fill"
        case .inbox: return "tray.fill"
        case .scheduled: return "calendar"
        case .overdue: return "exclamationmark.circle.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

struct InboxView: View {
    // MARK: - Environment
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries (fetch all tasks)
    @Query(sort: \Task.createdAt, order: .reverse) private var allTasks: [Task]

    // MARK: - State
    @State private var selectedFilter: TaskFilter = .inbox
    @State private var showAddTaskSheet = false
    @State private var showAIChatSheet = false
    @State private var taskToEdit: Task? = nil
    @State private var showScheduleSheet = false
    @State private var taskToSchedule: Task?

    // MARK: - Recurring Task Confirmation
    @State private var showRecurringDeleteConfirmation = false
    @State private var taskToDelete: Task? = nil
    @State private var showRecurringEditConfirmation = false
    @State private var taskPendingEdit: Task? = nil
    @State private var editThisInstanceOnly = false

    // MARK: - Filtered Tasks

    private var filteredTasks: [Task] {
        switch selectedFilter {
        case .all:
            return allTasks.filter { !$0.isCompleted }
        case .inbox:
            return allTasks.filter { $0.scheduledStartTime == nil && !$0.isCompleted }
        case .scheduled:
            return allTasks.filter { $0.scheduledStartTime != nil && !$0.isCompleted }
        case .overdue:
            return allTasks.filter { $0.isOverdue }
        case .completed:
            return allTasks.filter { $0.isCompleted }.prefix(50).map { $0 }
        }
    }

    private var taskCounts: [TaskFilter: Int] {
        // Only count parent/standalone tasks, not recurring instances
        let parentTasks = allTasks.filter { $0.parentTaskId == nil }
        return [
            .all: parentTasks.filter { !$0.isCompleted }.count,
            .inbox: parentTasks.filter { $0.scheduledStartTime == nil && !$0.isCompleted }.count,
            .scheduled: parentTasks.filter { $0.scheduledStartTime != nil && !$0.isCompleted }.count,
            .overdue: parentTasks.filter { $0.isOverdue }.count,
            .completed: parentTasks.filter { $0.isCompleted }.count
        ]
    }

    // MARK: - Grouped Tasks by Date

    /// Groups tasks by their scheduled date - only today, tomorrow, day after tomorrow, and unscheduled
    private var groupedTasks: [(date: Date?, tasks: [Task])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let dayAfter = calendar.date(byAdding: .day, value: 2, to: today)!

        // Group tasks by date
        var grouped: [Date?: [Task]] = [:]

        for task in filteredTasks {
            let dateKey: Date?
            if let scheduledTime = task.scheduledStartTime {
                let taskDay = calendar.startOfDay(for: scheduledTime)

                // Only include today, tomorrow, or day after tomorrow
                if calendar.isDate(taskDay, inSameDayAs: today) ||
                   calendar.isDate(taskDay, inSameDayAs: tomorrow) ||
                   calendar.isDate(taskDay, inSameDayAs: dayAfter) {
                    dateKey = taskDay
                } else {
                    // Skip tasks from other dates
                    continue
                }
            } else {
                // Unscheduled tasks go under nil key
                dateKey = nil
            }

            if grouped[dateKey] == nil {
                grouped[dateKey] = []
            }
            grouped[dateKey]?.append(task)
        }

        // Sort groups: today first, then tomorrow, then day after, nil (unscheduled) last
        let sortedGroups = grouped.sorted { lhs, rhs in
            // nil (unscheduled) goes last
            guard let lhsDate = lhs.key else { return false }
            guard let rhsDate = rhs.key else { return true }

            // Sort by date (today → tomorrow → day after)
            return lhsDate < rhsDate
        }

        // Sort tasks within each group by time
        return sortedGroups.map { (date: $0.key, tasks: $0.value.sorted { lhs, rhs in
            let lhsTime = lhs.scheduledStartTime ?? lhs.createdAt
            let rhsTime = rhs.scheduledStartTime ?? rhs.createdAt
            return lhsTime < rhsTime
        })}
    }

    /// Formats a date for section header
    private func formatDateHeader(_ date: Date?) -> String {
        guard let date = date else {
            return "غير مجدول"  // "Unscheduled"
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if calendar.isDate(date, inSameDayAs: today) {
            return "اليوم"  // "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: today)!) {
            return "غداً"  // "Tomorrow"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 2, to: today)!) {
            return "بعد غد"  // "Day after tomorrow"
        } else {
            // Use full date formatting for other dates
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ar")
            formatter.dateStyle = .full
            return formatter.string(from: date)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                themeManager.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter chips
                    filterChipsView

                    if filteredTasks.isEmpty {
                        // Empty state
                        emptyStateView
                    } else {
                        taskListView
                    }
                }

                // Enhanced Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        EnhancedFAB(
                            action: {
                                showAddTaskSheet = true
                            },
                            onLongPress: {
                                showAIChatSheet = true
                            }
                        )
                        .environmentObject(themeManager)
                        .accessibilityIdentifier("inbox_add_task_fab")
                        .padding(.trailing, MZSpacing.screenPadding)
                        .padding(.bottom, MZSpacing.screenPadding)
                    }
                }
            }
            .navigationTitle("المهام")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddTaskSheet) {
                AddTaskSheet(task: nil)
                    .environmentObject(appEnvironment)
                    .environmentObject(themeManager)
            }
            .sheet(item: $taskToEdit) { task in
                AddTaskSheet(task: task)
                    .environmentObject(appEnvironment)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showScheduleSheet) {
                if let task = taskToSchedule {
                    ScheduleTaskSheet(task: task)
                        .environmentObject(appEnvironment)
                        .environmentObject(themeManager)
                }
            }
            .sheet(isPresented: $showAIChatSheet) {
                AIChatSheet { createdTask in
                    // Task was created from AI, optionally scroll to it or show feedback
                    HapticManager.shared.trigger(.success)
                }
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
            }
            .confirmationDialog(
                "حذف المهمة المتكررة",
                isPresented: $showRecurringDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("حذف هذه المرة فقط", role: .destructive) {
                    if let task = taskToDelete {
                        deleteThisInstanceOnly(task)
                    }
                }
                Button("حذف جميع التكرارات", role: .destructive) {
                    if let task = taskToDelete {
                        deleteAllInstances(task)
                    }
                }
                Button("إلغاء", role: .cancel) {
                    taskToDelete = nil
                }
            } message: {
                Text("هل تريد حذف هذه المرة فقط أم جميع تكرارات المهمة؟")
            }
            .confirmationDialog(
                "تعديل المهمة المتكررة",
                isPresented: $showRecurringEditConfirmation,
                titleVisibility: .visible
            ) {
                Button("تعديل هذه المرة فقط") {
                    if let task = taskPendingEdit {
                        editThisInstanceOnly = true
                        taskToEdit = task
                    }
                    taskPendingEdit = nil
                }
                Button("تعديل جميع التكرارات") {
                    if let task = taskPendingEdit {
                        editThisInstanceOnly = false
                        taskToEdit = task
                    }
                    taskPendingEdit = nil
                }
                Button("إلغاء", role: .cancel) {
                    taskPendingEdit = nil
                }
            } message: {
                Text("هل تريد تعديل هذه المرة فقط أم جميع تكرارات المهمة؟")
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MZSpacing.sm) {
                ForEach(TaskFilter.allCases) { filter in
                    FilterChip(
                        filter: filter,
                        count: taskCounts[filter] ?? 0,
                        isSelected: selectedFilter == filter,
                        action: {
                            withAnimation(MZAnimation.snappy) {
                                selectedFilter = filter
                            }
                            HapticManager.shared.trigger(.selection)
                        }
                    )
                    .environmentObject(themeManager)
                }
            }
            .padding(.horizontal, MZSpacing.screenPadding)
            .padding(.vertical, MZSpacing.sm)
        }
        // Removed: .flipsForRightToLeftLayoutDirection + .environment(\.layoutDirection) - was causing text inversion
        .background(themeManager.backgroundColor)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: MZSpacing.lg) {
            Spacer()

            Image(systemName: selectedFilter.icon)
                .font(.system(size: 60))
                .foregroundColor(themeManager.textTertiaryColor)

            Text(emptyStateMessage)
                .font(MZTypography.titleMedium)
                .foregroundColor(themeManager.textSecondaryColor)
                .multilineTextAlignment(.center)

            if selectedFilter != .completed {
                Button {
                    showAddTaskSheet = true
                } label: {
                    Text("إضافة مهمة جديدة")
                        .font(MZTypography.labelLarge)
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .padding(.horizontal, MZSpacing.lg)
                        .padding(.vertical, MZSpacing.sm)
                        .background(
                            Capsule()
                                .fill(themeManager.primaryColor)
                        )
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityIdentifier("inbox_empty_state_add_button")
            }

            Spacer()
        }
        .padding()
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all: return "لا توجد مهام"
        case .inbox: return "صندوق الوارد فارغ"
        case .scheduled: return "لا توجد مهام مجدولة"
        case .overdue: return "لا توجد مهام متأخرة 🎉"
        case .completed: return "لا توجد مهام مكتملة"
        }
    }

    // MARK: - Task List

    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(groupedTasks.enumerated()), id: \.offset) { index, group in
                    // Date section header
                    dateSectionHeader(date: group.date, taskCount: group.tasks.count)

                    // Tasks in this section
                    LazyVStack(spacing: 10) {
                        ForEach(group.tasks) { task in
                            taskRow(for: task)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                if selectedFilter == .completed && allTasks.filter({ $0.isCompleted }).count > 50 {
                    Text("عرض آخر 50 مهمة مكتملة")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textSecondaryColor)
                        .padding()
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 80) // Space for FAB
        }
    }

    // MARK: - Date Section Header

    private func dateSectionHeader(date: Date?, taskCount: Int) -> some View {
        HStack(spacing: 8) {
            // Date icon
            Image(systemName: date == nil ? "tray" : "calendar")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isDateToday(date) ? themeManager.primaryColor : themeManager.textSecondaryColor)

            // Date text
            Text(formatDateHeader(date))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(isDateToday(date) ? themeManager.primaryColor : themeManager.textPrimaryColor)

            // Task count badge
            Text("\(taskCount)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.textSecondaryColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(themeManager.surfaceSecondaryColor)
                )

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeManager.backgroundColor)
    }

    private func isDateToday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return Calendar.current.isDateInToday(date)
    }

    // MARK: - Task Row

    @ViewBuilder
    private func taskRow(for task: Task) -> some View {
        if selectedFilter == .completed {
            // Completed task row
            CompletedTaskRow(task: task)
                .environmentObject(themeManager)
                .onTapGesture {
                    uncompleteTask(task)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteTask(task)
                    } label: {
                        Label("حذف", systemImage: "trash")
                    }
                }
        } else {
            // Active task row with tappable checkbox
            TaskRowWithCheckbox(
                task: task,
                onToggleComplete: {
                    completeTask(task)
                },
                onTap: {
                    editTask(task)
                }
            )
            .environmentObject(themeManager)
            .contextMenu {
                taskContextMenu(for: task)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    scheduleTask(task)
                } label: {
                    Label("جدولة", systemImage: "calendar.badge.plus")
                }
                .tint(themeManager.primaryColor)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    deleteTask(task)
                } label: {
                    Label("حذف", systemImage: "trash")
                }

                Button {
                    completeTask(task)
                } label: {
                    Label("تم", systemImage: "checkmark")
                }
                .tint(themeManager.successColor)
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func taskContextMenu(for task: Task) -> some View {
        Button {
            editTask(task)
        } label: {
            Label("تعديل", systemImage: "pencil")
        }

        Button {
            scheduleTask(task)
        } label: {
            Label("جدولة على الجدول", systemImage: "calendar.badge.plus")
        }

        Button {
            completeTask(task)
        } label: {
            Label("وضع علامة مكتمل", systemImage: "checkmark.circle")
        }

        Button {
            duplicateTask(task)
        } label: {
            Label("تكرار", systemImage: "doc.on.doc")
        }

        Divider()

        Button(role: .destructive) {
            deleteTask(task)
        } label: {
            Label("حذف", systemImage: "trash")
        }
    }

    // MARK: - Actions

    private func scheduleTask(_ task: Task) {
        taskToSchedule = task
        showScheduleSheet = true
        HapticManager.shared.trigger(.success)
    }

    private func completeTask(_ task: Task) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            task.complete()
            try? modelContext.save()
        }
        HapticManager.shared.trigger(.success)
    }

    private func uncompleteTask(_ task: Task) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            task.uncomplete()
            try? modelContext.save()
        }
        HapticManager.shared.trigger(.success)
    }

    /// Edit a task - shows confirmation for recurring tasks
    private func editTask(_ task: Task) {
        // Check if this is a recurring task (has parent or has recurrence rule)
        let isRecurringTask = task.parentTaskId != nil || task.recurrenceRule != nil

        if isRecurringTask {
            // Show confirmation dialog for recurring tasks
            taskPendingEdit = task
            showRecurringEditConfirmation = true
        } else {
            // Regular task - edit directly
            taskToEdit = task
        }
    }

    private func deleteTask(_ task: Task) {
        // Check if this is a recurring task (has parent or has recurrence rule)
        let isRecurringTask = task.parentTaskId != nil || task.recurrenceRule != nil

        if isRecurringTask {
            // Show confirmation dialog
            taskToDelete = task
            showRecurringDeleteConfirmation = true
        } else {
            // Regular task - delete directly
            deleteNonRecurringTask(task)
        }
    }

    /// Delete a non-recurring task directly
    private func deleteNonRecurringTask(_ task: Task) {
        modelContext.delete(task)
        try? modelContext.save()
        HapticManager.shared.trigger(.warning)
    }

    /// Delete only this instance of a recurring task
    private func deleteThisInstanceOnly(_ task: Task) {
        // If this is a child instance, mark the date as dismissed on parent
        if let parentId = task.parentTaskId, let scheduledDate = task.scheduledDate {
            let descriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == parentId })
            if let parentTask = try? modelContext.fetch(descriptor).first {
                parentTask.dismissRecurringInstance(for: scheduledDate)
            }
        }
        // If this is a parent task, just dismiss the date (don't delete the parent)
        else if task.recurrenceRule != nil, let scheduledDate = task.scheduledDate {
            task.dismissRecurringInstance(for: scheduledDate)
            // Don't delete the parent - just save the dismissal and return
            try? modelContext.save()
            taskToDelete = nil
            HapticManager.shared.trigger(.warning)
            return
        }

        // Delete the instance
        modelContext.delete(task)
        try? modelContext.save()
        taskToDelete = nil
        HapticManager.shared.trigger(.warning)
    }

    /// Delete all instances of a recurring task (parent + all children)
    private func deleteAllInstances(_ task: Task) {
        // Find the parent task ID
        let parentId: UUID
        if let pid = task.parentTaskId {
            // This is a child instance - get parent ID
            parentId = pid
        } else {
            // This is the parent task itself
            parentId = task.id
        }

        // Find all tasks with this parentTaskId (children)
        let childDescriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.parentTaskId == parentId })
        let childTasks = (try? modelContext.fetch(childDescriptor)) ?? []

        // Find and delete the parent task
        let parentDescriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == parentId })
        if let parentTask = try? modelContext.fetch(parentDescriptor).first {
            modelContext.delete(parentTask)
        }

        // Delete all child instances
        for child in childTasks {
            modelContext.delete(child)
        }

        // Also delete the current task if it wasn't already deleted
        if task.parentTaskId == nil && task.id != parentId {
            modelContext.delete(task)
        }

        try? modelContext.save()
        taskToDelete = nil
        HapticManager.shared.trigger(.warning)
    }

    private func duplicateTask(_ task: Task) {
        let duplicate = Task(
            title: task.title + " (نسخة)",
            duration: task.duration,
            category: task.category,
            notes: task.notes
        )
        modelContext.insert(duplicate)
        try? modelContext.save()
        HapticManager.shared.trigger(.success)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let filter: TaskFilter
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: MZSpacing.xs) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14))
                Text(filter.rawValue)
                    .font(MZTypography.labelMedium)
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? themeManager.primaryColor : themeManager.textOnPrimaryColor)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(
                            Circle()
                                .fill(isSelected ? themeManager.surfaceColor : themeManager.primaryColor.opacity(0.6))
                        )
                }
            }
            .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
            .padding(.horizontal, MZSpacing.md)
            .padding(.vertical, MZSpacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityIdentifier("inbox_filter_chip_\(filter.rawValue)")
    }
}

// MARK: - Task Row with Checkbox

struct TaskRowWithCheckbox: View {
    let task: Task
    let onToggleComplete: () -> Void
    let onTap: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            // Tappable checkbox
            Button {
                onToggleComplete()
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color(hex: task.colorHex), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if task.isCompleted {
                        Circle()
                            .fill(themeManager.successColor)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(themeManager.textOnPrimaryColor)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("task_checkbox_\(task.id.uuidString)")

            // Task content (tappable for editing)
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Task icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: task.colorHex).opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: task.icon)
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: task.colorHex))
                    }

                    // Task info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.textPrimaryColor)
                            .lineLimit(2)

                        HStack(spacing: 12) {
                            // Duration
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 11))
                                Text(task.duration.formattedDuration)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(themeManager.textSecondaryColor)

                            // Recurrence type indicator
                            if let rule = task.recurrenceRule {
                                HStack(spacing: 4) {
                                    Image(systemName: "repeat")
                                        .font(.system(size: 11))
                                    Text(recurrenceTypeArabic(rule.frequency))
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(themeManager.primaryColor)
                            }

                            // Due date indicator
                            if let dueDate = task.dueDate {
                                HStack(spacing: 4) {
                                    Image(systemName: task.isOverdue ? "exclamationmark.circle.fill" : "flag.fill")
                                        .font(.system(size: 11))
                                    Text(formatDueDate(dueDate))
                                        .font(.system(size: 13))
                                    // Add overdue text label for accessibility
                                    if task.isOverdue {
                                        Text("متأخرة")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                }
                                .foregroundColor(task.isOverdue ? themeManager.errorColor : (task.isDueSoon ? themeManager.warningColor : themeManager.textSecondaryColor))
                            }

                            // Scheduled time (just time, not full date)
                            if let scheduledTime = task.scheduledStartTime {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 11))
                                    Text(scheduledTime.formatted(date: .omitted, time: .shortened))
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(themeManager.textTertiaryColor)
                            }
                        }
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textTertiaryColor)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(themeManager.surfaceColor)
        .cornerRadius(themeManager.cornerRadius(.medium))
        .shadow(
            color: themeManager.overlayColor.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )
    }

    // MARK: - Helper Functions

    /// Converts recurrence frequency to Arabic text
    private func recurrenceTypeArabic(_ frequency: RecurrenceRule.Frequency) -> String {
        switch frequency {
        case .daily:
            return "يومي"
        case .weekly:
            return "أسبوعي"
        case .monthly:
            return "شهري"
        }
    }

    /// Formats due date in a user-friendly way
    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if calendar.isDate(date, inSameDayAs: today) {
            return "اليوم " + date.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: today)!) {
            return "غداً " + date.formatted(date: .omitted, time: .shortened)
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ar")
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Task Row (Legacy)

struct TaskRow: View {
    let task: Task

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            // Task icon
            ZStack {
                Circle()
                    .fill(Color(hex: task.colorHex).opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: task.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: task.colorHex))
            }

            // Task info
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(themeManager.textPrimaryColor)
                    .lineLimit(2)

                HStack(spacing: 16) {
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(task.duration.formattedDuration)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(themeManager.textSecondaryColor)

                    if task.recurrenceRule != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 12))
                            Text("متكرر")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(themeManager.primaryColor)
                    }
                }
            }

            Spacer()

            // Drag indicator
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16))
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .padding(16)
        .background(themeManager.surfaceColor)
        .cornerRadius(themeManager.cornerRadius(.medium))
        .shadow(
            color: themeManager.overlayColor.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Completed Task Row

struct CompletedTaskRow: View {
    let task: Task

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            // Checkmark icon
            ZStack {
                Circle()
                    .fill(themeManager.successColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.successColor)
            }

            // Task info
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(themeManager.textSecondaryColor)
                    .strikethrough()
                    .lineLimit(2)

                if let completedAt = task.completedAt {
                    Text("اكتمل \(completedAt.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(themeManager.surfaceColor.opacity(0.6))
        .cornerRadius(themeManager.cornerRadius(.medium))
        .shadow(
            color: themeManager.overlayColor.opacity(0.03),
            radius: 2,
            x: 0,
            y: 1
        )
    }
}

// MARK: - Schedule Task Sheet

struct ScheduleTaskSheet: View {
    let task: Task

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    @Query private var allPrayers: [PrayerTime]

    @State private var selectedDate = Date()
    @State private var selectedTime = Date()

    private var todayPrayers: [PrayerTime] {
        let calendar = Calendar.current
        return allPrayers.filter { prayer in
            calendar.isDate(prayer.date, inSameDayAs: selectedDate)
        }
    }

    private var hasConflict: Bool {
        let startTime = combinedDateTime
        return todayPrayers.contains { prayer in
            prayer.overlaps(with: startTime, duration: task.duration)
        }
    }

    private var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? Date()
    }

    var body: some View {
        NavigationView {
            Form {
                Section("التاريخ") {
                    DatePicker(
                        "اختر التاريخ",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                }

                Section("الوقت") {
                    DatePicker(
                        "اختر الوقت",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                }

                if hasConflict {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(themeManager.warningColor)
                            Text("يتعارض هذا الوقت مع وقت صلاة")
                                .font(.system(size: 15))
                                .foregroundColor(themeManager.warningColor)
                        }
                    }
                }

                Section {
                    Button {
                        scheduleTask()
                    } label: {
                        HStack {
                            Spacer()
                            Text(hasConflict ? "جدولة على أي حال" : "جدولة")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(themeManager.textOnPrimaryColor)
                            Spacer()
                        }
                    }
                    .listRowBackground(
                        (hasConflict ? themeManager.warningColor : themeManager.primaryColor)
                            .cornerRadius(8)
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("جدولة المهمة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func scheduleTask() {
        let scheduledTime = combinedDateTime

        // Round to nearest 15 minutes
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledTime)
        let minute = components.minute ?? 0
        let roundedMinute = (minute / 15) * 15

        var roundedComponents = components
        roundedComponents.minute = roundedMinute

        if let rounded = calendar.date(from: roundedComponents) {
            task.scheduleAt(time: rounded)
            try? modelContext.save()
        }

        HapticManager.shared.trigger(.success)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    InboxView()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
        .modelContainer(AppEnvironment.preview().modelContainer)
}
