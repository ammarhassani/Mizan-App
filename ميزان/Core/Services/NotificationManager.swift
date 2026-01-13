//
//  NotificationManager.swift
//  Mizan
//
//  Manages all app notifications (prayers, tasks, reminders)
//

import Foundation
import UserNotifications
import AVFoundation

@MainActor
final class NotificationManager: ObservableObject {
    // MARK: - Singleton
    static let shared = NotificationManager()

    // MARK: - Published State
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isEnabled = false

    // MARK: - Notification Config
    private let config: NotificationConfig
    private let audioPlayer: AVAudioPlayer?

    // MARK: - Notification Categories
    private enum Category: String {
        case prayer = "PRAYER_NOTIFICATION"
        case task = "TASK_NOTIFICATION"
        case reminder = "REMINDER_NOTIFICATION"
    }

    // MARK: - Notification Actions
    private enum Action: String {
        case completeTask = "COMPLETE_TASK"
        case snooze = "SNOOZE"
        case dismiss = "DISMISS"
    }

    // MARK: - Initialization

    private init() {
        self.config = ConfigurationManager.shared.notificationConfig

        // Initialize audio player with default adhan
        var player: AVAudioPlayer?
        if let adhanURL = Bundle.main.url(forResource: "adhan_makkah", withExtension: "mp3") {
            player = try? AVAudioPlayer(contentsOf: adhanURL)
            player?.prepareToPlay()
        }
        self.audioPlayer = player

        // Check current authorization status
        Task {
            await checkAuthorizationStatus()
        }

        // Set up notification categories and actions
        setupNotificationCategories()
    }

    // MARK: - Authorization

    /// Request notification permission from user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])

