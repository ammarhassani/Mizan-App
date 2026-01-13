# Mizan UI Design System

## Overview

Mizan is an Islamic daily planner app that seamlessly integrates prayer times with task management. This design system draws inspiration from successful planner apps like Structured while incorporating Islamic design elements and ensuring excellent readability for Arabic text.

## Design Philosophy

- **Simplicity & Clarity**: Clean, minimal interface that reduces cognitive load
- **Cultural Authenticity**: Incorporates Islamic design elements thoughtfully
- **Accessibility**: Excellent readability for both Arabic and English text
- **Responsive**: Fluid interactions with meaningful feedback
- **Spiritual Integration**: Prayer times naturally integrated into daily planning

---

## 1. Component Library

### 1.1 Core Components

#### Primary Button
```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(22)
                .shadow(
                    color: themeManager.primaryColor.opacity(0.4),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .buttonStyle(DramaticButtonStyle())
    }
}
```

#### Secondary Button
```swift
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(22)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
```

#### Floating Action Button (FAB)
```swift
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(themeManager.primaryColor)
                        .shadow(
                            color: themeManager.primaryColor.opacity(0.4),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                )
        }
        .buttonStyle(BouncyButtonStyle())
    }
}
```

#### Task Card
```swift
struct TaskCard: View {
    let task: Task
    let onTap: () -> Void
    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -200
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Category indicator with glow effect
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: task.colorHex), Color(hex: task.colorHex).opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 6, height: 44)
                    .shadow(
                        color: Color(hex: task.colorHex).opacity(0.6),
                        radius: 12,
                        x: 0,
                        y: 0
                    )
                
                // Pulsing glow
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: task.colorHex).opacity(0.3))
                    .frame(width: 14, height: 44)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .opacity(isPressed ? 0.8 : 0.6)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPressed)
            }
            
            // Task content with theme-aware styling
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.textPrimaryColor)
                    .lineLimit(2)
                    .shadow(color: themeManager.textPrimaryColor.opacity(0.3), radius: 2, x: 0, y: 1)
                
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.primaryColor)
                    
                    Text("\(task.duration) د")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
                
                Spacer()
                
                // Floating action indicator
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.primaryColor)
                    .offset(x: isPressed ? 4 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPressed)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [themeManager.primaryColor.opacity(0.3), themeManager.primaryColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: themeManager.primaryColor.opacity(0.2),
                    radius: isPressed ? 16 : 8,
                    x: 0,
                    y: isPressed ? 8 : 4
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .rotation3DEffect(.degrees(isPressed ? 2 : 0), anchor: .center, perspective: 0.8)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isPressed = false
                }
                onTap()
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).delay(0.5)) {
                shimmerOffset = 200
            }
        }
    }
}
```

#### Prayer Block
```swift
struct PrayerBlock: View {
    let prayer: PrayerTime
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: prayer.colorHex),
                    Color(hex: prayer.colorHex).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(themeManager.cornerRadius(.medium))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: prayer.prayerType.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Text(prayer.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if prayer.isJummah {
                        Text("جمعة")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(6)
                    }
                }
                
                Text(prayer.adhanTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("\(prayer.duration) دقيقة")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            .padding(12)
        }
    }
}
```

### 1.2 Input Components

#### Custom TextField
```swift
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.textPrimaryColor)
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 17))
                    .foregroundColor(themeManager.textPrimaryColor)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(16)
            .background(themeManager.surfaceSecondaryColor)
            .cornerRadius(themeManager.cornerRadius(.medium))
        }
    }
}
```

#### Duration Picker
```swift
struct DurationPicker: View {
    @Binding var duration: Int
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("المدة")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.textPrimaryColor)
            
            HStack {
                Text("\(duration) دقيقة")
                    .font(.system(size: 17))
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Spacer()
                
                Stepper("", value: $duration, in: 5...240, step: 5)
                    .labelsHidden()
            }
            .padding(16)
            .background(themeManager.surfaceSecondaryColor)
            .cornerRadius(themeManager.cornerRadius(.medium))
        }
    }
}
```

---

## 2. Layout Patterns

### 2.1 Timeline Layout

The timeline is the core of Mizan, displaying a 24-hour view with integrated prayers and tasks.

