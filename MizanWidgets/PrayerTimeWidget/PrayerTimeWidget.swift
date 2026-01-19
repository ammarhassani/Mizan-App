//
//  PrayerTimeWidget.swift
//  MizanWidgets
//
//  Home screen widget showing prayer times and upcoming tasks
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct PrayerTimeEntry: TimelineEntry {
    let date: Date
    let nextPrayer: WidgetPrayerData?
    let todayPrayers: [WidgetPrayerData]
    let upcomingTasks: [WidgetTaskData]
    let theme: WidgetThemeData

    static var placeholder: PrayerTimeEntry {
        PrayerTimeEntry(
            date: Date(),
            nextPrayer: .placeholder,
            todayPrayers: [.placeholder],
            upcomingTasks: [.placeholder],
            theme: .defaultTheme
        )
    }
}

// MARK: - Timeline Provider

struct PrayerTimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerTimeEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimeEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimeEntry>) -> Void) {
        let entry = createEntry()

        // Update every 15 minutes or at next prayer time
        var nextUpdate = Date().addingTimeInterval(15 * 60)

        if let nextPrayer = entry.nextPrayer {
            // Update right after prayer time
            let prayerUpdateTime = nextPrayer.time.addingTimeInterval(60)
            if prayerUpdateTime > Date() && prayerUpdateTime < nextUpdate {
                nextUpdate = prayerUpdateTime
            }
        }

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> PrayerTimeEntry {
        let provider = WidgetDataProvider.shared

        return PrayerTimeEntry(
            date: Date(),
            nextPrayer: provider.getNextPrayer(),
            todayPrayers: provider.getTodayPrayers(),
            upcomingTasks: provider.getUpcomingTasks(limit: 3),
            theme: provider.getTheme()
        )
    }
}

// MARK: - Widget Views

struct PrayerTimeWidgetEntryView: View {
    var entry: PrayerTimeEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Prayer Countdown)

struct SmallWidgetView: View {
    let entry: PrayerTimeEntry

    private var primaryColor: Color {
        Color(widgetHex: entry.theme.primaryColorHex)
    }

    private var backgroundColor: Color {
        Color(widgetHex: entry.theme.backgroundColorHex)
    }

    private var textPrimaryColor: Color {
        Color(widgetHex: entry.theme.textPrimaryColorHex)
    }

    private var textSecondaryColor: Color {
        Color(widgetHex: entry.theme.textSecondaryColorHex)
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [primaryColor, primaryColor.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                if let prayer = entry.nextPrayer {
                    // Prayer icon
                    Image(systemName: prayer.icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.9))

                    // Prayer name
                    Text(prayer.nameArabic)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    // Countdown or time
                    if prayer.time > Date() {
                        Text(prayer.time, style: .relative)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    } else {
                        Text(prayer.time, style: .time)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                } else {
                    // No prayer data
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.9))

                    Text("ميزان")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("افتح التطبيق")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
        }
        .containerBackground(for: .widget) {
            primaryColor
        }
    }
}

// MARK: - Medium Widget (Prayer + Tasks)

struct MediumWidgetView: View {
    let entry: PrayerTimeEntry

    private var primaryColor: Color {
        Color(widgetHex: entry.theme.primaryColorHex)
    }

    private var backgroundColor: Color {
        Color(widgetHex: entry.theme.backgroundColorHex)
    }

    private var surfaceColor: Color {
        Color(widgetHex: entry.theme.surfaceColorHex)
    }

    private var textPrimaryColor: Color {
        Color(widgetHex: entry.theme.textPrimaryColorHex)
    }

