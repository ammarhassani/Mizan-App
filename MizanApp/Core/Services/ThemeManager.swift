//
//  ThemeManager.swift
//  Mizan
//
//  Manages app themes and theme switching
//

import SwiftUI
import Combine
import UIKit

@MainActor
final class ThemeManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentTheme: Theme
    @Published var isDarkMode: Bool = false
    @Published var isRamadan: Bool = false

    // MARK: - App Icon Properties
    @AppStorage("autoSwitchAppIcon") var autoSwitchAppIcon: Bool = true
    @AppStorage("manualAppIcon") private var manualAppIconOverride: String = ""

    /// Map theme IDs to alternate icon names (nil = primary icon)
    private let themeIconMap: [String: String?] = [
        "noor": nil,  // Primary icon
        "layl": "AppIcon-Layl",
        "fajr": "AppIcon-Fajr",
        "sahara": "AppIcon-Sahara",
        "ramadan": "AppIcon-Ramadan"
    ]

    /// All available app icon options
    static let availableIcons: [(id: String, name: String, iconName: String?)] = [
        ("noor", "نور", nil),
        ("layl", "ليل", "AppIcon-Layl"),
        ("fajr", "فجر", "AppIcon-Fajr"),
        ("sahara", "صحراء", "AppIcon-Sahara"),
        ("ramadan", "رمضان", "AppIcon-Ramadan")
    ]

    // MARK: - Private Properties
    private let config: ThemeConfiguration
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        self.config = ConfigurationManager.shared.themeConfig

        // Load saved theme or use default
        let savedThemeId = UserDefaults.standard.string(forKey: "selectedTheme") ?? "noor"
        self.currentTheme = config.themes.first { $0.id == savedThemeId } ?? config.themes[0]

        // Detect dark mode
        self.isDarkMode = currentTheme.id == "layl" || currentTheme.id == "ramadan"
    }

    // MARK: - Public Methods

    /// Switch to a different theme
    func switchTheme(to themeId: String, userSettings: UserSettings? = nil) {
        guard let theme = config.themes.first(where: { $0.id == themeId }) else {
            print("❌ Theme not found: \(themeId)")
            return
        }

        // Check Pro requirement
        if theme.isPro {
            guard let settings = userSettings, settings.isProActive() else {
                print("⚠️ Theme '\(themeId)' requires Pro subscription")
                return
            }
        }

        // Animate theme change
        withAnimation(.easeInOut(duration: 0.5)) {
            currentTheme = theme
            isDarkMode = theme.id == "layl" || theme.id == "ramadan"
        }

        // Save preference
        UserDefaults.standard.set(themeId, forKey: "selectedTheme")

        // Update user settings if provided
        userSettings?.updateTheme(themeId)

        // Update app icon if auto-switch is enabled
        print("🔄 Icon switch check: autoSwitch=\(autoSwitchAppIcon), manualOverride='\(manualAppIconOverride)'")
        if autoSwitchAppIcon && manualAppIconOverride.isEmpty {
            updateAppIcon(forTheme: themeId)
        } else {
            print("⏭️ Icon switch skipped: autoSwitch=\(autoSwitchAppIcon), manualOverride='\(manualAppIconOverride)'")
        }

        // Trigger haptic feedback
        let _ = HapticManager.shared
        // Skip haptic for now to avoid conflict

        print("✨ Switched to theme: \(theme.name)")
    }

    /// Get all available themes
    func allThemes() -> [Theme] {
        return config.themes
    }

    /// Get free themes only
    func freeThemes() -> [Theme] {
        return config.themes.filter { !$0.isPro }
    }

    /// Get Pro themes only
    func proThemes() -> [Theme] {
        return config.themes.filter { $0.isPro }
    }

    /// Get colors for a specific theme by ID (for icon previews and logo variants)
    /// Returns (background, primary, accent) colors tuple
    func colorsForTheme(_ themeId: String) -> (background: Color, primary: Color, accent: Color)? {
        guard let theme = config.themes.first(where: { $0.id == themeId }) else { return nil }

        let background: Color
        if let gradient = theme.colors.backgroundGradient, !gradient.isEmpty {
            background = Color(hex: gradient[0])
        } else {
            background = Color(hex: theme.colors.background)
        }

        let accent: Color
        if let warning = theme.colors.warning {
            accent = Color(hex: warning)
        } else if let secondary = theme.colors.accent {
            accent = Color(hex: secondary)
        } else {
            accent = Color(hex: theme.colors.primary)
        }

        return (background, Color(hex: theme.colors.primary), accent)
    }

    /// Check if Ramadan theme should auto-activate
    func checkRamadanAutoActivation(hijriMonth: String) {
        // Check if current month is Ramadan (month 9 in Hijri calendar)
        isRamadan = hijriMonth.contains("Ramadan") || hijriMonth.contains("رمضان") || hijriMonth.contains("09")

        if isRamadan {
            if let ramadanTheme = config.themes.first(where: { $0.autoActivateDuringRamadan == true }) {
                print("🌙 Ramadan detected - auto-activating Ramadan theme")
                switchTheme(to: ramadanTheme.id)
            }
        }
    }

    /// Get color scheme for SwiftUI environment
    var colorScheme: ColorScheme? {
        if isDarkMode {
            return .dark
        } else if currentTheme.id == "noor" || currentTheme.id == "sahara" {
            return .light
        }
        return nil // Auto
    }

    // MARK: - App Icon Management

    /// Debounce timer for icon changes
    private static var iconChangeWorkItem: DispatchWorkItem?
    private static var isChangingIcon = false

    /// Update app icon to match a specific theme (debounced)
    func updateAppIcon(forTheme themeId: String? = nil) {
        let targetTheme = themeId ?? currentTheme.id
        print("🎨 updateAppIcon called for theme: \(targetTheme)")

        // Check if theme exists in map
        guard themeIconMap.keys.contains(targetTheme) else {
            print("❌ Theme '\(targetTheme)' not found in themeIconMap. Available: \(themeIconMap.keys.joined(separator: ", "))")
            return
        }

        let iconName = themeIconMap[targetTheme] ?? nil
        print("🎯 Target icon: \(iconName ?? "Primary (nil)")")

        // Check if we need to change the icon
        let currentIcon = UIApplication.shared.alternateIconName
        print("📱 Current icon: \(currentIcon ?? "Primary (nil)")")

        guard currentIcon != iconName else {
            print("ℹ️ Icon already set correctly, skipping")
            return
        }

        // Cancel any pending icon change
        Self.iconChangeWorkItem?.cancel()
        Self.iconChangeWorkItem = nil

        print("⏱️ Scheduling icon change in 0.5s...")

        // Debounce icon changes to prevent rapid API calls
        let workItem = DispatchWorkItem { [weak self] in
            Self.iconChangeWorkItem = nil
            self?.performIconChange(to: iconName)
        }
        Self.iconChangeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    /// Set a manual app icon override (independent of theme)
    func setManualIcon(_ iconName: String?) {
        manualAppIconOverride = iconName ?? ""

        // Cancel any pending icon change
        Self.iconChangeWorkItem?.cancel()
        Self.iconChangeWorkItem = nil

        // Small delay to avoid conflicts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.performIconChange(to: iconName)
        }
    }

    /// Actually perform the icon change
    private func performIconChange(to iconName: String?) {
        print("🔧 performIconChange to: \(iconName ?? "Primary (nil)")")

        // Skip icon switching on iOS 19+ due to beta bug where API succeeds but SpringBoard shows grid
        if #available(iOS 19, *) {
            print("⚠️ Skipping icon change on iOS 19+ due to known beta issue")
            return
        }

        // EXTENSIVE LOGGING - Bundle and Icon Diagnostics
        print("📂 ===== ICON DIAGNOSTICS START =====")

        // Log bundle path
        let bundlePath = Bundle.main.bundlePath
        print("📂 Bundle path: \(bundlePath)")

        // Check for Assets.car (compiled asset catalog)
        let assetsCar = (bundlePath as NSString).appendingPathComponent("Assets.car")
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: assetsCar) {
            if let attrs = try? fileManager.attributesOfItem(atPath: assetsCar),
               let size = attrs[.size] as? Int64 {
                print("📦 Assets.car exists! Size: \(size) bytes")
            } else {
                print("📦 Assets.car exists!")
            }
        } else {
            print("❌ Assets.car NOT FOUND - this is a PROBLEM!")
        }

        // List ALL files in bundle root
        print("📂 All files in bundle root:")
        if let files = try? fileManager.contentsOfDirectory(atPath: bundlePath) {
            for file in files.sorted() {
                let filePath = (bundlePath as NSString).appendingPathComponent(file)
                var isDir: ObjCBool = false
                fileManager.fileExists(atPath: filePath, isDirectory: &isDir)
                if isDir.boolValue {
                    print("   📁 \(file)/")
                } else {
                    if let attrs = try? fileManager.attributesOfItem(atPath: filePath),
                       let size = attrs[.size] as? Int64 {
                        print("   📄 \(file) (\(size) bytes)")
                    } else {
                        print("   📄 \(file)")
                    }
                }
            }
        }

        // Try to load icon from Asset Catalog using UIImage(named:)
        if let iconName = iconName {
            print("🎨 ===== ASSET CATALOG LOAD TEST =====")

            // Try loading with different name variations
            let namesToTry = [iconName, "\(iconName)-icon", "icon"]
            for name in namesToTry {
                if let image = UIImage(named: name) {
                    print("   ✅ UIImage(named: \"\(name)\") loaded! Size: \(image.size)")
                } else {
                    print("   ❌ UIImage(named: \"\(name)\") returned nil")
                }
            }

            // Try loading the icon as an app icon specifically
            // App icons in asset catalogs have specific naming
            let appIconNames = [
                iconName,
                "\(iconName)60x60",
                "\(iconName)60x60@2x",
                "\(iconName)60x60@3x"
            ]
            print("🔍 Testing app icon specific names:")
            for name in appIconNames {
                if let image = UIImage(named: name) {
                    print("   ✅ \(name) -> loaded (\(image.size))")
                } else {
                    print("   ❌ \(name) -> nil")
                }
            }

            // NEW: Check PNG file details
            print("🔬 ===== PNG FILE ANALYSIS =====")
            let pngNames = ["\(iconName)60x60@2x.png", "\(iconName)60x60@3x.png"]
            for pngName in pngNames {
                if let path = Bundle.main.path(forResource: pngName.replacingOccurrences(of: ".png", with: ""), ofType: "png") {
                    print("   📄 \(pngName):")
                    print("      Path: \(path)")

                    // Load and analyze
                    if let image = UIImage(contentsOfFile: path) {
                        print("      ✅ Loaded via contentsOfFile")
                        print("      Size: \(image.size.width)x\(image.size.height)")
                        print("      Scale: \(image.scale)")
                        print("      RenderingMode: \(image.renderingMode.rawValue)")

                        if let cgImage = image.cgImage {
                            print("      CGImage width: \(cgImage.width)")
                            print("      CGImage height: \(cgImage.height)")
                            print("      BitsPerComponent: \(cgImage.bitsPerComponent)")
                            print("      BitsPerPixel: \(cgImage.bitsPerPixel)")
                            print("      BytesPerRow: \(cgImage.bytesPerRow)")
                            print("      AlphaInfo: \(cgImage.alphaInfo.rawValue) (\(Self.alphaInfoName(cgImage.alphaInfo)))")
                            print("      ColorSpace: \(cgImage.colorSpace?.name ?? "nil" as CFString)")
                            print("      BitmapInfo: \(cgImage.bitmapInfo.rawValue)")
                        }
                    } else {
                        print("      ❌ Failed to load via contentsOfFile")
                    }

                    // Check file attributes
                    if let attrs = try? fileManager.attributesOfItem(atPath: path) {
                        print("      FileSize: \(attrs[.size] ?? "unknown")")
                    }

                    // Read PNG header bytes
                    if let data = fileManager.contents(atPath: path) {
                        print("      📊 PNG Header Analysis:")
                        let bytes = [UInt8](data.prefix(33))
                        let hexHeader = bytes.prefix(8).map { String(format: "%02X", $0) }.joined(separator: " ")
                        print("         First 8 bytes: \(hexHeader)")

                        // Check PNG signature
                        let pngSig: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
                        if Array(bytes.prefix(8)) == pngSig {
                            print("         ✅ Valid PNG signature")
                        } else {
                            print("         ❌ INVALID PNG signature!")
                        }

                        // Parse IHDR chunk (starts at byte 8)
                        if bytes.count >= 29 {
                            let ihdrLength = UInt32(bytes[8]) << 24 | UInt32(bytes[9]) << 16 | UInt32(bytes[10]) << 8 | UInt32(bytes[11])
                            let ihdrType = String(bytes: bytes[12..<16], encoding: .ascii) ?? "????"
                            print("         IHDR chunk: length=\(ihdrLength), type=\(ihdrType)")

                            if ihdrType == "IHDR" && ihdrLength == 13 {
                                let width = UInt32(bytes[16]) << 24 | UInt32(bytes[17]) << 16 | UInt32(bytes[18]) << 8 | UInt32(bytes[19])
                                let height = UInt32(bytes[20]) << 24 | UInt32(bytes[21]) << 16 | UInt32(bytes[22]) << 8 | UInt32(bytes[23])
                                let bitDepth = bytes[24]
                                let colorType = bytes[25]
                                let compression = bytes[26]
                                let filter = bytes[27]
                                let interlace = bytes[28]

                                print("         Width: \(width), Height: \(height)")
                                print("         Bit Depth: \(bitDepth)")
                                print("         Color Type: \(colorType) (\(Self.pngColorTypeName(colorType)))")
                                print("         Compression: \(compression), Filter: \(filter), Interlace: \(interlace)")

                                // Check for correct icon format
                                if colorType == 2 && bitDepth == 8 {
                                    print("         ✅ Correct format: 8-bit RGB (no alpha)")
                                } else if colorType == 6 {
                                    print("         ❌ PROBLEM: Color type 6 = RGBA (has alpha channel)")
                                } else {
                                    print("         ⚠️ Unusual color type for app icon")
                                }
                            }
                        }
                    }
                } else {
                    print("   ❌ \(pngName) not found in bundle")
                }
            }

            // Check SpringBoard cache info
            print("🔍 ===== SPRINGBOARD/SYSTEM INFO =====")
            print("   ProcessInfo.processInfo.processIdentifier: \(ProcessInfo.processInfo.processIdentifier)")
            print("   Bundle.main.bundleIdentifier: \(Bundle.main.bundleIdentifier ?? "nil")")

            // Try alternate loading methods
            print("🔍 ===== ALTERNATE LOAD METHODS =====")
            if let path = Bundle.main.path(forResource: "\(iconName)60x60@3x", ofType: "png"),
               let data = fileManager.contents(atPath: path),
               let provider = CGDataProvider(data: data as CFData),
               let cgImage = CGImage(pngDataProviderSource: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) {
                print("   ✅ CGImage direct load succeeded")
                print("      Width: \(cgImage.width), Height: \(cgImage.height)")
                print("      AlphaInfo: \(cgImage.alphaInfo.rawValue)")
                print("      BitsPerPixel: \(cgImage.bitsPerPixel)")
            } else {
                print("   ❌ CGImage direct load failed")
            }

            // NEW: Check what iOS expects
            print("🔍 ===== iOS ICON RESOLUTION TEST =====")
            let screen = UIScreen.main
            print("   Screen scale: \(screen.scale)")
            print("   Screen bounds: \(screen.bounds)")

            // Check alternate icon config specifically
            if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
               let alternateIcons = icons["CFBundleAlternateIcons"] as? [String: Any],
               let iconConfig = alternateIcons[iconName] as? [String: Any] {
                print("   Icon '\(iconName)' config:")
                for (key, value) in iconConfig {
                    print("      \(key): \(value)")
                }

                // Check if CFBundleIconFiles points to existing files
                if let iconFiles = iconConfig["CFBundleIconFiles"] as? [String] {
                    print("   Checking CFBundleIconFiles resolution:")
                    for baseFile in iconFiles {
                        // iOS looks for these patterns
                        let patterns = [
                            "\(baseFile)@2x",
                            "\(baseFile)@3x",
                            "\(baseFile)@2x~iphone",
                            "\(baseFile)@3x~iphone"
                        ]
                        for pattern in patterns {
                            if let path = Bundle.main.path(forResource: pattern, ofType: "png") {
                                print("      ✅ \(pattern).png found")
                            } else {
                                print("      ❌ \(pattern).png NOT found")
                            }
                        }
                    }
                }
            }
        }

        // Dump FULL CFBundleIcons structure
        print("📋 ===== FULL CFBundleIcons DUMP =====")
        if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any] {
            dumpDictionary(icons, indent: "   ")
        } else {
            print("   ❌ CFBundleIcons not found in Info.plist!")
        }

        print("📋 ===== FULL CFBundleIcons~ipad DUMP =====")
        if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons~ipad") as? [String: Any] {
            dumpDictionary(icons, indent: "   ")
        } else {
            print("   (No iPad-specific icons)")
        }

        // Check if primary icon is working
        print("🔍 ===== PRIMARY ICON CHECK =====")
        if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any] {
            print("   Primary icon config: \(primaryIcon)")
            if let iconName = primaryIcon["CFBundleIconName"] as? String {
                print("   Primary CFBundleIconName: \(iconName)")
            }
            if let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String] {
                print("   Primary CFBundleIconFiles: \(iconFiles)")
                for file in iconFiles {
                    if let path = Bundle.main.path(forResource: file, ofType: nil) {
                        print("      ✅ Found: \(file) at \(path)")
                    } else if let path = Bundle.main.path(forResource: file, ofType: "png") {
                        print("      ✅ Found: \(file).png at \(path)")
                    } else {
                        print("      ❌ Not found: \(file)")
                    }
                }
            }
        }

        // Test supportsAlternateIcons
        print("🔍 ===== SYSTEM CHECKS =====")
        print("   supportsAlternateIcons: \(UIApplication.shared.supportsAlternateIcons)")
        print("   Current alternateIconName: \(UIApplication.shared.alternateIconName ?? "nil (primary)")")

        print("📂 ===== ICON DIAGNOSTICS END =====")

        // Prevent concurrent changes
        guard !Self.isChangingIcon else {
            print("⏳ Already changing icon, skipping")
            return
        }

        // Check if already set to this icon
        guard UIApplication.shared.alternateIconName != iconName else {
            print("ℹ️ Icon already correct in performIconChange")
            return
        }

        Self.isChangingIcon = true

        // Use the supportsAlternateIcons check
        guard UIApplication.shared.supportsAlternateIcons else {
            print("❌ Alternate icons NOT supported on this device/simulator")
            Self.isChangingIcon = false
            return
        }

        // Log iOS version
        print("📱 iOS Version: \(UIDevice.current.systemVersion)")
        print("📱 Device: \(UIDevice.current.model)")

        print("📲 Calling setAlternateIconName(\(iconName ?? "nil"))...")

        UIApplication.shared.setAlternateIconName(iconName) { error in
            DispatchQueue.main.async {
                Self.isChangingIcon = false
            }

            if let error = error as NSError? {
                print("📋 Error details: domain=\(error.domain), code=\(error.code)")
                print("📋 Full error: \(error)")
                print("📋 UserInfo: \(error.userInfo)")

                // Decode common error codes
                switch (error.domain, error.code) {
                case ("NSCocoaErrorDomain", 3072):
                    print("⚠️ Error 3072: Operation cancelled (usually benign)")
                case ("NSCocoaErrorDomain", 4):
                    print("⚠️ Error 4: File not found")
                case ("_LSLaunchErrorDomain", _):
                    print("❌ LaunchServices error - icon file may be invalid")
                default:
                    print("❌ Unknown error type")
                }

                // Ignore certain iOS quirks - the icon may have actually changed
                if error.domain == "NSCocoaErrorDomain" && (error.code == 3072 || error.code == 4) {
                    print("⚠️ Icon change completed with warning: \(error.localizedDescription)")
                    return
                }
                print("❌ Icon change FAILED: \(error.localizedDescription)")
            } else {
                print("✅ Icon changed successfully to: \(iconName ?? "Primary")")
                // Verify the change
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let currentIcon = UIApplication.shared.alternateIconName
                    print("🔍 Verification: Current icon is now: \(currentIcon ?? "Primary (nil)")")
                    if currentIcon == iconName {
                        print("✅ Icon change VERIFIED")

                        // Additional verification - try to check SpringBoard
                        print("🔍 Post-change diagnostics:")
                        print("   alternateIconName: \(UIApplication.shared.alternateIconName ?? "nil")")
                        print("   supportsAlternateIcons: \(UIApplication.shared.supportsAlternateIcons)")
                    } else {
                        print("⚠️ Icon mismatch! Expected: \(iconName ?? "nil"), Got: \(currentIcon ?? "nil")")
                    }
                }
            }
        }
    }

    /// Clear manual icon override and sync with current theme
    func clearManualIconOverride() {
        manualAppIconOverride = ""
        if autoSwitchAppIcon {
            updateAppIcon(forTheme: currentTheme.id)
        }
    }

    /// Get current app icon name
    var currentAppIconName: String? {
        UIApplication.shared.alternateIconName
    }

    /// Check if a specific icon is currently active
    func isIconActive(_ iconName: String?) -> Bool {
        UIApplication.shared.alternateIconName == iconName
    }

    /// Helper to get alpha info name
    private static func alphaInfoName(_ alphaInfo: CGImageAlphaInfo) -> String {
        switch alphaInfo {
        case .none: return "none"
        case .premultipliedLast: return "premultipliedLast"
        case .premultipliedFirst: return "premultipliedFirst"
        case .last: return "last"
        case .first: return "first"
        case .noneSkipLast: return "noneSkipLast"
        case .noneSkipFirst: return "noneSkipFirst"
        case .alphaOnly: return "alphaOnly"
        @unknown default: return "unknown"
        }
    }

    /// Helper to get PNG color type name
    private static func pngColorTypeName(_ colorType: UInt8) -> String {
        switch colorType {
        case 0: return "Grayscale"
        case 2: return "RGB"
        case 3: return "Indexed"
        case 4: return "Grayscale+Alpha"
        case 6: return "RGBA"
        default: return "Unknown"
        }
    }

    /// Helper to dump dictionary for debugging
    private func dumpDictionary(_ dict: [String: Any], indent: String = "") {
        for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
            if let nested = value as? [String: Any] {
                print("\(indent)\(key):")
                dumpDictionary(nested, indent: indent + "   ")
            } else if let array = value as? [Any] {
                print("\(indent)\(key): \(array)")
            } else {
                print("\(indent)\(key): \(value)")
            }
        }
    }
}

