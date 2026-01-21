# Event Horizon Phase 1: Foundation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the existing 5-theme system with a single Dark Matter theme, creating the foundation for the cinematic UI overhaul.

**Architecture:** Create new Cinematic design tokens (Colors, Typography, Spacing, Animation), build DarkMatterTheme as a drop-in replacement for ThemeManager, then migrate all views to use the new system. The migration uses a compatibility layer to minimize breaking changes.

**Tech Stack:** SwiftUI, Swift 5.9+, iOS 17+

---

## Pre-Implementation Checklist

- [x] Worktree created at `.worktrees/event-horizon`
- [x] Branch: `feature/event-horizon`
- [x] Build passing
- [x] Tests passing (29/30)

---

## Task 1: Create CinematicColors

**Files:**
- Create: `MizanApp/Core/DesignSystem/Tokens/CinematicColors.swift`
- Test: Build verification (no unit tests for color constants)

### Step 1: Create the color tokens file

Create `MizanApp/Core/DesignSystem/Tokens/CinematicColors.swift`:

```swift
//
//  CinematicColors.swift
//  Mizan
//
//  Dark Matter theme color palette for Event Horizon UI
//

import SwiftUI

/// Cinematic color palette for Dark Matter theme
struct CinematicColors {
    // MARK: - Core Backgrounds

    /// Primary void background - #050508
    static let voidBlack = Color(red: 0.02, green: 0.02, blue: 0.03)

    /// Dark matter base for fluid simulation - #0a0a1a
    static let darkMatter = Color(red: 0.04, green: 0.04, blue: 0.10)

    /// Elevated surface color - #0f0f1f
    static let surface = Color(red: 0.06, green: 0.06, blue: 0.12)

    /// Secondary surface - #14142a
    static let surfaceSecondary = Color(red: 0.08, green: 0.08, blue: 0.16)

    // MARK: - Accent Colors

    /// Primary accent cyan - #7fdbff
    static let accentCyan = Color(red: 0.50, green: 0.86, blue: 1.0)

    /// Prayer/spiritual gold - #ffd700
    static let prayerGold = Color(red: 1.0, green: 0.84, blue: 0.0)

    /// Secondary accent magenta - #ff6bff
    static let accentMagenta = Color(red: 1.0, green: 0.42, blue: 1.0)

    // MARK: - Text Colors

    /// Primary text - #e8e8e8
    static let textPrimary = Color(red: 0.91, green: 0.91, blue: 0.91)

    /// Secondary text - #6b7280
    static let textSecondary = Color(red: 0.42, green: 0.45, blue: 0.50)

    /// Tertiary/disabled text - #4b5563
    static let textTertiary = Color(red: 0.29, green: 0.33, blue: 0.39)

    /// Text on accent backgrounds - #050508
    static let textOnAccent = Color(red: 0.02, green: 0.02, blue: 0.03)

    // MARK: - Semantic Colors

    /// Success state - #22c55e
    static let success = Color(red: 0.13, green: 0.77, blue: 0.37)

    /// Warning state - #f59e0b
    static let warning = Color(red: 0.96, green: 0.62, blue: 0.04)

    /// Error state - #ef4444
    static let error = Color(red: 0.94, green: 0.27, blue: 0.27)

    /// Info state - #3b82f6
    static let info = Color(red: 0.23, green: 0.51, blue: 0.96)

    // MARK: - Glass Material

    /// Glass surface base (use with opacity)
    static let glass = Color.white

    /// Glass border glow
    static let glassBorder = accentCyan

    // MARK: - Category Colors

    /// Work category - #3b82f6
    static let categoryWork = Color(red: 0.23, green: 0.51, blue: 0.96)

    /// Personal category - #8b5cf6
    static let categoryPersonal = Color(red: 0.55, green: 0.36, blue: 0.96)

    /// Health category - #22c55e
    static let categoryHealth = Color(red: 0.13, green: 0.77, blue: 0.37)

    /// Learning category - #f59e0b
    static let categoryLearning = Color(red: 0.96, green: 0.62, blue: 0.04)

    /// Worship category - #ffd700
    static let categoryWorship = Color(red: 1.0, green: 0.84, blue: 0.0)

    /// Other category - #7fdbff
    static let categoryOther = Color(red: 0.50, green: 0.86, blue: 1.0)

    // MARK: - Prayer Period Colors

    /// Fajr - deep blue with gold hints
    static let periodFajr = Color(red: 0.10, green: 0.15, blue: 0.35)

    /// Sunrise - warm gold
    static let periodSunrise = Color(red: 0.35, green: 0.25, blue: 0.15)

    /// Dhuhr - amber
    static let periodDhuhr = Color(red: 0.30, green: 0.22, blue: 0.12)

    /// Asr - copper bronze
    static let periodAsr = Color(red: 0.28, green: 0.18, blue: 0.10)

    /// Maghrib - deep red purple
    static let periodMaghrib = Color(red: 0.25, green: 0.10, blue: 0.20)

    /// Isha - deep void blue
    static let periodIsha = Color(red: 0.05, green: 0.05, blue: 0.15)
}
```

