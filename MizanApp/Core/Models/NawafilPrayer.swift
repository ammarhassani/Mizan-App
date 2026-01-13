//
//  NawafilPrayer.swift
//  Mizan
//
//  SwiftData model for voluntary (nafil) prayers (Pro feature)
//

import Foundation
import SwiftData

@Model
final class NawafilPrayer {
    // MARK: - Identity
    var id: UUID
    var date: Date

    // MARK: - Nawafil Info
    var nawafilType: String // e.g., "before_fajr", "duha", "witr"

    // MARK: - Timing
    var suggestedTime: Date
    var duration: Int // minutes
    var rakaat: Int

    // MARK: - State
    var isCompleted: Bool
    var completedAt: Date?
    var isDismissed: Bool // User skipped for today

    // MARK: - Attachment (for Rawatib)
    var attachedToPrayer: PrayerType?
    var attachmentPosition: AttachmentPosition?

    // MARK: - Initialization
    init(
        date: Date,
        nawafilType: String,
        suggestedTime: Date,
        duration: Int,
        rakaat: Int
    ) {
        self.id = UUID()
        self.date = date
        self.nawafilType = nawafilType
        self.suggestedTime = suggestedTime
        self.duration = duration
        self.rakaat = rakaat
        self.isCompleted = false
        self.completedAt = nil
        self.isDismissed = false
        self.attachedToPrayer = nil
        self.attachmentPosition = nil
    }

    // MARK: - Computed Properties

    var config: NawafilType? {
        let nawafilConfig = ConfigurationManager.shared.nawafilConfig
        return nawafilConfig?.nawafilTypes.first { $0.type == nawafilType }
    }

    var arabicName: String {
        config?.arabicName ?? nawafilType
    }

    var englishName: String {
        config?.englishName ?? nawafilType
    }

    var icon: String {
        config?.icon ?? "moon.stars.fill"
    }

    var colorHex: String {
        config?.colorHex ?? "#52B788"
    }

    var colorOpacity: Double {
        config?.colorOpacity ?? 0.7
    }

    var isTimeBlock: Bool {
        config?.isTimeBlock ?? false
    }

    /// Whether this nawafil is attached to a prayer (rawatib) vs standalone (duha, witr, tahajjud)
    var isAttachedToPrayer: Bool {
        attachedToPrayer != nil
    }

    /// Whether this is a standalone nawafil that should appear as separate segment
    var isStandalone: Bool {
        attachedToPrayer == nil
    }

    // MARK: - Methods

    func markCompleted() {
        isCompleted = true
        completedAt = Date()
    }

    func unmarkCompleted() {
        isCompleted = false
        completedAt = nil
    }

    func dismiss() {
        isDismissed = true
    }

    func undismiss() {
        isDismissed = false
    }

    func attachToPrayer(_ prayerType: PrayerType, position: AttachmentPosition) {
        attachedToPrayer = prayerType
        attachmentPosition = position
    }

    /// Calculate duration based on rakaat count
    /// Uses 3 minutes per rakaa, snaps to nearest 10 if > 5
    static func calculateDuration(for nawafilType: String, rakaat: Int) -> Int {
        let config = ConfigurationManager.shared.nawafilConfig
        let nawafil = config?.nawafilTypes.first(where: { $0.type == nawafilType })

        // Check if this is a time block (e.g., Qiyam al-Layl) with fixed duration
        if let nawafil = nawafil, nawafil.isTimeBlock == true {
            return nawafil.durationMinutes ?? 30
        }

        // Calculate duration: 3 minutes per rakaa
        let rawDuration = rakaat * 3

        // If total <= 5 min: use actual value
        // If total > 5 min: snap to nearest 10
        if rawDuration <= 5 {
            return rawDuration
        } else {
            // Snap to nearest 10 (round to nearest)
            return Int(round(Double(rawDuration) / 10.0)) * 10
        }
    }

    /// Check if this nawafil overlaps with a time range
    func overlaps(with startTime: Date, duration durationMinutes: Int) -> Bool {
        let endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
        let taskRange = startTime...endTime

        return timeRange.overlaps(taskRange)
    }
}

// MARK: - Attachment Position

enum AttachmentPosition: String, Codable {
    case before
    case after
}

// MARK: - Nawafil Prayer Extensions

extension NawafilPrayer: Comparable {
    static func < (lhs: NawafilPrayer, rhs: NawafilPrayer) -> Bool {
        return lhs.suggestedTime < rhs.suggestedTime
    }

    static func == (lhs: NawafilPrayer, rhs: NawafilPrayer) -> Bool {
        return lhs.id == rhs.id
    }
}

