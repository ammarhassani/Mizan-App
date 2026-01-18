//
//  RamadanModeView.swift
//  Mizan
//
//  A breathtaking Ramadan mode with special effects that creates
//  a divine spiritual experience during the holy month
//

import SwiftUI

struct RamadanModeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var ramadanPhase: CGFloat = 0
    @State private var lanterns: [RamadanLantern] = []
    @State private var stars: [RamadanStar] = []
    @State private var crescentMoons: [CrescentMoon] = []
    @State private var lightBeams: [RamadanLightBeam] = []
    @State private var floatingVerses: [FloatingVerse] = []
    @State private var prayerGlow: [RamadanPrayerGlowEffect] = []
    @State private var isIftarTime = false
    @State private var isSuhoorTime = false

    let prayers: [PrayerTime]
    let currentDate: Date

    // Ramadan gold color - intentionally specific for Ramadan aesthetic
    private var ramadanGold: Color {
        themeManager.warningColor
    }

    var body: some View {
        ZStack {
            // Magical Ramadan night sky
            RamadanNightSky(
                phase: ramadanPhase,
                stars: stars,
                crescents: crescentMoons,
                ramadanGold: ramadanGold
            )
            .environmentObject(themeManager)

            // Floating lanterns
            ForEach(lanterns) { lantern in
                RamadanLanternView(lantern: lantern, phase: ramadanPhase)
            }

            // Divine light beams
            ForEach(lightBeams) { beam in
                RamadanLightBeamView(beam: beam, phase: ramadanPhase)
            }

            // Floating verses
            ForEach(floatingVerses) { verse in
                FloatingVerseView(verse: verse, phase: ramadanPhase, ramadanGold: ramadanGold)
            }

            // Prayer glow effects
            ForEach(prayerGlow) { glow in
                RamadanPrayerGlowView(glow: glow, phase: ramadanPhase)
            }

            // Special time indicators
            if isIftarTime {
                IftarCelebrationView(phase: ramadanPhase, ramadanGold: ramadanGold)
                    .environmentObject(themeManager)
            }

            if isSuhoorTime {
                SuhoorTimeView(phase: ramadanPhase)
                    .environmentObject(themeManager)
            }

            // Ramadan header
            RamadanHeader(
                currentDate: currentDate,
                phase: ramadanPhase,
                ramadanGold: ramadanGold
            )
            .environmentObject(themeManager)
        }
        .onAppear {
            initializeRamadanEffects()
            startRamadanAnimation()
            checkSpecialTimes()
        }
        .onChange(of: currentDate) { _, _ in
            checkSpecialTimes()
        }
    }

    // MARK: - Animation Control

    private func startRamadanAnimation() {
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            ramadanPhase = 1.0
        }
    }

    // MARK: - Effect Initialization

    private func initializeRamadanEffects() {
        let screenSize = UIScreen.main.bounds

        // Initialize lanterns
        lanterns = (0..<12).map { index in
            RamadanLantern(
                id: index,
                x: CGFloat.random(in: 0...screenSize.width),
                y: CGFloat.random(in: 100...screenSize.height - 100),
                size: CGFloat.random(in: 30...60),
                color: lanternColor,
                glowIntensity: Double.random(in: 0.5...1.0),
                swingSpeed: Double.random(in: 1...3),
                swingAmount: CGFloat.random(in: 10...30)
            )
        }

        // Initialize stars
        stars = (0..<50).map { index in
            RamadanStar(
                id: index,
                x: CGFloat.random(in: 0...screenSize.width),
                y: CGFloat.random(in: 0...screenSize.height * 0.6),
                size: CGFloat.random(in: 2...6),
                brightness: Double.random(in: 0.5...1.0),
                twinkleSpeed: Double.random(in: 2...5)
            )
        }

        // Initialize crescent moons
        crescentMoons = (0..<3).map { index in
            CrescentMoon(
                id: index,
                x: CGFloat.random(in: 50...screenSize.width - 50),
                y: CGFloat.random(in: 50...200),
                size: CGFloat.random(in: 40...80),
                rotation: Double.random(in: 0...360),
                glowIntensity: Double.random(in: 0.6...1.0)
            )
        }

        // Initialize light beams
        lightBeams = (0..<8).map { index in
            RamadanLightBeam(
                id: index,
                angle: Double(index) * 45,
                color: ramadanGold,
                intensity: 0.4,
                width: 4
            )
        }

        // Initialize floating verses
        floatingVerses = [
            FloatingVerse(
                text: "شهر رمضان الذي أنزل فيه القرآن",
                x: screenSize.width / 2,
                y: screenSize.height * 0.3,
                fontSize: 20,
                opacity: 0.8,
                floatSpeed: 1.5
            ),
            FloatingVerse(
                text: "هدى للناس وبينات من الهدى والفرقان",
                x: screenSize.width / 2,
                y: screenSize.height * 0.7,
                fontSize: 18,
                opacity: 0.7,
                floatSpeed: 2.0
            )
        ]

        // Initialize prayer glow effects
        prayerGlow = prayers.map { prayer in
            RamadanPrayerGlowEffect(
                prayer: prayer,
                intensity: 0.8,
                radius: 100,
                pulseSpeed: 2.0
            )
        }
    }

    // MARK: - Special Times Check

    private func checkSpecialTimes() {
        let now = Date()

        // Check if it's Iftar time (Maghrib)
        if let maghrib = prayers.first(where: { $0.prayerType == .maghrib }) {
            let timeUntilMaghrib = maghrib.adhanTime.timeIntervalSince(now)
            isIftarTime = timeUntilMaghrib <= 300 && timeUntilMaghrib > 0 // Within 5 minutes
        }

        // Check if it's Suhoor time (before Fajr)
        if let fajr = prayers.first(where: { $0.prayerType == .fajr }) {
            let suhoorTime = fajr.adhanTime.addingTimeInterval(-1800) // 30 minutes before Fajr
            let timeUntilSuhoor = suhoorTime.timeIntervalSince(now)
            isSuhoorTime = timeUntilSuhoor <= 300 && timeUntilSuhoor > 0 // Within 5 minutes
        }
    }

    // MARK: - Color Helpers

    private var lanternColor: Color {
        let colors: [Color] = [ramadanGold, themeManager.warningColor, themeManager.warningColor.opacity(0.8), themeManager.errorColor]
        return colors.randomElement() ?? ramadanGold
    }
}

