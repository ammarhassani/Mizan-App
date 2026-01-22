//
//  PrayerAnchorCard.swift
//  MizanApp
//
//  Cosmic-styled prayer card - "Celestial Anchor" in the timeline.
//

import SwiftUI

struct PrayerAnchorCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    let prayer: PrayerTime
    let isCurrentPrayer: Bool
    let isCompleted: Bool
    let onComplete: () -> Void

    // Cosmic names for prayers
    private var cosmicName: String {
        switch prayer.prayerType {
        case .fajr: return "First Light"
        case .dhuhr: return "Solar Zenith"
        case .asr: return "Golden Descent"
        case .maghrib: return "Solar Collapse"
        case .isha: return "Deep Void"
        }
    }

    // Check if currently in the prayer window
    private var isInWindow: Bool {
        let now = Date()
        return now >= prayer.effectiveStartTime && now <= prayer.effectiveEndTime
    }

    private var massReward: Int {
        isInWindow ? 150 : 50
    }

    var body: some View {
        HStack(spacing: MZSpacing.md) {
            // Prayer indicator
            Circle()
                .fill(isCurrentPrayer ? themeManager.warningColor : themeManager.primaryColor.opacity(0.3))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(themeManager.primaryColor, lineWidth: isCurrentPrayer ? 2 : 0)
                        .scaleEffect(isCurrentPrayer ? 1.5 : 1)
                        .opacity(isCurrentPrayer ? 0.5 : 0)
                )

            VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                // Prayer name and time
                HStack {
                    Text(prayer.displayName)
                        .font(MZTypography.titleSmall)
                        .foregroundColor(themeManager.textPrimaryColor)

                    Spacer()

                    Text(prayer.adhanTime.formatted(date: .omitted, time: .shortened))
                        .font(MZTypography.dataMedium)
                        .foregroundColor(themeManager.textPrimaryColor)
                }

                // Cosmic name and Mass reward
                HStack {
                    Text(cosmicName)
                        .font(MZTypography.bodySmall)
                        .foregroundColor(themeManager.textSecondaryColor)

                    Spacer()

                    if isInWindow {
                        Text("+\(massReward) Mass in window")
                            .font(MZTypography.labelSmall)
                            .foregroundColor(themeManager.successColor)
                    } else {
                        Text("+\(massReward) Mass")
                            .font(MZTypography.labelSmall)
                            .foregroundColor(themeManager.textTertiaryColor)
                    }
                }
            }

            // Completion button
            Button(action: onComplete) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? themeManager.successColor : themeManager.surfaceColor)
                        .frame(width: 32, height: 32)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(themeManager.textOnPrimaryColor)
                    }
                }
            }
            .disabled(isCompleted)
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .fill(themeManager.surfaceColor.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .stroke(
                            isCurrentPrayer ? themeManager.warningColor.opacity(0.5) : themeManager.primaryColor.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: isCurrentPrayer ? themeManager.warningColor.opacity(0.2) : .clear, radius: 8)
    }
}
