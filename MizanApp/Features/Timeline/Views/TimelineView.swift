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
    @State private var countdownPrayer: PrayerTime? = nil
    @State private var isScrolling = false
    @State private var usePremiumCards = true

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

    // MARK: - Divine Prayer Period

    private var divinePrayerPeriod: PrayerPeriod {
        guard let current = currentPrayerPeriod else {
            // Default based on time of day
            let hour = Calendar.current.component(.hour, from: Date())
            if hour < 5 { return .tahajjud }
            if hour < 7 { return .fajr }
            if hour < 12 { return .dhuhr }
            if hour < 15 { return .asr }
            if hour < 18 { return .maghrib }
            if hour < 20 { return .isha }
            return .tahajjud
        }

        switch current {
        case .fajr: return .fajr
        case .dhuhr: return .dhuhr
        case .asr: return .asr
        case .maghrib: return .maghrib
        case .isha: return .isha
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Divine atmosphere background - ALIVE with visual effects
                if appEnvironment.userSettings.enableBackgroundAmbiance {
                    DivineAtmosphere(
                        prayerPeriod: divinePrayerPeriod,
                        isScrolling: isScrolling,
                        intensity: 1.0,
                        showGeometry: true,
                        showParticles: true,
                        showLightRays: true
                    )
                    .environmentObject(themeManager)
                } else {
                    themeManager.backgroundColor
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    // Cinematic Date Navigator - Divine Time Portal
                    CinematicDateNavigator(
                        selectedDate: $selectedDate,
                        hijriDate: todayPrayers.first?.hijriDate,
                        currentPrayerPeriod: divinePrayerPeriod
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
        .sheet(item: $countdownPrayer) { prayer in
            MesmerizingPrayerCountdown(
                prayer: prayer,
                isActive: true,
                onDismiss: {
                    countdownPrayer = nil
                }
            )
            .environmentObject(themeManager)
        }
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
                .padding(.horizontal, 8)
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
            GapSegmentView(segment: segment, usePremiumFlow: usePremiumCards)
                .environmentObject(themeManager)

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

                let isCurrentPrayer = currentPrayerPeriod == prayer.prayerType

                if usePremiumCards {
                    // Premium glassmorphic prayer card
                    prayerCardView(
                        prayer: prayer,
                        preNawafil: preNawafil,
                        postNawafil: postNawafil,
                        isCurrentPrayer: isCurrentPrayer
                    )
                } else {
                    // Legacy prayer block
                    TimelinePrayerBlock(
                        prayer: prayer,
                        minHeight: minPrayerBlockHeight,
                        preNawafil: preNawafil,
                        postNawafil: postNawafil,
                        onShowCountdown: appEnvironment.userSettings.enablePrayerCountdownScreen ? {
                            countdownPrayer = prayer
                        } : nil
                    )
                    .background(
                        PrayerGateGradient(colorHex: prayer.colorHex)
                    )
                }
            }

        case .nawafil:
            if let nawafil = segment.nawafil {
                TimelineNawafilBlock(nawafil: nawafil, minHeight: minNawafilBlockHeight)
            }

        case .task:
            // Regular task (no overlapping prayers)
            if let task = segment.task {
                if usePremiumCards {
                    PremiumTaskCard(
                        task: task,
                        minHeight: minTaskBlockHeight,
                        hasTaskOverlap: segment.hasTaskOverlap,
                        overlappingTaskCount: segment.overlappingTaskCount,
                        onToggleCompletion: {
                            toggleTaskCompletion(task)
                        }
                    )
                    .environmentObject(themeManager)
                } else {
                    TimelineTaskBlock(
                        task: task,
                        minHeight: minTaskBlockHeight,
                        onToggleCompletion: {
                            toggleTaskCompletion(task)
                        }
                    )
                }
            }

        case .taskContainer:
            // Task with prayers/nawafil nested inside (prayer priority)
            if let task = segment.task {
                TaskContainerBlock(
                    task: task,
                    containedPrayers: segment.containedPrayers,
                    containedNawafil: segment.containedNawafil,
                    hasTaskOverlap: segment.hasTaskOverlap,
                    overlappingTaskCount: segment.overlappingTaskCount,
                    onToggleCompletion: {
                        toggleTaskCompletion(task)
                    },
                    onPrayerTap: appEnvironment.userSettings.enablePrayerCountdownScreen ? { prayer in
                        countdownPrayer = prayer
                    } : nil
                )
                .environmentObject(themeManager)
            }

        case .taskCluster:
            // Multiple overlapping tasks displayed side-by-side
            TaskClusterView(
                tasks: segment.clusteredTasks,
                clusterStart: segment.startTime,
                clusterEnd: segment.endTime,
                containedPrayers: segment.containedPrayers,
                containedNawafil: segment.containedNawafil,
                onToggleCompletion: { task in
                    toggleTaskCompletion(task)
                },
                onPrayerTap: appEnvironment.userSettings.enablePrayerCountdownScreen ? { prayer in
                    countdownPrayer = prayer
                } : nil
            )
            .environmentObject(themeManager)
        }
    }

    // MARK: - Premium Prayer Card

    @ViewBuilder
    private func prayerCardView(
        prayer: PrayerTime,
        preNawafil: NawafilPrayer?,
        postNawafil: NawafilPrayer?,
        isCurrentPrayer: Bool
    ) -> some View {
        let card = GlassmorphicPrayerCard(
            prayer: prayer,
            minHeight: minPrayerBlockHeight,
            preNawafil: preNawafil,
            postNawafil: postNawafil,
            isCurrentPrayer: isCurrentPrayer,
            onShowCountdown: appEnvironment.userSettings.enablePrayerCountdownScreen ? {
                countdownPrayer = prayer
            } : nil
        )
        .environmentObject(themeManager)

        if isCurrentPrayer {
            CurrentPrayerHighlight(prayerColor: Color(hex: prayer.colorHex)) {
                card
            }
            .environmentObject(themeManager)
        } else {
            card
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
                // RTL layout: swipe left = previous day, swipe right = next day
                if horizontalAmount > verticalAmount && horizontalAmount > 80 {
                    let calendar = Calendar.current

                    if value.translation.width < 0 {
                        // Swipe left = previous day (RTL)
                        if let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedDate = previousDay
                                dragOffset = 0
                            }
                            HapticManager.shared.trigger(.selection)
                            scrollToNowOnAppear = true
                        }
                    } else {
                        // Swipe right = next day (RTL)
                        if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedDate = nextDay
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
    var onShowCountdown: (() -> Void)? = nil

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

                    // Countdown button
                    if let onShowCountdown = onShowCountdown {
                        Button {
                            onShowCountdown()
                            HapticManager.shared.trigger(.selection)
                        } label: {
                            Image(systemName: "timer")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.textOnPrimaryColor)
                                .padding(8)
                                .background(themeManager.textOnPrimaryColor.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
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

                Text("\(nawafil.rakaat) \(nawafil.rakaat.arabicRakaat) • \(nawafil.duration) \(nawafil.duration.arabicMinutes)")
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

                Text("\(task.duration) \(task.duration.arabicMinutes)")
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

    // NEW: For task containers (prayers nested inside tasks)
    var containedPrayers: [PrayerTime] = []
    var containedNawafil: [NawafilPrayer] = []
    var hasTaskOverlap: Bool = false
    var overlappingTaskCount: Int = 0  // Number of overlapping tasks for merge counter

    // NEW: For task clusters (multiple overlapping tasks displayed side-by-side)
    var clusteredTasks: [Task] = []

    // Overlap metrics for detection (visual handled by OverlapWarningModifier)
    var overlapMetrics: OverlapMetrics = .none

    enum SegmentType {
        case prayer
        case task
        case taskContainer  // Task with prayers/nawafil inside
        case taskCluster    // Multiple overlapping tasks displayed side-by-side
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
            return "\(hours) \(hours.arabicHours)"
        } else {
            return "\(mins) \(mins.arabicMinutes)"
        }
    }

    /// Whether this task container has any contained items
    var hasContainedItems: Bool {
        !containedPrayers.isEmpty || !containedNawafil.isEmpty
    }

    init(
        startTime: Date,
        endTime: Date,
        segmentType: SegmentType,
        prayer: PrayerTime? = nil,
        task: Task? = nil,
        nawafil: NawafilPrayer? = nil,
        containedPrayers: [PrayerTime] = [],
        containedNawafil: [NawafilPrayer] = [],
        hasTaskOverlap: Bool = false,
        overlappingTaskCount: Int = 0,
        clusteredTasks: [Task] = [],
        overlapMetrics: OverlapMetrics = .none
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.segmentType = segmentType
        self.prayer = prayer
        self.task = task
        self.nawafil = nawafil
        self.containedPrayers = containedPrayers
        self.containedNawafil = containedNawafil
        self.hasTaskOverlap = hasTaskOverlap
        self.overlappingTaskCount = overlappingTaskCount
        self.clusteredTasks = clusteredTasks
        self.overlapMetrics = overlapMetrics
    }
}

// MARK: - Build Segments Extension

extension TimelineView {
    /// Build timeline segments from prayers, tasks, and nawafil
    /// Implements prayer priority - prayers are ALWAYS visible, nested inside tasks when they overlap
    /// Implements task clustering - overlapping tasks are grouped and displayed side-by-side
    func buildSegments(
        prayers: [PrayerTime],
        tasks: [Task],
        nawafil: [NawafilPrayer],
        dayStart: Date,
        dayEnd: Date
    ) -> [TimelineSegment] {
        var segments: [TimelineSegment] = []

        // Track which prayers are contained within tasks (so we don't add them as standalone)
        var containedPrayerIDs: Set<UUID> = []
        var containedNawafilIDs: Set<UUID> = []

        // STEP 1: Build task clusters (group overlapping tasks together)
        let taskClusters = buildTaskClusters(from: tasks)

        // STEP 2: Process each cluster
        for cluster in taskClusters {
            if cluster.count == 1 {
                // Single task - use existing logic
                let task = cluster[0]
                guard let taskStart = task.scheduledStartTime,
                      let taskEnd = task.endTime else { continue }

                // Find prayers that overlap with this task
                let overlappingPrayers = prayers.filter { prayer in
                    let prayerStart = prayer.effectiveStartTime
                    let prayerEnd = prayer.effectiveEndTime
                    return prayerStart < taskEnd && prayerEnd > taskStart
                }.sorted { $0.effectiveStartTime < $1.effectiveStartTime }

                // Find standalone nawafil that overlap with this task
                let overlappingNawafil = nawafil.filter { naf in
                    guard !naf.isDismissed && naf.isStandalone else { return false }
                    return naf.startTime < taskEnd && naf.endTime > taskStart
                }.sorted { $0.suggestedTime < $1.suggestedTime }

                // Mark contained prayers and nawafil
                for prayer in overlappingPrayers {
                    containedPrayerIDs.insert(prayer.id)
                }
                for naf in overlappingNawafil {
                    containedNawafilIDs.insert(naf.id)
                }

                // Determine segment type based on whether it contains prayers
                let segmentType: TimelineSegment.SegmentType = overlappingPrayers.isEmpty && overlappingNawafil.isEmpty ? .task : .taskContainer

                // Calculate effective end time - extend to include prayers that go beyond task end
                let prayerMaxEnd = overlappingPrayers.map { $0.effectiveEndTime }.max()
                let nawafilMaxEnd = overlappingNawafil.map { $0.endTime }.max()
                let effectiveEndTime = [taskEnd, prayerMaxEnd, nawafilMaxEnd].compactMap { $0 }.max() ?? taskEnd

                segments.append(TimelineSegment(
                    startTime: taskStart,
                    endTime: effectiveEndTime,
                    segmentType: segmentType,
                    task: task,
                    containedPrayers: overlappingPrayers,
                    containedNawafil: overlappingNawafil,
                    hasTaskOverlap: false,  // Single task, no overlap
                    overlappingTaskCount: 0
                ))
            } else {
                // Multiple overlapping tasks - create a cluster segment
                let clusterStart = cluster.compactMap { $0.scheduledStartTime }.min()!
                let clusterEnd = cluster.compactMap { $0.endTime }.max()!

                // Find prayers that overlap with the entire cluster timespan
                let overlappingPrayers = prayers.filter { prayer in
                    let prayerStart = prayer.effectiveStartTime
                    let prayerEnd = prayer.effectiveEndTime
                    return prayerStart < clusterEnd && prayerEnd > clusterStart
                }.sorted { $0.effectiveStartTime < $1.effectiveStartTime }

                // Find standalone nawafil that overlap with cluster
                let overlappingNawafil = nawafil.filter { naf in
                    guard !naf.isDismissed && naf.isStandalone else { return false }
                    return naf.startTime < clusterEnd && naf.endTime > clusterStart
                }.sorted { $0.suggestedTime < $1.suggestedTime }

                // Mark contained prayers and nawafil
                for prayer in overlappingPrayers {
                    containedPrayerIDs.insert(prayer.id)
                }
                for naf in overlappingNawafil {
                    containedNawafilIDs.insert(naf.id)
                }

                // Calculate effective end time including prayers
                let prayerMaxEnd = overlappingPrayers.map { $0.effectiveEndTime }.max()
                let nawafilMaxEnd = overlappingNawafil.map { $0.endTime }.max()
                let effectiveEndTime = [clusterEnd, prayerMaxEnd, nawafilMaxEnd].compactMap { $0 }.max() ?? clusterEnd

                segments.append(TimelineSegment(
                    startTime: clusterStart,
                    endTime: effectiveEndTime,
                    segmentType: .taskCluster,
                    containedPrayers: overlappingPrayers,
                    containedNawafil: overlappingNawafil,
                    hasTaskOverlap: true,
                    overlappingTaskCount: cluster.count,
                    clusteredTasks: cluster
                ))
            }
        }

        // STEP 3: Add standalone prayers (not contained in any task)
        for prayer in prayers {
            if !containedPrayerIDs.contains(prayer.id) {
                segments.append(TimelineSegment(
                    startTime: prayer.effectiveStartTime,
                    endTime: prayer.effectiveEndTime,
                    segmentType: .prayer,
                    prayer: prayer
                ))
            }
        }

        // STEP 4: Add standalone nawafil (not contained in any task or prayer)
        for naf in nawafil where !naf.isDismissed && naf.isStandalone {
            if !containedNawafilIDs.contains(naf.id) {
                segments.append(TimelineSegment(
                    startTime: naf.startTime,
                    endTime: naf.endTime,
                    segmentType: .nawafil,
                    nawafil: naf
                ))
            }
        }

        // STEP 5: Sort segments by start time
        segments.sort { $0.startTime < $1.startTime }

        // STEP 6: Insert gaps between segments
        return insertGaps(into: segments, dayStart: dayStart, dayEnd: dayEnd)
    }

    /// Group tasks into clusters where overlapping tasks are in the same cluster
    /// This enables side-by-side display of overlapping tasks instead of stacking them
    private func buildTaskClusters(from tasks: [Task]) -> [[Task]] {
        // Filter to scheduled tasks only
        let scheduledTasks = tasks.filter { $0.scheduledStartTime != nil && $0.endTime != nil }
        guard !scheduledTasks.isEmpty else { return [] }

        // Sort by start time for efficient processing
        let sorted = scheduledTasks.sorted { $0.startTime < $1.startTime }

        var clusters: [[Task]] = []
        var currentCluster: [Task] = [sorted[0]]
        var clusterEnd = sorted[0].endTime!

        for i in 1..<sorted.count {
            let task = sorted[i]
            let taskStart = task.startTime

            // If this task starts before current cluster ends, it overlaps
            if taskStart < clusterEnd {
                currentCluster.append(task)
                // Extend cluster end if needed
                if let taskEnd = task.endTime, taskEnd > clusterEnd {
                    clusterEnd = taskEnd
                }
            } else {
                // No overlap - start new cluster
                clusters.append(currentCluster)
                currentCluster = [task]
                clusterEnd = task.endTime!
            }
        }

        // Don't forget last cluster
        clusters.append(currentCluster)

        return clusters
    }

    /// Insert gap segments between content segments
    private func insertGaps(into segments: [TimelineSegment], dayStart: Date, dayEnd: Date) -> [TimelineSegment] {
        var result: [TimelineSegment] = []
        var currentTime = dayStart

        for segment in segments {
            // Handle overlapping segments - skip if starts before current time
            let effectiveStart = max(segment.startTime, currentTime)

            // Add gap if there's time between current position and this segment
            if effectiveStart > currentTime {
                result.append(TimelineSegment(
                    startTime: currentTime,
                    endTime: effectiveStart,
                    segmentType: .gap
                ))
            }

            // Add the content segment
            result.append(segment)
            currentTime = max(currentTime, segment.endTime)
        }

        // Add final gap if needed
        if currentTime < dayEnd {
            result.append(TimelineSegment(
                startTime: currentTime,
                endTime: dayEnd,
                segmentType: .gap
            ))
        }

        return result
    }
}

// MARK: - Gap Segment View

struct GapSegmentView: View {
    let segment: TimelineSegment
    var usePremiumFlow: Bool = true

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
        if usePremiumFlow {
            // Premium organic flow connector
            premiumFlowView
        } else {
            // Legacy style gap
            legacyGapView
        }
    }

    // MARK: - Premium Flow View

    private var premiumFlowView: some View {
        HStack(alignment: .top, spacing: 10) {
            // Time labels - matching GlassmorphicPrayerCard layout
            VStack(alignment: .trailing, spacing: 2) {
                Text(segment.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(themeManager.textSecondaryColor.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Text(segment.endTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(themeManager.textSecondaryColor.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 60, alignment: .trailing)

            // Organic flow connector
            if height > 20 {
                OrganicTimeFlow(
                    height: height,
                    duration: segment.endTime.timeIntervalSince(segment.startTime),
                    isCollapsed: segment.isCollapsedGap
                )
                .environmentObject(themeManager)
            } else {
                CompactFlowDot()
                    .environmentObject(themeManager)
                    .frame(height: height)
            }
        }
        .frame(height: height)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    // MARK: - Legacy Gap View

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