### Step 2: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

### Step 3: Commit

```bash
git add MizanApp/Core/DesignSystem/Tokens/CinematicColors.swift
git commit -m "feat(design): add CinematicColors for Dark Matter theme

Introduce color palette for Event Horizon cinematic UI:
- Core backgrounds (void, dark matter, surfaces)
- Accent colors (cyan, gold, magenta)
- Text hierarchy (primary, secondary, tertiary)
- Semantic colors (success, warning, error)
- Category and prayer period colors

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Create CinematicTypography

**Files:**
- Create: `MizanApp/Core/DesignSystem/Tokens/CinematicTypography.swift`
- Test: Build verification

### Step 1: Create the typography tokens file

Create `MizanApp/Core/DesignSystem/Tokens/CinematicTypography.swift`:

```swift
//
//  CinematicTypography.swift
//  Mizan
//
//  Cinematic typography system with dramatic contrasts
//

import SwiftUI

/// Typography tokens for cinematic Dark Matter theme
/// Uses geometric contrast: SF Pro Display for headers, SF Mono for data
struct CinematicTypography {
    // MARK: - Display (Massive Impact)

    /// 56pt bold, wide tracking - splash screens, celebrations
    static let displayLarge = Font.system(size: 56, weight: .bold, design: .default)

    /// 44pt bold, wide tracking - major headers
    static let displayMedium = Font.system(size: 44, weight: .bold, design: .default)

    // MARK: - Headlines (Section Headers, ALL CAPS)

    /// 28pt semibold - primary section headers
    static let headlineLarge = Font.system(size: 28, weight: .semibold, design: .default)

    /// 22pt semibold - secondary headers
    static let headlineMedium = Font.system(size: 22, weight: .semibold, design: .default)

    /// 18pt semibold - tertiary headers
    static let headlineSmall = Font.system(size: 18, weight: .semibold, design: .default)

    // MARK: - Title (Cards, Navigation)

    /// 22pt semibold - card titles
    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)

    /// 18pt semibold - navigation titles
    static let titleMedium = Font.system(size: 18, weight: .semibold, design: .default)

    /// 16pt semibold - small titles
    static let titleSmall = Font.system(size: 16, weight: .semibold, design: .default)

    // MARK: - Data (Numbers, Stats, Mass Display)

    /// 32pt medium monospace - large data displays
    static let dataLarge = Font.system(size: 32, weight: .medium, design: .monospaced)

    /// 20pt medium monospace - medium data
    static let dataMedium = Font.system(size: 20, weight: .medium, design: .monospaced)

    /// 14pt medium monospace - small data
    static let dataSmall = Font.system(size: 14, weight: .medium, design: .monospaced)

    // MARK: - Body (Content)

    /// 17pt regular - primary body text
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)

    /// 15pt regular - secondary body
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)

    /// 13pt regular - small body
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Labels (Metadata, ALL CAPS)

    /// 12pt semibold - primary labels
    static let labelLarge = Font.system(size: 12, weight: .semibold, design: .default)

    /// 10pt semibold - secondary labels
    static let labelMedium = Font.system(size: 10, weight: .semibold, design: .default)

    /// 9pt medium - tertiary labels
    static let labelSmall = Font.system(size: 9, weight: .medium, design: .default)

    // MARK: - Arabic Variants

    /// Arabic display text
    static let arabicDisplay = Font.system(size: 48, weight: .bold)

    /// Arabic headline text
    static let arabicHeadline = Font.system(size: 28, weight: .semibold)

    /// Arabic body text
    static let arabicBody = Font.system(size: 17, weight: .regular)

    // MARK: - Tracking Values (for Text modifier)

    /// Wide tracking for display text
    static let trackingDisplay: CGFloat = 6

    /// Medium tracking for headlines
    static let trackingHeadline: CGFloat = 3

    /// Standard tracking for labels
    static let trackingLabel: CGFloat = 1.5
}

