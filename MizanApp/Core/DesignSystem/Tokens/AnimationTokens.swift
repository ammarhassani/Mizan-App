//
//  AnimationTokens.swift
//  Mizan
//
//  Design System Animation Tokens
//

import SwiftUI

/// Animation presets using spring physics
struct MZAnimation {
    // MARK: - Standard Springs

    /// Gentle spring for subtle interactions
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.8)

    /// Bouncy spring for playful interactions
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)

    /// Snappy spring for quick responses
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.9)

    /// Soft spring for smooth transitions
    static let soft = Animation.spring(response: 0.6, dampingFraction: 0.85)

    /// Stiff spring for immediate feedback
    static let stiff = Animation.spring(response: 0.2, dampingFraction: 0.95)

    // MARK: - Dramatic Springs

    /// Dramatic spring for celebrations
    static let dramatic = Animation.spring(response: 0.7, dampingFraction: 0.5)

    /// Breathing animation for continuous effects
    static let breathe = Animation.spring(response: 1.2, dampingFraction: 0.7)

    /// Celebration spring for task completion
    static let celebration = Animation.spring(response: 0.4, dampingFraction: 0.5)

    // MARK: - Form Animations

    /// Floating label animation
    static let floatingLabel = Animation.spring(response: 0.35, dampingFraction: 0.85)

    /// Input focus border animation
    static let focusBorder = Animation.easeOut(duration: 0.2)

    /// Validation shake animation
    static let validationShake = Animation.spring(response: 0.15, dampingFraction: 0.3)

    // MARK: - Timeline Animations

    /// Current time indicator pulse
    static let timePulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)

    /// Pinch zoom snap animation
    static let zoomSnap = Animation.spring(response: 0.25, dampingFraction: 0.9)

    /// Particle burst animation
    static let particleBurst = Animation.easeOut(duration: 0.8)

    /// Prayer atmosphere transition (slow crossfade)
    static let atmosphereTransition = Animation.linear(duration: 2.0)

    /// Flow connector shimmer
    static let flowShimmer = Animation.linear(duration: 3.0).repeatForever(autoreverses: false)

    // MARK: - Durations

    struct Duration {
        static let instant: Double = 0.0
        static let veryFast: Double = 0.15
        static let fast: Double = 0.2
        static let medium: Double = 0.4
        static let slow: Double = 0.6
        static let dramatic: Double = 1.2
    }

    // MARK: - Stagger Helper

    /// Creates staggered delay for list animations
    /// - Parameters:
    ///   - index: The item index in the list
    ///   - interval: Time between each item (default 0.05s)
    /// - Returns: Delay in seconds
    static func stagger(index: Int, interval: Double = 0.05) -> Double {
        Double(index) * interval
    }
}
