//
//  TypographyTokens.swift
//  Mizan
//
//  Design System Typography Tokens
//

import SwiftUI

/// Typography tokens following an 8pt scale
struct MZTypography {
    // MARK: - Display (Splash, Celebrations)
    static let displayLarge = Font.system(size: 56, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 44, weight: .bold, design: .rounded)

    // MARK: - Headlines (Section Headers)
    static let headlineLarge = Font.system(size: 32, weight: .semibold)
    static let headlineMedium = Font.system(size: 28, weight: .semibold)
    static let headlineSmall = Font.system(size: 24, weight: .semibold)

    // MARK: - Title (Cards, Navigation)
    static let titleLarge = Font.system(size: 22, weight: .semibold)
    static let titleMedium = Font.system(size: 18, weight: .semibold)
    static let titleSmall = Font.system(size: 16, weight: .semibold)

    // MARK: - Data (Numbers, Stats, Mass Display)
    static let dataLarge = Font.system(size: 32, weight: .medium, design: .monospaced)
    static let dataMedium = Font.system(size: 20, weight: .medium, design: .monospaced)
    static let dataSmall = Font.system(size: 14, weight: .medium, design: .monospaced)

    // MARK: - Body (Content)
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)

    // MARK: - Label (Metadata)
    static let labelLarge = Font.system(size: 14, weight: .medium)
    static let labelMedium = Font.system(size: 12, weight: .medium)
    static let labelSmall = Font.system(size: 11, weight: .medium)

    // MARK: - Arabic Variants
    static let arabicDisplay = Font.custom("SF Arabic Rounded", size: 48).weight(.bold)
    static let arabicHeadline = Font.custom("SF Arabic", size: 28).weight(.semibold)
    static let arabicBody = Font.custom("SF Arabic", size: 17)
}
