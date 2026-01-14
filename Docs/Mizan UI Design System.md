# Mizan UI Design System

## Vision

Mizan is a **generational** iOS app that makes users feel emotionally impacted when they use it. Every interaction is intentional, every transition is magical, and every moment is crafted with deep care.

**Core Principle:** Change the FEELING, not the functionality. Same features, dramatically better experience.

**Design Philosophy:**
- iOS-native (evolves with Apple's design language)
- Progressive disclosure (essentials first, complexity on demand)
- Performance-first (eliminate lag, maximize fluidity)
- Sensory-rich (haptics, animations, visual feedback)

**Inspiration:**
- **Structured**: Two-tier task creation, minimal friction
- **Things 3**: Paper-like minimalism, deeply native feel
- **Flighty**: Dark sophistication, high-quality haptics
- **Headspace**: Soft animations, award-winning UI

---

## 1. Design System Architecture

### 1.1 Folder Structure

```
MizanApp/DesignSystem/
├── Tokens/
│   ├── ColorTokens.swift
│   ├── TypographyTokens.swift
│   ├── SpacingTokens.swift
│   ├── AnimationTokens.swift
│   └── ShadowTokens.swift
├── Components/
│   ├── Buttons/
│   ├── Cards/
│   ├── Inputs/
│   ├── Feedback/
│   └── Layout/
├── Animations/
│   ├── SpringPresets.swift
│   ├── TransitionPresets.swift
│   ├── PhaseAnimators/
│   └── KeyframeAnimations/
├── Effects/
│   ├── ParticleSystem.swift
│   ├── ConfettiView.swift
│   ├── AtmosphericBackground.swift
│   └── GlowEffect.swift
└── Haptics/
    └── HapticPatterns.swift
```

---

## 2. Token Systems

### 2.1 Typography Tokens

```swift
struct MZTypography {
    // Display - splash, celebrations
    static let displayLarge = Font.system(size: 56, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 44, weight: .bold, design: .rounded)

    // Headlines - section headers
    static let headlineLarge = Font.system(size: 32, weight: .semibold)
    static let headlineMedium = Font.system(size: 28, weight: .semibold)
    static let headlineSmall = Font.system(size: 24, weight: .semibold)

    // Title - cards, navigation
    static let titleLarge = Font.system(size: 22, weight: .semibold)
    static let titleMedium = Font.system(size: 18, weight: .semibold)
    static let titleSmall = Font.system(size: 16, weight: .semibold)

    // Body - content
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)

    // Label - metadata
    static let labelLarge = Font.system(size: 14, weight: .medium)
    static let labelMedium = Font.system(size: 12, weight: .medium)
    static let labelSmall = Font.system(size: 11, weight: .medium)

    // Arabic variants
    static let arabicDisplay = Font.custom("SF Arabic Rounded", size: 48).weight(.bold)
    static let arabicHeadline = Font.custom("SF Arabic", size: 28).weight(.semibold)
    static let arabicBody = Font.custom("SF Arabic", size: 17)
}
```

### 2.2 Spacing Tokens (8pt Grid)

```swift
struct MZSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64

    // Semantic
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let screenPadding: CGFloat = 20
    static let itemSpacing: CGFloat = 12
}
```

### 2.3 Animation Tokens

```swift
struct MZAnimation {
    // Standard springs
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.9)
    static let soft = Animation.spring(response: 0.6, dampingFraction: 0.85)
    static let stiff = Animation.spring(response: 0.2, dampingFraction: 0.95)

    // Dramatic springs
    static let dramatic = Animation.spring(response: 0.7, dampingFraction: 0.5)
    static let breathe = Animation.spring(response: 1.2, dampingFraction: 0.7)
    static let celebration = Animation.spring(response: 0.4, dampingFraction: 0.5)

    // Durations
    struct Duration {
        static let instant: Double = 0.0
        static let veryFast: Double = 0.15
        static let fast: Double = 0.2
        static let medium: Double = 0.4
        static let slow: Double = 0.6
        static let dramatic: Double = 1.2
    }

    // Stagger for lists
    static func stagger(index: Int, interval: Double = 0.05) -> Double {
        Double(index) * interval
    }
}
```

### 2.4 Shadow Tokens

```swift
struct MZShadow {
    struct Level {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }

    static let none = Level(color: .clear, radius: 0, y: 0)
    static let sm = Level(color: .black.opacity(0.08), radius: 4, y: 2)
    static let md = Level(color: .black.opacity(0.12), radius: 8, y: 4)
    static let lg = Level(color: .black.opacity(0.16), radius: 16, y: 8)
    static let lifted = Level(color: .black.opacity(0.25), radius: 20, y: 12)

    static func glow(color: Color, intensity: Double = 0.4) -> Level {
        Level(color: color.opacity(intensity), radius: 20, y: 0)
    }
}
```

---

## 3. Color Themes

### 3.1 Noor (Light - Default)

```swift
let colors = MZColorPalette(
    background: "#FFFFFF",
    surface: "#FFFFFF",
    surfaceSecondary: "#F8F8F8",
    primary: "#007AFF",
    primaryLight: "#4D94FF",
    primaryDark: "#0051CC",
    textPrimary: "#000000",
    textSecondary: "#8E8E93",
    textTertiary: "#C7C7CC",
    success: "#34C759",
    warning: "#FF9500",
    error: "#FF3B30",
    divider: "#E5E5EA"
)
```

### 3.2 Layl (Dark - Pro)

```swift
let colors = MZColorPalette(
    background: "#000000",
    surface: "#1C1C1E",
    surfaceSecondary: "#2C2C2E",
    primary: "#0A84FF",
    textPrimary: "#FFFFFF",
    textSecondary: "#8E8E93"
)
let specialEffects = MZSpecialEffects(useGlowInsteadOfShadow: true)
```

### 3.3 Fajr (Dawn - Pro)

```swift
let colors = MZColorPalette(
    background: "#E8DFF5",
    surface: "#FFFFFF",
    primary: "#6C63FF",
    textPrimary: "#2D2A4A"
)
let specialEffects = MZSpecialEffects(
    backgroundGradient: ["#E8DFF5", "#FCE1E4", "#FCF4DD"]
)
```

### 3.4 Ramadan (Celebration - Pro)

```swift
let colors = MZColorPalette(
    background: "#1E1B4B",
    surface: "#312E81",
    primary: "#FFD700",
    textPrimary: "#FFFFFF"
)
let specialEffects = MZSpecialEffects(
    useGlowInsteadOfShadow: true,
    starParticles: true,
    festiveAnimations: true,
    autoActivateDuringRamadan: true
)
```

---

## 4. Screen Redesigns

### 4.1 AddTaskSheet - Modern Two-Tier Design

**Problem:** Current Form causes lag, all options visible at once, not following modern patterns.

**Solution:** ScrollView + VStack, progressive disclosure, horizontal scrolling.

#### Wireframes

**Title Section:**
```
┌─────────────────────────────────────────┐
│  📝 اسم المهمة                          │
│  ┌─────────────────────────────────────┐│
│  │ مثال: مراجعة المشروع               ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

**Duration Section:**
```
┌─────────────────────────────────────────┐
│  ⏱️ المدة                               │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐    │
│  │15د │ │30د │ │45د │ │1س  │ │1.5س│ →  │
│  └────┘ └────┘ └────┘ └────┘ └────┘    │
└─────────────────────────────────────────┘
```

**Category Section (Horizontal Scroll):**
```
┌─────────────────────────────────────────┐
│  🏷️ الفئة                               │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐       │
│  │ 👤  │ │ 💼  │ │ 📖  │ │ 🏋️  │  →    │
│  │شخصي │ │ عمل │ │دراسة│ │رياضة│       │
│  └─────┘ └─────┘ └─────┘ └─────┘       │
└─────────────────────────────────────────┘
```

**Advanced Section (Collapsible):**
```
┌─────────────────────────────────────────┐
│  ⚙️ خيارات إضافية                    ▼  │
├─────────────────────────────────────────┤
│  📅 جدولة                          [OFF]│
│  🔄 التكرار                   [OFF] PRO │
│  📝 ملاحظات                             │
│  ┌─────────────────────────────────────┐│
│  │ اضف ملاحظات...                     ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

**Save Button (Fixed Bottom):**
```
┌─────────────────────────────────────────┐
│  ┌─────────────────────────────────────┐│
│  │         إضافة المهمة ✓             ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

#### Component Specifications

| Component | Property | Value |
|-----------|----------|-------|
| **Title Field** | Font | 17pt regular |
| | Background | surfaceSecondaryColor |
| | Corner radius | 12pt |
| | Padding | 14pt |
| **Duration Chip** | Size | 56pt × 36pt |
| | Font | labelLarge (14pt medium) |
| | Spacing | 10pt |
| | Shape | Capsule |
| **Category Chip** | Size | 70pt × 80pt |
| | Icon size | 24pt SF Symbol |
| | Label font | 12pt |
| | Shape | RoundedRectangle 12pt |
| **Advanced Header** | Font | titleSmall (16pt semibold) |
| | Chevron | 14pt semibold |
| | Padding | 16pt |
| **Save Button** | Height | 50pt |
| | Font | titleSmall (16pt semibold) |
| | Shape | Capsule |
| | Shadow | primaryColor.opacity(0.4), radius 8, y 4 |

#### State Management

```swift
@State private var showAdvancedOptions = false  // Controls collapsible section
@State private var isKeyboardVisible = false    // For save button positioning
```

#### Verification Checklist

- [ ] Open Add Task sheet - feels snappy, no lag
- [ ] Essential fields (title, duration, category) visible immediately
- [ ] Duration chips scroll horizontally, selection works with haptic
- [ ] Category chips scroll horizontally (NOT grid), selection works
- [ ] Tap "خيارات إضافية" to expand/collapse advanced section
- [ ] Schedule toggle + date/time pickers work correctly
- [ ] Recurrence shows Pro badge for free users
- [ ] Notes field expands when typing
- [ ] Save button fixed at bottom, always accessible
- [ ] Save button disabled when title is empty
- [ ] Edit mode loads all existing task data correctly
- [ ] Delete button appears in edit mode
- [ ] Keyboard doesn't cover save button
- [ ] RTL layout correct for Arabic text

#### Implementation

```swift
struct AddTaskSheet: View {
    @State private var showAdvancedOptions = false

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: MZSpacing.lg) {
                            // TIER 1: ESSENTIALS (Always Visible)
                            titleSection
                            durationSection
                            categorySection

                            // TIER 2: ADVANCED (Collapsible)
                            advancedSection
                        }
                        .padding(MZSpacing.screenPadding)
                    }

                    // Fixed Save Button
                    saveButton
                        .padding(MZSpacing.screenPadding)
                }
            }
            .navigationTitle(isEditing ? "تعديل المهمة" : "مهمة جديدة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
            }
        }
    }

    // MARK: - Title Section (Prominent)
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            Text("العنوان")
                .font(MZTypography.labelLarge)
                .foregroundColor(themeManager.textSecondaryColor)

            TextField("أدخل عنوان المهمة", text: $taskTitle)
                .font(MZTypography.titleLarge)
                .padding(MZSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.surfaceSecondaryColor)
                )
                .focused($isTitleFocused)
        }
    }

    // MARK: - Duration Section (Compact Horizontal Chips)
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("المدة")
                .font(MZTypography.labelLarge)
                .foregroundColor(themeManager.textSecondaryColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MZSpacing.xs) {
                    ForEach(durationOptions, id: \.self) { duration in
                        DurationChip(
                            duration: duration,
                            isSelected: selectedDuration == duration,
                            action: {
                                withAnimation(MZAnimation.snappy) {
                                    selectedDuration = duration
                                }
                                HapticManager.shared.trigger(.selection)
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Category Section (Horizontal Scroll - NOT Grid)
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("الفئة")
                .font(MZTypography.labelLarge)
                .foregroundColor(themeManager.textSecondaryColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MZSpacing.sm) {
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: {
                                withAnimation(MZAnimation.bouncy) {
                                    selectedCategory = category
                                }
                                HapticManager.shared.trigger(.selection)
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Advanced Section (Collapsible)
    private var advancedSection: some View {
        VStack(spacing: MZSpacing.md) {
            // Disclosure button
            Button {
                withAnimation(MZAnimation.gentle) {
                    showAdvancedOptions.toggle()
                }
                HapticManager.shared.trigger(.light)
            } label: {
                HStack {
                    Text("خيارات إضافية")
                        .font(MZTypography.titleSmall)
                        .foregroundColor(themeManager.textPrimaryColor)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.textSecondaryColor)
                        .rotationEffect(.degrees(showAdvancedOptions ? 180 : 0))
                }
                .padding(MZSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.surfaceSecondaryColor)
                )
            }

            // Collapsible content
            if showAdvancedOptions {
                VStack(spacing: MZSpacing.md) {
                    // Schedule toggle
                    scheduleSection

                    // Recurrence (Pro)
                    if isPro {
                        recurrenceSection
                    }

                    // Notes (expandable)
                    notesSection
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
    }

    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(spacing: MZSpacing.sm) {
            Toggle(isOn: $isScheduled) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(themeManager.primaryColor)
                    Text("جدولة")
                        .font(MZTypography.bodyLarge)
                }
            }
            .tint(themeManager.primaryColor)
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.surfaceSecondaryColor)
            )
            .onChange(of: isScheduled) { _, value in
                HapticManager.shared.trigger(value ? .success : .light)
            }

            if isScheduled {
                DatePicker("التاريخ والوقت", selection: $scheduledDate)
                    .datePickerStyle(.compact)
                    .padding(MZSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.surfaceSecondaryColor)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            Text("ملاحظات")
                .font(MZTypography.labelLarge)
                .foregroundColor(themeManager.textSecondaryColor)

            TextEditor(text: $notes)
                .font(MZTypography.bodyLarge)
                .frame(minHeight: 80, maxHeight: 150)
                .padding(MZSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.surfaceSecondaryColor)
                )
                .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Save Button (Fixed Bottom)
    private var saveButton: some View {
        Button {
            saveTask()
        } label: {
            Text(isEditing ? "حفظ التعديلات" : "إضافة المهمة")
                .font(MZTypography.titleSmall)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MZSpacing.md)
                .background(
                    Capsule()
                        .fill(
                            taskTitle.isEmpty
                                ? Color.gray
                                : themeManager.primaryColor
                        )
                        .shadow(
                            color: themeManager.primaryColor.opacity(0.4),
                            radius: 8, y: 4
                        )
                )
        }
        .disabled(taskTitle.isEmpty)
        .buttonStyle(PressableButtonStyle())
    }

    private let durationOptions = [15, 30, 45, 60, 90, 120]
}

// MARK: - Duration Chip Component
struct DurationChip: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            Text("\(duration) د")
                .font(MZTypography.labelLarge)
                .foregroundColor(isSelected ? .white : themeManager.textPrimaryColor)
                .padding(.horizontal, MZSpacing.md)
                .padding(.vertical, MZSpacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
                )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Category Chip Component
struct CategoryChip: View {
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: MZSpacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.nameArabic)
                    .font(MZTypography.labelLarge)
            }
            .foregroundColor(isSelected ? .white : Color(hex: category.colorHex))
            .padding(.horizontal, MZSpacing.md)
            .padding(.vertical, MZSpacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: category.colorHex) : Color(hex: category.colorHex).opacity(0.15))
            )
        }
        .buttonStyle(PressableButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(MZAnimation.bouncy, value: isSelected)
    }
}
```

---

### 4.2 TimelineView - Atmospheric Prayer Experience

**Changes from current:**
- Break 950-line monolith into components
- Add prayer proximity atmospheric effects
- Enhance drag-and-drop fluidity
- Cinematic date navigation

```swift
struct TimelineView: View {
    @State private var selectedDate = Date()

