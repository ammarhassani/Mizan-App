//
//  TaskClusterView.swift
//  Mizan
//
//  Renders overlapping tasks and prayers as a chronological event stream.
//  Uses an agenda/list approach where each event (task start, task end, prayer)
//  appears as a row sorted by time.
//

import SwiftUI

// MARK: - Cluster Event Model

/// Represents a moment in time within a cluster
enum ClusterEventType {
    case taskStart(Task)
    case taskEnd(Task)
    case prayer(PrayerTime)
    case nawafil(NawafilPrayer)
}

struct ClusterEvent: Identifiable {
    let id = UUID()
    let time: Date
    let type: ClusterEventType

    /// Sort priority for events at the same time
    /// Lower = appears first (prayers before task ends)
    var sortPriority: Int {
        switch type {
        case .taskStart: return 0
        case .prayer: return 1
        case .nawafil: return 2
        case .taskEnd: return 3
        }
    }
}

// MARK: - Task Cluster View

/// Renders overlapping tasks and prayers as a chronological agenda list
struct TaskClusterView: View {
    let tasks: [Task]
    let clusterStart: Date
    let clusterEnd: Date
    let containedPrayers: [PrayerTime]
    let containedNawafil: [NawafilPrayer]
    var onToggleCompletion: ((Task) -> Void)?
    var onPrayerTap: ((PrayerTime) -> Void)?
    var onTaskTap: ((Task) -> Void)?
    var onTaskDelete: ((Task) -> Void)?

    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Computed Properties

    /// Generate chronological events from tasks and prayers
    private var events: [ClusterEvent] {
        var allEvents: [ClusterEvent] = []

        // Add task start/end events
        for task in tasks {
            allEvents.append(ClusterEvent(
                time: task.startTime,
                type: .taskStart(task)
            ))
            if let endTime = task.endTime {
                allEvents.append(ClusterEvent(
                    time: endTime,
                    type: .taskEnd(task)
                ))
            }
        }

        // Add prayer events
        for prayer in containedPrayers {
            allEvents.append(ClusterEvent(
                time: prayer.adhanTime,
                type: .prayer(prayer)
            ))
        }

        // Add nawafil events
        for nawafil in containedNawafil {
            allEvents.append(ClusterEvent(
                time: nawafil.suggestedTime,
                type: .nawafil(nawafil)
            ))
        }

        // Sort by time, then by priority
        return allEvents.sorted { lhs, rhs in
            if lhs.time == rhs.time {
                return lhs.sortPriority < rhs.sortPriority
            }
            return lhs.time < rhs.time
        }
    }

    /// Grouped task ends (for collapsing multiple ends at same time)
    private var groupedEvents: [ClusterEvent] {
        // For now, return events as-is
        // Future optimization: collapse consecutive task ends
        events
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            clusterHeader

            // Event list with active task indicators
            VStack(spacing: 0) {
                ForEach(Array(groupedEvents.enumerated()), id: \.element.id) { index, event in
                    eventRow(for: event)

                    if index < groupedEvents.count - 1 {
                        Divider()
                            .background(themeManager.textSecondaryColor.opacity(0.15))
                            .padding(.leading, 84)  // Align with content (26 dots + 50 time + 8 spacing)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(clusterBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(clusterBorder)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    // MARK: - Cluster Header

    /// Build count text showing only non-zero items
    private var countText: String {
        var parts: [String] = []
        if tasks.count > 0 {
            parts.append("\(tasks.count) مهام")
        }
        if containedPrayers.count > 0 {
            parts.append("\(containedPrayers.count) صلوات")
        }
        return parts.isEmpty ? "" : "(\(parts.joined(separator: "، ")))"
    }

    private var clusterHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.merge")
                .font(.system(size: 11))
                .foregroundColor(themeManager.warningColor)

            Text("متداخلة")  // "Overlapping" in Arabic
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(themeManager.warningColor)

            if !countText.isEmpty {
                Text(countText)
                    .font(.system(size: 10))
                    .foregroundColor(themeManager.textTertiaryColor)
            }

            Spacer()

            // Time range
            HStack(spacing: 3) {
                Text(clusterStart.formatted(date: .omitted, time: .shortened))
                Text("-")
                Text(clusterEnd.formatted(date: .omitted, time: .shortened))
            }
            .font(.system(size: 9, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundColor(themeManager.textSecondaryColor)
        }
        .padding(.bottom, 10)
    }

    // MARK: - Overlap Timeline

    /// Visual timeline showing which tasks are active
    private var overlapTimeline: some View {
        GeometryReader { geometry in
            let totalDuration = clusterEnd.timeIntervalSince(clusterStart)
            let height = geometry.size.height

            ZStack(alignment: .top) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(themeManager.textSecondaryColor.opacity(0.1))
                    .frame(width: 4)

                // Task bars
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    let taskStart = max(task.startTime, clusterStart)
                    let taskEnd = min(task.endTime ?? clusterEnd, clusterEnd)
                    let startOffset = taskStart.timeIntervalSince(clusterStart) / totalDuration
                    let endOffset = taskEnd.timeIntervalSince(clusterStart) / totalDuration

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: task.category.colorHex))
                        .frame(width: 4, height: max(4, CGFloat(endOffset - startOffset) * height))
                        .offset(y: CGFloat(startOffset) * height)
                        .opacity(0.8)
                }
            }
        }
        .frame(width: 4)
    }

    // MARK: - Active Tasks Helper

    /// Returns tasks that are active (running) at a given time
    private func activeTasks(at time: Date) -> [Task] {
        tasks.filter { task in
            let start = task.startTime
            let end = task.endTime ?? clusterEnd
            return time >= start && time < end
        }
    }

    // MARK: - Event Row

