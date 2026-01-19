//
//  AITaskCreationCard.swift
//  Mizan
//
//  All-in-one task creation card for AI chat - collects time, duration, and recurrence at once
//

import SwiftUI

// MARK: - Time Option

enum TimeOption: String, CaseIterable {
    case now = "now"
    case inOneHour = "in_one_hour"
    case tomorrow = "tomorrow"
    case custom = "custom"

    var label: String {
        switch self {
        case .now: return "الآن"
        case .inOneHour: return "بعد ساعة"
        case .tomorrow: return "بكرة"
        case .custom: return "اختيار"
        }
    }

    var icon: String {
        switch self {
        case .now: return "bolt.fill"
        case .inOneHour: return "clock"
        case .tomorrow: return "sun.max"
        case .custom: return "calendar"
        }
    }
}

// MARK: - Duration Option

enum DurationOption: Int, CaseIterable {
    case min15 = 15
    case min30 = 30
    case min45 = 45
    case min60 = 60
    case min90 = 90
    case min120 = 120

    var label: String {
        switch self {
        case .min15: return "15 د"
        case .min30: return "30 د"
        case .min45: return "45 د"
        case .min60: return "ساعة"
        case .min90: return "1.5 س"
        case .min120: return "ساعتين"
        }
    }
}

// MARK: - Recurrence Option

enum RecurrenceOption: String, CaseIterable {
    case oneTime = "none"
    case daily = "daily"
    case weekly = "weekly"

    var label: String {
        switch self {
        case .oneTime: return "مرة واحدة"
        case .daily: return "يومياً"
        case .weekly: return "أسبوعياً"
        }
    }

    var icon: String {
        switch self {
        case .oneTime: return "1.circle"
        case .daily: return "repeat"
        case .weekly: return "repeat.circle"
        }
    }
}

// MARK: - AI Task Creation Card

struct AITaskCreationCard: View {
    let taskTitle: String
    let category: String?
    var onComplete: ((Date, Int, RecurrenceOption) -> Void)?
    var onCancel: (() -> Void)?

    @EnvironmentObject var themeManager: ThemeManager

    @State private var selectedTime: TimeOption = .now
    @State private var selectedDuration: DurationOption = .min30
    @State private var selectedRecurrence: RecurrenceOption = .oneTime

    @State private var showCustomTimePicker: Bool = false
    @State private var customDate: Date = Date()
    @State private var customTime: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            // Header with task title
            header

            Divider()
                .background(themeManager.textTertiaryColor.opacity(0.3))

            // Time selection
            timeSection

            // Duration selection
            durationSection

            // Recurrence selection
            recurrenceSection

