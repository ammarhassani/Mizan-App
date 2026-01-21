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

    private init() {
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

    // MARK: - Corner Radius

    /// Corner radius size options
    enum DMCornerRadiusSize {
        case small, medium, large, extraLarge
    }

    /// Get corner radius for a size
    func cornerRadius(_ size: DMCornerRadiusSize) -> CGFloat {
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

    // MARK: - Shadows

    /// Shadow style options
    enum DMShadowStyle {
        case card, elevated, floating
    }

    /// Shadow configuration tuple
    typealias ShadowConfig = (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)

    /// Get shadow configuration for a style
    func shadow(_ style: DMShadowStyle) -> ShadowConfig {
        switch style {
        case .card:
            return (CinematicColors.accentCyan.opacity(0.1), 8, 0, 4)
        case .elevated:
            return (CinematicColors.accentCyan.opacity(0.15), 16, 0, 8)
        case .floating:
            return (CinematicColors.accentCyan.opacity(0.2), 24, 0, 12)
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

    // MARK: - Glass Styles

    /// Glass style options
    enum DMGlassStyle {
        case subtle, standard, frosted, prayer
    }

    /// Glass style configuration tuple
    typealias GlassConfig = (blur: CGFloat, opacity: Double, glow: Bool)

    /// Get glass style configuration
    func glassStyle(_ style: DMGlassStyle) -> GlassConfig {
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
}