#### Key Principles:
- **Vertical Scrolling**: Natural for time-based content
- **15-minute Grid**: Fine-grained scheduling precision
- **Visual Hierarchy**: Prayers prominently displayed
- **Current Time Indicator**: Always visible red line
- **Smart Bounds**: Timeline adjusts based on first/last prayer

#### Implementation Pattern:
```swift
struct TimelineLayout: View {
    let hourHeight: CGFloat = 60
    let gridSpacing: CGFloat = 15 // 15 minutes
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    // Background grid
                    hourGrid
                    
                    // Timeline items
                    timelineItemsOverlay
                    
                    // Current time indicator
                    if Calendar.current.isDateInToday(selectedDate) {
                        currentTimeIndicator
                    }
                }
                .padding(.leading, 60) // Space for time labels
            }
        }
    }
}
```

### 2.2 Inbox Layout

The inbox manages unscheduled tasks with a clean, actionable interface.

#### Key Principles:
- **Card-based Design**: Each task is a distinct card
- **Swipe Actions**: Quick access to common actions
- **Floating Action Button**: Always present for adding tasks
- **Empty States**: Helpful guidance when no tasks exist
- **Progressive Disclosure**: Completed tasks hidden by default

#### Implementation Pattern:
```swift
struct InboxLayout: View {
    var body: some View {
        ZStack {
            if inboxTasks.isEmpty && !showCompletedTasks {
                emptyStateView
            } else {
                taskListView
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(icon: "plus", action: addTask)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
        }
    }
}
```

### 2.3 Settings Layout

Settings use a grouped list pattern with clear sections and visual hierarchy.

#### Key Principles:
- **Grouped Sections**: Related settings grouped together
- **Navigation Links**: Drills down to detailed settings
- **Toggle Switches**: Binary settings use toggles
- **Visual Feedback**: Theme changes preview immediately
- **RTL Support**: Proper layout for Arabic text

#### Implementation Pattern:
```swift
struct SettingsLayout: View {
    var body: some View {
        NavigationView {
            Form {
                Section("المظهر") {
                    ThemeSelectorRow()
                    LanguageSelectorRow()
                }
                
                Section("الإشعارات") {
                    NotificationToggleRow()
                    PrayerAlertRow()
                }
                
                Section("الصلاة") {
                    PrayerCalculationRow()
                    LocationRow()
                }
            }
            .navigationTitle("الإعدادات")
        }
    }
}
```

---

## 3. Color Schemes

### 3.1 Theme System

Mizan includes 5 carefully crafted themes, each with distinct personalities while maintaining readability and cultural appropriateness.

### 3.2 Noor (Light Theme)

The default light theme with a clean, minimalist appearance matching Structured.

```swift
struct NoorTheme: Theme {
    let colors = ColorPalette(
        background: "#FFFFFF",
        surface: "#FFFFFF",
        surfaceSecondary: "#F8F8F8",
        primary: "#007AFF",
        primaryLight: "#4D94FF",
        primaryDark: "#0051CC",
        secondary: "#5856D",
        accent: "#FF9500",
        textPrimary: "#000000",
        textSecondary: "#8E8E93",
        textTertiary: "#C7C7CC",
        prayerGradientStart: "#007AFF",
        prayerGradientEnd: "#4D94FF",
        success: "#34C759",
        warning: "#FF9500",
        error: "#FF3B30",
        info: "#007AFF",
        divider: "#E5E5EA"
    )
    
    let taskColors = TaskColors(
        work: "#007AFF",
        personal: "#FF9500",
        study: "#5856D",
        health: "#34C759",
        social: "#FF3B30",
        worship: "#AF52DE"
    )
}
```

### 3.3 Layl (Dark Theme)

A clean dark theme matching Structured's dark mode.

```swift
struct LaylTheme: Theme {
    let colors = ColorPalette(
        background: "#000000",
        surface: "#1C1C1E",
        surfaceSecondary: "#2C2C2E",
        primary: "#007AFF",
        primaryLight: "#4D94FF",
        primaryDark: "#0051CC",
        secondary: "#5856D6",
        accent: "#FF9500",
        textPrimary: "#FFFFFF",
        textSecondary: "#8E8E93",
        textTertiary: "#48484A",
        prayerGradientStart: "#007AFF",
        prayerGradientEnd: "#4D94FF",
        success: "#34C759",
        warning: "#FF9500",
        error: "#FF3B30",
        info: "#007AFF",
        divider: "#38383A"
    )
    
    let useGlowInsteadOfShadow = true
}
```

