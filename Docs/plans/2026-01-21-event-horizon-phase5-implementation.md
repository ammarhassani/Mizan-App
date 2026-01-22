# Phase 5: Timeline Overhaul Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform the Timeline view with cosmic-themed prayer and task cards, orbital status header, and connect everything to the gamification backend.

**Architecture:** Glass-style cards with cosmic naming for prayers, floating task cards with Mass rewards, animated counters, and implosion/materialization effects on completion.

**Tech Stack:** SwiftUI, Core Animation, existing theme system, ProgressionService integration.

---

## Task 1: Create OrbitalStatusHeader

**Files:**
- Create: `MizanApp/Features/Timeline/Views/Components/OrbitalStatusHeader.swift`

**Step 1: Create the orbital status header component**

```swift
//
//  OrbitalStatusHeader.swift
//  MizanApp
//
//  Displays current Orbit level, Mass, Light Velocity streak, and Combo multiplier.
//

import SwiftUI

struct OrbitalStatusHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var progressionService: ProgressionService

    var body: some View {
        VStack(spacing: MZSpacing.sm) {
            // Orbit Level
            Text("ORBIT \(progressionService.currentOrbit)")
                .font(MZTypography.labelLarge)
                .foregroundColor(themeManager.textSecondaryColor)
                .tracking(2)

            // Progress bar to next orbit
            if let nextOrbit = progressionService.getNextOrbitConfig() {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        Capsule()
                            .fill(themeManager.surfaceColor)
                            .frame(height: 4)

                        // Progress fill
                        Capsule()
                            .fill(themeManager.primaryColor)
                            .frame(width: geometry.size.width * progressionService.getOrbitProgress(), height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, MZSpacing.xl)
            }

            // Orbit Title
            if let currentOrbit = progressionService.getCurrentOrbitConfig() {
                Text(currentOrbit.title.uppercased())
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
            }

            // Stats Row
            HStack(spacing: MZSpacing.xl) {
                // Mass
                StatItem(
                    icon: "diamond.fill",
                    value: formatMass(progressionService.currentMass),
                    label: "MASS",
                    color: themeManager.primaryColor
                )

                // Combo Multiplier
                StatItem(
                    icon: "bolt.fill",
                    value: String(format: "%.1fx", progressionService.comboMultiplier),
                    label: "COMBO",
                    color: themeManager.warningColor
                )

                // Light Velocity (Streak)
                StatItem(
                    icon: "flame.fill",
                    value: "\(progressionService.currentStreak)",
                    label: "DAYS",
                    color: themeManager.errorColor
                )
            }
            .padding(.top, MZSpacing.sm)
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                .fill(themeManager.surfaceColor.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                        .stroke(themeManager.primaryColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func formatMass(_ mass: Double) -> String {
        if mass >= 1000 {
            return String(format: "%.1fK", mass / 1000)
        }
        return String(format: "%.0f", mass)
    }
}

struct StatItem: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: MZSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(MZTypography.dataMedium)
                    .foregroundColor(themeManager.textPrimaryColor)

                Text(label)
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
        }
    }
}
```

**Step 2: Build to verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | tail -30`

**Step 3: Commit**

```bash
git add MizanApp/Features/Timeline/Views/Components/OrbitalStatusHeader.swift
git commit -m "feat(timeline): add OrbitalStatusHeader with Mass/Combo/Streak display"
```

---

## Task 2: Create MassCounter Animation Component

**Files:**
- Create: `MizanApp/Features/Timeline/Views/Components/MassCounter.swift`

**Step 1: Create animated mass counter**

```swift
//
//  MassCounter.swift
//  MizanApp
//
//  Animated counter for displaying Mass with recent gain animation.
//

import SwiftUI

struct MassCounter: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currentMass: Double
    let recentGain: Double

    @State private var displayedMass: Double = 0
    @State private var showGain: Bool = false

    var body: some View {
        HStack(spacing: MZSpacing.xs) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 16))
                .foregroundColor(themeManager.primaryColor)

            Text(formatMass(displayedMass))
                .font(MZTypography.dataLarge)
                .foregroundColor(themeManager.textPrimaryColor)
                .contentTransition(.numericText())

            if showGain && recentGain > 0 {
                Text("+\(Int(recentGain))")
                    .font(MZTypography.labelMedium)
                    .foregroundColor(themeManager.successColor)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .onChange(of: currentMass) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                displayedMass = newValue
            }
        }
        .onChange(of: recentGain) { _, newValue in
            if newValue > 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showGain = true
                }

                // Hide after delay
                _Concurrency.Task {
                    try? await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showGain = false
                        }
                    }
                }
            }
        }
        .onAppear {
            displayedMass = currentMass
        }
    }

    private func formatMass(_ mass: Double) -> String {
        if mass >= 10000 {
            return String(format: "%.1fK", mass / 1000)
        } else if mass >= 1000 {
            return String(format: "%.2fK", mass / 1000)
        }
        return String(format: "%.0f", mass)
    }
}
```

**Step 2: Build to verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | tail -30`

