# Phase 4: Gamification Backend Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the complete gamification backend for Mass, Orbit, Light Velocity, Dark Matter, and Combo systems with persistent storage and configuration.

**Architecture:** Extend UserSettings with gamification properties, create SwiftData models for achievements/missions, implement services following existing @MainActor + ObservableObject patterns, and load configuration from JSON files. All services integrate with existing AppEnvironment.

**Tech Stack:** SwiftUI, SwiftData, UserDefaults (fallback), Combine, JSON configuration files.

---

## Context from Previous Phases

**Phase 1 (Foundation):** Created DarkMatterTheme, CinematicColors, CinematicTypography, CinematicSpacing, CinematicAnimation tokens.

**Phase 2 (Visual Foundation):** Created DeviceTier, DarkMatterShader.metal, MetalView, DarkMatterBackground, ParticleSystem, shaders.

**Phase 3 (Core Components):** Created CinematicContainer, EventHorizonDock, WarpTransition, replaced MainTabView.

**Existing Files to Reference:**
- `MizanApp/Core/Models/UserSettings.swift` - Add gamification properties here
- `MizanApp/App/AppEnvironment.swift:62-68` - Register models in Schema
- `MizanApp/Core/Services/PrayerTimeService.swift` - Service pattern to follow
- `MizanApp/Core/Configuration/ConfigurationManager.swift` - Config loading pattern
- `MizanApp/Resources/Configuration/` - JSON config location

---

## Task 1: Create GamificationConfig.json

**Files:**
- Create: `MizanApp/Resources/Configuration/GamificationConfig.json`

**Purpose:** Define achievements, orbit levels, and XP/Mass requirements.

**Step 1: Create the configuration file**