// MARK: - Text Style Modifiers

extension View {
    /// Apply cinematic headline style (ALL CAPS, wide tracking)
    func cinematicHeadline() -> some View {
        self
            .textCase(.uppercase)
            .tracking(CinematicTypography.trackingHeadline)
    }

    /// Apply cinematic label style (ALL CAPS, tracking)
    func cinematicLabel() -> some View {
        self
            .textCase(.uppercase)
            .tracking(CinematicTypography.trackingLabel)
    }

    /// Apply cinematic display style (ALL CAPS, wide tracking)
    func cinematicDisplay() -> some View {
        self
            .textCase(.uppercase)
            .tracking(CinematicTypography.trackingDisplay)
    }
}
```

### Step 2: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

### Step 3: Commit

```bash
git add MizanApp/Core/DesignSystem/Tokens/CinematicTypography.swift
git commit -m "feat(design): add CinematicTypography with geometric contrast

Typography system for cinematic UI:
- Display fonts (56pt, 44pt) for splash/celebrations
- Headlines with ALL CAPS and wide tracking
- SF Mono for data/numbers (Mass, Orbit displays)
- Body and label hierarchies
- View modifiers for cinematic text styles

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Create CinematicSpacing

**Files:**
- Create: `MizanApp/Core/DesignSystem/Tokens/CinematicSpacing.swift`
- Test: Build verification

### Step 1: Create the spacing tokens file

Create `MizanApp/Core/DesignSystem/Tokens/CinematicSpacing.swift`:

```swift
//
//  CinematicSpacing.swift
//  Mizan
//
//  Spacing system for cinematic Dark Matter theme
//

import SwiftUI

/// Spacing tokens following an 8pt grid system
/// Designed for dramatic layouts with breathing room
struct CinematicSpacing {
    // MARK: - Base Scale (8pt grid)

    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64

    // MARK: - Semantic Spacing

    /// Card internal padding
    static let cardPadding: CGFloat = 16

    /// Space between sections
    static let sectionSpacing: CGFloat = 32

    /// Screen edge padding
    static let screenPadding: CGFloat = 16

    /// Space between list items
    static let itemSpacing: CGFloat = 12

    // MARK: - Component Specific

    /// Horizontal chip padding
    static let chipPaddingH: CGFloat = 16

    /// Vertical chip padding
    static let chipPaddingV: CGFloat = 10

    /// Button vertical padding
    static let buttonPaddingV: CGFloat = 16

    /// Glass card padding
    static let glassPadding: CGFloat = 20

    /// Dock item spacing
    static let dockItemSpacing: CGFloat = 24

    // MARK: - Timeline Specific

    /// Prayer card height
    static let prayerCardHeight: CGFloat = 100

    /// Task card height (minimum)
    static let taskCardMinHeight: CGFloat = 72

    /// Timeline hour height at normal zoom
    static let timelineHourHeight: CGFloat = 120

    // MARK: - Corner Radius

    /// Small radius (chips, buttons)
    static let radiusSmall: CGFloat = 8

    /// Medium radius (cards)
    static let radiusMedium: CGFloat = 16

    /// Large radius (sheets, modals)
    static let radiusLarge: CGFloat = 24

    /// Extra large radius (full-screen elements)
    static let radiusExtraLarge: CGFloat = 32
}
```

### Step 2: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

### Step 3: Commit

```bash
git add MizanApp/Core/DesignSystem/Tokens/CinematicSpacing.swift
git commit -m "feat(design): add CinematicSpacing with 8pt grid system

Spacing tokens for cinematic layouts:
- Base scale (xxxs to xxxl)
- Semantic spacing (cards, sections, screens)
- Component-specific values (chips, buttons, glass)
- Timeline-specific spacing
- Corner radius scale

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Create CinematicAnimation

**Files:**
- Create: `MizanApp/Core/DesignSystem/Tokens/CinematicAnimation.swift`
- Test: Build verification

### Step 1: Create the animation tokens file

Create `MizanApp/Core/DesignSystem/Tokens/CinematicAnimation.swift`:

```swift
//
//  CinematicAnimation.swift
//  Mizan
//
//  Animation system for cinematic Dark Matter theme
//

