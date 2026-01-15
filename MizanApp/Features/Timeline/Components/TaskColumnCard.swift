//
//  TaskColumnCard.swift
//  Mizan
//
//  Compact task card for side-by-side column layout within a cluster.
//  Displays task with proportional positioning based on start time within the cluster.
//

import SwiftUI

/// Compact task card for side-by-side column layout
struct TaskColumnCard: View {
    let task: Task
    let clusterStart: Date
    let clusterEnd: Date
    let clusterHeight: CGFloat
    var onToggleCompletion: (() -> Void)?

    @EnvironmentObject var themeManager: ThemeManager
    @State private var checkScale: CGFloat = 1.0

    private var taskColor: Color { Color(hex: task.colorHex) }

    /// Height based on task duration relative to cluster
    private var cardHeight: CGFloat {
        let totalClusterMinutes = clusterEnd.timeIntervalSince(clusterStart) / 60
        guard totalClusterMinutes > 0 else { return 60 }

        let taskMinutes = CGFloat(task.duration)
        let proportionalHeight = (taskMinutes / CGFloat(totalClusterMinutes)) * clusterHeight
        return max(60, proportionalHeight)
    }

    /// Top offset based on task start relative to cluster start
    private var topOffset: CGFloat {
        let totalClusterMinutes = clusterEnd.timeIntervalSince(clusterStart) / 60
        guard totalClusterMinutes > 0 else { return 0 }

        let offsetMinutes = task.startTime.timeIntervalSince(clusterStart) / 60
        let proportionalOffset = (CGFloat(offsetMinutes) / CGFloat(totalClusterMinutes)) * clusterHeight
        return max(0, proportionalOffset)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Spacer for positioning based on start time
            if topOffset > 0 {
                Spacer().frame(height: topOffset)
            }

            // The actual card
            taskCard
                .frame(height: cardHeight)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private var taskCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with checkbox and title
            HStack(alignment: .top, spacing: 8) {
                // Compact checkbox
                Button {
                    triggerCheckAnimation()
                    onToggleCompletion?()
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundColor(task.isCompleted ? themeManager.successColor : taskColor)
                        .scaleEffect(checkScale)
                }
                .buttonStyle(.plain)

                // Title
                Text(task.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.textPrimaryColor)
                    .strikethrough(task.isCompleted, color: themeManager.textSecondaryColor)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            // Time and category at bottom
            HStack {
                // Time range
                VStack(alignment: .leading, spacing: 1) {
                    Text(task.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(taskColor)

                    if let endTime = task.endTime {
                        Text(endTime.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 8, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(taskColor.opacity(0.7))
                    }
                }

                Spacer()

                // Category icon
                Image(systemName: task.category.icon)
                    .font(.system(size: 10))
                    .foregroundColor(taskColor.opacity(0.7))
            }
        }
        .padding(10)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(cardBorder)
        .opacity(task.isCompleted ? 0.7 : 1.0)
    }

    private var cardBackground: some View {
        ZStack {
            themeManager.surfaceColor.opacity(0.8)
            taskColor.opacity(0.08)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(taskColor.opacity(0.3), lineWidth: 1)
    }

    private func triggerCheckAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            checkScale = 0.8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                checkScale = 1.1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                checkScale = 1.0
            }
        }
        HapticManager.shared.trigger(.success)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Single task card
        TaskColumnCard(
            task: {
                let task = Task(title: "اجتماع العمل", duration: 60, category: .work)
                task.scheduleAt(time: Date())
                return task
            }(),
            clusterStart: Date(),
            clusterEnd: Date().addingTimeInterval(2 * 60 * 60),
            clusterHeight: 200
        )
        .frame(width: 150)

        // Completed task
        TaskColumnCard(
            task: {
                let task = Task(title: "تمارين صباحية", duration: 30, category: .health)
                task.scheduleAt(time: Date())
                task.isCompleted = true
                return task
            }(),
            clusterStart: Date(),
            clusterEnd: Date().addingTimeInterval(2 * 60 * 60),
            clusterHeight: 200
        )
        .frame(width: 150)
    }
    .padding()
    .background(Color.black.opacity(0.9))
    .environmentObject(ThemeManager())
}
