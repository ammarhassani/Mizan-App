//
//  TaskClusterView.swift
//  Mizan
//
//  Renders overlapping tasks side-by-side in columns.
//  Shows tasks happening at the same time in a visual cluster.
//

import SwiftUI

/// Renders overlapping tasks side-by-side in columns
struct TaskClusterView: View {
    let tasks: [Task]
    let clusterStart: Date
    let clusterEnd: Date
    let containedPrayers: [PrayerTime]
    let containedNawafil: [NawafilPrayer]
    var onToggleCompletion: ((Task) -> Void)?
    var onPrayerTap: ((PrayerTime) -> Void)?

    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Computed Properties

    /// Tasks sorted by start time then by duration (longer first)
    private var sortedTasks: [Task] {
        tasks.sorted { lhs, rhs in
            if lhs.startTime == rhs.startTime {
                return lhs.duration > rhs.duration
            }
            return lhs.startTime < rhs.startTime
        }
    }

    /// Total cluster duration in minutes
    private var clusterDuration: Int {
        Int(clusterEnd.timeIntervalSince(clusterStart) / 60)
    }

    /// Cluster height based on duration (100pt per hour)
    private var clusterHeight: CGFloat {
        let minHeight: CGFloat = 100
        let calculatedHeight = CGFloat(clusterDuration) * (100.0 / 60.0)
        return max(minHeight, calculatedHeight)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Main cluster view
            HStack(alignment: .top, spacing: 10) {
                // Time column showing cluster span
                clusterTimeColumn

                // Tasks in side-by-side columns
                tasksColumnsView
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .background(clusterBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(clusterBorder)

            // Show contained prayers if any
            if !containedPrayers.isEmpty {
                containedPrayersSection
            }

            // Show contained nawafil if any
            if !containedNawafil.isEmpty {
                containedNawafilSection
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    // MARK: - Time Column

    private var clusterTimeColumn: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Cluster start
            Text(clusterStart.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(themeManager.primaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            // Overlap indicator
            HStack(spacing: 3) {
                Image(systemName: "arrow.triangle.merge")
                    .font(.system(size: 10))
                Text("×\(tasks.count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundColor(themeManager.warningColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(themeManager.warningColor.opacity(0.12))
            )

            Spacer()

            // Cluster end
            Text(clusterEnd.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(themeManager.textSecondaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 55, alignment: .trailing)
        .frame(minHeight: clusterHeight)
    }

    // MARK: - Tasks Columns

    private var tasksColumnsView: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(sortedTasks) { task in
                TaskColumnCard(
                    task: task,
                    clusterStart: clusterStart,
                    clusterEnd: clusterEnd,
                    clusterHeight: clusterHeight,
                    onToggleCompletion: { onToggleCompletion?(task) }
                )
                .environmentObject(themeManager)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: clusterHeight)
    }

    // MARK: - Background

    private var clusterBackground: some View {
        ZStack {
            themeManager.surfaceColor.opacity(0.5)

            // Subtle gradient to show it's a cluster
            LinearGradient(
                colors: [
                    themeManager.warningColor.opacity(0.03),
                    themeManager.surfaceColor.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var clusterBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                themeManager.warningColor.opacity(0.25),
                lineWidth: 1.5
            )
    }

    // MARK: - Contained Prayers

    private var containedPrayersSection: some View {
        VStack(spacing: 6) {
            ForEach(containedPrayers) { prayer in
                ContainedPrayerChip(prayer: prayer) {
                    onPrayerTap?(prayer)
                }
                .environmentObject(themeManager)
            }
        }
        .padding(.horizontal, 65)  // Align with task columns
        .padding(.vertical, 6)
    }

    // MARK: - Contained Nawafil

    private var containedNawafilSection: some View {
        VStack(spacing: 6) {
            ForEach(containedNawafil) { nawafil in
                ContainedNawafilChip(nawafil: nawafil)
                    .environmentObject(themeManager)
            }
        }
        .padding(.horizontal, 65)
        .padding(.vertical, 6)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Two overlapping tasks
            TaskClusterView(
                tasks: {
                    let task1 = Task(title: "اجتماع العمل", duration: 120, category: .work)
                    task1.scheduleAt(time: Date())

                    let task2 = Task(title: "مكالمة مهمة", duration: 60, category: .personal)
                    task2.scheduleAt(time: Date().addingTimeInterval(60 * 30)) // 30 min later

                    return [task1, task2]
                }(),
                clusterStart: Date(),
                clusterEnd: Date().addingTimeInterval(2 * 60 * 60),
                containedPrayers: [],
                containedNawafil: []
            )

            // Three overlapping tasks
            TaskClusterView(
                tasks: {
                    let task1 = Task(title: "مراجعة التقرير", duration: 90, category: .work)
                    task1.scheduleAt(time: Date())

                    let task2 = Task(title: "رد على الإيميلات", duration: 45, category: .work)
                    task2.scheduleAt(time: Date().addingTimeInterval(30 * 60))

                    let task3 = Task(title: "تمارين سريعة", duration: 30, category: .health)
                    task3.scheduleAt(time: Date().addingTimeInterval(60 * 60))

                    return [task1, task2, task3]
                }(),
                clusterStart: Date(),
                clusterEnd: Date().addingTimeInterval(2.5 * 60 * 60),
                containedPrayers: [],
                containedNawafil: []
            )
        }
        .padding()
    }
    .background(Color.black.opacity(0.9))
    .environmentObject(ThemeManager())
}
