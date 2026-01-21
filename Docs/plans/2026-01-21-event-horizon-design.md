# "The Event Horizon" - Cinematic UI Overhaul

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform Mizan from a basic task/prayer app into a cinematic, gamified cosmic experience with Christopher Nolan-inspired aesthetics and real-time Metal shader backgrounds.

**Architecture:** Single Dark Matter theme with fluid Metal shader simulation, gamification system (Mass/Orbit/Light Velocity), EventHorizonDock navigation, and glass shard card components. All existing themes deleted. Pro monetization shifts to gamification and AI features while preserving existing Pro gates (Nawafil, Adhan customization).

**Tech Stack:** SwiftUI, Metal Shaders, Core Animation, Core Haptics, UserDefaults/SwiftData for gamification persistence.

---

## Table of Contents

1. [Core Identity & Theme](#section-1-core-identity--theme)
2. [Gamification System](#section-2-gamification-system)
3. [Visual Foundation](#section-3-visual-foundation)
4. [UI Components](#section-4-ui-components)
5. [Screens & Flows](#section-5-screens--flows)
6. [Animations & Transitions](#section-6-animations--transitions)
7. [Technical Architecture](#section-7-technical-architecture)
8. [Implementation Phases](#section-8-implementation-phases)

---

## Section 1: Core Identity & Theme

### Single Theme: Dark Matter

All existing themes (Noor, Layl, Fajr, Sahara, Ramadan) are **deleted**. One unified cinematic identity.

### Color Palette

| Token | Value | Usage |
|-------|-------|-------|
| `voidBlack` | `#050508` | Primary background |
| `darkMatter` | `#0a0a1a` | Fluid simulation base |
| `accentCyan` | `#7fdbff` | Interactions, highlights, default accent |
| `prayerGold` | `#ffd700` | Prayer-related elements |
| `glassSurface` | `#FFFFFF` @ 6% | Card backgrounds |
| `textPrimary` | `#e8e8e8` | Primary text |
| `textSecondary` | `#6b7280` | Secondary text |
| `success` | `#22c55e` | Success states |
| `warning` | `#f59e0b` | Warnings, amber |
| `error` | `#ef4444` | Errors, destructive |

### Pro Monetization

**Existing Pro Features (Keep Gated):**
- Mizan AI Chat - Full AI assistant access
- Nawafil Settings - Bonus prayer configuration
- Adhan Customization - Premium adhan sounds (Makkah, Cairo, etc.)
- Prayer Time Offsets - Manual adjustment per prayer
- Advanced Notification Settings

**New Pro Features (Event Horizon):**
- Full Gamification System (Orbit progression beyond Orbit 3)
- Achievements system
- Daily/Weekly missions
- Dark Matter currency earning
- Accent Color Customization (Orbit 10+ AND Pro)
- Advanced Statistics Dashboard
- Cosmetic Unlockables
- Seasonal Event Participation

**Free Tier Includes:**
- Core prayer times and notifications
- Basic task management
- Timeline view with Dark Matter background
- Gamification preview (Mass/Orbit visible, capped at Orbit 3)
- Basic completion animations
- Default accent color (cyan only)

---

## Section 2: Gamification System

### Core Metrics

| Metric | Old Term | Description | Display |
|--------|----------|-------------|---------|
| **Mass** | XP | High-precision points (1,247.83) | Animated counter with decimals |
| **Orbit** | Level | Progression tier (1-100+) | Orbital ring visualization |
| **Light Velocity** | Streak | Consecutive days | Velocity trail effect |
| **Dark Matter** | Currency | Premium currency | Glowing particle count |

### Mass Earning

```
BASE EARNINGS:
├─ Task Completion:          +10-50 Mass (scales with duration)
├─ Prayer In-Window:         +150 Mass (Power Source)
├─ Prayer Outside Window:    +50 Mass
├─ Nawafil (Bonus Prayers):  +75 Mass each
└─ Daily Login:              +25 Mass

MULTIPLIERS (Stack):
├─ Light Velocity:           +10% per day (max +100%)
├─ Prayer Window Bonus:      ×3 for in-window prayers
├─ Combo Chain:              +5% per consecutive completion (resets after 1hr idle)
├─ Perfect Day:              ×1.5 if all 5 prayers completed in-window
└─ Ramadan Season:           ×2 all earnings during Hijri month 9

BONUSES:
├─ First prayer of day:      +50 Mass "Dawn Bonus"
├─ Last prayer of day:       +50 Mass "Night Seal"
├─ Full Week Completion:     +200 Mass
└─ Orbit Advancement:        +500 Mass milestone
```

### Combo System - "Gravitational Chaining"

```
Action 1:     1.0x
Action 2:     1.05x  (+5%)
Action 3:     1.10x  (+10%)
Action 4:     1.15x  (+15%)
Action 5+:    1.20x  (cap)

Visual: Each completion creates a "gravity thread" connecting to the last.
        Chain breaks after 60 minutes of inactivity.
```

### Light Velocity (Streak System)

| Days | Velocity | Multiplier | Visual |
|------|----------|------------|--------|
| 1-6 | Drift | 1.0x - 1.6x | Slow particle drift |
| 7-13 | Cruise | 1.7x - 1.9x | Steady particle stream |
| 14-29 | Warp | 1.9x - 2.0x | Stretched light trails |
| 30-59 | Hyperwarp | 2.0x + glow | Intense motion blur aura |
| 60+ | Lightspeed | 2.0x + special | Permanent light trail on avatar |

**Streak Protection:**
- "Gravity Anchor" (costs 100 Dark Matter): Protects one missed day
- Earned 1 free Anchor every 30 days of streak

### Orbit Progression

| Orbit | Mass Required | Title | Unlock |
|-------|---------------|-------|--------|
| 1 | 0 | Dust | Base experience |
| 2 | 500 | Particle | Subtle background particles |
| 3 | 1,200 | Fragment | Card glow effect |
| 4 | 2,000 | Asteroid | Dock pulse animation |
| 5 | 3,000 | **Voyager** | Enhanced implosion effect |
| 7 | 5,000 | Moon | Orbital ring around profile |
| 10 | 8,000 | **Navigator** | Accent color customization (5 colors) |
| 15 | 15,000 | Planet | Gravitational distortion on cards |
| 20 | 25,000 | Giant | Particle trail on interactions |
| 25 | 40,000 | **Pilot** | Premium card borders (3 styles) |
| 30 | 60,000 | Star | Background nebula color shift |
| 40 | 100,000 | Supernova | Screen-edge glow effect |
| 50 | 150,000 | **Commander** | Exclusive particle system |
| 75 | 300,000 | Black Hole | Gravitational lensing on UI |
| 100 | 500,000 | **Singularity** | Ultimate visual suite + title |

### Achievements

**Prayer Achievements:**
| Achievement | Requirement | Reward |
|-------------|-------------|--------|
| First Light | Complete first Fajr | +100 Mass, Badge |
| Solar Collector | All 5 prayers in-window (1 day) | +300 Mass |
| Light Keeper | 7 consecutive days all prayers in-window | +1,000 Mass, Title |
| Devoted | 30 days all prayers in-window | +5,000 Mass, Card Border |
| Eternal Dawn | 100 Fajr prayers in-window | +10,000 Mass, Avatar Glow |

**Streak Achievements:**
| Achievement | Requirement | Reward |
|-------------|-------------|--------|
| Ignition | 3-day streak | +50 Mass |
| Momentum | 7-day streak | +200 Mass, Badge |
| Unstoppable | 14-day streak | +500 Mass |
| Event Horizon | 30-day streak | +2,000 Mass, Title |
| Time Dilation | 60-day streak | +5,000 Mass, Particle Effect |
| Eternal Velocity | 100-day streak | +15,000 Mass, Legendary Border |

**Productivity Achievements:**
| Achievement | Requirement | Reward |
|-------------|-------------|--------|
| First Step | Complete first task | +25 Mass |
| Centurion | 100 tasks completed | +1,000 Mass |
| Mass Accumulator | 10,000 total Mass | Badge |
| Gravity Well | 50,000 total Mass | Title |
| Cosmic Entity | 100,000 total Mass | Ultimate Badge |

**Hidden Achievements:**
| Achievement | Requirement | Reward |
|-------------|-------------|--------|
| Night Owl | Complete task between 2-4 AM | +100 Mass, Secret Badge |
| Speed of Light | Complete 5 tasks in 5 minutes | +200 Mass |
| Patience | Stare at loading screen for 30s | +50 Mass, Easter Egg |
| The Void | Open app at exactly midnight | +150 Mass |
| Cosmic Alignment | Complete prayer exactly as Adhan starts | +500 Mass, Rare Title |

### Daily Missions

Each day, 3 missions rotate (refresh at Fajr time):

```
PRAYER MISSIONS:
├─ "Dawn Raider": Complete Fajr within 15 min of Adhan    (+75 Mass)
├─ "Solar Peak": Complete Dhuhr in-window                 (+50 Mass)
├─ "Golden Hour": Complete Asr in-window                  (+50 Mass)
├─ "Twilight": Complete Maghrib within 10 min             (+75 Mass)
├─ "Deep Space": Complete Isha before midnight            (+50 Mass)

TASK MISSIONS:
├─ "Momentum": Complete 3 tasks today                     (+100 Mass)
├─ "Focus": Complete a task over 30 minutes               (+75 Mass)
├─ "Quick Strike": Complete 3 tasks under 15 min each     (+100 Mass)
├─ "Clear Orbit": Clear all tasks from inbox              (+150 Mass)

COMBO MISSIONS:
├─ "Chain Reaction": Reach 5x combo chain                 (+100 Mass)
├─ "Perfect Orbit": Complete all 5 prayers + 3 tasks      (+250 Mass)
├─ "Mass Harvest": Earn 500 Mass today                    (+100 bonus Mass)
```

### Weekly Challenge

One major challenge per week:
- "Supernova Week": Earn 3,000 Mass in 7 days → +1,000 bonus Mass + cosmetic
- "Light Year": 7-day perfect streak → +2,000 Mass + rare particle effect
- "Orbital Cleanup": Complete 30 tasks in 7 days → +1,500 Mass

### Seasonal Events

**Ramadan Event - "The Sacred Month":**
- Duration: Entire Hijri month 9
- All Mass earnings ×2
- Special Ramadan achievements unlocked
- Exclusive "Crescent" particle effect (limited time)
- Suhoor/Iftar prayer bonuses (+200 Mass each)
- 30-day Ramadan completion → Legendary "Blessed" title + unique card border

**Eid Events:**
- Eid al-Fitr: 3-day celebration, +500 Mass daily login bonus
- Eid al-Adha: Special achievement set, exclusive cosmetics

**Lunar Events (Monthly):**
- New Moon: Mystery bonus Mass (random 100-500)
- Full Moon: All multipliers +25% for 24 hours

### Dark Matter Economy

**Earning Dark Matter:**
```
├─ Daily Login (Day 7):           +5 Dark Matter
├─ Orbit Advancement:             +10 Dark Matter
├─ Weekly Challenge Completion:   +15 Dark Matter
├─ Achievement Completion:        +5-25 Dark Matter
├─ Seasonal Event Completion:     +50 Dark Matter
└─ Purchase:                      Real money (Pro feature)
```

**Spending Dark Matter:**
```
COSMETICS:
├─ Accent Glow Colors:            50 DM each (beyond free 5)
├─ Card Border Styles:            100-300 DM
├─ Particle Effects:              150-500 DM
├─ Titles:                        75-200 DM
├─ Dock Animations:               200 DM
└─ Background Nebula Tints:       250 DM

UTILITY:
├─ Gravity Anchor (streak save):  100 DM
├─ Mass Boost (2x for 24hr):      150 DM
└─ Mission Reroll:                25 DM
```

---

## Section 3: Visual Foundation

### Dark Matter Background (Metal Shader)

A real-time fluid simulation written in Metal.

**Shader Architecture:**
```
DarkMatterShader.metal
├─ Uniforms:
│   ├─ time: Float (continuous animation driver)
│   ├─ touchPosition: Float2 (user interaction point)
│   ├─ touchIntensity: Float (0-1, fades after touch)
│   ├─ scrollVelocity: Float (drives time dilation)
│   ├─ prayerPeriod: Int (0-5, affects color temperature)
│   └─ density: Float (fluid thickness)
│
├─ Noise Functions:
│   ├─ Simplex 3D noise (base turbulence)
│   ├─ Fractal Brownian Motion (layered detail)
│   └─ Curl noise (fluid-like movement)
│
└─ Output: Swirling nebula with depth layers
```

**Interaction Behaviors:**
| Input | Effect |
|-------|--------|
| Idle | Slow, hypnotic swirl (~0.1 speed) |
| Touch | Gravitational well forms at finger |
| Scroll | Time dilation - fast scroll stretches fluid |
| Prayer shift | Color temperature transitions |

**Prayer Period Colors:**
```
Fajr (First Light):      Deep blue → soft gold emerging
Sunrise:                 Gold ribbons through deep blue
Dhuhr (Solar Zenith):    Warm amber threads in void
Asr (Golden Descent):    Copper and bronze swirls
Maghrib (Solar Collapse): Deep red collapsing to purple
Isha (Deep Void):        Pure deep blue-black, subtle cyan wisps
```

**Performance Tiers:**
| Feature | High (A14+) | Medium (A12-13) | Low (A11-) |
|---------|-------------|-----------------|------------|
| Shader Res | 100% | 75% | 50% |
| Target FPS | 60 | 60 | 30 |
| Particles | 200 | 100 | 50 |
| Noise Octaves | 4 | 3 | 2 |

### Layered Depth System

```
Z-Index Stack (back to front):
├─ Layer 0: Dark Matter fluid simulation (Metal shader)
├─ Layer 1: Distant star field (subtle, static points)
├─ Layer 2: Prayer anchor points (glowing fixed orbs)
├─ Layer 3: Floating glass cards (parallax responsive)
├─ Layer 4: UI elements (dock, headers)
└─ Layer 5: Overlays (modals, celebrations)
```

### Glass Shard Material

```
Material Properties:
├─ Base: #FFFFFF at 6% opacity
├─ Blur: 20pt gaussian (frosted effect)
├─ Grain: Subtle noise texture overlay (2% opacity)
├─ Border: 1px glow line (#7fdbff at 40% opacity)
├─ Border Animation: Slow pulse (2s cycle)
├─ Corner Radius: 16pt
├─ Shadow: Soft cyan glow beneath (8pt spread, 15% opacity)
```

### Particle System

```
Particle Types:
├─ Dust:       Tiny (2px), slow drift, white 20% opacity
├─ Stars:      Small (4px), static twinkle, white 60% opacity
├─ Embers:     Medium (6px), float upward near prayers, gold
└─ Wisps:      Elongated (2x8px), follow fluid flow, cyan
```

---

## Section 4: UI Components

### EventHorizonDock

**Collapsed State:**
- Single glowing point (12px diameter)
- Position: Bottom center, 24pt from safe area
- Slow pulse animation (2s cycle)
- Tap to expand

**Expanded State:**
- Elliptical ring (280pt wide × 80pt tall)
- 4 navigation icons orbit the center
- Slow continuous rotation (30s full cycle)
- Auto-collapse after 3s idle

**Dock Items:**
| Position | Icon | Label | Destination |
|----------|------|-------|-------------|
| Top | Timeline glyph | TIMELINE | TimelineView |
| Right | Inbox glyph | INBOX | InboxView |
| Bottom | AI glyph | MIZAN AI | AIChatView |
| Left | Gear glyph | SETTINGS | SettingsView |

### CinematicTypography

```swift
// DISPLAY - Massive impact headers
displayLarge: 56pt, bold, +6 tracking
displayMedium: 44pt, bold, +4 tracking

// HEADLINES - Section headers, ALL CAPS
headlineLarge: 28pt, semibold, +3 tracking
headlineMedium: 22pt, semibold, +2 tracking

// DATA - Numbers, stats, Mass display
dataLarge: 32pt, medium, monospaced
dataMedium: 20pt, medium, monospaced
dataSmall: 14pt, medium, monospaced

// BODY - Regular reading text
bodyLarge: 17pt, regular
bodyMedium: 15pt, regular
bodySmall: 13pt, regular

// LABELS - Small metadata, ALL CAPS
labelLarge: 12pt, semibold, +1.5 tracking
labelMedium: 10pt, semibold, +1.2 tracking
```

### Prayer Cards - "Celestial Anchors"

Prayers as luminous fixed points with cosmic naming:
- Fajr = "First Light"
- Dhuhr = "Solar Zenith"
- Asr = "Golden Descent"
- Maghrib = "Solar Collapse"
- Isha = "Deep Void"

**Card Structure:**
```
┌─────────────────────────────────────────┐
│  ◉ FAJR                    04:52 AM     │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│  First Light · +150 Mass in window      │
│  ○ ○ ○ ● ○                 [COMPLETE]   │
└─────────────────────────────────────────┘
```

### Task Cards - "Floating Mass"

```
┌─────────────────────────────────────────┐
│  📋  Weekly Review                      │
│  ─────────────────────────────          │
│  30 min · Work · +35 Mass               │
│                              ☐          │
└─────────────────────────────────────────┘
```

**Category Glow Accents:**
- Work: Blue (#3b82f6)
- Personal: Purple (#8b5cf6)
- Health: Green (#22c55e)
- Learning: Amber (#f59e0b)
- Worship: Gold (#ffd700)
- Other: Cyan (#7fdbff)

### Orbital Status Header

```
┌─────────────────────────────────────────────────────┐
│                    ORBIT 7                          │
│               ═══════●═══════                       │
│                   NAVIGATOR                         │
│                                                     │
│   ◈ 4,892.47        ⚡ 1.7×        🔥 12 days      │
└─────────────────────────────────────────────────────┘
```

### Haptic Feedback (Minimal Accents)

- **Task Completion**: Building pulse → sharp "collapse" impact
- **Dock Expansion**: Soft "bloom" haptic
- **Dock Selection**: Crisp "lock" tap
- **Orbit Level Up**: 3 ascending pulses
- **Errors**: Single sharp warning tap

---

## Section 5: Screens & Flows

### Timeline View - "Mission Control"

Primary screen with vertical timeline, prayers as celestial anchors.

**Features:**
- Orbital Status header (fixed)
- Prayer anchor cards (luminous fixed points)
- Task cards floating between prayers
- Current time indicator (glowing line with pulse)
- Pinch-to-zoom (3 levels)
- Pull-down gravity stretch effect
- Scroll velocity affects background time dilation

### Inbox View - "Mass Repository"

Task management hub with filtering.

**Features:**
- Glass filter chips (category, status)
- Task list with swipe actions
- Swipe right: Complete (implosion)
- Swipe left: Delete (disintegration)
- New task materialization animation
- Potential Mass display per task

### AI Chat View - "Mizan Intelligence"

Pro feature with cinematic styling.

**Features:**
- Glowing orb AI avatar
- Glass message bubbles
- Typing indicator (orbiting dots)
- Quick action suggestions
- Inline task creation cards

### Settings View - "System Configuration"

**Sections:**
- Account (Pro status, Orbit, Mass)
- Prayer Settings (calculation, location, notifications)
- Display (accent color, particles, reduce motion)
- Data (export, refresh, cache)
- About (achievements, statistics, version)

### Onboarding - "Mission Briefing"

4-screen introduction:
1. "Welcome to the Void" - Tap to begin
2. "Your Actions Have Mass" - Explain Mass earning
3. "Build Light Velocity" - Explain streaks
4. "Reach New Orbits" - Show progression

### Paywall - "Unlock the Singularity"

Cinematic Pro upgrade prompt with feature list and glowing CTA.

---

## Section 6: Animations & Transitions

### Animation Tokens

```swift
// SPRINGS
gentle: response 0.5, damping 0.8
snappy: response 0.3, damping 0.9
elastic: response 0.4, damping 0.6
dramatic: response 0.6, damping 0.5

// CONTINUOUS
pulse: 2.0s, repeat forever
drift: 30.0s, linear, repeat
breathe: 3.0s, repeat forever

// SPECIAL
warp: 0.3s ease-in-out
implosion: 0.8s ease-in
materialization: 0.5s spring
orbitLevelUp: 0.6s spring, damping 0.4
```

### Key Sequences

**Task Implosion (Gravitational Pull) - 0.8s:**
1. 0-0.3s: Card edges warp inward, haptic begins
2. 0.3-0.6s: Particles rush toward center, card stretches
3. 0.6-0.75s: Collapse to bright point, flash
4. 0.75-0.8s: Ripple emanates, Mass counter updates

**Tab Warp Transition - 0.3s:**
1. Current view motion blurs in exit direction
2. Brief void moment
3. New view slides in with settle bounce

**Dock Expansion - 0.4s:**
1. Point brightens
2. Ring outline expands
3. Icons spiral outward with trails
4. Icons settle with elastic bounce

**Orbit Level Up - 2.0s:**
1. Screen edges pulse
2. Current orbit ring expands
3. New ring forms, title appears
4. Particle burst celebration

### Reduced Motion Support

When enabled:
- Implosion → Instant fade out
- Warp → Cross-fade
- Dock expansion → Instant state change
- Background shader → Static gradient
- Particles → Disabled

---

## Section 7: Technical Architecture

### New File Structure

```
MizanApp/
├─ Core/
│   ├─ DesignSystem/
│   │   ├─ Theme/
│   │   │   └─ DarkMatterTheme.swift (NEW)
│   │   ├─ Tokens/
│   │   │   ├─ CinematicTypography.swift (NEW)
│   │   │   ├─ CinematicAnimation.swift (NEW)
│   │   │   ├─ CinematicSpacing.swift (NEW)
│   │   │   └─ CinematicColors.swift (NEW)
│   │   ├─ Shaders/
│   │   │   ├─ DarkMatterShader.metal (NEW)
│   │   │   ├─ WarpTransitionShader.metal (NEW)
│   │   │   ├─ ImplosionShader.metal (NEW)
│   │   │   └─ GlassShader.metal (NEW)
│   │   └─ Components/
│   │       ├─ DarkMatterBackground.swift (NEW)
│   │       ├─ CinematicContainer.swift (NEW)
│   │       ├─ EventHorizonDock.swift (NEW)
│   │       ├─ OrbitalStatusHeader.swift (NEW)
│   │       ├─ ParticleSystem.swift (NEW)
│   │       ├─ ImplosionEffect.swift (NEW)
│   │       ├─ MaterializationEffect.swift (NEW)
│   │       ├─ WarpTransition.swift (NEW)
│   │       └─ MassCounter.swift (NEW)
│   │
│   └─ Gamification/ (NEW)
│       ├─ Models/
│       │   ├─ CosmicProgression.swift
│       │   ├─ Achievement.swift
│       │   ├─ DailyMission.swift
│       │   └─ CosmicReward.swift
│       ├─ Services/
│       │   ├─ ProgressionService.swift
│       │   ├─ AchievementService.swift
│       │   ├─ MissionService.swift
│       │   ├─ StreakService.swift
│       │   └─ RewardService.swift
│       └─ ViewModels/
│           ├─ ProgressionViewModel.swift
│           └─ AchievementViewModel.swift
│
├─ Features/
│   ├─ Timeline/ (MODIFY)
│   ├─ TaskManagement/ (MODIFY)
│   ├─ AIChat/ (MODIFY styling)
│   ├─ Settings/ (MAJOR MODIFY)
│   ├─ Onboarding/ (REPLACE)
│   ├─ Gamification/ (NEW)
│   └─ Paywall/ (MODIFY)
│
└─ Resources/
    └─ Configuration/
        ├─ ThemeConfig.json (MODIFY)
        ├─ GamificationConfig.json (NEW)
        ├─ AchievementsConfig.json (NEW)
        └─ MissionsConfig.json (NEW)
```

### Files to Delete

- ThemeSelectionView.swift
- All theme assets for: Noor, Fajr, Sahara, Ramadan
- Extra app icons for other themes
- GlassmorphicPrayerCard.swift (replaced)
- PremiumTaskCard.swift (replaced)
- AnimatedOnboardingBackground.swift (replaced)

### Data Model Changes

**UserSettings.swift additions:**
```swift
// Cosmic Progression
var currentMass: Double = 0.0
var currentOrbit: Int = 1
var lightVelocity: Int = 0
var lightVelocityMultiplier: Double = 1.0
var lastActiveDate: Date?
var darkMatterBalance: Int = 0

// Lifetime Stats
var totalMassEarned: Double = 0.0
var highestOrbit: Int = 1
var longestVelocity: Int = 0
var perfectDays: Int = 0

// Customization
var accentColorIndex: Int = 0
var unlockedAccentColors: [Int] = [0]
var equippedCardBorder: String? = nil
var equippedParticleEffect: String? = nil
var equippedTitle: String? = nil

// Achievements
var unlockedAchievements: [String] = []
var achievementProgress: [String: Int] = [:]
```

---

## Section 8: Implementation Phases

### Phase 1: Foundation
- Create new theme system (DarkMatterTheme)
- Create typography, animation, spacing, color tokens
- Delete old ThemeManager and theme configs
- Update all views to use new system

### Phase 2: Visual Foundation
- Create Metal shaders (DarkMatter, Warp, Implosion, Glass)
- Create DarkMatterBackground with touch/scroll interaction
- Implement device tier detection and performance fallbacks
- Create ParticleSystem

### Phase 3: Core Components
- Create CinematicContainer (glass cards)
- Create EventHorizonDock with all states
- Create WarpTransition
- Replace MainTabView with dock navigation

### Phase 4: Gamification Backend
- Update UserSettings with gamification properties
- Create all gamification models
- Create all gamification services
- Create config JSON files
- Implement Mass, Orbit, Velocity, Combo logic

### Phase 5: Timeline Overhaul
- Create PrayerAnchorCard and TaskMassCard
- Create OrbitalStatusHeader and MassCounter
- Create ImplosionEffect and MaterializationEffect
- Major modify TimelineView
- Connect to ProgressionService

### Phase 6: Inbox & Task Management
- Update InboxView styling
- Implement materialization/disintegration
- Connect to gamification

### Phase 7: Gamification UI
- Create achievement views and components
- Create mission views and components
- Create orbit/velocity visualizations
- Implement celebration animations

### Phase 8: Onboarding & Settings
- Replace OnboardingView with Mission Briefing
- Update SettingsView
- Create AccentColorView and StatisticsView
- Update PaywallSheet

### Phase 9: AI Chat & Polish
- Update AI chat styling
- Performance optimization
- Reduce motion support
- Haptic tuning

### Phase 10: Cleanup & Testing
- Delete unused files
- Update tests
- QA pass
- Performance profiling

---

## Verification Checklist

### "The Nolan Test"
- [ ] Is it cohesive? (Single visual language throughout)
- [ ] Is it dark and moody? (Deep blacks, selective highlights)
- [ ] Does the background respond to touch? (Gravitational wells)
- [ ] Do transitions feel cinematic? (Warp, implosion effects)

### Performance
- [ ] 60fps on high-tier devices
- [ ] 30fps minimum on low-tier devices
- [ ] Battery usage acceptable
- [ ] No memory leaks
- [ ] Shader compiles without errors

### Functionality
- [ ] All Pro gates preserved (Nawafil, Adhan, etc.)
- [ ] Gamification calculates correctly
- [ ] Achievements unlock at right triggers
- [ ] Streaks track correctly
- [ ] Seasonal events activate properly

---

## Appendix: Prayer Integration Summary

Prayers serve three roles in the cosmic theme:

1. **Celestial Events** - Each prayer has a cosmic name and triggers background color shifts
2. **Navigation Anchors** - Fixed luminous points on timeline that tasks orbit around
3. **Power Sources** - Primary Mass generators with 3× in-window bonus

This makes prayers the spiritual AND mechanical heart of the Mizan experience.
