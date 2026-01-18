//
//  SettingsComponents.swift
//  Mizan
//
//  Reusable components for settings with animations and haptics
//

import SwiftUI

// MARK: - Settings Section Header

struct SettingsSectionHeader: View {
    let icon: String
    let title: String
    var iconColor: Color = .primary

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: MZSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.15))
                )

            Text(title)
                .font(MZTypography.titleSmall)
                .foregroundColor(themeManager.textPrimaryColor)
        }
        .padding(.vertical, MZSpacing.xs)
    }
}

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.surfaceColor)
                .shadow(color: themeManager.overlayColor.opacity(0.05), radius: 8, y: 2)
        )
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = true
    var showProBadge: Bool = false

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: MZSpacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                )

            // Text
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MZSpacing.xs) {
                    Text(title)
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(themeManager.textPrimaryColor)

                    if showProBadge {
                        ProBadgeSmall()
                    }
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            Spacer()

            // Chevron
            if showChevron {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.textTertiaryColor)
            }
        }
        .padding(MZSpacing.md)
        .contentShape(Rectangle())
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var isLocked: Bool = false

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: MZSpacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                )

            // Text
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MZSpacing.xs) {
                    Text(title)
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(themeManager.textPrimaryColor)

                    if isLocked {
                        ProBadgeSmall()
                    }
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            Spacer()

            // Animated Toggle
            AnimatedToggle(isOn: $isOn, isDisabled: isLocked)
                .environmentObject(themeManager)
        }
        .padding(MZSpacing.md)
        .contentShape(Rectangle())
        .opacity(isLocked ? 0.7 : 1.0)
    }
}

// MARK: - Animated Toggle

struct AnimatedToggle: View {
    @Binding var isOn: Bool
    var isDisabled: Bool = false

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button {
            guard !isDisabled else { return }
            withAnimation(MZAnimation.bouncy) {
                isOn.toggle()
            }
            HapticManager.shared.trigger(isOn ? .success : .light)
        } label: {
            ZStack {
                // Track
                Capsule()
                    .fill(isOn ? themeManager.primaryColor : themeManager.textSecondaryColor.opacity(0.3))
                    .frame(width: 51, height: 31)

                // Thumb
                Circle()
                    .fill(themeManager.surfaceColor)
                    .frame(width: 27, height: 27)
                    .shadow(color: themeManager.overlayColor.opacity(0.15), radius: 2, y: 1)
                    .offset(x: isOn ? 10 : -10)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Settings Divider

struct SettingsDivider: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Divider()
            .background(themeManager.dividerColor)
            .padding(.leading, 60)
    }
}

// MARK: - Pro Badge Small

struct ProBadgeSmall: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Text("Pro")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(themeManager.textPrimaryColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: [themeManager.warningColor, themeManager.warningColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
    }
}

// MARK: - Pro Upgrade Card

struct ProUpgradeCard: View {
    let action: () -> Void

    @State private var shimmerOffset: CGFloat = -200
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: MZSpacing.md) {
                // Star icon with glow
                ZStack {
                    Circle()
                        .fill(themeManager.warningColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .blur(radius: 8)

                    Image(systemName: "star.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager.warningColor, themeManager.warningColor.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolEffect(.pulse, options: .repeating)
                }

                VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                    Text("الترقية إلى Pro")
                        .font(MZTypography.titleMedium)
                        .foregroundColor(themeManager.textOnPrimaryColor)

                    Text("ثيمات، نوافل، وميزات إضافية")
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.8))
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
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
                    .overlay(
                        // Shimmer effect
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        themeManager.textOnPrimaryColor.opacity(0.2),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: shimmerOffset)
                            .mask(RoundedRectangle(cornerRadius: 16))
                    )
            )
            .shadow(color: themeManager.primaryColor.opacity(0.4), radius: 12, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @StateObject var themeManager = ThemeManager()

    VStack(spacing: 20) {
        SettingsSectionHeader(icon: "bell.fill", title: "الإشعارات", iconColor: themeManager.errorColor)

        SettingsCard {
            SettingsRow(icon: "moon.stars.fill", iconColor: themeManager.primaryColor, title: "النوافل")
            SettingsDivider()
            SettingsToggleRow(icon: "bell.badge.fill", iconColor: themeManager.errorColor, title: "الإشعارات", isOn: .constant(true))
        }

        ProUpgradeCard { }
    }
    .padding()
    .background(themeManager.backgroundColor)
    .environmentObject(themeManager)
}
