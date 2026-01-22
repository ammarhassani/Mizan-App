# Phase 3: Core Components Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create the core cinematic UI components - glass cards, EventHorizonDock navigation, warp transitions - and replace the standard TabView navigation.

**Architecture:** CinematicContainer provides the glass shard material base, EventHorizonDock replaces TabView with orbital navigation, WarpTransition handles view switching with motion blur effect.

**Tech Stack:** SwiftUI, Core Animation, Core Haptics, Metal (WarpTransition uses WarpTransitionShader.metal)

---

## Context from Previous Phases

**Phase 1 (Foundation):** Created DarkMatterTheme, CinematicColors, CinematicTypography, CinematicSpacing, CinematicAnimation tokens.

**Phase 2 (Visual Foundation):** Created DeviceTier, DarkMatterShader.metal, MetalView, DarkMatterBackground, ParticleSystem, GlassShader.metal, ImplosionShader.metal, WarpTransitionShader.metal.

**Existing Files to Reference:**
- `MizanApp/Core/DesignSystem/Tokens/CinematicColors.swift` - Glass material colors
- `MizanApp/Core/DesignSystem/Tokens/CinematicAnimation.swift` - Animation presets (dockExpand, dockCollapse, warp)
- `MizanApp/Core/DesignSystem/Components/DarkMatterBackground.swift` - Background component
- `MizanApp/Core/DesignSystem/Shaders/WarpTransitionShader.metal` - Warp effect shader
- `MizanApp/App/MizanApp.swift` - Contains MainTabView to replace (lines 288-333)

---

## Task 1: CinematicContainer (Glass Card Component)

**Files:**
- Create: `MizanApp/Core/DesignSystem/Components/CinematicContainer.swift`

**Purpose:** Reusable glass shard card component with 6% white opacity, blur, grain texture, animated cyan border glow.

**Step 1: Create the file with imports and documentation**

```swift
//
//  CinematicContainer.swift
//  MizanApp
//
//  Glass shard container component for cinematic UI.
//  Features: frosted glass effect, animated border glow, grain texture.
//

import SwiftUI
```

**Step 2: Define GlassStyle enum for different glass variants**

```swift
/// Glass material style variants
enum GlassStyle {
    case standard      // 6% opacity, cyan border
    case elevated      // 8% opacity, stronger glow
    case subtle        // 4% opacity, no border animation
    case prayer        // Gold-tinted for prayer cards
}
```

**Step 3: Create CinematicContainer struct with properties**

```swift
/// Cinematic glass shard container
struct CinematicContainer<Content: View>: View {
    // Configuration
    let style: GlassStyle
    let cornerRadius: CGFloat
    let animateBorder: Bool

    // Content
    @ViewBuilder let content: () -> Content

    // State for border animation
    @State private var borderGlow: CGFloat = 0.4

    init(
        style: GlassStyle = .standard,
        cornerRadius: CGFloat = 16,
        animateBorder: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.animateBorder = animateBorder
        self.content = content
    }
}
```

**Step 4: Implement computed properties for style-dependent values**

```swift
extension CinematicContainer {
    private var glassOpacity: Double {
        switch style {
        case .standard: return 0.06
        case .elevated: return 0.08
        case .subtle: return 0.04
        case .prayer: return 0.06
        }
    }

    private var borderColor: Color {
        switch style {
        case .standard, .elevated, .subtle:
            return CinematicColors.glassBorder
        case .prayer:
            return CinematicColors.prayerGold
        }
    }

    private var shadowColor: Color {
        switch style {
        case .standard, .elevated, .subtle:
            return CinematicColors.accentCyan
        case .prayer:
            return CinematicColors.prayerGold
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .standard: return 8
        case .elevated: return 12
        case .subtle: return 4
        case .prayer: return 8
        }
    }
}
```

**Step 5: Implement the body with glass effect layers**

