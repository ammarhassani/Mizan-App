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
    @State private var currentTimeOffset: CGFloat = 0
    @State private var scrollToNowOnAppear = true

    // MARK: - Queries
    @Query private var allTasks: [Task]
    @Query private var allPrayers: [PrayerTime]
    @Query private var allNawafil: [NawafilPrayer]

    // MARK: - Constants
    private let hourHeight: CGFloat = 60
    private let gridSpacing: CGFloat = 15 // 15 minutes

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
        return allPrayers.filter { prayer in
            calendar.isDate(prayer.date, inSameDayAs: selectedDate)
        }
    }

    private var todayNawafil: [NawafilPrayer] {
        let calendar = Calendar.current
        return allNawafil.filter { nawafil in
            calendar.isDate(nawafil.date, inSameDayAs: selectedDate) && !nawafil.isDismissed
        }
    }

    private var timelineItems: [TimelineItem] {
        TimelineHelper.items(
            for: selectedDate,
            tasks: allTasks,
            prayers: allPrayers,
            nawafil: allNawafil
        )
    }

    private var totalHours: Int {
        let start = timelineBounds.start
        let end = timelineBounds.end
        return Int(end.timeIntervalSince(start) / 3600) + 1
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
                        scrollToNow()
                    } label: {
                        Image(systemName: "clock")
                            .foregroundColor(themeManager.primaryColor)
                    }
                }
            }
        }
        .onAppear {
            if scrollToNowOnAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    scrollToNow()
                    scrollToNowOnAppear = false
                }
            }
            startCurrentTimeUpdater()
        }
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
                ZStack(alignment: .topLeading) {
                    // Hour markers and grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<totalHours, id: \.self) { hour in
                            timelineHourRow(hour: hour)
                                .id("hour_\(hour)")
                        }
                    }

                    // Timeline items (prayers, tasks, nawafil)
                    timelineItemsOverlay

                    // Current time indicator
                    if Calendar.current.isDateInToday(selectedDate) {
                        currentTimeIndicator
                    }
                }
                .padding(.leading, 60) // Space for time labels
                .padding(.trailing, 16)
            }
            .onChange(of: selectedDate) { _, _ in
                scrollToNow()
            }
        }
    }

    // MARK: - Timeline Hour Row

    private func timelineHourRow(hour: Int) -> some View {
        let hourDate = Calendar.current.date(byAdding: .hour, value: hour, to: timelineBounds.start)!

        return ZStack(alignment: .topLeading) {
            // Hour background
            Rectangle()
                .fill(hour % 2 == 0 ? themeManager.backgroundColor : themeManager.surfaceColor.opacity(0.3))
                .frame(height: hourHeight)

            // 15-minute grid lines
            VStack(spacing: 0) {
                ForEach(0..<4) { quarter in
                    if quarter > 0 {
                        Divider()
                            .background(themeManager.textSecondaryColor.opacity(0.2))
                            .frame(height: 1)
                    }
                    Spacer()
                        .frame(height: gridSpacing)
                }
            }
            .frame(height: hourHeight)

            // Hour line (thicker)
            Divider()
                .background(themeManager.textSecondaryColor.opacity(0.4))
                .frame(height: 2)

            // Time label
            HStack {
                Text(hourDate.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.textSecondaryColor)
                    .frame(width: 50, alignment: .trailing)
                    .offset(x: -60)

                Spacer()
            }
            .offset(y: -10)
        }
        .frame(height: hourHeight)
    }

    // MARK: - Timeline Items Overlay

    private var timelineItemsOverlay: some View {
        ForEach(timelineItems, id: \.id) { item in
            TimelineItemView(
                item: item,
                hourHeight: hourHeight,
                baseTime: timelineBounds.start,
                prayers: todayPrayers
            )
        }
    }

    // MARK: - Current Time Indicator

    private var currentTimeIndicator: some View {
        GeometryReader { geometry in
            let now = Date()
            let yPosition = yPosition(for: now)

            ZStack(alignment: .leading) {
                // Red line
                Rectangle()
                    .fill(Color.red)
                    .frame(height: 2)

                // Circle indicator
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .offset(x: -6)
            }
            .offset(y: yPosition)
            .animation(.linear(duration: 1.0), value: currentTimeOffset)
        }
    }

    // MARK: - Helper Methods

    private func yPosition(for date: Date) -> CGFloat {
        let interval = date.timeIntervalSince(timelineBounds.start)
        let hours = interval / 3600
        return CGFloat(hours) * hourHeight
    }

    private func scrollToNow() {
        let now = Date()
        let interval = now.timeIntervalSince(timelineBounds.start)
        let hour = Int(interval / 3600)

        // Scroll to current hour (offset by a few hours to center it)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            // Scroll to 2 hours before current time for better context
            let targetHour = max(0, hour - 2)
            // Note: ScrollViewReader proxy would be used here in actual implementation
        }
    }

    private func startCurrentTimeUpdater() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTimeOffset = yPosition(for: Date())
        }
    }
}

