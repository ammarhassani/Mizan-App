//
//  ConfigurationManager.swift
//  Mizan
//
//  Configuration loader for all JSON config files
//  This is the foundation of the configuration-driven architecture
//

import Foundation

final class ConfigurationManager {
    static let shared = ConfigurationManager()

    // Configuration objects
    private(set) var prayerConfig: PrayerConfiguration!
    private(set) var themeConfig: ThemeConfiguration!
    private(set) var animationConfig: AnimationConfiguration!
    private(set) var nawafilConfig: NawafilConfiguration!
    private(set) var notificationConfig: NotificationConfiguration!
    private(set) var localizationConfig: LocalizationConfiguration!

    private init() {
        loadConfigurations()
    }

    /// Loads all JSON configuration files from the bundle
    private func loadConfigurations() {
        do {
            prayerConfig = try loadJSON("PrayerConfig")
            themeConfig = try loadJSON("ThemeConfig")
            animationConfig = try loadJSON("AnimationConfig")
            nawafilConfig = try loadJSON("NawafilConfig")
            notificationConfig = try loadJSON("NotificationConfig")
            localizationConfig = try loadJSON("LocalizationConfig")

            print("✅ All configurations loaded successfully")
        } catch {
            fatalError("Failed to load configuration files: \(error)")
        }
    }

    /// Generic JSON loader
    private func loadJSON<T: Decodable>(_ filename: String) throws -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ConfigError.fileNotFound(filename)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(T.self, from: data)
    }

    /// Reload all configurations (useful for development/testing)
    func reloadConfigurations() {
        loadConfigurations()
    }

    /// Get localized string
    func string(for key: String, language: AppLanguage = .arabic) -> String {
        let components = key.split(separator: ".").map(String.init)
        guard components.count >= 2 else { return key }

        let section = components[0]
        let stringKey = components[1]

        // Navigate through nested dictionaries
        if let sectionDict = localizationConfig.strings[section] as? [String: Any],
           let stringDict = sectionDict[stringKey] as? [String: String] {
            return stringDict[language.rawValue] ?? key
        }

        return key
    }
}

enum ConfigError: Error {
    case fileNotFound(String)
    case invalidFormat(String)
}

// MARK: - Configuration Models

struct PrayerConfiguration: Codable {
    let version: String
    let defaults: [String: PrayerDefaults]
    let jummah: JummahConfig
    let ramadan: RamadanConfig
    let calculationMethods: CalculationMethodsConfig
    let highLatitude: HighLatitudeConfig
    let api: APIConfig
    let notifications: PrayerNotificationsConfig
}

struct PrayerDefaults: Codable {
    let durationMinutes: Int
    let bufferBeforeMinutes: Int
    let bufferAfterMinutes: Int
    let colorHex: String
    let colorHexLight: String
    let icon: String
    let arabicName: String
    let englishName: String
}

struct JummahConfig: Codable {
    let enabled: Bool
    let durationMinutes: Int
    let bufferBeforeMinutes: Int
    let bufferAfterMinutes: Int
    let offsetFromDhuhrMinutes: Int
    let colorHex: String
    let colorHexLight: String
    let icon: String
    let arabicName: String
    let englishName: String
    let notificationArabic: String
    let notificationEnglish: String
}

struct RamadanConfig: Codable {
    let suhoor: RamadanTimeBlock
    let iftar: RamadanTimeBlock
    let tarawih: TarawihConfig
}

struct RamadanTimeBlock: Codable {
    let offsetBeforeFajrMinutes: Int?
    let offsetFromMaghribMinutes: Int?
    let durationMinutes: Int
    let colorHex: String
    let arabicName: String
    let englishName: String
    let icon: String
}

struct TarawihConfig: Codable {
    let offsetAfterIshaMinutes: Int
    let defaultRakaat: Int
    let rakaatOptions: [Int]
    let durationPerRakaatMinutes: Int
    let colorHex: String
    let arabicName: String
    let englishName: String
    let icon: String
}

struct CalculationMethodsConfig: Codable {
    let methods: [CalculationMethodDetail]
    let regionalDefaults: [String: String]
}

struct CalculationMethodDetail: Codable {
    let id: String
    let apiCode: Int
    let nameArabic: String
    let nameEnglish: String
    let fajrAngle: Double
    let ishaAngle: Double?
    let ishaMinutesAfterMaghrib: Int?
    let regionArabic: String
    let regionEnglish: String
}

struct HighLatitudeConfig: Codable {
    let thresholdDegrees: Double
    let methods: [HighLatitudeMethod]
    let defaultMethod: String
}