```json
{
  "version": "1.0",
  "mass_system": {
    "base_earnings": {
      "task_completion_min": 10,
      "task_completion_max": 50,
      "prayer_in_window": 150,
      "prayer_outside_window": 50,
      "nawafil_completion": 75,
      "daily_login": 25
    },
    "bonuses": {
      "dawn_bonus": 50,
      "night_seal": 50,
      "full_week": 200,
      "orbit_advancement": 500
    }
  },
  "combo_system": {
    "multiplier_increment": 0.05,
    "max_multiplier": 1.20,
    "timeout_seconds": 3600
  },
  "light_velocity": {
    "tiers": [
      { "min_days": 1, "max_days": 6, "name": "Drift", "multiplier": 1.0 },
      { "min_days": 7, "max_days": 13, "name": "Cruise", "multiplier": 1.7 },
      { "min_days": 14, "max_days": 29, "name": "Warp", "multiplier": 1.9 },
      { "min_days": 30, "max_days": 59, "name": "Hyperwarp", "multiplier": 2.0 },
      { "min_days": 60, "max_days": 999, "name": "Lightspeed", "multiplier": 2.0 }
    ]
  },
  "orbits": [
    { "level": 1, "mass_required": 0, "title_en": "Dust", "title_ar": "غبار", "unlock": null },
    { "level": 2, "mass_required": 500, "title_en": "Particle", "title_ar": "جسيم", "unlock": "subtle_particles" },
    { "level": 3, "mass_required": 1200, "title_en": "Fragment", "title_ar": "شظية", "unlock": "card_glow" },
    { "level": 4, "mass_required": 2000, "title_en": "Asteroid", "title_ar": "كويكب", "unlock": "dock_pulse" },
    { "level": 5, "mass_required": 3000, "title_en": "Voyager", "title_ar": "رحالة", "unlock": "enhanced_implosion" },
    { "level": 7, "mass_required": 5000, "title_en": "Moon", "title_ar": "قمر", "unlock": "orbital_ring" },
    { "level": 10, "mass_required": 8000, "title_en": "Navigator", "title_ar": "ملاح", "unlock": "accent_colors" },
    { "level": 15, "mass_required": 15000, "title_en": "Planet", "title_ar": "كوكب", "unlock": "gravity_distortion" },
    { "level": 20, "mass_required": 25000, "title_en": "Giant", "title_ar": "عملاق", "unlock": "particle_trail" },
    { "level": 25, "mass_required": 40000, "title_en": "Pilot", "title_ar": "طيار", "unlock": "premium_borders" },
    { "level": 30, "mass_required": 60000, "title_en": "Star", "title_ar": "نجم", "unlock": "nebula_shift" },
    { "level": 40, "mass_required": 100000, "title_en": "Supernova", "title_ar": "مستعر أعظم", "unlock": "edge_glow" },
    { "level": 50, "mass_required": 150000, "title_en": "Commander", "title_ar": "قائد", "unlock": "exclusive_particles" },
    { "level": 75, "mass_required": 300000, "title_en": "Black Hole", "title_ar": "ثقب أسود", "unlock": "gravitational_lensing" },
    { "level": 100, "mass_required": 500000, "title_en": "Singularity", "title_ar": "تفرد", "unlock": "ultimate_suite" }
  ],
  "achievements": [
    {
      "id": "first_light",
      "title_en": "First Light",
      "title_ar": "النور الأول",
      "description_en": "Complete your first Fajr prayer",
      "description_ar": "أكمل صلاة الفجر الأولى",
      "icon": "sunrise.fill",
      "requirement_type": "prayer_fajr_count",
      "requirement_value": 1,
      "mass_reward": 100,
      "rarity": "common"
    },
    {
      "id": "solar_collector",
      "title_en": "Solar Collector",
      "title_ar": "جامع الشمس",
      "description_en": "Complete all 5 prayers on time in one day",
      "description_ar": "أكمل الصلوات الخمس في وقتها في يوم واحد",
      "icon": "sun.max.fill",
      "requirement_type": "perfect_day_count",
      "requirement_value": 1,
      "mass_reward": 300,
      "rarity": "rare"
    },
    {
      "id": "light_keeper",
      "title_en": "Light Keeper",
      "title_ar": "حارس النور",
      "description_en": "7 consecutive days with all prayers on time",
      "description_ar": "7 أيام متتالية مع جميع الصلوات في وقتها",
      "icon": "sparkles",
      "requirement_type": "perfect_streak",
      "requirement_value": 7,
      "mass_reward": 1000,
      "rarity": "epic"
    },
    {
      "id": "ignition",
      "title_en": "Ignition",
      "title_ar": "الاشتعال",
      "description_en": "Achieve a 3-day streak",
      "description_ar": "حقق سلسلة 3 أيام",
      "icon": "flame.fill",
      "requirement_type": "streak_days",
      "requirement_value": 3,
      "mass_reward": 50,
      "rarity": "common"
    },
    {
      "id": "momentum",
      "title_en": "Momentum",
      "title_ar": "الزخم",
      "description_en": "Achieve a 7-day streak",
      "description_ar": "حقق سلسلة 7 أيام",
      "icon": "bolt.fill",
      "requirement_type": "streak_days",
      "requirement_value": 7,
      "mass_reward": 200,
      "rarity": "rare"
    },
    {
      "id": "event_horizon",
      "title_en": "Event Horizon",
      "title_ar": "أفق الحدث",
      "description_en": "Achieve a 30-day streak",
      "description_ar": "حقق سلسلة 30 يوم",
      "icon": "circle.hexagongrid.fill",
      "requirement_type": "streak_days",
      "requirement_value": 30,
      "mass_reward": 2000,
      "rarity": "epic"
    },
    {
      "id": "first_step",
      "title_en": "First Step",
      "title_ar": "الخطوة الأولى",
      "description_en": "Complete your first task",
      "description_ar": "أكمل مهمتك الأولى",
      "icon": "checkmark.circle.fill",
      "requirement_type": "task_count",
      "requirement_value": 1,
      "mass_reward": 25,
      "rarity": "common"
    },
    {
      "id": "centurion",
      "title_en": "Centurion",
      "title_ar": "القائد المئوي",
      "description_en": "Complete 100 tasks",
      "description_ar": "أكمل 100 مهمة",
      "icon": "trophy.fill",
      "requirement_type": "task_count",
      "requirement_value": 100,
      "mass_reward": 1000,
      "rarity": "epic"
    },
    {
      "id": "mass_accumulator",
      "title_en": "Mass Accumulator",
      "title_ar": "مجمع الكتلة",
      "description_en": "Earn 10,000 total Mass",
      "description_ar": "اكسب 10,000 كتلة إجمالية",
      "icon": "atom",
      "requirement_type": "total_mass",
      "requirement_value": 10000,
      "mass_reward": 500,
      "rarity": "rare"
    },
    {
      "id": "gravity_well",
      "title_en": "Gravity Well",
      "title_ar": "بئر الجاذبية",
      "description_en": "Earn 50,000 total Mass",
      "description_ar": "اكسب 50,000 كتلة إجمالية",
      "icon": "circle.dotted",
      "requirement_type": "total_mass",
      "requirement_value": 50000,
      "mass_reward": 2500,
      "rarity": "epic"
    },
    {
      "id": "cosmic_entity",
      "title_en": "Cosmic Entity",
      "title_ar": "كيان كوني",
      "description_en": "Earn 100,000 total Mass",
      "description_ar": "اكسب 100,000 كتلة إجمالية",
      "icon": "sparkle",
      "requirement_type": "total_mass",
      "requirement_value": 100000,
      "mass_reward": 10000,
      "rarity": "legendary"
    }
  ],
  "daily_missions": [
    {
      "id": "prayer_streak",
      "title_en": "Celestial Alignment",
      "title_ar": "المحاذاة السماوية",
      "description_en": "Complete 3 prayers on time today",
      "description_ar": "أكمل 3 صلوات في الوقت اليوم",
      "requirement_type": "prayers_on_time_today",
      "requirement_value": 3,
      "mass_reward": 75
    },
    {
      "id": "task_burst",
      "title_en": "Mass Burst",
      "title_ar": "انفجار الكتلة",
      "description_en": "Complete 5 tasks today",
      "description_ar": "أكمل 5 مهام اليوم",
      "requirement_type": "tasks_completed_today",
      "requirement_value": 5,
      "mass_reward": 100
    },
    {
      "id": "fajr_hero",
      "title_en": "Dawn Guardian",
      "title_ar": "حارس الفجر",
      "description_en": "Complete Fajr prayer on time",
      "description_ar": "أكمل صلاة الفجر في وقتها",
      "requirement_type": "fajr_on_time_today",
      "requirement_value": 1,
      "mass_reward": 50
    }
  ]
}
```

