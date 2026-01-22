//
//  TaskMassCard.swift
//  MizanApp
//
//  Task card displaying potential Mass reward - "Floating Mass" in the timeline.
//

import SwiftUI

struct TaskMassCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    let task: Task
    let onComplete: () -> Void
    let onTap: () -> Void

    // Calculate potential Mass based on duration
    private var potentialMass: Int {
        let duration = task.duration
        guard duration > 0 else { return 10 }
        // Scale from 10-50 based on duration (15-120 min range)
        let durationFactor = min(1.0, max(0.2, Double(duration) / 60.0))
        return Int(10.0 + (40.0 * durationFactor))
    }

    // Category color
    private var categoryColor: Color {
        if let userCategory = task.userCategory {
            return Color(hex: userCategory.colorHex) ?? themeManager.primaryColor
        }
        return themeManager.primaryColor
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MZSpacing.md) {
                // Category indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(categoryColor)
                    .frame(width: 4, height: 40)

                VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                    // Task title
                    Text(task.title)
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(task.isCompleted ? themeManager.textTertiaryColor : themeManager.textPrimaryColor)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)

                    // Duration and category
                    HStack(spacing: MZSpacing.sm) {
                        if task.duration > 0 {
                            Text("\(task.duration) min")
                                .font(MZTypography.labelSmall)
                                .foregroundColor(themeManager.textSecondaryColor)
                        }

                        if let userCategory = task.userCategory {
                            Text(userCategory.name)
                                .font(MZTypography.labelSmall)
                                .foregroundColor(categoryColor)
                        }

                        Spacer()

                        if !task.isCompleted {
                            Text("+\(potentialMass) Mass")
                                .font(MZTypography.labelSmall)
                                .foregroundColor(themeManager.successColor)
                        }
                    }
                }

                Spacer()

                // Completion checkbox
                Button(action: onComplete) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(task.isCompleted ? themeManager.successColor : themeManager.surfaceColor)
                            .frame(width: 28, height: 28)

                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(themeManager.textOnPrimaryColor)
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(themeManager.textSecondaryColor.opacity(0.5), lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                        }
                    }
                }
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                    .fill(themeManager.surfaceColor.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                            .stroke(themeManager.primaryColor.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