    var body: some View {
        ZStack {
            // Atmospheric background (time-of-day gradient)
            AtmosphericTimeBackground(date: selectedDate)

            VStack(spacing: 0) {
                // Cinematic date navigator
                CinematicDateNavigator(selectedDate: $selectedDate)

                // Timeline content
                TimelineContent(date: selectedDate)
            }
        }
    }
}

// MARK: - Cinematic Date Navigator
struct CinematicDateNavigator: View {
    @Binding var selectedDate: Date
    @State private var transitionDirection: TransitionDirection = .forward

    enum TransitionDirection { case forward, backward }

    var body: some View {
        HStack(spacing: MZSpacing.sm) {
            NavigationArrowButton(direction: .right) {
                navigateBack()
            }

            Spacer()

            // Date with push transition
            VStack(spacing: MZSpacing.xxs) {
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(MZTypography.titleMedium)
                    .id("date-\(selectedDate)")
                    .transition(dateTransition)

                Text(hijriDate)
                    .font(MZTypography.labelMedium)
                    .foregroundColor(.secondary)
            }

            Spacer()

            NavigationArrowButton(direction: .left) {
                navigateForward()
            }

            // Today button
            if !Calendar.current.isDateInToday(selectedDate) {
                Button {
                    navigateToToday()
                } label: {
                    Text("اليوم")
                        .font(MZTypography.labelLarge)
                        .foregroundColor(.white)
                        .padding(.horizontal, MZSpacing.md)
                        .padding(.vertical, MZSpacing.xs)
                        .background(Capsule().fill(Color.accentColor))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, MZSpacing.screenPadding)
        .padding(.vertical, MZSpacing.sm)
    }

    private var dateTransition: AnyTransition {
        .asymmetric(
            insertion: .push(from: transitionDirection == .forward ? .trailing : .leading).combined(with: .opacity),
            removal: .push(from: transitionDirection == .forward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func navigateForward() {
        transitionDirection = .forward
        HapticManager.shared.trigger(.selection)
        withAnimation(MZAnimation.bouncy) {
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
        }
    }

    private func navigateBack() {
        transitionDirection = .backward
        HapticManager.shared.trigger(.selection)
        withAnimation(MZAnimation.bouncy) {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
        }
    }

    private func navigateToToday() {
        let today = Date()
        transitionDirection = selectedDate > today ? .backward : .forward
        HapticManager.shared.trigger(.medium)
        withAnimation(MZAnimation.gentle) {
            selectedDate = today
        }
    }

    private var hijriDate: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: selectedDate)
    }
}

// MARK: - Timeline Content
struct TimelineContent: View {
    let date: Date
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: MZSpacing.sm) {
                    ForEach(timelineItems, id: \.id) { item in
                        TimelineItemView(item: item)
                            .id(item.id)
                    }
                }
                .padding(MZSpacing.screenPadding)
            }
            .onAppear {
                // Scroll to current time
                scrollToCurrentTime(proxy: proxy)
            }
        }
    }
}

