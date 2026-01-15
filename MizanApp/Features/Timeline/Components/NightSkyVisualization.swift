//
//  NightSkyVisualization.swift
//  Mizan
//
//  A breathtaking night sky visualization for Tahajjud/Qiyam prayers
//  Creates a divine celestial atmosphere for late-night worship
//

import SwiftUI

struct NightSkyVisualization: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var nightPhase: CGFloat = 0
    @State private var stars: [NightSkyStar] = []
    @State private var shootingStars: [NightShootingStar] = []
    @State private var nebulae: [NightNebula] = []
    @State private var moonPhases: [NightMoonPhase] = []
    @State private var cosmicDust: [NightCosmicDust] = []

    let isActive: Bool
    let currentPrayer: PrayerType?
    let opacity: CGFloat

    init(isActive: Bool, currentPrayer: PrayerType?, opacity: CGFloat = 1.0) {
        self.isActive = isActive
        self.currentPrayer = currentPrayer
        self.opacity = opacity
    }

    var body: some View {
        ZStack {
            // Deep space background
            NightSkyBackgroundView(phase: nightPhase)
                .environmentObject(themeManager)

            // Nebulae
            ForEach(nebulae) { nebula in
                NightNebulaView(nebula: nebula, phase: nightPhase)
                    .environmentObject(themeManager)
            }

            // Moon phases
            ForEach(moonPhases) { moonPhase in
                NightMoonView(moonPhase: moonPhase, phase: nightPhase)
                    .environmentObject(themeManager)
            }

            // Stars
            ForEach(stars) { star in
                NightStarView(star: star, phase: nightPhase)
                    .environmentObject(themeManager)
            }

            // Shooting stars
            ForEach(shootingStars) { shootingStar in
                NightShootingStarView(shootingStar: shootingStar, phase: nightPhase)
                    .environmentObject(themeManager)
            }

            // Cosmic dust
            ForEach(cosmicDust) { dust in
                NightCosmicDustView(dust: dust, phase: nightPhase)
                    .environmentObject(themeManager)
            }

            // Prayer glow effect
            if let prayer = currentPrayer {
                Circle()
                    .fill(Color(hex: prayer.defaultColorHex).opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 50)
                    .scaleEffect(1.0 + sin(nightPhase * .pi * 2) * 0.2)
            }
        }
        .opacity(opacity)
        .onAppear {
            initializeNightSky()
            startNightAnimation()
        }
        .onDisappear {
            stopNightAnimation()
        }
        .onChange(of: isActive) { _, active in
            if active {
                startNightAnimation()
            } else {
                stopNightAnimation()
            }
        }
    }

    // MARK: - Animation Control

    private func startNightAnimation() {
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            nightPhase = 1.0
        }
    }

    private func stopNightAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            nightPhase = 0
        }
    }

    // MARK: - Night Sky Initialization

    private func initializeNightSky() {
        let screenSize = UIScreen.main.bounds

        // Initialize stars
        stars = (0..<150).map { index in
            NightSkyStar(
                id: index,
                x: CGFloat.random(in: 0...screenSize.width),
                y: CGFloat.random(in: 0...screenSize.height),
                size: CGFloat.random(in: 0.5...3),
                brightness: Double.random(in: 0.3...1.0),
                twinkleSpeed: Double.random(in: 2...8)
            )
        }

        // Initialize shooting stars
        shootingStars = (0..<3).map { index in
            NightShootingStar(
                id: index,
                startX: CGFloat.random(in: 0...screenSize.width),
                startY: CGFloat.random(in: 0...screenSize.height * 0.5),
                endX: CGFloat.random(in: 0...screenSize.width),
                endY: CGFloat.random(in: screenSize.height * 0.5...screenSize.height),
                speed: Double.random(in: 2...5)
            )
        }

        // Initialize nebulae
        nebulae = (0..<2).map { index in
            NightNebula(
                id: index,
                x: CGFloat.random(in: -100...screenSize.width + 100),
                y: CGFloat.random(in: -100...screenSize.height + 100),
                size: CGFloat.random(in: 300...500),
                opacity: Double.random(in: 0.1...0.2),
                rotationSpeed: Double.random(in: 0.1...0.3)
            )
        }

        // Initialize moon phases
        moonPhases = [
            NightMoonPhase(
                id: 0,
                phase: .crescent,
                x: screenSize.width * 0.8,
                y: screenSize.height * 0.15,
                size: 50,
                glowIntensity: 0.7
            )
        ]

        // Initialize cosmic dust
        cosmicDust = (0..<30).map { _ in
            NightCosmicDust(
                x: CGFloat.random(in: 0...screenSize.width),
                y: CGFloat.random(in: 0...screenSize.height),
                size: CGFloat.random(in: 1...2),
                driftSpeed: Double.random(in: 0.2...0.8)
            )
        }
    }
}

// MARK: - Night Sky Background