### 3.4 Fajr (Dawn Theme)

A soft, gradient theme inspired by the colors of dawn.

```swift
struct FajrTheme: Theme {
    let colors = ColorPalette(
        background: "#E8DFF5",
        surface: "#FFFFFF",
        surfaceSecondary: "#FAF5FF",
        primary: "#6C63FF",
        primaryLight: "#8B7FFF",
        primaryDark: "#5851DB",
        secondary: "#E879F9",
        accent: "#FCA5A5",
        textPrimary: "#2D2A4A",
        textSecondary: "#6B5B95",
        textTertiary: "#9B8FB6",
        prayerGradientStart: "#6C63FF",
        prayerGradientEnd: "#E879F9",
        success: "#A78BFA",
        warning: "#FBBF24",
        error: "#F87171",
        info: "#60A5FA",
        divider: "#E9D5FF"
    )
    
    let backgroundGradient = ["#E8DFF5", "#FCE1E4", "#FCF4DD"]
    let useGradientBackground = true
}
```

### 3.5 Sahara (Desert Theme)

Warm, earthy tones inspired by desert landscapes.

```swift
struct SaharaTheme: Theme {
    let colors = ColorPalette(
        background: "#E9D5C1",
        surface: "#F5EAD8",
        surfaceSecondary: "#EFE2CF",
        primary: "#D4734C",
        primaryLight: "#E89668",
        primaryDark: "#C45A30",
        secondary: "#8B6F47",
        accent: "#C88F5C",
        textPrimary: "#3D2817",
        textSecondary: "#705437",
        textTertiary: "#9A7B5B",
        prayerGradientStart: "#D4734C",
        prayerGradientEnd: "#C88F5C",
        success: "#8B6F47",
        warning: "#E89668",
        error: "#C45A30",
        info: "#8B6F47",
        divider: "#D4B69C"
    )
    
    let specialEffects = SpecialEffects(
        arabesquePattern: true,
        patternOpacity: 0.05,
        hardShadows: true
    )
}
```

### 3.6 Ramadan (Special Theme)

A festive theme that automatically activates during Ramadan.

```swift
struct RamadanTheme: Theme {
    let colors = ColorPalette(
        background: "#1E1B4B",
        surface: "#312E81",
        surfaceSecondary: "#3730A3",
        primary: "#FFD700",
        primaryLight: "#FDE047",
        primaryDark: "#FFA500",
        secondary: "#A78BFA",
        accent: "#F472B6",
        textPrimary: "#FFFFFF",
        textSecondary: "#E0E7FF",
        textTertiary: "#C7D2FE",
        prayerGradientStart: "#FFD700",
        prayerGradientEnd: "#FFA500",
        success: "#A78BFA",
        warning: "#FDE047",
        error: "#F87171",
        info: "#60A5FA",
        divider: "#4C1D95"
    )
    
    let specialEffects = SpecialEffects(
        crescentMoonIcon: true,
        festiveAnimations: true,
        starParticles: true,
        useGlow: true
    )
    
    let autoActivateDuringRamadan = true
}
```

---

## 4. Typography System

### 4.1 Font Hierarchy

Mizan uses a dual typography system matching Structured's clean font hierarchy.

#### Arabic Fonts
- **Display Headers**: SF Arabic Rounded Bold
- **Section Headers**: SF Arabic Rounded Semibold
- **Body Text**: SF Arabic Rounded Medium
- **Captions**: SF Arabic Rounded Regular

#### English Fonts
- **Display Headers**: SF Pro Rounded Bold
- **Section Headers**: SF Pro Rounded Semibold
- **Body Text**: SF Pro Rounded Medium
- **Captions**: SF Pro Rounded Regular

### 4.2 Typography Scale

