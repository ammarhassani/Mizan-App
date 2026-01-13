//
//  TimelineItem.swift
//  Mizan
//
//  Protocol for items that can be displayed on the timeline
//

import Foundation
import SwiftUI

/// Protocol for items that appear on the timeline (tasks, prayers, nawafil)
protocol TimelineItem {
    var id: UUID { get }
    var startTime: Date { get }
    var duration: Int { get } // minutes
    var title: String { get }
    var colorHex: String { get }
    var isMovable: Bool { get } // false for prayers and nawafil
    var itemType: TimelineItemType { get }
}

enum TimelineItemType {
    case task
    case fardPrayer
    case nawafilPrayer
}

// MARK: - Task Conformance

extension Task: TimelineItem {
    var startTime: Date {
        scheduledStartTime ?? Date()
    }

    var isMovable: Bool {
        true
    }

    var itemType: TimelineItemType {
        .task
    }
}

// MARK: - PrayerTime Conformance

extension PrayerTime: TimelineItem {
    var startTime: Date {
        actualPrayerTime
    }

    var title: String {
        displayName
    }

    var isMovable: Bool {
        false
    }

    var itemType: TimelineItemType {
        .fardPrayer
    }
}

// MARK: - NawafilPrayer Conformance

extension NawafilPrayer: TimelineItem {
    var startTime: Date {
        suggestedTime
    }

    var title: String {
        arabicName
    }

    var isMovable: Bool {
        false // Nawafil are suggested, not draggable
    }

    var itemType: TimelineItemType {
        .nawafilPrayer
    }
}

// MARK: - TimelineItem Helpers

extension TimelineItem {
    /// End time of this item
    var endTime: Date {
        startTime.addingTimeInterval(TimeInterval(duration * 60))
    }

    /// Time range occupied by this item
    var timeRange: ClosedRange<Date> {
        startTime...endTime
    }

    /// Y position on timeline (assuming 60pt per hour)
    func yPosition(relativeTo baseTime: Date, hourHeight: CGFloat = 60) -> CGFloat {
        let interval = startTime.timeIntervalSince(baseTime)
        let hours = interval / 3600
        return CGFloat(hours) * hourHeight
    }

    /// Height on timeline
    var height: CGFloat {
        let hourHeight: CGFloat = 60
        let minutes = CGFloat(duration)
        return (minutes / 60.0) * hourHeight
    }

    /// SwiftUI Color from hex
    var color: Color {
        Color(hex: colorHex)
    }

    /// Check if this item overlaps with another
    func overlaps(with other: TimelineItem) -> Bool {
        return timeRange.overlaps(other.timeRange)
    }

    /// Check if this item overlaps with a time range
    func overlaps(startTime: Date, duration durationMinutes: Int) -> Bool {
        let endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
        let range = startTime...endTime
        return timeRange.overlaps(range)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Get hex string from Color
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// MARK: - Timeline Helpers

struct TimelineHelper {
    /// Get all timeline items for a given date
    static func items(
        for date: Date,
        tasks: [Task],
        prayers: [PrayerTime],
        nawafil: [NawafilPrayer]
    ) -> [TimelineItem] {
        let calendar = Calendar.current

        // Filter tasks for this date
        let dateTasks = tasks.filter { task in
            guard let scheduledTime = task.scheduledStartTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }

        // Filter prayers for this date
        let datePrayers = prayers.filter { prayer in
            calendar.isDate(prayer.date, inSameDayAs: date)
        }

        // Filter nawafil for this date
        let dateNawafil = nawafil.filter { nawafil in
            calendar.isDate(nawafil.date, inSameDayAs: date) && !nawafil.isDismissed
        }

        // Combine all items
        var allItems: [TimelineItem] = []
        allItems.append(contentsOf: dateTasks)
        allItems.append(contentsOf: datePrayers)
        allItems.append(contentsOf: dateNawafil)

        // Sort by start time
        return allItems.sorted { $0.startTime < $1.startTime }
    }

    /// Find the next available slot for a task
    static func nextAvailableSlot(
        after time: Date,
        duration: Int,
        existingItems: [TimelineItem],
        maxAttempts: Int = 48 // Search up to 24 hours
    ) -> Date? {
        var candidateTime = time
        let interval: TimeInterval = 30 * 60 // 30 minutes

        for _ in 0..<maxAttempts {
            // Check if this slot is available
            let candidateEnd = candidateTime.addingTimeInterval(TimeInterval(duration * 60))
            let candidateRange = candidateTime...candidateEnd

            var hasConflict = false
            for item in existingItems {
                if item.itemType != .task && item.timeRange.overlaps(candidateRange) {
                    hasConflict = true
                    break
                }
            }

            if !hasConflict {
                return candidateTime
            }

            // Try next slot
            candidateTime = candidateTime.addingTimeInterval(interval)
        }

        return nil
    }

    /// Get timeline start and end times for a date (12:00 AM to 11:59 PM)
    static func timelineBounds(for date: Date, prayers: [PrayerTime]) -> (start: Date, end: Date) {
        let calendar = Calendar.current

        // Start at 12:00 AM (midnight)
        let startTime = calendar.startOfDay(for: date)

        // End at 11:59 PM (1 minute before next midnight)
        let endTime = calendar.date(byAdding: .day, value: 1, to: startTime)!.addingTimeInterval(-60)

        return (startTime, endTime)
    }
}