import SwiftUI

/// Animation presets for cinematic interactions
struct CinematicAnimation {
    // MARK: - Springs (Physics-Based)

    /// Gentle spring for subtle interactions
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.8)

    /// Snappy spring for quick responses
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.9)

    /// Elastic spring with bounce
    static let elastic = Animation.spring(response: 0.4, dampingFraction: 0.6)

    /// Dramatic spring for celebrations
    static let dramatic = Animation.spring(response: 0.6, dampingFraction: 0.5)

    /// Soft spring for smooth transitions
    static let soft = Animation.spring(response: 0.6, dampingFraction: 0.85)

    /// Stiff spring for immediate feedback
    static let stiff = Animation.spring(response: 0.2, dampingFraction: 0.95)

    // MARK: - Easing (Traditional Curves)

    /// Smooth ease in-out
    static let smooth = Animation.easeInOut(duration: 0.3)

    /// Enter animation
    static let enter = Animation.easeOut(duration: 0.25)

    /// Exit animation
    static let exit = Animation.easeIn(duration: 0.2)

    /// Slow transition
    static let slow = Animation.easeInOut(duration: 0.6)

    // MARK: - Continuous (Looping)

    /// Slow pulse effect
    static let pulse = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)

    /// Slow drift for particles
    static let drift = Animation.linear(duration: 30.0).repeatForever(autoreverses: false)

    /// Breathing glow effect
    static let breathe = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)

    /// Fast pulse for active states
    static let pulseFast = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)

    // MARK: - Signature Animations

    /// Warp transition between tabs
    static let warp = Animation.easeInOut(duration: 0.3)

    /// Task implosion animation
    static let implosion = Animation.easeIn(duration: 0.8)

    /// Task materialization (reverse implosion)
    static let materialization = Animation.spring(response: 0.5, dampingFraction: 0.7)

    /// Orbit level up celebration
    static let orbitLevelUp = Animation.spring(response: 0.6, dampingFraction: 0.4)

    /// Dock expansion
    static let dockExpand = Animation.spring(response: 0.4, dampingFraction: 0.7)

    /// Dock collapse
    static let dockCollapse = Animation.easeOut(duration: 0.3)

    // MARK: - Durations

    /// Instant (no animation)
    static let durationInstant: Double = 0.0

    /// Very fast
    static let durationVeryFast: Double = 0.15

    /// Fast
    static let durationFast: Double = 0.2

    /// Medium
    static let durationMedium: Double = 0.4

    /// Slow
    static let durationSlow: Double = 0.6

    /// Dramatic
    static let durationDramatic: Double = 1.2

    // MARK: - Stagger Helper

    /// Create staggered animation delay for list items
    static func stagger(index: Int, interval: Double = 0.05) -> Animation {
        Animation.spring(response: 0.4, dampingFraction: 0.8)
            .delay(Double(index) * interval)
    }
}

// MARK: - View Extension for Cinematic Transitions

extension View {
    /// Apply cinematic appear animation
    func cinematicAppear(delay: Double = 0) -> some View {
        self
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                removal: .opacity
            ))
            .animation(CinematicAnimation.enter.delay(delay), value: UUID())
    }
}
```

### Step 2: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

### Step 3: Commit

```bash
git add MizanApp/Core/DesignSystem/Tokens/CinematicAnimation.swift
git commit -m "feat(design): add CinematicAnimation for cinematic interactions

Animation system for Event Horizon:
- Spring animations (gentle, snappy, elastic, dramatic)
- Easing curves (smooth, enter, exit)
- Continuous loops (pulse, drift, breathe)
- Signature animations (warp, implosion, materialization)
- Duration constants and stagger helper

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Create DarkMatterTheme

**Files:**
- Create: `MizanApp/Core/DesignSystem/Theme/DarkMatterTheme.swift`
- Test: Build verification

### Step 1: Create the theme manager replacement

