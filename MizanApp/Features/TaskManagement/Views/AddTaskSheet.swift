//
//  AddTaskSheet.swift
//  Mizan
//
//  Modern two-tier task creation sheet with progressive disclosure
//

import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    var task: Task? // nil for new task, non-nil for editing

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries
    @Query(sort: \UserCategory.order) private var userCategories: [UserCategory]

    // MARK: - Form State
    @State private var title = ""
    @State private var duration = 30
    @State private var selectedCategory: TaskCategory = .personal
    @State private var selectedUserCategory: UserCategory?
    @State private var notes = ""
    @State private var enableRecurrence = false
    @State private var recurrenceFrequency: RecurrenceRule.Frequency = .daily
    @State private var recurrenceDays: [Int] = []
    @State private var scheduleNow = false
    @State private var scheduledDate = Date()
    @State private var scheduledTime = Date()
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    // MARK: - UI State
    @State private var showAdvancedOptions = false
    @State private var showCustomDurationPicker = false
    @FocusState private var isTitleFocused: Bool

    // MARK: - Available Durations
    private let availableDurations = [15, 30, 45, 60, 90, 120, 180, 240]

    private var isCustomDuration: Bool {
        !availableDurations.contains(duration)
    }

    // MARK: - Initialization

    init(task: Task?) {
        self.task = task

        if let task = task {
            _title = State(initialValue: task.title)
            _duration = State(initialValue: task.duration)
            _selectedCategory = State(initialValue: task.category)
            _notes = State(initialValue: task.notes ?? "")
            _enableRecurrence = State(initialValue: task.recurrenceRule != nil)
            _showAdvancedOptions = State(initialValue: task.notes?.isEmpty == false || task.recurrenceRule != nil || task.scheduledStartTime != nil || task.dueDate != nil)

            if let taskDueDate = task.dueDate {
                _hasDueDate = State(initialValue: true)
                _dueDate = State(initialValue: taskDueDate)
            }

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

    private var isEditing: Bool {
        task != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Scrollable content
                    ScrollView {
                        VStack(spacing: MZSpacing.lg) {
                            // TIER 1: ESSENTIALS (Always Visible)
                            titleSection
                            durationSection
                            categorySection

                            // TIER 2: ADVANCED (Collapsible)
                            advancedSection
                        }
                        .padding(MZSpacing.screenPadding)
                        .padding(.bottom, 100) // Space for fixed button
                    }

                    // Fixed Save Button
                    saveButtonSection
                }
            }
            .navigationTitle(isEditing ? "تعديل المهمة" : "مهمة جديدة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }

                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            deleteTask()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(themeManager.errorColor)
                        }
                    }
                }
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                hideKeyboard()
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            MZFloatingTextField(
                text: $title,
                placeholder: "عنوان المهمة",
                icon: "pencil"
            )
            .environmentObject(themeManager)
            .focused($isTitleFocused)
            .validationFeedback(titleValidationState)
        }
    }

    private var titleValidationState: ValidationState {
        if title.isEmpty {
            return .idle
        } else if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .error("العنوان لا يمكن أن يكون فارغاً")
        } else {
            return .idle
        }
    }

    // MARK: - Duration Section (Horizontal Chips)

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("المدة")
                .font(MZTypography.labelLarge)
                .foregroundColor(themeManager.textSecondaryColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MZSpacing.xs + 2) {
                    ForEach(availableDurations, id: \.self) { minutes in
                        DurationChipNew(
                            minutes: minutes,
                            isSelected: duration == minutes,
                            action: {
                                withAnimation(MZAnimation.snappy) {
                                    duration = minutes
                                }
                                HapticManager.shared.trigger(.selection)
                            }
                        )
                        .environmentObject(themeManager)
                    }

                    // Custom duration chip
                    Button {
                        showCustomDurationPicker = true
                        HapticManager.shared.trigger(.selection)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 12))
                            Text(isCustomDuration ? formatCustomDuration(duration) : "مخصص")
                                .font(MZTypography.labelLarge)
                        }
                        .foregroundColor(isCustomDuration ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
                        .frame(minWidth: 56)
                        .padding(.horizontal, MZSpacing.md)
                        .padding(.vertical, MZSpacing.xs)
                        .background(
                            Capsule()
                                .fill(isCustomDuration ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
                        )
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(.vertical, 4)
                .flipsForRightToLeftLayoutDirection(true)
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .sheet(isPresented: $showCustomDurationPicker) {
            CustomDurationPickerSheet(duration: $duration)
                .environmentObject(themeManager)
        }
    }

    private func formatCustomDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) د"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) س"
            } else {
                return "\(hours):\(String(format: "%02d", remainingMinutes))"
            }
        }
    }

    // MARK: - Category Section (Horizontal Scroll with 3D Chips)

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("الفئة")
                .font(MZTypography.labelLarge)
                .foregroundColor(themeManager.textSecondaryColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MZSpacing.sm) {
                    // Use UserCategories if available, fall back to TaskCategory enum
                    if !userCategories.isEmpty {
                        ForEach(userCategories) { category in
                            MZUserCategoryChip3D(
                                category: category,
                                isSelected: selectedUserCategory?.id == category.id,
                                action: {
                                    withAnimation(MZAnimation.bouncy) {
                                        selectedUserCategory = category
                                        // Also update legacy category for backwards compatibility
                                        if let legacyCategory = TaskCategory(rawValue: category.name.lowercased()) {
                                            selectedCategory = legacyCategory
                                        }
                                    }
                                    HapticManager.shared.trigger(.selection)
                                }
                            )
                            .environmentObject(themeManager)
                        }
                    } else {
                        // Fallback to legacy TaskCategory enum with 3D chips
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            MZTaskCategoryChip3D(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: {
                                    withAnimation(MZAnimation.bouncy) {
                                        selectedCategory = category
                                    }
                                    HapticManager.shared.trigger(.selection)
                                }
                            )
                            .environmentObject(themeManager)
                        }
                    }
                }
                .padding(.vertical, 4)
                .flipsForRightToLeftLayoutDirection(true)
            }
            .environment(\.layoutDirection, .rightToLeft)
            .fixedSize(horizontal: false, vertical: true)

            // Category hint text
            Text(selectedCategory.hintArabic)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(themeManager.textSecondaryColor)
                .padding(.horizontal, 4)
                .padding(.top, 2)
                .animation(.easeInOut(duration: 0.2), value: selectedCategory)
        }
        .onAppear {
            // Set initial selected category if not already set
            if selectedUserCategory == nil && !userCategories.isEmpty {
                // Find matching category or use first
                if let task = task, let taskCategory = task.userCategory {
                    selectedUserCategory = taskCategory
                } else {
                    let legacyName = selectedCategory.rawValue.capitalized
                    selectedUserCategory = userCategories.first { $0.name == legacyName } ?? userCategories.first
                }
            }
        }
    }

    // MARK: - Advanced Section (Collapsible)

    private var advancedSection: some View {
        VStack(spacing: MZSpacing.md) {
            // Disclosure button
            Button {
                withAnimation(MZAnimation.gentle) {
                    showAdvancedOptions.toggle()
                }
                HapticManager.shared.trigger(.light)
            } label: {
                HStack {
                    Text("خيارات إضافية")
                        .font(MZTypography.titleSmall)
                        .foregroundColor(themeManager.textPrimaryColor)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.textSecondaryColor)
                        .rotationEffect(.degrees(showAdvancedOptions ? 180 : 0))
                }
                .padding(MZSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.surfaceSecondaryColor)
                )
            }
            .buttonStyle(PressableButtonStyle())

            // Collapsible content
            if showAdvancedOptions {
                VStack(spacing: MZSpacing.md) {
                    scheduleSection
                    dueDateSection
                    recurrenceSection
                    notesSection
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(spacing: MZSpacing.sm) {
            // Toggle row
            HStack {
                HStack(spacing: MZSpacing.sm) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.primaryColor)
                        .symbolEffect(.bounce, value: scheduleNow)

                    Text("جدولة")
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(themeManager.textPrimaryColor)
                }

                Spacer()

                Toggle("", isOn: $scheduleNow)
                    .labelsHidden()
                    .tint(themeManager.primaryColor)
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.surfaceSecondaryColor)
            )
            .onChange(of: scheduleNow) { _, value in
                HapticManager.shared.trigger(value ? .success : .light)
            }

            // Date/Time pickers
            if scheduleNow {
                VStack(spacing: MZSpacing.sm) {
                    DatePicker(
                        "التاريخ",
                        selection: $scheduledDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .padding(MZSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.surfaceSecondaryColor)
                    )

                    DatePicker(
                        "الوقت",
                        selection: $scheduledTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .padding(MZSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.surfaceSecondaryColor)
                    )
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Due Date Section

    private var dueDateSection: some View {
        VStack(spacing: MZSpacing.sm) {
            // Toggle row
            HStack {
                HStack(spacing: MZSpacing.sm) {
                    Image(systemName: "flag")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.primaryColor)
                        .symbolEffect(.bounce, value: hasDueDate)

                    Text("موعد التسليم")
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(themeManager.textPrimaryColor)
                }

                Spacer()

                Toggle("", isOn: $hasDueDate)
                    .labelsHidden()
                    .tint(themeManager.primaryColor)
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.surfaceSecondaryColor)
            )
            .onChange(of: hasDueDate) { _, value in
                HapticManager.shared.trigger(value ? .success : .light)
                if value && dueDate < Date() {
                    // Default to tomorrow if no due date set
                    dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                }
            }

            // Due date picker
            if hasDueDate {
                DatePicker(
                    "التاريخ",
                    selection: $dueDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .padding(MZSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.surfaceSecondaryColor)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Recurrence Section (Pro)

    private var recurrenceSection: some View {
        VStack(spacing: MZSpacing.sm) {
            // Toggle row with Pro badge
            HStack {
                HStack(spacing: MZSpacing.sm) {
                    Image(systemName: "repeat")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.primaryColor)
                        .symbolEffect(.bounce, value: enableRecurrence)

                    Text("التكرار")
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(themeManager.textPrimaryColor)

                    if !appEnvironment.userSettings.isPro {
                        Text("Pro")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(themeManager.textPrimaryColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(themeManager.warningColor)
                            )
                    }
                }

                Spacer()

                Toggle("", isOn: $enableRecurrence)
                    .labelsHidden()
                    .tint(themeManager.primaryColor)
                    .disabled(!appEnvironment.userSettings.isPro)
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.surfaceSecondaryColor)
            )
            .onChange(of: enableRecurrence) { _, newValue in
                if newValue && !appEnvironment.userSettings.isPro {
                    enableRecurrence = false
                    // TODO: Show paywall
                } else {
                    HapticManager.shared.trigger(newValue ? .success : .light)
                }
            }

            // Recurrence options
            if enableRecurrence && appEnvironment.userSettings.isPro {
                VStack(spacing: MZSpacing.sm) {
                    Picker("النمط", selection: $recurrenceFrequency) {
                        Text("يومي").tag(RecurrenceRule.Frequency.daily)
                        Text("أسبوعي").tag(RecurrenceRule.Frequency.weekly)
                        Text("شهري").tag(RecurrenceRule.Frequency.monthly)
                    }
                    .pickerStyle(.segmented)
                    .padding(MZSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.surfaceSecondaryColor)
                    )

                    if recurrenceFrequency == .weekly {
                        customDaysPicker
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Custom Days Picker

    private var customDaysPicker: some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            Text("اختر الأيام")
                .font(MZTypography.labelLarge)
                .foregroundColor(themeManager.textSecondaryColor)

            HStack(spacing: MZSpacing.xs) {
                ForEach(Array(1...7), id: \.self) { day in
                    let dayName = Calendar.current.shortWeekdaySymbols[day - 1]
                    let isSelected = recurrenceDays.contains(day)

                    Button {
                        withAnimation(MZAnimation.snappy) {
                            if isSelected {
                                recurrenceDays.removeAll { $0 == day }
                            } else {
                                recurrenceDays.append(day)
                            }
                        }
                        HapticManager.shared.trigger(.selection)
                    } label: {
                        Text(dayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(isSelected ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
                            )
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.surfaceSecondaryColor)
        )
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            Text("ملاحظات")
                .font(MZTypography.labelLarge)
                .foregroundColor(themeManager.textSecondaryColor)

            TextEditor(text: $notes)
                .font(MZTypography.bodyLarge)
                .frame(minHeight: 80, maxHeight: 150)
                .padding(MZSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.surfaceSecondaryColor)
                )
                .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Save Button (Fixed Bottom)

    private var saveButtonSection: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.5)

            Button {
                saveTask()
            } label: {
                Text(isEditing ? "حفظ التعديلات" : "إضافة المهمة")
                    .font(MZTypography.titleSmall)
                    .foregroundColor(themeManager.textOnPrimaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MZSpacing.buttonPaddingV)
                    .background(
                        Capsule()
                            .fill(isFormValid ? themeManager.primaryColor : themeManager.textSecondaryColor.opacity(0.5))
                            .shadow(
                                color: isFormValid ? themeManager.primaryColor.opacity(0.4) : .clear,
                                radius: 8,
                                y: 4
                            )
                    )
            }
            .disabled(!isFormValid)
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, MZSpacing.screenPadding)
            .padding(.vertical, MZSpacing.md)
            .background(themeManager.backgroundColor)
        }
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
            existingTask.userCategory = selectedUserCategory
            existingTask.notes = notes.isEmpty ? nil : notes
            existingTask.dueDate = hasDueDate ? dueDate : nil

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
            newTask.userCategory = selectedUserCategory

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

            // Set due date if enabled
            if hasDueDate {
                newTask.dueDate = dueDate
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

// MARK: - Duration Chip (New Design)

struct DurationChipNew: View {
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
                return "\(hours) س"
            } else {
                return "\(hours):\(remainingMinutes) س"
            }
        }
    }

    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(MZTypography.labelLarge)
                .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
                .frame(minWidth: 56)
                .padding(.horizontal, MZSpacing.md)
                .padding(.vertical, MZSpacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
                )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Category Chip (New Design - Horizontal)

struct CategoryChipNew: View {
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: MZSpacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.nameArabic)
                    .font(MZTypography.labelLarge)
            }
            .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : Color(hex: category.defaultColorHex))
            .padding(.horizontal, MZSpacing.md)
            .padding(.vertical, MZSpacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: category.defaultColorHex) : Color(hex: category.defaultColorHex).opacity(0.15))
            )
        }
        .buttonStyle(PressableButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(MZAnimation.bouncy, value: isSelected)
    }
}