// MARK: - Prayer Block with Atmosphere
struct PrayerBlockView: View {
    let prayer: PrayerTime
    let isApproaching: Bool
    let minutesUntil: Int

    @State private var pulsePhase: CGFloat = 0
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            // Base card
            HStack {
                VStack(alignment: .leading, spacing: MZSpacing.xs) {
                    HStack {
                        Image(systemName: prayer.icon)
                            .font(.system(size: 20))
                            .symbolEffect(.bounce, value: isApproaching)

                        Text(prayer.nameArabic)
                            .font(MZTypography.titleMedium)
                    }
                    .foregroundColor(.white)

                    Text(prayer.time.formatted(date: .omitted, time: .shortened))
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Countdown badge when approaching
                if isApproaching && minutesUntil <= 30 {
                    PrayerCountdownBadge(minutes: minutesUntil)
                }
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: prayer.colorHex), Color(hex: prayer.colorHex).opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )

            // Atmospheric glow when approaching
            if isApproaching {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: prayer.colorHex), lineWidth: 2 + pulsePhase * 2)
                    .blur(radius: 4 + pulsePhase * 4)
                    .opacity(0.6 - pulsePhase * 0.3)
            }
        }
        .onAppear {
            if isApproaching {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulsePhase = 1.0
                }
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: minutesUntil == 5)
        .sensoryFeedback(.impact(flexibility: .solid), trigger: minutesUntil == 1)
    }
}