Create directory first:
```bash
mkdir -p MizanApp/Core/DesignSystem/Theme
```

Create `MizanApp/Core/DesignSystem/Theme/DarkMatterTheme.swift`:

```swift
//
//  DarkMatterTheme.swift
//  Mizan
//
//  Single Dark Matter theme - replaces multi-theme ThemeManager
//  Provides backward-compatible API for gradual migration
//

import SwiftUI
import Combine

/// Dark Matter theme manager - single cinematic theme for Event Horizon
/// Maintains backward compatibility with ThemeManager API during migration
@MainActor
final class DarkMatterTheme: ObservableObject {
    // MARK: - Singleton

    static let shared = DarkMatterTheme()

    // MARK: - Published Properties (Backward Compatibility)

    /// Always dark mode
    @Published var isDarkMode: Bool = true

    /// Ramadan detection (for seasonal events)
    @Published var isRamadan: Bool = false

    // MARK: - Core Colors

    var primaryColor: Color { CinematicColors.accentCyan }
    var backgroundColor: Color { CinematicColors.voidBlack }
    var surfaceColor: Color { CinematicColors.surface }
    var surfaceSecondaryColor: Color { CinematicColors.surfaceSecondary }

    // MARK: - Text Colors

    var textPrimaryColor: Color { CinematicColors.textPrimary }
    var textSecondaryColor: Color { CinematicColors.textSecondary }
    var textTertiaryColor: Color { CinematicColors.textTertiary }
    var textOnPrimaryColor: Color { CinematicColors.textOnAccent }

    // MARK: - Semantic Colors

    var successColor: Color { CinematicColors.success }
    var errorColor: Color { CinematicColors.error }
    var warningColor: Color { CinematicColors.warning }
    var infoColor: Color { CinematicColors.info }

    // MARK: - Additional Colors (Backward Compatibility)

    var dividerColor: Color { CinematicColors.textTertiary.opacity(0.3) }
    var disabledColor: Color { CinematicColors.textTertiary }
    var borderColor: Color { CinematicColors.glassBorder.opacity(0.4) }
    var focusedBorderColor: Color { CinematicColors.glassBorder }

    // MARK: - Glass Material

    var glassBackground: Color { CinematicColors.glass.opacity(0.06) }
    var glassBorder: Color { CinematicColors.glassBorder.opacity(0.4) }

    // MARK: - Initialization

    private init() {
        // Check for Ramadan (Hijri month 9)
        checkRamadan()
    }

    // MARK: - Category Colors

    func categoryColor(_ category: TaskCategory) -> Color {
        switch category {
        case .work:
            return CinematicColors.categoryWork
        case .personal:
            return CinematicColors.categoryPersonal
        case .health:
            return CinematicColors.categoryHealth
        case .learning:
            return CinematicColors.categoryLearning
        case .worship:
            return CinematicColors.categoryWorship
        case .pilesOfGood:
            return CinematicColors.prayerGold
        case .other:
            return CinematicColors.categoryOther
        }
    }

    // MARK: - Prayer Period Colors

    func prayerPeriodColor(_ period: PrayerPeriod) -> Color {
        switch period {
        case .fajr:
            return CinematicColors.periodFajr
        case .sunrise:
            return CinematicColors.periodSunrise
        case .dhuhr:
            return CinematicColors.periodDhuhr
        case .asr:
            return CinematicColors.periodAsr
        case .maghrib:
            return CinematicColors.periodMaghrib
        case .isha, .night:
            return CinematicColors.periodIsha
        default:
            return CinematicColors.darkMatter
        }
    }

    // MARK: - Corner Radius (Backward Compatibility)

    enum CornerRadiusSize {
        case small, medium, large, extraLarge
    }

    func cornerRadius(_ size: CornerRadiusSize) -> CGFloat {
        switch size {
        case .small:
            return CinematicSpacing.radiusSmall
        case .medium:
            return CinematicSpacing.radiusMedium
        case .large:
            return CinematicSpacing.radiusLarge
        case .extraLarge:
            return CinematicSpacing.radiusExtraLarge
        }
    }

    // MARK: - Shadow (Backward Compatibility)

    enum ShadowStyle {
        case card, elevated, floating
    }

    func shadow(_ style: ShadowStyle) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        switch style {
        case .card:
            return (CinematicColors.accentCyan.opacity(0.1), 8, 0, 4)
        case .elevated:
            return (CinematicColors.accentCyan.opacity(0.15), 16, 0, 8)
        case .floating:
            return (CinematicColors.accentCyan.opacity(0.2), 24, 0, 12)
        }
    }

    // MARK: - Atmosphere Gradient (Backward Compatibility)

    func atmosphereGradient(for period: PrayerPeriod) -> LinearGradient {
        let baseColor = prayerPeriodColor(period)
        return LinearGradient(
            colors: [
                baseColor,
                CinematicColors.voidBlack
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Prayer Gradient

    var prayerGradient: LinearGradient {
        LinearGradient(
            colors: [
                CinematicColors.prayerGold.opacity(0.3),
                CinematicColors.voidBlack
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Glass Styles (Backward Compatibility)

    enum GlassStyle {
        case subtle, standard, frosted, prayer
    }

    func glassStyle(_ style: GlassStyle) -> (blur: CGFloat, opacity: Double, glow: Bool) {
        switch style {
        case .subtle:
            return (10, 0.04, false)
        case .standard:
            return (20, 0.06, true)
        case .frosted:
            return (30, 0.08, true)
        case .prayer:
            return (20, 0.08, true)
        }
    }

    // MARK: - Particle Color

    func particleColor(for period: PrayerPeriod) -> Color {
        switch period {
        case .fajr, .sunrise:
            return CinematicColors.prayerGold.opacity(0.6)
        case .maghrib:
            return CinematicColors.accentMagenta.opacity(0.5)
        default:
            return CinematicColors.accentCyan.opacity(0.4)
        }
    }

    // MARK: - Ramadan Detection

    private func checkRamadan() {
        let islamic = Calendar(identifier: .islamicUmmAlQura)
        let month = islamic.component(.month, from: Date())
        isRamadan = (month == 9)
    }
}

// MARK: - ThemeManager Compatibility Alias

/// Alias for backward compatibility during migration
/// Views using `@EnvironmentObject var themeManager: ThemeManager` will work
typealias ThemeManager = DarkMatterTheme
```

