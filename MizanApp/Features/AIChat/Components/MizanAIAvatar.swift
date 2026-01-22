//
//  MizanAIAvatar.swift
//  Mizan
//
//  Simple AI assistant avatar using SF Symbol sparkles
//  Clean, recognizable at any size - inspired by Claude/ChatGPT
//

import SwiftUI

/// The Mizan AI assistant avatar
/// Simple sparkles icon on primaryColor background
struct MizanAIAvatar: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// Size of the avatar (width and height)
    var size: CGFloat = 28

    /// Whether the AI is currently thinking/processing
    var isThinking: Bool = false

    // MARK: - Animation State

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Outer glow (subtle cosmic effect)
            if !ReduceMotion.isEnabled {
                RoundedRectangle(cornerRadius: size * 0.25)
                    .fill(themeManager.primaryColor.opacity(0.3))
                    .frame(width: size + 4, height: size + 4)
                    .blur(radius: isThinking ? 6 : 3)
                    .animation(.easeInOut(duration: 0.6), value: isThinking)
            }

            // Background
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(themeManager.primaryColor)
                .frame(width: size, height: size)

            // Sparkles icon
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundColor(themeManager.textOnPrimaryColor)
                .scaleEffect(pulseScale)
        }
        .onChange(of: isThinking) { _, thinking in
            if thinking {
                startPulse()
            } else {
                stopPulse()
            }
        }
        .onAppear {
            if isThinking {
                startPulse()
            }
        }
        .onDisappear {
            // Stop animation when view disappears
            stopPulse()
        }
    }

    // MARK: - Animation

    private func startPulse() {
        // Simple scale pulse - NOT repeatForever to avoid performance issues
        withAnimation(.easeInOut(duration: 0.6)) {
            pulseScale = 1.1
        }
        // Schedule return to normal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if isThinking {
                withAnimation(.easeInOut(duration: 0.6)) {
                    pulseScale = 1.0
                }
                // Continue pulse if still thinking
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if isThinking {
                        startPulse()
                    }
                }
            }
        }
    }

    private func stopPulse() {
        withAnimation(.easeOut(duration: 0.2)) {
            pulseScale = 1.0
        }
    }
}

// MARK: - Large Avatar Variant (for Welcome Screen)

/// Larger variant of the AI avatar for welcome screens
struct MizanAIAvatarLarge: View {
    @EnvironmentObject var themeManager: ThemeManager

    var size: CGFloat = 64

    @State private var appeared = false
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            // Cosmic glow effect (respects reduce motion)
            if !ReduceMotion.isEnabled {
                // Outer glow ring
                RoundedRectangle(cornerRadius: size * 0.3)
                    .fill(themeManager.primaryColor.opacity(0.2))
                    .frame(width: size + 16, height: size + 16)
                    .blur(radius: glowPulse ? 12 : 8)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowPulse)

                // Inner glow ring
                RoundedRectangle(cornerRadius: size * 0.25)
                    .fill(themeManager.primaryColor.opacity(0.3))
                    .frame(width: size + 6, height: size + 6)
                    .blur(radius: 4)
            }

            // Background with gradient
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.primaryColor,
                            themeManager.primaryColor.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // Sparkles icon
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundColor(themeManager.textOnPrimaryColor)
        }
        .scaleEffect(appeared ? 1.0 : 0.8)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(ReduceMotion.animation(.spring(response: 0.6, dampingFraction: 0.7))) {
                appeared = true
            }
            // Start glow pulse after appear animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Preview

#Preview("AI Avatar Sizes") {
    VStack(spacing: 32) {
        HStack(spacing: 24) {
            VStack {
                MizanAIAvatar(size: 28)
                Text("28pt")
                    .font(.caption)
            }

            VStack {
                MizanAIAvatar(size: 32, isThinking: true)
                Text("32pt thinking")
                    .font(.caption)
            }

            VStack {
                MizanAIAvatar(size: 40)
                Text("40pt")
                    .font(.caption)
            }
        }

        MizanAIAvatarLarge(size: 64)
        Text("64pt (Welcome)")
            .font(.caption)

        MizanAIAvatarLarge(size: 80)
        Text("80pt (Large)")
            .font(.caption)
    }
    .padding()
    .environmentObject(ThemeManager())
}