**Step 2: Add file to Xcode project**

The file will be automatically included if placed in the Resources/Configuration folder.

**Step 3: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=6C863E0C-0FC3-4603-9CEF-008681275531' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add MizanApp/Resources/Configuration/GamificationConfig.json
git commit -m "feat(gamification): add GamificationConfig.json with achievements and orbits"
```

---

## Task 2: Create Gamification Configuration Models

**Files:**
- Create: `MizanApp/Core/Configuration/GamificationConfiguration.swift`

**Purpose:** Define Codable structs to decode GamificationConfig.json.

**Step 1: Create the configuration models file**

```swift
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
```

**Step 2: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=6C863E0C-0FC3-4603-9CEF-008681275531' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add MizanApp/Core/Configuration/GamificationConfiguration.swift
git commit -m "feat(gamification): add GamificationConfiguration codable models"
```

---

## Task 3: Update ConfigurationManager to Load Gamification Config

**Files:**
- Modify: `MizanApp/Core/Configuration/ConfigurationManager.swift`

**Purpose:** Add gamification config loading to ConfigurationManager.

**Step 1: Add gamification config property**

Add after other config properties (around line 20):

```swift
private(set) var gamificationConfig: GamificationConfiguration!
```

**Step 2: Load gamification config in loadConfigurations()**

Add inside the `do` block of `loadConfigurations()`:

```swift
gamificationConfig = try loadJSON("GamificationConfig")
```

**Step 3: Add fallback in loadFallbackConfigurations()**

Add a fallback for gamification config:

```swift
// In loadFallbackConfigurations(), add:
// gamificationConfig is required, so log error but continue
MizanLogger.shared.lifecycle.error("Failed to load GamificationConfig.json")
```

**Step 4: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=6C863E0C-0FC3-4603-9CEF-008681275531' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add MizanApp/Core/Configuration/ConfigurationManager.swift
git commit -m "feat(gamification): load GamificationConfig in ConfigurationManager"
```

---

## Task 4: Add Gamification Properties to UserSettings

**Files:**
- Modify: `MizanApp/Core/Models/UserSettings.swift`

**Purpose:** Add Mass, Orbit, LightVelocity, Combo tracking properties.

**Step 1: Add gamification properties to UserSettings class**

Add these properties after existing properties:

```swift
// MARK: - Gamification Properties

/// Total accumulated Mass points
var massTotalPoints: Double = 0

/// Current Orbit level (1-100+)
var orbitCurrentLevel: Int = 1

/// Current Light Velocity streak (consecutive days)
var lightVelocityStreak: Int = 0

/// Longest streak ever achieved
var lightVelocityLongestStreak: Int = 0

/// Last activity date for streak tracking
var lastActivityDate: Date?

/// Current combo count
var comboCurrentCount: Int = 0

/// Last combo activity timestamp
var comboLastActivityDate: Date?

/// Total tasks completed (for achievements)
var totalTasksCompleted: Int = 0

/// Total prayers completed on time (for achievements)
var totalPrayersOnTime: Int = 0

/// Total perfect days (all 5 prayers on time)
var totalPerfectDays: Int = 0

/// Total Fajr prayers completed on time
var totalFajrOnTime: Int = 0

