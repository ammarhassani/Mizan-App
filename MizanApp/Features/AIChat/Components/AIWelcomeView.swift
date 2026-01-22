//
//  AIWelcomeView.swift
//  Mizan
//
//  Welcome screen for AI chat with avatar, greeting, and quick suggestions
//

import SwiftUI

/// Welcome screen shown when AI chat is empty
struct AIWelcomeView: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// Quick suggestions to display
    let suggestions: [String]

    /// Callback when a suggestion is tapped
    var onSuggestionTap: ((String) -> Void)?

    // MARK: - State

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Subtle cosmic background particles (respects reduce motion)
            if !ReduceMotion.isEnabled {
                WelcomeCosmicBackground()
                    .environmentObject(themeManager)
            }

            VStack(spacing: MZSpacing.xl) {
                Spacer()

                // Avatar and greeting
                VStack(spacing: MZSpacing.lg) {
                    // Large AI Avatar
                    MizanAIAvatarLarge(size: 72)
                        .scaleEffect(appeared ? 1.0 : 0.8)
                        .opacity(appeared ? 1.0 : 0)

                    // Greeting text
                    VStack(spacing: MZSpacing.xs) {
                        Text("مرحباً، أنا مساعد ميزان")
                            .font(MZTypography.titleLarge)
                            .foregroundColor(themeManager.textPrimaryColor)

                        Text("كيف يمكنني مساعدتك اليوم؟")
                            .font(MZTypography.bodyLarge)
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1.0 : 0)
                    .offset(y: appeared ? 0 : 10)
                }

                // Quick suggestions
                if !suggestions.isEmpty {
                    VStack(spacing: MZSpacing.sm) {
                        // Suggestions grid
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: MZSpacing.xs),
                                GridItem(.flexible(), spacing: MZSpacing.xs)
                            ],
                            spacing: MZSpacing.xs
                        ) {
                            ForEach(suggestions.prefix(4), id: \.self) { suggestion in
                                SuggestionChip(
                                    text: suggestion,
                                    onTap: {
                                        onSuggestionTap?(suggestion)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, MZSpacing.md)
                    }
                    .opacity(appeared ? 1.0 : 0)
                    .offset(y: appeared ? 0 : 20)
                }

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            let animation = ReduceMotion.animation(
                .spring(response: 0.6, dampingFraction: 0.8).delay(0.1),
                reducedDuration: 0.2
            )
            withAnimation(animation) {
                appeared = true
            }
        }
    }
}

// MARK: - Welcome Cosmic Background

/// Subtle cosmic particle background for welcome screen
private struct WelcomeCosmicBackground: View {
    @EnvironmentObject var themeManager: ThemeManager

    @State private var particles: [WelcomeParticle] = []
    @State private var animationPhase = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(themeManager.primaryColor.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: particle.blur)
                        .position(
                            x: particle.x * geometry.size.width,
                            y: particle.y * geometry.size.height + (animationPhase ? particle.drift : 0)
                        )
                }
            }
            .onAppear {
                // Generate particles
                particles = (0..<12).map { _ in
                    WelcomeParticle(
                        x: CGFloat.random(in: 0...1),
                        y: CGFloat.random(in: 0...1),
                        size: CGFloat.random(in: 2...6),
                        opacity: Double.random(in: 0.05...0.15),
                        blur: CGFloat.random(in: 0...2),
                        drift: CGFloat.random(in: -20...20)
                    )
                }
                // Start drift animation
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    animationPhase = true
                }
            }
        }
    }
}

/// Particle data for welcome background
private struct WelcomeParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let blur: CGFloat
    let drift: CGFloat
}

// MARK: - Suggestion Chip

/// Quick suggestion chip button
private struct SuggestionChip: View {
    @EnvironmentObject var themeManager: ThemeManager

    let text: String
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            HapticManager.shared.trigger(.light)
            onTap?()
        } label: {
            HStack(spacing: MZSpacing.xs) {
                Image(systemName: suggestionIcon)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.primaryColor)

                Text(text)
                    .font(MZTypography.labelMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, MZSpacing.sm)
            .padding(.vertical, MZSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    // Glass-like surface
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .fill(themeManager.surfaceColor)

                    // Subtle gradient
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.primaryColor.opacity(0.04),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                    .stroke(themeManager.primaryColor.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Icon Detection

    private var suggestionIcon: String {
        if text.contains("أضف") || text.contains("add") {
            return "plus.circle"
        } else if text.contains("مهام") || text.contains("tasks") || text.contains("ما هي") {
            return "list.bullet"
        } else if text.contains("رتب") || text.contains("arrange") || text.contains("جدول") {
            return "calendar.badge.clock"
        } else if text.contains("احذف") || text.contains("delete") {
            return "trash"
        } else if text.contains("وقت") || text.contains("time") || text.contains("فارغ") {
            return "clock"
        } else {
            return "sparkles"
        }
    }
}

// MARK: - Preview

#Preview("AI Welcome") {
    AIWelcomeView(
        suggestions: [
            "أضف مهمة دراسة",
            "ما هي مهامي غداً؟",
            "رتب مهامي اليوم",
            "هل يوجد وقت فارغ؟"
        ],
        onSuggestionTap: { suggestion in
            print("Tapped: \(suggestion)")
        }
    )
    .background(Color.gray.opacity(0.05))
    .environmentObject(ThemeManager())
}
