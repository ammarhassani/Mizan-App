//
//  TimelineView.swift
//  Mizan
//
//  Main timeline view with hour markers, prayers, and tasks
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    // MARK: - Environment
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager

    @Environment(\.modelContext) private var modelContext

    // MARK: - State
    @State private var selectedDate = Date()
    @State private var scrollToNowOnAppear = true
    @State private var nawafilRefreshID = UUID()

    // MARK: - Queries
    @Query private var allTasks: [Task]
    @Query private var allPrayers: [PrayerTime]
    @Query private var allNawafil: [NawafilPrayer]

    // MARK: - Constants
    private let minPrayerBlockHeight: CGFloat = 110
    private let minNawafilBlockHeight: CGFloat = 60
    private let minTaskBlockHeight: CGFloat = 50
    private let contentHourHeight: CGFloat = 100 // Points per hour within content regions

    // MARK: - Timeline Segments (computed)

    private var timelineSegments: [TimelineSegment] {
        buildSegments(
            prayers: todayPrayers,
            tasks: todayTasks,
            nawafil: todayNawafil,
            dayStart: timelineBounds.start,
            dayEnd: timelineBounds.end
        )
    }

    // MARK: - Computed Properties

    private var timelineBounds: (start: Date, end: Date) {
        TimelineHelper.timelineBounds(for: selectedDate, prayers: todayPrayers)
    }

    private var todayTasks: [Task] {
        let calendar = Calendar.current
        return allTasks.filter { task in
            guard let scheduledTime = task.scheduledStartTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: selectedDate)
        }
    }

    private var todayPrayers: [PrayerTime] {
        let calendar = Calendar.current
        let filtered = allPrayers.filter { prayer in
            calendar.isDate(prayer.date, inSameDayAs: selectedDate)
        }

        // Deduplicate: keep only one prayer per prayer type
        // Prefer the user's current calculation method, otherwise take first
        var seen: [PrayerType: PrayerTime] = [:]
        let userMethod = appEnvironment.userSettings.calculationMethod

        for prayer in filtered.sorted(by: { $0.adhanTime < $1.adhanTime }) {
            if seen[prayer.prayerType] == nil {
                seen[prayer.prayerType] = prayer
            } else if prayer.calculationMethod == userMethod {
                // Replace with preferred calculation method
                seen[prayer.prayerType] = prayer
            }
        }

        return seen.values.sorted { $0.adhanTime < $1.adhanTime }
    }

    private var todayNawafil: [NawafilPrayer] {
        let calendar = Calendar.current
        let filtered = allNawafil.filter { nawafil in
            calendar.isDate(nawafil.date, inSameDayAs: selectedDate) && !nawafil.isDismissed
        }

        // Deduplicate: keep only one nawafil per type
        var seen: [String: NawafilPrayer] = [:]
        for nawafil in filtered.sorted(by: { $0.suggestedTime < $1.suggestedTime }) {
            if seen[nawafil.nawafilType] == nil {
                seen[nawafil.nawafilType] = nawafil
            }
        }

        return seen.values.sorted { $0.suggestedTime < $1.suggestedTime }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                themeManager.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Date Selector
                    dateSelector
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(themeManager.surfaceColor)

                    // Timeline
                    timelineScrollView
                }
            }
            .navigationTitle("الجدول")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Reset to today and scroll will happen via onAppear
                        selectedDate = Date()
                    } label: {
                        Image(systemName: "clock")
                            .foregroundColor(themeManager.primaryColor)
                    }
                }
            }
        }
        .onChange(of: appEnvironment.nawafilRefreshTrigger) { _, _ in
            // Force view to re-query nawafil data
            nawafilRefreshID = UUID()
        }
        .id(nawafilRefreshID)
    }

    // MARK: - Date Selector

    private var dateSelector: some View {
        HStack(spacing: 12) {
            // Previous day
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeManager.primaryColor)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Date display
            VStack(spacing: 4) {
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.textPrimaryColor)

                if let hijriDate = todayPrayers.first?.hijriDate {
                    Text(hijriDate)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            Spacer()

            // Next day
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeManager.primaryColor)
                    .frame(width: 44, height: 44)
            }

            // Today button
            if !Calendar.current.isDateInToday(selectedDate) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = Date()
                    }
                } label: {
                    Text("اليوم")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.primaryColor)
                        .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Timeline ScrollView

    private var timelineScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    ForEach(timelineSegments) { segment in
                        segmentView(for: segment)
                            .id(segment.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: selectedDate) { _, _ in
                scrollToCurrentPrayer(proxy: proxy)
            }
            .onAppear {
                if scrollToNowOnAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        scrollToCurrentPrayer(proxy: proxy)
                    }
                }
            }
        }
    }

    // MARK: - Segment Rendering

    @ViewBuilder
    private func segmentView(for segment: TimelineSegment) -> some View {
        switch segment.segmentType {
        case .gap:
            GapSegmentView(segment: segment)

        case .prayer:
            if let prayer = segment.prayer {
                // Find attached pre and post nawafil for this prayer
                let preNawafil = todayNawafil.first { nawafil in
                    nawafil.attachedToPrayer == prayer.prayerType &&
                    nawafil.attachmentPosition == .before &&
                    !nawafil.isDismissed
                }
                let postNawafil = todayNawafil.first { nawafil in
                    nawafil.attachedToPrayer == prayer.prayerType &&
                    nawafil.attachmentPosition == .after &&
                    !nawafil.isDismissed
                }

                TimelinePrayerBlock(
                    prayer: prayer,
                    minHeight: minPrayerBlockHeight,
                    preNawafil: preNawafil,
                    postNawafil: postNawafil
                )
                .background(
                    // Prayer gate gradient - subtle glow behind the prayer block
                    PrayerGateGradient(colorHex: prayer.colorHex)
                )
            }

        case .nawafil:
            if let nawafil = segment.nawafil {
                TimelineNawafilBlock(nawafil: nawafil, minHeight: minNawafilBlockHeight)
            }

        case .task:
            if let task = segment.task {
                TimelineTaskBlock(task: task, minHeight: minTaskBlockHeight)
            }
        }
    }

    private func scrollToCurrentPrayer(proxy: ScrollViewProxy) {
        // Find the next upcoming prayer or current prayer segment
        let now = Date()

        // Find a segment that is current or upcoming
        if let currentSegment = timelineSegments.first(where: { segment in
            segment.segmentType == .prayer && segment.endTime > now
        }) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                proxy.scrollTo(currentSegment.id, anchor: .center)
            }
        }
    }

}

