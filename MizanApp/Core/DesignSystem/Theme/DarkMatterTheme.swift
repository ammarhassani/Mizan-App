//
//  DarkMatterTheme.swift
//  Mizan
//
//  Single Dark Matter theme for Event Horizon cinematic UI.
//  Provides a static theme that uses CinematicColors, CinematicSpacing,
//  CinematicTypography, and CinematicAnimation tokens.
//
//  During migration, views can use DarkMatterTheme.shared directly
//  or continue using ThemeManager until fully migrated.
//

import SwiftUI
import Combine
import os.log
import UIKit

/// Dark Matter theme - single cinematic theme for Event Horizon
/// Static theme manager that provides all design tokens for the dark cinematic UI.
///
/// Usage:
/// ```swift
/// // Direct access
/// let color = DarkMatterTheme.shared.primaryColor
///
/// // Or inject as environment object
/// .environmentObject(DarkMatterTheme.shared)
/// ```
@MainActor
final class DarkMatterTheme: ObservableObject {
    // MARK: - Singleton

    static let shared = DarkMatterTheme()

    // MARK: - Published Properties

    /// Always dark mode for Dark Matter theme
    @Published private(set) var isDarkMode: Bool = true

    /// Ramadan detection (for seasonal events)
    @Published private(set) var isRamadan: Bool = false

    // MARK: - Core Colors

    /// Primary accent color - cyan
    var primaryColor: Color { CinematicColors.accentCyan }

    /// Main background - void black
    var backgroundColor: Color { CinematicColors.voidBlack }

    /// Elevated surface color
    var surfaceColor: Color { CinematicColors.surface }

    /// Secondary surface color
    var surfaceSecondaryColor: Color { CinematicColors.surfaceSecondary }

    /// Dark matter base color for fluid effects
    var darkMatterColor: Color { CinematicColors.darkMatter }

    // MARK: - Text Colors

    /// Primary text color
    var textPrimaryColor: Color { CinematicColors.textPrimary }

    /// Secondary text color
    var textSecondaryColor: Color { CinematicColors.textSecondary }

    /// Tertiary/disabled text color
    var textTertiaryColor: Color { CinematicColors.textTertiary }

    /// Text color for use on accent backgrounds
    var textOnPrimaryColor: Color { CinematicColors.textOnAccent }

    // MARK: - Semantic Colors

    /// Success state color
    var successColor: Color { CinematicColors.success }

    /// Error state color
    var errorColor: Color { CinematicColors.error }

    /// Warning state color
    var warningColor: Color { CinematicColors.warning }

    /// Info state color
    var infoColor: Color { CinematicColors.info }

    // MARK: - Additional Colors

    /// Divider color
    var dividerColor: Color { CinematicColors.textTertiary.opacity(0.3) }

    /// Disabled state color
    var disabledColor: Color { CinematicColors.textTertiary }

    /// Border color
    var borderColor: Color { CinematicColors.glassBorder.opacity(0.4) }

    /// Focused border color
    var focusedBorderColor: Color { CinematicColors.glassBorder }

    /// Prayer/spiritual gold accent
    var prayerGoldColor: Color { CinematicColors.prayerGold }

    /// Secondary magenta accent
    var accentMagentaColor: Color { CinematicColors.accentMagenta }

    // MARK: - Glass Material Colors

    /// Glass surface base color (use with low opacity)
    var glassBackground: Color { CinematicColors.glass.opacity(0.06) }

    /// Glass border glow color
    var glassBorder: Color { CinematicColors.glassBorder.opacity(0.4) }

    // MARK: - Initialization

    /// Internal initializer for backward compatibility with existing code using ThemeManager()
    /// Prefer using DarkMatterTheme.shared for new code
    init() {
        checkRamadan()
    }

    // MARK: - Category Colors

    /// Get color for a task category
    func categoryColor(_ category: TaskCategory) -> Color {
        switch category {
        case .work:
            return CinematicColors.categoryWork
        case .personal:
            return CinematicColors.categoryPersonal
        case .health:
            return CinematicColors.categoryHealth
        case .study:
            return CinematicColors.categoryLearning
        case .social:
            return CinematicColors.accentMagenta
        case .worship:
            return CinematicColors.categoryWorship
        }
    }

    // MARK: - Prayer Period Colors

