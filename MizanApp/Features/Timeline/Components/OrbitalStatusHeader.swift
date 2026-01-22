//
//  OrbitalStatusHeader.swift
//  MizanApp
//
//  Displays current Orbit level, Mass, Light Velocity streak, and Combo multiplier.
//

import SwiftUI

struct OrbitalStatusHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var progressionService: ProgressionService

    var body: some View {
        VStack(spacing: MZSpacing.sm) {
            // Orbit Level
            Text("ORBIT \(progressionService.currentOrbit)")
                .font(MZTypography.labelLarge)
                .foregroundColor(themeManager.textSecondaryColor)
                .tracking(2)

            // Progress bar to next orbit
            if progressionService.getNextOrbitConfig() != nil {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        Capsule()
                            .fill(themeManager.surfaceColor)
                            .frame(height: 4)

                        // Progress fill
                        Capsule()
                            .fill(themeManager.primaryColor)
                            .frame(width: geometry.size.width * progressionService.getOrbitProgress(), height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, MZSpacing.xl)
            }

            // Orbit Title
            if let currentOrbit = progressionService.getCurrentOrbitConfig() {
                Text(currentOrbit.localizedTitle.uppercased())
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
            }

            // Stats Row
            HStack(spacing: MZSpacing.xl) {
                // Mass
                StatItem(
                    icon: "diamond.fill",
                    value: formatMass(progressionService.currentMass),
                    label: "MASS",
                    color: themeManager.primaryColor
                )

                // Combo Multiplier
                StatItem(
                    icon: "bolt.fill",
                    value: String(format: "%.1fx", progressionService.comboMultiplier),
                    label: "COMBO",
                    color: themeManager.warningColor
                )

                // Light Velocity (Streak)
                StatItem(
                    icon: "flame.fill",
                    value: "\(progressionService.currentStreak)",
                    label: "DAYS",
                    color: themeManager.errorColor
                )
            }
            .padding(.top, MZSpacing.sm)
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                .fill(themeManager.surfaceColor.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                        .stroke(themeManager.primaryColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func formatMass(_ mass: Double) -> String {
        if mass >= 1000 {
            return String(format: "%.1fK", mass / 1000)
        }
        return String(format: "%.0f", mass)
    }
}

struct StatItem: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: MZSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(MZTypography.dataMedium)
                    .foregroundColor(themeManager.textPrimaryColor)

                Text(label)
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
        }
    }
}
