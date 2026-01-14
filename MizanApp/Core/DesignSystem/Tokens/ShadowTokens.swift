//
//  ShadowTokens.swift
//  Mizan
//
//  Design System Shadow Tokens
//

import SwiftUI

/// Shadow presets for elevation hierarchy
struct MZShadow {
    /// Shadow level definition
    struct Level {
        let color: Color
        let radius: CGFloat
        let y: CGFloat

        /// No shadow
        static let none = Level(color: .clear, radius: 0, y: 0)

        /// Small shadow for subtle elevation
        static let sm = Level(color: .black.opacity(0.08), radius: 4, y: 2)

        /// Medium shadow for cards
        static let md = Level(color: .black.opacity(0.12), radius: 8, y: 4)

        /// Large shadow for modals
        static let lg = Level(color: .black.opacity(0.16), radius: 16, y: 8)

        /// Lifted shadow for pressed states
        static let lifted = Level(color: .black.opacity(0.25), radius: 20, y: 12)
    }

    // MARK: - Convenience Accessors

    static let none = Level.none
    static let sm = Level.sm
    static let md = Level.md
    static let lg = Level.lg
    static let lifted = Level.lifted

    // MARK: - Dynamic Glow

    /// Creates a glow effect with custom color
    /// - Parameters:
    ///   - color: The glow color
    ///   - intensity: Opacity of the glow (default 0.4)
    /// - Returns: A shadow level with glow effect
    static func glow(color: Color, intensity: Double = 0.4) -> Level {
        Level(color: color.opacity(intensity), radius: 20, y: 0)
    }
}

// MARK: - View Extension

extension View {
    /// Applies a shadow level to the view
    func mzShadow(_ level: MZShadow.Level) -> some View {
        self.shadow(color: level.color, radius: level.radius, y: level.y)
    }
}
