//
//  TaskCreationStep2View.swift
//  Mizan
//
//  Step 2 of task creation: Date, Time (with duration-based intervals), Duration
//

import SwiftUI

struct TaskCreationStep2View: View {
    // MARK: - Bindings (shared with parent)
    @Binding var title: String
    @Binding var icon: String
    @Binding var duration: Int
    @Binding var scheduledDate: Date
    @Binding var scheduledTime: Date
    @Binding var notes: String
    @Binding var enableRecurrence: Bool
    @Binding var recurrenceFrequency: RecurrenceRule.Frequency
    @Binding var recurrenceDays: [Int]

    let isEditing: Bool
    let isPro: Bool
    let onSave: () -> Void
    let onBack: () -> Void
    let onAddToInbox: () -> Void

    // MARK: - Environment
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appEnvironment: AppEnvironment

    // MARK: - State
    @State private var showTimeMenu = false
    @State private var showDurationMenu = false
    @State private var showDurationPicker = false
    @State private var showNotesSheet = false
    @State private var showRecurrenceSheet = false
    @State private var showIconPicker = false
    @State private var showDatePicker = false

    // MARK: - Duration Presets
    private let durationPresets = [1, 15, 30, 45, 60, 90]

    // MARK: - Computed

    private var timeRangePreview: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US")

        let startStr = formatter.string(from: scheduledTime)
        let endTime = scheduledTime.addingTimeInterval(TimeInterval(duration * 60))
        let endStr = formatter.string(from: endTime)

        return "\(startStr) - \(endStr) (\(formatDuration(duration)))"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with icon + time preview + title
            headerSection

            Divider()
                .background(themeManager.surfaceSecondaryColor)

            // Scheduling content
            ScrollView {
                VStack(spacing: MZSpacing.lg) {
                    // Date row
                    dateRow

                    // Time section
                    timeSection

                    // Duration section
                    durationSection

                    // Recurrence section
                    recurrenceSection

                    // Notes section (if has notes)
                    if !notes.isEmpty {
                        notesPreview
                    }
                }
                .padding(.horizontal, MZSpacing.md)
                .padding(.top, MZSpacing.md)
                .padding(.bottom, MZSpacing.xl)
            }

            // Save button
            saveButton
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .sheet(isPresented: $showDurationPicker) {
            DurationPickerSheet(duration: $duration)
                .presentationDetents([.medium])
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showNotesSheet) {
            notesSheet
        }
        .sheet(isPresented: $showRecurrenceSheet) {
            recurrenceSheet
        }
        .sheet(isPresented: $showIconPicker) {
            IconPickerSheet(selectedIcon: $icon)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center, spacing: MZSpacing.md) {
            // Icon (tappable to change)
            Button {
                showIconPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(themeManager.textOnPrimaryColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.textOnPrimaryColor)
                }
            }