// MARK: - Countdown Badge
struct PrayerCountdownBadge: View {
    let minutes: Int
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12))
            Text("\(minutes) د")
                .font(MZTypography.labelMedium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, MZSpacing.sm)
        .padding(.vertical, MZSpacing.xs)
        .background(
            Capsule()
                .fill(urgencyColor)
                .scaleEffect(pulseScale)
        )
        .onAppear {
            if minutes <= 5 {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.1
                }
            }
        }
    }

    private var urgencyColor: Color {
        if minutes <= 1 { return .red }
        else if minutes <= 5 { return .orange }
        else { return .white.opacity(0.3) }
    }
}
```

---

### 4.3 InboxView - Enhanced Cards & Interactions

**Changes from current:**
- Remove Form/List overhead
- Better card design with depth
- Horizontal category badges
- Delightful empty state
- Enhanced FAB

```swift
struct InboxView: View {
    @State private var showAddTask = false
    @State private var showCompletedTasks = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()

            if inboxTasks.isEmpty && !showCompletedTasks {
                // Delightful empty state
                DelightfulEmptyState(type: .inbox) {
                    showAddTask = true
                }
            } else {
                // Task list
                ScrollView {
                    LazyVStack(spacing: MZSpacing.sm) {
                        // Active tasks
                        ForEach(Array(inboxTasks.enumerated()), id: \.element.id) { index, task in
                            InboxTaskCard(task: task)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                                .animation(
                                    MZAnimation.bouncy.delay(MZAnimation.stagger(index: index)),
                                    value: inboxTasks.count
                                )
                        }

                        // Completed section
                        if !completedTasks.isEmpty {
                            CompletedTasksSection(
                                tasks: completedTasks,
                                isExpanded: $showCompletedTasks
                            )
                        }
                    }
                    .padding(MZSpacing.screenPadding)
                    .padding(.bottom, 100) // Space for FAB
                }
            }

            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    EnhancedFAB {
                        showAddTask = true
                    }
                    .padding(MZSpacing.screenPadding)
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet()
        }
    }
}