// MARK: - Ramadan Night Sky

struct RamadanNightSky: View {
    @EnvironmentObject var themeManager: ThemeManager
    let phase: CGFloat
    let stars: [RamadanStar]
    let crescents: [CrescentMoon]
    let ramadanGold: Color

    var body: some View {
        ZStack {
            // Deep night gradient - uses theme background as base
            LinearGradient(
                colors: [
                    themeManager.backgroundColor,
                    themeManager.primaryColor.opacity(0.2),
                    themeManager.backgroundColor.opacity(0.9),
                    themeManager.primaryColor.opacity(0.15),
                    themeManager.backgroundColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Stars
            ForEach(stars) { star in
                RamadanStarView(star: star, phase: phase, starColor: ramadanGold)
            }

            // Crescent moons
            ForEach(crescents) { crescent in
                CrescentMoonView(crescent: crescent, phase: phase, ramadanGold: ramadanGold)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Ramadan Lantern View

struct RamadanLanternView: View {
    let lantern: RamadanLantern
    let phase: CGFloat

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(lantern.color.opacity(0.3))
                .frame(width: lantern.size * 2, height: lantern.size * 2)
                .blur(radius: 20)

            // Main lantern
            VStack(spacing: 5) {
                // Lantern body
                RoundedRectangle(cornerRadius: 10)
                    .fill(lantern.color)
                    .frame(width: lantern.size, height: lantern.size * 1.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(lantern.color.opacity(0.8), lineWidth: 2)
                    )

                // Lantern top
                Circle()
                    .fill(lantern.color)
                    .frame(width: lantern.size * 0.8, height: lantern.size * 0.8)

                // Lantern bottom
                Rectangle()
                    .fill(lantern.color.opacity(0.6))
                    .frame(width: lantern.size * 0.3, height: lantern.size * 0.5)
            }
        }
        .position(
            x: lantern.x + CGFloat(sin(Double(phase) * lantern.swingSpeed)) * lantern.swingAmount,
            y: lantern.y + CGFloat(abs(cos(Double(phase) * lantern.swingSpeed))) * 10
        )
        .rotationEffect(.degrees(sin(Double(phase) * lantern.swingSpeed) * 5))
        .opacity(lantern.glowIntensity)
    }
}

// MARK: - Ramadan Star View

struct RamadanStarView: View {
    let star: RamadanStar
    let phase: CGFloat
    let starColor: Color

    var body: some View {
        ZStack {
            // Star glow
            Circle()
                .fill(starColor.opacity(0.3))
                .frame(width: star.size * 3, height: star.size * 3)
                .blur(radius: star.size)

            // Star shape
            RamadanStarShape()
                .fill(starColor)
                .frame(width: star.size, height: star.size)
        }
        .position(x: star.x, y: star.y)
        .opacity(star.brightness * (0.7 + sin(Double(phase) * star.twinkleSpeed) * 0.3))
        .scaleEffect(1.0 + CGFloat(sin(Double(phase) * star.twinkleSpeed)) * 0.2)
    }
}

// MARK: - Crescent Moon View

struct CrescentMoonView: View {
    let crescent: CrescentMoon
    let phase: CGFloat
    let ramadanGold: Color

    var body: some View {
        ZStack {
            // Moon glow
            Circle()
                .fill(ramadanGold.opacity(0.2))
                .frame(width: crescent.size * 2, height: crescent.size * 2)
                .blur(radius: 30)

            // Crescent shape
            RamadanCrescentShape()
                .fill(
                    LinearGradient(
                        colors: [ramadanGold, ramadanGold.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: crescent.size, height: crescent.size)
                .rotationEffect(.degrees(crescent.rotation + Double(phase) * 10))
        }
        .position(x: crescent.x, y: crescent.y)
        .opacity(crescent.glowIntensity)
    }
}

// MARK: - Ramadan Light Beam View

struct RamadanLightBeamView: View {
    let beam: RamadanLightBeam
    let phase: CGFloat

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [beam.color.opacity(0), beam.color.opacity(beam.intensity), beam.color.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: beam.width)
            .frame(height: UIScreen.main.bounds.height)
            .rotationEffect(.degrees(beam.angle))
            .opacity(0.3 + sin(Double(phase) * 2 + beam.angle) * 0.2)
    }
}

// MARK: - Floating Verse View

struct FloatingVerseView: View {
    let verse: FloatingVerse
    let phase: CGFloat
    let ramadanGold: Color

    var body: some View {
        Text(verse.text)
            .font(.system(size: verse.fontSize, weight: .medium))
            .foregroundColor(ramadanGold.opacity(verse.opacity))
            .multilineTextAlignment(.center)
            .position(
                x: verse.x,
                y: verse.y + CGFloat(sin(Double(phase) * verse.floatSpeed)) * 20
            )
            .opacity(verse.opacity * (0.7 + sin(Double(phase) * 2) * 0.3))
    }
}

// MARK: - Ramadan Prayer Glow View

struct RamadanPrayerGlowView: View {
    let glow: RamadanPrayerGlowEffect
    let phase: CGFloat

    var body: some View {
        Circle()
            .fill(Color(hex: glow.prayer.colorHex).opacity(0.2))
            .frame(width: glow.radius * 2, height: glow.radius * 2)
            .blur(radius: 30)
            .position(x: glow.x, y: glow.y)
            .scaleEffect(1.0 + CGFloat(sin(Double(phase) * glow.pulseSpeed)) * CGFloat(glow.intensity) * 0.3)
            .opacity(glow.intensity * (0.5 + sin(Double(phase) * glow.pulseSpeed) * 0.5))
    }
}

// MARK: - Iftar Celebration View

struct IftarCelebrationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let phase: CGFloat
    let ramadanGold: Color

    @State private var celebrationScale: CGFloat = 0
    @State private var showCelebrationText = false

    var body: some View {
        ZStack {
            // Celebration rays
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(ramadanGold.opacity(0.3))
                    .frame(width: 3, height: 200)
                    .rotationEffect(.degrees(Double(index) * 30 + Double(phase) * 5))
                    .opacity(0.5 + sin(Double(phase) * 2) * 0.5)
            }

            // Celebration text
            if showCelebrationText {
                VStack(spacing: 10) {
                    Text("حان وقت الإفطار")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(ramadanGold)

                    Text("الله أكبر على ما هدانا")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.9))
                }
                .scaleEffect(celebrationScale)
                .opacity(0.8 + sin(Double(phase) * 3) * 0.2)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                celebrationScale = 1.0
                showCelebrationText = true
            }
        }
    }
}

// MARK: - Suhoor Time View

struct SuhoorTimeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let phase: CGFloat

