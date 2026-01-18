//
//  TimelineView.swift
//  Mizan
//
//  Main timeline view with hour markers, prayers, and tasks
//

import SwiftUI
import SwiftData

// MARK: - Time Comparison Helpers

/// Normalizes a date to a reference date (keeping only time components)
/// This allows comparing times without worrying about date mismatches
private func timeOnlyMinutes(from date: Date) -> Int {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: date)
    return (components.hour ?? 0) * 60 + (components.minute ?? 0)
}

/// Checks if a time falls within a time range (comparing time-of-day only, ignoring dates)
private func timeIsWithinRange(_ time: Date, start: Date, end: Date) -> Bool {
    let timeMinutes = timeOnlyMinutes(from: time)
    let startMinutes = timeOnlyMinutes(from: start)
    let endMinutes = timeOnlyMinutes(from: end)

    // Handle overnight ranges (e.g., 11 PM to 2 AM)
    if endMinutes < startMinutes {
        return timeMinutes >= startMinutes || timeMinutes <= endMinutes
    }

    return timeMinutes >= startMinutes && timeMinutes <= endMinutes
}

// MARK: - Intelligent Height Calculation

/// Calculates height using diminishing returns - short tasks get fair space,
/// long tasks don't explode the layout.
/// - Parameters:
///   - durationMinutes: Task duration in minutes
///   - minHeight: Minimum height to return (default 60pt)
/// - Returns: Calculated height with logarithmic scaling for long durations
func intelligentTaskHeight(durationMinutes: Int, minHeight: CGFloat = 60) -> CGFloat {
    let hours = CGFloat(durationMinutes) / 60.0

    if hours <= 0.5 {
        // Short tasks (≤30min): minimum height
        return minHeight
    } else if hours <= 1.0 {
        // Up to 1 hour: grow to 80pt
        return minHeight + (hours - 0.5) * 40  // 60 → 80
    } else {
        // Beyond 1 hour: logarithmic growth
        // Base 80pt + log2(hours) * 30
        // 2hr → 110pt, 4hr → 140pt, 8hr → 170pt
        return 80 + log2(hours) * 30
    }
}

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
    @State private var taskToEdit: Task? = nil

    // MARK: - Recurring Task Confirmation
    @State private var showRecurringDeleteConfirmation = false
    @State private var taskToDelete: Task? = nil

    // MARK: - Queries
    @Query private var allTasks: [Task]
    @Query private var allPrayers: [PrayerTime]
    @Query private var allNawafil: [NawafilPrayer]

    // MARK: - Constants
    private let minPrayerBlockHeight: CGFloat = 110
    private let minNawafilBlockHeight: CGFloat = 60
    private let minTaskBlockHeight: CGFloat = 60
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

    /// Hijri date for the selected date - uses prayer API data or calculates locally
    private var hijriDateString: String? {
        // Respect user's toggle
        guard appEnvironment.userSettings.showHijriDate else { return nil }

        // Try to get from prayer data first (API provides accurate Hijri date)
        if let hijriFromPrayer = todayPrayers.first?.hijriDate, !hijriFromPrayer.isEmpty {
            return hijriFromPrayer
        }

        // Fallback: Calculate locally using Islamic calendar
        let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)
        let formatter = DateFormatter()
        formatter.calendar = islamicCalendar
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "d MMMM yyyy"

        return formatter.string(from: selectedDate)
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

                // Timeline with swipe and pinch gestures
                timelineScrollView
                    .safeAreaInset(edge: .top, spacing: 0) {
                        // Invisible spacer - content scrolls under the date bar + countdown banner
                        // 56pt for date navigator, +50pt when countdown banner is visible
                        Color.clear.frame(height: approachingPrayer != nil ? 106 : 56)
                            .animation(.easeInOut(duration: 0.3), value: approachingPrayer != nil)
                    }
                    .offset(x: dragOffset)
                    .gesture(horizontalSwipeGesture)
                    .timelineGestures(scale: $timelineScale) { location in
                        // Long press handling - could open edit sheet
                        HapticManager.shared.trigger(.medium)
                    }

                // Floating overlays at ZStack level (full screen positioning)
                VStack {
                    // Date Navigator - glass pill at top
                    CinematicDateNavigator(
                        selectedDate: $selectedDate,
                        hijriDate: hijriDateString,
                        currentPrayerPeriod: divinePrayerPeriod
                    )
                    .environmentObject(themeManager)

                    // Prayer Approaching Banner - below date navigator
                    if let approaching = approachingPrayer {
                        PrayerApproachingIndicator(
                            prayerName: approaching.prayer.displayName,
                            prayerTime: approaching.prayer.adhanTime,
                            colorHex: approaching.prayer.colorHex
                        )
                        .environmentObject(themeManager)
                    }

                    Spacer()
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
            .navigationBarHidden(true)
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
        .sheet(item: $taskToEdit) { task in
            AddTaskSheet(task: task)
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
        }
        .confirmationDialog(
            "حذف المهمة المتكررة",
            isPresented: $showRecurringDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("حذف هذه المرة فقط", role: .destructive) {
                if let task = taskToDelete {
                    deleteThisInstanceOnly(task)
                }
            }
            Button("حذف جميع التكرارات", role: .destructive) {
                if let task = taskToDelete {
                    deleteAllInstances(task)
                }
            }
            Button("إلغاء", role: .cancel) {
                taskToDelete = nil
            }
        } message: {
            Text("هل تريد حذف هذه المرة فقط أم جميع تكرارات المهمة؟")
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
                // Minimal horizontal padding - cards handle their own margins
                .padding(.horizontal, 4)
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

    /// Determines the accent color for a segment's timeline dot
    private func segmentAccentColor(for segment: TimelineSegment) -> Color {
        switch segment.segmentType {
        case .gap:
            return themeManager.textSecondaryColor
        case .prayer:
            if let colorHex = segment.prayer?.colorHex {
                return Color(hex: colorHex)
            }
            return themeManager.primaryColor
        case .nawafil:
            if let colorHex = segment.nawafil?.colorHex {
                return Color(hex: colorHex)
            }
            return themeManager.primaryColor
        case .task, .taskContainer:
            if let colorHex = segment.task?.colorHex {
                return Color(hex: colorHex)
            }
            return themeManager.primaryColor
        case .taskCluster:
            return themeManager.warningColor // Cluster uses warning color
        }
    }

    @ViewBuilder
    private func segmentView(for segment: TimelineSegment) -> some View {
        let isGap = segment.segmentType == .gap
        let accentColor = segmentAccentColor(for: segment)

        TimelineRow(accentColor: accentColor, showDot: !isGap) {
            segmentContent(for: segment)
        }
        .environmentObject(themeManager)
    }

    @ViewBuilder
    private func segmentContent(for segment: TimelineSegment) -> some View {
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
                        },
                        onTap: {
                            taskToEdit = task
                        },
                        onDelete: {
                            deleteTask(task)
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
                    prayerNawafilMap: segment.prayerNawafilMap,
                    hasTaskOverlap: segment.hasTaskOverlap,
                    overlappingTaskCount: segment.overlappingTaskCount,
                    onToggleCompletion: {
                        toggleTaskCompletion(task)
                    },
                    onPrayerTap: appEnvironment.userSettings.enablePrayerCountdownScreen ? { prayer in
                        countdownPrayer = prayer
                    } : nil,
                    onTap: {
                        taskToEdit = task
                    },
                    onDelete: {
                        deleteTask(task)
                    }
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
                prayerNawafilMap: segment.prayerNawafilMap,
                onToggleCompletion: { task in
                    toggleTaskCompletion(task)
                },
                onPrayerTap: appEnvironment.userSettings.enablePrayerCountdownScreen ? { prayer in
                    countdownPrayer = prayer
                } : nil,
                onTaskTap: { task in
                    taskToEdit = task
                },
                onTaskDelete: { task in
                    deleteTask(task)
                }
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

    private func deleteTask(_ task: Task) {
        // Check if this is a recurring task (has parent or has recurrence rule)
        let isRecurringTask = task.parentTaskId != nil || task.recurrenceRule != nil

        if isRecurringTask {
            // Show confirmation dialog
            taskToDelete = task
            showRecurringDeleteConfirmation = true
        } else {
            // Regular task - delete directly
            deleteNonRecurringTask(task)
        }
    }

    /// Delete a non-recurring task directly
    private func deleteNonRecurringTask(_ task: Task) {
        print("🗑️ [TIMELINE] DELETE NON-RECURRING TASK: '\(task.title)'")
        modelContext.delete(task)
        try? modelContext.save()
        HapticManager.shared.trigger(.warning)
    }

    /// Delete only this instance of a recurring task
    private func deleteThisInstanceOnly(_ task: Task) {
        print("🗑️ [TIMELINE] DELETE THIS INSTANCE ONLY: '\(task.title)'")

        // If this is a child instance, mark the date as dismissed on parent
        if let parentId = task.parentTaskId, let scheduledDate = task.scheduledDate {
            let descriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == parentId })
            if let parentTask = try? modelContext.fetch(descriptor).first {
                parentTask.dismissRecurringInstance(for: scheduledDate)
                print("   → Dismissed date \(scheduledDate) on parent")
            }
        }
        // If this is a parent task, just dismiss the date (don't delete the parent)
        else if task.recurrenceRule != nil, let scheduledDate = task.scheduledDate {
            task.dismissRecurringInstance(for: scheduledDate)
            // Don't delete the parent - just save the dismissal and return
            try? modelContext.save()
            taskToDelete = nil
            HapticManager.shared.trigger(.warning)
            return
        }

        // Delete the instance
        modelContext.delete(task)
        try? modelContext.save()
        taskToDelete = nil
        HapticManager.shared.trigger(.warning)
    }

    /// Delete all instances of a recurring task (parent + all children)
    private func deleteAllInstances(_ task: Task) {
        print("🗑️ [TIMELINE] DELETE ALL INSTANCES: '\(task.title)'")

        // Find the parent task ID
        let parentId: UUID
        if let pid = task.parentTaskId {
            // This is a child instance - get parent ID
            parentId = pid
        } else {
            // This is the parent task itself
            parentId = task.id
        }

        // Find all tasks with this parentTaskId (children)
        let childDescriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.parentTaskId == parentId })
        let childTasks = (try? modelContext.fetch(childDescriptor)) ?? []

        // Find and delete the parent task
        let parentDescriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == parentId })
        if let parentTask = try? modelContext.fetch(parentDescriptor).first {
            modelContext.delete(parentTask)
            print("   → Deleted parent task")
        }

        // Delete all child instances
        for child in childTasks {
            modelContext.delete(child)
        }
        print("   → Deleted \(childTasks.count) child instances")

        // Also delete the current task if it wasn't already deleted
        if task.parentTaskId == nil && task.id != parentId {
            modelContext.delete(task)
        }

        try? modelContext.save()
        taskToDelete = nil
        HapticManager.shared.trigger(.warning)
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
                .foregroundColor(nawafil.isCompleted ? themeManager.successColor : themeManager.textOnPrimaryColor.opacity(0.6))
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

    private var nawafilColor: Color {
        Color(hex: nawafil.colorHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Time row above (left-aligned like other cards)
            HStack(spacing: 6) {
                Text(nawafil.suggestedTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(nawafilColor)

                Text("•")
                    .font(.system(size: 8))
                    .foregroundColor(themeManager.textTertiaryColor)

                Text(nawafil.duration.formattedDuration)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            .padding(.leading, 4)

            // Nawafil card
            nawafilBlockContent
        }
        .frame(minHeight: minHeight)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .opacity(nawafil.isCompleted ? 0.6 : 1.0)
    }

    private var nawafilBlockContent: some View {
        HStack(spacing: 10) {
            // Badge on left
            Text("نافلة")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(themeManager.textOnPrimaryColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(nawafilColor)
                .cornerRadius(4)

            Spacer()

            // Name and details (centered)
            VStack(spacing: 2) {
                Text(nawafil.arabicName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(nawafilColor)

                Text("\(nawafil.rakaat) \(nawafil.rakaat.arabicRakaat)")
                    .font(.system(size: 11))
                    .foregroundColor(nawafilColor.opacity(0.7))
            }

            Spacer()

            // Icon on right
            Image(systemName: nawafil.icon)
                .font(.system(size: 20))
                .foregroundColor(nawafilColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            nawafilColor.opacity(0.1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundColor(nawafilColor.opacity(0.5))
        )
        .cornerRadius(12)
    }
}


// MARK: - Timeline Task Block

struct TimelineTaskBlock: View {
    let task: Task
    let minHeight: CGFloat
    var onToggleCompletion: (() -> Void)?

    @EnvironmentObject var themeManager: ThemeManager

    private var blockHeight: CGFloat {
        intelligentTaskHeight(durationMinutes: task.duration, minHeight: minHeight)
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

                Text(task.duration.formattedDuration)
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.textSecondaryColor)
            }

            Spacer()

            // Task icon
            Image(systemName: task.icon)
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
    var prayerNawafilMap: [UUID: (pre: NawafilPrayer?, post: NawafilPrayer?)] = [:]  // Rawatib nawafil for each prayer
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
        durationMinutes.formattedDuration
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
        prayerNawafilMap: [UUID: (pre: NawafilPrayer?, post: NawafilPrayer?)] = [:],
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
        self.prayerNawafilMap = prayerNawafilMap
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

                // Find prayers whose athan time falls within the task timespan
                // Using time-of-day comparison to avoid date mismatch issues
                let overlappingPrayers = prayers.filter { prayer in
                    timeIsWithinRange(prayer.adhanTime, start: taskStart, end: taskEnd)
                }.sorted { $0.adhanTime < $1.adhanTime }

                // Find standalone nawafil that overlap with this task
                let overlappingNawafil = nawafil.filter { naf in
                    guard !naf.isDismissed && naf.isStandalone else { return false }
                    return naf.startTime < taskEnd && naf.endTime > taskStart
                }.sorted { $0.suggestedTime < $1.suggestedTime }

                // Build rawatib nawafil map for each contained prayer
                var prayerNawafilMap: [UUID: (pre: NawafilPrayer?, post: NawafilPrayer?)] = [:]
                for prayer in overlappingPrayers {
                    let preNawafil = nawafil.first { naf in
                        !naf.isDismissed &&
                        naf.attachedToPrayer == prayer.prayerType &&
                        naf.attachmentPosition == .before
                    }
                    let postNawafil = nawafil.first { naf in
                        !naf.isDismissed &&
                        naf.attachedToPrayer == prayer.prayerType &&
                        naf.attachmentPosition == .after
                    }
                    prayerNawafilMap[prayer.id] = (pre: preNawafil, post: postNawafil)
                }

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
                    prayerNawafilMap: prayerNawafilMap,
                    hasTaskOverlap: false,  // Single task, no overlap
                    overlappingTaskCount: 0
                ))
            } else {
                // Multiple overlapping tasks - create a cluster segment
                let clusterStart = cluster.compactMap { $0.scheduledStartTime }.min()!
                let clusterEnd = cluster.compactMap { $0.endTime }.max()!

                // Find prayers whose athan time falls within the cluster timespan
                // Using time-of-day comparison to avoid date mismatch issues
                let overlappingPrayers = prayers.filter { prayer in
                    timeIsWithinRange(prayer.adhanTime, start: clusterStart, end: clusterEnd)
                }.sorted { $0.adhanTime < $1.adhanTime }

                // Find standalone nawafil that overlap with cluster
                let overlappingNawafil = nawafil.filter { naf in
                    guard !naf.isDismissed && naf.isStandalone else { return false }
                    return naf.startTime < clusterEnd && naf.endTime > clusterStart
                }.sorted { $0.suggestedTime < $1.suggestedTime }

                // Build rawatib nawafil map for each contained prayer
                var prayerNawafilMap: [UUID: (pre: NawafilPrayer?, post: NawafilPrayer?)] = [:]
                for prayer in overlappingPrayers {
                    let preNawafil = nawafil.first { naf in
                        !naf.isDismissed &&
                        naf.attachedToPrayer == prayer.prayerType &&
                        naf.attachmentPosition == .before
                    }
                    let postNawafil = nawafil.first { naf in
                        !naf.isDismissed &&
                        naf.attachedToPrayer == prayer.prayerType &&
                        naf.attachmentPosition == .after
                    }
                    prayerNawafilMap[prayer.id] = (pre: preNawafil, post: postNawafil)
                }

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
                    prayerNawafilMap: prayerNawafilMap,
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
            return max(30, CGFloat(duration) / 60.0 * 80)
        } else if duration < 120 {
            // Medium gaps: compressed
            return 40
        } else {
            // Large gaps: collapsed
            return 35
        }
    }

    /// Format duration for display
    private var durationText: String {
        let minutes = segment.durationMinutes
        if minutes < 60 {
            return "\(minutes) د"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) س"
            } else {
                return "\(hours) س \(mins) د"
            }
        }
    }

    var body: some View {
        // Clean gap view - just centered label, no disconnected lines
        HStack {
            Spacer()

            // Free time label in glass pill
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 8))
                Text("وقت حر")
                    .font(.system(size: 9, weight: .medium))
                Text("•")
                    .font(.system(size: 6))
                Text(durationText)
                    .font(.system(size: 9, weight: .medium))
                    .monospacedDigit()
            }
            .foregroundColor(themeManager.textTertiaryColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background {
                ZStack {
                    // Solid opaque background to block glow from elements below
                    Capsule()
                        .fill(themeManager.backgroundColor)

                    // Glass effect on top
                    if #available(iOS 26.0, *) {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .glassEffect(.regular, in: Capsule())
                    } else {
                        Capsule()
                            .fill(themeManager.surfaceSecondaryColor.opacity(0.7))
                    }
                }
            }
            .zIndex(10) // Bring label to front

            Spacer()
        }
        .frame(height: height)
        .padding(.horizontal, 4)
        .zIndex(1) // Ensure gap segment is above timeline track
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
