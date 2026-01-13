//
//  PrayerTimeService.swift
//  Mizan
//
//  Service for fetching and managing prayer times from Aladhan API
//

import Foundation
import SwiftData
import Combine

@MainActor
final class PrayerTimeService: ObservableObject {
    // MARK: - Published Properties
    @Published var todayPrayers: [PrayerTime] = []
    @Published var isLoading = false
    @Published var error: APIError?
    @Published var lastUpdateTime: Date?
    @Published var isOfflineMode = false

    // MARK: - Dependencies
    private let networkClient: NetworkClient
    private let cacheManager: CacheManager
    private let modelContext: ModelContext

    // MARK: - Initialization
    init(networkClient: NetworkClient, cacheManager: CacheManager, modelContext: ModelContext) {
        self.networkClient = networkClient
        self.cacheManager = cacheManager
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// Fetch prayer times for a specific date
    func fetchPrayerTimes(
        for date: Date,
        latitude: Double,
        longitude: Double,
        method: CalculationMethod
    ) async throws -> [PrayerTime] {
        // 1. Try to load from SwiftData cache first (offline-first)
        if let cached = try? fetchCachedPrayers(for: date, latitude: latitude, longitude: longitude, method: method) {
            print("✅ Loaded prayer times from SwiftData cache")
            return cached
        }

        // 2. Try to load from file cache
        let cacheKey = CacheManager.prayerTimesKey(date: date, latitude: latitude, longitude: longitude, method: method)
        if let cachedResponse = cacheManager.load(forKey: cacheKey, as: AladhanResponse.self) {
            print("✅ Loaded prayer times from file cache")
            let prayers = try parsePrayerTimes(from: cachedResponse, date: date, method: method, latitude: latitude, longitude: longitude)
            try savePrayers(prayers)
            return prayers
        }

        // 3. Fetch from API
        isLoading = true
        isOfflineMode = false
        error = nil

        do {
            let endpoint = APIEndpoint.prayerTimes(
                date: date,
                latitude: latitude,
                longitude: longitude,
                method: method.apiCode
            )

            let response: AladhanResponse = try await networkClient.request(endpoint)

            // 4. Save to file cache
            cacheManager.save(response, forKey: cacheKey)

            // 5. Parse and save to SwiftData
            let prayers = try parsePrayerTimes(from: response, date: date, method: method, latitude: latitude, longitude: longitude)
            try savePrayers(prayers)

            lastUpdateTime = Date()
            isLoading = false

            print("✅ Fetched and cached prayer times for \(date)")
            return prayers

        } catch {
            isLoading = false
            self.error = error as? APIError ?? .networkError(error)

            // Try to return cached data on error
            if let cached = try? fetchCachedPrayers(for: date, latitude: latitude, longitude: longitude, method: method) {
                isOfflineMode = true
                print("⚠️ API failed, using offline cache")
                return cached
            }

            throw error
        }
    }

    /// Prefetch prayer times for the next N days (for offline support)
    func prefetchPrayerTimes(
        days: Int = 30,
        latitude: Double,
        longitude: Double,
        method: CalculationMethod
    ) async {
        print("📥 Starting prefetch for \(days) days...")

        for dayOffset in 0..<days {
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) else {
                continue
            }

            // Skip if already cached
            if (try? fetchCachedPrayers(for: date, latitude: latitude, longitude: longitude, method: method)) != nil {
                continue
            }

            // Fetch with delay to avoid rate limiting
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay

            do {
                _ = try await fetchPrayerTimes(for: date, latitude: latitude, longitude: longitude, method: method)
                print("✅ Prefetched day \(dayOffset + 1)/\(days)")
            } catch {
                print("⚠️ Failed to prefetch day \(dayOffset + 1): \(error)")
            }
        }

        print("✅ Prefetch completed")
    }

    /// Get today's prayer times
    func fetchTodayPrayers(
        latitude: Double,
        longitude: Double,
        method: CalculationMethod
    ) async throws -> [PrayerTime] {
        let today = Date()
        let prayers = try await fetchPrayerTimes(for: today, latitude: latitude, longitude: longitude, method: method)
        todayPrayers = prayers
        return prayers
    }

    /// Check if prayer times need to be refreshed (location changed significantly)
    func needsRefresh(
        newLatitude: Double,
        newLongitude: Double,
        oldLatitude: Double?,
        oldLongitude: Double?
    ) -> Bool {
        guard let oldLat = oldLatitude, let oldLon = oldLongitude else {
            return true // No previous location
        }

        // Calculate distance using Haversine
        let distance = haversineDistance(
            lat1: oldLat, lon1: oldLon,
            lat2: newLatitude, lon2: newLongitude
        )

        // Refresh if moved more than 50km
        return distance > 50_000
    }

    // MARK: - Private Methods