// MARK: - User Category Chip (For UserCategory Model)

struct UserCategoryChip: View {
    let category: UserCategory
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: MZSpacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.displayName)
                    .font(MZTypography.labelLarge)
            }
            .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : Color(hex: category.colorHex))
            .padding(.horizontal, MZSpacing.md)
            .padding(.vertical, MZSpacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: category.colorHex) : Color(hex: category.colorHex).opacity(0.15))
            )
        }
        .buttonStyle(PressableButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(MZAnimation.bouncy, value: isSelected)
    }
}

// MARK: - Legacy Chips (For Compatibility)

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
                .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
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
        .buttonStyle(.plain)
    }
}

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
                        .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : Color(hex: category.defaultColorHex))
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
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Duration Picker Sheet

struct CustomDurationPickerSheet: View {
    @Binding var duration: Int

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()

                VStack(spacing: MZSpacing.lg) {
                    // Radial Duration Picker (up to 14 hours)
                    MZRadialDurationPicker(duration: $duration, maxDuration: 840)
                        .environmentObject(themeManager)
                        .padding(.top, MZSpacing.md)

                    Spacer()

                    // Save button
                    Button {
                        HapticManager.shared.trigger(.success)
                        dismiss()
                    } label: {
                        Text("حفظ")
                            .font(MZTypography.titleSmall)
                            .foregroundColor(themeManager.textOnPrimaryColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MZSpacing.buttonPaddingV)
                            .background(
                                Capsule()
                                    .fill(duration > 0 ? themeManager.primaryColor : themeManager.textSecondaryColor.opacity(0.5))
                            )
                    }
                    .disabled(duration == 0)
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal, MZSpacing.screenPadding)
                    .padding(.bottom, MZSpacing.lg)
                }
            }
            .navigationTitle("مدة مخصصة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Legacy Duration Picker (Wheel Style)

struct LegacyDurationPicker: View {
    @Binding var duration: Int

    @EnvironmentObject var themeManager: ThemeManager

    @State private var hours: Int = 0
    @State private var minutes: Int = 30

    var body: some View {
        VStack(spacing: MZSpacing.xl) {
            // Duration display
            Text(durationDisplayText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryColor)
                .contentTransition(.numericText())
                .animation(MZAnimation.snappy, value: totalMinutes)

            // Picker wheels
            HStack(spacing: 0) {
                // Hours picker
                VStack(spacing: MZSpacing.xs) {
                    Text("ساعات")
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textSecondaryColor)

                    Picker("Hours", selection: $hours) {
                        ForEach(0..<13) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 150)
                    .clipped()
                }

                Text(":")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(themeManager.textSecondaryColor)
                    .padding(.top, 20)

                // Minutes picker
                VStack(spacing: MZSpacing.xs) {
                    Text("دقائق")
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textSecondaryColor)

                    Picker("Minutes", selection: $minutes) {
                        ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 150)
                    .clipped()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.surfaceSecondaryColor)
            )

            // Quick presets
            VStack(alignment: .leading, spacing: MZSpacing.sm) {
                Text("اختصارات")
                    .font(MZTypography.labelLarge)
                    .foregroundColor(themeManager.textSecondaryColor)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: MZSpacing.sm) {
                    ForEach([25, 50, 75, 100, 150, 300], id: \.self) { preset in
                        Button {
                            setFromMinutes(preset)
                            HapticManager.shared.trigger(.selection)
                        } label: {
                            Text(formatPreset(preset))
                                .font(MZTypography.labelMedium)
                                .foregroundColor(themeManager.textPrimaryColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, MZSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(themeManager.surfaceSecondaryColor)
                                )
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
            .padding(.horizontal, MZSpacing.screenPadding)
        }
        .onAppear {
            setFromMinutes(duration)
        }
        .onChange(of: hours) { _, _ in updateDuration() }
        .onChange(of: minutes) { _, _ in updateDuration() }
    }

    private var totalMinutes: Int {
        hours * 60 + minutes
    }

    private var durationDisplayText: String {
        if hours == 0 {
            return "\(minutes) دقيقة"
        } else if minutes == 0 {
            return hours == 1 ? "ساعة" : "\(hours) ساعات"
        } else {
            return "\(hours):\(String(format: "%02d", minutes))"
        }
    }

    private func setFromMinutes(_ totalMins: Int) {
        hours = totalMins / 60
        minutes = (totalMins % 60 / 5) * 5 // Round to nearest 5
    }

    private func updateDuration() {
        duration = totalMinutes
    }

    private func formatPreset(_ mins: Int) -> String {
        if mins < 60 {
            return "\(mins) د"
        } else {
            let h = mins / 60
            let m = mins % 60
            if m == 0 {
                return "\(h) س"
            } else {
                return "\(h):\(String(format: "%02d", m))"
            }
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
