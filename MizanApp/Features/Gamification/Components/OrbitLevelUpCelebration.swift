//
//  OrbitLevelUpCelebration.swift
//  MizanApp
//
//  Cinematic celebration overlay when user advances to a new orbit level.
//

import SwiftUI

struct OrbitLevelUpCelebration: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var progressionService: ProgressionService

    let orbitConfig: OrbitConfig
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var orbitRingScale: CGFloat = 0.3
    @State private var orbitRingOpacity: Double = 0
    @State private var titleScale: CGFloat = 0.5
    @State private var titleOpacity: Double = 0
    @State private var particlesVisible = false
    @State private var starBurstRotation: Double = 0

    var body: some View {
        ZStack {
            // Dark cosmic background
            themeManager.backgroundColor
                .opacity(0.95)
                .ignoresSafeArea()

            // Animated star burst
            starBurst
                .opacity(particlesVisible ? 1 : 0)

            // Main content
            VStack(spacing: MZSpacing.xxl) {
                Spacer()

                // Orbit ring visualization
                orbitRingVisualization

                // Level text
                Text("Orbit \(orbitConfig.level)")
                    .font(MZTypography.displayLarge)
                    .foregroundColor(themeManager.primaryColor)
                    .scaleEffect(titleScale)
                    .opacity(titleOpacity)

                // Orbit name
                Text(orbitConfig.localizedTitle)
                    .font(MZTypography.headlineMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .opacity(showContent ? 1 : 0)

                // Unlock text
                if let unlock = orbitConfig.unlock {
                    Text("Unlocked: \(unlock)")
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(themeManager.successColor)
                        .padding(.horizontal, MZSpacing.md)
                        .padding(.vertical, MZSpacing.xs)
                        .background(
                            Capsule()
                                .fill(themeManager.successColor.opacity(0.2))
                        )
                        .opacity(showContent ? 1 : 0)
                }

                Spacer()

                // Continue button
                Button {
                    onDismiss()
                } label: {
                    Text("Continue Journey")
                        .font(MZTypography.labelLarge)
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .padding(.horizontal, MZSpacing.xxl)
                        .padding(.vertical, MZSpacing.md)
                        .background(
                            Capsule()
                                .fill(themeManager.primaryColor)
                        )
                }
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, MZSpacing.xxl)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private var orbitRingVisualization: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [themeManager.primaryColor.opacity(0.4), themeManager.primaryColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .scaleEffect(orbitRingScale)
                .opacity(orbitRingOpacity)

            // Orbit rings
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(
                        themeManager.primaryColor.opacity(0.3 - Double(ring) * 0.1),
                        lineWidth: 2
                    )
                    .frame(width: CGFloat(140 + ring * 30), height: CGFloat(140 + ring * 30))
                    .scaleEffect(orbitRingScale)
                    .opacity(orbitRingOpacity)
            }

            // Central orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(themeManager.textOnPrimaryColor.opacity(0.3), lineWidth: 2)
                )
                .scaleEffect(orbitRingScale)
                .opacity(orbitRingOpacity)

            // Level number
            Text("\(orbitConfig.level)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.textOnPrimaryColor)
                .scaleEffect(orbitRingScale)
                .opacity(orbitRingOpacity)
        }
    }

    private var starBurst: some View {
        ZStack {
            ForEach(0..<24, id: \.self) { index in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 2, height: 100)
                    .offset(y: -150)
                    .rotationEffect(.degrees(Double(index) * 15 + starBurstRotation))
            }
        }
    }

    private func startAnimation() {
        // Phase 1: Ring expansion
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            orbitRingScale = 1.0
            orbitRingOpacity = 1.0
        }

        // Phase 2: Title appear
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
            titleScale = 1.0
            titleOpacity = 1.0
        }

        // Phase 3: Particles and content
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            particlesVisible = true
            showContent = true
        }

        // Phase 4: Star burst rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            starBurstRotation = 360
        }

        // Haptic
        HapticManager.shared.trigger(.success)
    }
}

// MARK: - Velocity Tier Indicator

struct VelocityTierIndicator: View {
    @EnvironmentObject var themeManager: ThemeManager

    let tier: VelocityTierConfig
    let currentStreak: Int

    // Icon based on tier name
    private var tierIcon: String {
        switch tier.name.lowercased() {
        case "photon":
            return "bolt.fill"
        case "light":
            return "rays"
        case "warp":
            return "tornado"
        case "superluminal":
            return "sparkles"
        default:
            return "flame"
        }
    }

    var body: some View {
        HStack(spacing: MZSpacing.sm) {
            // Icon
            Image(systemName: tierIcon)
                .font(.system(size: 24))
                .foregroundColor(themeManager.primaryColor)

            VStack(alignment: .leading, spacing: 2) {
                // Tier name
                Text(tier.name)
                    .font(MZTypography.labelMedium)
                    .foregroundColor(themeManager.textPrimaryColor)

                // Streak info
                Text("\(currentStreak) day streak")
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textSecondaryColor)
            }

            Spacer()

            // Multiplier
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", tier.multiplier))x")
                    .font(MZTypography.dataMedium)
                    .foregroundColor(themeManager.successColor)
                Text("multiplier")
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textTertiaryColor)
            }
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .fill(themeManager.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .stroke(themeManager.primaryColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Combo Indicator

struct ComboIndicator: View {
    @EnvironmentObject var themeManager: ThemeManager

    let comboCount: Int
    let multiplier: Double

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: MZSpacing.sm) {
            // Combo flame icon
            ZStack {
                Circle()
                    .fill(themeManager.warningColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .scaleEffect(pulseScale)

                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.warningColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Combo")
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textSecondaryColor)

                Text("\(comboCount)x chain")
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
            }

            Spacer()

            // Multiplier badge
            Text("\(String(format: "%.1f", multiplier))x")
                .font(MZTypography.dataLarge)
                .foregroundColor(themeManager.warningColor)
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .fill(themeManager.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .stroke(themeManager.warningColor.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}
