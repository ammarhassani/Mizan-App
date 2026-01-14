//
//  InteractionTokens.swift
//  Mizan
//
//  Design System Interaction & Gesture Tokens
//

import SwiftUI

/// Interaction constants for gestures and visual feedback
struct MZInteraction {
    // MARK: - Gesture Thresholds

    /// Minimum distance for swipe gesture recognition
    static let swipeThreshold: CGFloat = 80

    /// Duration for long press recognition
    static let longPressDuration: Double = 0.5

    /// Minimum scale for pinch-to-zoom
    static let pinchMinScale: CGFloat = 0.5

    /// Maximum scale for pinch-to-zoom
    static let pinchMaxScale: CGFloat = 2.0

    /// Scale detents for haptic feedback during zoom
    static let scaleDetents: [CGFloat] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

    // MARK: - Visual Feedback

    /// Scale when element is pressed
    static let pressedScale: CGFloat = 0.95

    /// Scale when element is elevated/dragging
    static let elevatedScale: CGFloat = 1.05

    /// Radius for glow effects
    static let glowRadius: CGFloat = 8

    /// Opacity for glow effects
    static let glowOpacity: Double = 0.4

    /// Border width for focus states
    static let focusBorderWidth: CGFloat = 2

    /// Default border width
    static let defaultBorderWidth: CGFloat = 1

    // MARK: - Floating Label

    /// Vertical offset when label is floating
    static let floatingLabelOffset: CGFloat = -24

    /// Scale when label is floating
    static let floatingLabelScale: CGFloat = 0.85

    // MARK: - Validation Feedback

    /// Shake amplitude for error animation
    static let shakeAmplitude: CGFloat = 6

    /// Number of shake oscillations
    static let shakeOscillations: Int = 3

    // MARK: - Particle Counts

    /// Maximum particles for celebration effects
    static let celebrationParticles: Int = 40

    /// Maximum particles for ambient effects (subtle)
    static let ambienceParticles: Int = 15

    // MARK: - Timeline

    /// Base height per hour in timeline
    static let baseHourHeight: CGFloat = 100

    /// Minimum hour height (at min zoom)
    static let minHourHeight: CGFloat = 50

    /// Maximum hour height (at max zoom)
    static let maxHourHeight: CGFloat = 200

    // MARK: - Radial Picker

    /// Diameter of the radial duration picker
    static let radialPickerDiameter: CGFloat = 240

    /// Size of the draggable handle
    static let radialHandleSize: CGFloat = 28

    /// Minutes per snap increment
    static let durationSnapInterval: Int = 15
}

// MARK: - Haptic Feedback Extension

extension MZInteraction {
    /// Trigger haptic feedback for scale detent
    static func hapticForScaleDetent(_ scale: CGFloat) {
        if scaleDetents.contains(where: { abs($0 - scale) < 0.05 }) {
            HapticManager.shared.trigger(.light)
        }
    }
}