struct HighLatitudeMethod: Codable {
    let id: String
    let nameArabic: String
    let nameEnglish: String
    let descriptionArabic: String
    let descriptionEnglish: String
    let fajrOffsetHours: Double?
    let ishaOffsetHours: Double?
    let searchWindowDays: Int?
}

struct APIConfig: Codable {
    let baseUrl: String
    let endpoints: [String: String]
    let cacheDays: Int
    let timeoutSeconds: Int
    let retryAttempts: Int
    let retryDelaySeconds: [Int]
}

struct PrayerNotificationsConfig: Codable {
    let prayerReminderMinutesBefore: Int
    let prayerReminderMinutesAfter: Int
    let defaultAdhanAudio: String
}

struct ThemeConfiguration: Codable {
    let version: String
    let themes: [Theme]
}

struct Theme: Codable, Identifiable {
    let id: String
    let name: String
    let nameArabic: String
    let isPro: Bool
    let colors: ThemeColors
    let fonts: ThemeFonts?
    let shadows: ThemeShadows?
    let cornerRadius: CornerRadiusConfig?
    let useGlowInsteadOfShadow: Bool?
    let useGradientBackground: Bool?
    let specialEffects: ThemeSpecialEffects?
    let autoActivateDuringRamadan: Bool?
}

struct ThemeColors: Codable {
    let background: String
    let backgroundGradient: [String]?
    let surface: String?
    let surfaceSecondary: String?
    let primary: String
    let primaryLight: String?
    let primaryDark: String?
    let secondary: String
    let accent: String?
    let textPrimary: String
    let textSecondary: String?
    let textTertiary: String?
    let prayerGradientStart: String
    let prayerGradientEnd: String
    let success: String?
    let warning: String?
    let error: String?
    let info: String?
    let divider: String?
    let taskColors: [String: String]?
}

struct ThemeFonts: Codable {
    let body: String
    let bodyMedium: String?
    let bodySemibold: String?
    let header: String
    let headerBold: String?
    let headerHeavy: String?
    let arabicBody: String?
    let arabicBodyMedium: String?
    let arabicBodySemibold: String?
    let arabicHeader: String?
    let arabicHeaderBold: String?
    let arabicHeaderHeavy: String?
}

struct ThemeShadows: Codable {
    let card: ShadowConfig
    let elevated: ShadowConfig?
    let floating: ShadowConfig?
}

struct ShadowConfig: Codable {
    let color: String
    let radius: Double
    let x: Double
    let y: Double
}

struct CornerRadiusConfig: Codable {
    let small: Double
    let medium: Double
    let large: Double
    let extraLarge: Double
}

struct ThemeSpecialEffects: Codable {
    let arabesquePattern: Bool?
    let patternOpacity: Double?
    let crescentMoonIcon: Bool?
    let festiveAnimations: Bool?
    let starParticles: Bool?
    let useGlow: Bool?
    let hardShadows: Bool?
}

struct AnimationConfiguration: Codable {
    let version: String
    let springs: [String: SpringConfig]
    let durations: [String: Double]
    let easing: [String: [Double]]
    let haptics: [String: HapticConfig]
    let signatureAnimations: [String: SignatureAnimation]
    let performance: PerformanceConfig
    let microInteractions: [String: MicroInteractionConfig]
}

struct SpringConfig: Codable {
    let response: Double
    let dampingFraction: Double
    let blendDuration: Double
    let description: String?
}

struct HapticConfig: Codable {
    let intensity: Double?
    let sharpness: Double?
    let type: String?
    let notificationType: String?
    let usage: String?
    let minIntervalMs: Int?
}

struct SignatureAnimation: Codable {
    let totalDuration: Double?
    let duration: Double?
    let spring: String?
    let easing: String?
    let haptic: String?
    let sequence: [AnimationStep]?
    let scale: Double?
    let shadowRadius: Double?
    let shadowOpacity: Double?
    let rotateDegrees: Double?
    let glowColor: String?
    let glowRadius: Double?
    let pulseDuration: Double?
    let pulseMinOpacity: Double?
    let pulseMaxOpacity: Double?
    let wobbleAngle: Double?
    let wobbleDuration: Double?
}

struct AnimationStep: Codable {
    let action: String
    let duration: Double
    let delay: Double?
    let spring: String?
    let easing: String?
    let haptic: String?
    let scaleFrom: Double?
    let scaleTo: Double?
    let scaleSettle: Double?
    let blurRadius: Double?
    let overshoot: Bool?
    let continuous: Bool?
    let stagger: Bool?
    let staggerInterval: Double?
    let proOnly: Bool?
    let pulseScale: Double?
}

