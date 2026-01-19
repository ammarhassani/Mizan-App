//
//  AppEnvironment.swift
//  Mizan
//
//  Central dependency injection container for the app
//

import SwiftUI
import SwiftData
import Combine
import CoreLocation
import os.log

@MainActor
final class AppEnvironment: ObservableObject {
    // MARK: - Singleton
    static let shared = AppEnvironment()

    // MARK: - SwiftData
    let modelContainer: ModelContainer
    private let modelContext: ModelContext

    // MARK: - Services
    let networkClient: NetworkClient
    let cacheManager: CacheManager
    let prayerTimeService: PrayerTimeService
    let locationManager: LocationManager
    let themeManager: ThemeManager
    let hapticManager: HapticManager
    let notificationManager: NotificationManager

    // AI Service (lazy initialization)
    private(set) lazy var aiTaskService: AITaskService = {
        AITaskService(config: ConfigurationManager.shared.aiConfig)
    }()

    // MARK: - User Settings
    @Published var userSettings: UserSettings

    // MARK: - App State
    @Published var isInitialized = false
    @Published var initializationError: Error?
    @Published var onboardingCompleted = false
    @Published var nawafilRefreshTrigger = 0

    /// Tracks the last date notifications were scheduled for (to avoid duplicate scheduling)
    private var lastNotificationScheduleDate: Date?

    // MARK: - Observers
    private var notificationObservers: [NSObjectProtocol] = []

    // MARK: - Data Storage State
    /// True if using fallback in-memory storage (data won't persist)
    @Published private(set) var isUsingInMemoryStorage = false

    // MARK: - Initialization
    private init() {
        // Initialize SwiftData container
        let schema = Schema([
            Task.self,
            PrayerTime.self,
            UserSettings.self,
            NawafilPrayer.self,
            UserCategory.self
        ])

        let diskConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        // Try disk storage first, fallback to in-memory if it fails
        var container: ModelContainer
        var usingInMemory = false

        do {
            container = try ModelContainer(for: schema, configurations: [diskConfiguration])
            MizanLogger.shared.storage.info("SwiftData initialized with disk storage")
        } catch {
            MizanLogger.shared.storage.warning("Disk storage failed: \(error.localizedDescription). Falling back to in-memory storage.")

            // Try in-memory as fallback
            let memoryConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                allowsSave: true
            )

            do {
                container = try ModelContainer(for: schema, configurations: [memoryConfiguration])
                usingInMemory = true
                MizanLogger.shared.storage.info("SwiftData initialized with in-memory storage (data won't persist)")
            } catch {
                // This should rarely happen - log and crash with clear message
                MizanLogger.shared.storage.error("Critical: Both disk and in-memory storage failed: \(error.localizedDescription)")
                fatalError("Unable to initialize data storage. Please reinstall the app. Error: \(error)")
            }
        }

        modelContainer = container
        modelContext = modelContainer.mainContext
        isUsingInMemoryStorage = usingInMemory

        // Initialize services
        self.networkClient = NetworkClient()
        self.cacheManager = CacheManager()
        self.prayerTimeService = PrayerTimeService(
            networkClient: networkClient,
            cacheManager: cacheManager,
            modelContext: modelContext
        )
        self.locationManager = LocationManager()
        self.themeManager = ThemeManager()
        self.hapticManager = HapticManager.shared
        self.notificationManager = NotificationManager.shared

        // Load or create user settings
        let loadedSettings: UserSettings
        do {
            let descriptor = FetchDescriptor<UserSettings>()
            let existingSettings = try modelContext.fetch(descriptor)
            if let firstSetting = existingSettings.first {
                loadedSettings = firstSetting
            } else {
                let newSettings = UserSettings()
                modelContext.insert(newSettings)
                try? modelContext.save()
                loadedSettings = newSettings
            }
            MizanLogger.shared.storage.info("User settings loaded")
        } catch {
            MizanLogger.shared.storage.error("Failed to load user settings: \(error.localizedDescription)")
            loadedSettings = UserSettings()
            modelContext.insert(loadedSettings)
        }

        self.userSettings = loadedSettings
        self.onboardingCompleted = loadedSettings.hasCompletedOnboarding

        // Migrate old default adhan to new default
        if loadedSettings.selectedAdhanAudio == "default_adhan.mp3" {
            loadedSettings.selectedAdhanAudio = "makkah_adhan.mp3"
            try? modelContext.save()
        }