// MARK: - Inbox Task Card
struct InboxTaskCard: View {
    let task: Task
    @State private var isPressed = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: MZSpacing.md) {
            // Category color bar
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: task.category.colorHex))
                .frame(width: 4, height: 50)

            // Task content
            VStack(alignment: .leading, spacing: MZSpacing.xs) {
                Text(task.title)
                    .font(MZTypography.titleSmall)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .lineLimit(2)

                HStack(spacing: MZSpacing.sm) {
                    // Duration chip
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("\(task.duration) د")
                            .font(MZTypography.labelSmall)
                    }
                    .foregroundColor(themeManager.textSecondaryColor)

                    // Category chip
                    Text(task.category.nameArabic)
                        .font(MZTypography.labelSmall)
                        .foregroundColor(Color(hex: task.category.colorHex))
                        .padding(.horizontal, MZSpacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(hex: task.category.colorHex).opacity(0.15))
                        )
                }
            }

            Spacer()

            // Drag indicator
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16))
                .foregroundColor(themeManager.textTertiaryColor)
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.surfaceColor)
                .shadow(
                    color: MZShadow.sm.color,
                    radius: MZShadow.sm.radius,
                    y: MZShadow.sm.y
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(MZAnimation.snappy, value: isPressed)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                scheduleTask(task)
            } label: {
                Label("جدولة", systemImage: "calendar.badge.plus")
            }
            .tint(themeManager.primaryColor)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteTask(task)
            } label: {
                Label("حذف", systemImage: "trash")
            }

            Button {
                completeTask(task)
            } label: {
                Label("تم", systemImage: "checkmark")
            }
            .tint(.green)
        }
        .contextMenu {
            Button {
                duplicateTask(task)
            } label: {
                Label("نسخ", systemImage: "doc.on.doc")
            }

            Button {
                editTask(task)
            } label: {
                Label("تعديل", systemImage: "pencil")
            }
        }
    }
}

// MARK: - Enhanced FAB
struct EnhancedFAB: View {
    let action: () -> Void
    @State private var isPressed = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(themeManager.primaryColor)
                        .shadow(
                            color: themeManager.primaryColor.opacity(0.4),
                            radius: 12,
                            y: 6
                        )
                )
        }
        .buttonStyle(BouncyButtonStyle())
        .symbolEffect(.bounce, value: isPressed)
    }
}

// MARK: - Delightful Empty State
struct DelightfulEmptyState: View {
    let type: EmptyStateType
    let action: () -> Void

    @State private var isAnimating = false
    @State private var iconBounce = false

    enum EmptyStateType {
        case inbox, timeline, completed

        var icon: String {
            switch self {
            case .inbox: return "tray"
            case .timeline: return "calendar.badge.plus"
            case .completed: return "checkmark.seal"
            }
        }

        var title: String {
            switch self {
            case .inbox: return "صندوق الوارد فارغ"
            case .timeline: return "لا توجد مهام مجدولة"
            case .completed: return "لا توجد مهام مكتملة"
            }
        }

        var subtitle: String {
            switch self {
            case .inbox: return "أضف مهمة جديدة لتبدأ"
            case .timeline: return "اسحب مهمة من صندوق الوارد"
            case .completed: return "أكمل مهمة لتراها هنا"
            }
        }

