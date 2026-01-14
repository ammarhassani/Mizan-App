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
    @State private var dragOffset: CGFloat = 0
    @State private var timelineScale: CGFloat = 1.0
    @State private var showScaleIndicator = false

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

    /// Returns the next approaching prayer within 30 minutes
    private var approachingPrayer: (prayer: PrayerTime, minutes: Int)? {
        guard Calendar.current.isDateInToday(selectedDate) else { return nil }

        let now = Date()
        for prayer in todayPrayers {
            let minutesUntil = Int(prayer.adhanTime.timeIntervalSince(now) / 60)
            if minutesUntil > 0 && minutesUntil <= 30 {
                return (prayer, minutesUntil)
            }
        }
        return nil
    }

    /// Returns the current prayer period based on time
    private var currentPrayerPeriod: PrayerType? {
        guard Calendar.current.isDateInToday(selectedDate) else { return nil }

        let now = Date()
        var currentPrayer: PrayerType? = nil

        for prayer in todayPrayers.reversed() {
            if now >= prayer.adhanTime {
                currentPrayer = prayer.prayerType
                break
            }
        }

        return currentPrayer
    }

    /// Scaled hour height based on zoom level
    private var scaledHourHeight: CGFloat {
        contentHourHeight * timelineScale
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Background with prayer atmosphere
                themeManager.backgroundColor
                    .ignoresSafeArea()

                // Prayer atmosphere (subtle gradient only - particles disabled for performance)
                // TODO: Re-enable particles once performance is optimized
                // if Calendar.current.isDateInToday(selectedDate) {
                //     PrayerTimeAmbience(currentPrayer: currentPrayerPeriod, showParticles: false)
                //         .environmentObject(themeManager)
                // }

                VStack(spacing: 0) {
                    // Cinematic Date Navigator
                    CinematicDateNavigator(
                        selectedDate: $selectedDate,
                        hijriDate: todayPrayers.first?.hijriDate
                    )
                    .environmentObject(themeManager)

                    // Prayer Approaching Banner (if applicable)
                    if let approaching = approachingPrayer {
                        PrayerApproachingIndicator(
                            prayerName: approaching.prayer.displayName,
                            minutesUntil: approaching.minutes,
                            colorHex: approaching.prayer.colorHex
                        )
                        .padding(.top, MZSpacing.xs)
                    }

                    // Timeline with swipe and pinch gestures
                    timelineScrollView
                        .offset(x: dragOffset)
                        .gesture(horizontalSwipeGesture)
                        .timelineGestures(scale: $timelineScale) { location in
                            // Long press handling - could open edit sheet
                            HapticManager.shared.trigger(.medium)
                        }
                }

                // TODO: Re-enable zoom controls once segment height scaling is implemented
                // The zoom feature requires passing scaledHourHeight to all segment views
                // and having them recalculate their heights based on the scale factor.
                // For now, disabled to prevent broken UI.
                //
                // Scale indicator overlay
                // if showScaleIndicator {
                //     VStack {
                //         Spacer()
                //         TimelineScaleIndicator(scale: timelineScale)
                //             .environmentObject(themeManager)
                //             .padding(.bottom, MZSpacing.xl)
                //     }
                // }
                //
                // Zoom controls (optional - positioned at bottom right)
                // VStack {
                //     Spacer()
                //     HStack {
                //         Spacer()
                //         TimelineZoomControls(scale: $timelineScale)
                //             .environmentObject(themeManager)
                //             .padding(MZSpacing.md)
                //     }
                // }
            }
            .navigationTitle("الجدول")
            .navigationBarTitleDisplayMode(.inline)
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
        // TODO: Re-enable when zoom feature is fully implemented
        // .onChange(of: timelineScale) { _, _ in
        //     // Show scale indicator briefly when zooming
        //     showScaleIndicator = true
        //     DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        //         showScaleIndicator = false
        //     }
        // }
        .id(nawafilRefreshID)
    }

    // MARK: - Timeline ScrollView

    private var timelineScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                // Timeline segments
                LazyVStack(spacing: 0) {
                    ForEach(timelineSegments) { segment in
                        segmentView(for: segment)
                            .id(segment.id)
                    }
                }
                // TODO: CurrentTimeIndicator needs proper Y positioning based on time
                // It should be positioned at a calculated offset within the LazyVStack
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: selectedDate) { _, newDate in
                scrollToCurrentPrayer(proxy: proxy)
                // Fetch prayers and generate nawafil for the selected date if needed
                fetchPrayersAndNawafilIfNeeded(for: newDate)
                // Generate recurring task instances for the selected date
                appEnvironment.generateRecurringTaskInstances(for: newDate)
            }
            .onAppear {
                // Always check if prayers need to be fetched when view appears
                fetchPrayersAndNawafilIfNeeded(for: selectedDate)
                // Generate recurring task instances for today
                appEnvironment.generateRecurringTaskInstances(for: selectedDate)

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
                // Jummah has no pre-sunnah, only post-sunnah
                let preNawafil: NawafilPrayer? = prayer.isJummah ? nil : todayNawafil.first { nawafil in
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
                TimelineTaskBlock(
                    task: task,
                    minHeight: minTaskBlockHeight,
                    onToggleCompletion: {
                        toggleTaskCompletion(task)
                    }
                )
            }
        }
    }

    private func toggleTaskCompletion(_ task: Task) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if task.isCompleted {
                task.uncomplete()
            } else {
                task.complete()
            }
            try? modelContext.save()
        }
    }

    // MARK: - Horizontal Swipe Gesture

    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { value in
                // Only respond to horizontal drags (not vertical scrolling)
                let horizontalAmount = abs(value.translation.width)
                let verticalAmount = abs(value.translation.height)

                if horizontalAmount > verticalAmount {
                    // Provide resistance - only show partial offset
                    dragOffset = value.translation.width * 0.3
                }
            }
            .onEnded { value in
                let horizontalAmount = abs(value.translation.width)
                let verticalAmount = abs(value.translation.height)

                // Only trigger navigation if horizontal movement is dominant
                if horizontalAmount > verticalAmount && horizontalAmount > 80 {
                    let calendar = Calendar.current

                    if value.translation.width < 0 {
                        // Swipe left = next day
                        if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedDate = nextDay
                                dragOffset = 0
                            }
                            HapticManager.shared.trigger(.selection)
                            scrollToNowOnAppear = true
                        }
                    } else {
                        // Swipe right = previous day
                        if let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedDate = previousDay
                                dragOffset = 0
                            }
                            HapticManager.shared.trigger(.selection)
                            scrollToNowOnAppear = true
                        }
                    }
                } else {
                    // Not enough movement, reset offset
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
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

    /// Fetch prayers and generate nawafil for a specific date if needed
    private func fetchPrayersAndNawafilIfNeeded(for date: Date) {
        let calendar = Calendar.current

        // Check if prayers already exist for this date
        let prayersForDate = allPrayers.filter { prayer in
            calendar.isDate(prayer.date, inSameDayAs: date)
        }

        if prayersForDate.isEmpty {
            // No prayers for this date - fetch them
            _Concurrency.Task {
                guard let lat = appEnvironment.userSettings.lastKnownLatitude,
                      let lon = appEnvironment.userSettings.lastKnownLongitude else {
                    return
                }

                do {
                    _ = try await appEnvironment.prayerTimeService.fetchPrayerTimes(
                        for: date,
                        latitude: lat,
                        longitude: lon,
                        method: appEnvironment.userSettings.calculationMethod
                    )
                    // After fetching prayers, generate nawafil
                    generateNawafilIfNeeded(for: date)
                } catch {
                    print("❌ Failed to fetch prayers for \(date): \(error)")
                }
            }
        } else {
            // Prayers exist, just generate nawafil if needed
            generateNawafilIfNeeded(for: date)
        }
    }

    /// Generate nawafil for a specific date if they don't already exist
    private func generateNawafilIfNeeded(for date: Date) {
        // Check if nawafil already exist for this date
        let calendar = Calendar.current
        let existingForDate = allNawafil.filter { nawafil in
            calendar.isDate(nawafil.date, inSameDayAs: date)
        }

        // Skip if nawafil already exist for this date
        guard existingForDate.isEmpty else { return }

        // Skip if not Pro or nawafil not enabled
        guard appEnvironment.userSettings.isPro && appEnvironment.userSettings.nawafilEnabled else { return }

        // Get prayers for this date
        let prayersForDate = allPrayers.filter { prayer in
            calendar.isDate(prayer.date, inSameDayAs: date)
        }

        // Skip if no prayers for this date
        guard !prayersForDate.isEmpty else { return }

        // Generate nawafil for this date
        appEnvironment.generateNawafilForDate(date, prayerTimes: prayersForDate)
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 65, alignment: .trailing)
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
                            .foregroundColor(themeManager.textOnPrimaryColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(themeManager.textOnPrimaryColor.opacity(0.25))
                            .cornerRadius(4)
                    }
                }
                .foregroundColor(themeManager.textOnPrimaryColor)
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
                    Text("\(prayer.iqamaOffset) د \(prayer.isJummah ? "خطبة" : "انتظار")")
                        .font(.system(size: 10))
                    Spacer()
                }
                .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.7))
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
                    .fill(themeManager.textOnPrimaryColor.opacity(0.25))
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
                .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.8))
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
                .foregroundColor(nawafil.isCompleted ? themeManager.successColor : themeManager.textOnPrimaryColor.opacity(0.4))
        }
        .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.85))
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(themeManager.textOnPrimaryColor.opacity(0.12))
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 65, alignment: .trailing)

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
                .foregroundColor(themeManager.textOnPrimaryColor)
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
    var onToggleCompletion: (() -> Void)?

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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 65, alignment: .trailing)

            // Task block content
            taskBlockContent
        }
        .frame(height: blockHeight)
        .padding(.horizontal, 4)
        .opacity(task.isCompleted ? 0.6 : 1.0)
    }

    private var taskBlockContent: some View {
        HStack(spacing: 10) {
            // Tappable completion checkbox
            Button {
                onToggleCompletion?()
                HapticManager.shared.trigger(.success)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.isCompleted ? themeManager.successColor : Color(hex: task.colorHex))
            }
            .buttonStyle(.plain)

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
    // TODO: Flow connectors need proper alignment with prayer blocks
    var useFlowConnector: Bool = false

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
        if useFlowConnector && segment.isCollapsedGap {
            // Use organic flow connector for larger gaps
            TimelineFlowConnector(
                height: height,
                showDuration: true,
                durationText: segment.gapDurationText
            )
            .environmentObject(themeManager)
            .padding(.leading, 4)
        } else if useFlowConnector {
            // Simple flow connector for small gaps
            SimpleFlowConnector(height: height)
                .environmentObject(themeManager)
                .padding(.leading, 4)
        } else {
            // Legacy style gap
            legacyGapView
        }
    }

    private var legacyGapView: some View {
        HStack(spacing: 8) {
            // Time labels
            VStack(alignment: .trailing, spacing: 2) {
                Text(segment.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if segment.isCollapsedGap {
                    Text("···")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(themeManager.textSecondaryColor.opacity(0.5))
                }

                Text(segment.endTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(themeManager.textSecondaryColor.opacity(0.6))
            .frame(width: 65, alignment: .trailing)

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
