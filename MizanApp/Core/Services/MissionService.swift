//
//  MissionService.swift
//  MizanApp
//
//  Service for daily mission generation and tracking.
//

import Foundation
import SwiftData
import Combine
import os

@MainActor
final class MissionService: ObservableObject {
    // MARK: - Published State

    @Published private(set) var todaysMissions: [DailyMission] = []

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
        generateTodaysMissions()
    }

    func setProgressionService(_ service: ProgressionService) {
        self.progressionService = service
    }

    private func loadUserSettings() {
        let descriptor = FetchDescriptor<UserSettings>()
        userSettings = try? modelContext.fetch(descriptor).first
    }

    // MARK: - Mission Generation

    /// Generate today's missions (called at Fajr time or app launch)
    func generateTodaysMissions() {
        guard let config = config, let settings = userSettings else { return }

        let dateKey = todayDateKey()
        let completedToday = settings.completedMissions[dateKey] ?? []

        // Select 3 random missions for today
        // Use a seeded random based on date for consistency
        let seed = dateKey.hashValue
        var rng = SeededRandomNumberGenerator(seed: UInt64(abs(seed)))

        let shuffled = config.dailyMissions.shuffled(using: &rng)
        let selectedConfigs = Array(shuffled.prefix(3))

        todaysMissions = selectedConfigs.map { missionConfig in
            DailyMission(
                config: missionConfig,
                isCompleted: completedToday.contains(missionConfig.id),
                currentProgress: getCurrentProgress(for: missionConfig)
            )
        }
    }

    private func getCurrentProgress(for mission: MissionConfig) -> Int {
        guard userSettings != nil else { return 0 }

        switch mission.requirementType {
        case "prayers_on_time_today":
            return getTodayPrayersOnTime()
        case "tasks_completed_today":
            return getTodayTasksCompleted()
        case "fajr_on_time_today":
            return getTodayFajrCompleted() ? 1 : 0
        default:
            return 0
        }
    }

    // MARK: - Progress Tracking

    /// Update mission progress (call after relevant actions)
    func updateMissionProgress() {
        for i in todaysMissions.indices {
            let mission = todaysMissions[i]
            if !mission.isCompleted {
                let newProgress = getCurrentProgress(for: mission.config)
                todaysMissions[i].currentProgress = newProgress

                // Check if mission is now complete
                if newProgress >= mission.config.requirementValue {
                    completeMission(at: i)
                }
            }
        }
    }

    private func completeMission(at index: Int) {
        guard index < todaysMissions.count else { return }

        let mission = todaysMissions[index]
        todaysMissions[index].isCompleted = true

        // Award mass reward
        let reward = Double(mission.config.massReward)
        progressionService?.awardDirectMass(reward)

        // Track completion
        let dateKey = todayDateKey()
        var completedToday = userSettings?.completedMissions[dateKey] ?? []
        completedToday.append(mission.config.id)
        userSettings?.completedMissions[dateKey] = completedToday

        // Haptic feedback
        HapticManager.shared.trigger(.success)

        save()

        MizanLogger.shared.lifecycle.info("Mission completed: \(mission.config.id)")
    }

    // MARK: - Helpers

    private func todayDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func getTodayPrayersOnTime() -> Int {
        // This would integrate with PrayerTimeService
        // Simplified placeholder
        return 0
    }

    private func getTodayTasksCompleted() -> Int {
        // This would integrate with task completion tracking
        // Simplified placeholder
        return 0
    }

    private func getTodayFajrCompleted() -> Bool {
        // This would integrate with PrayerTimeService
        // Simplified placeholder
        return false
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext.save()
        } catch {
            MizanLogger.shared.lifecycle.error("Failed to save mission data: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct DailyMission: Identifiable {
    let id: String
    let config: MissionConfig
    var isCompleted: Bool
    var currentProgress: Int

    init(config: MissionConfig, isCompleted: Bool, currentProgress: Int) {
        self.id = config.id
        self.config = config
        self.isCompleted = isCompleted
        self.currentProgress = currentProgress
    }

    var progress: Double {
        Double(currentProgress) / Double(config.requirementValue)
    }
}

// MARK: - Seeded RNG for consistent daily mission selection

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // Simple LCG
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
