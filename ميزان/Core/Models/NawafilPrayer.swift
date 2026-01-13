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
        return nawafilConfig.nawafilTypes.first { $0.type == nawafilType }
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

    var endTime: Date {
        suggestedTime.addingTimeInterval(TimeInterval(duration * 60))
    }

    var timeRange: ClosedRange<Date> {
        suggestedTime...endTime
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
    static func calculateDuration(for nawafilType: String, rakaat: Int) -> Int {
        let config = ConfigurationManager.shared.nawafilConfig
        guard let nawafil = config.nawafilTypes.first(where: { $0.type == nawafilType }) else {
            return 10 // default
        }

        // For types with duration per 2 rakaat
        if let durationPer2Rakaat = nawafil.durationPer2RakaatMinutes {
            return (rakaat / 2) * durationPer2Rakaat
        }

        // For types with duration calculation dictionary
        if let durationCalc = nawafil.durationCalculation {
            let key = "\(rakaat)_rakaat"
            if let duration = durationCalc[key] {
                return duration
            }
        }

        // Default duration
        return nawafil.durationMinutes ?? 10
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
        enabledNawafilTypes: [String]
    ) -> [NawafilPrayer] {
        var nawafil: [NawafilPrayer] = []
        let config = ConfigurationManager.shared.nawafilConfig

        for nawafilType in config.nawafilTypes {
            // Skip if not enabled by user
            guard enabledNawafilTypes.contains(nawafilType.type) else { continue }

            // Calculate suggested time based on timing rules
            if let suggestedTime = calculateSuggestedTime(
                for: nawafilType,
                date: date,
                prayerTimes: prayerTimes
            ) {
                // Get rakaat count (use default if user-configurable)
                let rakaat = nawafilType.rakaat.default ?? nawafilType.rakaat.fixed ?? 2

                // Calculate duration
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
        }

        return nawafil.sorted()
    }

    /// Calculate suggested time for a nawafil based on its timing rules
    private static func calculateSuggestedTime(
        for nawafilType: NawafilType,
        date: Date,
        prayerTimes: [PrayerTime]
    ) -> Date? {
        let timing = nawafilType.timing
        let calendar = Calendar.current

        // Attached to a specific prayer
        if let attachmentPrayer = timing.attachment,
           let offsetMinutes = timing.offsetMinutes,
           let prayerType = PrayerType(rawValue: attachmentPrayer),
           let prayer = prayerTimes.first(where: { $0.prayerType == prayerType }) {

            if timing.position == "before" {
                // Schedule before the prayer adhan
                return prayer.adhanTime.addingTimeInterval(TimeInterval(offsetMinutes * 60))
            } else if timing.position == "after" {
                // Schedule after the prayer ends
                return prayer.prayerEndTime.addingTimeInterval(TimeInterval(offsetMinutes * 60))
            }
        }

        // Time-based calculation (e.g., Duha, Tahajjud, Qiyam al-Layl)
        if timing.calculation == "last_third_of_night" {
            // Calculate last third of night based on Maghrib to Fajr
            if let maghrib = prayerTimes.first(where: { $0.prayerType == .maghrib }),
               let fajr = prayerTimes.first(where: { $0.prayerType == .fajr }) {

                let nightDuration = fajr.adhanTime.timeIntervalSince(maghrib.adhanTime)
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