```swift
extension CinematicContainer {
    var body: some View {
        content()
            .background(
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(CinematicColors.glass.opacity(glassOpacity))

                    // Grain texture overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.white.opacity(0.02))
                        .overlay(
                            GrainTextureView()
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                                .opacity(0.03)
                        )

                    // Animated border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            borderColor.opacity(animateBorder ? borderGlow : 0.4),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: shadowColor.opacity(0.15), radius: shadowRadius, y: 4)
            .onAppear {
                if animateBorder {
                    withAnimation(CinematicAnimation.pulse) {
                        borderGlow = 0.6
                    }
                }
            }
    }
}
```

**Step 6: Create GrainTextureView helper**

```swift
/// Subtle noise texture for glass grain effect
struct GrainTextureView: View {
    var body: some View {
        Canvas { context, size in
            // Generate subtle noise pattern
            for _ in 0..<Int(size.width * size.height * 0.01) {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                context.fill(
                    Rectangle().path(in: rect),
                    with: .color(.white.opacity(Double.random(in: 0...0.5)))
                )
            }
        }
    }
}
```

**Step 7: Add convenience view modifiers**

```swift
extension View {
    /// Wrap content in a standard cinematic container
    func cinematicCard(
        style: GlassStyle = .standard,
        cornerRadius: CGFloat = 16,
        animateBorder: Bool = true
    ) -> some View {
        CinematicContainer(
            style: style,
            cornerRadius: cornerRadius,
            animateBorder: animateBorder
        ) {
            self
        }
    }
}
```

**Step 8: Add preview**

```swift
#if DEBUG
struct CinematicContainer_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            CinematicColors.voidBlack.ignoresSafeArea()

            VStack(spacing: 20) {
                CinematicContainer(style: .standard) {
                    Text("Standard Glass")
                        .foregroundColor(CinematicColors.textPrimary)
                        .padding()
                }

                CinematicContainer(style: .elevated) {
                    Text("Elevated Glass")
                        .foregroundColor(CinematicColors.textPrimary)
                        .padding()
                }

                CinematicContainer(style: .prayer) {
                    Text("Prayer Glass")
                        .foregroundColor(CinematicColors.textPrimary)
                        .padding()
                }

                Text("Using Modifier")
                    .foregroundColor(CinematicColors.textPrimary)
                    .padding()
                    .cinematicCard(style: .subtle)
            }
            .padding()
        }
    }
}
#endif
```

**Step 9: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 10: Commit**

```bash
git add MizanApp/Core/DesignSystem/Components/CinematicContainer.swift
git commit -m "feat(ui): add CinematicContainer glass card component"
```

---

## Task 2: EventHorizonDock - Collapsed State

**Files:**
- Create: `MizanApp/Core/DesignSystem/Components/EventHorizonDock.swift`

**Purpose:** Create the dock component starting with collapsed state (glowing point).

**Step 1: Create file with imports and DockItem definition**

```swift
//
//  EventHorizonDock.swift
//  MizanApp
//
//  Orbital navigation dock replacing standard TabView.
//  Collapsed: Single glowing point. Expanded: Elliptical orbit ring with 4 icons.
//

import SwiftUI

/// Navigation destinations for the dock
enum DockDestination: Int, CaseIterable, Identifiable {
    case timeline = 0
    case inbox = 1
    case mizanAI = 2
    case settings = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .timeline: return "الجدول"
        case .inbox: return "المهام"
        case .mizanAI: return "Mizan AI"
        case .settings: return "الإعدادات"
        }
    }

    var icon: String {
        switch self {
        case .timeline: return "calendar"
        case .inbox: return "tray.fill"
        case .mizanAI: return "sparkles"
        case .settings: return "gearshape.fill"
        }
    }

    /// Position angle on the ellipse (degrees from top)
    var orbitAngle: Double {
        switch self {
        case .timeline: return 0      // Top
        case .inbox: return 90        // Right
        case .mizanAI: return 180     // Bottom
        case .settings: return 270    // Left
        }
    }
}
```

**Step 2: Create EventHorizonDock struct with state**

