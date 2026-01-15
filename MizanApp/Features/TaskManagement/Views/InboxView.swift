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
    @State private var selectedTask: Task?
    @State private var showScheduleSheet = false
    @State private var taskToSchedule: Task?

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
        [
            .all: allTasks.filter { !$0.isCompleted }.count,
            .inbox: allTasks.filter { $0.scheduledStartTime == nil && !$0.isCompleted }.count,
            .scheduled: allTasks.filter { $0.scheduledStartTime != nil && !$0.isCompleted }.count,
            .overdue: allTasks.filter { $0.isOverdue }.count,
            .completed: allTasks.filter { $0.isCompleted }.count
        ]
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
                        EnhancedFAB {
                            selectedTask = nil
                            showAddTaskSheet = true
                        }
                        .environmentObject(themeManager)
                        .padding(.trailing, MZSpacing.screenPadding)
                        .padding(.bottom, MZSpacing.screenPadding)
                    }
                }
            }
            .navigationTitle("المهام")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddTaskSheet) {
                AddTaskSheet(task: selectedTask)
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
            .flipsForRightToLeftLayoutDirection(true)
        }
        // Removed: .environment(\.layoutDirection, .rightToLeft) - was causing text inversion
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
                    selectedTask = nil
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
            LazyVStack(spacing: 12) {
                ForEach(filteredTasks) { task in
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
                                selectedTask = task
                                showAddTaskSheet = true
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

                if selectedFilter == .completed && allTasks.filter({ $0.isCompleted }).count > 50 {
                    Text("عرض آخر 50 مهمة مكتملة")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textSecondaryColor)
                        .padding()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 80) // Space for FAB
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func taskContextMenu(for task: Task) -> some View {
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

    private func deleteTask(_ task: Task) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            modelContext.delete(task)
            try? modelContext.save()
        }
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

            // Task content (tappable for editing)
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Category icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: task.colorHex).opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: task.category.icon)
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
                                Text("\(task.duration) د")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(themeManager.textSecondaryColor)

                            // Scheduled time indicator
                            if let scheduledTime = task.scheduledStartTime {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 11))
                                    Text(scheduledTime.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(themeManager.primaryColor)
                            }

                            // Due date indicator
                            if let dueDate = task.dueDate {
                                HStack(spacing: 4) {
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: 11))
                                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(task.isOverdue ? themeManager.errorColor : (task.isDueSoon ? themeManager.warningColor : themeManager.textSecondaryColor))
                            }

                            if task.recurrenceRule != nil {
                                Image(systemName: "repeat")
                                    .font(.system(size: 11))
                                    .foregroundColor(themeManager.primaryColor)
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
            color: Color.black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Task Row (Legacy)

struct TaskRow: View {
    let task: Task

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(Color(hex: task.colorHex).opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: task.category.icon)
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
                        Text("\(task.duration) د")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(themeManager.textSecondaryColor)

                    // Category
                    Text(task.category.nameArabic)
                        .font(.system(size: 14))
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
            color: Color.black.opacity(0.05),
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
            color: Color.black.opacity(0.03),
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
                                .foregroundColor(.orange)
                            Text("يتعارض هذا الوقت مع وقت صلاة")
                                .font(.system(size: 15))
                                .foregroundColor(.orange)
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
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .listRowBackground(
                        (hasConflict ? Color.orange : themeManager.primaryColor)
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