struct PerformanceConfig: Codable {
    let targetFps: Int
    let minimumAcceptableFps: Int
    let enableFrameRateMonitoring: Bool
    let reduceMotionThreshold: Double
    let lazyLoadingThresholdHours: Int
    let debounceHapticMs: Int
}

struct MicroInteractionConfig: Codable {
    let slideDuration: Double?
    let spring: String?
    let haptic: String?
    let dragSpring: String?
    let hapticOnSnap: String?
    let snapInterval: Int?
    let scrollSpring: String?
    let hapticOnChange: String?
    let pushDuration: Double?
    let popDuration: Double?
    let rotationDuration: Double?
    let duration: Double?
    let continuous: Bool?
    let sequence: [AnimationStep]?
}

struct NawafilConfiguration: Codable {
    let version: String
    let proFeature: Bool
    let nawafilTypes: [NawafilType]
    let rawatib: RawatibConfig
    let displaySettings: NawafilDisplaySettings
    let notifications: NawafilNotificationsConfig
}

struct NawafilType: Codable, Identifiable {
    let type: String
    var id: String { type }
    let arabicName: String
    let englishName: String
    let rakaat: NawafilRakaat
    let durationMinutes: Int?
    let durationPer2RakaatMinutes: Int?
    let durationCalculation: [String: Int]?
    let durationOptions: [Int]?
    let timing: NawafilTiming
    let importance: String
    let autoScheduleIfRawatibEnabled: Bool?
    let autoScheduleIfEnabled: Bool?
    let userMustEnable: Bool?
    let icon: String
    let colorHex: String
    let colorOpacity: Double
    let descriptionArabic: String
    let descriptionEnglish: String
    let isTimeBlock: Bool?
    let specialStyling: Bool?
    let display: NawafilDisplay?
    let activities: [NawafilActivity]?
    let ramadan: NawafilRamadanConfig?
}

struct NawafilRakaat: Codable {
    let fixed: Int?
    let userConfigurable: Bool?
    let min: Int?
    let max: Int?
    let `default`: Int?
    let mustBeEven: Bool?
    let mustBeOdd: Bool?
    let options: [Int]?
    let userChoice: Bool?
    let notFixed: Bool?
}

struct NawafilTiming: Codable {
    let attachment: String?
    let position: String?
    let offsetMinutes: Int?
    let relativeTo: String?
    let earliest: String?
    let latest: String?
    let suggestedTime: String?
    let suggestedTimeFormula: String?
    let calculation: String?
    let basedOn: [String]?
    let formula: String?
    let defaultTimeBeforeFajrHours: Double?
    let alternative: String?
    let preferred: String?
}

struct NawafilDisplay: Codable {
    let iconEmoji: String?
    let descriptionArabic: String?
    let descriptionEnglish: String?
    let showActivitiesSuggestion: Bool?
}

struct NawafilActivity: Codable {
    let arabic: String
    let english: String
}

struct NawafilRamadanConfig: Codable {
    let emphasize: Bool?
    let defaultRakaat: Int?
    let defaultDurationMinutes: Int?
    let lasttenNightsReminder: Bool?
    let last10Nights: NawafilLast10Nights?
}

struct NawafilLast10Nights: Codable {
    let extraEmphasis: Bool?
    let laylatAlQadrSuggestion: Bool?
    let oddNights: [Int]?
}

struct RawatibConfig: Codable {
    let descriptionArabic: String
    let descriptionEnglish: String
    let enabledByDefault: Bool
    let types: [String]
    let granularControl: Bool
    let toggleAllOption: Bool
}

struct NawafilDisplaySettings: Codable {
    let badgeTextArabic: String
    let badgeTextEnglish: String
    let opacityComparedToFard: Double
    let borderStyle: String
    let completionTracking: CompletionTrackingConfig
    let dismissal: DismissalConfig
    let noGuiltMessaging: Bool
}

struct CompletionTrackingConfig: Codable {
    let enabled: Bool
    let optional: Bool
    let userConfigurable: Bool
}

struct DismissalConfig: Codable {
    let canSkipToday: Bool
    let skipTextArabic: String
    let skipTextEnglish: String
    let doesNotAffectStreak: Bool
}

struct NawafilNotificationsConfig: Codable {
    let enabled: Bool
    let gentleReminders: Bool
    let timeBeforeSuggestedTimeMinutes: Int
    let canBeDisabledPerType: Bool
    let notificationTone: String
}

struct NotificationConfiguration: Codable {
    let version: String
    let prayerNotifications: PrayerNotifications
    let taskNotifications: TaskNotifications
    let nawafilNotifications: NawafilNotifications
    let specialNotifications: SpecialNotifications
    let notificationActions: [String: NotificationAction]
    let notificationCategories: [String: NotificationCategory]
    let sounds: NotificationSounds
    let settings: NotificationSettings
}