```swift
/// Orbital navigation dock
struct EventHorizonDock: View {
    // Binding to selected destination
    @Binding var selection: DockDestination

    // State
    @State private var isExpanded = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var orbitRotation: Double = 0
    @State private var autoCollapseTask: _Concurrency.Task<Void, Never>?

    // Configuration
    private let collapsedSize: CGFloat = 12
    private let expandedWidth: CGFloat = 280
    private let expandedHeight: CGFloat = 80
    private let iconSize: CGFloat = 24
    private let autoCollapseDelay: Double = 3.0

    var body: some View {
        ZStack {
            if isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
        .frame(height: isExpanded ? expandedHeight + 60 : collapsedSize + 40)
        .onAppear {
            startPulseAnimation()
        }
    }
}
```

**Step 3: Implement collapsed view (glowing point)**

```swift
extension EventHorizonDock {
    private var collapsedView: some View {
        Button {
            expandDock()
        } label: {
            ZStack {
                // Outer glow
                Circle()
                    .fill(CinematicColors.accentCyan.opacity(0.3))
                    .frame(width: collapsedSize * 2, height: collapsedSize * 2)
                    .blur(radius: 8)
                    .scaleEffect(pulseScale)

                // Core point
                Circle()
                    .fill(CinematicColors.accentCyan)
                    .frame(width: collapsedSize, height: collapsedSize)

                // Inner bright spot
                Circle()
                    .fill(.white)
                    .frame(width: collapsedSize * 0.4, height: collapsedSize * 0.4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func startPulseAnimation() {
        withAnimation(CinematicAnimation.pulse) {
            pulseScale = 1.2
        }
    }
}
```

**Step 4: Implement expand/collapse functions**

```swift
extension EventHorizonDock {
    private func expandDock() {
        // Cancel any pending auto-collapse
        autoCollapseTask?.cancel()

        withAnimation(CinematicAnimation.dockExpand) {
            isExpanded = true
        }

        // Haptic feedback
        HapticManager.shared.trigger(.light)

        // Schedule auto-collapse
        scheduleAutoCollapse()

        // Start orbit rotation
        startOrbitRotation()
    }

    private func collapseDock() {
        autoCollapseTask?.cancel()

        withAnimation(CinematicAnimation.dockCollapse) {
            isExpanded = false
        }
    }

    private func scheduleAutoCollapse() {
        autoCollapseTask = _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(autoCollapseDelay * 1_000_000_000))
            if !_Concurrency.Task.isCancelled {
                await MainActor.run {
                    collapseDock()
                }
            }
        }
    }

    private func startOrbitRotation() {
        // Slow continuous rotation - 30 seconds for full cycle
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }
    }
}
```

**Step 5: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 6: Commit**

```bash
git add MizanApp/Core/DesignSystem/Components/EventHorizonDock.swift
git commit -m "feat(dock): add EventHorizonDock collapsed state"
```

---

## Task 3: EventHorizonDock - Expanded State

**Files:**
- Modify: `MizanApp/Core/DesignSystem/Components/EventHorizonDock.swift`

**Purpose:** Add expanded state with elliptical orbit ring and orbiting icons.

**Step 1: Add expandedView implementation**

Add after collapsedView:

```swift
extension EventHorizonDock {
    private var expandedView: some View {
        ZStack {
            // Elliptical orbit ring
            orbitRing

            // Orbiting icons
            ForEach(DockDestination.allCases) { destination in
                dockIcon(for: destination)
            }

            // Center tap area to collapse
            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
                .onTapGesture {
                    collapseDock()
                }
        }
        .frame(width: expandedWidth, height: expandedHeight)
    }

    private var orbitRing: some View {
        Ellipse()
            .stroke(
                LinearGradient(
                    colors: [
                        CinematicColors.accentCyan.opacity(0.6),
                        CinematicColors.accentCyan.opacity(0.2),
                        CinematicColors.accentCyan.opacity(0.6)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 1.5
            )
            .frame(width: expandedWidth, height: expandedHeight)
            .shadow(color: CinematicColors.accentCyan.opacity(0.3), radius: 4)
    }
}
```

**Step 2: Add dockIcon helper**