        var buttonTitle: String? {
            switch self {
            case .inbox: return "إضافة مهمة"
            case .timeline: return "عرض المهام"
            case .completed: return nil
            }
        }
    }

    var body: some View {
        VStack(spacing: MZSpacing.lg) {
            // Animated circles
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 0.5 : 0.2)
                        .animation(
                            .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                            value: isAnimating
                        )
                }

                Image(systemName: type.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                    .symbolEffect(.bounce.byLayer, value: iconBounce)
            }

            VStack(spacing: MZSpacing.xs) {
                Text(type.title)
                    .font(MZTypography.titleLarge)

                Text(type.subtitle)
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(.secondary)
            }

            if let buttonTitle = type.buttonTitle {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(MZTypography.titleSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, MZSpacing.lg)
                        .padding(.vertical, MZSpacing.sm)
                        .background(Capsule().fill(Color.accentColor))
                }
            }
        }
        .onAppear {
            isAnimating = true
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                iconBounce.toggle()
            }
        }
    }
}
```

---

### 4.4 SettingsView - Visual Hierarchy

**Changes:**
- Section headers with icons
- Pro features with gold accent
- Interactive toggles with haptics

```swift
struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: MZSpacing.lg) {
                    // Pro upgrade banner (if not pro)
                    if !isPro {
                        ProUpgradeBanner()
                    }

                    // Settings sections
                    SettingsSection(title: "الصلاة", icon: "moon.stars.fill") {
                        PrayerSettingsContent()
                    }

                    SettingsSection(title: "الإشعارات", icon: "bell.fill") {
                        NotificationSettingsContent()
                    }

                    SettingsSection(title: "المظهر", icon: "paintbrush.fill") {
                        ThemeSettingsContent()
                    }

                    SettingsSection(title: "حول التطبيق", icon: "info.circle.fill") {
                        AboutContent()
                    }
                }
                .padding(MZSpacing.screenPadding)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("الإعدادات")
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            // Header
            HStack(spacing: MZSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.primaryColor)

                Text(title)
                    .font(MZTypography.titleSmall)
                    .foregroundColor(themeManager.textPrimaryColor)
            }

            // Content
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.surfaceColor)
            )
        }
    }
}

// MARK: - Animated Toggle Row
struct AnimatedToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack {
            HStack(spacing: MZSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(themeManager.primaryColor)
                    .symbolEffect(.bounce, value: isOn)

                Text(title)
                    .font(MZTypography.bodyLarge)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(themeManager.primaryColor)
        }
        .padding(MZSpacing.md)
        .onChange(of: isOn) { _, value in
            HapticManager.shared.trigger(value ? .success : .light)
        }
    }
}
```

---

### 4.5 Onboarding - Story-Driven Flow

```swift
struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isTransitioning = false

    var body: some View {
        ZStack {
            // Evolving background
            OnboardingBackground(page: currentPage)

            TabView(selection: $currentPage) {
                WelcomePage { advancePage() }.tag(0)
                LocationPage { advancePage() }.tag(1)
                MethodPage { advancePage() }.tag(2)
                NotificationsPage { completeOnboarding() }.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .disabled(isTransitioning)

            // Custom page indicator
            VStack {
                Spacer()
                PageIndicator(current: currentPage, total: 4)
                    .padding(.bottom, 100)
            }
        }
    }

    private func advancePage() {
        isTransitioning = true
        HapticManager.shared.trigger(.medium)

        withAnimation(MZAnimation.gentle) {
            currentPage += 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isTransitioning = false
        }
    }
}

// MARK: - Page Indicator
struct PageIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: MZSpacing.sm) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.white : Color.white.opacity(0.3))
                    .frame(width: i == current ? 32 : 8, height: 8)
                    .animation(MZAnimation.bouncy, value: current)
            }
        }
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    let onContinue: () -> Void

    @State private var moonRevealed = false
    @State private var titleRevealed = false
    @State private var featuresRevealed = false
    @State private var buttonRevealed = false

    var body: some View {
        VStack(spacing: MZSpacing.xxl) {
            Spacer()

            // Moon icon
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.white, Color(hex: "#FFD700")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .symbolEffect(.bounce, options: .speed(0.5).repeat(1), value: moonRevealed)
                .scaleEffect(moonRevealed ? 1.0 : 0.3)
                .opacity(moonRevealed ? 1.0 : 0.0)
                .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: 30)

            VStack(spacing: MZSpacing.md) {
                Text("ميزان")
                    .font(MZTypography.displayLarge)
                    .foregroundColor(.white)
                    .opacity(titleRevealed ? 1 : 0)
                    .offset(y: titleRevealed ? 0 : 30)

                Text("خطط يومك حول ما يهم حقًا")
                    .font(MZTypography.bodyLarge)
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(titleRevealed ? 1 : 0)
            }

            // Features with stagger
            VStack(alignment: .leading, spacing: MZSpacing.md) {
                FeatureRow(icon: "clock.fill", text: "تتبع أوقات الصلاة تلقائيًا")
                    .opacity(featuresRevealed ? 1 : 0)
                    .offset(x: featuresRevealed ? 0 : -30)

                FeatureRow(icon: "list.bullet", text: "إدارة المهام اليومية")
                    .opacity(featuresRevealed ? 1 : 0)
                    .offset(x: featuresRevealed ? 0 : -30)
                    .animation(MZAnimation.gentle.delay(0.1), value: featuresRevealed)

                FeatureRow(icon: "bell.fill", text: "تنبيهات ذكية")
                    .opacity(featuresRevealed ? 1 : 0)
                    .offset(x: featuresRevealed ? 0 : -30)
                    .animation(MZAnimation.gentle.delay(0.2), value: featuresRevealed)
            }
            .padding(.horizontal, MZSpacing.xxl)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("ابدأ")
                    .font(MZTypography.titleMedium)
                    .foregroundColor(Color(hex: "#14746F"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MZSpacing.md)
                    .background(
                        Capsule()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    )
            }
            .padding(.horizontal, MZSpacing.xxl)
            .opacity(buttonRevealed ? 1 : 0)
            .offset(y: buttonRevealed ? 0 : 30)
        }
        .padding(.bottom, MZSpacing.xxl)
        .onAppear {
            // Choreographed reveal
            withAnimation(MZAnimation.dramatic.delay(0.3)) { moonRevealed = true }
            withAnimation(MZAnimation.gentle.delay(0.6)) { titleRevealed = true }
            withAnimation(MZAnimation.gentle.delay(0.9)) { featuresRevealed = true }
            withAnimation(MZAnimation.bouncy.delay(1.4)) { buttonRevealed = true }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                HapticManager.shared.trigger(.medium)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: MZSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 32)

            Text(text)
                .font(MZTypography.bodyLarge)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}