// MARK: - Theme Access Helpers

extension ThemeManager {
    /// Get primary color
    var primaryColor: Color {
        Color(hex: currentTheme.colors.primary)
    }

    /// Get background color
    var backgroundColor: Color {
        if let gradient = currentTheme.colors.backgroundGradient, !gradient.isEmpty {
            return Color(hex: gradient[0])
        }
        return Color(hex: currentTheme.colors.background)
    }

    /// Get surface color
    var surfaceColor: Color {
        Color(hex: currentTheme.colors.surface ?? currentTheme.colors.background)
    }

    /// Get secondary surface color (from theme config)
    var surfaceSecondaryColor: Color {
        if let surfaceSecondary = currentTheme.colors.surfaceSecondary {
            return Color(hex: surfaceSecondary)
        }
        return surfaceColor.opacity(0.9)
    }

    /// Get tertiary text color (from theme config)
    var textTertiaryColor: Color {
        if let textTertiary = currentTheme.colors.textTertiary {
            return Color(hex: textTertiary)
        }
        return textSecondaryColor.opacity(0.7)
    }

    /// Get text color for primary background (WCAG2 compliant)
    var textOnPrimaryColor: Color {
        if let textOnPrimary = currentTheme.colors.textOnPrimary {
            return Color(hex: textOnPrimary)
        }
        // Default to white for most themes, but dark for light primary colors
        return isDarkMode ? Color(hex: "#000000") : Color(hex: "#FFFFFF")
    }

