//
//  DeviceTier.swift
//  MizanApp
//
//  Created for Event Horizon cinematic UI overhaul - Phase 2, Task 1
//  Provides device performance detection and scaling factors for visual effects.
//

import SwiftUI
import UIKit

// MARK: - Device Tier

/// Represents the performance tier of the current device.
/// Used to scale visual effects appropriately for optimal performance.
public enum DeviceTier: Int, Comparable {
    /// A11 and older chips - reduced effects for smooth performance
    case low = 0
    /// A12-A13 chips - balanced effects
    case medium = 1
    /// A14+ chips - full cinematic effects
    case high = 2

    public static func < (lhs: DeviceTier, rhs: DeviceTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Device Capabilities

/// Provides performance capabilities and scaling factors based on device tier.
/// Use the singleton `current` property to access device-specific settings.
public struct DeviceCapabilities {

    // MARK: - Singleton

    /// The current device's capabilities, computed once at app launch.
    public static let current = DeviceCapabilities()

    // MARK: - Properties

    /// The detected performance tier of the device.
    public let tier: DeviceTier

    /// Target frame rate for animations (60 for high/medium, 30 for low).
    public var targetFrameRate: Int {
        switch tier {
        case .high, .medium:
            return 60
        case .low:
            return 30
        }
    }

    /// Resolution scale for shader effects (1.0 for high, 0.75 for medium, 0.5 for low).
    public var shaderResolutionScale: Float {
        switch tier {
        case .high:
            return 1.0
        case .medium:
            return 0.75
        case .low:
            return 0.5
        }
    }

    /// Maximum particle count for particle effects.
    public var maxParticles: Int {
        switch tier {
        case .high:
            return 200
        case .medium:
            return 100
        case .low:
            return 50
        }
    }

    /// Number of noise octaves for procedural effects.
    public var noiseOctaves: Int {
        switch tier {
        case .high:
            return 4
        case .medium:
            return 3
        case .low:
            return 2
        }
    }

    /// Whether shader interaction (touch response) is enabled.
    public var enableShaderInteraction: Bool {
        tier >= .medium
    }

    /// Whether particle effects are enabled (true for all tiers).
    public var enableParticles: Bool {
        true
    }

    /// Whether glass blur effects are enabled.
    public var enableGlassBlur: Bool {
        tier >= .medium
    }

    // MARK: - Initialization

    private init() {
        self.tier = Self.detectTier()
    }

    /// Creates capabilities with a specific tier (for testing/previews).
    internal init(tier: DeviceTier) {
        self.tier = tier
    }

    // MARK: - Tier Detection

    private static func detectTier() -> DeviceTier {
        // Check accessibility settings first - reduce motion forces low tier
        if UIAccessibility.isReduceMotionEnabled {
            return .low
        }

        // Get device identifier
        let identifier = getDeviceIdentifier()

        // Parse and determine tier
        return parseTier(from: identifier)
    }

    private static func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        return identifier
    }

    private static func parseTier(from identifier: String) -> DeviceTier {
        // Simulator detection - default to high for development
        if identifier.contains("x86_64") || identifier.contains("arm64") && identifier.contains("Mac") {
            return .high
        }

        // Also check for simulator via process info
        #if targetEnvironment(simulator)
        return .high
        #endif

        // Parse iPhone identifier (e.g., "iPhone14,2")
        if identifier.hasPrefix("iPhone") {
            return parseIPhoneTier(from: identifier)
        }

        // Parse iPad identifier (e.g., "iPad13,4")
        if identifier.hasPrefix("iPad") {
            return parseIPadTier(from: identifier)
        }

        // Unknown device - default to medium for safety
        return .medium
    }

    private static func parseIPhoneTier(from identifier: String) -> DeviceTier {
        // Extract major version from identifier like "iPhone14,2"
        let stripped = identifier.replacingOccurrences(of: "iPhone", with: "")
        let components = stripped.split(separator: ",")

        guard let majorString = components.first,
              let major = Int(majorString) else {
            return .medium
        }

        // iPhone identifier mapping to chip generations:
        // iPhone13,x = iPhone 12 series (A14) - HIGH
        // iPhone14,x = iPhone 13 series (A15) - HIGH
        // iPhone15,x = iPhone 14 series (A15/A16) - HIGH
        // iPhone16,x = iPhone 15 series (A16/A17) - HIGH
        // iPhone12,x = iPhone 11 series (A13) - MEDIUM
        // iPhone11,x = iPhone XS/XR series (A12) - MEDIUM
        // iPhone10,x and below = A11 and older - LOW

        if major >= 13 {
            return .high
        } else if major >= 11 {
            return .medium
        } else {
            return .low
        }
    }

    private static func parseIPadTier(from identifier: String) -> DeviceTier {
        // Extract major version from identifier like "iPad13,4"
        let stripped = identifier.replacingOccurrences(of: "iPad", with: "")
        let components = stripped.split(separator: ",")

        guard let majorString = components.first,
              let major = Int(majorString) else {
            return .medium
        }

        // iPad identifier mapping to chip generations:
        // iPad13,x = iPad Pro M1 (2021), iPad Air M1 - HIGH
        // iPad14,x = iPad Pro M2, various iPads - HIGH
        // iPad11,x = iPad Air 3 (A12), iPad 7th gen - MEDIUM
        // iPad12,x = iPad 9th gen (A13) - MEDIUM
        // iPad8,x-10,x = Various A12/A12X/A12Z - MEDIUM
        // iPad7,x and below = A10X and older - LOW

        if major >= 13 {
            return .high
        } else if major >= 8 {
            return .medium
        } else {
            return .low
        }
    }
}

// MARK: - SwiftUI Environment Integration

/// Environment key for accessing device capabilities in SwiftUI views.
private struct DeviceCapabilitiesKey: EnvironmentKey {
    static let defaultValue = DeviceCapabilities.current
}

public extension EnvironmentValues {
    /// Access device capabilities from the environment.
    /// Usage: `@Environment(\.deviceCapabilities) var capabilities`
    var deviceCapabilities: DeviceCapabilities {
        get { self[DeviceCapabilitiesKey.self] }
        set { self[DeviceCapabilitiesKey.self] = newValue }
    }
}

// MARK: - Preview Helpers

#if DEBUG
public extension DeviceCapabilities {
    /// Creates a mock DeviceCapabilities with the specified tier for previews.
    static func preview(tier: DeviceTier) -> DeviceCapabilities {
        DeviceCapabilities(tier: tier)
    }
}
#endif