// MARK: - Timeline Prayer Block

struct TimelinePrayerBlock: View {
    let prayer: PrayerTime
    let minHeight: CGFloat
    var preNawafil: NawafilPrayer? = nil
    var postNawafil: NawafilPrayer? = nil

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Time column
            VStack(alignment: .trailing, spacing: 4) {
                Text(prayer.adhanTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: prayer.colorHex))
            }
            .frame(width: 55, alignment: .trailing)
            .padding(.top, 14)

            // Main prayer block
            VStack(alignment: .leading, spacing: 0) {
                // Header with prayer name
                HStack(spacing: 10) {
                    Image(systemName: prayer.prayerType.icon)
                        .font(.system(size: 20, weight: .medium))

                    Text(prayer.displayName)
                        .font(.system(size: 18, weight: .bold))

                    Spacer()

                    if prayer.isJummah {
                        Text("جمعة")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(4)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Athan info row
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 10))
                    Text("الأذان")
                        .font(.system(size: 11, weight: .medium))
                    Text("•")
                        .font(.system(size: 8))
                    Text("\(prayer.iqamaOffset) د انتظار")
                        .font(.system(size: 10))
                    Spacer()
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

                // Pre-nawafil (if any)
                if let pre = preNawafil {
                    nawafilRow(nawafil: pre, label: "قبل")
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                }

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 1)
                    .padding(.horizontal, 12)

                // Iqama info row
                HStack(spacing: 6) {
                    Image(systemName: "person.wave.2.fill")
                        .font(.system(size: 10))
                    Text("الإقامة")
                        .font(.system(size: 11, weight: .medium))
                    Text("•")
                        .font(.system(size: 8))
                    Text("\(prayer.duration) د صلاة")
                        .font(.system(size: 10))
                    Spacer()
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 6)

                // Post-nawafil (if any)
                if let post = postNawafil {
                    nawafilRow(nawafil: post, label: "بعد")
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }

                // Bottom padding if no post nawafil
                if postNawafil == nil {
                    Spacer().frame(height: 4)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: prayer.colorHex),
                                Color(hex: prayer.colorHex).opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .frame(minHeight: minHeight)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    // MARK: - Nawafil Row

    private func nawafilRow(nawafil: NawafilPrayer, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 9))
            Text(nawafil.arabicName)
                .font(.system(size: 10, weight: .medium))
            Text("•")
                .font(.system(size: 7))
            Text("\(nawafil.rakaat) ركعات")
                .font(.system(size: 9))
            Spacer()
            Image(systemName: nawafil.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundColor(nawafil.isCompleted ? .green : .white.opacity(0.4))
        }
        .foregroundColor(.white.opacity(0.85))
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.12))
        .cornerRadius(6)
    }
}