// MARK: - Timeline Item View

struct TimelineItemView: View {
    let item: TimelineItem
    let hourHeight: CGFloat
    let baseTime: Date
    let prayers: [PrayerTime]

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Group {
            switch item.itemType {
            case .fardPrayer:
                TimelinePrayerBlock(prayer: item as! PrayerTime, hourHeight: hourHeight, baseTime: baseTime)
            case .nawafilPrayer:
                TimelineNawafilBlock(nawafil: item as! NawafilPrayer, hourHeight: hourHeight, baseTime: baseTime)
            case .task:
                DraggableTaskView(
                    task: item as! Task,
                    hourHeight: hourHeight,
                    baseTime: baseTime,
                    prayers: prayers
                )
            }
        }
    }
}

// MARK: - Timeline Prayer Block

struct TimelinePrayerBlock: View {
    let prayer: PrayerTime
    let hourHeight: CGFloat
    let baseTime: Date

    @EnvironmentObject var themeManager: ThemeManager

    private var yPosition: CGFloat {
        let startWithBuffer = prayer.actualPrayerTime.addingTimeInterval(TimeInterval(-prayer.bufferBefore * 60))
        let interval = startWithBuffer.timeIntervalSince(baseTime)
        let hours = interval / 3600
        return CGFloat(hours) * hourHeight
    }

    private var blockHeight: CGFloat {
        let totalDuration = prayer.bufferBefore + prayer.duration + prayer.bufferAfter
        return CGFloat(totalDuration) / 60.0 * hourHeight
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: prayer.colorHex),
                    Color(hex: prayer.colorHex).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(themeManager.cornerRadius(.medium))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: prayer.prayerType.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)

                    Text(prayer.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    if prayer.isJummah {
                        Text("جمعة")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(6)
                    }
                }

                Text(prayer.adhanTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                Text("\(prayer.duration) دقيقة")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }
            .padding(12)
        }
        .frame(height: blockHeight)
        .offset(y: yPosition)
    }
}

// MARK: - Timeline Nawafil Block

struct TimelineNawafilBlock: View {
    let nawafil: NawafilPrayer
    let hourHeight: CGFloat
    let baseTime: Date

    @EnvironmentObject var themeManager: ThemeManager

    private var yPosition: CGFloat {
        let interval = nawafil.suggestedTime.timeIntervalSince(baseTime)
        let hours = interval / 3600
        return CGFloat(hours) * hourHeight
    }

    private var blockHeight: CGFloat {
        CGFloat(nawafil.duration) / 60.0 * hourHeight
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Lighter green background for nawafil
            Color(hex: "#52B788")
                .opacity(0.6)
                .cornerRadius(themeManager.cornerRadius(.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .stroke(Color(hex: "#14746F"), lineWidth: 2)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#14746F"))

                    Text(nawafil.arabicName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#14746F"))

                    Spacer()

                    Text("نافلة")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#14746F"))
                        .cornerRadius(4)
                }

                Text("\(nawafil.rakaat) ركعة")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#14746F").opacity(0.8))

                if !nawafil.isCompleted {
                    Spacer()
                }
            }
            .padding(10)
        }
        .frame(height: blockHeight)
        .offset(y: yPosition)
        .opacity(nawafil.isCompleted ? 0.5 : 1.0)
    }
}


// MARK: - Preview

#Preview {
    TimelineView()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
        .modelContainer(AppEnvironment.preview().modelContainer)
}
