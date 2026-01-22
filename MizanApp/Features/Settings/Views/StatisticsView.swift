//
//  StatisticsView.swift
//  MizanApp
//
//  Comprehensive statistics view showing prayer and task history.
//

import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appEnvironment: AppEnvironment

    @State private var selectedTimeRange: TimeRange = .week

    var body: some View {
        ScrollView {
            VStack(spacing: MZSpacing.lg) {
                // Time range selector
                timeRangeSelector

                // Summary cards
                summarySection

                // Prayer statistics
                prayerStatisticsSection

                // Task statistics
                taskStatisticsSection

                // Gamification statistics (Pro only)
                if appEnvironment.userSettings.isPro {
                    gamificationStatisticsSection
                }
            }
            .padding(.horizontal, MZSpacing.screenPadding)
            .padding(.vertical, MZSpacing.md)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        HStack(spacing: MZSpacing.xs) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeRange = range
                    }
                    HapticManager.shared.trigger(.selection)
                } label: {
                    Text(range.title)
                        .font(MZTypography.labelMedium)
                        .foregroundColor(selectedTimeRange == range ? themeManager.textOnPrimaryColor : themeManager.textSecondaryColor)
                        .padding(.horizontal, MZSpacing.md)
                        .padding(.vertical, MZSpacing.sm)
                        .background(
                            Capsule()
                                .fill(selectedTimeRange == range ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
                        )
                }
            }
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        HStack(spacing: MZSpacing.md) {
            summaryCard(
                title: "Prayers",
                value: "\(appEnvironment.userSettings.totalPrayersOnTime)",
                subtitle: "on time",
                icon: "moon.stars.fill",
                color: themeManager.primaryColor
            )

            summaryCard(
                title: "Tasks",
                value: "\(appEnvironment.userSettings.totalTasksCompleted)",
                subtitle: "completed",
                icon: "checkmark.circle.fill",
                color: themeManager.successColor
            )

            if appEnvironment.userSettings.isPro {
                summaryCard(
                    title: "Mass",
                    value: "\(Int(appEnvironment.userSettings.massTotalPoints))",
                    subtitle: "earned",
                    icon: "atom",
                    color: themeManager.warningColor
                )
            }
        }
    }

    private func summaryCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: MZSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(MZTypography.dataLarge)
                .foregroundColor(themeManager.textPrimaryColor)

            VStack(spacing: 2) {
                Text(title)
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textSecondaryColor)
                Text(subtitle)
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textTertiaryColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .fill(themeManager.surfaceColor)
        )
    }

    // MARK: - Prayer Statistics

    private var prayerStatisticsSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("Prayer Statistics")
                .font(MZTypography.titleSmall)
                .foregroundColor(themeManager.textPrimaryColor)

            VStack(spacing: MZSpacing.sm) {
                statisticRow(
                    title: "Perfect Days",
                    value: "\(appEnvironment.userSettings.totalPerfectDays)",
                    subtitle: "all prayers on time",
                    icon: "star.fill",
                    color: themeManager.warningColor
                )

                statisticRow(
                    title: "Fajr Prayers",
                    value: "\(appEnvironment.userSettings.totalFajrOnTime)",
                    subtitle: "on time",
                    icon: "sunrise.fill",
                    color: themeManager.primaryColor
                )

                statisticRow(
                    title: "Current Streak",
                    value: "\(appEnvironment.userSettings.lightVelocityStreak)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: themeManager.errorColor
                )

                statisticRow(
                    title: "Longest Streak",
                    value: "\(appEnvironment.userSettings.lightVelocityLongestStreak)",
                    subtitle: "days",
                    icon: "trophy.fill",
                    color: themeManager.successColor
                )
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                    .fill(themeManager.surfaceColor)
            )
        }
    }

    // MARK: - Task Statistics

    private var taskStatisticsSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("Task Statistics")
                .font(MZTypography.titleSmall)
                .foregroundColor(themeManager.textPrimaryColor)

            VStack(spacing: MZSpacing.sm) {
                statisticRow(
                    title: "Tasks Completed",
                    value: "\(appEnvironment.userSettings.totalTasksCompleted)",
                    subtitle: "total",
                    icon: "checkmark.circle.fill",
                    color: themeManager.successColor
                )
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                    .fill(themeManager.surfaceColor)
            )
        }
    }

    // MARK: - Gamification Statistics

    private var gamificationStatisticsSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("Gamification")
                .font(MZTypography.titleSmall)
                .foregroundColor(themeManager.textPrimaryColor)

            VStack(spacing: MZSpacing.sm) {
                statisticRow(
                    title: "Current Orbit",
                    value: "\(appEnvironment.progressionService.currentOrbit)",
                    subtitle: appEnvironment.progressionService.getCurrentOrbitConfig()?.localizedTitle ?? "",
                    icon: "circle.circle.fill",
                    color: themeManager.primaryColor
                )

                statisticRow(
                    title: "Total Mass",
                    value: "\(Int(appEnvironment.progressionService.currentMass))",
                    subtitle: "earned",
                    icon: "atom",
                    color: themeManager.warningColor
                )

                statisticRow(
                    title: "Achievements",
                    value: "\(appEnvironment.achievementService.unlockedAchievements.count)",
                    subtitle: "unlocked",
                    icon: "trophy.fill",
                    color: themeManager.successColor
                )
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                    .fill(themeManager.surfaceColor)
            )
        }
    }

    // MARK: - Helper Views

    private func statisticRow(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
            }

            Spacer()

            // Value
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(MZTypography.dataMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
                Text(subtitle)
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textTertiaryColor)
            }
        }
    }
}

// MARK: - Time Range

enum TimeRange: String, CaseIterable {
    case week
    case month
    case year
    case allTime

    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        case .allTime: return "All Time"
        }
    }
}