struct NightSkyBackgroundView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let phase: CGFloat

    var body: some View {
        ZStack {
            // Base gradient - uses theme background as base
            LinearGradient(
                colors: [
                    themeManager.backgroundColor,
                    themeManager.primaryColor.opacity(0.1),
                    themeManager.backgroundColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle moving clouds
            ForEach(0..<2, id: \.self) { index in
                NightSkyCloud(
                    phase: phase,
                    index: index,
                    opacity: 0.05
                )
                .environmentObject(themeManager)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Night Star View

struct NightStarView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let star: NightSkyStar
    let phase: CGFloat

    var body: some View {
        Circle()
            .fill(themeManager.textOnPrimaryColor)
            .frame(width: star.size, height: star.size)
            .position(x: star.x, y: star.y)
            .opacity(star.brightness * (0.5 + sin(phase * .pi * star.twinkleSpeed) * 0.5))
            .blur(radius: star.size / 3)
    }
}

// MARK: - Shooting Star View

struct NightShootingStarView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let shootingStar: NightShootingStar
    let phase: CGFloat

    private var currentPosition: CGPoint {
        let cyclePhase = (phase * shootingStar.speed).truncatingRemainder(dividingBy: 1.0)
        return CGPoint(
            x: shootingStar.startX + (shootingStar.endX - shootingStar.startX) * cyclePhase,
            y: shootingStar.startY + (shootingStar.endY - shootingStar.startY) * cyclePhase
        )
    }

    var body: some View {
        ZStack {
            // Star trail
            Path { path in
                path.move(to: CGPoint(x: shootingStar.startX, y: shootingStar.startY))
                path.addLine(to: currentPosition)
            }
            .stroke(
                LinearGradient(
                    colors: [themeManager.textOnPrimaryColor.opacity(0), themeManager.textOnPrimaryColor.opacity(0.6), themeManager.textOnPrimaryColor.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 1.5
            )
            .opacity(0.8)

            // Star head
            Circle()
                .fill(themeManager.textOnPrimaryColor)
                .frame(width: 3, height: 3)
                .position(currentPosition)
                .blur(radius: 1)
        }
    }
}

// MARK: - Nebula View

struct NightNebulaView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let nebula: NightNebula
    let phase: CGFloat

    var body: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [themeManager.primaryColor.opacity(nebula.opacity), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: nebula.size / 2
                )
            )
            .frame(width: nebula.size, height: nebula.size * 0.6)
            .blur(radius: 40)
            .rotationEffect(.degrees(Double(phase) * nebula.rotationSpeed * 360))
            .position(x: nebula.x, y: nebula.y)
            .opacity(nebula.opacity * (0.7 + sin(Double(phase) * .pi * 2) * 0.3))
    }
}

// MARK: - Moon View

struct NightMoonView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let moonPhase: NightMoonPhase
    let phase: CGFloat

    var body: some View {
        ZStack {
            // Moon glow
            Circle()
                .fill(themeManager.warningColor.opacity(0.2))
                .frame(width: moonPhase.size * 2, height: moonPhase.size * 2)
                .blur(radius: 20)

            // Moon crescent shape
            NightCrescentShape()
                .fill(
                    LinearGradient(
                        colors: [themeManager.warningColor, themeManager.warningColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: moonPhase.size, height: moonPhase.size)
        }
        .position(x: moonPhase.x, y: moonPhase.y)
        .scaleEffect(1.0 + sin(phase * .pi * 2) * 0.05)
        .opacity(moonPhase.glowIntensity)
    }
}

// MARK: - Cosmic Dust View

struct NightCosmicDustView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let dust: NightCosmicDust
    let phase: CGFloat

    var body: some View {
        Circle()
            .fill(themeManager.textOnPrimaryColor.opacity(0.4))
            .frame(width: dust.size, height: dust.size)
            .position(
                x: dust.x + sin(Double(phase) * .pi * dust.driftSpeed) * 15,
                y: dust.y + phase * 3
            )
            .opacity(0.4 + sin(Double(phase) * .pi * 3) * 0.3)
    }
}

// MARK: - Supporting Views

struct NightSkyCloud: View {
    @EnvironmentObject var themeManager: ThemeManager
    let phase: CGFloat
    let index: Int
    let opacity: Double

    var body: some View {
        Ellipse()
            .fill(themeManager.textOnPrimaryColor.opacity(opacity))
            .frame(width: 250 + CGFloat(index) * 80, height: 80)
            .blur(radius: 25)
            .offset(
                x: sin(phase * .pi * 0.2 + Double(index)) * 150,
                y: 40 + CGFloat(index) * 35
            )
            .opacity(0.4 + sin(phase * .pi * 0.4 + Double(index)) * 0.2)
    }
}

struct NightCrescentShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Outer circle
        path.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))

        // Inner circle (to create crescent)
        path.addEllipse(in: CGRect(
            x: center.x - radius * 0.6,
            y: center.y - radius,
            width: radius * 1.2,
            height: radius * 2
        ))

        return path
    }
}

// MARK: - Data Models

struct NightSkyStar: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let brightness: Double
    let twinkleSpeed: Double
}

struct NightShootingStar: Identifiable {
    let id: Int
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let speed: Double
}

struct NightNebula: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let rotationSpeed: Double
}

struct NightMoonPhase: Identifiable {
    let id: Int
    let phase: NightMoonPhaseType
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let glowIntensity: Double
}

struct NightCosmicDust: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let driftSpeed: Double
}

enum NightMoonPhaseType {
    case crescent, half, full
}

#Preview {
    NightSkyVisualization(
        isActive: true,
        currentPrayer: .isha
    )
    .environmentObject(ThemeManager())
}