```swift
struct TypographyScale {
    // Display
    let display1 = Font.system(size: 32, weight: .heavy)
    let display2 = Font.system(size: 28, weight: .bold)
    let display3 = Font.system(size: 24, weight: .semibold)
    
    // Headers
    let header1 = Font.system(size: 20, weight: .semibold)
    let header2 = Font.system(size: 18, weight: .semibold)
    let header3 = Font.system(size: 16, weight: .medium)
    
    // Body
    let body1 = Font.system(size: 17, weight: .regular)
    let body2 = Font.system(size: 15, weight: .regular)
    let body3 = Font.system(size: 14, weight: .regular)
    
    // Captions
    let caption1 = Font.system(size: 12, weight: .medium)
    let caption2 = Font.system(size: 11, weight: .regular)
}
```

### 4.3 Arabic Text Optimization

Special considerations for Arabic text:

```swift
extension View {
    func arabicOptimized() -> some View {
        self
            .environment(\.layoutDirection, .rightToLeft)
            .font(.custom("SF Arabic Text", size: 17))
            .lineSpacing(2)
            .tracking(0.5)
    }
}

struct ArabicText: View {
    let text: String
    let style: FontStyle
    
    var body: some View {
        Text(text)
            .font(arabicFont(for: style))
            .environment(\.layoutDirection, .rightToLeft)
    }
    
    private func arabicFont(for style: FontStyle) -> Font {
        switch style {
        case .header:
            return .custom("SF Arabic Display", size: 20, weight: .semibold)
        case .body:
            return .custom("SF Arabic Text", size: 17, weight: .medium)
        case .caption:
            return .custom("SF Arabic Text", size: 14, weight: .regular)
        }
    }
}
```

---

## 5. Iconography and Visual Elements

### 5.1 Icon System

Mizan uses SF Symbols with custom Islamic-themed icons for religious elements.

#### Core Icons
- **Task Categories**: Each category has a distinct icon
- **Prayer Times**: Custom icons for each prayer
- **Navigation**: Standard iOS navigation icons
- **Actions**: Clear, universally understood action icons

#### Prayer Icons
```swift
extension PrayerType {
    var icon: String {
        switch self {
        case .fajr: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.and.horizon.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.fill"
        }
    }
    
    var arabicIcon: String {
        switch self {
        case .fajr: return "fajr.icon"
        case .dhuhr: return "dhuhr.icon"
        case .asr: return "asr.icon"
        case .maghrib: return "maghrib.icon"
        case .isha: return "isha.icon"
        }
    }
}
```

### 5.2 Islamic Design Elements

#### Geometric Patterns
Subtle arabesque patterns in the Sahara theme:
```swift
struct ArabesquePattern: View {
    let opacity: Double
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Draw geometric pattern
                drawArabesque(in: CGRect(origin: .zero, size: geometry.size), path: &path)
            }
            .fill(Color.primary.opacity(opacity))
        }
    }
}
```

#### Decorative Elements
- **Crescent Moon**: Used in Ramadan theme
- **Star Patterns**: Subtle background elements
- **Calligraphy**: Special headers for Islamic content
- **Geometric Borders**: Frame important sections

---

## 6. Animation Specifications

### 6.1 Spring Physics System

Mizan uses a comprehensive spring animation system for natural, responsive interactions.

#### Spring Definitions
```swift
struct AnimationSprings {
    // Gentle: Smooth, calm animations
    static let gentle = Spring(
        response: 0.4,
        dampingFraction: 0.8,
        blendDuration: 0.3
    )
    
    // Bouncy: Playful with overshoot
    static let bouncy = Spring(
        response: 0.35,
        dampingFraction: 0.7,
        blendDuration: 0.2
    )
    
    // Snappy: Quick, precise feedback
    static let snappy = Spring(
        response: 0.25,
        dampingFraction: 0.85,
        blendDuration: 0.15
    )
    
    // Soft: Very gentle for subtle changes
    static let soft = Spring(
        response: 0.5,
        dampingFraction: 0.9,
        blendDuration: 0.35
    )
    
    // Stiff: Tight, fast animations
    static let stiff = Spring(
        response: 0.2,
        dampingFraction: 0.92,
        blendDuration: 0.1
    )
}
```

### 6.2 Signature Animations

#### App Launch Animation
```swift
struct AppLaunchAnimation: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // App content
            ContentView()
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
```

#### Task Creation Animation
```swift
struct TaskCreationAnimation: View {
    @State private var showSheet = false
    
    var body: some View {
        Button("Add Task") {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showSheet = true
            }
        }
        .sheet(isPresented: $showSheet) {
            AddTaskSheet()
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
        }
    }
}
```

