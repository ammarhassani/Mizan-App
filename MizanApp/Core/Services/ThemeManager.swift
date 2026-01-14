//
//  ThemeManager.swift
//  Mizan
//
//  Manages app themes and theme switching
//

import SwiftUI
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentTheme: Theme
    @Published var isDarkMode: Bool = false
    @Published var isRamadan: Bool = false

    // MARK: - Private Properties
    private let config: ThemeConfiguration
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        self.config = ConfigurationManager.shared.themeConfig

        // Load saved theme or use default
        let savedThemeId = UserDefaults.standard.string(forKey: "selectedTheme") ?? "noor"
        self.currentTheme = config.themes.first { $0.id == savedThemeId } ?? config.themes[0]

        // Detect dark mode
        self.isDarkMode = currentTheme.id == "layl" || currentTheme.id == "ramadan"
    }

    // MARK: - Public Methods

    /// Switch to a different theme
    func switchTheme(to themeId: String, userSettings: UserSettings? = nil) {
        guard let theme = config.themes.first(where: { $0.id == themeId }) else {
            print("❌ Theme not found: \(themeId)")
            return
        }

        // Check Pro requirement
        if theme.isPro {
            guard let settings = userSettings, settings.isProActive() else {
                print("⚠️ Theme '\(themeId)' requires Pro subscription")
                return
            }
        }

        // Animate theme change
        withAnimation(.easeInOut(duration: 0.5)) {
            currentTheme = theme
            isDarkMode = theme.id == "layl" || theme.id == "ramadan"
        }

        // Save preference
        UserDefaults.standard.set(themeId, forKey: "selectedTheme")

        // Update user settings if provided
        userSettings?.updateTheme(themeId)

        // Trigger haptic feedback
        let _ = HapticManager.shared
        // Skip haptic for now to avoid conflict

        print("✨ Switched to theme: \(theme.name)")
    }

    /// Get all available themes
    func allThemes() -> [Theme] {
        return config.themes
    }

    /// Get free themes only
    func freeThemes() -> [Theme] {
        return config.themes.filter { !$0.isPro }
    }

    /// Get Pro themes only
    func proThemes() -> [Theme] {
        return config.themes.filter { $0.isPro }
    }

    /// Check if Ramadan theme should auto-activate
    func checkRamadanAutoActivation(hijriMonth: String) {
        // Check if current month is Ramadan (month 9 in Hijri calendar)
        isRamadan = hijriMonth.contains("Ramadan") || hijriMonth.contains("رمضان") || hijriMonth.contains("09")

        if isRamadan {
            if let ramadanTheme = config.themes.first(where: { $0.autoActivateDuringRamadan == true }) {
                print("🌙 Ramadan detected - auto-activating Ramadan theme")
                switchTheme(to: ramadanTheme.id)
            }
        }
    }

    /// Get color scheme for SwiftUI environment
    var colorScheme: ColorScheme? {
        if isDarkMode {
            return .dark
        } else if currentTheme.id == "noor" || currentTheme.id == "sahara" {
            return .light
        }
        return nil // Auto
    }
}

// MARK: - Theme Access Helpers

extension ThemeManager {
    /// Get primary color
    var primaryColor: Color {
        Color(hex: currentTheme.colors.primary)
    }

    /// Get background color
    var backgroundColor: Color {
        if let gradient = currentTheme.colors.backgroundGradient, !gradient.isEmpty {
            return Color(hex: gradient[0])
        }
        return Color(hex: currentTheme.colors.background)
    }

    /// Get surface color
    var surfaceColor: Color {
        Color(hex: currentTheme.colors.surface ?? currentTheme.colors.background)
    }

    /// Get secondary surface color (from theme config)
    var surfaceSecondaryColor: Color {
        if let surfaceSecondary = currentTheme.colors.surfaceSecondary {
            return Color(hex: surfaceSecondary)
        }
        return surfaceColor.opacity(0.9)
    }

    /// Get tertiary text color (from theme config)
    var textTertiaryColor: Color {
        if let textTertiary = currentTheme.colors.textTertiary {
            return Color(hex: textTertiary)
        }
        return textSecondaryColor.opacity(0.7)
    }

    /// Get text color for primary background (WCAG2 compliant)
    var textOnPrimaryColor: Color {
        if let textOnPrimary = currentTheme.colors.textOnPrimary {
            return Color(hex: textOnPrimary)
        }
        // Default to white for most themes, but dark for light primary colors
        return isDarkMode ? Color(hex: "#000000") : Color(hex: "#FFFFFF")
    }

    /// Get placeholder text color
    var placeholderTextColor: Color {
        if let placeholder = currentTheme.colors.placeholderText {
            return Color(hex: placeholder)
        }
        return textSecondaryColor.opacity(0.6)
    }

    /// Get success color
    var successColor: Color {
        if let success = currentTheme.colors.success {
            return Color(hex: success)
        }
        return Color(hex: "#10B981")
    }

    /// Get error color
    var errorColor: Color {
        if let error = currentTheme.colors.error {
            return Color(hex: error)
        }
        return Color(hex: "#EF4444")
    }

