//
//  NotificationManager.swift
//  Mizan
//
//  Manages all app notifications (prayers, tasks, reminders)
//

import Foundation
import UserNotifications
import AVFoundation
import Combine

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    // MARK: - Singleton
    static let shared = NotificationManager()

    // MARK: - Published State
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isEnabled = false

    // MARK: - Notification Config
    private let config: NotificationConfiguration
    private var audioPlayer: AVAudioPlayer?

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

    override private init() {
        self.config = ConfigurationManager.shared.notificationConfig

        // Initialize audio player with default adhan
        var player: AVAudioPlayer?
        if let adhanURL = Bundle.main.url(forResource: "adhan_makkah", withExtension: "mp3") {
            player = try? AVAudioPlayer(contentsOf: adhanURL)
            player?.prepareToPlay()
        }
        self.audioPlayer = player

        super.init()
        UNUserNotificationCenter.current().delegate = self

        // Set up notification categories and actions
        setupNotificationCategories()

        // Check current authorization status
        _Concurrency.Task {
            await checkAuthorizationStatus()
        }
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
        guard isEnabled, userSettings.notificationsEnabled, userSettings.prayerNotificationsEnabled else { return }

        // Get notification settings from config
        let prayerNotifications = config.prayerNotifications

        // Before adhan (user-selected minutes)
        let beforeNotif = prayerNotifications.beforePrayer
        await schedulePrayerNotification(
            prayer: prayer,
            timing: .before,
            minutesOffset: userSettings.prayerReminderMinutes,
            template: beforeNotif.titleTemplateArabic,
            bodyTemplate: beforeNotif.bodyTemplateArabic,
            sound: beforeNotif.sound
        )

        // At adhan time - use user's selected adhan sound
        let atTimeNotif = prayerNotifications.atPrayerTime
        let adhanNotificationSound = resolveNotificationSoundFile(for: userSettings.selectedAdhanAudio)
        await schedulePrayerNotification(
            prayer: prayer,
            timing: .atAdhan,
            minutesOffset: 0,
            template: atTimeNotif.titleTemplateArabic,
            bodyTemplate: atTimeNotif.bodyTemplateArabic,
            sound: adhanNotificationSound
        )

        // At iqama time
        let iqamaNotif = prayerNotifications.atIqama
        await schedulePrayerNotification(
            prayer: prayer,
            timing: .atIqama,
            minutesOffset: 0,
            template: iqamaNotif.titleTemplateArabic,
            bodyTemplate: iqamaNotif.bodyTemplateArabic,
            sound: iqamaNotif.sound
        )
    }

    private enum PrayerNotificationTiming {
        case before, atAdhan, atIqama
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
            // Trigger X minutes BEFORE adhan (subtract time)
            triggerDate = prayer.adhanTime.addingTimeInterval(TimeInterval(-minutesOffset * 60))
        case .atAdhan:
            triggerDate = prayer.adhanTime
        case .atIqama:
            // Trigger at iqama time (adhan + iqama offset)
            triggerDate = prayer.iqamaStartTime
        }

        print("🔔 Scheduling \(timing) for \(prayer.displayName): trigger=\(triggerDate), now=\(Date()), adhan=\(prayer.adhanTime)")

        // Don't schedule if in the past
        guard triggerDate > Date() else {
            print("⏭️ Skipping \(timing) for \(prayer.displayName) - already past")
            return
        }

        // Replace placeholders in templates
        let title = template.replacingOccurrences(of: "{prayer_name}", with: prayer.displayName)
        let body = bodyTemplate
            .replacingOccurrences(of: "{prayer_name}", with: prayer.displayName)
            .replacingOccurrences(of: "{minutes}", with: "\(abs(minutesOffset))")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = Category.prayer.rawValue
        // Use custom sound if provided, otherwise default
        if let soundName = sound, !soundName.isEmpty, soundName != "adhan_selected_by_user" {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        } else {
            content.sound = .default
        }
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
        guard isEnabled, userSettings.notificationsEnabled, userSettings.taskNotificationsEnabled else { return }
        guard let scheduledTime = task.scheduledStartTime else { return }
        guard scheduledTime > Date() else { return } // Don't schedule past tasks

        let taskNotifications = config.taskNotifications

        // At start time (available for all users)
        let atStartNotif = taskNotifications.atTaskStart
        await scheduleTaskNotificationAtTime(
            task: task,
            triggerDate: scheduledTime,
            template: atStartNotif.titleTemplateArabic,
            bodyTemplate: atStartNotif.bodyTemplateArabic
        )

        // Before start (Pro only)
        if userSettings.isPro {
            let beforeNotif = taskNotifications.beforeTaskStart
            if let minutesBefore = beforeNotif.defaultMinutes {
                let beforeDate = scheduledTime.addingTimeInterval(TimeInterval(-minutesBefore * 60))
                if beforeDate > Date() {
                    await scheduleTaskNotificationAtTime(
                        task: task,
                        triggerDate: beforeDate,
                        template: beforeNotif.titleTemplateArabic,
                        bodyTemplate: beforeNotif.bodyTemplateArabic
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
        // Capture only the needed values to avoid Sendable warnings
        let taskIdString = task.id.uuidString
        let taskTitle = task.title
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let taskIdentifiers = requests
                .filter { $0.identifier.contains(taskIdString) }
                .map { $0.identifier }

            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: taskIdentifiers
            )
            print("🗑️ Removed notifications for task: \(taskTitle)")
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

    /// Resolve the notification sound file for adhan - tries notification version first, then original
    private func resolveNotificationSoundFile(for selectedAdhan: String) -> String? {
        // Extract the base name without extension
        let baseName = selectedAdhan.replacingOccurrences(of: ".mp3", with: "")

        // Try notification-specific version first (shorter, optimized for notifications)
        let notificationVersion = "\(baseName)_notification"
        if Bundle.main.url(forResource: notificationVersion, withExtension: "mp3") != nil {
            return "\(notificationVersion).mp3"
        }

        // Try the original adhan file
        if Bundle.main.url(forResource: baseName, withExtension: "mp3") != nil {
            print("⚠️ Using original adhan file for notification (notification version not found): \(baseName)")
            return selectedAdhan
        }

        // Try alternative naming patterns
        let alternativeNames = [
            "adhan_\(baseName)",
            baseName.replacingOccurrences(of: "_adhan", with: ""),
            "\(baseName)_adhan"
        ]
        for altName in alternativeNames {
            if Bundle.main.url(forResource: altName, withExtension: "mp3") != nil {
                print("⚠️ Using alternative adhan file for notification: \(altName)")
                return "\(altName).mp3"
            }
        }

        print("❌ No adhan sound file found for: \(selectedAdhan) - using default notification sound")
        return nil
    }

    /// Check if a specific adhan audio file is available
    func isAdhanAvailable(id: String) -> Bool {
        // Try multiple filename patterns
        let possibleNames = [id, "\(id)_adhan", "adhan_\(id)", id.replacingOccurrences(of: "_adhan", with: "")]
        for name in possibleNames {
            if Bundle.main.url(forResource: name, withExtension: "mp3") != nil {
                return true
            }
        }
        return false
    }

    /// Play adhan audio
    func playAdhan(style: String = "makkah") {
        // Try to load the specific adhan file
        let possibleNames = [style, "\(style)_adhan", "adhan_\(style)", style.replacingOccurrences(of: "_adhan", with: "")]
        var audioURL: URL?

        for name in possibleNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
                audioURL = url
                break
            }
        }

        guard let url = audioURL else {
            print("⚠️ Adhan audio file not found for: \(style)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("🔊 Playing adhan: \(style)")
        } catch {
            print("❌ Failed to play adhan: \(error)")
        }
    }

    /// Stop adhan audio
    func stopAdhan() {
        audioPlayer?.stop()
    }

    // MARK: - Test Notifications

    /// Schedule test notifications for debugging (fires in 10, 20, 30 seconds)
    func scheduleTestNotifications(userSettings: UserSettings) async {
        let adhanSound = userSettings.selectedAdhanAudio
            .replacingOccurrences(of: ".mp3", with: "_notification.mp3")

        // Test 1: Before adhan (10 sec)
        await scheduleTestNotification(
            title: "تجربة: قبل الأذان",
            body: "متبقي 10 دقيقة على الصلاة",
            sound: nil,
            delay: 10
        )

        // Test 2: At adhan (20 sec)
        await scheduleTestNotification(
            title: "تجربة: الأذان",
            body: "حان الآن وقت الصلاة",
            sound: adhanSound,
            delay: 20
        )

        // Test 3: At iqama (30 sec)
        await scheduleTestNotification(
            title: "تجربة: الإقامة",
            body: "حان وقت إقامة الصلاة",
            sound: nil,
            delay: 30
        )

        print("🧪 Scheduled 3 test notifications (10s, 20s, 30s)")
    }

    private func scheduleTestNotification(title: String, body: String, sound: String?, delay: Int) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let soundName = sound, !soundName.isEmpty {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        } else {
            content.sound = .default
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(delay), repeats: false)
        let request = UNNotificationRequest(identifier: "test_\(delay)", content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Test notification scheduled for \(delay)s")
        } catch {
            print("❌ Failed to schedule test: \(error)")
        }
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

// MARK: - Notification Names for App Communication

extension Notification.Name {
    /// Posted when user taps "Mark Complete" on a task notification
    static let taskCompletedFromNotification = Notification.Name("taskCompletedFromNotification")
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
        let originalContent = response.notification.request.content

        switch response.actionIdentifier {
        case Action.completeTask.rawValue:
            if let taskIdString = userInfo["taskId"] as? String {
                // Post notification to main thread for task completion
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .taskCompletedFromNotification,
                        object: nil,
                        userInfo: ["taskId": taskIdString]
                    )
                }
                print("✅ Posted task completion for: \(taskIdString)")
            }

        case Action.snooze.rawValue:
            // Reschedule notification for 15 minutes later
            let snoozeMinutes = 15
            let newContent = UNMutableNotificationContent()
            newContent.title = originalContent.title
            newContent.body = "⏰ تم التأجيل - \(originalContent.body)"
            newContent.sound = .default
            newContent.categoryIdentifier = originalContent.categoryIdentifier
            newContent.userInfo = userInfo

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(snoozeMinutes * 60),
                repeats: false
            )

            let identifier = "snoozed_\(UUID().uuidString)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: newContent,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to snooze notification: \(error)")
                } else {
                    print("⏰ Snoozed notification for \(snoozeMinutes) minutes")
                }
            }

        default:
            break
        }

        completionHandler()
    }
}