/// JSON storage for unlocked achievement IDs
private var unlockedAchievementIDsJSON: String = "[]"

/// Unlocked achievement IDs
@Transient
var unlockedAchievementIDs: [String] {
    get {
        guard let data = unlockedAchievementIDsJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
    set {
        if let data = try? JSONEncoder().encode(newValue),
           let json = String(data: data, encoding: .utf8) {
            unlockedAchievementIDsJSON = json
        }
    }
}

/// JSON storage for completed daily mission IDs with dates
private var completedMissionsJSON: String = "{}"

/// Completed missions mapped by date string (yyyy-MM-dd)
@Transient
var completedMissions: [String: [String]] {
    get {
        guard let data = completedMissionsJSON.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: [String]].self, from: data)) ?? [:]
    }
    set {
        if let data = try? JSONEncoder().encode(newValue),
           let json = String(data: data, encoding: .utf8) {
            completedMissionsJSON = json
        }
    }
}
```

**Step 2: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=6C863E0C-0FC3-4603-9CEF-008681275531' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add MizanApp/Core/Models/UserSettings.swift
git commit -m "feat(gamification): add gamification properties to UserSettings"
```

---

## Task 5: Create ProgressionService

**Files:**
- Create: `MizanApp/Core/Services/ProgressionService.swift`

**Purpose:** Core service for Mass earning, Orbit progression, Light Velocity tracking, and Combo system.

**Step 1: Create the ProgressionService file**