**Step 3: Commit**

```bash
git add MizanApp/Features/Timeline/Views/Components/MassCounter.swift
git commit -m "feat(timeline): add animated MassCounter component"
```

---

## Task 3: Create PrayerAnchorCard

**Files:**
- Create: `MizanApp/Features/Timeline/Views/Components/PrayerAnchorCard.swift`

**Step 1: Create prayer anchor card with cosmic naming**

```swift
//
//  PrayerAnchorCard.swift
//  MizanApp
//
//  Cosmic-styled prayer card - "Celestial Anchor" in the timeline.
//

import SwiftUI

struct PrayerAnchorCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    let prayer: PrayerTime
    let isCurrentPrayer: Bool
    let onComplete: () -> Void

    // Cosmic names for prayers
    private var cosmicName: String {
        switch prayer.prayerType {
        case .fajr: return "First Light"
        case .sunrise: return "Dawn Rise"
        case .dhuhr: return "Solar Zenith"
        case .asr: return "Golden Descent"
        case .maghrib: return "Solar Collapse"
        case .isha: return "Deep Void"
        }
    }

    private var massReward: Int {
        prayer.isInWindow ? 150 : 50
    }

    var body: some View {
        HStack(spacing: MZSpacing.md) {
            // Prayer indicator
            Circle()
                .fill(isCurrentPrayer ? themeManager.warningColor : themeManager.primaryColor.opacity(0.3))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(themeManager.primaryColor, lineWidth: isCurrentPrayer ? 2 : 0)
                        .scaleEffect(isCurrentPrayer ? 1.5 : 1)
                        .opacity(isCurrentPrayer ? 0.5 : 0)
                )

            VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                // Prayer name and time
                HStack {
                    Text(prayer.prayerType.localizedName(userSettings: nil))
                        .font(MZTypography.titleSmall)
                        .foregroundColor(themeManager.textPrimaryColor)

                    Spacer()

                    Text(prayer.adhanTime.formatted(date: .omitted, time: .shortened))
                        .font(MZTypography.dataMedium)
                        .foregroundColor(themeManager.textPrimaryColor)
                }

                // Cosmic name and Mass reward
                HStack {
                    Text(cosmicName)
                        .font(MZTypography.bodySmall)
                        .foregroundColor(themeManager.textSecondaryColor)

                    Spacer()

                    if prayer.isInWindow {
                        Text("+\(massReward) Mass in window")
                            .font(MZTypography.labelSmall)
                            .foregroundColor(themeManager.successColor)
                    } else {
                        Text("+\(massReward) Mass")
                            .font(MZTypography.labelSmall)
                            .foregroundColor(themeManager.textTertiaryColor)
                    }
                }
            }

            // Completion button
            Button(action: onComplete) {
                ZStack {
                    Circle()
                        .fill(prayer.isCompleted ? themeManager.successColor : themeManager.surfaceColor)
                        .frame(width: 32, height: 32)

                    if prayer.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(themeManager.textOnPrimaryColor)
                    }
                }
            }
            .disabled(prayer.isCompleted)
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .fill(themeManager.surfaceColor.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .stroke(
                            isCurrentPrayer ? themeManager.warningColor.opacity(0.5) : themeManager.primaryColor.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: isCurrentPrayer ? themeManager.warningColor.opacity(0.2) : .clear, radius: 8)
    }
}
```

**Step 2: Build to verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | tail -30`

**Step 3: Commit**

```bash
git add MizanApp/Features/Timeline/Views/Components/PrayerAnchorCard.swift
git commit -m "feat(timeline): add PrayerAnchorCard with cosmic naming"
```

---

## Task 4: Create TaskMassCard

**Files:**
- Create: `MizanApp/Features/Timeline/Views/Components/TaskMassCard.swift`

**Step 1: Create task card with Mass display**

```swift
//
//  TaskMassCard.swift
//  MizanApp
//
//  Task card displaying potential Mass reward - "Floating Mass" in the timeline.
//

import SwiftUI

