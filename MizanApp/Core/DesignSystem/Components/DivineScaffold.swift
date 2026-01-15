//
//  DivineScaffold.swift
//  Mizan
//
//  The unified wrapper that brings divine atmosphere to every screen.
//  Automatically adapts to prayer period, theme, and user context.
//

import SwiftUI

// MARK: - Divine Scaffold

struct DivineScaffold<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    let content: Content
    var prayerPeriod: PrayerPeriod
    var intensity: DivineIntensity
    var showGeometry: Bool
    var geometryPattern: GeometricPatternType
    var isScrolling: Bool
    var respectsReduceMotion: Bool

    @State private var isKeyboardVisible = false

    init(
        prayerPeriod: PrayerPeriod = .dhuhr,
        intensity: DivineIntensity = .standard,
        showGeometry: Bool = true,
        geometryPattern: GeometricPatternType = .octagram,
        isScrolling: Bool = false,
        respectsReduceMotion: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.prayerPeriod = prayerPeriod
        self.intensity = intensity
        self.showGeometry = showGeometry
        self.geometryPattern = geometryPattern
        self.isScrolling = isScrolling
        self.respectsReduceMotion = respectsReduceMotion
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Divine Atmosphere Background
            if shouldShowAtmosphere {
                DivineAtmosphere(
                    prayerPeriod: prayerPeriod,
                    isScrolling: isScrolling || isKeyboardVisible,
                    intensity: effectiveIntensity,
                    showGeometry: showGeometry,
                    showParticles: intensity != .minimal,
                    showLightRays: intensity == .immersive
                )
                .environmentObject(themeManager)
                .transition(.opacity)
            } else {
                // Fallback to simple gradient for reduce motion
                themeManager.backgroundColor
                    .ignoresSafeArea()
            }

            // Content with edge fade
            VStack(spacing: 0) {
                content
            }

            // Top edge divine mist
            if intensity == .immersive && !isScrolling {
                edgeMist
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }

    // MARK: - Computed Properties

    private var shouldShowAtmosphere: Bool {
        if respectsReduceMotion && UIAccessibility.isReduceMotionEnabled {
            return false
        }
        return true
    }

    private var effectiveIntensity: Double {
        switch intensity {
        case .minimal: return 0.3
        case .subtle: return 0.5
        case .standard: return 0.7
        case .immersive: return 1.0
        }
    }

    // MARK: - Edge Mist

    private var edgeMist: some View {
        VStack {
            LinearGradient(
                colors: [
                    themeManager.backgroundColor.opacity(0.8),
                    themeManager.backgroundColor.opacity(0.4),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)
            .blur(radius: 10)

            Spacer()

            LinearGradient(
                colors: [
                    .clear,
                    themeManager.backgroundColor.opacity(0.4),
                    themeManager.backgroundColor.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .blur(radius: 10)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Divine Intensity

enum DivineIntensity {
    case minimal     // Just gradient, no particles
    case subtle      // Light particles, no rays
    case standard    // Full particles, subtle geometry
    case immersive   // Everything at full intensity

    var geometryOpacity: Double {
        switch self {
        case .minimal: return 0.03
        case .subtle: return 0.05
        case .standard: return 0.08
        case .immersive: return 0.12
        }
    }
}

// MARK: - View Extension

extension View {
    /// Wraps the view in a divine atmosphere
    func divineAtmosphere(
        prayerPeriod: PrayerPeriod = .dhuhr,
        intensity: DivineIntensity = .standard,
        showGeometry: Bool = true,
        geometryPattern: GeometricPatternType = .octagram
    ) -> some View {
        DivineScaffold(
            prayerPeriod: prayerPeriod,
            intensity: intensity,
            showGeometry: showGeometry,
            geometryPattern: geometryPattern
        ) {
            self
        }
    }
}

// MARK: - Prayer Period Helper

extension PrayerPeriod {
    /// Determines the current prayer period based on prayer times
    static func current(from prayers: [PrayerTime], at date: Date = Date()) -> PrayerPeriod {
        let now = date

        // Sort prayers by adhan time
        let sortedPrayers = prayers.sorted { $0.adhanTime < $1.adhanTime }

        // Find current period
        for (index, prayer) in sortedPrayers.enumerated() {
            let prayerTime = prayer.adhanTime

            if now < prayerTime {
                // We're before this prayer
                if index == 0 {
                    // Before Fajr = Tahajjud
                    return .tahajjud
                } else {
                    // Return the previous prayer's period
                    return PrayerPeriod(rawValue: sortedPrayers[index - 1].prayerType.rawValue) ?? .dhuhr
                }
            }
        }

        // After Isha
        let ishaTime = sortedPrayers.last?.adhanTime ?? now

        // Check if it's late night (tahajjud time)
        let calendar = Calendar.current
        if let fajrTomorrow = calendar.date(byAdding: .day, value: 1, to: sortedPrayers.first?.adhanTime ?? now) {
            let midpoint = ishaTime.addingTimeInterval(fajrTomorrow.timeIntervalSince(ishaTime) / 2)
            if now > midpoint {
                return .tahajjud
            }
        }

        return .isha
    }

    /// Pattern that best suits this prayer period
    var suggestedPattern: GeometricPatternType {
        switch self {
        case .fajr: return .arabesque     // Flowing, awakening
        case .sunrise: return .hexagonal  // Bright, geometric
        case .dhuhr: return .octagram     // Classic, centered
        case .asr: return .muqarnas       // Depth, shadow
        case .maghrib: return .arabesque  // Transitional
        case .isha: return .octagram      // Night majesty
        case .tahajjud: return .hexagonal // Cosmic
        }
    }
}

// MARK: - Preview

#Preview {
    TabView {
        DivineScaffold(
            prayerPeriod: .fajr,
            intensity: .immersive
        ) {
            VStack {
                Text("صلاة الفجر")
                    .font(MZTypography.displayMedium)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.top, 100)
        }
        .tabItem { Text("Fajr") }

        DivineScaffold(
            prayerPeriod: .isha,
            intensity: .immersive,
            geometryPattern: .octagram
        ) {
            VStack {
                Text("صلاة العشاء")
                    .font(MZTypography.displayMedium)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.top, 100)
        }
        .tabItem { Text("Isha") }

        DivineScaffold(
            prayerPeriod: .tahajjud,
            intensity: .immersive,
            geometryPattern: .hexagonal
        ) {
            VStack {
                Text("قيام الليل")
                    .font(MZTypography.displayMedium)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.top, 100)
        }
        .tabItem { Text("Tahajjud") }
    }
    .environmentObject(ThemeManager())
}
