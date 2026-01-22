//
//  MissionCard.swift
//  MizanApp
//
//  Daily mission card with cosmic styling and progress tracking.
//

import SwiftUI

struct MissionCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    let mission: DailyMission

    // Get icon name based on requirement type
    private var missionIconName: String {
        switch mission.config.requirementType {
        case "prayers_on_time_today":
            return "moon.stars"
        case "tasks_completed_today":
            return "checkmark.circle"
        case "fajr_on_time_today":
            return "sunrise"
        default:
            return "target"
        }
    }

    var body: some View {
        HStack(spacing: MZSpacing.md) {
            // Mission icon with progress ring
            missionIcon

            // Mission info
            VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                // Title
                Text(mission.config.localizedTitle)
                    .font(MZTypography.bodyLarge)
                    .foregroundColor(mission.isCompleted ? themeManager.textSecondaryColor : themeManager.textPrimaryColor)
                    .strikethrough(mission.isCompleted)

                // Description
                Text(mission.config.localizedDescription)
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textTertiaryColor)
                    .lineLimit(2)

                // Progress text
                if !mission.isCompleted {
                    Text("\(mission.currentProgress)/\(mission.config.requirementValue)")
                        .font(MZTypography.dataMedium)
                        .foregroundColor(themeManager.primaryColor)
                }
            }

            Spacer()

            // Mass reward
            VStack(spacing: 2) {
                if mission.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.successColor)
                } else {
                    Text("+\(mission.config.massReward)")
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.successColor)
                }
                Text("Mass")
                    .font(MZTypography.labelSmall)
                    .foregroundColor(mission.isCompleted ? themeManager.successColor : themeManager.textTertiaryColor)
            }
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .fill(mission.isCompleted ? themeManager.successColor.opacity(0.1) : themeManager.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .stroke(mission.isCompleted ? themeManager.successColor.opacity(0.3) : themeManager.surfaceSecondaryColor, lineWidth: 1)
                )
        )
    }

    private var missionIcon: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(themeManager.surfaceSecondaryColor, lineWidth: 3)
                .frame(width: 48, height: 48)

            Circle()
                .trim(from: 0, to: mission.progress)
                .stroke(
                    mission.isCompleted ? themeManager.successColor : themeManager.primaryColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 48, height: 48)
                .rotationEffect(.degrees(-90))

            // Icon
            Image(systemName: missionIconName)
                .font(.system(size: 20))
                .foregroundColor(mission.isCompleted ? themeManager.successColor : themeManager.primaryColor)
        }
    }
}

// MARK: - Mission Completion Celebration

struct MissionCompletedBanner: View {
    @EnvironmentObject var themeManager: ThemeManager

    let mission: DailyMission
    @Binding var isVisible: Bool

    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0

    var body: some View {
        if isVisible {
            HStack(spacing: MZSpacing.sm) {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.warningColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Mission Complete!")
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textPrimaryColor)
                    Text(mission.config.localizedTitle)
                        .font(MZTypography.labelSmall)
                        .foregroundColor(themeManager.textSecondaryColor)
                }

                Spacer()

                Text("+\(mission.config.massReward)")
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.successColor)
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                    .fill(themeManager.surfaceColor)
                    .shadow(color: themeManager.overlayColor.opacity(0.2), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, MZSpacing.screenPadding)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    offset = 0
                    opacity = 1
                }
                // Auto dismiss
                _Concurrency.Task {
                    try? await _Concurrency.Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = -100
                            opacity = 0
                        }
                        _Concurrency.Task {
                            try? await _Concurrency.Task.sleep(nanoseconds: 300_000_000)
                            await MainActor.run {
                                isVisible = false
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Daily Missions Header

struct DailyMissionsHeader: View {
    @EnvironmentObject var themeManager: ThemeManager

    let completedCount: Int
    let totalCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                Text("Daily Missions")
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.textPrimaryColor)

                Text("\(completedCount)/\(totalCount) completed")
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textSecondaryColor)
            }

            Spacer()

            // All complete indicator
            if completedCount == totalCount {
                HStack(spacing: MZSpacing.xxs) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                    Text("All Done!")
                        .font(MZTypography.labelMedium)
                }
                .foregroundColor(themeManager.successColor)
            }
        }
        .padding(.horizontal, MZSpacing.screenPadding)
        .padding(.vertical, MZSpacing.sm)
    }
}
