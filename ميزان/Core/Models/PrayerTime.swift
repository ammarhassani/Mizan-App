//
//  PrayerTime.swift
//  Mizan
//
//  SwiftData model for prayer times
//

import Foundation
import SwiftData

@Model
final class PrayerTime {
    // MARK: - Identity
    var id: UUID
    var date: Date // The day this prayer is for

    // MARK: - Prayer Info
    var prayerType: PrayerType

    // MARK: - Times
    var adhanTime: Date // Official prayer time from API
    var iqamaTime: Date? // Optional delay for congregation
    var duration: Int // minutes (from PrayerConfig.json)
    var bufferBefore: Int // minutes
    var bufferAfter: Int // minutes

    // MARK: - Calculation Details
    var calculationMethod: CalculationMethod
    var latitude: Double
    var longitude: Double
    var hijriDate: String // e.g., "13 Rajab 1448"

    // MARK: - User Adjustments
    var manualOffset: Int // ±minutes adjustment

    // MARK: - State
    var isJummah: Bool // Friday Dhuhr replacement
    var isRamadan: Bool

    // MARK: - Initialization
    init(
        date: Date,
        prayerType: PrayerType,
        adhanTime: Date,
        calculationMethod: CalculationMethod,
        latitude: Double = 0,
        longitude: Double = 0
    ) {
        self.id = UUID()
        self.date = date
        self.prayerType = prayerType
        self.adhanTime = adhanTime
        self.iqamaTime = nil
        self.calculationMethod = calculationMethod
        self.latitude = latitude
        self.longitude = longitude
        self.hijriDate = ""
        self.manualOffset = 0
        self.isJummah = false
        self.isRamadan = false

        // Get defaults from config
        let config = ConfigurationManager.shared.prayerConfig.defaults[prayerType.rawValue]
        self.duration = config?.durationMinutes ?? prayerType.defaultDuration
        self.bufferBefore = config?.bufferBeforeMinutes ?? 5
        self.bufferAfter = config?.bufferAfterMinutes ?? 5
    }

    // MARK: - Computed Properties

    /// Effective start time including buffer before
    var effectiveStartTime: Date {
        adhanTime.addingTimeInterval(TimeInterval((manualOffset - bufferBefore) * 60))
    }

    /// Effective end time including prayer duration and buffer after
    var effectiveEndTime: Date {
        adhanTime.addingTimeInterval(TimeInterval((manualOffset + duration + bufferAfter) * 60))
    }

    /// Actual prayer start time (with manual offset applied)
    var actualPrayerTime: Date {
        adhanTime.addingTimeInterval(TimeInterval(manualOffset * 60))
    }

    /// Prayer end time (without buffer)
    var prayerEndTime: Date {
        actualPrayerTime.addingTimeInterval(TimeInterval(duration * 60))
    }

    /// Time range for the entire prayer block (including buffers)
    var timeRange: ClosedRange<Date> {
        effectiveStartTime...effectiveEndTime
    }

    /// Display name (respects Jummah)
    var displayName: String {
        if isJummah && prayerType == .dhuhr {
            let jummahConfig = ConfigurationManager.shared.prayerConfig.jummah
            return jummahConfig.arabicName
        }
        return prayerType.arabicName
    }

    /// Color hex for this prayer (respects Jummah and theme)
    var colorHex: String {
        if isJummah && prayerType == .dhuhr {
            return ConfigurationManager.shared.prayerConfig.jummah.colorHex
        }
        return ConfigurationManager.shared.prayerConfig.defaults[prayerType.rawValue]?.colorHex ?? prayerType.defaultColorHex
    }

    // MARK: - Methods

    func adjustTime(byMinutes minutes: Int) {
        manualOffset = minutes
    }

    func updateDuration(_ newDuration: Int) {
        duration = newDuration
    }