            // Action buttons
            actionButtons
        }
        .padding(MZSpacing.md)
        .background(themeManager.surfaceColor)
        .cornerRadius(themeManager.cornerRadius(.large))
        .shadow(color: themeManager.textPrimaryColor.opacity(0.1), radius: 8, y: 4)
        .sheet(isPresented: $showCustomTimePicker) {
            customTimePickerSheet
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: MZSpacing.sm) {
            // Task icon based on category
            Image(systemName: TaskIconDetector.shared.detectIcon(from: taskTitle))
                .font(.system(size: 20))
                .foregroundColor(themeManager.primaryColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(taskTitle)
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .lineLimit(2)

                if let cat = category {
                    Text(categoryArabicName(cat))
                        .font(MZTypography.labelSmall)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            Spacer()
        }
    }

    // MARK: - Time Section

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            Label("متى؟", systemImage: "clock")
                .font(MZTypography.labelMedium)
                .foregroundColor(themeManager.textSecondaryColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MZSpacing.xs) {
                    ForEach(TimeOption.allCases, id: \.self) { option in
                        ChipButton(
                            label: option.label,
                            icon: option.icon,
                            isSelected: selectedTime == option,
                            action: {
                                selectedTime = option
                                if option == .custom {
                                    showCustomTimePicker = true
                                }
                            }
                        )
                    }
                }
            }

            // Show selected custom time if applicable
            if selectedTime == .custom {
                Text(formattedCustomDateTime)
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.primaryColor)
                    .padding(.leading, MZSpacing.xs)
            }
        }
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            Label("كم المدة؟", systemImage: "timer")
                .font(MZTypography.labelMedium)
                .foregroundColor(themeManager.textSecondaryColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MZSpacing.xs) {
                    ForEach(DurationOption.allCases, id: \.self) { option in
                        ChipButton(
                            label: option.label,
                            isSelected: selectedDuration == option,
                            action: { selectedDuration = option }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Recurrence Section

    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            Label("تكرار؟", systemImage: "repeat")
                .font(MZTypography.labelMedium)
                .foregroundColor(themeManager.textSecondaryColor)

            HStack(spacing: MZSpacing.xs) {
                ForEach(RecurrenceOption.allCases, id: \.self) { option in
                    ChipButton(
                        label: option.label,
                        icon: option.icon,
                        isSelected: selectedRecurrence == option,
                        action: { selectedRecurrence = option }
                    )
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: MZSpacing.sm) {
            // Cancel button
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

            // Add button
            Button {
                let scheduledDate = computeScheduledDate()
                onComplete?(scheduledDate, selectedDuration.rawValue, selectedRecurrence)
            } label: {
                HStack(spacing: MZSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text("إضافة")
                }
                .font(MZTypography.labelMedium)
                .foregroundColor(themeManager.textOnPrimaryColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MZSpacing.sm)
                .background(themeManager.primaryColor)
                .cornerRadius(themeManager.cornerRadius(.medium))
            }
        }
        .padding(.top, MZSpacing.xs)
    }

    // MARK: - Custom Time Picker Sheet

    private var customTimePickerSheet: some View {
        NavigationView {
            VStack(spacing: MZSpacing.md) {
                DatePicker(
                    "التاريخ",
                    selection: $customDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: "ar"))

                DatePicker(
                    "الوقت",
                    selection: $customTime,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .environment(\.locale, Locale(identifier: "ar"))

                Spacer()
            }
            .padding()
            .navigationTitle("اختر الوقت")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") {
                        showCustomTimePicker = false
                        // Reset to "now" if cancelled
                        selectedTime = .now
                    }
                    .foregroundColor(themeManager.primaryColor)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("تم") {
                        showCustomTimePicker = false
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Helpers

    private func computeScheduledDate() -> Date {
        let calendar = Calendar.current

        switch selectedTime {
        case .now:
            return Date()
        case .inOneHour:
            return Date().addingTimeInterval(60 * 60)
        case .tomorrow:
            // Tomorrow at 9 AM
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
        case .custom:
            // Combine custom date and time
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: customDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: customTime)
            var combined = DateComponents()
            combined.year = dateComponents.year
            combined.month = dateComponents.month
            combined.day = dateComponents.day
            combined.hour = timeComponents.hour
            combined.minute = timeComponents.minute
            return calendar.date(from: combined) ?? Date()
        }
    }

    private var formattedCustomDateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ar")
        dateFormatter.dateFormat = "EEEE, d MMMM - h:mm a"
        return dateFormatter.string(from: computeScheduledDate())
    }

    private func categoryArabicName(_ category: String) -> String {
        switch category.lowercased() {
        case "work": return "عمل"
        case "personal": return "شخصي"
        case "study": return "دراسة"
        case "health": return "صحة"
        case "social": return "اجتماعي"
        case "worship": return "عبادة"
        default: return category
        }
    }
}

// MARK: - Chip Button Component

struct ChipButton: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: MZSpacing.xxs) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 12))
                }
                Text(label)
                    .font(MZTypography.labelMedium)
            }
            .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
            .padding(.horizontal, MZSpacing.sm)
            .padding(.vertical, MZSpacing.xs)
            .background(isSelected ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
            .cornerRadius(themeManager.cornerRadius(.small))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        AITaskCreationCard(
            taskTitle: "الذهاب للنادي",
            category: "health",
            onComplete: { date, duration, recurrence in
                print("Complete: \(date), \(duration) min, \(recurrence)")
            },
            onCancel: {
                print("Cancelled")
            }
        )
        .padding()
    }
    .background(ThemeManager().surfaceSecondaryColor)
    .environmentObject(ThemeManager())
}
