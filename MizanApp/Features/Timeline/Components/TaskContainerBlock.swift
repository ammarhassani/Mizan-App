//
//  TaskContainerBlock.swift
//  Mizan
//
//  Unified task container that displays tasks with nested prayers/nawafil inside.
//  Implements "prayer priority" - prayers are always visible as pause points within tasks.
//

import SwiftUI

/// A task block that can contain prayers and nawafil nested inside
/// Used when a task overlaps with prayer times
struct TaskContainerBlock: View {
    let task: Task
    let containedPrayers: [PrayerTime]
    let containedNawafil: [NawafilPrayer]
    let hasTaskOverlap: Bool
    var overlappingTaskCount: Int = 0
    var onToggleCompletion: (() -> Void)? = nil
    var onPrayerTap: ((PrayerTime) -> Void)? = nil

    @State private var isExpanded: Bool = true  // Default expanded
    @EnvironmentObject var themeManager: ThemeManager

    private var taskColor: Color { Color(hex: task.colorHex) }
    private var hasContainedItems: Bool {
        !containedPrayers.isEmpty || !containedNawafil.isEmpty
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Time column (shows start AND end time)
            taskTimeColumn

            // Main card with overlap warning effect
            VStack(spacing: 0) {
                // Header (always visible)
                taskHeader

                // Contained items (prayers/nawafil) - shown when expanded
                if hasContainedItems && isExpanded {
                    containedItemsSection
                }
            }
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(borderOverlay)
            .overlapWarning(hasOverlap: hasTaskOverlap, overlapCount: overlappingTaskCount)
            .shadow(color: taskColor.opacity(0.12), radius: 8, y: 4)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .opacity(task.isCompleted ? 0.7 : 1.0)
    }

    // MARK: - Time Column (simple start/end time display)

    private var taskTimeColumn: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Start time
            Text(task.startTime.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(taskColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            // End time
            if let endTime = task.endTime {
                Text(endTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(taskColor.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(width: 55, alignment: .trailing)
    }

    // MARK: - Task Header

    private var taskHeader: some View {
        HStack(spacing: 12) {
            // Checkbox
            taskCheckbox

            // Task info
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.textPrimaryColor)
                    .strikethrough(task.isCompleted)
                    .lineLimit(2)

                // Category chip
                HStack(spacing: 4) {
                    Image(systemName: task.category.icon)
                        .font(.system(size: 9))
                    Text(task.category.nameArabic)
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(taskColor.opacity(0.9))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(taskColor.opacity(0.12)))
            }

            Spacer()

            // Expand/collapse (only if has contained items)
            if hasContainedItems {
                expandCollapseButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Task Checkbox

    private var taskCheckbox: some View {
        Button {
            onToggleCompletion?()
            HapticManager.shared.trigger(.success)
        } label: {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(task.isCompleted ? themeManager.successColor : taskColor)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expand/Collapse Button

    private var expandCollapseButton: some View {
        Button {
            withAnimation(MZAnimation.gentle) {
                isExpanded.toggle()
            }
            HapticManager.shared.trigger(.selection)
        } label: {
            HStack(spacing: 4) {
                Text("\(containedPrayers.count) صلوات")
                    .font(.system(size: 9, weight: .medium))
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(themeManager.textSecondaryColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(themeManager.surfaceSecondaryColor))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Contained Items Section

    private var containedItemsSection: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(themeManager.textSecondaryColor.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 12)

            VStack(spacing: 6) {
                // Prayers
                ForEach(containedPrayers) { prayer in
                    ContainedPrayerChip(prayer: prayer, onTap: {
                        onPrayerTap?(prayer)
                    })
                    .environmentObject(themeManager)
                }

                // Nawafil
                ForEach(containedNawafil) { nawafil in
                    ContainedNawafilChip(nawafil: nawafil)
                        .environmentObject(themeManager)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        ZStack {
            // Frosted base
            themeManager.surfaceColor.opacity(0.7)

            // Top highlight
            LinearGradient(
                colors: [
                    themeManager.textOnPrimaryColor.opacity(0.08),
                    themeManager.textOnPrimaryColor.opacity(0.02),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )

            // Accent tint
            taskColor.opacity(0.05)
        }
    }

    // MARK: - Border Overlay

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(
                LinearGradient(
                    colors: [
                        taskColor.opacity(0.35),
                        taskColor.opacity(0.15),
                        taskColor.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

}

// MARK: - Contained Prayer Chip (nested inside task)

struct ContainedPrayerChip: View {
    let prayer: PrayerTime
    var onTap: (() -> Void)? = nil
    @EnvironmentObject var themeManager: ThemeManager

    private var prayerColor: Color { Color(hex: prayer.colorHex) }
    private var prayerStatus: PrayerStatus {
        if prayer.hasPassed { return .passed }
        else if prayer.isCurrently { return .current }
        else { return .upcoming }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Prayer icon
            Image(systemName: prayer.prayerType.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(prayerColor)

            // Prayer name
            Text(prayer.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.textPrimaryColor)

            Spacer()

            // Time
            Text(prayer.adhanTime.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(prayerColor)

            // Status badge
            Text(prayerStatus.arabicLabel)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(themeManager.textOnPrimaryColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(statusColor))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(prayerColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(prayerColor.opacity(0.25), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
            HapticManager.shared.trigger(.selection)
        }
    }

    private var statusColor: Color {
        switch prayerStatus {
        case .passed: return themeManager.textSecondaryColor
        case .current: return prayerColor
        case .upcoming: return themeManager.primaryColor
        }
    }
}

// MARK: - Contained Nawafil Chip (nested inside task)

struct ContainedNawafilChip: View {
    let nawafil: NawafilPrayer
    @EnvironmentObject var themeManager: ThemeManager

    private var nawafilColor: Color { Color(hex: nawafil.colorHex) }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 10))
                .foregroundColor(nawafilColor.opacity(0.8))

            Text(nawafil.arabicName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.textPrimaryColor.opacity(0.9))

            Text("•")
                .foregroundColor(themeManager.textSecondaryColor)

            Text("\(nawafil.rakaat) \(nawafil.rakaat.arabicRakaat)")
                .font(.system(size: 10))
                .foregroundColor(themeManager.textSecondaryColor)

            Spacer()

            Image(systemName: nawafil.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundColor(nawafil.isCompleted ? themeManager.successColor : themeManager.textSecondaryColor.opacity(0.4))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(nawafilColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(nawafilColor.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                )
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        TaskContainerBlock(
            task: {
                let t = Task(title: "Work Project", duration: 480, category: .work)
                t.scheduleAt(time: Date())
                return t
            }(),
            containedPrayers: [],
            containedNawafil: [],
            hasTaskOverlap: false
        )

        TaskContainerBlock(
            task: {
                let t = Task(title: "Full Day Meeting", duration: 480, category: .work)
                t.scheduleAt(time: Date())
                return t
            }(),
            containedPrayers: [
                PrayerTime(date: Date(), prayerType: .dhuhr, adhanTime: Date(), calculationMethod: .mwl),
                PrayerTime(date: Date(), prayerType: .asr, adhanTime: Date().addingTimeInterval(4 * 3600), calculationMethod: .mwl)
            ],
            containedNawafil: [],
            hasTaskOverlap: true
        )
    }
    .padding()
    .background(Color.black.opacity(0.9))
    .environmentObject(ThemeManager())
}
