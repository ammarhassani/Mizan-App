//
//  TimeRangePicker.swift
//  Mizan
//
//  Custom wheel picker showing time ranges that adapt to duration
//  e.g., with 30min duration: "9:00 - 9:30 PM", "9:30 - 10:00 PM"
//

import SwiftUI

struct TimeRangePicker: View {
    @Binding var selectedTime: Date
    let duration: Int // minutes
    let date: Date // The day to generate times for

    @EnvironmentObject var themeManager: ThemeManager

    @State private var selectedIndex: Int = 0

    // MARK: - Time Slots

    private var timeSlots: [Date] {
        generateTimeSlots(for: date, interval: duration)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom wheel picker
            Picker("Time", selection: $selectedIndex) {
                ForEach(0..<timeSlots.count, id: \.self) { index in
                    timeSlotRow(for: timeSlots[index])
                        .tag(index)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 180)
            .onChange(of: selectedIndex) { _, newIndex in
                if newIndex < timeSlots.count {
                    selectedTime = timeSlots[newIndex]
                }
            }
            .onChange(of: duration) { _, _ in
                // When duration changes, find closest slot to current time
                updateSelectionForNewDuration()
            }
            .onAppear {
                // Initialize selection to closest slot
                selectedIndex = findClosestSlotIndex(to: selectedTime)
            }
        }
        .background(themeManager.surfaceColor)
        .cornerRadius(themeManager.cornerRadius(.large))
    }

    // MARK: - Time Slot Row

    private func timeSlotRow(for startTime: Date) -> some View {
        let endTime = startTime.addingTimeInterval(TimeInterval(duration * 60))
        let isSelected = selectedIndex == timeSlots.firstIndex(of: startTime)

        return HStack(spacing: 4) {
            Text(formatTime(startTime))
            Text("-")
                .foregroundColor(themeManager.textSecondaryColor)
            Text(formatTime(endTime))
        }
        .font(MZTypography.titleMedium)
        .foregroundColor(isSelected == true ? themeManager.primaryColor : themeManager.textPrimaryColor)
        .padding(.horizontal, MZSpacing.lg)
        .padding(.vertical, MZSpacing.sm)
        .background(
            Group {
                if isSelected == true {
                    Capsule()
                        .fill(themeManager.primaryColor.opacity(0.15))
                }
            }
        )
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }

    private func generateTimeSlots(for day: Date, interval: Int) -> [Date] {
        let calendar = Calendar.current
        var slots: [Date] = []

        // Start from midnight of the day
        let startOfDay = calendar.startOfDay(for: day)

        // Generate slots for entire day based on interval
        // Use minimum 5 minute interval to avoid too many slots
        let effectiveInterval = max(interval, 5)

        var currentTime = startOfDay
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        while currentTime < endOfDay {
            slots.append(currentTime)
            currentTime = currentTime.addingTimeInterval(TimeInterval(effectiveInterval * 60))
        }

        return slots
    }

    private func findClosestSlotIndex(to time: Date) -> Int {
        guard !timeSlots.isEmpty else { return 0 }

        let timeInterval = time.timeIntervalSince1970
        var closestIndex = 0
        var smallestDiff = Double.infinity

        for (index, slot) in timeSlots.enumerated() {
            let diff = abs(slot.timeIntervalSince1970 - timeInterval)
            if diff < smallestDiff {
                smallestDiff = diff
                closestIndex = index
            }
        }

        return closestIndex
    }

    private func updateSelectionForNewDuration() {
        // Regenerate slots and find closest to current selection
        let newSlots = generateTimeSlots(for: date, interval: duration)
        if !newSlots.isEmpty {
            selectedIndex = min(selectedIndex, newSlots.count - 1)
            // Find the slot closest to the current selectedTime
            selectedIndex = findClosestSlotIndex(to: selectedTime)
        }
    }
}

// MARK: - Alternative Compact Time Range Picker

/// A more compact version showing just start time with end time calculated
struct CompactTimeRangePicker: View {
    @Binding var selectedTime: Date
    let duration: Int
    let date: Date

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            // Selected time range display
            selectedTimeDisplay

            // Time picker wheel
            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 150)
        }
    }

    private var selectedTimeDisplay: some View {
        let endTime = selectedTime.addingTimeInterval(TimeInterval(duration * 60))
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US")

        return HStack(spacing: MZSpacing.xs) {
            Text(formatter.string(from: selectedTime))
                .font(MZTypography.titleLarge)
                .foregroundColor(themeManager.primaryColor)

            Text("-")
                .foregroundColor(themeManager.textSecondaryColor)

            Text(formatter.string(from: endTime))
                .font(MZTypography.titleLarge)
                .foregroundColor(themeManager.primaryColor)

            Text("(\(formatDuration(duration)))")
                .font(MZTypography.labelMedium)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .padding(.horizontal, MZSpacing.md)
        .padding(.vertical, MZSpacing.sm)
        .background(
            Capsule()
                .fill(themeManager.primaryColor.opacity(0.1))
        )
    }

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
}

// MARK: - Preview

#Preview("Time Range Picker") {
    let themeManager = ThemeManager()
    VStack(spacing: 20) {
        TimeRangePicker(
            selectedTime: .constant(Date()),
            duration: 30,
            date: Date()
        )
        .environmentObject(themeManager)

        TimeRangePicker(
            selectedTime: .constant(Date()),
            duration: 15,
            date: Date()
        )
        .environmentObject(themeManager)
    }
    .padding()
    .background(themeManager.backgroundColor)
}

#Preview("Compact Time Range Picker") {
    let themeManager = ThemeManager()
    CompactTimeRangePicker(
        selectedTime: .constant(Date()),
        duration: 45,
        date: Date()
    )
    .environmentObject(themeManager)
    .padding()
    .background(themeManager.backgroundColor)
}