// MARK: - Timeline Nawafil Block

struct TimelineNawafilBlock: View {
    let nawafil: NawafilPrayer
    let minHeight: CGFloat

    @EnvironmentObject var themeManager: ThemeManager

    // Dynamic block height
    private var blockHeight: CGFloat {
        let contentHeight = CGFloat(nawafil.duration) / 60.0 * 100
        return max(minHeight, contentHeight)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Time label on the left
            Text(nawafil.suggestedTime.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: nawafil.colorHex))
                .frame(width: 55, alignment: .trailing)

            // Nawafil block content
            nawafilBlockContent
        }
        .frame(height: blockHeight)
        .padding(.horizontal, 4)
        .opacity(nawafil.isCompleted ? 0.5 : 1.0)
    }

    private var nawafilBlockContent: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: nawafil.icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: nawafil.colorHex))

            // Name and details
            VStack(alignment: .leading, spacing: 2) {
                Text(nawafil.arabicName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: nawafil.colorHex))

                Text("\(nawafil.rakaat) ركعة • \(nawafil.duration) دقيقة")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: nawafil.colorHex).opacity(0.7))
            }

            Spacer()

            // Badge
            Text("نافلة")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(hex: nawafil.colorHex))
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Color(hex: nawafil.colorHex).opacity(0.12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .foregroundColor(Color(hex: nawafil.colorHex).opacity(0.5))
        )
        .cornerRadius(themeManager.cornerRadius(.medium))
    }
}


// MARK: - Timeline Task Block

struct TimelineTaskBlock: View {
    let task: Task
    let minHeight: CGFloat

    @EnvironmentObject var themeManager: ThemeManager

    private var blockHeight: CGFloat {
        let contentHeight = CGFloat(task.duration) / 60.0 * 100
        return max(minHeight, contentHeight)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Time label on the left
            Text(task.startTime.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: task.colorHex))
                .frame(width: 55, alignment: .trailing)

            // Task block content
            taskBlockContent
        }
        .frame(height: blockHeight)
        .padding(.horizontal, 4)
        .opacity(task.isCompleted ? 0.6 : 1.0)
    }

    private var taskBlockContent: some View {
        HStack(spacing: 10) {
            // Completion checkbox
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(task.isCompleted ? .green : Color(hex: task.colorHex))

            // Task details
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.textPrimaryColor)
                    .strikethrough(task.isCompleted)

                Text("\(task.duration) دقيقة")
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.textSecondaryColor)
            }

            Spacer()

            // Category icon
            Image(systemName: task.category.icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: task.colorHex).opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: task.colorHex).opacity(0.1))
        .cornerRadius(themeManager.cornerRadius(.medium))
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .stroke(Color(hex: task.colorHex).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Timeline Segment

/// Represents a segment of the timeline (content block or gap)
struct TimelineSegment: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let segmentType: SegmentType
    let prayer: PrayerTime?
    let task: Task?
    let nawafil: NawafilPrayer?

    enum SegmentType {
        case prayer
        case task
        case nawafil
        case gap
    }

    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    /// Whether this is a compressed gap that should show indicator
    var isCollapsedGap: Bool {
        segmentType == .gap && durationMinutes >= 30
    }

    /// Format the gap duration for display
    var gapDurationText: String {
        let hours = durationMinutes / 60
        let mins = durationMinutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)س \(mins)د"
        } else if hours > 0 {
            return "\(hours) ساعة"
        } else {
            return "\(mins) دقيقة"
        }
    }

    init(startTime: Date, endTime: Date, segmentType: SegmentType, prayer: PrayerTime? = nil, task: Task? = nil, nawafil: NawafilPrayer? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.segmentType = segmentType
        self.prayer = prayer
        self.task = task
        self.nawafil = nawafil
    }
}

// MARK: - Build Segments Extension