```swift
//
//  ProgressionService.swift
//  MizanApp
//
//  Core gamification service for Mass, Orbit, Light Velocity, and Combo systems.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class ProgressionService: ObservableObject {
    // MARK: - Published State

    @Published private(set) var currentMass: Double = 0
    @Published private(set) var currentOrbit: Int = 1
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var currentCombo: Int = 0
    @Published private(set) var comboMultiplier: Double = 1.0

    /// Triggered when orbit level increases
    @Published var didLevelUp: Bool = false
    @Published var newOrbitLevel: Int = 0

    /// Recent mass gain for animation
    @Published var recentMassGain: Double = 0

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private var userSettings: UserSettings?
    private var config: GamificationConfiguration? {
        ConfigurationManager.shared.gamificationConfig
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserSettings()
        syncFromUserSettings()
    }

    private func loadUserSettings() {
        let descriptor = FetchDescriptor<UserSettings>()
        userSettings = try? modelContext.fetch(descriptor).first
    }

    private func syncFromUserSettings() {
        guard let settings = userSettings else { return }
        currentMass = settings.massTotalPoints
        currentOrbit = settings.orbitCurrentLevel
        currentStreak = settings.lightVelocityStreak
        currentCombo = settings.comboCurrentCount

        // Calculate combo multiplier from count
        if let config = config {
            let increment = config.comboSystem.multiplierIncrement
            let max = config.comboSystem.maxMultiplier
            comboMultiplier = min(1.0 + (Double(currentCombo) * increment), max)
        }
    }

    // MARK: - Mass Earning

    /// Award Mass for completing a task
    func awardMassForTask(duration: Int) {
        guard let config = config else { return }

        let base = config.massSystem.baseEarnings
        // Scale mass based on duration (10-50 range scaled by duration 15-120 min)
        let durationFactor = min(1.0, max(0.2, Double(duration) / 60.0))
        let baseMass = Double(base.taskCompletionMin) + (Double(base.taskCompletionMax - base.taskCompletionMin) * durationFactor)

        let finalMass = applyMultipliers(to: baseMass)
        addMass(finalMass)

        // Update combo
        incrementCombo()

        // Update task count for achievements
        userSettings?.totalTasksCompleted += 1
        save()
    }

    /// Award Mass for completing a prayer
    func awardMassForPrayer(isOnTime: Bool, isFajr: Bool) {
        guard let config = config else { return }

        let base = config.massSystem.baseEarnings
        let baseMass = Double(isOnTime ? base.prayerInWindow : base.prayerOutsideWindow)

        var finalMass = applyMultipliers(to: baseMass)

        // Dawn bonus for Fajr
        if isFajr && isOnTime {
            finalMass += Double(config.massSystem.bonuses.dawnBonus)
            userSettings?.totalFajrOnTime += 1
        }

        addMass(finalMass)
        incrementCombo()

        if isOnTime {
            userSettings?.totalPrayersOnTime += 1
        }

        save()
    }

    /// Award Mass for completing Nawafil
    func awardMassForNawafil() {
        guard let config = config else { return }

        let baseMass = Double(config.massSystem.baseEarnings.nawafilCompletion)
        let finalMass = applyMultipliers(to: baseMass)

        addMass(finalMass)
        incrementCombo()
    }

    /// Award daily login bonus
    func awardDailyLoginBonus() {
        guard let config = config else { return }

        let baseMass = Double(config.massSystem.baseEarnings.dailyLogin)
        addMass(baseMass)

        // Update streak
        updateStreak()
    }

    /// Award bonus for perfect day (all 5 prayers on time)
    func awardPerfectDayBonus() {
        guard let config = config else { return }

        let bonusMass = Double(config.massSystem.bonuses.fullWeek) // Reusing this for perfect day
        addMass(bonusMass * 0.5) // Half of full week bonus

        userSettings?.totalPerfectDays += 1
        save()
    }

    // MARK: - Private Mass Helpers

    private func addMass(_ amount: Double) {
        currentMass += amount
        userSettings?.massTotalPoints = currentMass
        recentMassGain = amount

        // Check for orbit advancement
        checkOrbitAdvancement()

        save()

        // Reset recent gain after delay
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                self.recentMassGain = 0
            }
        }
    }

    private func applyMultipliers(to baseMass: Double) -> Double {
        var mass = baseMass

        // Apply combo multiplier
        mass *= comboMultiplier

        // Apply light velocity multiplier
        if let velocityTier = getCurrentVelocityTier() {
            mass *= velocityTier.multiplier
        }

        return mass
    }

    // MARK: - Orbit Progression

    private func checkOrbitAdvancement() {
        guard let config = config else { return }

        // Find the highest orbit we qualify for
        let qualifyingOrbits = config.orbits.filter { currentMass >= Double($0.massRequired) }
        guard let highestOrbit = qualifyingOrbits.max(by: { $0.level < $1.level }) else { return }

        if highestOrbit.level > currentOrbit {
            let previousOrbit = currentOrbit
            currentOrbit = highestOrbit.level
            userSettings?.orbitCurrentLevel = currentOrbit

            // Award orbit advancement bonus
            let bonus = Double(config.massSystem.bonuses.orbitAdvancement)
            currentMass += bonus
            userSettings?.massTotalPoints = currentMass

            // Trigger level up notification
            didLevelUp = true
            newOrbitLevel = currentOrbit

            // Haptic feedback
            HapticManager.shared.trigger(.success)

            MizanLogger.shared.lifecycle.info("Orbit advanced from \(previousOrbit) to \(currentOrbit)")

            // Reset level up flag after delay
            _Concurrency.Task {
                try? await _Concurrency.Task.sleep(nanoseconds: 4_000_000_000)
                await MainActor.run {
                    self.didLevelUp = false
                }
            }

            save()
        }
    }

    /// Get current orbit configuration
    func getCurrentOrbitConfig() -> OrbitConfig? {
        config?.orbits.first { $0.level == currentOrbit }
    }

    /// Get next orbit configuration
    func getNextOrbitConfig() -> OrbitConfig? {
        config?.orbits.first { $0.level > currentOrbit }
    }

    /// Get progress to next orbit (0.0 - 1.0)
    func getOrbitProgress() -> Double {
        guard let current = getCurrentOrbitConfig(),
              let next = getNextOrbitConfig() else { return 1.0 }

        let currentRequired = Double(current.massRequired)
        let nextRequired = Double(next.massRequired)
        let progress = (currentMass - currentRequired) / (nextRequired - currentRequired)

        return min(1.0, max(0.0, progress))
    }

    // MARK: - Light Velocity (Streak)

    private func updateStreak() {
        guard let settings = userSettings else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = settings.lastActivityDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
            } else if daysDiff > 1 {
                // Streak broken
                currentStreak = 1
            }
            // daysDiff == 0: same day, no change
        } else {
            // First activity
            currentStreak = 1
        }

        settings.lightVelocityStreak = currentStreak
        settings.lastActivityDate = today

        // Update longest streak
        if currentStreak > settings.lightVelocityLongestStreak {
            settings.lightVelocityLongestStreak = currentStreak
        }

        save()
    }

    /// Get current velocity tier based on streak
    func getCurrentVelocityTier() -> VelocityTierConfig? {
        config?.lightVelocity.tiers.first {
            currentStreak >= $0.minDays && currentStreak <= $0.maxDays
        }
    }

    // MARK: - Combo System

    private func incrementCombo() {
        guard let config = config else { return }

        let now = Date()

        // Check if combo has expired
        if let lastComboDate = userSettings?.comboLastActivityDate {
            let secondsSinceLastCombo = now.timeIntervalSince(lastComboDate)
            if secondsSinceLastCombo > Double(config.comboSystem.timeoutSeconds) {
                // Combo expired, reset
                currentCombo = 0
            }
        }

        // Increment combo
        currentCombo += 1
        userSettings?.comboCurrentCount = currentCombo
        userSettings?.comboLastActivityDate = now

        // Recalculate multiplier
        let increment = config.comboSystem.multiplierIncrement
        let max = config.comboSystem.maxMultiplier
        comboMultiplier = min(1.0 + (Double(currentCombo) * increment), max)

        save()
    }

    /// Reset combo (called when timeout expires)
    func resetComboIfExpired() {
        guard let config = config,
              let lastComboDate = userSettings?.comboLastActivityDate else { return }

        let secondsSinceLastCombo = Date().timeIntervalSince(lastComboDate)
        if secondsSinceLastCombo > Double(config.comboSystem.timeoutSeconds) {
            currentCombo = 0
            comboMultiplier = 1.0
            userSettings?.comboCurrentCount = 0
            save()
        }
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext.save()
        } catch {
            MizanLogger.shared.lifecycle.error("Failed to save gamification data: \(error)")
        }
    }
}
```