    @ViewBuilder
    private func eventRow(for event: ClusterEvent) -> some View {
        HStack(spacing: 8) {
            // Active tasks indicator - colored dots showing which tasks are running
            HStack(spacing: 2) {
                let active = activeTasks(at: event.time)
                ForEach(active, id: \.id) { task in
                    Circle()
                        .fill(Color(hex: task.category.colorHex))
                        .frame(width: 6, height: 6)
                }
                // Pad to maintain consistent width for up to 3 tasks
                if active.count < 3 {
                    ForEach(0..<(3 - active.count), id: \.self) { _ in
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .frame(width: 26, alignment: .leading)

            // Time column
            Text(event.time.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(themeManager.textSecondaryColor)
                .frame(width: 50, alignment: .trailing)

            // Event content
            switch event.type {
            case .taskStart(let task):
                taskStartRow(task)
            case .taskEnd(let task):
                taskEndRow(task)
            case .prayer(let prayer):
                prayerRow(prayer)
            case .nawafil(let nawafil):
                nawafilRow(nawafil)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Task Start Row (Prominent)

    private func taskStartRow(_ task: Task) -> some View {
        HStack(spacing: 8) {
            // Category color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: task.category.colorHex))
                .frame(width: 4, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                // Task name
                Text(task.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.textPrimaryColor)
                    .lineLimit(1)

                // Start indicator
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 8))
                    Text("يبدأ")  // "starts"
                        .font(.system(size: 10))
                }
                .foregroundColor(Color(hex: task.category.colorHex))
            }

            Spacer()

            // Duration badge
            Text(task.duration.formattedDuration)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: task.category.colorHex))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(hex: task.category.colorHex).opacity(0.15))
                )

            // Completion toggle
            Button {
                onToggleCompletion?(task)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.isCompleted ? themeManager.successColor : Color(hex: task.category.colorHex).opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let onTaskTap = onTaskTap {
                HapticManager.shared.trigger(.light)
                onTaskTap(task)
            }
        }
        .contextMenu {
            // Edit option
            Button {
                onTaskTap?(task)
            } label: {
                Label("تعديل", systemImage: "pencil")
            }

            // Toggle completion
            Button {
                onToggleCompletion?(task)
            } label: {
                Label(task.isCompleted ? "إلغاء الإكمال" : "إكمال", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
            }

            Divider()

            // Delete option
            Button(role: .destructive) {
                onTaskDelete?(task)
            } label: {
                Label("حذف", systemImage: "trash")
            }
        }
    }

    // MARK: - Task End Row (Subtle)

    private func taskEndRow(_ task: Task) -> some View {
        HStack(spacing: 8) {
            // Muted color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(themeManager.textTertiaryColor.opacity(0.3))
                .frame(width: 4, height: 20)

            // End indicator
            HStack(spacing: 4) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 7))
                Text("\(task.title) ينتهي")  // "ends"
                    .font(.system(size: 11))
            }
            .foregroundColor(themeManager.textTertiaryColor)

            Spacer()
        }
    }

    // MARK: - Prayer Row (Distinct)

    private func prayerRow(_ prayer: PrayerTime) -> some View {
        Button {
            onPrayerTap?(prayer)
        } label: {
            HStack(spacing: 8) {
                // Prayer icon
                Image(systemName: prayer.prayerType.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: prayer.colorHex))
                    .frame(width: 24)

                // Prayer name
                Text(prayer.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(themeManager.textPrimaryColor)

                Spacer()

                // Status badge
                prayerStatusBadge(prayer)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: prayer.colorHex).opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: prayer.colorHex).opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Nawafil Row

    private func nawafilRow(_ nawafil: NawafilPrayer) -> some View {
        HStack(spacing: 8) {
            // Nawafil icon
            Image(systemName: "moon.stars")
                .font(.system(size: 12))
                .foregroundColor(themeManager.primaryColor.opacity(0.7))
                .frame(width: 24)

            // Name
            Text(nawafil.arabicName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.textSecondaryColor)

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.primaryColor.opacity(0.08))
        )
    }

    // MARK: - Prayer Status Badge

    @ViewBuilder
    private func prayerStatusBadge(_ prayer: PrayerTime) -> some View {
        if prayer.hasPassed {
            Text("فائتة")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(themeManager.textOnPrimaryColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(themeManager.textSecondaryColor.opacity(0.6)))
        } else if prayer.isCurrently {
            Text("الآن")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(themeManager.textOnPrimaryColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(themeManager.successColor))
        } else {
            Circle()
                .fill(Color(hex: prayer.colorHex))
                .frame(width: 8, height: 8)
        }
    }

    // MARK: - Background & Border

    private var clusterBackground: some View {
        ZStack {
            themeManager.surfaceColor.opacity(0.6)

            // Subtle gradient
            LinearGradient(
                colors: [
                    themeManager.warningColor.opacity(0.03),
                    themeManager.surfaceColor.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var clusterBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                themeManager.warningColor.opacity(0.3),
                lineWidth: 1.5
            )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Agenda cluster example
            TaskClusterView(
                tasks: {
                    let work = Task(title: "العمل", duration: 480, category: .work)
                    work.scheduleAt(time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!)

                    let read = Task(title: "القراءة", duration: 60, category: .personal)
                    read.scheduleAt(time: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date())!)

                    let eat = Task(title: "الغداء", duration: 60, category: .health)
                    eat.scheduleAt(time: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date())!)

                    return [work, read, eat]
                }(),
                clusterStart: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
                clusterEnd: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())!,
                containedPrayers: [],
                containedNawafil: []
            )
        }
        .padding()
    }
    .background(Color.black.opacity(0.9))
    .environmentObject(ThemeManager())
}