extension NawafilPrayer {
    /// Create nawafil prayers for a given date and prayer times
    static func generateForDate(
        _ date: Date,
        prayerTimes: [PrayerTime],
        enabledNawafilTypes: [String],
        rakaatPreferences: [String: Int] = [:],
        timePreferences: [String: Int] = [:] // minutes since midnight
    ) -> [NawafilPrayer] {
        var nawafil: [NawafilPrayer] = []
        let config = ConfigurationManager.shared.nawafilConfig

        for nawafilType in config?.nawafilTypes ?? [] {
            // Skip if not enabled by user
            guard enabledNawafilTypes.contains(nawafilType.type) else { continue }

            // Calculate suggested time based on timing rules
            guard let defaultTime = calculateSuggestedTime(
                for: nawafilType,
                date: date,
                prayerTimes: prayerTimes
            ) else { continue }

            // Use user's preferred time if set, otherwise use calculated default
            let suggestedTime: Date
            if let userMinutes = timePreferences[nawafilType.type] {
                // Convert user's preferred minutes since midnight to Date
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: date)
                suggestedTime = startOfDay.addingTimeInterval(TimeInterval(userMinutes * 60))
            } else {
                suggestedTime = defaultTime
            }

            // Get rakaat count: user preference > config default > fixed > fallback
            let rakaat: Int
            if let userPref = rakaatPreferences[nawafilType.type] {
                rakaat = userPref
            } else {
                rakaat = nawafilType.rakaat.default ?? nawafilType.rakaat.fixed ?? 2
            }

            // Calculate duration based on actual rakaat count
            let duration = calculateDuration(for: nawafilType.type, rakaat: rakaat)

            let prayer = NawafilPrayer(
                date: date,
                nawafilType: nawafilType.type,
                suggestedTime: suggestedTime,
                duration: duration,
                rakaat: rakaat
            )

            // Attach to prayer if it's a rawatib type
            if let attachment = nawafilType.timing.attachment,
               let position = nawafilType.timing.position,
               let prayerType = PrayerType(rawValue: attachment),
               let attachPos = AttachmentPosition(rawValue: position) {
                prayer.attachToPrayer(prayerType, position: attachPos)
            }

            nawafil.append(prayer)
        }

        return nawafil.sorted()
    }

    /// Calculate suggested time for a nawafil based on its timing rules
    /// Pre-prayer nawafil: positioned AFTER athan, BEFORE iqama
    /// Post-prayer nawafil: positioned AFTER prayer ends
    private static func calculateSuggestedTime(
        for nawafilType: NawafilType,
        date: Date,
        prayerTimes: [PrayerTime]
    ) -> Date? {
        let timing = nawafilType.timing

        // Attached to a specific prayer
        if let attachmentPrayer = timing.attachment,
           let prayerType = PrayerType(rawValue: attachmentPrayer),
           let prayer = prayerTimes.first(where: { $0.prayerType == prayerType }) {

            if timing.position == "before" {
                // Pre-prayer nawafil: starts AFTER athan, during the waiting period before iqama
                // User prays sunnah rawatib during the athan-to-iqama gap
                // Start a few minutes after athan to allow time to settle
                return prayer.effectiveStartTime.addingTimeInterval(TimeInterval(2 * 60)) // 2 min after athan
            } else if timing.position == "after" {
                // Post-prayer nawafil: starts immediately after iqama ends (prayer completed)
                return prayer.iqamaEndTime
            }
        }

        // Time-based calculation (e.g., Duha, Tahajjud, Qiyam al-Layl)
        if timing.calculation == "last_third_of_night" {
            // Calculate last third of night based on Maghrib to Fajr
            if let maghrib = prayerTimes.first(where: { $0.prayerType == .maghrib }),
               let fajr = prayerTimes.first(where: { $0.prayerType == .fajr }) {

                // Fix: When Fajr and Maghrib are from the same calendar day,
                // Fajr (5:30 AM) appears before Maghrib (5:00 PM) chronologically.
                // But Fajr actually represents the NEXT morning's prayer.
                // We need to add 24 hours to get the correct night duration.
                var nightDuration: TimeInterval
                if fajr.adhanTime < maghrib.adhanTime {
                    // Fajr is "before" Maghrib = it's actually next day's Fajr
                    let nextDayFajr = fajr.adhanTime.addingTimeInterval(24 * 60 * 60)
                    nightDuration = nextDayFajr.timeIntervalSince(maghrib.adhanTime)
                } else {
                    nightDuration = fajr.adhanTime.timeIntervalSince(maghrib.adhanTime)
                }

                let lastThirdStart = maghrib.adhanTime.addingTimeInterval(nightDuration * 2 / 3)
                return lastThirdStart
            }
        }

        // Mid-morning for Duha
        if timing.suggestedTime == "mid_morning",
           let fajr = prayerTimes.first(where: { $0.prayerType == .fajr }) {
            // 15 minutes after sunrise (sunrise is ~30min after Fajr)
            let sunriseApprox = fajr.adhanTime.addingTimeInterval(TimeInterval(30 * 60))
            return sunriseApprox.addingTimeInterval(TimeInterval(15 * 60))
        }

        return nil
    }
}