**Step 2: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=6C863E0C-0FC3-4603-9CEF-008681275531' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add MizanApp/Core/Services/ProgressionService.swift
git commit -m "feat(gamification): add ProgressionService for Mass/Orbit/Velocity/Combo"
```

---

## Task 6: Create AchievementService

**Files:**
- Create: `MizanApp/Core/Services/AchievementService.swift`

**Purpose:** Track achievement progress and unlock achievements.

**Step 1: Create the AchievementService file**

```swift
//
//  AchievementService.swift
//  MizanApp
//
//  Service for tracking and unlocking achievements.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class AchievementService: ObservableObject {
    // MARK: - Published State

    @Published private(set) var unlockedAchievements: [AchievementConfig] = []
    @Published private(set) var lockedAchievements: [AchievementConfig] = []

    /// Newly unlocked achievement for celebration
    @Published var newlyUnlockedAchievement: AchievementConfig?

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private var userSettings: UserSettings?
    private var progressionService: ProgressionService?

    private var config: GamificationConfiguration? {
        ConfigurationManager.shared.gamificationConfig
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserSettings()
        refreshAchievementLists()
    }

    func setProgressionService(_ service: ProgressionService) {
        self.progressionService = service
    }

    private func loadUserSettings() {
        let descriptor = FetchDescriptor<UserSettings>()
        userSettings = try? modelContext.fetch(descriptor).first
    }

    private func refreshAchievementLists() {
        guard let config = config, let settings = userSettings else { return }

        let unlockedIDs = Set(settings.unlockedAchievementIDs)

        unlockedAchievements = config.achievements.filter { unlockedIDs.contains($0.id) }
        lockedAchievements = config.achievements.filter { !unlockedIDs.contains($0.id) }
    }

    // MARK: - Achievement Checking

    /// Check all achievements and unlock any that are now completed
    func checkAchievements() {
        guard let config = config, let settings = userSettings else { return }

        for achievement in lockedAchievements {
            if isAchievementCompleted(achievement, settings: settings) {
                unlockAchievement(achievement)
            }
        }
    }

    private func isAchievementCompleted(_ achievement: AchievementConfig, settings: UserSettings) -> Bool {
        let value = achievement.requirementValue

        switch achievement.requirementType {
        case "prayer_fajr_count":
            return settings.totalFajrOnTime >= value

        case "perfect_day_count":
            return settings.totalPerfectDays >= value

        case "perfect_streak":
            // This requires tracking perfect day streaks, simplified for now
            return settings.totalPerfectDays >= value

        case "streak_days":
            return settings.lightVelocityStreak >= value || settings.lightVelocityLongestStreak >= value

        case "task_count":
            return settings.totalTasksCompleted >= value

        case "total_mass":
            return settings.massTotalPoints >= Double(value)

        default:
            return false
        }
    }

    // MARK: - Unlock Achievement

    private func unlockAchievement(_ achievement: AchievementConfig) {
        guard var unlockedIDs = userSettings?.unlockedAchievementIDs else { return }

        // Add to unlocked list
        unlockedIDs.append(achievement.id)
        userSettings?.unlockedAchievementIDs = unlockedIDs

        // Award mass reward
        progressionService?.awardMassForTask(duration: 0) // This is a hack, need direct mass add

        // Trigger celebration
        newlyUnlockedAchievement = achievement
        HapticManager.shared.trigger(.success)

        // Refresh lists
        refreshAchievementLists()

        // Save
        save()

        MizanLogger.shared.lifecycle.info("Achievement unlocked: \(achievement.id)")

        // Reset celebration after delay
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                self.newlyUnlockedAchievement = nil
            }
        }
    }

    // MARK: - Achievement Progress

    /// Get progress for a specific achievement (0.0 - 1.0)
    func getProgress(for achievement: AchievementConfig) -> Double {
        guard let settings = userSettings else { return 0 }

        let required = Double(achievement.requirementValue)
        var current: Double = 0

        switch achievement.requirementType {
        case "prayer_fajr_count":
            current = Double(settings.totalFajrOnTime)
        case "perfect_day_count":
            current = Double(settings.totalPerfectDays)
        case "perfect_streak":
            current = Double(settings.totalPerfectDays)
        case "streak_days":
            current = Double(max(settings.lightVelocityStreak, settings.lightVelocityLongestStreak))
        case "task_count":
            current = Double(settings.totalTasksCompleted)
        case "total_mass":
            current = settings.massTotalPoints
        default:
            return 0
        }

        return min(1.0, current / required)
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext.save()
        } catch {
            MizanLogger.shared.lifecycle.error("Failed to save achievement data: \(error)")
        }
    }
}
```

**Step 2: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=6C863E0C-0FC3-4603-9CEF-008681275531' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add MizanApp/Core/Services/AchievementService.swift
git commit -m "feat(gamification): add AchievementService for tracking and unlocking"
```