```

---

## 5. Dramatic Moments

### 5.1 Splash Screen

```swift
struct SplashScreen: View {
    @State private var moonRevealed = false
    @State private var starsVisible = false
    @State private var titleRevealed = false

    var body: some View {
        ZStack {
            // Animated mesh gradient (iOS 18+) or fallback
            AnimatedGradientBackground()

            // Floating stars
            ParticleStarsView()
                .opacity(starsVisible ? 1 : 0)

            VStack(spacing: MZSpacing.lg) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 100))
                    .symbolEffect(.breathe.pulse.byLayer, options: .repeating)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.white, Color(hex: "#FFD700")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: 30)
                    .scaleEffect(moonRevealed ? 1.0 : 0.3)
                    .opacity(moonRevealed ? 1.0 : 0.0)

                Text("ميزان")
                    .font(MZTypography.displayLarge)
                    .foregroundColor(.white)
                    .opacity(titleRevealed ? 1 : 0)
                    .blur(radius: titleRevealed ? 0 : 10)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) { starsVisible = true }
            withAnimation(MZAnimation.dramatic.delay(0.4)) { moonRevealed = true }
            withAnimation(MZAnimation.gentle.delay(0.7)) { titleRevealed = true }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                HapticManager.shared.trigger(.medium)
            }
        }
    }
}
```

### 5.2 Task Completion Celebration

```swift
struct TaskCompletionCelebration: View {
    @Binding var isCompleting: Bool
    let taskColor: Color

    @State private var ringProgress: CGFloat = 0
    @State private var checkScale: CGFloat = 0
    @State private var glowIntensity: CGFloat = 0
    @State private var confettiTrigger = 0

    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(Color.green.opacity(0.2))
                .scaleEffect(1 + glowIntensity * 0.3)
                .blur(radius: 10 * glowIntensity)

            // Ring
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 32, height: 32)

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.green)
                .scaleEffect(checkScale)

            // Confetti
            ConfettiView(trigger: $confettiTrigger, colors: [.green, .mint, taskColor])
        }
        .onChange(of: isCompleting) { _, completing in
            if completing {
                withAnimation(MZAnimation.snappy) { ringProgress = 1.0 }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(MZAnimation.bouncy) { checkScale = 1.0 }
                    HapticManager.shared.trigger(.success)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.3)) { glowIntensity = 1.0 }
                    confettiTrigger += 1
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.5)) { glowIntensity = 0 }
                }
            }
        }
    }
}
```

### 5.3 Theme Switch Animation

```swift
struct ThemeSwitchOverlay: View {
    @Binding var isAnimating: Bool
    let toTheme: MZTheme

    @State private var waveProgress: CGFloat = 0

    var body: some View {
        if isAnimating {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)

                GeometryReader { geo in
                    let maxRadius = sqrt(pow(geo.size.width, 2) + pow(geo.size.height, 2))

                    Circle()
                        .fill(Color(hex: toTheme.colors.primary))
                        .frame(width: maxRadius * 2 * waveProgress, height: maxRadius * 2 * waveProgress)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .blur(radius: 30 * (1 - waveProgress))
                }

                if waveProgress > 0.5 {
                    Text(toTheme.nameArabic)
                        .font(MZTypography.headlineLarge)
                        .foregroundColor(.white)
                        .opacity(Double((waveProgress - 0.5) * 2))
                }
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(MZAnimation.breathe) { waveProgress = 1.0 }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    HapticManager.shared.trigger(.heavy)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.3)) { isAnimating = false }
                }
            }
        }
    }
}
```

### 5.4 First Prayer Celebration

```swift
struct FirstPrayerCelebration: View {
    @Binding var isShowing: Bool
    let prayerName: String