extension TimelineView {
    /// Build timeline segments from prayers, tasks, and nawafil
    func buildSegments(
        prayers: [PrayerTime],
        tasks: [Task],
        nawafil: [NawafilPrayer],
        dayStart: Date,
        dayEnd: Date
    ) -> [TimelineSegment] {
        // Collect all timeline items with their time ranges
        struct ItemEntry {
            let start: Date
            let end: Date
            let type: TimelineSegment.SegmentType
            let prayer: PrayerTime?
            let task: Task?
            let nawafil: NawafilPrayer?
        }

        var items: [ItemEntry] = []

        // Add prayers
        for prayer in prayers {
            items.append(ItemEntry(
                start: prayer.effectiveStartTime,
                end: prayer.effectiveEndTime,
                type: .prayer,
                prayer: prayer,
                task: nil,
                nawafil: nil
            ))
        }

        // Add tasks with scheduled times
        for task in tasks where task.scheduledStartTime != nil {
            items.append(ItemEntry(
                start: task.startTime,
                end: task.endTime,
                type: .task,
                prayer: nil,
                task: task,
                nawafil: nil
            ))
        }

        // Add nawafil - only standalone nawafil (not attached to prayers)
        // Attached rawatib nawafil will be shown inside prayer blocks
        for naf in nawafil where !naf.isDismissed && naf.isStandalone {
            items.append(ItemEntry(
                start: naf.startTime,
                end: naf.endTime,
                type: .nawafil,
                prayer: nil,
                task: nil,
                nawafil: naf
            ))
        }

        // Sort by start time
        items.sort { $0.start < $1.start }

        var segments: [TimelineSegment] = []
        var currentTime = dayStart

        for item in items {
            // Skip items that start before current time (overlapping)
            if item.start < currentTime {
                // Handle overlap: if item extends past currentTime, still add it
                if item.end > currentTime {
                    segments.append(TimelineSegment(
                        startTime: item.start,
                        endTime: item.end,
                        segmentType: item.type,
                        prayer: item.prayer,
                        task: item.task,
                        nawafil: item.nawafil
                    ))
                    currentTime = item.end
                }
                continue
            }

            // Add gap segment if there's time before this item
            if item.start > currentTime {
                segments.append(TimelineSegment(
                    startTime: currentTime,
                    endTime: item.start,
                    segmentType: .gap
                ))
            }

            // Add content segment for this item
            segments.append(TimelineSegment(
                startTime: item.start,
                endTime: item.end,
                segmentType: item.type,
                prayer: item.prayer,
                task: item.task,
                nawafil: item.nawafil
            ))

            currentTime = item.end
        }

        // Add final gap if needed
        if currentTime < dayEnd {
            segments.append(TimelineSegment(
                startTime: currentTime,
                endTime: dayEnd,
                segmentType: .gap
            ))
        }

        return segments
    }
}

// MARK: - Gap Segment View

struct GapSegmentView: View {
    let segment: TimelineSegment

    @EnvironmentObject var themeManager: ThemeManager

    /// Height for this gap segment
    var height: CGFloat {
        let duration = segment.durationMinutes
        if duration < 30 {
            // Short gaps: proportional height (100pt/hr)
            return CGFloat(duration) / 60.0 * 100
        } else if duration < 120 {
            // Medium gaps: compressed
            return 50
        } else {
            // Large gaps: collapsed
            return 40
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Time labels
            VStack(alignment: .trailing, spacing: 2) {
                Text(segment.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .medium))

                if segment.isCollapsedGap {
                    Text("···")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(themeManager.textSecondaryColor.opacity(0.5))
                }

                Text(segment.endTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(themeManager.textSecondaryColor.opacity(0.6))
            .frame(width: 55, alignment: .trailing)

            // Dashed line with duration
            VStack(spacing: 0) {
                Rectangle()
                    .fill(themeManager.textSecondaryColor.opacity(0.15))
                    .frame(height: 1)

                if segment.isCollapsedGap {
                    Text(segment.gapDurationText)
                        .font(.system(size: 10))
                        .foregroundStyle(themeManager.textSecondaryColor.opacity(0.4))
                        .padding(.vertical, 4)
                }

                Rectangle()
                    .fill(themeManager.textSecondaryColor.opacity(0.15))
                    .frame(height: 1)
            }

            Spacer()
        }
        .frame(height: height)
        .padding(.leading, 4)
    }
}

// MARK: - Prayer Gate Gradient

/// Subtle gradient background for prayer blocks
/// Creates a "prayer time window" visual effect
struct PrayerGateGradient: View {
    let colorHex: String

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Horizontal glow extending beyond the block
                LinearGradient(
                    colors: [
                        Color(hex: colorHex).opacity(0),
                        Color(hex: colorHex).opacity(0.08),
                        Color(hex: colorHex).opacity(0.08),
                        Color(hex: colorHex).opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                // Vertical fade at top and bottom
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            Color(hex: colorHex).opacity(0),
                            Color(hex: colorHex).opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 16)

                    Spacer()

                    LinearGradient(
                        colors: [
                            Color(hex: colorHex).opacity(0.05),
                            Color(hex: colorHex).opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 16)
                }
            }
        }
        .cornerRadius(16)
        .padding(.horizontal, -8) // Extend slightly beyond the block
        .padding(.vertical, -4)
    }
}

// MARK: - Preview

#Preview {
    TimelineView()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
        .modelContainer(AppEnvironment.preview().modelContainer)
}