```swift
extension EventHorizonDock {
    private func dockIcon(for destination: DockDestination) -> some View {
        let angle = Angle(degrees: destination.orbitAngle + orbitRotation)
        let isSelected = selection == destination

        // Calculate position on ellipse
        let x = cos(angle.radians) * (expandedWidth / 2 - iconSize)
        let y = sin(angle.radians) * (expandedHeight / 2 - iconSize / 2)

        return Button {
            selectDestination(destination)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Glow for selected item
                    if isSelected {
                        Circle()
                            .fill(CinematicColors.accentCyan.opacity(0.3))
                            .frame(width: iconSize * 1.8, height: iconSize * 1.8)
                            .blur(radius: 8)
                    }

                    // Icon background
                    Circle()
                        .fill(isSelected ? CinematicColors.accentCyan : CinematicColors.surface)
                        .frame(width: iconSize * 1.5, height: iconSize * 1.5)

                    // Icon
                    Image(systemName: destination.icon)
                        .font(.system(size: iconSize * 0.6, weight: .medium))
                        .foregroundColor(isSelected ? CinematicColors.textOnAccent : CinematicColors.textPrimary)
                }

                // Label
                Text(destination.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? CinematicColors.accentCyan : CinematicColors.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .offset(x: x, y: y)
    }

    private func selectDestination(_ destination: DockDestination) {
        // Reset auto-collapse timer
        autoCollapseTask?.cancel()

        // Update selection
        withAnimation(CinematicAnimation.snappy) {
            selection = destination
        }

        // Haptic feedback
        HapticManager.shared.trigger(.selection)

        // Collapse after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            collapseDock()
        }
    }
}
```

**Step 3: Add preview**

```swift
#if DEBUG
struct EventHorizonDock_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var selection: DockDestination = .timeline

        var body: some View {
            ZStack {
                CinematicColors.voidBlack.ignoresSafeArea()

                VStack {
                    Spacer()

                    Text("Selected: \(selection.label)")
                        .foregroundColor(CinematicColors.textPrimary)

                    Spacer()

                    EventHorizonDock(selection: $selection)
                        .padding(.bottom, 24)
                }
            }
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
#endif
```

**Step 4: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add MizanApp/Core/DesignSystem/Components/EventHorizonDock.swift
git commit -m "feat(dock): add EventHorizonDock expanded state with orbiting icons"
```

---

## Task 4: WarpTransition Component

**Files:**
- Create: `MizanApp/Core/DesignSystem/Components/WarpTransition.swift`

**Purpose:** View transition with motion blur warp effect for tab switching.

**Step 1: Create file with imports and TransitionDirection enum**

```swift
//
//  WarpTransition.swift
//  MizanApp
//
//  Cinematic warp transition between views.
//  Features: Motion blur in exit direction, void moment, settle bounce.
//

import SwiftUI

/// Direction of warp transition
enum WarpDirection {
    case left
    case right
    case up
    case down

    var offset: CGSize {
        switch self {
        case .left: return CGSize(width: -UIScreen.main.bounds.width, height: 0)
        case .right: return CGSize(width: UIScreen.main.bounds.width, height: 0)
        case .up: return CGSize(width: 0, height: -UIScreen.main.bounds.height)
        case .down: return CGSize(width: 0, height: UIScreen.main.bounds.height)
        }
    }

    var opposite: WarpDirection {
        switch self {
        case .left: return .right
        case .right: return .left
        case .up: return .down
        case .down: return .up
        }
    }
}
```

**Step 2: Create WarpTransition modifier**

```swift
/// Warp transition view modifier
struct WarpTransitionModifier: ViewModifier {
    let direction: WarpDirection
    let isActive: Bool