#### Drag and Drop Animations
```swift
struct DragAnimation: ViewModifier {
    let isDragging: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .shadow(
                color: isDragging ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                radius: isDragging ? 16 : 4,
                x: 0,
                y: isDragging ? 8 : 2
            )
            .rotationEffect(.degrees(isDragging ? 2 : 0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
    }
}
```

#### Prayer Time Alert Animation
```swift
struct PrayerAlertAnimation: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        PrayerBlock(prayer: prayer)
            .scaleEffect(pulseScale)
            .shadow(
                color: Color(hex: prayer.colorHex).opacity(glowOpacity),
                radius: 20,
                x: 0,
                y: 0
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                    glowOpacity = 0.8
                }
            }
    }
}
```

### 6.3 Micro-interactions

#### Button Press Animation
```swift
struct ButtonPressAnimation: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
    }
}
```

#### Toggle Switch Animation
```swift
struct ToggleSwitchAnimation: View {
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(isOn ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 52, height: 32)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .offset(x: isOn ? 12 : -12)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isOn.toggle()
                    }
                }
        }
    }
}
```

---

## 7. Interaction Patterns

### 7.1 Drag and Drop System

Mizan implements a sophisticated drag and drop system for scheduling tasks.

#### Drag States
```swift
enum DragState {
    case idle
    case pressing
    case dragging(translation: CGSize)
    case overTarget(isValid: Bool)
}
```

#### Draggable Task Implementation
```swift
struct DraggableTask: View {
    let task: Task
    @State private var dragState = DragState.idle
    @State private var location: CGPoint = .zero
    
    var body: some View {
        TaskCard(task: task)
            .offset(dragState == .dragging(let translation) ? translation : .zero)
            .scaleEffect(dragState == .dragging(_) ? 1.05 : 1.0)
            .shadow(
                color: dragState == .dragging(_) ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                radius: dragState == .dragging(_) ? 16 : 4,
                x: 0,
                y: dragState == .dragging(_) ? 8 : 2
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragState)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragState = .dragging(translation: value.translation)
                    }
                    .onEnded { value in
                        handleDrop(at: value.location)
                        dragState = .idle
                    }
            )
    }
}
```

#### Drop Target Implementation
```swift
struct DropTarget: View {
    let isValidDrop: Bool
    let onDrop: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Rectangle()
            .fill(isValidDrop ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
            .stroke(
                isValidDrop ? Color.green : Color.red,
                style: StrokeStyle(lineWidth: 2, dash: [5, 5])
            )
            .opacity(isHovered ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onDrop(of: [.text], isTargeted: { hovering in
                isHovered = hovering
                return true
            }) { providers in
                onDrop()
                return true
            }
    }
}
```

### 7.2 Swipe Actions

Tasks support swipe actions for quick operations:

```swift
struct SwipeableTask: View {
    let task: Task
    
    var body: some View {
        TaskCard(task: task)
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
    }
}
```

### 7.3 Haptic Feedback

Mizan uses haptic feedback to enhance interactions:

```swift
struct HapticManager {
    static let shared = HapticManager()
    
    func trigger(_ type: HapticType) {
        switch type {
        case .light:
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
        case .medium:
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
        case .heavy:
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            
        case .success:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            
        case .warning:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.warning)
            
        case .error:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.error)
        }
    }
}

enum HapticType {
    case light, medium, heavy
    case success, warning, error
}
```

---

## 8. RTL Layout Considerations

### 8.1 Layout Direction Handling

Mizan properly handles both LTR and RTL layouts based on language selection:

```swift
struct LocalizedView: View {
    @Environment(\.locale) var locale
    
    var body: some View {
        HStack {
            if locale.language.languageCode == .arabic {
                // RTL layout
                ArabicContent()
                Spacer()
                Icon()
            } else {
                // LTR layout
                Icon()
                Spacer()
                EnglishContent()
            }
        }
        .environment(\.layoutDirection, locale.language.languageCode == .arabic ? .rightToLeft : .leftToRight)
    }
}
```

### 8.2 Text Alignment

Dynamic text alignment based on language:

```swift
extension View {
    func localizedTextAlignment() -> some View {
        self.environment(\.locale) { locale in
            if locale.language.languageCode == .arabic {
                self.multilineTextAlignment(.trailing)
            } else {
                self.multilineTextAlignment(.leading)
            }
        }
    }
}
```

### 8.3 Navigation Patterns

RTL-aware navigation:

```swift
struct RTLNavigationView: View {
    @Environment(\.locale) var locale
    
    var body: some View {
        NavigationView {
            ContentView()
                .navigationTitle("Title")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: locale.language.languageCode == .arabic ? .navigationBarLeading : .navigationBarTrailing) {
                        Button("Action") {
                            // Action
                        }
                    }
                }
        }
        .environment(\.layoutDirection, locale.language.languageCode == .arabic ? .rightToLeft : .leftToRight)
    }
}
```

### 8.4 Icon Direction

Icons flip for RTL layout:

```swift
struct LocalizedIcon: View {
    let systemName: String
    
    @Environment(\.locale) var locale
    @Environment(\.layoutDirection) var layoutDirection
    
    var body: some View {
        Image(systemName: systemName)
            .scaleEffect(x: layoutDirection == .rightToLeft ? -1 : 1, y: 1, anchor: .center)
    }
}
```

---

## 9. Implementation Guidelines

### 9.1 Component Architecture

Mizan follows a hierarchical component architecture:

```
App
├── DesignSystem
│   ├── Components
│   │   ├── Buttons
│   │   ├── Cards
│   │   ├── Forms
│   │   └── Navigation
│   ├── Layouts
│   │   ├── Timeline
│   │   ├── Inbox
│   │   └── Settings
│   ├── Themes
│   │   ├── Noor
│   │   ├── Layl
│   │   ├── Fajr
│   │   ├── Sahara
│   │   └── Ramadan
│   └── Utilities
│       ├── Extensions
│       └── Helpers
└── Features
    ├── Timeline
    ├── TaskManagement
    ├── Prayer
    └── Settings
```

### 9.2 Theme Manager Implementation

```swift
class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = .noor
    
    func setTheme(_ theme: Theme) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentTheme = theme
        }
        HapticManager.shared.trigger(.medium)
    }
    
    var backgroundColor: Color {
        currentTheme.colors.background
    }
    
    var surfaceColor: Color {
        currentTheme.colors.surface
    }
    
    var primaryColor: Color {
        currentTheme.colors.primary
    }
    
    var textPrimaryColor: Color {
        currentTheme.colors.textPrimary
    }
    
    var textSecondaryColor: Color {
        currentTheme.colors.textSecondary
    }
    
    func cornerRadius(_ size: CornerRadiusSize) -> CGFloat {
        currentTheme.cornerRadius[size]
    }
    
    func shadow(_ type: ShadowType) -> Shadow {
        currentTheme.shadows[type]
    }
}
```

### 9.3 Accessibility Considerations

Mizan is designed with accessibility in mind:

```swift
struct AccessibleButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to activate")
        .accessibilityAddTraits(.isButton)
    }
}
```

### 9.4 Performance Optimizations

Key performance considerations:

1. **Lazy Loading**: Timeline uses lazy loading for better performance
2. **Image Caching**: Icons and images are cached
3. **Animation Optimization**: Animations use hardware acceleration
4. **Memory Management**: Proper cleanup of resources
5. **Efficient Updates**: Only update changed UI elements

```swift
struct OptimizedTimeline: View {
    @State private var visibleHours: Set<Int> = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    TimelineHourRow(hour: hour)
                        .onAppear {
                            visibleHours.insert(hour)
                        }
                        .onDisappear {
                            visibleHours.remove(hour)
                        }
                }
            }
        }
    }
}
```

---

## 10. Conclusion

This design system provides a comprehensive foundation for Mizan's UI, ensuring:

1. **Consistency**: Unified visual language across all features
2. **Flexibility**: Adaptable to different themes and languages
3. **Accessibility**: Usable by all users
4. **Performance**: Smooth animations and interactions
5. **Cultural Authenticity**: Respectful incorporation of Islamic design elements
6. **Maintainability**: Clear structure for future development

The system draws inspiration from successful planner apps while maintaining its unique Islamic identity and focus on prayer integration. The careful attention to typography, color, and interaction patterns creates a delightful user experience that helps users balance their spiritual and daily responsibilities.