    /// Get placeholder text color
    var placeholderTextColor: Color {
        if let placeholder = currentTheme.colors.placeholderText {
            return Color(hex: placeholder)
        }
        return textSecondaryColor.opacity(0.6)
    }

    /// Get success color
    var successColor: Color {
        if let success = currentTheme.colors.success {
            return Color(hex: success)
        }
        return Color(hex: "#10B981")
    }

    /// Get error color
    var errorColor: Color {
        if let error = currentTheme.colors.error {
            return Color(hex: error)
        }
        return Color(hex: "#EF4444")
    }

    /// Get warning color
    var warningColor: Color {
        if let warning = currentTheme.colors.warning {
            return Color(hex: warning)
        }
        return Color(hex: "#F59E0B")
    }

    // MARK: - Additional Exposed Colors

    /// Get info color
    var infoColor: Color {
        if let info = currentTheme.colors.info {
            return Color(hex: info)
        }
        return Color(hex: "#3B82F6")
    }

    /// Get divider color
    var dividerColor: Color {
        if let divider = currentTheme.colors.divider {
            return Color(hex: divider)
        }
        return textTertiaryColor.opacity(0.3)
    }

    /// Get primary light color (lighter variant)
    var primaryLightColor: Color {
        if let primaryLight = currentTheme.colors.primaryLight {
            return Color(hex: primaryLight)
        }
        return primaryColor.opacity(0.8)
    }

