//
//  ProgressionService.swift
//  MizanApp
//
//  Core gamification service for Mass, Orbit, Light Velocity, and Combo systems.
//

import Foundation
import SwiftData
import Combine
import os

@MainActor
final class ProgressionService: ObservableObject {
    // MARK: - Published State

    @Published private(set) var currentMass: Double = 0
    @Published private(set) var currentOrbit: Int = 1
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var currentCombo: Int = 0
    @Published private(set) var comboMultiplier: Double = 1.0

    /// Triggered when orbit level increases
    @Published var didLevelUp: Bool = false
    @Published var newOrbitLevel: Int = 0

    /// Recent mass gain for animation
    @Published var recentMassGain: Double = 0

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private var userSettings: UserSettings?
    private var config: GamificationConfiguration? {
        ConfigurationManager.shared.gamificationConfig
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserSettings()
        syncFromUserSettings()
    }

    private func loadUserSettings() {
        let descriptor = FetchDescriptor<UserSettings>()
        userSettings = try? modelContext.fetch(descriptor).first
    }

    private func syncFromUserSettings() {
        guard let settings = userSettings else { return }
        currentMass = settings.massTotalPoints
        currentOrbit = settings.orbitCurrentLevel
        currentStreak = settings.lightVelocityStreak
        currentCombo = settings.comboCurrentCount

        // Calculate combo multiplier from count
        if let config = config {
            let increment = config.comboSystem.multiplierIncrement
            let max = config.comboSystem.maxMultiplier
            comboMultiplier = min(1.0 + (Double(currentCombo) * increment), max)
        }
    }

    // MARK: - Mass Earning

    /// Award Mass for completing a task
    func awardMassForTask(duration: Int) {
        guard let config = config else { return }

        let base = config.massSystem.baseEarnings
        // Scale mass based on duration (10-50 range scaled by duration 15-120 min)
        let durationFactor = min(1.0, max(0.2, Double(duration) / 60.0))
        let baseMass = Double(base.taskCompletionMin) + (Double(base.taskCompletionMax - base.taskCompletionMin) * durationFactor)

        let finalMass = applyMultipliers(to: baseMass)
        addMass(finalMass)

        // Update combo
        incrementCombo()

        // Update task count for achievements
        userSettings?.totalTasksCompleted += 1
        save()
    }

    /// Award Mass for completing a prayer
    func awardMassForPrayer(isOnTime: Bool, isFajr: Bool) {
        guard let config = config else { return }

        let base = config.massSystem.baseEarnings
        let baseMass = Double(isOnTime ? base.prayerInWindow : base.prayerOutsideWindow)

        var finalMass = applyMultipliers(to: baseMass)

        // Dawn bonus for Fajr
        if isFajr && isOnTime {
            finalMass += Double(config.massSystem.bonuses.dawnBonus)
            userSettings?.totalFajrOnTime += 1
        }

        addMass(finalMass)
        incrementCombo()

        if isOnTime {
            userSettings?.totalPrayersOnTime += 1
        }

        save()
    }

    /// Award Mass for completing Nawafil
    func awardMassForNawafil() {
        guard let config = config else { return }

        let baseMass = Double(config.massSystem.baseEarnings.nawafilCompletion)
        let finalMass = applyMultipliers(to: baseMass)

        addMass(finalMass)
        incrementCombo()
    }

    /// Award daily login bonus
    func awardDailyLoginBonus() {
        guard let config = config else { return }

        let baseMass = Double(config.massSystem.baseEarnings.dailyLogin)
        addMass(baseMass)

        // Update streak
        updateStreak()
    }

    /// Award bonus for perfect day (all 5 prayers on time)
    func awardPerfectDayBonus() {
        guard let config = config else { return }

        let bonusMass = Double(config.massSystem.bonuses.fullWeek) // Reusing this for perfect day
        addMass(bonusMass * 0.5) // Half of full week bonus

        userSettings?.totalPerfectDays += 1
        save()
    }

    /// Direct mass award (for achievement rewards)
    func awardDirectMass(_ amount: Double) {
        addMass(amount)
    }

    // MARK: - Private Mass Helpers