    @State private var showSuhoorText = false

    var body: some View {
        ZStack {
            // Gentle glow
            Circle()
                .fill(themeManager.primaryColor.opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .scaleEffect(1.0 + CGFloat(sin(Double(phase) * 2)) * 0.2)

            // Suhoor text
            if showSuhoorText {
                VStack(spacing: 10) {
                    Text("وقت السحور")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themeManager.primaryColor)

                    Text("تزودوا بالطعام والشراب")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.9))
                }
                .opacity(0.8 + sin(Double(phase) * 2) * 0.2)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                showSuhoorText = true
            }
        }
    }
}

// MARK: - Ramadan Header

struct RamadanHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currentDate: Date
    let phase: CGFloat
    let ramadanGold: Color

    var body: some View {
        VStack(spacing: 15) {
            // Ramadan crescent and star
            ZStack {
                RamadanCrescentShape()
                    .fill(
                        LinearGradient(
                            colors: [ramadanGold, ramadanGold.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                RamadanStarShape()
                    .fill(ramadanGold)
                    .frame(width: 20, height: 20)
                    .offset(x: -20, y: -20)
            }
            .scaleEffect(1.0 + CGFloat(sin(Double(phase))) * 0.1)

            // Ramadan text
            Text("رمضان المبارك")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ramadanGold)

            // Hijri date
            Text(hijriDate)
                .font(.system(size: 18))
                .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.9))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(themeManager.surfaceColor.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(ramadanGold.opacity(0.5), lineWidth: 2)
                )
        )
    }

    private var hijriDate: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: currentDate)
    }
}

