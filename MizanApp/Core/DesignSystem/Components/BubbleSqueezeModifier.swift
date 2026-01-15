//
//  BubbleSqueezeModifier.swift
//  Mizan
//
//  View modifier that applies a "bubble squeeze" effect for overlapping tasks.
//  The squeeze is proportional to overlap duration - more overlap = more compression.
//

import SwiftUI

/// Direction of the squeeze effect
enum SqueezeDirection {
    case top       // Being squeezed from above
    case bottom    // Being squeezed from below
    case both      // Squeezed from both sides
}

/// Applies a "bubble squeeze" effect to views based on overlap amount
struct BubbleSqueezeModifier: ViewModifier {
    let squeezeAmount: CGFloat        // 0.0 - 0.3
    let direction: SqueezeDirection
    let isAnimated: Bool

    // More aggressive scaling for visible effect
    // 30% max compression for maximum overlap (was 15%)
    private var horizontalScale: CGFloat {
        1.0 - (squeezeAmount * 1.0)
    }

    private var verticalOffset: CGFloat {
        // Increased offset for visibility (was 20)
        switch direction {
        case .top:
            return squeezeAmount * 30     // Push down
        case .bottom:
            return -squeezeAmount * 30    // Push up
        case .both:
            return 0
        }
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(
                x: horizontalScale,
                y: 1.0,
                anchor: anchorPoint
            )
            .offset(y: verticalOffset)
            .animation(
                isAnimated ? .spring(response: 0.4, dampingFraction: 0.7) : nil,
                value: squeezeAmount
            )
    }

    private var anchorPoint: UnitPoint {
        switch direction {
        case .top: return .bottom
        case .bottom: return .top
        case .both: return .center
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply bubble squeeze effect for task overlaps
    /// - Parameters:
    ///   - amount: The squeeze amount (0.0 - 0.3)
    ///   - direction: Which direction the squeeze comes from
    ///   - animated: Whether to animate the squeeze
    func bubbleSqueeze(
        amount: CGFloat,
        direction: SqueezeDirection = .both,
        animated: Bool = true
    ) -> some View {
        self.modifier(BubbleSqueezeModifier(
            squeezeAmount: amount,
            direction: direction,
            isAnimated: animated
        ))
    }
}