    @State private var blur: CGFloat = 0
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .offset(offset)
            .scaleEffect(scale)
            .onChange(of: isActive) { _, active in
                if active {
                    performWarpOut()
                } else {
                    performWarpIn()
                }
            }
    }

    private func performWarpOut() {
        // Phase 1: Motion blur starts
        withAnimation(.easeIn(duration: 0.1)) {
            blur = 20
            scale = 0.98
        }

        // Phase 2: Slide out
        withAnimation(.easeIn(duration: 0.15).delay(0.1)) {
            offset = direction.offset
        }
    }

    private func performWarpIn() {
        // Reset to opposite side
        offset = direction.opposite.offset
        blur = 15
        scale = 0.98

        // Phase 1: Slide in with blur
        withAnimation(.easeOut(duration: 0.15)) {
            offset = .zero
        }

        // Phase 2: Clear blur and settle
        withAnimation(CinematicAnimation.snappy.delay(0.1)) {
            blur = 0
            scale = 1.0
        }
    }
}
```

**Step 3: Create WarpTransitionContainer for switching views**

```swift
/// Container that handles warp transitions between child views
struct WarpTransitionContainer<Content: View>: View {
    let selection: Int
    @ViewBuilder let content: () -> Content

    @State private var currentSelection: Int
    @State private var isTransitioning = false
    @State private var transitionDirection: WarpDirection = .right

    init(selection: Int, @ViewBuilder content: @escaping () -> Content) {
        self.selection = selection
        self._currentSelection = State(initialValue: selection)
        self.content = content
    }

    var body: some View {
        ZStack {
            // Void background (visible during transition)
            CinematicColors.voidBlack

            // Content with transition
            content()
                .modifier(WarpTransitionModifier(
                    direction: transitionDirection,
                    isActive: isTransitioning
                ))
        }
        .onChange(of: selection) { oldValue, newValue in
            if oldValue != newValue {
                performTransition(from: oldValue, to: newValue)
            }
        }
    }

    private func performTransition(from oldIndex: Int, to newIndex: Int) {
        // Determine direction based on index change
        transitionDirection = newIndex > oldIndex ? .left : .right

        // Start transition
        isTransitioning = true

        // Update content at midpoint
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentSelection = newIndex
            isTransitioning = false
        }
    }
}
```

**Step 4: Add view extension for easy warp transition**

```swift
extension View {
    /// Apply warp transition effect
    func warpTransition(direction: WarpDirection, isActive: Bool) -> some View {
        modifier(WarpTransitionModifier(direction: direction, isActive: isActive))
    }
}