            await checkAuthorizationStatus()
            return granted
        } catch {
            print("❌ Notification authorization error: \(error)")
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isEnabled = settings.authorizationStatus == .authorized
    }

    // MARK: - Setup

    private func setupNotificationCategories() {
        // Prayer notification actions
        let prayerCategory = UNNotificationCategory(
            identifier: Category.prayer.rawValue,
            actions: [
                UNNotificationAction(
                    identifier: Action.dismiss.rawValue,
                    title: "تم",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        // Task notification actions
        let taskCategory = UNNotificationCategory(
            identifier: Category.task.rawValue,
            actions: [
                UNNotificationAction(
                    identifier: Action.completeTask.rawValue,
                    title: "وضع علامة مكتمل",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: Action.snooze.rawValue,
                    title: "تأجيل 15 دقيقة",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            prayerCategory,
            taskCategory
        ])
    }

    // MARK: - Prayer Notifications

    /// Schedule all notifications for a prayer time
    func schedulePrayerNotifications(for prayer: PrayerTime, userSettings: UserSettings) async {
        guard isEnabled, userSettings.notificationsEnabled else { return }

        // Get notification settings from config
        let prayerNotifications = config.prayerNotifications

        // 10 minutes before
        if let beforeNotif = prayerNotifications.first(where: { $0.timing == "before" }) {
            await schedulePrayerNotification(
                prayer: prayer,
                timing: .before,
                minutesOffset: beforeNotif.minutesOffset,
                template: beforeNotif.titleArabic,
                bodyTemplate: beforeNotif.bodyArabic,
                sound: beforeNotif.sound
            )
        }

        // At adhan time
        if let atTimeNotif = prayerNotifications.first(where: { $0.timing == "at_time" }) {
            await schedulePrayerNotification(
                prayer: prayer,
                timing: .atTime,
                minutesOffset: 0,
                template: atTimeNotif.titleArabic,
                bodyTemplate: atTimeNotif.bodyArabic,
                sound: atTimeNotif.sound
            )
        }

        // 5 minutes after
        if let afterNotif = prayerNotifications.first(where: { $0.timing == "after" }) {
            await schedulePrayerNotification(
                prayer: prayer,
                timing: .after,
                minutesOffset: afterNotif.minutesOffset,
                template: afterNotif.titleArabic,
                bodyTemplate: afterNotif.bodyArabic,
                sound: afterNotif.sound
            )
        }
    }

    private enum PrayerNotificationTiming {
        case before, atTime, after
    }

    private func schedulePrayerNotification(
        prayer: PrayerTime,
        timing: PrayerNotificationTiming,
        minutesOffset: Int,
        template: String,
        bodyTemplate: String,
        sound: String?
    ) async {
        let triggerDate: Date
        switch timing {
        case .before:
            triggerDate = prayer.adhanTime.addingTimeInterval(TimeInterval(minutesOffset * 60))
        case .atTime:
            triggerDate = prayer.adhanTime
        case .after:
            triggerDate = prayer.adhanTime.addingTimeInterval(TimeInterval(-minutesOffset * 60))
        }

        // Don't schedule if in the past
        guard triggerDate > Date() else { return }

        // Replace placeholders in template
        let title = template.replacingOccurrences(of: "{prayer_name}", with: prayer.displayName)
        let body = bodyTemplate.replacingOccurrences(of: "{minutes}", with: "\(abs(minutesOffset))")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = Category.prayer.rawValue
        content.sound = timing == .atTime ? .default : .default // Adhan sound for atTime
        content.badge = 1
        content.userInfo = [
            "prayerType": prayer.prayerType.rawValue,
            "prayerId": prayer.id.uuidString,
            "timing": "\(timing)"
        ]

        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let identifier = "prayer_\(prayer.id.uuidString)_\(timing)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Scheduled prayer notification: \(prayer.displayName) - \(timing)")
        } catch {
            print("❌ Failed to schedule prayer notification: \(error)")
        }
    }

    /// Remove all prayer notifications
    func removeAllPrayerNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let prayerIdentifiers = requests
                .filter { $0.identifier.starts(with: "prayer_") }
                .map { $0.identifier }

            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: prayerIdentifiers
            )
            print("🗑️ Removed \(prayerIdentifiers.count) prayer notifications")
        }
    }

    // MARK: - Task Notifications

    /// Schedule notification for a task
    func scheduleTaskNotification(for task: Task, userSettings: UserSettings) async {
        guard isEnabled, userSettings.notificationsEnabled else { return }
        guard let scheduledTime = task.scheduledStartTime else { return }
        guard scheduledTime > Date() else { return } // Don't schedule past tasks

        let taskNotifications = config.taskNotifications

        // At start time (available for all users)
        if let atStartNotif = taskNotifications.first(where: { $0.timing == "at_start" }) {
            await scheduleTaskNotificationAtTime(
                task: task,
                triggerDate: scheduledTime,
                template: atStartNotif.titleArabic,
                bodyTemplate: atStartNotif.bodyArabic
            )
        }

        // Before start (Pro only)
        if userSettings.isPro {
            if let beforeNotif = taskNotifications.first(where: { $0.timing == "before" }) {
                let beforeDate = scheduledTime.addingTimeInterval(TimeInterval(beforeNotif.minutesOffset * 60))
                if beforeDate > Date() {
                    await scheduleTaskNotificationAtTime(
                        task: task,
                        triggerDate: beforeDate,
                        template: beforeNotif.titleArabic,
                        bodyTemplate: beforeNotif.bodyArabic
                    )
                }
            }
        }
    }

    private func scheduleTaskNotificationAtTime(
        task: Task,
        triggerDate: Date,
        template: String,
        bodyTemplate: String
    ) async {
        let title = template.replacingOccurrences(of: "{task_title}", with: task.title)
        let body = bodyTemplate.replacingOccurrences(of: "{duration}", with: "\(task.duration)")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = Category.task.rawValue
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "taskId": task.id.uuidString,
            "taskTitle": task.title
        ]

        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let identifier = "task_\(task.id.uuidString)_\(Int(triggerDate.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Scheduled task notification: \(task.title)")
        } catch {
            print("❌ Failed to schedule task notification: \(error)")
        }
    }

    /// Remove notifications for a specific task
    func removeTaskNotifications(for task: Task) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let taskIdentifiers = requests
                .filter { $0.identifier.contains(task.id.uuidString) }
                .map { $0.identifier }

            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: taskIdentifiers
            )
            print("🗑️ Removed notifications for task: \(task.title)")
        }
    }

    /// Remove all task notifications
    func removeAllTaskNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let taskIdentifiers = requests
                .filter { $0.identifier.starts(with: "task_") }
                .map { $0.identifier }

            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: taskIdentifiers
            )
            print("🗑️ Removed \(taskIdentifiers.count) task notifications")
        }
    }

    // MARK: - Adhan Playback

    /// Play adhan audio
    func playAdhan(style: String = "makkah") {
        guard let player = audioPlayer else {
            print("⚠️ Audio player not initialized")
            return
        }

        player.play()
        print("🔊 Playing adhan: \(style)")
    }

    /// Stop adhan audio
    func stopAdhan() {
        audioPlayer?.stop()
    }

    // MARK: - Bulk Operations

    /// Schedule notifications for all prayers in a date range
    func schedulePrayerNotifications(
        for prayers: [PrayerTime],
        userSettings: UserSettings
    ) async {
        for prayer in prayers {
            await schedulePrayerNotifications(for: prayer, userSettings: userSettings)
        }
    }

    /// Schedule notifications for all scheduled tasks
    func scheduleTaskNotifications(
        for tasks: [Task],
        userSettings: UserSettings
    ) async {
        for task in tasks where task.scheduledStartTime != nil {
            await scheduleTaskNotification(for: task, userSettings: userSettings)
        }
    }

    /// Remove all notifications
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("🗑️ Removed all notifications")
    }

    // MARK: - Debug

    /// Get count of pending notifications
    func getPendingNotificationsCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.count
    }

    /// Print all pending notifications (debug)
    func printPendingNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📋 Pending notifications: \(requests.count)")
        for request in requests {
            print("  - \(request.identifier): \(request.content.title)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification action
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case Action.completeTask.rawValue:
            if let taskId = userInfo["taskId"] as? String {
                // TODO: Mark task as complete
                print("✅ Completing task: \(taskId)")
            }

        case Action.snooze.rawValue:
            // Reschedule notification for 15 minutes later
            print("⏰ Snoozing notification")

        default:
            break
        }

        completionHandler()
    }
}