### Step 2: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -10
```

Expected: Build errors due to missing types (TaskCategory, PrayerPeriod) - this is expected, we'll fix in next task.

### Step 3: Add required type imports

We need to check if TaskCategory and PrayerPeriod exist and adjust imports. First, let's find them:

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && grep -r "enum TaskCategory" --include="*.swift" -l
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && grep -r "enum PrayerPeriod" --include="*.swift" -l
```

Then update the file to import or reference correctly based on findings.

### Step 4: Commit (after build passes)

```bash
git add MizanApp/Core/DesignSystem/Theme/
git commit -m "feat(theme): add DarkMatterTheme as ThemeManager replacement

Single Dark Matter theme for Event Horizon:
- Singleton pattern with shared instance
- Full backward compatibility with ThemeManager API
- All color properties mapped to CinematicColors
- Category and prayer period color methods
- Glass material styles
- Shadow and corner radius helpers
- TypeAlias for seamless migration

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Update App Entry Point

**Files:**
- Modify: `MizanApp/App/MizanApp.swift`
- Modify: `MizanApp/App/AppEnvironment.swift` (if exists)
- Test: Build and run verification

### Step 1: Find and read current app entry

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && cat MizanApp/App/MizanApp.swift | head -60
```

### Step 2: Update to use DarkMatterTheme

Replace ThemeManager initialization with DarkMatterTheme.shared. The exact changes depend on current implementation.

### Step 3: Verify build and run

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -5
```

### Step 4: Commit

```bash
git add MizanApp/App/
git commit -m "feat(app): integrate DarkMatterTheme into app entry

Update app initialization to use single Dark Matter theme:
- Replace ThemeManager with DarkMatterTheme.shared
- Maintain EnvironmentObject injection for compatibility

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 7: Delete ThemeSelectionView

**Files:**
- Delete: `MizanApp/Features/Settings/Views/ThemeSelectionView.swift`
- Modify: `MizanApp/Features/Settings/Views/SettingsView.swift` (remove navigation link)
- Test: Build verification

### Step 1: Find ThemeSelectionView

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && find . -name "ThemeSelectionView.swift" -o -name "*ThemeSelection*"
```

### Step 2: Find references in SettingsView

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && grep -n "ThemeSelection" MizanApp/Features/Settings/Views/SettingsView.swift
```