    /// Get warning color
    var warningColor: Color {
        if let warning = currentTheme.colors.warning {
            return Color(hex: warning)
        }
        return Color(hex: "#F59E0B")
    }

    /// Get urgency color based on level
    func urgencyColor(_ level: UrgencyLevel) -> Color {
        switch level {
        case .low:
            if let color = currentTheme.colors.urgencyLow {
                return Color(hex: color)
            }
            return textTertiaryColor
        case .medium:
            if let color = currentTheme.colors.urgencyMedium {
                return Color(hex: color)
            }
            return warningColor
        case .high:
            if let color = currentTheme.colors.urgencyHigh {
                return Color(hex: color)
            }
            return Color(hex: "#F97316")
        case .critical:
            if let color = currentTheme.colors.urgencyCritical {
                return Color(hex: color)
            }
            return errorColor
        }
    }

    /// Get text primary color
    var textPrimaryColor: Color {
        Color(hex: currentTheme.colors.textPrimary)
    }

    /// Get text secondary color
    var textSecondaryColor: Color {
        Color(hex: currentTheme.colors.textSecondary ?? currentTheme.colors.textPrimary)
    }

    /// Get prayer gradient colors
    var prayerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: currentTheme.colors.prayerGradientStart),
                Color(hex: currentTheme.colors.prayerGradientEnd)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Get category color
    func categoryColor(_ category: TaskCategory) -> Color {
        if let taskColors = currentTheme.colors.taskColors,
           let colorHex = taskColors[category.rawValue] {
            return Color(hex: colorHex)
        }
        return Color(hex: category.defaultColorHex)
    }

    /// Get corner radius
    func cornerRadius(_ size: CornerRadiusSize) -> CGFloat {
        guard let radiusConfig = currentTheme.cornerRadius else {
            return size.defaultValue
        }

        switch size {
        case .small: return radiusConfig.small
        case .medium: return radiusConfig.medium
        case .large: return radiusConfig.large
        case .extraLarge: return radiusConfig.extraLarge
        }
    }

    /// Get shadow configuration
    func shadow(_ type: ShadowType) -> ShadowConfiguration {
        guard let shadows = currentTheme.shadows else {
            return ShadowConfiguration.default
        }

        let shadowConfig: ShadowConfig
        switch type {
        case .card:
            shadowConfig = shadows.card
        case .elevated:
            shadowConfig = shadows.elevated ?? shadows.card
        case .floating:
            shadowConfig = shadows.floating ?? shadows.card
        }

        return ShadowConfiguration(
            color: Color(hex: shadowConfig.color),
            radius: shadowConfig.radius,
            x: shadowConfig.x,
            y: shadowConfig.y,
            useGlow: currentTheme.useGlowInsteadOfShadow ?? false
        )
    }
}

// MARK: - Supporting Types

enum CornerRadiusSize {
    case small, medium, large, extraLarge

    var defaultValue: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        case .extraLarge: return 24
        }
    }
}

enum UrgencyLevel {
    case low      // > 15 minutes
    case medium   // 5-15 minutes
    case high     // 1-5 minutes
    case critical // < 1 minute
}

enum ShadowType {
    case card, elevated, floating
}

struct ShadowConfiguration {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    let useGlow: Bool

    static let `default` = ShadowConfiguration(
        color: Color.black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 2,
        useGlow: false
    )
}

// MARK: - View Modifiers

struct ThemedCardModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        let shadow = themeManager.shadow(.card)

        content
            .background(themeManager.surfaceColor)
            .cornerRadius(themeManager.cornerRadius(.medium))
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

struct ThemedButtonModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    let style: ButtonStyle

    enum ButtonStyle {
        case primary, secondary, tertiary
    }

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(themeManager.cornerRadius(.medium))
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return themeManager.primaryColor
        case .secondary:
            return themeManager.surfaceColor
        case .tertiary:
            return Color.clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return themeManager.textOnPrimaryColor
        case .secondary:
            return themeManager.textPrimaryColor
        case .tertiary:
            return themeManager.primaryColor
        }
    }
}

extension View {
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }

    func themedButton(style: ThemedButtonModifier.ButtonStyle = .primary) -> some View {
        modifier(ThemedButtonModifier(style: style))
    }
}

// MARK: - Haptic Manager

enum HapticType {
    case light, medium, heavy
    case success, warning, error
    case selection
}

final class HapticManager {
    static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private var lastHapticTime: Date?
    private let minimumInterval: TimeInterval = 0.1 // 100ms debounce

    private init() {
        // Prepare generators
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
    }

    func trigger(_ type: HapticType) {
        // Debounce haptics
        if let lastTime = lastHapticTime, Date().timeIntervalSince(lastTime) < minimumInterval {
            return
        }

        lastHapticTime = Date()

        switch type {
        case .light:
            impactLight.impactOccurred()
            impactLight.prepare()
        case .medium:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        case .heavy:
            impactHeavy.impactOccurred()
            impactHeavy.prepare()
        case .success:
            notification.notificationOccurred(.success)
        case .warning:
            notification.notificationOccurred(.warning)
        case .error:
            notification.notificationOccurred(.error)
        case .selection:
            selection.selectionChanged()
        }
    }
}