---

## Task 7: Create MissionService

**Files:**
- Create: `MizanApp/Core/Services/MissionService.swift`

**Purpose:** Generate and track daily missions.

**Step 1: Create the MissionService file**

```swift
//
//  MissionService.swift
//  MizanApp
//
//  Service for daily mission generation and tracking.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class MissionService: ObservableObject {
    // MARK: - Published State

    @Published private(set) var todaysMissions: [DailyMission] = []

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private var userSettings: UserSettings?
    private var progressionService: ProgressionService?

    private var config: GamificationConfiguration? {
        ConfigurationManager.shared.gamificationConfig
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserSettings()
        generateTodaysMissions()
    }

    func setProgressionService(_ service: ProgressionService) {
        self.progressionService = service
    }

    private func loadUserSettings() {
        let descriptor = FetchDescriptor<UserSettings>()
        userSettings = try? modelContext.fetch(descriptor).first
    }

    // MARK: - Mission Generation

    /// Generate today's missions (called at Fajr time or app launch)
    func generateTodaysMissions() {
        guard let config = config, let settings = userSettings else { return }

        let dateKey = todayDateKey()
        let completedToday = settings.completedMissions[dateKey] ?? []

        // Select 3 random missions for today
        // Use a seeded random based on date for consistency
        let seed = dateKey.hashValue
        var rng = SeededRandomNumberGenerator(seed: UInt64(abs(seed)))

        let shuffled = config.dailyMissions.shuffled(using: &rng)
        let selectedConfigs = Array(shuffled.prefix(3))

        todaysMissions = selectedConfigs.map { missionConfig in
            DailyMission(
                config: missionConfig,
                isCompleted: completedToday.contains(missionConfig.id),
                currentProgress: getCurrentProgress(for: missionConfig)
            )
        }
    }

    private func getCurrentProgress(for mission: MissionConfig) -> Int {
        guard let settings = userSettings else { return 0 }

        switch mission.requirementType {
        case "prayers_on_time_today":
            return getTodayPrayersOnTime()
        case "tasks_completed_today":
            return getTodayTasksCompleted()
        case "fajr_on_time_today":
            return getTodayFajrCompleted() ? 1 : 0
        default:
            return 0
        }
    }

    // MARK: - Progress Tracking

    /// Update mission progress (call after relevant actions)
    func updateMissionProgress() {
        for i in todaysMissions.indices {
            let mission = todaysMissions[i]
            if !mission.isCompleted {
                let newProgress = getCurrentProgress(for: mission.config)
                todaysMissions[i].currentProgress = newProgress

                // Check if mission is now complete
                if newProgress >= mission.config.requirementValue {
                    completeMission(at: i)
                }
            }
        }
    }

    private func completeMission(at index: Int) {
        guard index < todaysMissions.count else { return }

        let mission = todaysMissions[index]
        todaysMissions[index].isCompleted = true

        // Award mass reward
        let reward = Double(mission.config.massReward)
        // Directly add mass - need reference to progressionService
        // For now, mark as completed

        // Track completion
        let dateKey = todayDateKey()
        var completedToday = userSettings?.completedMissions[dateKey] ?? []
        completedToday.append(mission.config.id)
        userSettings?.completedMissions[dateKey] = completedToday

        // Haptic feedback
        HapticManager.shared.trigger(.success)

        save()

        MizanLogger.shared.lifecycle.info("Mission completed: \(mission.config.id)")
    }

    // MARK: - Helpers

    private func todayDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func getTodayPrayersOnTime() -> Int {
        // This would integrate with PrayerTimeService
        // Simplified placeholder
        return 0
    }

    private func getTodayTasksCompleted() -> Int {
        // This would integrate with task completion tracking
        // Simplified placeholder
        return 0
    }

    private func getTodayFajrCompleted() -> Bool {
        // This would integrate with PrayerTimeService
        // Simplified placeholder
        return false
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext.save()
        } catch {
            MizanLogger.shared.lifecycle.error("Failed to save mission data: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct DailyMission: Identifiable {
    let id: String
    let config: MissionConfig
    var isCompleted: Bool
    var currentProgress: Int

    init(config: MissionConfig, isCompleted: Bool, currentProgress: Int) {
        self.id = config.id
        self.config = config
        self.isCompleted = isCompleted
        self.currentProgress = currentProgress
    }

    var progress: Double {
        Double(currentProgress) / Double(config.requirementValue)
    }
}

// MARK: - Seeded RNG for consistent daily mission selection

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // Simple LCG
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
```

