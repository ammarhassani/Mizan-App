//
//  WidgetDataProvider.swift
//  MizanWidgets
//
//  Shared data provider for widget data using App Groups
//

import Foundation
import WidgetKit

// MARK: - App Group Configuration

enum AppGroupConfig {
    static let suiteName = "group.com.mizanapp.mizan"

    enum Keys {
        static let nextPrayer = "widget_next_prayer"
        static let todayPrayers = "widget_today_prayers"
        static let upcomingTasks = "widget_upcoming_tasks"
        static let lastUpdate = "widget_last_update"
        static let selectedTheme = "widget_selected_theme"
    }
}

// MARK: - Widget Data Models

struct WidgetPrayerData: Codable {
    let name: String
    let nameArabic: String
    let time: Date
    let colorHex: String
    let icon: String

    static var placeholder: WidgetPrayerData {
        WidgetPrayerData(
            name: "Dhuhr",
            nameArabic: "الظهر",
            time: Date(),
            colorHex: "#14746F",
            icon: "sun.max.fill"
        )
    }
}

struct WidgetTaskData: Codable {
    let id: String
    let title: String
    let startTime: Date?
    let duration: Int
    let colorHex: String
    let icon: String
    let isCompleted: Bool

    static var placeholder: WidgetTaskData {
        WidgetTaskData(
            id: UUID().uuidString,
            title: "مهمة نموذجية",
            startTime: Date().addingTimeInterval(3600),
            duration: 30,
            colorHex: "#3B82F6",
            icon: "checkmark.circle",
            isCompleted: false
        )
    }
}

struct WidgetThemeData: Codable {
    let primaryColorHex: String
    let backgroundColorHex: String
    let surfaceColorHex: String
    let textPrimaryColorHex: String
    let textSecondaryColorHex: String

    static var defaultTheme: WidgetThemeData {
        WidgetThemeData(
            primaryColorHex: "#14746F",
            backgroundColorHex: "#FAFAFA",
            surfaceColorHex: "#FFFFFF",
            textPrimaryColorHex: "#1A1A1A",
            textSecondaryColorHex: "#6B7280"
        )
    }
}

// MARK: - Widget Data Provider

final class WidgetDataProvider {
    static let shared = WidgetDataProvider()

    private let userDefaults: UserDefaults?

    private init() {
        userDefaults = UserDefaults(suiteName: AppGroupConfig.suiteName)
    }

    // MARK: - Read Data

    func getNextPrayer() -> WidgetPrayerData? {
        guard let data = userDefaults?.data(forKey: AppGroupConfig.Keys.nextPrayer) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetPrayerData.self, from: data)
    }

    func getTodayPrayers() -> [WidgetPrayerData] {
        guard let data = userDefaults?.data(forKey: AppGroupConfig.Keys.todayPrayers) else {
            return []
        }
        return (try? JSONDecoder().decode([WidgetPrayerData].self, from: data)) ?? []
    }

    func getUpcomingTasks(limit: Int = 3) -> [WidgetTaskData] {
        guard let data = userDefaults?.data(forKey: AppGroupConfig.Keys.upcomingTasks) else {
            return []
        }
        let allTasks = (try? JSONDecoder().decode([WidgetTaskData].self, from: data)) ?? []
        return Array(allTasks.prefix(limit))
    }

    func getTheme() -> WidgetThemeData {
        guard let data = userDefaults?.data(forKey: AppGroupConfig.Keys.selectedTheme),
              let theme = try? JSONDecoder().decode(WidgetThemeData.self, from: data) else {
            return .defaultTheme
        }
        return theme
    }

    func getLastUpdate() -> Date? {
        return userDefaults?.object(forKey: AppGroupConfig.Keys.lastUpdate) as? Date
    }

    // MARK: - Write Data (Called from main app)

    func saveNextPrayer(_ prayer: WidgetPrayerData) {
        if let data = try? JSONEncoder().encode(prayer) {
            userDefaults?.set(data, forKey: AppGroupConfig.Keys.nextPrayer)
        }
        updateLastModified()
    }

    func saveTodayPrayers(_ prayers: [WidgetPrayerData]) {
        if let data = try? JSONEncoder().encode(prayers) {
            userDefaults?.set(data, forKey: AppGroupConfig.Keys.todayPrayers)
        }
        updateLastModified()
    }

    func saveUpcomingTasks(_ tasks: [WidgetTaskData]) {
        if let data = try? JSONEncoder().encode(tasks) {
            userDefaults?.set(data, forKey: AppGroupConfig.Keys.upcomingTasks)
        }
        updateLastModified()
    }

    func saveTheme(_ theme: WidgetThemeData) {
        if let data = try? JSONEncoder().encode(theme) {
            userDefaults?.set(data, forKey: AppGroupConfig.Keys.selectedTheme)
        }
        updateLastModified()
    }

    private func updateLastModified() {
        userDefaults?.set(Date(), forKey: AppGroupConfig.Keys.lastUpdate)
    }

    // MARK: - Reload Widgets

    func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    func reloadPrayerWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "PrayerTimeWidget")
    }
}

// MARK: - Color Extension for Widgets

import SwiftUI

extension Color {
    init(widgetHex: String) {
        let hex = widgetHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