    @State private var starBurst = false
    @State private var textScale: CGFloat = 0.5

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            // Star burst
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: starBurst ? cos(Double(i) * 0.314) * 150 : 0,
                        y: starBurst ? sin(Double(i) * 0.314) * 150 : 0
                    )
                    .opacity(starBurst ? 0 : 1)
            }

            VStack(spacing: MZSpacing.lg) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce, value: isShowing)

                Text("مبارك!")
                    .font(MZTypography.headlineLarge)
                    .foregroundColor(.white)

                Text("أتممت صلاة \(prayerName)")
                    .font(MZTypography.bodyLarge)
                    .foregroundColor(.white.opacity(0.9))
            }
            .scaleEffect(textScale)
        }
        .onAppear {
            withAnimation(MZAnimation.bouncy) { textScale = 1.0 }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 1.0)) { starBurst = true }
                HapticManager.shared.trigger(.success)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { isShowing = false }
            }
        }
    }
}
```

### 5.5 End of Day Summary

```swift
struct EndOfDaySummary: View {
    @Binding var isPresented: Bool
    let prayersCompleted: Int
    let totalPrayers: Int
    let tasksCompleted: Int
    let totalTasks: Int

    @State private var chartAnimated = false

    var body: some View {
        VStack(spacing: MZSpacing.xl) {
            Text("ملخص اليوم")
                .font(MZTypography.headlineMedium)

            // Prayer ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 150, height: 150)

                Circle()
                    .trim(from: 0, to: chartAnimated ? CGFloat(prayersCompleted) / CGFloat(totalPrayers) : 0)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))

                VStack {
                    Text("\(prayersCompleted)/\(totalPrayers)")
                        .font(MZTypography.headlineLarge)
                    Text("صلوات")
                        .font(MZTypography.labelMedium)
                        .foregroundColor(.secondary)
                }
            }

            // Tasks stat
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                Text("\(tasksCompleted)/\(totalTasks) مهام")
                    .font(MZTypography.bodyLarge)
            }

            // Motivational
            Text(prayersCompleted == totalPrayers ? "ماشاء الله! يوم رائع" : "غداً يوم جديد")
                .font(MZTypography.bodyMedium)
                .foregroundColor(.secondary)

            Button { isPresented = false } label: {
                Text("إغلاق")
                    .font(MZTypography.titleSmall)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MZSpacing.md)
                    .background(Capsule().fill(Color.accentColor))
            }
            .padding(.horizontal, MZSpacing.xl)
        }
        .padding(MZSpacing.xl)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                chartAnimated = true
            }
        }
    }
}
```

---

## 6. iOS-Native Effects

### 6.1 SF Symbol Animations

```swift
// Bounce
.symbolEffect(.bounce, value: trigger)

// Pulse
.symbolEffect(.pulse, options: .repeating)

// Breathe
.symbolEffect(.breathe.pulse.byLayer)

// Variable color
.symbolEffect(.variableColor.iterative.reversing)
```

### 6.2 Sensory Feedback

```swift
.sensoryFeedback(.impact(weight: .heavy), trigger: value)
.sensoryFeedback(.selection, trigger: selectedItem)
.sensoryFeedback(.success, trigger: isComplete)
```

### 6.3 Materials

```swift
.background(.ultraThinMaterial)
.background(.regularMaterial)
.background(.thickMaterial)
```

### 6.4 Custom Transitions

```swift
extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    static var cardLift: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .opacity
        )
    }
}
```

---

## 7. Haptic System

```swift
class HapticManager {
    static let shared = HapticManager()

    func trigger(_ type: HapticType) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        switch type {
        case .light: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy: UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error: UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection: UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}

enum HapticType {
    case light, medium, heavy
    case success, warning, error
    case selection
}
```

---

## 8. Button Styles

```swift
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(MZAnimation.stiff, value: configuration.isPressed)
    }
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(MZAnimation.bouncy, value: configuration.isPressed)
    }
}
```

---

## 9. Performance Guidelines

1. **Replace Form with ScrollView + VStack** for better performance
2. **Use LazyVStack** for lists
3. **Canvas for particles** instead of multiple Views
4. **TimelineView** for continuous animations (battery efficient)
5. **Respect reduce motion** accessibility setting
6. **Clean up timers** in onDisappear

---

## 10. Implementation Checklist

### Foundation
- [ ] Create DesignSystem folder structure
- [ ] Implement token files
- [ ] Create base components
- [ ] Extend HapticManager

### Screen Redesigns
- [ ] AddTaskSheet (two-tier, ScrollView)
- [ ] TimelineView (components, atmosphere)
- [ ] InboxView (cards, empty state)
- [ ] SettingsView (sections, toggles)
- [ ] OnboardingView (story-driven)

### Dramatic Moments
- [ ] Splash screen
- [ ] Prayer atmospheric effects
- [ ] Task completion celebration
- [ ] Theme switch animation
- [ ] First prayer celebration
- [ ] End of day summary
- [ ] Delightful empty states

### Quality
- [ ] 60fps on iPhone 12+
- [ ] Reduce motion support
- [ ] RTL verification
- [ ] All device sizes