// MARK: - Ramadan Crescent Shape

struct RamadanCrescentShape: Shape {
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
            x: center.x - radius * 0.7,
            y: center.y - radius,
            width: radius * 1.4,
            height: radius * 2
        ))

        return path
    }
}

// MARK: - Ramadan Star Shape

struct RamadanStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4

        var path = Path()
        let points = 5

        for i in 0..<points * 2 {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let r = i % 2 == 0 ? radius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * r,
                y: center.y + CGFloat(sin(angle)) * r
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        return path
    }
}

// MARK: - Data Models

struct RamadanLantern: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
    let glowIntensity: Double
    let swingSpeed: Double
    let swingAmount: CGFloat
}

struct RamadanStar: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let brightness: Double
    let twinkleSpeed: Double
}

struct CrescentMoon: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let rotation: Double
    let glowIntensity: Double
}

struct RamadanLightBeam: Identifiable {
    let id: Int
    let angle: Double
    let color: Color
    let intensity: Double
    let width: CGFloat
}

struct FloatingVerse: Identifiable {
    let id = UUID()
    let text: String
    let x: CGFloat
    let y: CGFloat
    let fontSize: CGFloat
    let opacity: Double
    let floatSpeed: Double
}

struct RamadanPrayerGlowEffect: Identifiable {
    let id = UUID()
    let prayer: PrayerTime
    let intensity: Double
    let radius: CGFloat
    let pulseSpeed: Double

    var x: CGFloat {
        UIScreen.main.bounds.width / 2
    }

    var y: CGFloat {
        UIScreen.main.bounds.height / 2
    }
}

#Preview {
    RamadanModeView(
        prayers: [],
        currentDate: Date()
    )
    .environmentObject(ThemeManager())
}
