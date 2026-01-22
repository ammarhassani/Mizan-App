//
//  CinematicAnimation.swift
//  Mizan
//
//  Animation system for cinematic Dark Matter theme
//

import SwiftUI

/// Animation presets for cinematic interactions
struct CinematicAnimation {
    // MARK: - Springs (Physics-Based)

    /// Gentle spring for subtle interactions
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.8)

    /// Snappy spring for quick responses
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.9)

    /// Elastic spring with bounce
    static let elastic = Animation.spring(response: 0.4, dampingFraction: 0.6)

    /// Dramatic spring for celebrations
    static let dramatic = Animation.spring(response: 0.6, dampingFraction: 0.5)

    /// Soft spring for smooth transitions
    static let soft = Animation.spring(response: 0.6, dampingFraction: 0.85)

    /// Stiff spring for immediate feedback
    static let stiff = Animation.spring(response: 0.2, dampingFraction: 0.95)

    // MARK: - Easing (Traditional Curves)

    /// Smooth ease in-out
    static let smooth = Animation.easeInOut(duration: 0.3)

    /// Enter animation
    static let enter = Animation.easeOut(duration: 0.25)

    /// Exit animation
    static let exit = Animation.easeIn(duration: 0.2)

    /// Slow transition
    static let slow = Animation.easeInOut(duration: 0.6)

    // MARK: - Continuous (Looping)

    /// Slow pulse effect
    static let pulse = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)

    /// Slow drift for particles
    static let drift = Animation.linear(duration: 30.0).repeatForever(autoreverses: false)

    /// Breathing glow effect
    static let breathe = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)

    /// Fast pulse for active states
    static let pulseFast = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)

    // MARK: - Signature Animations

    /// Warp transition between tabs
    static let warp = Animation.easeInOut(duration: 0.3)

    /// Task implosion animation
    static let implosion = Animation.easeIn(duration: 0.8)

    /// Task materialization (reverse implosion)
    static let materialization = Animation.spring(response: 0.5, dampingFraction: 0.7)

    /// Orbit level up celebration
    static let orbitLevelUp = Animation.spring(response: 0.6, dampingFraction: 0.4)

    /// Dock expansion
    static let dockExpand = Animation.spring(response: 0.4, dampingFraction: 0.7)

    /// Dock collapse
    static let dockCollapse = Animation.easeOut(duration: 0.3)

    // MARK: - Durations

    /// Instant (no animation)
    static let durationInstant: Double = 0.0

    /// Very fast
    static let durationVeryFast: Double = 0.15

    /// Fast
    static let durationFast: Double = 0.2

    /// Medium
    static let durationMedium: Double = 0.4

    /// Slow
    static let durationSlow: Double = 0.6

    /// Dramatic
    static let durationDramatic: Double = 1.2

    // MARK: - Stagger Helper

    /// Create staggered animation delay for list items
    static func stagger(index: Int, interval: Double = 0.05) -> Animation {
        Animation.spring(response: 0.4, dampingFraction: 0.8)
            .delay(Double(index) * interval)
    }
}

// MARK: - Reduce Motion Support

/// Utility for checking system reduce motion preference
struct ReduceMotion {
    /// Check if user prefers reduced motion
    static var isEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Get animation respecting reduce motion preference with custom fallback duration
    /// When reduce motion is enabled, returns a fast simple animation
    static func animation(_ animation: Animation, reducedDuration: Double = 0.1) -> Animation {
        isEnabled ? .easeInOut(duration: reducedDuration) : animation
    }

    /// Get animation respecting reduce motion preference with custom reduced animation
    static func animation(_ animation: Animation, reducedTo reduced: Animation) -> Animation {
        isEnabled ? reduced : animation
    }
}

// MARK: - View Extension for Cinematic Transitions

extension View {
    /// Apply cinematic appear animation
    func cinematicAppear(delay: Double = 0) -> some View {
        self
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                removal: .opacity
            ))
            .animation(CinematicAnimation.enter.delay(delay), value: UUID())
    }

    /// Apply animation respecting reduce motion preference
    func accessibleAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.animation(ReduceMotion.animation(animation), value: value)
    }

    /// Apply spring animation with reduce motion fallback
    func accessibleSpring<V: Equatable>(response: Double = 0.5, dampingFraction: Double = 0.8, value: V) -> some View {
        let animation = Animation.spring(response: response, dampingFraction: dampingFraction)
        return self.animation(ReduceMotion.animation(animation, reducedDuration: 0.15), value: value)
    }

    /// Conditional glow effect respecting reduce motion
    func accessibleGlow(color: Color, radius: CGFloat, condition: Bool = true) -> some View {
        Group {
            if condition && !ReduceMotion.isEnabled {
                self.shadow(color: color, radius: radius)
            } else {
                self
            }
        }
    }
}
