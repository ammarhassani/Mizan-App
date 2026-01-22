//
//  GamificationConfiguration.swift
//  MizanApp
//
//  Codable models for gamification configuration.
//

import Foundation

// MARK: - Root Configuration

struct GamificationConfiguration: Codable {
    let version: String
    let massSystem: MassSystemConfig
    let comboSystem: ComboSystemConfig
    let lightVelocity: LightVelocityConfig
    let orbits: [OrbitConfig]
    let achievements: [AchievementConfig]
    let dailyMissions: [MissionConfig]

    enum CodingKeys: String, CodingKey {
        case version
        case massSystem = "mass_system"
        case comboSystem = "combo_system"
        case lightVelocity = "light_velocity"
        case orbits
        case achievements
        case dailyMissions = "daily_missions"
    }
}

// MARK: - Mass System

struct MassSystemConfig: Codable {
    let baseEarnings: BaseEarningsConfig
    let bonuses: BonusesConfig

    enum CodingKeys: String, CodingKey {
        case baseEarnings = "base_earnings"
        case bonuses
    }
}

struct BaseEarningsConfig: Codable {
    let taskCompletionMin: Int
    let taskCompletionMax: Int
    let prayerInWindow: Int
    let prayerOutsideWindow: Int
    let nawafilCompletion: Int
    let dailyLogin: Int

    enum CodingKeys: String, CodingKey {
        case taskCompletionMin = "task_completion_min"
        case taskCompletionMax = "task_completion_max"
        case prayerInWindow = "prayer_in_window"
        case prayerOutsideWindow = "prayer_outside_window"
        case nawafilCompletion = "nawafil_completion"
        case dailyLogin = "daily_login"
    }
}

struct BonusesConfig: Codable {
    let dawnBonus: Int
    let nightSeal: Int
    let fullWeek: Int
    let orbitAdvancement: Int

    enum CodingKeys: String, CodingKey {
        case dawnBonus = "dawn_bonus"
        case nightSeal = "night_seal"
        case fullWeek = "full_week"
        case orbitAdvancement = "orbit_advancement"
    }
}

// MARK: - Combo System

struct ComboSystemConfig: Codable {
    let multiplierIncrement: Double
    let maxMultiplier: Double
    let timeoutSeconds: Int

    enum CodingKeys: String, CodingKey {
        case multiplierIncrement = "multiplier_increment"
        case maxMultiplier = "max_multiplier"
        case timeoutSeconds = "timeout_seconds"
    }
}

// MARK: - Light Velocity

struct LightVelocityConfig: Codable {
    let tiers: [VelocityTierConfig]
}

struct VelocityTierConfig: Codable {
    let minDays: Int
    let maxDays: Int
    let name: String
    let multiplier: Double

    enum CodingKeys: String, CodingKey {
        case minDays = "min_days"
        case maxDays = "max_days"
        case name
        case multiplier
    }
}

// MARK: - Orbit

struct OrbitConfig: Codable, Identifiable {
    let level: Int
    let massRequired: Int
    let titleEn: String
    let titleAr: String
    let unlock: String?

    var id: Int { level }

    enum CodingKeys: String, CodingKey {
        case level
        case massRequired = "mass_required"
        case titleEn = "title_en"
        case titleAr = "title_ar"
        case unlock
    }

    /// Returns localized title based on current language
    var localizedTitle: String {
        // Use AppLanguage from UserSettings if available
        // For now, default to Arabic as the app is RTL-first
        titleAr
    }
}

// MARK: - Achievement

struct AchievementConfig: Codable, Identifiable {
    let id: String
    let titleEn: String
    let titleAr: String
    let descriptionEn: String
    let descriptionAr: String
    let icon: String
    let requirementType: String
    let requirementValue: Int
    let massReward: Int
    let rarity: AchievementRarity

    enum CodingKeys: String, CodingKey {
        case id
        case titleEn = "title_en"
        case titleAr = "title_ar"
        case descriptionEn = "description_en"
        case descriptionAr = "description_ar"
        case icon
        case requirementType = "requirement_type"
        case requirementValue = "requirement_value"
        case massReward = "mass_reward"
        case rarity
    }

    var localizedTitle: String { titleAr }
    var localizedDescription: String { descriptionAr }
}

enum AchievementRarity: String, Codable {
    case common
    case rare
    case epic
    case legendary

    var color: String {
        switch self {
        case .common: return "#94a3b8"     // Gray
        case .rare: return "#3b82f6"       // Blue
        case .epic: return "#a855f7"       // Purple
        case .legendary: return "#f59e0b"  // Gold
        }
    }
}

// MARK: - Mission

struct MissionConfig: Codable, Identifiable {
    let id: String
    let titleEn: String
    let titleAr: String
    let descriptionEn: String
    let descriptionAr: String
    let requirementType: String
    let requirementValue: Int
    let massReward: Int

    enum CodingKeys: String, CodingKey {
        case id
        case titleEn = "title_en"
        case titleAr = "title_ar"
        case descriptionEn = "description_en"
        case descriptionAr = "description_ar"
        case requirementType = "requirement_type"
        case requirementValue = "requirement_value"
        case massReward = "mass_reward"
    }

    var localizedTitle: String { titleAr }
    var localizedDescription: String { descriptionAr }
}
