//
//  AchievementCard.swift
//  MizanApp
//
//  Cosmic achievement card with unlock state and progress.
//

import SwiftUI

struct AchievementCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    let achievement: AchievementConfig
    let isUnlocked: Bool
    let progress: Double // 0.0 - 1.0

    var body: some View {
        HStack(spacing: MZSpacing.md) {
            // Achievement icon
            achievementIcon

            // Achievement info
            VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                // Title
                Text(achievement.localizedTitle)
                    .font(MZTypography.bodyLarge)
                    .foregroundColor(isUnlocked ? themeManager.textPrimaryColor : themeManager.textSecondaryColor)

                // Description
                Text(achievement.localizedDescription)
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textTertiaryColor)
                    .lineLimit(2)

                // Progress bar (if not unlocked)
                if !isUnlocked {
                    progressBar
                }
            }

            Spacer()

            // Mass reward
            if isUnlocked {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.successColor)
                    Text("+\(achievement.massReward)")
                        .font(MZTypography.labelSmall)
                        .foregroundColor(themeManager.successColor)
                }
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.textTertiaryColor)
                    Text("\(achievement.massReward)")
                        .font(MZTypography.labelSmall)
                        .foregroundColor(themeManager.textTertiaryColor)
                }
            }
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .fill(isUnlocked ? themeManager.primaryColor.opacity(0.1) : themeManager.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .stroke(isUnlocked ? themeManager.primaryColor.opacity(0.3) : themeManager.surfaceSecondaryColor, lineWidth: 1)
                )
        )
    }

    private var achievementIcon: some View {
        ZStack {
            // Background glow for unlocked
            if isUnlocked {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [themeManager.primaryColor.opacity(0.4), themeManager.primaryColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
            }

            // Icon circle
            Circle()
                .fill(isUnlocked ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
                .frame(width: 48, height: 48)

            // Icon
            Image(systemName: achievement.icon)
                .font(.system(size: 24))
                .foregroundColor(isUnlocked ? themeManager.textOnPrimaryColor : themeManager.textTertiaryColor)
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(themeManager.surfaceSecondaryColor)
                    .frame(height: 4)

                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(themeManager.primaryColor)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
        .padding(.top, MZSpacing.xxs)
    }
}

// MARK: - Achievement Celebration Overlay

struct AchievementUnlockedOverlay: View {
    @EnvironmentObject var themeManager: ThemeManager

    let achievement: AchievementConfig
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var iconRotation: Double = -30
    @State private var showParticles = false

    var body: some View {
        ZStack {
            // Dimmed background
            themeManager.backgroundColor
                .opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: MZSpacing.xl) {
                // Achievement icon with burst effect
                ZStack {
                    // Burst rays
                    ForEach(0..<12, id: \.self) { index in
                        Rectangle()
                            .fill(themeManager.primaryColor.opacity(0.3))
                            .frame(width: 3, height: showParticles ? 60 : 0)
                            .offset(y: -50)
                            .rotationEffect(.degrees(Double(index) * 30))
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: showParticles)
                    }

                    // Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [themeManager.primaryColor.opacity(0.6), themeManager.primaryColor.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    // Icon background
                    Circle()
                        .fill(themeManager.primaryColor)
                        .frame(width: 100, height: 100)

                    // Icon
                    Image(systemName: achievement.icon)
                        .font(.system(size: 48))
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .rotationEffect(.degrees(iconRotation))
                }

                // Title
                Text("Achievement Unlocked!")
                    .font(MZTypography.headlineMedium)
                    .foregroundColor(themeManager.primaryColor)

                // Achievement name
                Text(achievement.localizedTitle)
                    .font(MZTypography.titleLarge)
                    .foregroundColor(themeManager.textPrimaryColor)

                // Description
                Text(achievement.localizedDescription)
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(themeManager.textSecondaryColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MZSpacing.xl)

                // Mass reward
                HStack(spacing: MZSpacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                    Text("+\(achievement.massReward) Mass")
                        .font(MZTypography.titleMedium)
                }
                .foregroundColor(themeManager.successColor)
                .padding(.top, MZSpacing.md)

                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text("Continue")
                        .font(MZTypography.labelLarge)
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .padding(.horizontal, MZSpacing.xxl)
                        .padding(.vertical, MZSpacing.sm)
                        .background(
                            Capsule()
                                .fill(themeManager.primaryColor)
                        )
                }
                .padding(.top, MZSpacing.lg)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
                iconRotation = 0
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                showParticles = true
            }
        }
    }
}
