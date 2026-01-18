//
//  AddTaskSheet.swift
//  Mizan
//
//  Two-step task creation flow (Structured-style)
//  Step 1: Title + Intelligent Icon + Suggestions
//  Step 2: Date, Time, Duration scheduling
//

import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    var task: Task? // nil for new task, non-nil for editing

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    // MARK: - Step State

    enum Step {
        case step1 // Title + Icon
        case step2 // Scheduling
    }

    @State private var currentStep: Step = .step1

    // MARK: - Form State

    @State private var title = ""
    @State private var icon = "circle.fill"
    @State private var duration = 30
    @State private var selectedCategory: TaskCategory = .personal
    @State private var notes = ""
    @State private var enableRecurrence = false
    @State private var recurrenceFrequency: RecurrenceRule.Frequency = .daily
    @State private var recurrenceDays: [Int] = []
    @State private var scheduledDate = Date()
    @State private var scheduledTime = Date()

    // MARK: - UI State

    @State private var showRecurringDeleteConfirmation = false

    // MARK: - Computed Properties

    private var isEditing: Bool {
        task != nil
    }

    private var isPro: Bool {
        appEnvironment.userSettings.isPro
    }

    // MARK: - Initialization

    init(task: Task? = nil) {
        self.task = task

        if let task = task {
            _title = State(initialValue: task.title)
            _icon = State(initialValue: task.icon)
            _duration = State(initialValue: task.duration)
            _selectedCategory = State(initialValue: task.category)
            _notes = State(initialValue: task.notes ?? "")
            _enableRecurrence = State(initialValue: task.recurrenceRule != nil)
            // For editing, skip to step 2
            _currentStep = State(initialValue: .step2)

            if let rule = task.recurrenceRule {
                _recurrenceFrequency = State(initialValue: rule.frequency)
                if let days = rule.daysOfWeek {
                    _recurrenceDays = State(initialValue: days)
                }
            }

            if let scheduledStart = task.scheduledStartTime {
                _scheduledDate = State(initialValue: scheduledStart)
                _scheduledTime = State(initialValue: scheduledStart)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()

                switch currentStep {
                case .step1:
                    step1View

                case .step2:
                    step2View
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if currentStep == .step2 && !isEditing {
                            // Go back to step 1
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentStep = .step1
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: currentStep == .step2 && !isEditing ? "chevron.left" : "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.textOnPrimaryColor)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(themeManager.textOnPrimaryColor.opacity(0.15))
                            )
                            .contentShape(Circle())
                    }
                    .accessibilityLabel(currentStep == .step2 && !isEditing ? "رجوع" : "إغلاق")
                    .accessibilityHint(currentStep == .step2 && !isEditing ? "العودة للخطوة السابقة" : "إغلاق النموذج")
                }

                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            handleDeleteTapped()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(themeManager.errorColor)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("حذف المهمة")
                        .accessibilityHint("اضغط لحذف هذه المهمة")
                    }
                }
            }
            .confirmationDialog(
                "Delete Recurring Task",
                isPresented: $showRecurringDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete this instance only", role: .destructive) {
                    deleteThisInstanceOnly()
                }
                Button("Delete all instances", role: .destructive) {
                    deleteAllInstances()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Do you want to delete only this instance or all recurring instances?")
            }
        }
    }

    // MARK: - Step 1 View

    private var step1View: some View {
        TaskCreationStep1View(
            title: $title,
            icon: $icon,
            duration: $duration,
            scheduledTime: $scheduledTime,
            onContinue: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentStep = .step2
                }
            },
            onSelectSuggestion: { _ in
                // Auto-continue to step 2 when suggestion selected
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentStep = .step2
                }
            }
        )
        .environmentObject(themeManager)
    }

    // MARK: - Step 2 View

    private var step2View: some View {
        TaskCreationStep2View(
            title: $title,
            icon: $icon,
            duration: $duration,
            scheduledDate: $scheduledDate,
            scheduledTime: $scheduledTime,
            notes: $notes,
            enableRecurrence: $enableRecurrence,
            recurrenceFrequency: $recurrenceFrequency,
            recurrenceDays: $recurrenceDays,
            isEditing: isEditing,
            isPro: isPro,
            onSave: {
                saveTask()
            },
            onBack: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentStep = .step1
                }
            },
            onAddToInbox: {
                saveToInbox()
            }
        )
        .environmentObject(themeManager)
        .environmentObject(appEnvironment)
    }

    // MARK: - Save Task

    private func saveTask() {
        let combinedTime = combineDateAndTime()

        if let existingTask = task {
            // Update existing task
            existingTask.title = title
            existingTask.icon = icon
            existingTask.duration = duration
            existingTask.notes = notes.isEmpty ? nil : notes
            existingTask.scheduledStartTime = combinedTime
            existingTask.scheduledDate = Calendar.current.startOfDay(for: combinedTime)
            existingTask.updatedAt = Date()

            // Handle recurrence
            if enableRecurrence && isPro {
                existingTask.recurrenceRule = RecurrenceRule(
                    frequency: recurrenceFrequency,
                    daysOfWeek: recurrenceFrequency == .weekly ? recurrenceDays : nil
                )
                existingTask.isRecurring = true
            } else {
                existingTask.recurrenceRule = nil
                existingTask.isRecurring = false
            }

            // Reschedule notifications
            appEnvironment.notificationManager.removeTaskNotifications(for: existingTask)
            _Concurrency.Task {
                await appEnvironment.notificationManager.scheduleTaskNotification(for: existingTask, userSettings: appEnvironment.userSettings)
            }
        } else {
            // Create new task
            let newTask = Task(
                title: title,
                duration: duration,
                category: selectedCategory,
                icon: icon,
                notes: notes.isEmpty ? nil : notes
            )
            newTask.scheduledStartTime = combinedTime
            newTask.scheduledDate = Calendar.current.startOfDay(for: combinedTime)

            // Handle recurrence
            if enableRecurrence && isPro {
                newTask.recurrenceRule = RecurrenceRule(
                    frequency: recurrenceFrequency,
                    daysOfWeek: recurrenceFrequency == .weekly ? recurrenceDays : nil
                )
                newTask.isRecurring = true
            }

            modelContext.insert(newTask)

            // Schedule notification
            _Concurrency.Task {
                await appEnvironment.notificationManager.scheduleTaskNotification(for: newTask, userSettings: appEnvironment.userSettings)
            }
        }

        try? modelContext.save()
        HapticManager.shared.trigger(.success)
        dismiss()
    }

    private func saveToInbox() {
        // Save task without scheduling (inbox)
        if let existingTask = task {
            existingTask.title = title
            existingTask.icon = icon
            existingTask.duration = duration
            existingTask.notes = notes.isEmpty ? nil : notes
            existingTask.scheduledStartTime = nil
            existingTask.scheduledDate = nil
            existingTask.updatedAt = Date()
        } else {
            let newTask = Task(
                title: title,
                duration: duration,
                category: selectedCategory,
                icon: icon,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(newTask)
        }

        try? modelContext.save()
        HapticManager.shared.trigger(.success)
        dismiss()
    }

    private func combineDateAndTime() -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: scheduledDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? Date()
    }

    // MARK: - Delete Handling

    private func handleDeleteTapped() {
        guard let task = task else { return }

        let isRecurringTask = task.parentTaskId != nil || task.recurrenceRule != nil

        if isRecurringTask {
            showRecurringDeleteConfirmation = true
        } else {
            deleteNonRecurringTask()
        }
    }

    private func deleteNonRecurringTask() {
        guard let task = task else { return }
        modelContext.delete(task)
        try? modelContext.save()
        HapticManager.shared.trigger(.warning)
        dismiss()
    }

    private func deleteThisInstanceOnly() {
        guard let task = task else { return }

        if let parentId = task.parentTaskId, let scheduledDate = task.scheduledDate {
            let descriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == parentId })
            if let parentTask = try? modelContext.fetch(descriptor).first {
                parentTask.dismissRecurringInstance(for: scheduledDate)
            }
        } else if task.recurrenceRule != nil, let scheduledDate = task.scheduledDate {
            task.dismissRecurringInstance(for: scheduledDate)
            try? modelContext.save()
            HapticManager.shared.trigger(.warning)
            dismiss()
            return
        }

        modelContext.delete(task)
        try? modelContext.save()
        HapticManager.shared.trigger(.warning)
        dismiss()
    }

    private func deleteAllInstances() {
        guard let task = task else { return }

        let parentId: UUID
        if let pid = task.parentTaskId {
            parentId = pid
        } else {
            parentId = task.id
        }

        let childDescriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.parentTaskId == parentId })
        let childTasks = (try? modelContext.fetch(childDescriptor)) ?? []

        let parentDescriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == parentId })
        if let parentTask = try? modelContext.fetch(parentDescriptor).first {
            modelContext.delete(parentTask)
        }

        for child in childTasks {
            modelContext.delete(child)
        }

        if task.parentTaskId == nil && task.id != parentId {
            modelContext.delete(task)
        }

        try? modelContext.save()
        HapticManager.shared.trigger(.warning)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddTaskSheet()
        .environmentObject(AppEnvironment.shared)
        .environmentObject(ThemeManager())
        .modelContainer(for: Task.self, inMemory: true)
}
