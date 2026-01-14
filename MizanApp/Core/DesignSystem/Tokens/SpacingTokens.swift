//
//  SpacingTokens.swift
//  Mizan
//
//  Design System Spacing Tokens (8pt grid)
//

import SwiftUI

/// Spacing tokens following an 8pt grid system
struct MZSpacing {
    // MARK: - Base Scale
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64

    // MARK: - Semantic Spacing
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let screenPadding: CGFloat = 20
    static let itemSpacing: CGFloat = 12

    // MARK: - Component Specific
    static let chipPaddingH: CGFloat = 16
    static let chipPaddingV: CGFloat = 10
    static let buttonPaddingV: CGFloat = 16
}