    /// Get primary dark color (darker variant)
    var primaryDarkColor: Color {
        if let primaryDark = currentTheme.colors.primaryDark {
            return Color(hex: primaryDark)
        }
        return primaryColor
    }

    // MARK: - Semantic State Colors

    /// Get disabled color (for disabled text/icons)
    var disabledColor: Color {
        if let disabled = currentTheme.colors.disabled {
            return Color(hex: disabled)
        }
        return Color(hex: "#9CA3AF")
    }

    /// Get disabled background color
    var disabledBackgroundColor: Color {
        if let disabledBg = currentTheme.colors.disabledBackground {
            return Color(hex: disabledBg)
        }
        return Color(hex: "#F3F4F6")
    }

    /// Get border color
    var borderColor: Color {
        if let border = currentTheme.colors.border {
            return Color(hex: border)
        }
        return Color(hex: "#D1D5DB")
    }

    /// Get focused border color
    var focusedBorderColor: Color {
        if let borderFocused = currentTheme.colors.borderFocused {
            return Color(hex: borderFocused)
        }
        return primaryColor
    }

    /// Get pressed state color
    var pressedColor: Color {
        if let pressed = currentTheme.colors.pressed {
            return Color(hex: pressed)
        }
        return primaryDarkColor
    }

    /// Get urgency color based on level
    func urgencyColor(_ level: UrgencyLevel) -> Color {
        switch level {
        case .low:
            if let color = currentTheme.colors.urgencyLow {
                return Color(hex: color)
            }
            return textTertiaryColor
        case .medium:
            if let color = currentTheme.colors.urgencyMedium {
                return Color(hex: color)
            }
            return warningColor
        case .high:
            if let color = currentTheme.colors.urgencyHigh {
                return Color(hex: color)
            }
            return Color(hex: "#F97316")
        case .critical:
            if let color = currentTheme.colors.urgencyCritical {
                return Color(hex: color)
            }
            return errorColor
        }
    }

