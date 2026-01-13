//
//  AddTaskSheet.swift
//  Mizan
//
//  Sheet for adding and editing tasks
//

import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    var task: Task? // nil for new task, non-nil for editing

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    // MARK: - Form State
    @State private var title = ""
    @State private var duration = 30
    @State private var selectedCategory: TaskCategory = .personal
    @State private var notes = ""
    @State private var enableRecurrence = false
    @State private var recurrenceFrequency: RecurrenceRule.Frequency = .daily
    @State private var recurrenceDays: [Int] = []
    @State private var scheduleNow = false
    @State private var scheduledDate = Date()
    @State private var scheduledTime = Date()

    // MARK: - Available Durations
    private let availableDurations = [15, 30, 45, 60, 90, 120, 180, 240]

    // MARK: - Initialization

    init(task: Task?) {
        self.task = task

        if let task = task {
            _title = State(initialValue: task.title)
            _duration = State(initialValue: task.duration)
            _selectedCategory = State(initialValue: task.category)
            _notes = State(initialValue: task.notes ?? "")
            _enableRecurrence = State(initialValue: task.recurrenceRule != nil)

            if let rule = task.recurrenceRule {
                _recurrenceFrequency = State(initialValue: rule.frequency)
                if let days = rule.daysOfWeek {
                    _recurrenceDays = State(initialValue: days)
                }
            }

            if let scheduledStart = task.scheduledStartTime {
                _scheduleNow = State(initialValue: true)
                _scheduledDate = State(initialValue: scheduledStart)
                _scheduledTime = State(initialValue: scheduledStart)
            }
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isRecurrenceLocked: Bool {
        !appEnvironment.userSettings.isPro && enableRecurrence
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                // Title Section
                Section("العنوان") {
                    TextField("مثال: مراجعة المشروع", text: $title)
                        .font(.system(size: 17))
                }

                // Duration Section
                Section("المدة") {
                    durationPicker
                }

                // Category Section
                Section("الفئة") {
                    categoryPicker
                }

                // Notes Section
                Section("ملاحظات (اختياري)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .font(.system(size: 15))
                }

                // Recurrence Section (Pro)
                Section {
                    recurrenceToggle

                    if enableRecurrence {
                        recurrenceOptions
                    }
                } header: {
                    HStack {
                        Text("التكرار")
                        Spacer()
                        if !appEnvironment.userSettings.isPro {
                            Text("Pro")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(themeManager.primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                }

                // Schedule Section
                Section("جدولة") {
                    Toggle("جدولة على الجدول", isOn: $scheduleNow)

                    if scheduleNow {
                        DatePicker(
                            "التاريخ",
                            selection: $scheduledDate,
                            displayedComponents: .date
                        )

                        DatePicker(
                            "الوقت",
                            selection: $scheduledTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                // Save Button
                Section {
                    Button {
                        saveTask()
                    } label: {
                        HStack {
                            Spacer()
                            Text(task == nil ? "إضافة المهمة" : "حفظ التغييرات")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                    .listRowBackground(
                        (isFormValid ? themeManager.primaryColor : Color.gray)
                            .cornerRadius(8)
                    )
                }
            }
            .navigationTitle(task == nil ? "مهمة جديدة" : "تعديل المهمة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if task != nil {
                        Button(role: .destructive) {
                            deleteTask()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Duration Picker

    private var durationPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableDurations, id: \.self) { minutes in
                    DurationChip(
                        minutes: minutes,
                        isSelected: duration == minutes,
                        action: {
                            duration = minutes
                            HapticManager.shared.trigger(.selection)
                        }
                    )
                    .environmentObject(themeManager)
                }
            }
            .padding(.vertical, 8)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 12
        ) {
            ForEach(TaskCategory.allCases, id: \.self) { category in
                CategoryChip(
                    category: category,
                    isSelected: selectedCategory == category,
                    action: {
                        selectedCategory = category
                        HapticManager.shared.trigger(.selection)
                    }
                )
                .environmentObject(themeManager)
            }
        }
        .padding(.vertical, 8)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    // MARK: - Recurrence Toggle

    private var recurrenceToggle: some View {
        Toggle("تكرار المهمة", isOn: $enableRecurrence)
            .disabled(isRecurrenceLocked)
            .onChange(of: enableRecurrence) { _, newValue in
                if newValue && !appEnvironment.userSettings.isPro {
                    // Show paywall
                    enableRecurrence = false
                    // TODO: Trigger paywall sheet
                }
            }
    }

    // MARK: - Recurrence Options

    @ViewBuilder
    private var recurrenceOptions: some View {
        Picker("النمط", selection: $recurrenceFrequency) {
            Text("يومي").tag(RecurrenceRule.Frequency.daily)
            Text("أسبوعي").tag(RecurrenceRule.Frequency.weekly)
            Text("شهري").tag(RecurrenceRule.Frequency.monthly)
        }
        .pickerStyle(.segmented)

        if recurrenceFrequency == .weekly {
            customDaysPicker
        }
    }

    // MARK: - Custom Days Picker

    private var customDaysPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("اختر الأيام")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textSecondaryColor)

            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    let dayName = Calendar.current.shortWeekdaySymbols[day - 1]
                    let isSelected = recurrenceDays.contains(day)

                    Button {
                        if isSelected {
                            recurrenceDays.removeAll { $0 == day }
                        } else {
                            recurrenceDays.append(day)
                        }
                        HapticManager.shared.trigger(.selection)
                    } label: {
                        Text(dayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isSelected ? .white : themeManager.textPrimaryColor)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(isSelected ? themeManager.primaryColor : themeManager.surfaceColor)
                            )
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        if let existingTask = task {
            // Update existing task
            existingTask.title = trimmedTitle
            existingTask.duration = duration
            existingTask.category = selectedCategory
            existingTask.notes = notes.isEmpty ? nil : notes

            if enableRecurrence && appEnvironment.userSettings.isPro {
                let rule = RecurrenceRule(
                    frequency: recurrenceFrequency,
                    interval: 1,
                    daysOfWeek: recurrenceFrequency == .weekly ? recurrenceDays : nil
                )
                existingTask.recurrenceRule = rule
                existingTask.isRecurring = true
            } else {
                existingTask.recurrenceRule = nil
                existingTask.isRecurring = false
            }

            if scheduleNow {
                let combined = combineDateAndTime()
                existingTask.scheduleAt(time: combined)
            } else {
                existingTask.moveToInbox()
            }

        } else {
            // Create new task
            let newTask = Task(
                title: trimmedTitle,
                duration: duration,
                category: selectedCategory,
                notes: notes.isEmpty ? nil : notes
            )

            if enableRecurrence && appEnvironment.userSettings.isPro {
                let rule = RecurrenceRule(
                    frequency: recurrenceFrequency,
                    interval: 1,
                    daysOfWeek: recurrenceFrequency == .weekly ? recurrenceDays : nil
                )
                newTask.recurrenceRule = rule
                newTask.isRecurring = true
            }

            if scheduleNow {
                let combined = combineDateAndTime()
                newTask.scheduleAt(time: combined)
            }

            modelContext.insert(newTask)
        }

        try? modelContext.save()
        HapticManager.shared.trigger(.success)
        dismiss()
    }

    private func deleteTask() {
        guard let task = task else { return }
        modelContext.delete(task)
        try? modelContext.save()
        HapticManager.shared.trigger(.warning)
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

        // Round to nearest 15 minutes
        let minute = combined.minute ?? 0
        combined.minute = (minute / 15) * 15

        return calendar.date(from: combined) ?? Date()
    }
}

// MARK: - Duration Chip

struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    private var displayText: String {
        if minutes < 60 {
            return "\(minutes) د"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) ساعة"
            } else {
                return "\(hours):\(remainingMinutes) س"
            }
        }
    }

    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : themeManager.textPrimaryColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? themeManager.primaryColor : themeManager.surfaceColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? themeManager.primaryColor : Color.clear, lineWidth: 2)
                )
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.defaultColorHex).opacity(isSelected ? 1.0 : 0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: category.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : Color(hex: category.defaultColorHex))
                }

                Text(category.nameArabic)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.textPrimaryColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: category.defaultColorHex).opacity(0.1) : themeManager.surfaceColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: category.defaultColorHex) : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    AddTaskSheet(task: nil)
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
        .modelContainer(AppEnvironment.preview().modelContainer)
}
