//
//  ModernTypingIndicator.swift
//  Mizan
//
//  Modern typing indicator with AI avatar and simple dot animation
//  Performance optimized - no repeatForever animations
//

import SwiftUI

/// Modern typing indicator with avatar and animated dots
struct ModernTypingIndicator: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// The status text to display
    var statusText: String = "يفكر..."

    // MARK: - Animation State

    @State private var activeDot: Int = 0
    @State private var isAnimating = false

    var body: some View {
        // In RTL: first element goes to RIGHT
        HStack(alignment: .top, spacing: MZSpacing.sm) {
            // AI Avatar FIRST (appears on RIGHT in RTL)
            MizanAIAvatar(size: 28, isThinking: true)

            // Status content SECOND (appears next to avatar)
            VStack(alignment: .leading, spacing: MZSpacing.xs) {
                // Status text
                Text(statusText)
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(themeManager.textSecondaryColor)

                // Animated dots with cosmic glow
                HStack(spacing: MZSpacing.xxs) {
                    ForEach(0..<3, id: \.self) { index in
                        ZStack {
                            // Glow when active
                            if activeDot == index && !ReduceMotion.isEnabled {
                                Circle()
                                    .fill(themeManager.primaryColor.opacity(0.4))
                                    .frame(width: 8, height: 8)
                                    .blur(radius: 3)
                            }

                            Circle()
                                .fill(activeDot == index ? themeManager.primaryColor : themeManager.textTertiaryColor)
                                .frame(width: 5, height: 5)
                                .opacity(activeDot == index ? 1.0 : 0.4)
                                .scaleEffect(activeDot == index ? 1.2 : 1.0)
                        }
                    }
                }
            }
            .padding(.horizontal, MZSpacing.md)
            .padding(.vertical, MZSpacing.sm)
            .background(
                ZStack {
                    // Glass-like background
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .fill(themeManager.surfaceColor)

                    // Subtle cosmic gradient overlay
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.primaryColor.opacity(0.03),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                // Leading accent border (= RIGHT side in RTL) with glow
                HStack {
                    ZStack {
                        // Glow effect (respects reduce motion)
                        if !ReduceMotion.isEnabled {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(themeManager.primaryColor.opacity(0.3))
                                .frame(width: 5)
                                .blur(radius: 4)
                        }

                        // Solid border
                        RoundedRectangle(cornerRadius: 2)
                            .fill(themeManager.primaryColor.opacity(0.5))
                            .frame(width: 3)
                    }
                    Spacer()
                }
                .padding(.vertical, MZSpacing.xs)
                .padding(.leading, MZSpacing.xxs)
            )

            // Spacer LAST (fills remaining space on LEFT in RTL)
            Spacer()
        }
        .onAppear {
            isAnimating = true
            animateDots()
        }
        .onDisappear {
            isAnimating = false
        }
    }

    // MARK: - Animation

    private func animateDots() {
        guard isAnimating else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            activeDot = (activeDot + 1) % 3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            animateDots()
        }
    }
}

// MARK: - Preview

#Preview("Typing Indicator") {
    VStack(spacing: 32) {
        Text("Modern Typing Indicator")
            .font(.caption)

        ModernTypingIndicator()
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager())
}