    /// Get text primary color
    var textPrimaryColor: Color {
        Color(hex: currentTheme.colors.textPrimary)
    }

    /// Get text secondary color
    var textSecondaryColor: Color {
        Color(hex: currentTheme.colors.textSecondary ?? currentTheme.colors.textPrimary)
    }

    /// Get prayer gradient colors
    var prayerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: currentTheme.colors.prayerGradientStart),
                Color(hex: currentTheme.colors.prayerGradientEnd)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Splash Screen Colors

    /// Get splash moon color
    var splashMoonColor: Color {
        if let hex = currentTheme.colors.splashMoon {
            return Color(hex: hex)
        }
        return warningColor // Default fallback (gold-like)
    }

    /// Get splash text color (WCAG-compliant for splash gradient background)
    var splashTextColor: Color {
        if let hex = currentTheme.colors.splashText {
            return Color(hex: hex)
        }
        return textOnPrimaryColor // Default fallback
    }

    /// Get splash gradient colors
    var splashGradientColors: [Color] {
        if let colors = currentTheme.colors.splashGradient {
            return colors.map { Color(hex: $0) }
        }
        // Default fallback
        return [primaryColor, primaryColor.opacity(0.8), primaryColor.opacity(0.6)]
    }

    // MARK: - Overlay Color

    /// Get overlay color (replaces Color.black.opacity for theme-awareness)
    var overlayColor: Color {
        if let hex = currentTheme.colors.overlay {
            return Color(hex: hex)
        }
        return isDarkMode ? Color(hex: "#000000") : Color(hex: "#1A1A1A")
    }

    // MARK: - Prayer Atmosphere Gradients

    /// Get atmosphere gradient for a specific time period
    func atmosphereGradient(for period: AtmospherePeriod) -> [Color] {
        if let atmosphereColors = currentTheme.colors.atmosphere,
           let colors = atmosphereColors[period.rawValue] {
            return colors.map { Color(hex: $0) }
        }
        // Default fallback - derive from theme
        return defaultAtmosphereColors(for: period)
    }

    private func defaultAtmosphereColors(for period: AtmospherePeriod) -> [Color] {
        switch period {
        case .fajr:
            return [backgroundColor, primaryColor.opacity(0.3)]
        case .sunrise:
            return [primaryColor.opacity(0.5), warningColor.opacity(0.3)]
        case .morning:
            return [backgroundColor, surfaceColor]
        case .dhuhr:
            return [surfaceColor, backgroundColor]
        case .asr:
            return [primaryColor.opacity(0.2), surfaceColor]
        case .maghrib:
            return [warningColor.opacity(0.4), primaryColor.opacity(0.3)]
        case .isha:
            return [backgroundColor.opacity(0.9), primaryColor.opacity(0.2)]
        case .night:
            return [overlayColor, backgroundColor]
        }
    }

    // MARK: - Particle Colors

    /// Get particle color for a specific prayer/time period
    func particleColor(for period: AtmospherePeriod) -> Color {
        if let particleColors = currentTheme.colors.particles,
           let hex = particleColors[period.rawValue] {
            return Color(hex: hex)
        }
        // Fallback to theme-derived color
        return textOnPrimaryColor.opacity(0.5)
    }

    /// Get category color
    func categoryColor(_ category: TaskCategory) -> Color {
        if let taskColors = currentTheme.colors.taskColors,
           let colorHex = taskColors[category.rawValue] {
            return Color(hex: colorHex)
        }
        return Color(hex: category.defaultColorHex)
    }

    /// Get corner radius
    func cornerRadius(_ size: CornerRadiusSize) -> CGFloat {
        guard let radiusConfig = currentTheme.cornerRadius else {
            return size.defaultValue
        }

        switch size {
        case .small: return radiusConfig.small
        case .medium: return radiusConfig.medium
        case .large: return radiusConfig.large
        case .extraLarge: return radiusConfig.extraLarge
        }
    }

    /// Get shadow configuration
    func shadow(_ type: ShadowType) -> ShadowConfiguration {
        guard let shadows = currentTheme.shadows else {
            return ShadowConfiguration.default
        }

        let shadowConfig: ShadowConfig
        switch type {
        case .card:
            shadowConfig = shadows.card
        case .elevated:
            shadowConfig = shadows.elevated ?? shadows.card
        case .floating:
            shadowConfig = shadows.floating ?? shadows.card
        }

        return ShadowConfiguration(
            color: Color(hex: shadowConfig.color),
            radius: shadowConfig.radius,
            x: shadowConfig.x,
            y: shadowConfig.y,
            useGlow: currentTheme.useGlowInsteadOfShadow ?? false
        )
    }

    // MARK: - Glassmorphism Support

    /// Get glass style values for a specific style
    func glassStyle(_ style: GlassStyle) -> GlassStyleValues {
        guard let glassmorphism = currentTheme.glassmorphism else {
            return GlassStyleValues.default(for: style)
        }

        let config: GlassStyleConfig
        switch style {
        case .subtle:
            config = glassmorphism.subtle
        case .standard:
            config = glassmorphism.standard
        case .frosted:
            config = glassmorphism.frosted
        case .prayer:
            config = glassmorphism.prayer
        }

        return GlassStyleValues(
            blurRadius: config.blurRadius,
            backgroundOpacity: config.backgroundOpacity,
            borderOpacity: (leading: config.borderOpacityLeading, trailing: config.borderOpacityTrailing),
            accentTintOpacity: config.accentTintOpacity,
            highlightOpacity: config.highlightOpacity,
            glowRadius: config.glowRadius.map { CGFloat($0) },
            glowOpacity: config.glowOpacity.map { CGFloat($0) }
        )
    }
}