    /// Get color for a prayer period
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
        case .isha, .tahajjud:
            return CinematicColors.periodIsha
        }
    }

    // MARK: - Gradients

    /// Get atmosphere gradient for a prayer period
    func atmosphereGradient(for period: PrayerPeriod) -> LinearGradient {
        let baseColor = prayerPeriodColor(period)
        return LinearGradient(
            colors: [baseColor, CinematicColors.voidBlack],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Prayer-themed gradient
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

    /// Primary accent gradient
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                CinematicColors.accentCyan,
                CinematicColors.accentCyan.opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Particle Colors

    /// Get particle color for atmospheric effects
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

    // MARK: - Private Methods

    private func checkRamadan() {
        let islamic = Calendar(identifier: .islamicUmmAlQura)
        let month = islamic.component(.month, from: Date())
        isRamadan = (month == 9)
    }

    // MARK: - Legacy ThemeManager Compatibility

    /// Additional color properties for backward compatibility

    /// Primary light color (lighter variant)
    var primaryLightColor: Color { primaryColor.opacity(0.8) }

    /// Primary dark color (darker variant)
    var primaryDarkColor: Color { primaryColor }

    /// Placeholder text color
    var placeholderTextColor: Color { textSecondaryColor.opacity(0.6) }

    /// Disabled background color
    var disabledBackgroundColor: Color { surfaceSecondaryColor.opacity(0.5) }

    /// Overlay color (for modal backgrounds)
    var overlayColor: Color { CinematicColors.voidBlack }

    /// Splash moon color
    var splashMoonColor: Color { warningColor }

    /// Splash text color
    var splashTextColor: Color { textOnPrimaryColor }

    /// Pressed state color
    var pressedColor: Color { primaryDarkColor }

    /// Splash gradient colors
    var splashGradientColors: [Color] {
        [primaryColor, primaryColor.opacity(0.8), primaryColor.opacity(0.6)]
    }

    /// Color scheme for SwiftUI environment
    var colorScheme: ColorScheme? { .dark }

    /// Get colors for a specific theme by ID (for icon previews and logo variants)
    /// Returns (background, primary, accent) colors tuple
    /// Since we now have a single Dark Matter theme, all theme IDs return the same colors
    func colorsForTheme(_ themeId: String) -> (background: Color, primary: Color, accent: Color)? {
        return (backgroundColor, primaryColor, accentMagentaColor)
    }

    // MARK: - Legacy Theme Switching (No-op)

    /// Check if Ramadan theme should auto-activate
    /// With single Dark Matter theme, this only updates the isRamadan flag
    func checkRamadanAutoActivation(hijriMonth: String) {
        let wasRamadan = isRamadan
        isRamadan = hijriMonth.contains("Ramadan") || hijriMonth.contains("رمضان") || hijriMonth.contains("09")

        if isRamadan && !wasRamadan {
            MizanLogger.shared.theme.info("Ramadan detected - Dark Matter theme active")
        }
    }

    /// Switch theme (no-op for single Dark Matter theme)
    /// Preserved for backward compatibility with existing code
    func switchTheme(to themeId: String, userSettings: UserSettings? = nil) {
        // Single theme - no switching needed
        // Just log the request for debugging
        MizanLogger.shared.theme.debug("Theme switch requested to '\(themeId)' - Dark Matter theme always active")
    }

    // MARK: - Legacy Corner Radius Compatibility

    /// Get corner radius using legacy CornerRadiusSize enum
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

    // MARK: - Legacy Shadow Compatibility

    /// Get shadow configuration using legacy ShadowType enum
    func shadow(_ type: ShadowType) -> ShadowConfiguration {
        switch type {
        case .card:
            return ShadowConfiguration(
                color: CinematicColors.accentCyan.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4,
                useGlow: true
            )
        case .elevated:
            return ShadowConfiguration(
                color: CinematicColors.accentCyan.opacity(0.15),
                radius: 16,
                x: 0,
                y: 8,
                useGlow: true
            )
        case .floating:
            return ShadowConfiguration(
                color: CinematicColors.accentCyan.opacity(0.2),
                radius: 24,
                x: 0,
                y: 12,
                useGlow: true
            )
        }
    }

    // MARK: - Legacy Glass Style Compatibility

    /// Get glass style values using legacy GlassStyle enum
    func glassStyle(_ style: GlassStyle) -> GlassStyleValues {
        switch style {
        case .subtle:
            return GlassStyleValues(
                blurRadius: 10,
                backgroundOpacity: 0.04,
                borderOpacity: (leading: 0.3, trailing: 0.1),
                accentTintOpacity: 0.05,
                highlightOpacity: 0.1,
                glowRadius: 4,
                glowOpacity: 0.1
            )
        case .standard:
            return GlassStyleValues(
                blurRadius: 20,
                backgroundOpacity: 0.06,
                borderOpacity: (leading: 0.4, trailing: 0.1),
                accentTintOpacity: 0.08,
                highlightOpacity: 0.15,
                glowRadius: 8,
                glowOpacity: 0.15
            )
        case .frosted:
            return GlassStyleValues(
                blurRadius: 30,
                backgroundOpacity: 0.08,
                borderOpacity: (leading: 0.5, trailing: 0.15),
                accentTintOpacity: 0.1,
                highlightOpacity: 0.2,
                glowRadius: 12,
                glowOpacity: 0.2
            )
        case .prayer:
            return GlassStyleValues(
                blurRadius: 20,
                backgroundOpacity: 0.08,
                borderOpacity: (leading: 0.45, trailing: 0.12),
                accentTintOpacity: 0.12,
                highlightOpacity: 0.18,
                glowRadius: 10,
                glowOpacity: 0.18
            )
        }
    }

    // MARK: - Legacy Urgency Color

    /// Get urgency color based on level
    func urgencyColor(_ level: UrgencyLevel) -> Color {
        switch level {
        case .low:
            return textTertiaryColor
        case .medium:
            return warningColor
        case .high:
            return CinematicColors.accentMagenta
        case .critical:
            return errorColor
        }
    }

    // MARK: - Legacy Atmosphere Gradient

    /// Get atmosphere gradient for a specific time period (legacy AtmospherePeriod)
    func atmosphereGradient(for period: AtmospherePeriod) -> [Color] {
        switch period {
        case .fajr:
            return [CinematicColors.periodFajr, CinematicColors.voidBlack]
        case .sunrise:
            return [CinematicColors.periodSunrise, CinematicColors.voidBlack]
        case .morning:
            return [CinematicColors.periodDhuhr.opacity(0.5), CinematicColors.voidBlack]
        case .dhuhr:
            return [CinematicColors.periodDhuhr, CinematicColors.voidBlack]
        case .asr:
            return [CinematicColors.periodAsr, CinematicColors.voidBlack]
        case .maghrib:
            return [CinematicColors.periodMaghrib, CinematicColors.voidBlack]
        case .isha:
            return [CinematicColors.periodIsha, CinematicColors.voidBlack]
        case .night:
            return [CinematicColors.voidBlack, CinematicColors.darkMatter]
        }
    }

    /// Get particle color for a specific prayer/time period (legacy AtmospherePeriod)
    func particleColor(for period: AtmospherePeriod) -> Color {
        switch period {
        case .fajr, .sunrise:
            return CinematicColors.prayerGold.opacity(0.6)
        case .maghrib:
            return CinematicColors.accentMagenta.opacity(0.5)
        default:
            return CinematicColors.accentCyan.opacity(0.4)
        }
    }
}

// MARK: - Supporting Types (Legacy Compatibility)

/// Glass style variants for glassmorphism effects
enum GlassStyle {
    case subtle    // Minimal blur, higher opacity
    case standard  // Default glass effect
    case frosted   // Heavy blur, lower opacity
    case prayer    // Optimized for prayer cards
}

/// Values for a specific glass style
struct GlassStyleValues {
    let blurRadius: CGFloat
    let backgroundOpacity: CGFloat
    let borderOpacity: (leading: CGFloat, trailing: CGFloat)
    let accentTintOpacity: CGFloat
    let highlightOpacity: CGFloat
    let glowRadius: CGFloat?
    let glowOpacity: CGFloat?

    /// Default values when no theme config is available
    static func `default`(for style: GlassStyle) -> GlassStyleValues {
        switch style {
        case .subtle:
            return GlassStyleValues(
                blurRadius: 0.5,
                backgroundOpacity: 0.7,
                borderOpacity: (leading: 0.3, trailing: 0.1),
                accentTintOpacity: 0.05,
                highlightOpacity: 0.1,
                glowRadius: nil,
                glowOpacity: nil
            )
        case .standard:
            return GlassStyleValues(
                blurRadius: 8,
                backgroundOpacity: 0.5,
                borderOpacity: (leading: 0.4, trailing: 0.1),
                accentTintOpacity: 0.08,
                highlightOpacity: 0.15,
                glowRadius: nil,
                glowOpacity: nil
            )
        case .frosted:
            return GlassStyleValues(
                blurRadius: 20,
                backgroundOpacity: 0.3,
                borderOpacity: (leading: 0.5, trailing: 0.15),
                accentTintOpacity: 0.1,
                highlightOpacity: 0.2,
                glowRadius: nil,
                glowOpacity: nil
            )
        case .prayer:
            return GlassStyleValues(
                blurRadius: 12,
                backgroundOpacity: 0.4,
                borderOpacity: (leading: 0.45, trailing: 0.12),
                accentTintOpacity: 0.12,
                highlightOpacity: 0.18,
                glowRadius: nil,
                glowOpacity: nil
            )
        }
    }
}

/// Represents different time periods for atmosphere gradients
enum AtmospherePeriod: String, CaseIterable {
    case fajr
    case sunrise
    case morning
    case dhuhr
    case asr
    case maghrib
    case isha
    case night

    /// Get the appropriate period based on hour of day
    static func from(hour: Int) -> AtmospherePeriod {
        switch hour {
        case 4..<6:
            return .fajr
        case 6..<8:
            return .sunrise
        case 8..<12:
            return .morning
        case 12..<15:
            return .dhuhr
        case 15..<17:
            return .asr
        case 17..<19:
            return .maghrib
        case 19..<22:
            return .isha
        default:
            return .night
        }
    }
}

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
        color: Color(white: 0).opacity(0.15),
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
        let shadow = themeManager.shadow(ShadowType.card)

        content
            .background(themeManager.surfaceColor)
            .cornerRadius(themeManager.cornerRadius(CornerRadiusSize.medium))
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
            .cornerRadius(themeManager.cornerRadius(CornerRadiusSize.medium))
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

/// Alias for backward compatibility during migration
/// Views using `@EnvironmentObject var themeManager: ThemeManager` will work
typealias ThemeManager = DarkMatterTheme
