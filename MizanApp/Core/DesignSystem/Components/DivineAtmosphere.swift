//
//  DivineAtmosphere.swift
//  Mizan
//
//  Performance-optimized atmospheric background.
//  Reduced animations and particle counts for smooth 60 FPS.
//

import SwiftUI

// MARK: - Prayer Period

enum PrayerPeriod: String, CaseIterable {
    case fajr = "fajr"
    case sunrise = "sunrise"
    case dhuhr = "dhuhr"
    case asr = "asr"
    case maghrib = "maghrib"
    case isha = "isha"
    case tahajjud = "tahajjud"

    var celestialIntensity: Double {
        switch self {
        case .fajr: return 0.5
        case .sunrise: return 0.2
        case .dhuhr: return 0.1
        case .asr: return 0.2
        case .maghrib: return 0.6
        case .isha: return 0.8
        case .tahajjud: return 1.0
        }
    }

    var geometryOpacity: Double {
        switch self {
        case .fajr: return 0.06
        case .sunrise: return 0.04
        case .dhuhr: return 0.03
        case .asr: return 0.04
        case .maghrib: return 0.08
        case .isha: return 0.10
        case .tahajjud: return 0.12
        }
    }
}

// MARK: - Divine Atmosphere

struct DivineAtmosphere: View {
    @EnvironmentObject var themeManager: ThemeManager

    let prayerPeriod: PrayerPeriod
    var isScrolling: Bool = false
    var intensity: Double = 1.0
    var showGeometry: Bool = true
    var showParticles: Bool = true
    var showLightRays: Bool = true // Ignored - light rays removed for performance

    @State private var phase: Double = 0
    @State private var stars: [CelestialStar] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Base Gradient (theme-aware)
                baseGradient

                // Layer 2: Stars (reduced count)
                if !isScrolling {
                    starsLayer(in: geometry.size)
                }

                // Layer 3: Sacred Geometry (simplified)
                if showGeometry && !isScrolling {
                    sacredGeometryLayer
                        .opacity(prayerPeriod.geometryOpacity * intensity)
                }