// MARK: - Supporting Types

/// Glass style variants for glassmorphism effects
enum GlassStyle {
    case subtle    // Minimal blur, higher opacity
    case standard  // Default glass effect
    case frosted   // Heavy blur, lower opacity
    case prayer    // Optimized for prayer cards
}

/// Values for a specific glass style
struct GlassStyleValues {
    let blurRadius: CGFloat
    let backgroundOpacity: CGFloat
    let borderOpacity: (leading: CGFloat, trailing: CGFloat)
    let accentTintOpacity: CGFloat
    let highlightOpacity: CGFloat
    let glowRadius: CGFloat?
    let glowOpacity: CGFloat?

    /// Default values when no theme config is available
    static func `default`(for style: GlassStyle) -> GlassStyleValues {
        switch style {
        case .subtle:
            return GlassStyleValues(
                blurRadius: 0.5,
                backgroundOpacity: 0.7,
                borderOpacity: (leading: 0.3, trailing: 0.1),
                accentTintOpacity: 0.05,
                highlightOpacity: 0.1,
                glowRadius: nil,
                glowOpacity: nil
            )
        case .standard:
            return GlassStyleValues(
                blurRadius: 8,
                backgroundOpacity: 0.5,
                borderOpacity: (leading: 0.4, trailing: 0.1),
                accentTintOpacity: 0.08,
                highlightOpacity: 0.15,
                glowRadius: nil,
                glowOpacity: nil
            )
        case .frosted:
            return GlassStyleValues(
                blurRadius: 20,
                backgroundOpacity: 0.3,
                borderOpacity: (leading: 0.5, trailing: 0.15),
                accentTintOpacity: 0.1,
                highlightOpacity: 0.2,
                glowRadius: nil,
                glowOpacity: nil
            )
        case .prayer:
            return GlassStyleValues(
                blurRadius: 12,
                backgroundOpacity: 0.4,
                borderOpacity: (leading: 0.45, trailing: 0.12),
                accentTintOpacity: 0.12,
                highlightOpacity: 0.18,
                glowRadius: nil,
                glowOpacity: nil
            )
        }
    }
}