            // Title + Time preview
            VStack(alignment: .leading, spacing: 4) {
                Text(timeRangePreview)
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.8))

                Text(title)
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.textOnPrimaryColor)
                    .lineLimit(1)
            }

            Spacer()

            // Completion circle (for visual consistency)
            Circle()
                .stroke(themeManager.textOnPrimaryColor.opacity(0.5), lineWidth: 2)
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, MZSpacing.lg)
        .padding(.vertical, MZSpacing.xl)
        .background(themeManager.primaryColor)
    }

    // MARK: - Date Row

    private var dateRow: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.system(size: 18))
                .foregroundColor(themeManager.primaryColor)

            DatePicker(
                "",
                selection: $scheduledDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .labelsHidden()

            Spacer()

            // Today button
            if !Calendar.current.isDateInToday(scheduledDate) {
                Button {
                    scheduledDate = Date()
                    HapticManager.shared.trigger(.selection)
                } label: {
                    Text("Today")
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.primaryColor)
                        .padding(.horizontal, MZSpacing.md)
                        .padding(.vertical, MZSpacing.xs)
                        .background(
                            Capsule()
                                .fill(themeManager.primaryColor.opacity(0.15))
                        )
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                .fill(themeManager.surfaceColor)
        )
    }

    // MARK: - Time Section

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            // Header with menu
            HStack {
                Text("Time")
                    .font(MZTypography.labelLarge)
                    .foregroundColor(themeManager.textPrimaryColor)

                Spacer()

                Menu {
                    Button {
                        showDatePicker = true
                        HapticManager.shared.trigger(.selection)
                    } label: {
                        Label("Change Day", systemImage: "calendar")
                    }

                    Button {
                        onAddToInbox()
                    } label: {
                        Label("Add to Inbox", systemImage: "tray.fill")
                    }

                    Divider()

                    Button {
                        showNotesSheet = true
                    } label: {
                        Label("Add Notes", systemImage: "note.text")
                    }

                    if isPro {
                        Button {
                            showRecurrenceSheet = true
                        } label: {
                            Label("Repeat", systemImage: "repeat")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            // Time picker
            timePicker
        }
    }

    private var timePicker: some View {
        VStack(spacing: 0) {
            DatePicker(
                "",
                selection: $scheduledTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 150)

            // Time range display
            HStack {
                Spacer()
                Text(timeRangePreview)
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.primaryColor)
                    .padding(.horizontal, MZSpacing.lg)
                    .padding(.vertical, MZSpacing.sm)
                    .background(
                        Capsule()
                            .fill(themeManager.primaryColor.opacity(0.15))
                    )
                Spacer()
            }
            .padding(.bottom, MZSpacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                .fill(themeManager.surfaceColor)
        )
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            // Header with menu
            HStack {
                Text("Duration")
                    .font(MZTypography.labelLarge)
                    .foregroundColor(themeManager.textPrimaryColor)

                Spacer()

                Button {
                    showDurationPicker = true
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            // Duration chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MZSpacing.sm) {
                    ForEach(durationPresets, id: \.self) { preset in
                        durationChip(preset)
                    }
                }
            }
        }
    }

    private func durationChip(_ minutes: Int) -> some View {
        let isSelected = duration == minutes

        return Button {
            duration = minutes
            HapticManager.shared.trigger(.selection)
        } label: {
            Text(formatDurationShort(minutes))
                .font(MZTypography.labelLarge)
                .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
                .padding(.horizontal, MZSpacing.md)
                .padding(.vertical, MZSpacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? themeManager.primaryColor : themeManager.surfaceColor)
                )
        }
    }

    // MARK: - Recurrence Section

    private var recurrenceSection: some View {
        Button {
            if isPro {
                showRecurrenceSheet = true
            } else {
                // Show paywall or Pro badge hint
                HapticManager.shared.trigger(.warning)
            }
        } label: {
            HStack {
                Image(systemName: "repeat")
                    .font(.system(size: 18))
                    .foregroundColor(themeManager.primaryColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Repeat")
                        .font(MZTypography.labelLarge)
                        .foregroundColor(themeManager.textPrimaryColor)

                    if enableRecurrence {
                        Text(recurrenceDescription)
                            .font(MZTypography.labelSmall)
                            .foregroundColor(themeManager.primaryColor)
                    } else {
                        Text("Does not repeat")
                            .font(MZTypography.labelSmall)
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }

                Spacer()

                if !isPro {
                    Text("PRO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(themeManager.textPrimaryColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(themeManager.warningColor)
                        )
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                    .fill(themeManager.surfaceColor)
            )
        }
        .buttonStyle(.plain)
    }

    private var recurrenceDescription: String {
        switch recurrenceFrequency {
        case .daily:
            return "Every day"
        case .weekly:
            if recurrenceDays.isEmpty {
                return "Every week"
            } else {
                let dayNames = recurrenceDays.sorted().compactMap { dayNumber -> String? in
                    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    guard dayNumber >= 1 && dayNumber <= 7 else { return nil }
                    return days[dayNumber - 1]
                }
                return dayNames.joined(separator: ", ")
            }
        case .monthly:
            return "Every month"
        }
    }

    // MARK: - Notes Preview

    private var notesPreview: some View {
        Button {
            showNotesSheet = true
        } label: {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 18))
                    .foregroundColor(themeManager.primaryColor)

                Text(notes)
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(themeManager.textSecondaryColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                    .fill(themeManager.surfaceColor)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            onSave()
            HapticManager.shared.trigger(.success)
        } label: {
            Text(isEditing ? "Save" : "Continue")
                .font(MZTypography.titleMedium)
                .foregroundColor(themeManager.textOnPrimaryColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MZSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                        .fill(themeManager.primaryColor)
                )
        }
        .padding(.horizontal, MZSpacing.lg)
        .padding(.bottom, MZSpacing.xl)
    }

    // MARK: - Notes Sheet

    private var notesSheet: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $notes)
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .scrollContentBackground(.hidden)
                    .background(themeManager.surfaceColor)
                    .cornerRadius(themeManager.cornerRadius(.medium))
                    .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showNotesSheet = false
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Date Picker Sheet

    private var datePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $scheduledDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(themeManager.primaryColor)
                .padding()

                Spacer()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Change Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showDatePicker = false
                        HapticManager.shared.trigger(.success)
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Recurrence Sheet

    private var recurrenceSheet: some View {
        NavigationStack {
            VStack(spacing: MZSpacing.lg) {
                // Enable toggle
                Toggle("Repeat", isOn: $enableRecurrence)
                    .tint(themeManager.primaryColor)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                            .fill(themeManager.surfaceColor)
                    )

                if enableRecurrence {
                    // Frequency picker
                    Picker("Frequency", selection: $recurrenceFrequency) {
                        Text("Daily").tag(RecurrenceRule.Frequency.daily)
                        Text("Weekly").tag(RecurrenceRule.Frequency.weekly)
                        Text("Monthly").tag(RecurrenceRule.Frequency.monthly)
                    }
                    .pickerStyle(.segmented)

                    // Weekly day selector
                    if recurrenceFrequency == .weekly {
                        VStack(spacing: MZSpacing.sm) {
                            weekdaySelector

                            // Validation warning
                            if recurrenceDays.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.circle")
                                        .font(.system(size: 12))
                                    Text("اختر يومًا واحدًا على الأقل")
                                        .font(MZTypography.labelSmall)
                                }
                                .foregroundColor(themeManager.warningColor)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Repeat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showRecurrenceSheet = false
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var weekdaySelector: some View {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        let dayNumbers = [1, 2, 3, 4, 5, 6, 7] // Sunday = 1

        return HStack(spacing: MZSpacing.sm) {
            ForEach(0..<7, id: \.self) { index in
                let dayNum = dayNumbers[index]
                let isSelected = recurrenceDays.contains(dayNum)

                Button {
                    if isSelected {
                        recurrenceDays.removeAll { $0 == dayNum }
                    } else {
                        recurrenceDays.append(dayNum)
                    }
                    HapticManager.shared.trigger(.selection)
                } label: {
                    Text(days[index])
                        .font(MZTypography.labelMedium)
                        .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isSelected ? themeManager.primaryColor : themeManager.surfaceColor)
                        )
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else if minutes % 60 == 0 {
            let hours = minutes / 60
            return "\(hours) hr"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours) hr, \(mins) min"
        }
    }

    private func formatDurationShort(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)"
        } else if minutes % 60 == 0 {
            return "\(minutes / 60)h"
        } else {
            let h = minutes / 60
            let m = minutes % 60
            return "\(h).\(m / 6)h" // e.g., 90 = 1.5h
        }
    }
}

// MARK: - Preview

#Preview {
    TaskCreationStep2View(
        title: .constant("Study Session"),
        icon: .constant("book.fill"),
        duration: .constant(30),
        scheduledDate: .constant(Date()),
        scheduledTime: .constant(Date()),
        notes: .constant(""),
        enableRecurrence: .constant(false),
        recurrenceFrequency: .constant(.daily),
        recurrenceDays: .constant([]),
        isEditing: false,
        isPro: true,
        onSave: {},
        onBack: {},
        onAddToInbox: {}
    )
    .environmentObject(ThemeManager())
    .environmentObject(AppEnvironment.shared)
}
