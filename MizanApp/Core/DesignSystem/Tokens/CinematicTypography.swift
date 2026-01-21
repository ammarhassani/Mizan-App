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
