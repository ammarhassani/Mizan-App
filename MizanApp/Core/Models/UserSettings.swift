//
//  UserSettings.swift
//  Mizan
//
//  SwiftData model for user settings
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    // MARK: - Identity
    var id: UUID
    var lastUpdated: Date

    // MARK: - App Preferences
    var selectedTheme: String // theme ID from ThemeConfig.json
    var language: AppLanguage
    var useArabicNumerals: Bool
    var showHijriDate: Bool

    // MARK: - Prayer Settings
    var calculationMethod: CalculationMethod
    private var prayerAdjustmentsJSON: String = "{}" // Store as JSON to avoid SwiftData array issues
    var enableJummahMode: Bool
    var jummahCustomTime: Date? // If different from Dhuhr

    /// PrayerType.rawValue -> offset minutes
    @Transient
    var prayerAdjustments: [String: Int] {
        get {
            (try? JSONDecoder().decode([String: Int].self, from: Data(prayerAdjustmentsJSON.utf8))) ?? [:]
        }
        set {
            prayerAdjustmentsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "{}"
        }
    }

    // MARK: - Location
    var lastKnownLatitude: Double?
    var lastKnownLongitude: Double?
    var manualLocationName: String?
    var lastLocationUpdate: Date?

    // MARK: - Notifications
    var notificationsEnabled: Bool
    var prayerNotificationsEnabled: Bool
    var taskNotificationsEnabled: Bool
    var prayerReminderMinutes: Int // minutes before prayer
    var taskReminderMinutes: Int // Pro: minutes before task
    var selectedAdhanAudio: String // filename

    // MARK: - Pro Features
    var isPro: Bool
    var proExpiryDate: Date?
    var proSubscriptionType: String? // "monthly", "annual", "lifetime"
    var nawafilEnabled: Bool

    // SwiftData requires explicit storage configuration for arrays/dictionaries
    // Store as JSON strings internally, provide typed accessors
    private var enabledNawafilJSON: String = "[]"
    private var nawafilRakaatPreferencesJSON: String = "{}"
    private var nawafilTimePreferencesJSON: String = "{}"
    private var nawafilDurationPreferencesJSON: String = "{}"

    var calendarSyncEnabled: Bool

    // MARK: - Computed Accessors for Array/Dictionary Properties

    /// NawafilType IDs that are enabled
    @Transient
    var enabledNawafil: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(enabledNawafilJSON.utf8))) ?? []
        }
        set {
            enabledNawafilJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    /// Nawafil type -> user's chosen rakaat count
    @Transient
    var nawafilRakaatPreferences: [String: Int] {
        get {
            (try? JSONDecoder().decode([String: Int].self, from: Data(nawafilRakaatPreferencesJSON.utf8))) ?? [:]
        }
        set {
            nawafilRakaatPreferencesJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "{}"
        }
    }

    /// Nawafil type -> minutes since midnight (e.g., 9:30 AM = 570)
    @Transient
    var nawafilTimePreferences: [String: Int] {
        get {
            (try? JSONDecoder().decode([String: Int].self, from: Data(nawafilTimePreferencesJSON.utf8))) ?? [:]
        }
        set {
            nawafilTimePreferencesJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "{}"
        }
    }

    /// Nawafil type -> user's chosen duration in minutes
    @Transient
    var nawafilDurationPreferences: [String: Int] {
        get {
            (try? JSONDecoder().decode([String: Int].self, from: Data(nawafilDurationPreferencesJSON.utf8))) ?? [:]
        }
        set {
            nawafilDurationPreferencesJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "{}"
        }
    }

    // MARK: - Onboarding
    var hasCompletedOnboarding: Bool
    var lastOnboardingVersion: String

    // MARK: - Visual Effects
    var enableVisualEffects: Bool = true
    var enablePrayerCountdownScreen: Bool = true
    var enableParticleNotifications: Bool = true
    var enableBackgroundAmbiance: Bool = true
    var ramadanModeEnabled: Bool = false

    // MARK: - Initialization
    init() {
        self.id = UUID()
        self.lastUpdated = Date()

        // App preferences
        self.selectedTheme = "noor" // default free theme
        self.language = .arabic
        self.useArabicNumerals = true
        self.showHijriDate = true

        // Prayer settings
        self.calculationMethod = .mwl // Will be detected based on location
        // prayerAdjustments uses default JSON string "{}"
        self.enableJummahMode = true
        self.jummahCustomTime = nil

        // Location
        self.lastKnownLatitude = nil
        self.lastKnownLongitude = nil
        self.manualLocationName = nil
        self.lastLocationUpdate = nil

        // Notifications
        self.notificationsEnabled = true
        self.prayerNotificationsEnabled = true
        self.taskNotificationsEnabled = true
        self.prayerReminderMinutes = 10
        self.taskReminderMinutes = 5
        self.selectedAdhanAudio = "makkah_adhan.mp3"

        // Pro features
        self.isPro = false
        self.proExpiryDate = nil
        self.proSubscriptionType = nil
        self.nawafilEnabled = false
        // enabledNawafil, nawafilRakaatPreferences, nawafilTimePreferences use default JSON strings
        self.calendarSyncEnabled = false

        // Onboarding
        self.hasCompletedOnboarding = false
        self.lastOnboardingVersion = "1.0.0"

        // Visual Effects
        self.enableVisualEffects = true
        self.enablePrayerCountdownScreen = true
        self.enableParticleNotifications = true
        self.enableBackgroundAmbiance = true
        self.ramadanModeEnabled = false
    }

    // MARK: - Methods

    func updateLocation(latitude: Double, longitude: Double) {
        lastKnownLatitude = latitude
        lastKnownLongitude = longitude
        lastLocationUpdate = Date()
        lastUpdated = Date()
    }

    func updateCalculationMethod(_ method: CalculationMethod) {
        calculationMethod = method
        lastUpdated = Date()
    }

    func adjustPrayerTime(for prayerType: PrayerType, offsetMinutes: Int) {
        prayerAdjustments[prayerType.rawValue] = offsetMinutes
        lastUpdated = Date()
    }

    func getPrayerAdjustment(for prayerType: PrayerType) -> Int {
        return prayerAdjustments[prayerType.rawValue] ?? 0
    }

    func updateTheme(_ themeId: String) {
        selectedTheme = themeId
        lastUpdated = Date()
    }

    func enableProFeatures(subscriptionType: String, expiryDate: Date? = nil) {
        isPro = true
        proSubscriptionType = subscriptionType
        proExpiryDate = expiryDate
        lastUpdated = Date()
    }

    func disableProFeatures() {
        isPro = false
        proSubscriptionType = nil
        proExpiryDate = nil
        nawafilEnabled = false
        enabledNawafil = []
        calendarSyncEnabled = false
        lastUpdated = Date()
    }

    func isProActive() -> Bool {
        guard isPro else { return false }

        // Lifetime has no expiry
        if proSubscriptionType == "lifetime" {
            return true
        }

        // Check if subscription is expired
        if let expiryDate = proExpiryDate {
            return expiryDate > Date()
        }

        return true
    }

    func enableNawafil(types: [String]) {
        guard isProActive() else { return }
        nawafilEnabled = true
        enabledNawafil = types
        lastUpdated = Date()
    }

    func isNawafilEnabled(type: String) -> Bool {
        return nawafilEnabled && enabledNawafil.contains(type)
    }

    /// Get the user's preferred rakaat count for a nawafil type
    func getRakaatForNawafil(_ type: String) -> Int? {
        return nawafilRakaatPreferences[type]
    }

    /// Set the user's preferred rakaat count for a nawafil type
    func setRakaatForNawafil(_ type: String, rakaat: Int) {
        nawafilRakaatPreferences[type] = rakaat
        lastUpdated = Date()
    }

    /// Get rakaat with fallback to config default
    func getEffectiveRakaatForNawafil(_ type: String, config: NawafilType) -> Int {
        // User preference takes priority
        if let userPref = nawafilRakaatPreferences[type] {
            return userPref
        }
        // Fallback to config default
        return config.rakaat.default ?? config.rakaat.fixed ?? 2
    }

    /// Get the user's preferred time for a nawafil (minutes since midnight)
    func getTimeForNawafil(_ type: String) -> Int? {
        return nawafilTimePreferences[type]
    }

    /// Set the user's preferred time for a nawafil (minutes since midnight)
    func setTimeForNawafil(_ type: String, minutesSinceMidnight: Int) {
        nawafilTimePreferences[type] = minutesSinceMidnight
        lastUpdated = Date()
    }

    /// Convert minutes since midnight to Date for a given day
    func getTimeAsDate(_ type: String, for date: Date) -> Date? {
        guard let minutes = nawafilTimePreferences[type] else { return nil }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return startOfDay.addingTimeInterval(TimeInterval(minutes * 60))
    }

    /// Convert Date to minutes since midnight
    static func dateToMinutesSinceMidnight(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    /// Convert minutes since midnight to formatted time string
    static func minutesToTimeString(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        let date = Calendar.current.date(bySettingHour: hours, minute: mins, second: 0, of: Date())!
        return date.formatted(date: .omitted, time: .shortened)
    }

    /// Get the user's preferred duration for a nawafil type
    func getDurationForNawafil(_ type: String) -> Int? {
        return nawafilDurationPreferences[type]
    }

    /// Set the user's preferred duration for a nawafil type
    func setDurationForNawafil(_ type: String, duration: Int) {
        nawafilDurationPreferences[type] = duration
        lastUpdated = Date()
    }

    /// Get duration with fallback to config default
    func getEffectiveDurationForNawafil(_ type: String, config: NawafilType) -> Int {
        // User preference takes priority
        if let userPref = nawafilDurationPreferences[type] {
            return userPref
        }
        // Fallback to config default
        return config.durationMinutes ?? config.durationOptions?.first ?? 60
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        lastUpdated = Date()
    }

    /// Check if location has changed significantly (> 50km)
    func hasLocationChangedSignificantly(newLatitude: Double, newLongitude: Double) -> Bool {
        guard let oldLat = lastKnownLatitude, let oldLon = lastKnownLongitude else {
            return true // No previous location, consider it changed
        }

        let distance = haversineDistance(
            lat1: oldLat, lon1: oldLon,
            lat2: newLatitude, lon2: newLongitude
        )

        return distance > 50_000 // 50 km in meters
    }

    /// Calculate distance between two coordinates using Haversine formula
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0 // Earth's radius in meters
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180

        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon/2) * sin(dLon/2)

        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
}

// MARK: - User Settings Extensions

extension UserSettings {
    var currentTheme: Theme {
        let themes = ConfigurationManager.shared.themeConfig.themes
        return themes.first { $0.id == selectedTheme } ?? themes[0]
    }

    var isUsingArabic: Bool {
        return language == .arabic
    }

    var localizedString: (String) -> String {
        return { key in
            ConfigurationManager.shared.string(for: key, language: self.language)
        }
    }
}