    func convertToJummah() {
        guard prayerType == .dhuhr else { return }
        isJummah = true

        let jummahConfig = ConfigurationManager.shared.prayerConfig.jummah
        duration = jummahConfig.durationMinutes
        bufferBefore = jummahConfig.bufferBeforeMinutes
        bufferAfter = jummahConfig.bufferAfterMinutes

        // Offset Jummah time from Dhuhr
        adhanTime = adhanTime.addingTimeInterval(TimeInterval(jummahConfig.offsetFromDhuhrMinutes * 60))
    }

    /// Check if a given time range overlaps with this prayer block
    func overlaps(with startTime: Date, duration durationMinutes: Int) -> Bool {
        let endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
        let taskRange = startTime...endTime

        return timeRange.overlaps(taskRange)
    }
}

// MARK: - Prayer Type

enum PrayerType: String, Codable, CaseIterable, Identifiable {
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: String { rawValue }

    var arabicName: String {
        switch self {
        case .fajr: return "الفجر"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }

    var englishName: String {
        switch self {
        case .fajr: return "Fajr"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }

    var defaultDuration: Int {
        switch self {
        case .fajr: return 15
        case .dhuhr: return 20
        case .asr: return 20
        case .maghrib: return 15
        case .isha: return 20
        }
    }

    var icon: String {
        switch self {
        case .fajr: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.min.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        }
    }

    var defaultColorHex: String {
        switch self {
        case .fajr: return "#14746F"
        case .dhuhr: return "#0E8F8B"
        case .asr: return "#0E8F8B"
        case .maghrib: return "#D4734C"
        case .isha: return "#6C63FF"
        }
    }

    /// Order for display (sunrise to nighttime)
    var displayOrder: Int {
        switch self {
        case .fajr: return 0
        case .dhuhr: return 1
        case .asr: return 2
        case .maghrib: return 3
        case .isha: return 4
        }
    }
}

// MARK: - Calculation Method

enum CalculationMethod: String, Codable, CaseIterable, Identifiable {
    case mwl = "mwl"
    case ummAlQura = "umm_al_qura"
    case egyptian = "egyptian"
    case karachi = "karachi"
    case isna = "isna"
    case dubai = "dubai"
    case singapore = "singapore"
    case turkey = "turkey"

    var id: String { rawValue }

    var details: CalculationMethodDetail {
        let config = ConfigurationManager.shared.prayerConfig
        return config.calculationMethods.methods.first { $0.id == rawValue }!
    }

    var nameArabic: String {
        details.nameArabic
    }

    var nameEnglish: String {
        details.nameEnglish
    }

    var apiCode: Int {
        details.apiCode
    }

    var regionArabic: String {
        details.regionArabic
    }

    var regionEnglish: String {
        details.regionEnglish
    }

    /// Get default calculation method for a country code
    static func `default`(for countryCode: String) -> CalculationMethod {
        let config = ConfigurationManager.shared.prayerConfig
        let methodId = config.calculationMethods.regionalDefaults[countryCode] ?? "mwl"
        return CalculationMethod(rawValue: methodId) ?? .mwl
    }
}

// MARK: - Prayer Time Extensions

extension PrayerTime: Comparable {
    static func < (lhs: PrayerTime, rhs: PrayerTime) -> Bool {
        return lhs.adhanTime < rhs.adhanTime
    }

    static func == (lhs: PrayerTime, rhs: PrayerTime) -> Bool {
        return lhs.id == rhs.id
    }
}

extension PrayerTime {
    /// Check if this is the next upcoming prayer
    func isNext(prayers: [PrayerTime]) -> Bool {
        let now = Date()
        let upcomingPrayers = prayers.filter { $0.adhanTime > now }.sorted()
        return upcomingPrayers.first?.id == id
    }

    /// Minutes until this prayer
    var minutesUntil: Int {
        let now = Date()
        let interval = adhanTime.timeIntervalSince(now)
        return max(0, Int(interval / 60))
    }

    /// Whether this prayer time has passed
    var hasPassed: Bool {
        return effectiveEndTime < Date()
    }

    /// Whether we're currently in this prayer time
    var isCurrently: Bool {
        let now = Date()
        return timeRange.contains(now)
    }
}