/// Represents different time periods for atmosphere gradients
enum AtmospherePeriod: String, CaseIterable {
    case fajr
    case sunrise
    case morning
    case dhuhr
    case asr
    case maghrib
    case isha
    case night

    /// Get the appropriate period based on hour of day
    static func from(hour: Int) -> AtmospherePeriod {
        switch hour {
        case 4..<6:
            return .fajr
        case 6..<8:
            return .sunrise
        case 8..<12:
            return .morning
        case 12..<15:
            return .dhuhr
        case 15..<17:
            return .asr
        case 17..<19:
            return .maghrib
        case 19..<22:
            return .isha
        default:
            return .night
        }
    }
}

enum CornerRadiusSize {
    case small, medium, large, extraLarge

    var defaultValue: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        case .extraLarge: return 24
        }
    }
}

enum UrgencyLevel {
    case low      // > 15 minutes
    case medium   // 5-15 minutes
    case high     // 1-5 minutes
    case critical // < 1 minute
}

enum ShadowType {
    case card, elevated, floating
}

struct ShadowConfiguration {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    let useGlow: Bool

    static let `default` = ShadowConfiguration(
        color: Color(white: 0).opacity(0.15),  // Theme-neutral shadow color
        radius: 8,
        x: 0,
        y: 2,
        useGlow: false
    )
}