struct PrayerNotifications: Codable {
    let beforePrayer: NotificationTemplate
    let atPrayerTime: NotificationTemplate
    let afterPrayer: NotificationTemplate
}

struct TaskNotifications: Codable {
    let atTaskStart: NotificationTemplate
    let beforeTaskStart: NotificationTemplate
    let afterTaskEnd: NotificationTemplate
}

struct NawafilNotifications: Codable {
    let reminder: NotificationTemplate
}

struct SpecialNotifications: Codable {
    let jummah: JummahNotifications
    let ramadan: RamadanNotifications
}

struct JummahNotifications: Codable {
    let oneHourBefore: SpecialNotificationTemplate
    let thirtyMinutesBefore: SpecialNotificationTemplate
}

struct RamadanNotifications: Codable {
    let suhoorReminder: SuhoorNotificationTemplate
    let iftar: SpecialNotificationTemplate
    let last10Nights: SpecialNotificationTemplate
}

struct NotificationTemplate: Codable {
    let enabledFor: [String]?
    let proOnly: Bool?
    let defaultMinutes: Int?
    let options: [Int]?
    let titleTemplateArabic: String
    let titleTemplateEnglish: String
    let bodyTemplateArabic: String
    let bodyTemplateEnglish: String
    let sound: String
    let category: String
    let critical: Bool?
    let badgeIncrement: Int?
    let fullScreen: Bool?
    let gentleTone: Bool?
}

struct SpecialNotificationTemplate: Codable {
    let titleArabic: String
    let titleEnglish: String
    let bodyArabic: String
    let bodyEnglish: String
    let enabledByDefault: Bool?
}

struct SuhoorNotificationTemplate: Codable {
    let titleArabic: String
    let titleEnglish: String
    let bodyArabic: String
    let bodyEnglish: String
    let minutesBeforeFajr: Int
}

struct NotificationAction: Codable {
    let identifier: String
    let titleArabic: String
    let titleEnglish: String
    let foreground: Bool
    let destructive: Bool
    let snoozeMinutes: Int?
    let extendMinutes: Int?
    let proOnly: Bool?
    let optional: Bool?
}

struct NotificationCategory: Codable {
    let actions: [String]
    let intentIdentifiers: [String]
    let options: [String]
}

struct NotificationSounds: Codable {
    let adhanOptions: [AdhanOption]
    let notificationSounds: [NotificationSound]
}

struct AdhanOption: Codable, Identifiable {
    let id: String
    let nameArabic: String
    let nameEnglish: String
    let filename: String
    let durationSeconds: Int
    let pro: Bool
}

struct NotificationSound: Codable, Identifiable {
    let id: String
    let filename: String
}

struct NotificationSettings: Codable {
    let doNotDisturb: DoNotDisturbConfig
    let badge: BadgeConfig
    let delivery: DeliveryConfig
}

struct DoNotDisturbConfig: Codable {
    let respectSystemDnd: Bool
    let overrideForPrayer: Bool
    let overrideForCritical: Bool
}

struct BadgeConfig: Codable {
    let showPendingTasks: Bool
    let showPrayerCount: Bool
    let maxBadgeNumber: Int
}

struct DeliveryConfig: Codable {
    let immediate: Bool
    let provisionalAuthIfDeclined: Bool
}

struct LocalizationConfiguration: Codable {
    let version: String
    let defaultLanguage: String
    let supportedLanguages: [String]
    let strings: [String: Any]

    enum CodingKeys: String, CodingKey {
        case version
        case defaultLanguage
        case supportedLanguages
        case strings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        defaultLanguage = try container.decode(String.self, forKey: .defaultLanguage)
        supportedLanguages = try container.decode([String].self, forKey: .supportedLanguages)
        strings = try container.decode([String: Any].self, forKey: .strings)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(defaultLanguage, forKey: .defaultLanguage)
        try container.encode(supportedLanguages, forKey: .supportedLanguages)
        // strings encoding is complex, omit for now
    }
}

// MARK: - Enums

enum AppLanguage: String, Codable {
    case arabic = "ar"
    case english = "en"
}

// MARK: - Dictionary Decoding Extension

extension KeyedDecodingContainer {
    func decode(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any> {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }

    func decode(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any> {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }

    func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        var dictionary = Dictionary<String, Any>()

        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode(Array<Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: Array<Any>.Type) throws -> Array<Any> {
        var array: [Any] = []
        while isAtEnd == false {
            if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Int.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode(Array<Any>.self) {
                array.append(nestedArray)
            }
        }
        return array
    }

    mutating func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}

struct JSONCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}