    /// Fetch cached prayers from SwiftData
    private func fetchCachedPrayers(
        for date: Date,
        latitude: Double,
        longitude: Double,
        method: CalculationMethod
    ) throws -> [PrayerTime]? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<PrayerTime>(
            predicate: #Predicate { prayer in
                prayer.date >= startOfDay &&
                prayer.date < endOfDay &&
                abs(prayer.latitude - latitude) < 0.1 &&
                abs(prayer.longitude - longitude) < 0.1 &&
                prayer.calculationMethod == method
            },
            sortBy: [SortDescriptor(\.adhanTime)]
        )

        let results = try modelContext.fetch(descriptor)

        // Return nil if we don't have all 5 prayers
        guard results.count == 5 else { return nil }

        return results
    }

    /// Parse Aladhan API response into PrayerTime models
    private func parsePrayerTimes(
        from response: AladhanResponse,
        date: Date,
        method: CalculationMethod,
        latitude: Double,
        longitude: Double
    ) throws -> [PrayerTime] {
        let timings = response.data.timings
        let hijriDate = response.data.date.hijri.date
        let calendar = Calendar.current

        // Check if today is Friday for Jummah
        let isFriday = calendar.component(.weekday, from: date) == 6 // 6 = Friday

        var prayers: [PrayerTime] = []

        for prayerType in PrayerType.allCases {
            guard let timeString = timings.time(for: prayerType),
                  let adhanTime = response.data.parseTime(timeString, on: date) else {
                continue
            }

            let prayer = PrayerTime(
                date: date,
                prayerType: prayerType,
                adhanTime: adhanTime,
                calculationMethod: method,
                latitude: latitude,
                longitude: longitude
            )

            prayer.hijriDate = hijriDate

            // Apply durations and buffers from config
            let config = ConfigurationManager.shared.prayerConfig.defaults[prayerType.rawValue]
            if let config = config {
                prayer.duration = config.durationMinutes
                prayer.bufferBefore = config.bufferBeforeMinutes
                prayer.bufferAfter = config.bufferAfterMinutes
            }

            // Convert to Jummah if Friday and Dhuhr
            if isFriday && prayerType == .dhuhr {
                prayer.convertToJummah()
            }

            prayers.append(prayer)
        }

        return prayers.sorted { $0.adhanTime < $1.adhanTime }
    }

    /// Save prayers to SwiftData
    private func savePrayers(_ prayers: [PrayerTime]) throws {
        // Delete existing prayers for this date/location to avoid duplicates
        if let firstPrayer = prayers.first {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: firstPrayer.date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<PrayerTime>(
                predicate: #Predicate { prayer in
                    prayer.date >= startOfDay &&
                    prayer.date < endOfDay &&
                    abs(prayer.latitude - firstPrayer.latitude) < 0.1 &&
                    abs(prayer.longitude - firstPrayer.longitude) < 0.1
                }
            )

            let existing = try modelContext.fetch(descriptor)
            for prayer in existing {
                modelContext.delete(prayer)
            }
        }

        // Insert new prayers
        for prayer in prayers {
            modelContext.insert(prayer)
        }

        try modelContext.save()
    }

    /// Calculate distance between two coordinates (Haversine formula)
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0 // Earth's radius in meters
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180

        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon/2) * sin(dLon/2)

        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }

    // MARK: - Utility Methods

    /// Get next upcoming prayer
    func nextPrayer(from prayers: [PrayerTime]) -> PrayerTime? {
        let now = Date()
        return prayers.first { $0.adhanTime > now }
    }

    /// Get current prayer (if we're in prayer time now)
    func currentPrayer(from prayers: [PrayerTime]) -> PrayerTime? {
        let now = Date()
        return prayers.first { $0.timeRange.contains(now) }
    }

    /// Check if location services are available and authorized
    func checkLocationAuthorization() async -> Bool {
        // This will be implemented in LocationManager
        return true
    }

    /// Clear all cached prayer times
    func clearCache() {
        // Clear file cache
        cacheManager.clearAll()

        // Clear SwiftData cache
        let descriptor = FetchDescriptor<PrayerTime>()
        if let allPrayers = try? modelContext.fetch(descriptor) {
            for prayer in allPrayers {
                modelContext.delete(prayer)
            }
            try? modelContext.save()
        }

        print("🗑️ Cleared all prayer time cache")
    }

    /// Get cache statistics
    func getCacheStatistics() -> CacheStatistics {
        return CacheStatistics.current(cacheManager: cacheManager)
    }
}

// MARK: - Prayer Time Helpers

extension PrayerTimeService {
    /// Format time remaining until prayer
    static func formatTimeRemaining(minutes: Int) -> (arabic: String, english: String) {
        if minutes < 60 {
            return (arabic: "بعد \(minutes) دقيقة", english: "In \(minutes) minutes")
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return (arabic: "بعد \(hours) ساعة", english: "In \(hours) hour(s)")
            } else {
                return (arabic: "بعد \(hours) ساعة و\(remainingMinutes) دقيقة", english: "In \(hours)h \(remainingMinutes)m")
            }
        }
    }

    /// Check if it's Ramadan
    func isRamadan(hijriDate: String) -> Bool {
        // Check if hijriDate contains "Ramadan" or month number 9
        return hijriDate.contains("Ramadan") || hijriDate.contains("رمضان")
    }
}
