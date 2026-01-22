//
//  GamificationDashboardView.swift
//  MizanApp
//
//  Comprehensive gamification dashboard showing progress, missions, and achievements.
//

import SwiftUI

struct GamificationDashboardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appEnvironment: AppEnvironment

    @State private var selectedTab: GamificationTab = .progress
    @State private var showLevelUpCelebration = false

    private var progressionService: ProgressionService {
        appEnvironment.progressionService
    }

    private var achievementService: AchievementService {
        appEnvironment.achievementService
    }

    private var missionService: MissionService {
        appEnvironment.missionService
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                themeManager.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector

                    // Content based on selected tab
                    ScrollView {
                        LazyVStack(spacing: MZSpacing.md) {
                            switch selectedTab {
                            case .progress:
                                progressSection
                            case .missions:
                                missionsSection
                            case .achievements:
                                achievementsSection
                            }
                        }
                        .padding(.horizontal, MZSpacing.screenPadding)
                        .padding(.vertical, MZSpacing.md)
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(isPresented: $showLevelUpCelebration) {
            if let orbitConfig = progressionService.getCurrentOrbitConfig() {
                OrbitLevelUpCelebration(
                    progressionService: progressionService,
                    orbitConfig: orbitConfig,
                    onDismiss: {
                        showLevelUpCelebration = false
                    }
                )
                .environmentObject(themeManager)
            }
        }
        .onReceive(progressionService.$didLevelUp) { leveledUp in
            if leveledUp {
                showLevelUpCelebration = true
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: MZSpacing.xs) {
            ForEach(GamificationTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                    HapticManager.shared.trigger(.selection)
                } label: {
                    HStack(spacing: MZSpacing.xxs) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14))
                        Text(tab.title)
                            .font(MZTypography.labelMedium)
                    }
                    .foregroundColor(selectedTab == tab ? themeManager.textOnPrimaryColor : themeManager.textSecondaryColor)
                    .padding(.horizontal, MZSpacing.md)
                    .padding(.vertical, MZSpacing.sm)
                    .background(
                        Capsule()
                            .fill(selectedTab == tab ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
                    )
                }
            }
        }
        .padding(.horizontal, MZSpacing.screenPadding)
        .padding(.vertical, MZSpacing.sm)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: MZSpacing.lg) {
            // Orbit status card
            orbitStatusCard

            // Mass and multipliers
            massStatisticsCard

            // Velocity tier
            if let tier = progressionService.getCurrentVelocityTier() {
                VelocityTierIndicator(
                    tier: tier,
                    currentStreak: progressionService.currentStreak
                )
                .environmentObject(themeManager)
            }

            // Combo indicator
            if progressionService.currentCombo > 0 {
                ComboIndicator(
                    comboCount: progressionService.currentCombo,
                    multiplier: progressionService.comboMultiplier
                )
                .environmentObject(themeManager)
            }
        }
    }

    private var orbitStatusCard: some View {
        VStack(spacing: MZSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                    Text("Current Orbit")
                        .font(MZTypography.labelSmall)
                        .foregroundColor(themeManager.textSecondaryColor)

                    if let orbit = progressionService.getCurrentOrbitConfig() {
                        Text(orbit.localizedTitle)
                            .font(MZTypography.titleLarge)
                            .foregroundColor(themeManager.textPrimaryColor)
                    }
                }

                Spacer()

                // Orbit level badge
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [themeManager.primaryColor.opacity(0.3), themeManager.primaryColor.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)

                    Circle()
                        .fill(themeManager.primaryColor)
                        .frame(width: 44, height: 44)

                    Text("\(progressionService.currentOrbit)")
                        .font(MZTypography.titleLarge)
                        .foregroundColor(themeManager.textOnPrimaryColor)
                }
            }

            // Progress to next orbit
            if let nextOrbit = progressionService.getNextOrbitConfig() {
                VStack(spacing: MZSpacing.xs) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.surfaceSecondaryColor)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.primaryColor)
                                .frame(width: geometry.size.width * progressionService.getOrbitProgress(), height: 8)
                        }
                    }
                    .frame(height: 8)

                    // Progress text
                    HStack {
                        Text("\(Int(progressionService.currentMass)) Mass")
                            .font(MZTypography.labelSmall)
                            .foregroundColor(themeManager.textSecondaryColor)

                        Spacer()

                        Text("\(nextOrbit.massRequired) Mass to \(nextOrbit.localizedTitle)")
                            .font(MZTypography.labelSmall)
                            .foregroundColor(themeManager.textTertiaryColor)
                    }
                }
            }
        }
        .padding(MZSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                .fill(themeManager.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                        .stroke(themeManager.primaryColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var massStatisticsCard: some View {
        HStack(spacing: MZSpacing.md) {
            // Total Mass
            statisticItem(
                title: "Total Mass",
                value: "\(Int(progressionService.currentMass))",
                icon: "atom"
            )

            Divider()
                .frame(height: 40)

            // Streak
            statisticItem(
                title: "Streak",
                value: "\(progressionService.currentStreak)",
                icon: "flame"
            )

            Divider()
                .frame(height: 40)

            // Combo
            statisticItem(
                title: "Combo",
                value: "\(progressionService.currentCombo)",
                icon: "bolt"
            )
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .fill(themeManager.surfaceColor)
        )
    }

    private func statisticItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: MZSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(themeManager.primaryColor)

            Text(value)
                .font(MZTypography.dataMedium)
                .foregroundColor(themeManager.textPrimaryColor)

            Text(title)
                .font(MZTypography.labelSmall)
                .foregroundColor(themeManager.textTertiaryColor)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Missions Section

    private var missionsSection: some View {
        VStack(spacing: MZSpacing.md) {
            // Header
            DailyMissionsHeader(
                completedCount: missionService.todaysMissions.filter { $0.isCompleted }.count,
                totalCount: missionService.todaysMissions.count
            )
            .environmentObject(themeManager)

            // Mission cards
            ForEach(missionService.todaysMissions) { mission in
                MissionCard(mission: mission)
                    .environmentObject(themeManager)
            }

            if missionService.todaysMissions.isEmpty {
                emptyStateView(
                    icon: "target",
                    message: "No missions available today"
                )
            }
        }
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(spacing: MZSpacing.lg) {
            // Unlocked achievements
            if !achievementService.unlockedAchievements.isEmpty {
                VStack(alignment: .leading, spacing: MZSpacing.sm) {
                    Text("Unlocked")
                        .font(MZTypography.titleSmall)
                        .foregroundColor(themeManager.textPrimaryColor)
                        .padding(.leading, MZSpacing.xs)

                    ForEach(achievementService.unlockedAchievements, id: \.id) { achievement in
                        AchievementCard(
                            achievement: achievement,
                            isUnlocked: true,
                            progress: 1.0
                        )
                        .environmentObject(themeManager)
                    }
                }
            }

            // Locked achievements
            if !achievementService.lockedAchievements.isEmpty {
                VStack(alignment: .leading, spacing: MZSpacing.sm) {
                    Text("In Progress")
                        .font(MZTypography.titleSmall)
                        .foregroundColor(themeManager.textPrimaryColor)
                        .padding(.leading, MZSpacing.xs)

                    ForEach(achievementService.lockedAchievements, id: \.id) { achievement in
                        AchievementCard(
                            achievement: achievement,
                            isUnlocked: false,
                            progress: achievementService.getProgress(for: achievement)
                        )
                        .environmentObject(themeManager)
                    }
                }
            }

            if achievementService.unlockedAchievements.isEmpty && achievementService.lockedAchievements.isEmpty {
                emptyStateView(
                    icon: "trophy",
                    message: "No achievements available"
                )
            }
        }
    }

    private func emptyStateView(icon: String, message: String) -> some View {
        VStack(spacing: MZSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(themeManager.textTertiaryColor)

            Text(message)
                .font(MZTypography.bodyMedium)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MZSpacing.xxl)
    }
}

// MARK: - Tab Enum

enum GamificationTab: String, CaseIterable {
    case progress
    case missions
    case achievements

    var title: String {
        switch self {
        case .progress: return "Progress"
        case .missions: return "Missions"
        case .achievements: return "Achievements"
        }
    }

    var icon: String {
        switch self {
        case .progress: return "chart.line.uptrend.xyaxis"
        case .missions: return "target"
        case .achievements: return "trophy"
        }
    }
}
