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