### Step 3: Remove navigation link from SettingsView

Edit SettingsView.swift to remove the theme selection row/link.

### Step 4: Delete ThemeSelectionView.swift

```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && rm MizanApp/Features/Settings/Views/ThemeSelectionView.swift
```

### Step 5: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -10
```

### Step 6: Commit

```bash
git add -A
git commit -m "feat(settings): remove theme selection (single Dark Matter theme)

Event Horizon uses a single cinematic theme:
- Delete ThemeSelectionView.swift
- Remove theme selection navigation from Settings
- Dark Matter is now the only theme

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 8: Delete Old ThemeManager

**Files:**
- Delete: `MizanApp/Core/Services/ThemeManager.swift`
- Test: Build verification (should work due to typealias)

### Step 1: Verify DarkMatterTheme has typealias

Ensure `typealias ThemeManager = DarkMatterTheme` exists in DarkMatterTheme.swift

### Step 2: Delete old ThemeManager

```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && rm MizanApp/Core/Services/ThemeManager.swift
```

### Step 3: Verify build

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

If errors occur, they will indicate which files need the import path updated.

### Step 4: Fix any import errors

For each file with errors, add import or fix reference path.

### Step 5: Commit

```bash
git add -A
git commit -m "refactor(theme): delete old multi-theme ThemeManager

Complete migration to single Dark Matter theme:
- Remove old ThemeManager.swift
- DarkMatterTheme now serves as ThemeManager via typealias
- All existing code continues to work unchanged

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 9: Update ThemeConfig.json

**Files:**
- Modify: `MizanApp/Resources/Configuration/ThemeConfig.json`
- Test: Build and runtime verification

### Step 1: Find and read current config

Run:
```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && find . -name "ThemeConfig.json"
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && cat MizanApp/Resources/Configuration/ThemeConfig.json | head -50
```

### Step 2: Simplify to Dark Matter only

Replace the entire contents with a single Dark Matter theme configuration. The exact structure depends on current format.

### Step 3: Verify build and run

```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=ED5300B8-961F-4BD2-814D-BADE0A1D5F2A' build 2>&1 | tail -5
```

### Step 4: Commit

```bash
git add MizanApp/Resources/Configuration/ThemeConfig.json
git commit -m "config(theme): simplify ThemeConfig to Dark Matter only

Single theme configuration for Event Horizon:
- Remove Noor, Layl, Fajr, Sahara, Ramadan themes
- Dark Matter is the only theme
- Simplified configuration structure

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 10: Run Full Test Suite

**Files:**
- Test: All tests

### Step 1: Run unit tests

```bash
cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,id=CB32C2FD-421F-4D1E-ACE3-650C7D948ACB' test 2>&1 | grep -E "(Test Case|passed|failed|TEST SUCCEEDED|TEST FAILED)" | tail -40
```

### Step 2: Document any failures

If tests fail, create issues or fix immediately if simple.

### Step 3: Final commit for Phase 1

```bash
git add -A
git commit -m "test: verify Phase 1 foundation complete

All tests passing after Event Horizon Phase 1:
- CinematicColors, Typography, Spacing, Animation tokens
- DarkMatterTheme replacing ThemeManager
- Single theme configuration
- ThemeSelectionView removed

Phase 1 Foundation complete. Ready for Phase 2 (Visual Foundation).

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Phase 1 Completion Checklist

- [ ] Task 1: CinematicColors created and committed
- [ ] Task 2: CinematicTypography created and committed
- [ ] Task 3: CinematicSpacing created and committed
- [ ] Task 4: CinematicAnimation created and committed
- [ ] Task 5: DarkMatterTheme created and committed
- [ ] Task 6: App entry point updated
- [ ] Task 7: ThemeSelectionView deleted
- [ ] Task 8: Old ThemeManager deleted
- [ ] Task 9: ThemeConfig.json simplified
- [ ] Task 10: Full test suite passing

---

## Next Phase

After Phase 1 completion, proceed to **Phase 2: Visual Foundation** which includes:
- DarkMatterShader.metal
- DarkMatterBackground.swift
- ParticleSystem.swift
- Device tier detection