struct TaskMassCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    let task: Task
    let onComplete: () -> Void
    let onTap: () -> Void

    // Calculate potential Mass based on duration
    private var potentialMass: Int {
        guard let duration = task.duration else { return 10 }
        // Scale from 10-50 based on duration (15-120 min range)
        let durationFactor = min(1.0, max(0.2, Double(duration) / 60.0))
        return Int(10.0 + (40.0 * durationFactor))
    }

    // Category color
    private var categoryColor: Color {
        if let userCategory = task.userCategory {
            return Color(hex: userCategory.colorHex) ?? themeManager.primaryColor
        }
        return themeManager.primaryColor
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MZSpacing.md) {
                // Category indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(categoryColor)
                    .frame(width: 4, height: 40)

                VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                    // Task title
                    Text(task.title)
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(task.isCompleted ? themeManager.textTertiaryColor : themeManager.textPrimaryColor)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)

                    // Duration and category
                    HStack(spacing: MZSpacing.sm) {
                        if let duration = task.duration {
                            Text("\(duration) min")
                                .font(MZTypography.labelSmall)
                                .foregroundColor(themeManager.textSecondaryColor)
                        }

                        if let userCategory = task.userCategory {
                            Text(userCategory.name)
                                .font(MZTypography.labelSmall)
                                .foregroundColor(categoryColor)
                        }

                        Spacer()

                        if !task.isCompleted {
                            Text("+\(potentialMass) Mass")
                                .font(MZTypography.labelSmall)
                                .foregroundColor(themeManager.successColor)
                        }
                    }
                }

                Spacer()

                // Completion checkbox
                Button(action: onComplete) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(task.isCompleted ? themeManager.successColor : themeManager.surfaceColor)
                            .frame(width: 28, height: 28)

                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(themeManager.textOnPrimaryColor)
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(themeManager.textSecondaryColor.opacity(0.5), lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                        }
                    }
                }
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                    .fill(themeManager.surfaceColor.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                            .stroke(themeManager.primaryColor.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

**Step 2: Build to verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | tail -30`

**Step 3: Commit**

```bash
git add MizanApp/Features/Timeline/Views/Components/TaskMassCard.swift
git commit -m "feat(timeline): add TaskMassCard with Mass reward display"
```

---

## Task 5: Create ImplosionEffect

**Files:**
- Create: `MizanApp/Core/UI/Animations/ImplosionEffect.swift`

**Step 1: Create implosion animation for task completion**

```swift
//
//  ImplosionEffect.swift
//  MizanApp
//
//  Gravitational implosion effect for task/prayer completion.
//

import SwiftUI

struct ImplosionEffect: ViewModifier {
    @Binding var isActive: Bool
    let onComplete: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var blur: CGFloat = 0
    @State private var showFlash: Bool = false

    func body(content: Content) -> some View {
        ZStack {
            content
                .scaleEffect(scale)
                .opacity(opacity)
                .blur(radius: blur)

            // Flash effect
            if showFlash {
                Circle()
                    .fill(Color.white)
                    .scaleEffect(showFlash ? 2 : 0)
                    .opacity(showFlash ? 0 : 1)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                performImplosion()
            }
        }
    }

    private func performImplosion() {
        // Phase 1: Initial squeeze (0-0.3s)
        withAnimation(.easeIn(duration: 0.15)) {
            scale = 0.95
        }

        // Phase 2: Rapid collapse (0.15-0.4s)
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: 150_000_000)
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.25)) {
                    scale = 0.0
                    blur = 5
                }
            }

            // Phase 3: Flash (0.4s)
            try? await _Concurrency.Task.sleep(nanoseconds: 250_000_000)
            await MainActor.run {
                showFlash = true
                withAnimation(.easeOut(duration: 0.15)) {
                    showFlash = false
                }
                opacity = 0
            }

            // Complete
            try? await _Concurrency.Task.sleep(nanoseconds: 150_000_000)
            await MainActor.run {
                onComplete()
            }
        }
    }
}

extension View {
    func implosionEffect(isActive: Binding<Bool>, onComplete: @escaping () -> Void) -> some View {
        modifier(ImplosionEffect(isActive: isActive, onComplete: onComplete))
    }
}

// Simplified version for immediate use
struct ImplosionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isVisible: Bool
    let position: CGPoint

    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        if isVisible {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(scale)
                .opacity(opacity)
                .position(position)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.4)) {
                        scale = 1.5
                        opacity = 0
                    }

                    _Concurrency.Task {
                        try? await _Concurrency.Task.sleep(nanoseconds: 400_000_000)
                        await MainActor.run {
                            isVisible = false
                        }
                    }
                }
        }
    }
}
```

**Step 2: Build to verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | tail -30`

**Step 3: Commit**

```bash
git add MizanApp/Core/UI/Animations/ImplosionEffect.swift
git commit -m "feat(animations): add ImplosionEffect for task completion"
```

---

## Task 6: Create MaterializationEffect

**Files:**
- Create: `MizanApp/Core/UI/Animations/MaterializationEffect.swift`

**Step 1: Create materialization animation for new items**

