import Foundation
import os.log

/// Centralized logging service using os_log for production-ready logging.
/// Use this instead of print() statements throughout the app.
///
/// Usage:
/// ```swift
/// MizanLogger.shared.prayer.info("Prayer times calculated")
/// MizanLogger.shared.storage.error("Failed to save: \(error.localizedDescription)")
/// ```
final class MizanLogger {
    static let shared = MizanLogger()

    private let subsystem = Bundle.main.bundleIdentifier ?? "com.mizan.app"

    // MARK: - Category-specific Loggers

    /// App lifecycle events (initialization, state changes)
    lazy var lifecycle = Logger(subsystem: subsystem, category: "lifecycle")

    /// Prayer time calculations and updates
    lazy var prayer = Logger(subsystem: subsystem, category: "prayer")

    /// Task management operations
    lazy var task = Logger(subsystem: subsystem, category: "task")

    /// Nawafil prayer generation and tracking
    lazy var nawafil = Logger(subsystem: subsystem, category: "nawafil")

    /// Notification scheduling and delivery
    lazy var notification = Logger(subsystem: subsystem, category: "notification")

    /// Network requests and API calls
    lazy var network = Logger(subsystem: subsystem, category: "network")

    /// Data persistence and caching
    lazy var storage = Logger(subsystem: subsystem, category: "storage")

    /// StoreKit and in-app purchases
    lazy var storekit = Logger(subsystem: subsystem, category: "storekit")

    /// Theme and appearance changes
    lazy var theme = Logger(subsystem: subsystem, category: "theme")

    /// Location services
    lazy var location = Logger(subsystem: subsystem, category: "location")

    private init() {}
}