/// SwiftUI Transition for use with .transition()
extension AnyTransition {
    static func warp(direction: WarpDirection) -> AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: direction == .left ? .trailing : .leading)),
            removal: .opacity.combined(with: .move(edge: direction == .left ? .leading : .trailing))
        )
    }
}
```

**Step 5: Add preview**

```swift
#if DEBUG
struct WarpTransition_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var selection = 0

        var body: some View {
            ZStack {
                CinematicColors.voidBlack.ignoresSafeArea()

                VStack {
                    // Tab content
                    ZStack {
                        if selection == 0 {
                            Color.blue.opacity(0.3)
                                .overlay(Text("Tab 1").foregroundColor(.white))
                        } else if selection == 1 {
                            Color.green.opacity(0.3)
                                .overlay(Text("Tab 2").foregroundColor(.white))
                        } else {
                            Color.purple.opacity(0.3)
                                .overlay(Text("Tab 3").foregroundColor(.white))
                        }
                    }
                    .animation(CinematicAnimation.warp, value: selection)

                    // Tab buttons
                    HStack(spacing: 20) {
                        ForEach(0..<3) { index in
                            Button("Tab \(index + 1)") {
                                withAnimation(CinematicAnimation.warp) {
                                    selection = index
                                }
                            }
                            .foregroundColor(selection == index ? CinematicColors.accentCyan : CinematicColors.textSecondary)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
#endif
```

**Step 6: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 7: Commit**

```bash
git add MizanApp/Core/DesignSystem/Components/WarpTransition.swift
git commit -m "feat(transition): add WarpTransition component"
```

---

## Task 5: Replace MainTabView with Dock Navigation

**Files:**
- Modify: `MizanApp/App/MizanApp.swift`

**Purpose:** Replace standard TabView with EventHorizonDock and DarkMatterBackground.

**Step 1: Update MainTabView to use EventHorizonDock**

Replace the existing MainTabView (lines 288-333) with:

```swift
// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedDestination: DockDestination = .timeline

    // Prayer period for background (computed from current time)
    private var currentPrayerPeriod: Int {
        // Get current prayer period from prayer time service
        // For now, default to Isha (5) - this will be connected to PrayerTimeService
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<6: return 0   // Fajr
        case 6..<7: return 1   // Sunrise
        case 12..<15: return 2 // Dhuhr
        case 15..<17: return 3 // Asr
        case 17..<19: return 4 // Maghrib
        default: return 5      // Isha
        }
    }

    var body: some View {
        ZStack {
            // Dark Matter background
            DarkMatterBackground(prayerPeriod: currentPrayerPeriod)

            // Main content area
            VStack(spacing: 0) {
                // Current view based on selection
                currentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer(minLength: 0)
            }

            // Dock at bottom
            VStack {
                Spacer()
                EventHorizonDock(selection: $selectedDestination)
                    .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private var currentView: some View {
        switch selectedDestination {
        case .timeline:
            TimelineView()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)

        case .inbox:
            InboxView()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)

        case .mizanAI:
            MizanAITab()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)

        case .settings:
            SettingsView()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
        }
    }
}
```

**Step 2: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Run tests**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:MizanAppTests 2>&1 | tail -40`

Expected: All tests pass

**Step 4: Commit**

```bash
git add MizanApp/App/MizanApp.swift
git commit -m "feat(nav): replace MainTabView with EventHorizonDock navigation"
```

---

## Task 6: Add Warp Transition to View Switching

**Files:**
- Modify: `MizanApp/App/MizanApp.swift`

**Purpose:** Add warp transition effect when switching between dock destinations.

**Step 1: Add transition state to MainTabView**

Add after `@State private var selectedDestination`:

```swift
@State private var previousDestination: DockDestination = .timeline
@State private var isTransitioning = false
```

**Step 2: Update currentView with warp transition**

Replace the `currentView` computed property with:

```swift
@ViewBuilder
private var currentView: some View {
    ZStack {
        switch selectedDestination {
        case .timeline:
            TimelineView()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(x: transitionOffset)),
                    removal: .opacity.combined(with: .offset(x: -transitionOffset))
                ))

        case .inbox:
            InboxView()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(x: transitionOffset)),
                    removal: .opacity.combined(with: .offset(x: -transitionOffset))
                ))

        case .mizanAI:
            MizanAITab()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(x: transitionOffset)),
                    removal: .opacity.combined(with: .offset(x: -transitionOffset))
                ))

        case .settings:
            SettingsView()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(x: transitionOffset)),
                    removal: .opacity.combined(with: .offset(x: -transitionOffset))
                ))
        }
    }
    .animation(CinematicAnimation.warp, value: selectedDestination)
}

private var transitionOffset: CGFloat {
    selectedDestination.rawValue > previousDestination.rawValue ? 50 : -50
}
```

**Step 3: Track destination changes**

Add after the dock in body:

```swift
.onChange(of: selectedDestination) { oldValue, newValue in
    previousDestination = oldValue
}
```

**Step 4: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add MizanApp/App/MizanApp.swift
git commit -m "feat(nav): add warp transition to view switching"
```

---

## Task 7: Haptic Feedback Integration

**Files:**
- Modify: `MizanApp/Core/DesignSystem/Components/EventHorizonDock.swift`

**Purpose:** Ensure proper haptic feedback for all dock interactions.

**Step 1: Verify HapticManager import and usage**

Check that HapticManager is properly imported and being used. If not available, add fallback:

```swift
// Add at top of file if HapticManager doesn't exist
#if canImport(UIKit)
import UIKit
#endif

// Helper for haptics if HapticManager doesn't exist
extension EventHorizonDock {
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    private func triggerSelectionHaptic() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
```

**Step 2: Update expandDock haptic**

In `expandDock()`, ensure haptic is:
```swift
// Soft "bloom" haptic for expansion
let generator = UIImpactFeedbackGenerator(style: .light)
generator.impactOccurred()
```

**Step 3: Update selectDestination haptic**

In `selectDestination()`, ensure haptic is:
```swift
// Crisp "lock" tap for selection
let generator = UISelectionFeedbackGenerator()
generator.selectionChanged()
```

**Step 4: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add MizanApp/Core/DesignSystem/Components/EventHorizonDock.swift
git commit -m "feat(dock): integrate haptic feedback"
```

---

## Task 8: Reduced Motion Support

**Files:**
- Modify: `MizanApp/Core/DesignSystem/Components/EventHorizonDock.swift`
- Modify: `MizanApp/Core/DesignSystem/Components/WarpTransition.swift`
- Modify: `MizanApp/Core/DesignSystem/Components/CinematicContainer.swift`

**Purpose:** Respect accessibility Reduce Motion preference.

**Step 1: Add reduce motion check to EventHorizonDock**

Add environment property:
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

Update `expandDock()`:
```swift
private func expandDock() {
    autoCollapseTask?.cancel()

    if reduceMotion {
        // Instant state change
        isExpanded = true
    } else {
        withAnimation(CinematicAnimation.dockExpand) {
            isExpanded = true
        }
    }

    // Haptic feedback (always trigger)
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()

    scheduleAutoCollapse()

    if !reduceMotion {
        startOrbitRotation()
    }
}
```

**Step 2: Add reduce motion check to WarpTransition**

Add to WarpTransitionModifier:
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

func body(content: Content) -> some View {
    if reduceMotion {
        // Simple cross-fade for reduced motion
        content
            .opacity(isActive ? 0 : 1)
    } else {
        content
            .blur(radius: blur)
            .offset(offset)
            .scaleEffect(scale)
            .onChange(of: isActive) { _, active in
                if active {
                    performWarpOut()
                } else {
                    performWarpIn()
                }
            }
    }
}
```

**Step 3: Add reduce motion check to CinematicContainer**

Add environment property:
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

Update `onAppear`:
```swift
.onAppear {
    if animateBorder && !reduceMotion {
        withAnimation(CinematicAnimation.pulse) {
            borderGlow = 0.6
        }
    }
}
```

**Step 4: Build and verify**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add MizanApp/Core/DesignSystem/Components/EventHorizonDock.swift
git add MizanApp/Core/DesignSystem/Components/WarpTransition.swift
git add MizanApp/Core/DesignSystem/Components/CinematicContainer.swift
git commit -m "feat(a11y): add reduced motion support to core components"
```

---

## Task 9: Full Integration Test

**Files:**
- No new files

**Purpose:** Run full test suite and verify the integration.

**Step 1: Run unit tests**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:MizanAppTests 2>&1 | tail -50`

Expected: All tests pass

**Step 2: Run UI tests**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:MizanAppUITests 2>&1 | tail -50`

Expected: Tests pass (note: testSettingsTabLoads may be flaky - pre-existing issue)

**Step 3: Build for release**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && xcodebuild -scheme MizanApp -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Release build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 4: Document any issues**

If issues found, document them for follow-up.

---

## Task 10: Phase 3 Completion Commit

**Files:**
- No new files

**Purpose:** Create final commit marking Phase 3 completion.

**Step 1: Verify all files are committed**

Run: `cd /Users/engammar/Apps/Mizan/.worktrees/event-horizon && git status`

Expected: Clean working directory

**Step 2: Create summary commit if needed**

If any uncommitted changes:
```bash
git add -A
git commit -m "chore: Phase 3 cleanup and finalization"
```

**Step 3: Tag phase completion**

```bash
git tag -a phase3-complete -m "Phase 3: Core Components complete"
```

---

## Verification Checklist

After completing all tasks, verify:

- [ ] CinematicContainer renders glass cards with animated border
- [ ] EventHorizonDock shows collapsed state (glowing point)
- [ ] EventHorizonDock expands to orbital ring on tap
- [ ] Dock icons orbit and can be selected
- [ ] Dock auto-collapses after 3 seconds
- [ ] View switching uses warp transition
- [ ] Haptic feedback works on dock interactions
- [ ] Reduced motion disables animations
- [ ] Build succeeds
- [ ] Tests pass