```swift
//
//  MaterializationEffect.swift
//  MizanApp
//
//  Materialization effect for new tasks/items appearing.
//

import SwiftUI

struct MaterializationEffect: ViewModifier {
    let delay: Double

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var blur: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .blur(radius: blur)
            .onAppear {
                _Concurrency.Task {
                    try? await _Concurrency.Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    await MainActor.run {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            scale = 1.0
                            opacity = 1.0
                            blur = 0
                        }
                    }
                }
            }
    }
}

extension View {
    func materialize(delay: Double = 0) -> some View {
        modifier(MaterializationEffect(delay: delay))
    }
}

// Particle burst for materialization
struct MaterializationBurst: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isVisible: Bool
    let position: CGPoint

    @State private var particles: [MaterializationParticle] = []

    var body: some View {
        if isVisible {
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(themeManager.primaryColor.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .offset(x: particle.offset.width, y: particle.offset.height)
                }
            }
            .position(position)
            .onAppear {
                createParticles()
                animateParticles()
            }
        }
    }

    private func createParticles() {
        particles = (0..<8).map { _ in
            MaterializationParticle(
                id: UUID(),
                offset: .zero,
                size: CGFloat.random(in: 4...8),
                opacity: 1.0,
                angle: CGFloat.random(in: 0...360)
            )
        }
    }

    private func animateParticles() {
        for i in particles.indices {
            let angle = particles[i].angle * .pi / 180
            let distance: CGFloat = CGFloat.random(in: 30...60)

            withAnimation(.easeOut(duration: 0.5)) {
                particles[i].offset = CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                )
                particles[i].opacity = 0
            }
        }

        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                isVisible = false
            }
        }
    }
}

struct MaterializationParticle: Identifiable {
    let id: UUID
    var offset: CGSize
    var size: CGFloat
    var opacity: Double
    var angle: CGFloat
}
```

**Step 2: Build to verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | tail -30`

**Step 3: Commit**

```bash
git add MizanApp/Core/UI/Animations/MaterializationEffect.swift
git commit -m "feat(animations): add MaterializationEffect for new items"
```

---

## Task 7: Add MZTypography.dataMedium and dataLarge if missing

**Files:**
- Modify: `MizanApp/Core/UI/MZTypography.swift`

**Step 1: Check and add data typography styles**

If not already present, add:
```swift
// DATA - Numeric displays
static let dataLarge = Font.system(size: 32, weight: .medium, design: .monospaced)
static let dataMedium = Font.system(size: 20, weight: .medium, design: .monospaced)
static let dataSmall = Font.system(size: 14, weight: .medium, design: .monospaced)
```

**Step 2: Build to verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | tail -30`

**Step 3: Commit if changes made**

```bash
git add MizanApp/Core/UI/MZTypography.swift
git commit -m "feat(typography): add data display typography styles"
```

---

## Task 8: Integrate Gamification into TimelineView

**Files:**
- Modify: `MizanApp/Features/Timeline/Views/TimelineView.swift`

**Step 1: Add progressionService access**

Add to TimelineView:
```swift
@ObservedObject var progressionService = AppEnvironment.shared.progressionService!
```

**Step 2: Add OrbitalStatusHeader to the view**

Find the main VStack/ScrollView and add OrbitalStatusHeader at the top.

**Step 3: Update task completion to award Mass**

In the task completion handler, add:
```swift
if let duration = task.duration {
    progressionService.awardMassForTask(duration: duration)
}
```

**Step 4: Update prayer completion to award Mass**

In the prayer completion handler, add:
```swift
progressionService.awardMassForPrayer(isOnTime: prayer.isInWindow, isFajr: prayer.prayerType == .fajr)
```

**Step 5: Build to verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | tail -30`

**Step 6: Commit**

```bash
git add MizanApp/Features/Timeline/Views/TimelineView.swift
git commit -m "feat(timeline): integrate gamification services with Mass rewards"
```

---

## Task 9: Integration Test

**Step 1: Run full build**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -project Mizan.xcodeproj -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | tail -50`

Expected: BUILD SUCCEEDED

**Step 2: Fix any errors that appear**

---

## Task 10: Phase 5 Completion

**Step 1: Create git tag**

```bash
git tag -a event-horizon-phase5-complete -m "Phase 5: Timeline Overhaul complete - OrbitalStatusHeader, PrayerAnchorCard, TaskMassCard, ImplosionEffect, MaterializationEffect"
```

**Step 2: Verify all commits**

```bash
git log --oneline -10
```

---

## Summary

Phase 5 delivers:
1. **OrbitalStatusHeader** - Shows Orbit level, Mass, Combo, Streak
2. **MassCounter** - Animated Mass display with recent gain popup
3. **PrayerAnchorCard** - Cosmic-themed prayer cards with Mass rewards
4. **TaskMassCard** - Task cards showing potential Mass
5. **ImplosionEffect** - Gravitational collapse on completion
6. **MaterializationEffect** - Particle burst for new items
7. **TimelineView Integration** - Connected to gamification backend
