//
//  AchievementService.swift
//  MizanApp
//
//  Service for tracking and unlocking achievements.
//

import Foundation
import SwiftData
import Combine
import os

@MainActor
final class AchievementService: ObservableObject {
    // MARK: - Published State

    @Published private(set) var unlockedAchievements: [AchievementConfig] = []
    @Published private(set) var lockedAchievements: [AchievementConfig] = []

    /// Newly unlocked achievement for celebration
    @Published var newlyUnlockedAchievement: AchievementConfig?

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private var userSettings: UserSettings?
    private var progressionService: ProgressionService?

    private var config: GamificationConfiguration? {
        ConfigurationManager.shared.gamificationConfig
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserSettings()
        refreshAchievementLists()
    }

    func setProgressionService(_ service: ProgressionService) {
        self.progressionService = service
    }

    private func loadUserSettings() {
        let descriptor = FetchDescriptor<UserSettings>()
        userSettings = try? modelContext.fetch(descriptor).first
    }

    private func refreshAchievementLists() {
        guard let config = config, let settings = userSettings else { return }

        let unlockedIDs = Set(settings.unlockedAchievementIDs)

        unlockedAchievements = config.achievements.filter { unlockedIDs.contains($0.id) }
        lockedAchievements = config.achievements.filter { !unlockedIDs.contains($0.id) }
    }

    // MARK: - Achievement Checking

    /// Check all achievements and unlock any that are now completed
    func checkAchievements() {
        guard let config = config, let settings = userSettings else { return }

        for achievement in lockedAchievements {
            if isAchievementCompleted(achievement, settings: settings) {
                unlockAchievement(achievement)
            }
        }
    }

    private func isAchievementCompleted(_ achievement: AchievementConfig, settings: UserSettings) -> Bool {
        let value = achievement.requirementValue

        switch achievement.requirementType {
        case "prayer_fajr_count":
            return settings.totalFajrOnTime >= value

        case "perfect_day_count":
            return settings.totalPerfectDays >= value

        case "perfect_streak":
            // This requires tracking perfect day streaks, simplified for now
            return settings.totalPerfectDays >= value

        case "streak_days":
            return settings.lightVelocityStreak >= value || settings.lightVelocityLongestStreak >= value

        case "task_count":
            return settings.totalTasksCompleted >= value

        case "total_mass":
            return settings.massTotalPoints >= Double(value)

        default:
            return false
        }
    }

    // MARK: - Unlock Achievement

    private func unlockAchievement(_ achievement: AchievementConfig) {
        guard var unlockedIDs = userSettings?.unlockedAchievementIDs else { return }

        // Add to unlocked list
        unlockedIDs.append(achievement.id)
        userSettings?.unlockedAchievementIDs = unlockedIDs

        // Award mass reward
        progressionService?.awardDirectMass(Double(achievement.massReward))

        // Trigger celebration
        newlyUnlockedAchievement = achievement
        HapticManager.shared.trigger(.success)

        // Refresh lists
        refreshAchievementLists()

        // Save
        save()

        MizanLogger.shared.lifecycle.info("Achievement unlocked: \(achievement.id)")

        // Reset celebration after delay
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                self.newlyUnlockedAchievement = nil
            }
        }
    }

    // MARK: - Achievement Progress

    /// Get progress for a specific achievement (0.0 - 1.0)
    func getProgress(for achievement: AchievementConfig) -> Double {
        guard let settings = userSettings else { return 0 }

        let required = Double(achievement.requirementValue)
        var current: Double = 0

        switch achievement.requirementType {
        case "prayer_fajr_count":
            current = Double(settings.totalFajrOnTime)
        case "perfect_day_count":
            current = Double(settings.totalPerfectDays)
        case "perfect_streak":
            current = Double(settings.totalPerfectDays)
        case "streak_days":
            current = Double(max(settings.lightVelocityStreak, settings.lightVelocityLongestStreak))
        case "task_count":
            current = Double(settings.totalTasksCompleted)
        case "total_mass":
            current = settings.massTotalPoints
        default:
            return 0
        }

        return min(1.0, current / required)
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext.save()
        } catch {
            MizanLogger.shared.lifecycle.error("Failed to save achievement data: \(error)")
        }
    }
}
