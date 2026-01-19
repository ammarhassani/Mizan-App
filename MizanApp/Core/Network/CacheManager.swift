//
//  CacheManager.swift
//  Mizan
//
//  Manages caching of API responses for offline support
//

import Foundation
import os.log

final class CacheManager {
    private let fileManager = FileManager.default
    let cacheDirectory: URL
    private let config: APIConfig

    init() {
        self.config = ConfigurationManager.shared.prayerConfig.api

        // Create cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = paths[0].appendingPathComponent("PrayerTimesCache", isDirectory: true)

        // Ensure cache directory exists
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Clean old cache on init
        cleanExpiredCache()
    }

    // MARK: - Cache Operations

    /// Save data to cache with a key
    func save<T: Encodable>(_ data: T, forKey key: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let encoded = try? encoder.encode(data) else {
            MizanLogger.shared.storage.error("Failed to encode data for cache key: \(key)")
            return
        }

        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")

        do {
            try encoded.write(to: fileURL)
            MizanLogger.shared.storage.debug("Cached data for key: \(key)")
        } catch {
            MizanLogger.shared.storage.error("Failed to save cache: \(error.localizedDescription)")
        }
    }

    /// Load data from cache
    func load<T: Decodable>(forKey key: String, as type: T.Type) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil // Cache miss is normal, no need to log
        }

        // Check if cache is expired
        if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
           let creationDate = attributes[.creationDate] as? Date {

            let daysSinceCreation = Calendar.current.dateComponents([.day], from: creationDate, to: Date()).day ?? 0

            if daysSinceCreation > config.cacheDays {
                MizanLogger.shared.storage.debug("Cache expired for key: \(key)")
                try? fileManager.removeItem(at: fileURL)
                return nil
            }
        }

        // Load and decode
        guard let data = try? Data(contentsOf: fileURL) else {
            MizanLogger.shared.storage.error("Failed to read cache file: \(key)")
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let decoded = try? decoder.decode(T.self, from: data) else {
            MizanLogger.shared.storage.error("Failed to decode cache: \(key)")
            return nil
        }

        return decoded
    }

    /// Check if cache exists for a key
    func cacheExists(forKey key: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Remove cache for a specific key
    func removeCache(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        try? fileManager.removeItem(at: fileURL)
    }

    /// Clear all cached data
    func clearAll() {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        for fileURL in contents {
            try? fileManager.removeItem(at: fileURL)
        }

        MizanLogger.shared.storage.info("Cleared all cache")
    }

    // MARK: - Cache Keys

    /// Generate cache key for prayer times on a specific date
    static func prayerTimesKey(date: Date, latitude: Double, longitude: Double, method: CalculationMethod) -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: date)

        let latString = String(format: "%.2f", latitude)
        let lonString = String(format: "%.2f", longitude)

        return "prayer_\(dateString)_\(latString)_\(lonString)_\(method.rawValue)"
    }

    /// Generate cache key for monthly prayer times
    static func monthlyKey(month: Int, year: Int, latitude: Double, longitude: Double, method: CalculationMethod) -> String {
        let latString = String(format: "%.2f", latitude)
        let lonString = String(format: "%.2f", longitude)

        return "monthly_\(year)_\(month)_\(latString)_\(lonString)_\(method.rawValue)"
    }

    // MARK: - Cache Maintenance

    /// Clean expired cache (older than config.cacheDays)
    private func cleanExpiredCache() {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        let now = Date()
        var removedCount = 0

        for fileURL in contents {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let creationDate = attributes[.creationDate] as? Date {

                let daysSinceCreation = Calendar.current.dateComponents([.day], from: creationDate, to: now).day ?? 0

                if daysSinceCreation > config.cacheDays {
                    try? fileManager.removeItem(at: fileURL)
                    removedCount += 1
                }
            }
        }

        if removedCount > 0 {
            MizanLogger.shared.storage.debug("Cleaned \(removedCount) expired cache files")
        }
    }

    /// Get cache size in bytes
    func cacheSize() -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0

        for fileURL in contents {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }

        return totalSize
    }

    /// Get cache size in human-readable format
    func cacheSizeFormatted() -> String {
        let bytes = cacheSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Get number of cached files
    func cacheCount() -> Int {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return 0
        }
        return contents.count
    }
}

// MARK: - Cache Statistics

struct CacheStatistics {
    let count: Int
    let sizeBytes: Int64
    let sizeFormatted: String
    let oldestCacheDate: Date?
    let newestCacheDate: Date?

    static func current(cacheManager: CacheManager) -> CacheStatistics {
        let fileManager = FileManager.default
        let cacheDirectory = cacheManager.cacheDirectory

        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]) else {
            return CacheStatistics(count: 0, sizeBytes: 0, sizeFormatted: "0 KB", oldestCacheDate: nil, newestCacheDate: nil)
        }

        var totalSize: Int64 = 0
        var oldestDate: Date?
        var newestDate: Date?

        for fileURL in contents {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path) {
                if let fileSize = attributes[FileAttributeKey.size] as? Int64 {
                    totalSize += fileSize
                }

                if let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
                    if oldestDate == nil || creationDate < oldestDate! {
                        oldestDate = creationDate
                    }
                    if newestDate == nil || creationDate > newestDate! {
                        newestDate = creationDate
                    }
                }
            }
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        let sizeFormatted = formatter.string(fromByteCount: totalSize)

        return CacheStatistics(
            count: contents.count,
            sizeBytes: totalSize,
            sizeFormatted: sizeFormatted,
            oldestCacheDate: oldestDate,
            newestCacheDate: newestDate
        )
    }
}