    private func addMass(_ amount: Double) {
        currentMass += amount
        userSettings?.massTotalPoints = currentMass
        recentMassGain = amount

        // Check for orbit advancement
        checkOrbitAdvancement()

        save()

        // Reset recent gain after delay
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                self.recentMassGain = 0
            }
        }
    }

    private func applyMultipliers(to baseMass: Double) -> Double {
        var mass = baseMass

        // Apply combo multiplier
        mass *= comboMultiplier

        // Apply light velocity multiplier
        if let velocityTier = getCurrentVelocityTier() {
            mass *= velocityTier.multiplier
        }

        return mass
    }

    // MARK: - Orbit Progression

    private func checkOrbitAdvancement() {
        guard let config = config else { return }

        // Find the highest orbit we qualify for
        let qualifyingOrbits = config.orbits.filter { currentMass >= Double($0.massRequired) }
        guard let highestOrbit = qualifyingOrbits.max(by: { $0.level < $1.level }) else { return }

        if highestOrbit.level > currentOrbit {
            let previousOrbit = currentOrbit
            currentOrbit = highestOrbit.level
            userSettings?.orbitCurrentLevel = currentOrbit

            // Award orbit advancement bonus
            let bonus = Double(config.massSystem.bonuses.orbitAdvancement)
            currentMass += bonus
            userSettings?.massTotalPoints = currentMass

            // Trigger level up notification
            didLevelUp = true
            newOrbitLevel = currentOrbit

            // Haptic feedback
            HapticManager.shared.trigger(.success)

            MizanLogger.shared.lifecycle.info("Orbit advanced from \(previousOrbit) to \(self.currentOrbit)")

            // Reset level up flag after delay
            _Concurrency.Task {
                try? await _Concurrency.Task.sleep(nanoseconds: 4_000_000_000)
                await MainActor.run {
                    self.didLevelUp = false
                }
            }

            save()
        }
    }

    /// Get current orbit configuration
    func getCurrentOrbitConfig() -> OrbitConfig? {
        config?.orbits.first { $0.level == currentOrbit }
    }

    /// Get next orbit configuration
    func getNextOrbitConfig() -> OrbitConfig? {
        config?.orbits.first { $0.level > currentOrbit }
    }

    /// Get progress to next orbit (0.0 - 1.0)
    func getOrbitProgress() -> Double {
        guard let current = getCurrentOrbitConfig(),
              let next = getNextOrbitConfig() else { return 1.0 }

        let currentRequired = Double(current.massRequired)
        let nextRequired = Double(next.massRequired)
        let progress = (currentMass - currentRequired) / (nextRequired - currentRequired)

        return min(1.0, max(0.0, progress))
    }

    // MARK: - Light Velocity (Streak)

    private func updateStreak() {
        guard let settings = userSettings else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = settings.lastActivityDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
            } else if daysDiff > 1 {
                // Streak broken
                currentStreak = 1
            }
            // daysDiff == 0: same day, no change
        } else {
            // First activity
            currentStreak = 1
        }

        settings.lightVelocityStreak = currentStreak
        settings.lastActivityDate = today

        // Update longest streak
        if currentStreak > settings.lightVelocityLongestStreak {
            settings.lightVelocityLongestStreak = currentStreak
        }

        save()
    }

    /// Get current velocity tier based on streak
    func getCurrentVelocityTier() -> VelocityTierConfig? {
        config?.lightVelocity.tiers.first {
            currentStreak >= $0.minDays && currentStreak <= $0.maxDays
        }
    }

    // MARK: - Combo System

    private func incrementCombo() {
        guard let config = config else { return }

        let now = Date()

        // Check if combo has expired
        if let lastComboDate = userSettings?.comboLastActivityDate {
            let secondsSinceLastCombo = now.timeIntervalSince(lastComboDate)
            if secondsSinceLastCombo > Double(config.comboSystem.timeoutSeconds) {
                // Combo expired, reset
                currentCombo = 0
            }
        }

        // Increment combo
        currentCombo += 1
        userSettings?.comboCurrentCount = currentCombo
        userSettings?.comboLastActivityDate = now

        // Recalculate multiplier
        let increment = config.comboSystem.multiplierIncrement
        let max = config.comboSystem.maxMultiplier
        comboMultiplier = min(1.0 + (Double(currentCombo) * increment), max)

        save()
    }

    /// Reset combo (called when timeout expires)
    func resetComboIfExpired() {
        guard let config = config,
              let lastComboDate = userSettings?.comboLastActivityDate else { return }

        let secondsSinceLastCombo = Date().timeIntervalSince(lastComboDate)
        if secondsSinceLastCombo > Double(config.comboSystem.timeoutSeconds) {
            currentCombo = 0
            comboMultiplier = 1.0
            userSettings?.comboCurrentCount = 0
            save()
        }
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext.save()
        } catch {
            MizanLogger.shared.lifecycle.error("Failed to save gamification data: \(error)")
        }
    }
}
