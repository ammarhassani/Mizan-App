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

    // MARK: - User Settings
    @Published var userSettings: UserSettings

    // MARK: - App State
    @Published var isInitialized = false
    @Published var initializationError: Error?
    @Published var onboardingCompleted = false

    // MARK: - Initialization
    private init() {
        // Initialize SwiftData container
        let schema = Schema([
            Task.self,
            PrayerTime.self,
            UserSettings.self,
            NawafilPrayer.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext

            print("✅ SwiftData initialized")

        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }

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
            print("✅ User settings loaded")
        } catch {
            print("❌ Failed to load user settings: \(error)")
            loadedSettings = UserSettings()
            modelContext.insert(loadedSettings)
        }

        self.userSettings = loadedSettings
        self.onboardingCompleted = loadedSettings.hasCompletedOnboarding

        print("✅ AppEnvironment initialized")
    }

    // MARK: - App Lifecycle

    /// Initialize app on launch
    func initialize() async {
        print("🚀 Initializing Mizan...")

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
                        print("✅ Detected country: \(countryCode), using method: \(method.nameEnglish)")
                    }
                } else {
                    print("✅ Using saved calculation method: \(userSettings.calculationMethod.nameEnglish)")
                }

                // Fetch today's prayer times
                if let lat = userSettings.lastKnownLatitude,
                   let lon = userSettings.lastKnownLongitude {
                    _ = try await prayerTimeService.fetchTodayPrayers(
                        latitude: lat,
                        longitude: lon,
                        method: userSettings.calculationMethod
                    )
                }

                // Start prefetching prayer times in background
                _Concurrency.Task.detached(priority: .background) { [weak self] in
                    guard let self = self else { return }
                    if let lat = await self.userSettings.lastKnownLatitude,
                       let lon = await self.userSettings.lastKnownLongitude {
                        await self.prayerTimeService.prefetchPrayerTimes(
                            days: 30,
                            latitude: lat,
                            longitude: lon,
                            method: await self.userSettings.calculationMethod
                        )
                    }
                }

            } catch {
                print("⚠️ Location initialization failed: \(error)")
                initializationError = error
            }
        }

        // 3. Check Ramadan status
        if let firstPrayer = prayerTimeService.todayPrayers.first {
            themeManager.checkRamadanAutoActivation(hijriMonth: firstPrayer.hijriDate)
        }

        // 4. Apply saved theme
        themeManager.switchTheme(to: userSettings.selectedTheme, userSettings: userSettings)

        // 5. Check notification authorization and schedule notifications
        await notificationManager.checkAuthorizationStatus()
        if notificationManager.isEnabled && userSettings.notificationsEnabled {
            // Schedule notifications for today's prayers
            await notificationManager.schedulePrayerNotifications(
                for: prayerTimeService.todayPrayers,
                userSettings: userSettings
            )

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
        }

        isInitialized = true
        print("✅ Mizan initialized successfully")
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

            print("✅ Prayer times refreshed")
        } catch {
            print("❌ Failed to refresh prayer times: \(error)")
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
        print("✨ Pro features activated: \(type)")
    }

    /// Handle Pro subscription deactivation
    func deactivateProSubscription() {
        userSettings.disableProFeatures()
        print("⚠️ Pro features deactivated")
    }

    /// Save context
    func save() {
        do {
            try modelContext.save()
            print("💾 Context saved")
        } catch {
            print("❌ Failed to save context: \(error)")
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
        print("✅ Onboarding completed")
    }

    /// Fetch prayer times and complete setup after onboarding
    private func completePostOnboardingSetup() async {
        // Get location from LocationManager (not userSettings - it hasn't been updated yet)
        guard locationManager.isAuthorized,
              let location = locationManager.currentLocation else {
            print("⚠️ Cannot fetch prayers - location not available")
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
            print("✅ Detected country: \(countryCode), using method: \(method.nameEnglish)")
        }

        do {
            // Fetch today's prayer times
            _ = try await prayerTimeService.fetchTodayPrayers(
                latitude: lat,
                longitude: lon,
                method: userSettings.calculationMethod
            )
            print("✅ Prayer times fetched after onboarding")

            // Schedule notifications if enabled
            if notificationManager.isEnabled && userSettings.notificationsEnabled {
                await notificationManager.schedulePrayerNotifications(
                    for: prayerTimeService.todayPrayers,
                    userSettings: userSettings
                )
            }

            // Prefetch next 30 days in background
            _Concurrency.Task.detached(priority: .background) { [weak self] in
                guard let self = self else { return }
                await self.prayerTimeService.prefetchPrayerTimes(
                    days: 30,
                    latitude: lat,
                    longitude: lon,
                    method: await self.userSettings.calculationMethod
                )
            }
        } catch {
            print("❌ Failed to fetch prayer times after onboarding: \(error)")
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
