//
//  CinematicSpacing.swift
//  Mizan
//
//  Spacing system for cinematic Dark Matter theme
//

import SwiftUI

/// Spacing tokens following an 8pt grid system
/// Designed for dramatic layouts with breathing room
struct CinematicSpacing {
    // MARK: - Base Scale (8pt grid)

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

    /// Card internal padding
    static let cardPadding: CGFloat = 16

    /// Space between sections
    static let sectionSpacing: CGFloat = 32

    /// Screen edge padding
    static let screenPadding: CGFloat = 16

    /// Space between list items
    static let itemSpacing: CGFloat = 12

    // MARK: - Component Specific

    /// Horizontal chip padding
    static let chipPaddingH: CGFloat = 16

    /// Vertical chip padding
    static let chipPaddingV: CGFloat = 10

    /// Button vertical padding
    static let buttonPaddingV: CGFloat = 16

    /// Glass card padding
    static let glassPadding: CGFloat = 20

    /// Dock item spacing
    static let dockItemSpacing: CGFloat = 24

    // MARK: - Timeline Specific

    /// Prayer card height
    static let prayerCardHeight: CGFloat = 100

    /// Task card height (minimum)
    static let taskCardMinHeight: CGFloat = 72

    /// Timeline hour height at normal zoom
    static let timelineHourHeight: CGFloat = 120

    // MARK: - Corner Radius

    /// Small radius (chips, buttons)
    static let radiusSmall: CGFloat = 8

    /// Medium radius (cards)
    static let radiusMedium: CGFloat = 16

    /// Large radius (sheets, modals)
    static let radiusLarge: CGFloat = 24

    /// Extra large radius (full-screen elements)
    static let radiusExtraLarge: CGFloat = 32
}