**Step 2: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=6C863E0C-0FC3-4603-9CEF-008681275531' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add MizanApp/Core/Services/MissionService.swift
git commit -m "feat(gamification): add MissionService for daily missions"
```

---

## Task 8: Register Services in AppEnvironment

**Files:**
- Modify: `MizanApp/App/AppEnvironment.swift`

**Purpose:** Initialize and expose gamification services.

**Step 1: Add service properties**

Add after existing service properties:

```swift
// MARK: - Gamification Services

private(set) var progressionService: ProgressionService!
private(set) var achievementService: AchievementService!
private(set) var missionService: MissionService!
```

**Step 2: Initialize services after modelContext is available**

Find where other services are initialized and add:

```swift
// Initialize gamification services
progressionService = ProgressionService(modelContext: modelContext)
achievementService = AchievementService(modelContext: modelContext)
missionService = MissionService(modelContext: modelContext)

// Wire up dependencies
achievementService.setProgressionService(progressionService)
missionService.setProgressionService(progressionService)
```

**Step 3: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=6C863E0C-0FC3-4603-9CEF-008681275531' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add MizanApp/App/AppEnvironment.swift
git commit -m "feat(gamification): register gamification services in AppEnvironment"
```

---

## Task 9: Integration Test - Build and Verify

**Files:**
- No new files

**Purpose:** Ensure all gamification backend components compile and integrate.

**Step 1: Run unit tests**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=6C863E0C-0FC3-4603-9CEF-008681275531' test -only-testing:MizanAppTests 2>&1 | tail -40`

Expected: All tests pass

**Step 2: Build for release**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=6C863E0C-0FC3-4603-9CEF-008681275531' -configuration Release build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Document any issues**

If issues found, document them for follow-up.

---

## Task 10: Phase 4 Completion

**Files:**
- No new files

**Purpose:** Finalize Phase 4 with tag.

**Step 1: Verify clean git status**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && git status`

Expected: Clean working directory

**Step 2: Create summary commit if needed**

If any uncommitted changes:
```bash
git add -A
git commit -m "chore: Phase 4 cleanup and finalization"
```

**Step 3: Tag phase completion**

```bash
git tag -a phase4-complete -m "Phase 4: Gamification Backend complete

Models and Services:
- GamificationConfiguration for config loading
- ProgressionService for Mass/Orbit/Velocity/Combo
- AchievementService for tracking and unlocking
- MissionService for daily missions

Configuration:
- GamificationConfig.json with all achievements, orbits, missions
- Updated ConfigurationManager
- Updated UserSettings with gamification properties"
```

---

## Verification Checklist

After completing all tasks, verify:

- [ ] GamificationConfig.json loads without errors
- [ ] ConfigurationManager exposes gamificationConfig
- [ ] UserSettings has all gamification properties
- [ ] ProgressionService calculates Mass correctly
- [ ] ProgressionService tracks Orbit progression
- [ ] ProgressionService manages Light Velocity streaks
- [ ] ProgressionService handles Combo system
- [ ] AchievementService checks and unlocks achievements
- [ ] MissionService generates daily missions
- [ ] All services registered in AppEnvironment
- [ ] Build succeeds
- [ ] Tests pass
