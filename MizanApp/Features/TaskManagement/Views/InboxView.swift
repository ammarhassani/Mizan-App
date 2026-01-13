//
//  InboxView.swift
//  Mizan
//
//  Inbox view for managing unscheduled tasks
//

import SwiftUI
import SwiftData

struct InboxView: View {
    // MARK: - Environment
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries
    @Query(
        filter: #Predicate<Task> { task in
            task.scheduledStartTime == nil && !task.isCompleted
        },
        sort: \Task.createdAt,
        order: .reverse
    ) private var inboxTasks: [Task]

    @Query(
        filter: #Predicate<Task> { task in
            task.isCompleted
        },
        sort: \Task.completedAt,
        order: .reverse
    ) private var completedTasks: [Task]

    // MARK: - State
    @State private var showAddTaskSheet = false
    @State private var showCompletedTasks = false
    @State private var selectedTask: Task?
    @State private var showScheduleSheet = false
    @State private var taskToSchedule: Task?

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                themeManager.backgroundColor
                    .ignoresSafeArea()

                if inboxTasks.isEmpty && !showCompletedTasks {
                    emptyStateView
                } else {
                    taskListView
                }

                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingActionButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("قائمة المهام")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !completedTasks.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showCompletedTasks.toggle()
                            }
                        } label: {
                            Image(systemName: showCompletedTasks ? "checkmark.circle.fill" : "checkmark.circle")
                                .foregroundColor(themeManager.primaryColor)
                        }
                    }
                }
            }
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

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tray")
                .font(.system(size: 80))
                .foregroundColor(themeManager.textSecondaryColor)

            VStack(spacing: 8) {
                Text("لا توجد مهام")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(themeManager.textPrimaryColor)

                Text("اضغط + لإضافة مهمة جديدة")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.textSecondaryColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Task List

    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if !showCompletedTasks {
                    // Inbox tasks
                    ForEach(inboxTasks) { task in
                        TaskRow(task: task)
                            .environmentObject(themeManager)
                            .onTapGesture {
                                selectedTask = task
                                showAddTaskSheet = true
                            }
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
                                .tint(.green)
                            }
                    }
                } else {
                    // Completed tasks
                    ForEach(completedTasks.prefix(50)) { task in
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
                    }

                    if completedTasks.count > 50 {
                        Text("عرض آخر 50 مهمة مكتملة")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.textSecondaryColor)
                            .padding()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 80) // Space for FAB
        }
    }

    // MARK: - Floating Action Button

    private var floatingActionButton: some View {
        Button {
            selectedTask = nil
            showAddTaskSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(themeManager.primaryColor)
                        .shadow(
                            color: themeManager.primaryColor.opacity(0.4),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                )
        }
        .onTapWithHaptic {
            selectedTask = nil
            showAddTaskSheet = true
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

// MARK: - Task Row

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
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
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
