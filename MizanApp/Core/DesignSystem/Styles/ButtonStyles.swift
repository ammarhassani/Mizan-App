//
//  ButtonStyles.swift
//  Mizan
//
//  Design System Button Styles
//

import SwiftUI

/// Pressable button style with subtle scale effect
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(MZAnimation.stiff, value: configuration.isPressed)
    }
}

/// Bouncy button style for playful interactions
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(MZAnimation.bouncy, value: configuration.isPressed)
    }
}

/// Scale button style for larger press effect
struct ScaleButtonStyle: ButtonStyle {
    let scale: CGFloat

    init(scale: CGFloat = 0.92) {
        self.scale = scale
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(MZAnimation.snappy, value: configuration.isPressed)
    }
}