        // Migrate: Create default UserCategories if none exist
        migrateToUserCategories()

        // Set up notification observers
        setupNotificationObservers()

        MizanLogger.shared.lifecycle.info("AppEnvironment initialized")
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        // Listen for task completion from notification actions
        let taskCompletionObserver = NotificationCenter.default.addObserver(
            forName: .taskCompletedFromNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let taskIdString = notification.userInfo?["taskId"] as? String,
                  let taskId = UUID(uuidString: taskIdString) else {
                return
            }
            MainActor.assumeIsolated {
                self.completeTaskFromNotification(taskId: taskId)
            }
        }
        notificationObservers.append(taskCompletionObserver)
    }

    /// Complete a task triggered by notification action
    private func completeTaskFromNotification(taskId: UUID) {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.id == taskId }
        )

        do {
            if let task = try modelContext.fetch(descriptor).first {
                task.isCompleted = true
                task.completedAt = Date()
                try modelContext.save()

                // Remove any pending notifications for this task
                notificationManager.removeTaskNotifications(for: task)

                MizanLogger.shared.task.info("Task completed from notification: \(task.title)")
                HapticManager.shared.trigger(.success)
            }
        } catch {
            MizanLogger.shared.task.error("Failed to complete task from notification: \(error.localizedDescription)")
        }
    }

    // MARK: - App Lifecycle

    /// Initialize app on launch
    func initialize() async {
        MizanLogger.shared.lifecycle.info("Initializing Mizan...")

        // 1. Load configurations
        ConfigurationManager.shared.reloadConfigurations()

        // 2. Check location authorization
        if locationManager.isAuthorized {
            do {
                // Get current location
                let location = try await locationManager.getCurrentLocation()
                userSettings.updateLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )

                // Only auto-detect calculation method for new users who haven't completed onboarding
                if !userSettings.hasCompletedOnboarding {
                    if let countryCode = await locationManager.getCountryCode(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    ) {
                        let method = CalculationMethod.default(for: countryCode)
                        userSettings.updateCalculationMethod(method)
                        MizanLogger.shared.lifecycle.info("Detected country: \(countryCode), using method: \(method.nameEnglish)")
                    }
                } else {
                    MizanLogger.shared.lifecycle.debug("Using saved calculation method: \(self.userSettings.calculationMethod.nameEnglish)")
                }

                // Fetch today's prayer times
                if let lat = userSettings.lastKnownLatitude,
                   let lon = userSettings.lastKnownLongitude {
                    _ = try await prayerTimeService.fetchTodayPrayers(
                        latitude: lat,
                        longitude: lon,
                        method: userSettings.calculationMethod
                    )

                    // Start prefetching prayer times in background
                    // Capture values before entering detached task to avoid Sendable warnings
                    let prefetchMethod = userSettings.calculationMethod
                    _Concurrency.Task.detached(priority: .background) { [weak self] in
                        guard let self = self else { return }
                        await self.prayerTimeService.prefetchPrayerTimes(
                            days: 30,
                            latitude: lat,
                            longitude: lon,
                            method: prefetchMethod
                        )
                    }
                }

            } catch {
                MizanLogger.shared.location.warning("Location initialization failed: \(error.localizedDescription)")
                initializationError = error
            }
        }

        // 3. Check Ramadan status
        if let firstPrayer = prayerTimeService.todayPrayers.first {
            themeManager.checkRamadanAutoActivation(hijriMonth: firstPrayer.hijriDate)
        }

        // 4. Apply saved theme
        themeManager.switchTheme(to: userSettings.selectedTheme, userSettings: userSettings)

        // 5. Generate nawafil for today (Pro feature)
        if userSettings.isPro && userSettings.nawafilEnabled {
            generateNawafilForDate(Date(), prayerTimes: prayerTimeService.todayPrayers)
        }

        // 6. Check notification authorization and schedule notifications
        await notificationManager.checkAuthorizationStatus()
        if notificationManager.isEnabled && userSettings.notificationsEnabled {
            // Schedule notifications for today's prayers
            await notificationManager.schedulePrayerNotifications(
                for: prayerTimeService.todayPrayers,
                userSettings: userSettings
            )

            // Schedule notifications for tomorrow's prayers to ensure next-day coverage
            if let lat = userSettings.lastKnownLatitude,
               let lon = userSettings.lastKnownLongitude,
               let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                do {
                    let tomorrowPrayers = try await prayerTimeService.fetchPrayerTimes(
                        for: tomorrow,
                        latitude: lat,
                        longitude: lon,
                        method: userSettings.calculationMethod
                    )
                    await notificationManager.schedulePrayerNotifications(
                        for: tomorrowPrayers,
                        userSettings: userSettings
                    )
                    MizanLogger.shared.notification.info("Scheduled tomorrow's prayer notifications")
                } catch {
                    MizanLogger.shared.notification.warning("Failed to schedule tomorrow's notifications: \(error.localizedDescription)")
                }
            }

            // Schedule notifications for all scheduled tasks
            let descriptor = FetchDescriptor<Task>(
                predicate: #Predicate { $0.scheduledStartTime != nil && !$0.isCompleted }
            )
            if let tasks = try? modelContext.fetch(descriptor) {
                await notificationManager.scheduleTaskNotifications(
                    for: tasks,
                    userSettings: userSettings
                )
            }

            // Track when we last scheduled notifications
            lastNotificationScheduleDate = Calendar.current.startOfDay(for: Date())
        }

        isInitialized = true
        MizanLogger.shared.lifecycle.info("Mizan initialized successfully")
    }

    /// Refresh prayer times (called when location changes significantly)
    func refreshPrayerTimes() async {
        guard let lat = userSettings.lastKnownLatitude,
              let lon = userSettings.lastKnownLongitude else {
            return
        }

        do {
            _ = try await prayerTimeService.fetchTodayPrayers(
                latitude: lat,
                longitude: lon,
                method: userSettings.calculationMethod
            )

            // Reschedule prayer notifications with new times
            if notificationManager.isEnabled && userSettings.notificationsEnabled {
                notificationManager.removeAllPrayerNotifications()
                await notificationManager.schedulePrayerNotifications(
                    for: prayerTimeService.todayPrayers,
                    userSettings: userSettings
                )
            }

            MizanLogger.shared.prayer.info("Prayer times refreshed")
        } catch {
            MizanLogger.shared.prayer.error("Failed to refresh prayer times: \(error.localizedDescription)")
        }
    }

    /// Called when app becomes active - reschedules notifications if it's a new day
    func checkAndRescheduleNotifications() async {
        let today = Calendar.current.startOfDay(for: Date())

        // Only reschedule if it's a new day since last schedule
        guard lastNotificationScheduleDate != today else {
            return
        }

        guard let lat = userSettings.lastKnownLatitude,
              let lon = userSettings.lastKnownLongitude else {
            return
        }

        guard notificationManager.isEnabled && userSettings.notificationsEnabled else {
            return
        }

        MizanLogger.shared.notification.info("New day detected - rescheduling notifications...")

        // Remove old prayer notifications
        notificationManager.removeAllPrayerNotifications()

        // Fetch and schedule today's prayers
        do {
            let todayPrayers = try await prayerTimeService.fetchPrayerTimes(
                for: Date(),
                latitude: lat,
                longitude: lon,
                method: userSettings.calculationMethod
            )
            await notificationManager.schedulePrayerNotifications(
                for: todayPrayers,
                userSettings: userSettings
            )

            // Also schedule tomorrow's prayers
            if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                let tomorrowPrayers = try await prayerTimeService.fetchPrayerTimes(
                    for: tomorrow,
                    latitude: lat,
                    longitude: lon,
                    method: userSettings.calculationMethod
                )
                await notificationManager.schedulePrayerNotifications(
                    for: tomorrowPrayers,
                    userSettings: userSettings
                )
            }

            lastNotificationScheduleDate = today
            MizanLogger.shared.notification.info("Notifications rescheduled for new day")
        } catch {
            MizanLogger.shared.notification.error("Failed to reschedule notifications: \(error.localizedDescription)")
        }
    }

    /// Update location and refresh prayer times if needed
    func updateLocation(latitude: Double, longitude: Double) async {
        let needsRefresh = prayerTimeService.needsRefresh(
            newLatitude: latitude,
            newLongitude: longitude,
            oldLatitude: userSettings.lastKnownLatitude,
            oldLongitude: userSettings.lastKnownLongitude
        )

        userSettings.updateLocation(latitude: latitude, longitude: longitude)

        if needsRefresh {
            await refreshPrayerTimes()
        }
    }

    /// Handle Pro subscription activation
    func activateProSubscription(type: String, expiryDate: Date? = nil) {
        userSettings.enableProFeatures(subscriptionType: type, expiryDate: expiryDate)
        MizanLogger.shared.storekit.info("Pro features activated: \(type)")
    }

    /// Handle Pro subscription deactivation
    func deactivateProSubscription() {
        userSettings.disableProFeatures()
        MizanLogger.shared.storekit.warning("Pro features deactivated")
    }

    // MARK: - Nawafil Generation

    /// Generate nawafil for a specific date based on user settings
    func generateNawafilForDate(_ date: Date, prayerTimes: [PrayerTime]) {
        // Only generate if Pro and nawafil are enabled
        guard userSettings.isPro && userSettings.nawafilEnabled else {
            return
        }

        // Skip if no enabled nawafil
        guard !userSettings.enabledNawafil.isEmpty else {
            return
        }

        // Delete existing nawafil for this date to avoid duplicates
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<NawafilPrayer>()
        if let existingNawafil = try? modelContext.fetch(descriptor) {
            let toDelete = existingNawafil.filter { $0.date >= startOfDay && $0.date < endOfDay }
            for nawafil in toDelete {
                modelContext.delete(nawafil)
            }
        }

        // Generate new nawafil based on enabled types and user's rakaat/time preferences
        let newNawafil = NawafilPrayer.generateForDate(
            date,
            prayerTimes: prayerTimes,
            enabledNawafilTypes: userSettings.enabledNawafil,
            rakaatPreferences: userSettings.nawafilRakaatPreferences,
            timePreferences: userSettings.nawafilTimePreferences
        )

        // Insert into SwiftData
        for nawafil in newNawafil {
            modelContext.insert(nawafil)
        }

        do {
            try modelContext.save()
            MizanLogger.shared.nawafil.info("Generated \(newNawafil.count) nawafil for \(date.formatted(date: .abbreviated, time: .omitted))")
        } catch {
            MizanLogger.shared.nawafil.error("Failed to save nawafil: \(error.localizedDescription)")
        }
    }

    /// Refresh nawafil for today when settings change
    func refreshNawafil() {
        // IMPORTANT: Notify observers FIRST to ensure UI updates
        objectWillChange.send()

        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Delete ALL nawafil for today first (regardless of enabled state)
        let nawafilDescriptor = FetchDescriptor<NawafilPrayer>()
        if let existingNawafil = try? modelContext.fetch(nawafilDescriptor) {
            let toDelete = existingNawafil.filter { $0.date >= startOfDay && $0.date < endOfDay }
            for nawafil in toDelete {
                modelContext.delete(nawafil)
            }
            // Save deletion immediately
            try? modelContext.save()
        }

        // Only regenerate if nawafil is enabled AND there are enabled types
        guard userSettings.nawafilEnabled && !userSettings.enabledNawafil.isEmpty else {
            nawafilRefreshTrigger += 1
            return
        }

        // Get today's prayers from SwiftData
        let prayerDescriptor = FetchDescriptor<PrayerTime>(
            sortBy: [SortDescriptor(\.adhanTime)]
        )

        guard let allPrayers = try? modelContext.fetch(prayerDescriptor) else {
            MizanLogger.shared.nawafil.error("Could not fetch prayers for nawafil generation")
            nawafilRefreshTrigger += 1
            return
        }

        let todayPrayers = allPrayers.filter { $0.date >= startOfDay && $0.date < endOfDay }

        guard !todayPrayers.isEmpty else {
            MizanLogger.shared.nawafil.warning("No prayers found for today - nawafil generation skipped")
            nawafilRefreshTrigger += 1
            return
        }

        // Generate new nawafil with user's rakaat and time preferences
        let newNawafil = NawafilPrayer.generateForDate(
            today,
            prayerTimes: todayPrayers,
            enabledNawafilTypes: userSettings.enabledNawafil,
            rakaatPreferences: userSettings.nawafilRakaatPreferences,
            timePreferences: userSettings.nawafilTimePreferences
        )

        for nawafil in newNawafil {
            modelContext.insert(nawafil)
        }

        do {
            try modelContext.save()
            MizanLogger.shared.nawafil.info("Generated \(newNawafil.count) nawafil for today")
        } catch {
            MizanLogger.shared.nawafil.error("Failed to save nawafil: \(error.localizedDescription)")
        }

        // Trigger view refresh
        nawafilRefreshTrigger += 1
    }

    /// Save context
    func save() {
        do {
            try modelContext.save()
        } catch {
            MizanLogger.shared.storage.error("Failed to save context: \(error.localizedDescription)")
        }
    }

    // MARK: - Category Migration

    /// Migrate to UserCategory model by creating default categories if none exist
    private func migrateToUserCategories() {
        let descriptor = FetchDescriptor<UserCategory>()

        do {
            let existingCategories = try modelContext.fetch(descriptor)

            if existingCategories.isEmpty {
                // Create default categories
                let defaultCategories = UserCategory.createDefaultCategories()
                for category in defaultCategories {
                    modelContext.insert(category)
                }

                try modelContext.save()
                MizanLogger.shared.storage.info("Created \(defaultCategories.count) default UserCategories")

                // Migrate existing tasks to use UserCategory based on their TaskCategory enum
                migrateTasksToUserCategories(defaultCategories)
            }
        } catch {
            MizanLogger.shared.storage.error("Failed to migrate to UserCategories: \(error.localizedDescription)")
        }
    }

    /// Migrate existing tasks to use UserCategory based on their legacy TaskCategory
    private func migrateTasksToUserCategories(_ categories: [UserCategory]) {
        let taskDescriptor = FetchDescriptor<Task>()

        do {
            let allTasks = try modelContext.fetch(taskDescriptor)

            var migratedCount = 0
            for task in allTasks where task.userCategory == nil {
                // Find matching UserCategory by legacy category name
                let legacyName = UserCategory.nameForLegacyCategory(task.category)
                if let matchingCategory = categories.first(where: { $0.name == legacyName }) {
                    task.userCategory = matchingCategory
                    migratedCount += 1
                }
            }

            if migratedCount > 0 {
                try modelContext.save()
                MizanLogger.shared.storage.info("Migrated \(migratedCount) tasks to UserCategories")
            }
        } catch {
            MizanLogger.shared.storage.error("Failed to migrate tasks to UserCategories: \(error.localizedDescription)")
        }
    }

    // MARK: - Recurring Tasks Generation

    /// Generate recurring task instances for a specific date
    /// This should be called when navigating to a new date in the timeline
    func generateRecurringTaskInstances(for date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Fetch all recurring parent tasks (tasks with recurrenceRule that are not child instances)
        let descriptor = FetchDescriptor<Task>()
        guard let allTasks = try? modelContext.fetch(descriptor) else {
            MizanLogger.shared.task.error("Could not fetch tasks for recurring generation")
            return
        }

        // Find parent recurring tasks (have recurrenceRule, have scheduledStartTime, no parentTaskId)
        let parentRecurringTasks = allTasks.filter { task in
            task.recurrenceRule != nil && task.scheduledStartTime != nil && task.parentTaskId == nil
        }

        // Find existing instances for this date
        let existingInstancesForDate = allTasks.filter { task in
            guard let scheduledDate = task.scheduledDate else { return false }
            return calendar.isDate(scheduledDate, inSameDayAs: date)
        }

        var generatedCount = 0

        for parentTask in parentRecurringTasks {
            guard let recurrenceRule = parentTask.recurrenceRule,
                  let originalScheduledDate = parentTask.scheduledDate else {
                continue
            }

            // Skip if this is for a date before the original task was created
            if startOfDay < calendar.startOfDay(for: originalScheduledDate) {
                continue
            }

            // Skip if the target date is the same as the original task's date
            if calendar.isDate(originalScheduledDate, inSameDayAs: date) {
                continue
            }

            // Check if recurrence should have ended
            if recurrenceRule.shouldEndBefore(date: date) {
                continue
            }

            // Check if an instance already exists for this date with this parent
            let instanceExists = existingInstancesForDate.contains { task in
                task.parentTaskId == parentTask.id
            }

            if instanceExists {
                continue
            }

            // Check if this date was dismissed by the user
            if parentTask.isInstanceDismissed(for: date) {
                continue
            }

            // Check if this date matches the recurrence pattern
            if shouldGenerateInstance(for: date, parentTask: parentTask, rule: recurrenceRule) {
                let newInstance = parentTask.createRecurringInstance(for: date)
                modelContext.insert(newInstance)
                generatedCount += 1
            }
        }

        if generatedCount > 0 {
            do {
                try modelContext.save()
                MizanLogger.shared.task.info("Generated \(generatedCount) recurring task instance(s) for \(date.formatted(date: .abbreviated, time: .omitted))")
            } catch {
                MizanLogger.shared.task.error("Failed to save recurring task instances: \(error.localizedDescription)")
            }
        }
    }

    /// Check if a recurring task should generate an instance for the given date
    private func shouldGenerateInstance(for date: Date, parentTask: Task, rule: RecurrenceRule) -> Bool {
        let calendar = Calendar.current
        guard let originalDate = parentTask.scheduledDate else { return false }

        let originalStartOfDay = calendar.startOfDay(for: originalDate)
        let targetStartOfDay = calendar.startOfDay(for: date)

        switch rule.frequency {
        case .daily:
            // Check if the date is a multiple of the interval days from original
            let daysDifference = calendar.dateComponents([.day], from: originalStartOfDay, to: targetStartOfDay).day ?? 0
            return daysDifference > 0 && daysDifference % rule.interval == 0

        case .weekly:
            if let daysOfWeek = rule.daysOfWeek, !daysOfWeek.isEmpty {
                // Check if target date's weekday is in the selected days
                let targetWeekday = calendar.component(.weekday, from: date)
                return daysOfWeek.contains(targetWeekday)
            } else {
                // Every N weeks on the same day
                let weeksDifference = calendar.dateComponents([.weekOfYear], from: originalStartOfDay, to: targetStartOfDay).weekOfYear ?? 0
                let sameWeekday = calendar.component(.weekday, from: originalDate) == calendar.component(.weekday, from: date)
                return weeksDifference > 0 && weeksDifference % rule.interval == 0 && sameWeekday
            }

        case .monthly:
            // Every N months on the same day of month
            let monthsDifference = calendar.dateComponents([.month], from: originalStartOfDay, to: targetStartOfDay).month ?? 0
            let sameDay = calendar.component(.day, from: originalDate) == calendar.component(.day, from: date)
            return monthsDifference > 0 && monthsDifference % rule.interval == 0 && sameDay
        }
    }

    /// Mark onboarding as complete - fetches prayers FIRST, then transitions UI
    func markOnboardingComplete() async {
        // Fetch prayers BEFORE transitioning UI so TimelineView sees them when it mounts
        await completePostOnboardingSetup()

        // Now transition UI (TimelineView's @Query will find prayers in database)
        userSettings.completeOnboarding()
        save()
        onboardingCompleted = true
        MizanLogger.shared.lifecycle.info("Onboarding completed")
    }

    /// Fetch prayer times and complete setup after onboarding
    private func completePostOnboardingSetup() async {
        // Get location from LocationManager (not userSettings - it hasn't been updated yet)
        guard locationManager.isAuthorized,
              let location = locationManager.currentLocation else {
            MizanLogger.shared.location.warning("Cannot fetch prayers - location not available")
            return
        }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        // Update userSettings with the location
        userSettings.updateLocation(latitude: lat, longitude: lon)
        save()

        // Auto-detect calculation method based on country
        if let countryCode = await locationManager.getCountryCode(latitude: lat, longitude: lon) {
            let method = CalculationMethod.default(for: countryCode)
            userSettings.updateCalculationMethod(method)
            MizanLogger.shared.lifecycle.info("Detected country: \(countryCode), using method: \(method.nameEnglish)")
        }

        do {
            // Fetch today's prayer times
            _ = try await prayerTimeService.fetchTodayPrayers(
                latitude: lat,
                longitude: lon,
                method: userSettings.calculationMethod
            )
            MizanLogger.shared.prayer.info("Prayer times fetched after onboarding")

            // Schedule notifications if enabled
            if notificationManager.isEnabled && userSettings.notificationsEnabled {
                await notificationManager.schedulePrayerNotifications(
                    for: prayerTimeService.todayPrayers,
                    userSettings: userSettings
                )
            }

            // Prefetch next 30 days in background
            // Capture method before entering detached task to avoid Sendable warnings
            let prefetchMethod = userSettings.calculationMethod
            _Concurrency.Task.detached(priority: .background) { [weak self] in
                guard let self = self else { return }
                await self.prayerTimeService.prefetchPrayerTimes(
                    days: 30,
                    latitude: lat,
                    longitude: lon,
                    method: prefetchMethod
                )
            }
        } catch {
            MizanLogger.shared.prayer.error("Failed to fetch prayer times after onboarding: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview Helper

extension AppEnvironment {
    /// Create a mock environment for SwiftUI previews
    static func preview() -> AppEnvironment {
        let env = AppEnvironment.shared
        env.isInitialized = true
        return env
    }
}