                // Moon removed - was interfering with navigation UI
            }
        }
        .ignoresSafeArea()
        .onAppear {
            generateStars()
            startAnimations()
        }
        .onChange(of: prayerPeriod) { _, _ in
            generateStars()
        }
    }

    // MARK: - Layer 1: Base Gradient (Theme-Aware)

    private var baseGradient: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
        .animation(.easeInOut(duration: 1), value: prayerPeriod)
    }

    /// Theme-aware gradient colors - NO hardcoded hex colors
    /// Light themes use subtle tints instead of black blending to avoid dimming
    private var gradientColors: [Color] {
        let primary = themeManager.primaryColor
        let background = themeManager.backgroundColor
        let surface = themeManager.surfaceColor
        let isLightTheme = !themeManager.isDarkMode

        switch prayerPeriod {
        case .fajr:
            if isLightTheme {
                // Light themes: subtle warm tint, no black blending
                return [
                    background,
                    primary.opacity(0.06).blended(with: background, ratio: 0.9),
                    background
                ]
            } else {
                // Dark themes: original darkening
                return [
                    background.blended(with: .black, ratio: 0.5),
                    primary.opacity(0.2).blended(with: background, ratio: 0.7),
                    background
                ]
            }
        case .sunrise:
            // Morning - lighter, warm tint (same for both)
            return [
                background.blended(with: primary, ratio: 0.15),
                surface.blended(with: primary, ratio: 0.1),
                background
            ]
        case .dhuhr:
            // Midday - bright, minimal gradient (same for both)
            return [
                background.blended(with: .white, ratio: 0.1),
                background,
                background
            ]
        case .asr:
            // Afternoon - warm golden tint (same for both)
            return [
                background.blended(with: primary, ratio: 0.2),
                surface.blended(with: primary, ratio: 0.1),
                background
            ]
        case .maghrib:
            if isLightTheme {
                // Light themes: warm sunset tint without black
                return [
                    primary.opacity(0.15).blended(with: background, ratio: 0.85),
                    surface.blended(with: primary, ratio: 0.1),
                    background
                ]
            } else {
                // Dark themes: original dramatic effect
                return [
                    primary.opacity(0.3).blended(with: background, ratio: 0.6),
                    surface.blended(with: primary, ratio: 0.2),
                    background.blended(with: .black, ratio: 0.2)
                ]
            }
        case .isha:
            if isLightTheme {
                // Light themes: subtle evening tint without heavy black
                return [
                    primary.opacity(0.1).blended(with: background, ratio: 0.9),
                    surface.blended(with: primary, ratio: 0.05),
                    background
                ]
            } else {
                // Dark themes: original night effect
                return [
                    background.blended(with: .black, ratio: 0.7),
                    surface.blended(with: primary, ratio: 0.1),
                    background.blended(with: .black, ratio: 0.5)
                ]
            }
        case .tahajjud:
            if isLightTheme {
                // Light themes: very subtle deep night tint
                return [
                    primary.opacity(0.08).blended(with: background, ratio: 0.92),
                    background,
                    background
                ]
            } else {
                // Dark themes: original deep night
                return [
                    background.blended(with: .black, ratio: 0.85),
                    background.blended(with: .black, ratio: 0.7),
                    background.blended(with: .black, ratio: 0.6)
                ]
            }
        }
    }

    // MARK: - Layer 2: Stars (Reduced)

    @ViewBuilder
    private func starsLayer(in size: CGSize) -> some View {
        ForEach(stars) { star in
            Circle()
                .fill(themeManager.textOnPrimaryColor.opacity(star.brightness * (0.6 + Darwin.sin(phase * star.twinkleSpeed) * 0.4)))
                .frame(width: star.size, height: star.size)
                .position(x: star.x * size.width, y: star.y * size.height)
        }
        .opacity(prayerPeriod.celestialIntensity * intensity)
    }

    // MARK: - Layer 3: Sacred Geometry (Simplified)

    private var sacredGeometryLayer: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.6

            // Simple 8-point star
            drawSimpleOctagram(context: context, center: center, radius: radius)
        }
        .rotationEffect(.degrees(phase * 2)) // Very slow rotation
    }

    private func drawSimpleOctagram(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        var path = Path()
        let points = 8

        for i in 0..<points {
            let angle = (Double(i) / Double(points)) * .pi * 2 - .pi / 2
            let point = CGPoint(
                x: center.x + Darwin.cos(angle) * radius,
                y: center.y + Darwin.sin(angle) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        context.stroke(path, with: .color(themeManager.primaryColor), lineWidth: 0.5)
    }

    // MARK: - Layer 4: Moon

    @ViewBuilder
    private func moonView(in size: CGSize) -> some View {
        ZStack {
            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            themeManager.textOnPrimaryColor.opacity(0.2),
                            themeManager.textOnPrimaryColor.opacity(0.05),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)

            // Moon body
            Circle()
                .fill(themeManager.textOnPrimaryColor.opacity(0.85))
                .frame(width: 25, height: 25)

            // Crescent shadow
            Circle()
                .fill(themeManager.backgroundColor)
                .frame(width: 22, height: 22)
                .offset(x: 6, y: -2)
        }
        .position(x: size.width * 0.85, y: size.height * 0.12)
    }

    // MARK: - Helpers

    private func generateStars() {
        // Reduced star count: max 25 stars (was 100)
        let starCount = max(10, Int(25 * prayerPeriod.celestialIntensity))
        stars = (0..<starCount).map { _ in
            CelestialStar(
                x: Double.random(in: 0...1),
                y: Double.random(in: 0...0.5),
                size: Double.random(in: 1...2.5),
                brightness: Double.random(in: 0.4...1),
                twinkleSpeed: Double.random(in: 0.5...2)
            )
        }
    }

    private func startAnimations() {
        // Slower animation: 180s instead of 60s (3x slower = 3x fewer updates)
        withAnimation(.linear(duration: 180).repeatForever(autoreverses: false)) {
            phase = .pi * 2
        }
    }
}

// MARK: - Supporting Types

struct CelestialStar: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let size: Double
    let brightness: Double
    let twinkleSpeed: Double
}

// MARK: - Color Blending Extension

extension Color {
    func blended(with other: Color, ratio: Double) -> Color {
        let clampedRatio = max(0, min(1, ratio))

        let uiColor1 = UIColor(self)
        let uiColor2 = UIColor(other)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let r = r1 + (r2 - r1) * clampedRatio
        let g = g1 + (g2 - g1) * clampedRatio
        let b = b1 + (b2 - b1) * clampedRatio
        let a = a1 + (a2 - a1) * clampedRatio

        return Color(UIColor(red: r, green: g, blue: b, alpha: a))
    }
}

// MARK: - Preview

#Preview {
    TabView {
        DivineAtmosphere(prayerPeriod: .fajr)
            .tabItem { Text("Fajr") }

        DivineAtmosphere(prayerPeriod: .dhuhr)
            .tabItem { Text("Dhuhr") }

        DivineAtmosphere(prayerPeriod: .isha)
            .tabItem { Text("Isha") }

        DivineAtmosphere(prayerPeriod: .tahajjud)
            .tabItem { Text("Tahajjud") }
    }
    .environmentObject(ThemeManager())
}