// MARK: - View Modifiers

struct ThemedCardModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        let shadow = themeManager.shadow(.card)

        content
            .background(themeManager.surfaceColor)
            .cornerRadius(themeManager.cornerRadius(.medium))
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

struct ThemedButtonModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    let style: ButtonStyle

    enum ButtonStyle {
        case primary, secondary, tertiary
    }

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(themeManager.cornerRadius(.medium))
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return themeManager.primaryColor
        case .secondary:
            return themeManager.surfaceColor
        case .tertiary:
            return Color.clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return themeManager.textOnPrimaryColor
        case .secondary:
            return themeManager.textPrimaryColor
        case .tertiary:
            return themeManager.primaryColor
        }
    }
}

extension View {
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }

    func themedButton(style: ThemedButtonModifier.ButtonStyle = .primary) -> some View {
        modifier(ThemedButtonModifier(style: style))
    }
}

// MARK: - Haptic Manager

enum HapticType {
    case light, medium, heavy
    case success, warning, error
    case selection
}

final class HapticManager {
    static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private var lastHapticTime: Date?
    private let minimumInterval: TimeInterval = 0.1 // 100ms debounce

    private init() {
        // Prepare generators
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
    }

    func trigger(_ type: HapticType) {
        // Debounce haptics
        if let lastTime = lastHapticTime, Date().timeIntervalSince(lastTime) < minimumInterval {
            return
        }

        lastHapticTime = Date()

        switch type {
        case .light:
            impactLight.impactOccurred()
            impactLight.prepare()
        case .medium:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        case .heavy:
            impactHeavy.impactOccurred()
            impactHeavy.prepare()
        case .success:
            notification.notificationOccurred(.success)
        case .warning:
            notification.notificationOccurred(.warning)
        case .error:
            notification.notificationOccurred(.error)
        case .selection:
            selection.selectionChanged()
        }
    }
}
