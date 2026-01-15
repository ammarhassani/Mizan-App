//
//  Date+Extensions.swift
//  Mizan
//
//  Date extensions for Hijri calendar, prayer time helpers, and formatting
//

import Foundation

extension Date {
    // MARK: - Prayer Time Helpers

    /// Check if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if this date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Check if this date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Get start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Get end of day
    var endOfDay: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfDay)!
    }

    /// Check if this date is in the same day as another date
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Get relative day string (Today, Tomorrow, Yesterday, or day name)
    func relativeDayString(language: AppLanguage = .arabic) -> String {
        if isToday {
            return language == .arabic ? "اليوم" : "Today"
        } else if isTomorrow {
            return language == .arabic ? "غدًا" : "Tomorrow"
        } else if isYesterday {
            return language == .arabic ? "أمس" : "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: language == .arabic ? "ar" : "en")
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: self)
        }
    }

    // MARK: - Time Formatting

    /// Format time for display (e.g., "3:45 PM" or "١٥:٤٥")
    func timeString(use24Hour: Bool = false, useArabicNumerals: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        formatter.locale = Locale(identifier: useArabicNumerals ? "ar" : "en")
        return formatter.string(from: self)
    }

    /// Format date for display
    func dateString(style: DateFormatter.Style = .medium, language: AppLanguage = .arabic) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale(identifier: language == .arabic ? "ar" : "en")
        return formatter.string(from: self)
    }

    /// Format full date and time
    func fullDateTimeString(language: AppLanguage = .arabic, useArabicNumerals: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: language == .arabic ? "ar" : "en")

        var string = formatter.string(from: self)

        // Convert to Arabic numerals if needed
        if useArabicNumerals && language == .arabic {
            string = string.toArabicNumerals()
        }

        return string
    }

    // MARK: - Time Intervals

    /// Minutes until this date
    var minutesUntil: Int {
        let interval = timeIntervalSinceNow
        return max(0, Int(interval / 60))
    }

    /// Hours until this date
    var hoursUntil: Int {
        return minutesUntil / 60
    }

    /// Format time remaining until this date
    func timeRemainingString(language: AppLanguage = .arabic) -> String {
        let minutes = minutesUntil

        if minutes == 0 {
            return language == .arabic ? "الآن" : "Now"
        } else if minutes < 60 {
            return language == .arabic ? "بعد \(minutes) \(minutes.arabicMinutes)" : "In \(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60

            if language == .arabic {
                if remainingMinutes == 0 {
                    return "بعد \(hours) \(hours.arabicHours)"
                } else {
                    return "بعد \(hours) س و\(remainingMinutes) د"
                }
            } else {
                if remainingMinutes == 0 {
                    return "In \(hours)h"
                } else {
                    return "In \(hours)h \(remainingMinutes)m"
                }
            }
        }
    }

    // MARK: - Date Manipulation

    /// Add minutes to date
    func addingMinutes(_ minutes: Int) -> Date {
        addingTimeInterval(TimeInterval(minutes * 60))
    }

    /// Add hours to date
    func addingHours(_ hours: Int) -> Date {
        addingTimeInterval(TimeInterval(hours * 3600))
    }

    /// Add days to date
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    // MARK: - Hijri Calendar

    /// Get Hijri date string
    func hijriDateString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: self)
    }

    /// Get Hijri month name
    var hijriMonth: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: self)
    }

    /// Get Hijri month number (1-12)
    var hijriMonthNumber: Int {
        let calendar = Calendar(identifier: .islamicUmmAlQura)
        return calendar.component(.month, from: self)
    }

    /// Check if date is in Ramadan
    var isRamadan: Bool {
        return hijriMonthNumber == 9
    }

    /// Check if date is Friday
    var isFriday: Bool {
        let calendar = Calendar.current
        return calendar.component(.weekday, from: self) == 6 // 6 = Friday
    }

    // MARK: - Prayer Time Calculations

    /// Calculate last third of night (for Tahajjud/Qiyam)
    static func lastThirdOfNight(maghrib: Date, fajr: Date) -> Date {
        let nightDuration = fajr.timeIntervalSince(maghrib)
        return maghrib.addingTimeInterval(nightDuration * 2 / 3)
    }

    /// Calculate middle of night
    static func middleOfNight(maghrib: Date, fajr: Date) -> Date {
        let nightDuration = fajr.timeIntervalSince(maghrib)
        return maghrib.addingTimeInterval(nightDuration / 2)
    }

    // MARK: - ISO8601 Formatting

    /// Format as ISO8601 date string (YYYY-MM-DD)
    func iso8601DateString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.string(from: self)
    }

    /// Parse from ISO8601 date string
    static func fromISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.date(from: string)
    }
}

// MARK: - String Extensions for Numerals

extension String {
    /// Convert Western numerals to Arabic-Indic numerals
    func toArabicNumerals() -> String {
        let arabicNumerals = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        var result = self

        for (index, numeral) in arabicNumerals.enumerated() {
            result = result.replacingOccurrences(of: "\(index)", with: numeral)
        }

        return result
    }

    /// Convert Arabic-Indic numerals to Western numerals
    func toWesternNumerals() -> String {
        let arabicNumerals = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        var result = self

        for (index, numeral) in arabicNumerals.enumerated() {
            result = result.replacingOccurrences(of: numeral, with: "\(index)")
        }

        return result
    }
}

// MARK: - Calendar Helpers

extension Calendar {
    /// Get number of days in current month
    func daysInMonth(for date: Date) -> Int {
        return range(of: .day, in: .month, for: date)?.count ?? 30
    }

    /// Get first day of month
    func firstDayOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }

    /// Get last day of month
    func lastDayOfMonth(for date: Date) -> Date {
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return self.date(byAdding: components, to: firstDayOfMonth(for: date))!
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Convert to minutes
    var minutes: Int {
        return Int(self / 60)
    }

    /// Convert to hours
    var hours: Int {
        return Int(self / 3600)
    }

    /// Format as readable duration
    func durationString(language: AppLanguage = .arabic) -> String {
        let totalMinutes = minutes

        if totalMinutes < 60 {
            return language == .arabic ? "\(totalMinutes) \(totalMinutes.arabicMinutes)" : "\(totalMinutes) min"
        } else {
            let hours = totalMinutes / 60
            let remainingMinutes = totalMinutes % 60

            if language == .arabic {
                if remainingMinutes == 0 {
                    return "\(hours) \(hours.arabicHours)"
                } else {
                    return "\(hours) س \(remainingMinutes) د"
                }
            } else {
                if remainingMinutes == 0 {
                    return "\(hours)h"
                } else {
                    return "\(hours)h \(remainingMinutes)m"
                }
            }
        }
    }
}