    private var textSecondaryColor: Color {
        Color(widgetHex: entry.theme.textSecondaryColorHex)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Prayer section
            prayerSection
                .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(textSecondaryColor.opacity(0.2))
                .frame(width: 1)

            // Tasks section
            tasksSection
                .frame(maxWidth: .infinity)
        }
        .padding()
        .containerBackground(for: .widget) {
            backgroundColor
        }
    }

    private var prayerSection: some View {
        VStack(spacing: 6) {
            if let prayer = entry.nextPrayer {
                // Icon with colored background
                ZStack {
                    Circle()
                        .fill(primaryColor)
                        .frame(width: 44, height: 44)

                    Image(systemName: prayer.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Text(prayer.nameArabic)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textPrimaryColor)

                if prayer.time > Date() {
                    Text(prayer.time, style: .relative)
                        .font(.system(size: 13))
                        .foregroundColor(textSecondaryColor)
                        .lineLimit(1)
                } else {
                    Text(prayer.time, style: .time)
                        .font(.system(size: 13))
                        .foregroundColor(textSecondaryColor)
                }
            } else {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 24))
                    .foregroundColor(primaryColor)

                Text("الصلاة القادمة")
                    .font(.system(size: 14))
                    .foregroundColor(textSecondaryColor)
            }
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("المهام القادمة")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(textSecondaryColor)

            if entry.upcomingTasks.isEmpty {
                Spacer()
                Text("لا توجد مهام")
                    .font(.system(size: 13))
                    .foregroundColor(textSecondaryColor.opacity(0.7))
                Spacer()
            } else {
                ForEach(entry.upcomingTasks.prefix(2), id: \.id) { task in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(widgetHex: task.colorHex))
                            .frame(width: 8, height: 8)

                        Text(task.title)
                            .font(.system(size: 13))
                            .foregroundColor(textPrimaryColor)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

// MARK: - Large Widget (Full Timeline)

struct LargeWidgetView: View {
    let entry: PrayerTimeEntry

    private var primaryColor: Color {
        Color(widgetHex: entry.theme.primaryColorHex)
    }

    private var backgroundColor: Color {
        Color(widgetHex: entry.theme.backgroundColorHex)
    }

    private var surfaceColor: Color {
        Color(widgetHex: entry.theme.surfaceColorHex)
    }

    private var textPrimaryColor: Color {
        Color(widgetHex: entry.theme.textPrimaryColorHex)
    }

    private var textSecondaryColor: Color {
        Color(widgetHex: entry.theme.textSecondaryColorHex)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header with next prayer
            headerSection

            Divider()
                .background(textSecondaryColor.opacity(0.2))

            // Prayer times grid
            prayerTimesSection

            Divider()
                .background(textSecondaryColor.opacity(0.2))

            // Upcoming tasks
            tasksSection
        }
        .padding()
        .containerBackground(for: .widget) {
            backgroundColor
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("الصلاة القادمة")
                    .font(.system(size: 12))
                    .foregroundColor(textSecondaryColor)

                if let prayer = entry.nextPrayer {
                    Text(prayer.nameArabic)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(textPrimaryColor)
                } else {
                    Text("—")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(textPrimaryColor)
                }
            }

            Spacer()

            if let prayer = entry.nextPrayer {
                VStack(alignment: .trailing, spacing: 4) {
                    if prayer.time > Date() {
                        Text(prayer.time, style: .relative)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(primaryColor)
                    }

                    Text(prayer.time, style: .time)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(textPrimaryColor)
                }
            }
        }
    }

    private var prayerTimesSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(entry.todayPrayers.prefix(6), id: \.name) { prayer in
                VStack(spacing: 4) {
                    Text(prayer.nameArabic)
                        .font(.system(size: 11))
                        .foregroundColor(textSecondaryColor)

                    Text(prayer.time, style: .time)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(
                            prayer.time > Date() ? textPrimaryColor : textSecondaryColor.opacity(0.6)
                        )
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(prayer.time > Date() ? surfaceColor : surfaceColor.opacity(0.5))
                )
            }
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("المهام القادمة")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(textSecondaryColor)

            if entry.upcomingTasks.isEmpty {
                HStack {
                    Spacer()
                    Text("لا توجد مهام مجدولة")
                        .font(.system(size: 13))
                        .foregroundColor(textSecondaryColor.opacity(0.7))
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                ForEach(entry.upcomingTasks, id: \.id) { task in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(widgetHex: task.colorHex))
                            .frame(width: 10, height: 10)

                        Text(task.title)
                            .font(.system(size: 14))
                            .foregroundColor(textPrimaryColor)
                            .lineLimit(1)

                        Spacer()

                        if let startTime = task.startTime {
                            Text(startTime, style: .time)
                                .font(.system(size: 12))
                                .foregroundColor(textSecondaryColor)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Widget Configuration

struct PrayerTimeWidget: Widget {
    let kind: String = "PrayerTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimeProvider()) { entry in
            PrayerTimeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("أوقات الصلاة")
        .description("عرض الصلاة القادمة والمهام")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle

@main
struct MizanWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimeWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    PrayerTimeWidget()
} timeline: {
    PrayerTimeEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    PrayerTimeWidget()
} timeline: {
    PrayerTimeEntry.placeholder
}

#Preview("Large", as: .systemLarge) {
    PrayerTimeWidget()
} timeline: {
    PrayerTimeEntry.placeholder
}
