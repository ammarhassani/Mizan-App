//
//  MosqueGlowEffect.swift
//  Mizan
//
//  A divine "mosque glow" effect for prayer times that creates
//  a spiritual atmosphere around prayer moments
//

import SwiftUI

struct MosqueGlowEffect: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var glowPhase: CGFloat = 0
    @State private var lightRays: [MosqueLightRay] = []
    @State private var domeGlow: [DomeGlowLayer] = []
    @State private var minaretBeams: [MinaretBeam] = []
    @State private var prayerParticles: [MosquePrayerParticle] = []
    @State private var calligraphyPatterns: [CalligraphyPattern] = []

    let prayer: PrayerTime
    let isActive: Bool
    let intensity: CGFloat

    var body: some View {
        ZStack {
            // Base glow layers
            ForEach(domeGlow) { layer in
                DomeGlowLayerView(layer: layer, phase: glowPhase)
            }

            // Light rays from dome
            ForEach(lightRays) { ray in
                MosqueLightRayView(ray: ray, phase: glowPhase)
            }

            // Minaret beams
            ForEach(minaretBeams) { beam in
                MinaretBeamView(beam: beam, phase: glowPhase)
            }

            // Floating prayer particles
            ForEach(prayerParticles) { particle in
                MosquePrayerParticleView(particle: particle, phase: glowPhase)
            }

            // Arabic calligraphy patterns
            ForEach(calligraphyPatterns) { pattern in
                CalligraphyPatternView(pattern: pattern, phase: glowPhase)
                    .environmentObject(themeManager)
            }

            // Central mosque silhouette
            MosqueSilhouetteView(prayer: prayer, phase: glowPhase)
                .environmentObject(themeManager)
        }
        .onAppear {
            initializeMosqueGlow()
            startGlowAnimation()
        }
        .onChange(of: isActive) { _, active in
            if active {
                startGlowAnimation()
            } else {
                stopGlowAnimation()
            }
        }
        .onChange(of: prayer) { _, _ in
            updateGlowForPrayer()
        }
    }

    // MARK: - Animation Control

    private func startGlowAnimation() {
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) {
            glowPhase = 1.0
        }
    }

    private func stopGlowAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            glowPhase = 0
        }
    }

    // MARK: - Mosque Glow Initialization

    private func initializeMosqueGlow() {
        let screenSize = UIScreen.main.bounds

        // Initialize dome glow layers
        domeGlow = [
            DomeGlowLayer(
                id: 0,
                radius: 100,
                color: Color(hex: prayer.colorHex),
                opacity: 0.3,
                pulseSpeed: 1.0
            ),
            DomeGlowLayer(
                id: 1,
                radius: 150,
                color: Color(hex: prayer.colorHex),
                opacity: 0.2,
                pulseSpeed: 0.8
            ),
            DomeGlowLayer(
                id: 2,
                radius: 200,
                color: Color(hex: prayer.colorHex),
                opacity: 0.1,
                pulseSpeed: 0.6
            )
        ]

        // Initialize light rays
        lightRays = (0..<12).map { index in
            MosqueLightRay(
                id: index,
                angle: Double(index) * 30,
                length: 150 + CGFloat.random(in: 0...50),
                width: CGFloat.random(in: 2...4),
                opacity: Double.random(in: 0.3...0.7),
                color: Color(hex: prayer.colorHex)
            )
        }

        // Initialize minaret beams
        minaretBeams = [
            MinaretBeam(
                id: 0,
                x: screenSize.width * 0.3,
                y: screenSize.height * 0.4,
                height: 200,
                width: 30,
                color: Color(hex: prayer.colorHex),
                intensity: 0.8
            ),
            MinaretBeam(
                id: 1,
                x: screenSize.width * 0.7,
                y: screenSize.height * 0.4,
                height: 200,
                width: 30,
                color: Color(hex: prayer.colorHex),
                intensity: 0.8
            )
        ]

        // Initialize prayer particles
        prayerParticles = (0..<30).map { _ in
            MosquePrayerParticle(
                x: CGFloat.random(in: 0...screenSize.width),
                y: CGFloat.random(in: 0...screenSize.height),
                size: CGFloat.random(in: 2...6),
                color: Color(hex: prayer.colorHex),
                velocity: CGPoint(
                    x: CGFloat.random(in: -2...2),
                    y: CGFloat.random(in: -3...(-1))
                ),
                opacity: Double.random(in: 0.4...0.8),
                shape: particleShape
            )
        }

        // Initialize calligraphy patterns
        calligraphyPatterns = [
            CalligraphyPattern(
                id: 0,
                text: "الله",
                x: screenSize.width * 0.5,
                y: screenSize.height * 0.3,
                size: 40,
                rotation: 0,
                opacity: 0.6
            ),
            CalligraphyPattern(
                id: 1,
                text: "محمد",
                x: screenSize.width * 0.2,
                y: screenSize.height * 0.2,
                size: 30,
                rotation: 15,
                opacity: 0.5
            ),
            CalligraphyPattern(
                id: 2,
                text: "الرحمن",
                x: screenSize.width * 0.8,
                y: screenSize.height * 0.2,
                size: 35,
                rotation: -15,
                opacity: 0.5
            )
        ]
    }

    private func updateGlowForPrayer() {
        // Reinitialize with new prayer colors
        initializeMosqueGlow()
    }

    private var particleShape: MosqueParticleShape {
        let shapes: [MosqueParticleShape] = [.circle, .star, .hexagon]
        return shapes.randomElement() ?? .circle
    }
}

// MARK: - Dome Glow Layer View

struct DomeGlowLayerView: View {
    let layer: DomeGlowLayer
    let phase: CGFloat

    var body: some View {
        Circle()
            .fill(layer.color.opacity(layer.opacity))
            .frame(width: layer.radius * 2, height: layer.radius * 2)
            .blur(radius: layer.radius / 4)
            .scaleEffect(1.0 + CGFloat(sin(Double(phase) * layer.pulseSpeed)) * 0.3)
            .opacity(layer.opacity * (0.7 + sin(Double(phase) * layer.pulseSpeed * 2) * 0.3))
    }
}

// MARK: - Mosque Light Ray View

struct MosqueLightRayView: View {
    let ray: MosqueLightRay
    let phase: CGFloat

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [ray.color.opacity(0), ray.color.opacity(ray.opacity), ray.color.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: ray.width)
            .frame(height: ray.length)
            .rotationEffect(.degrees(ray.angle))
            .opacity(ray.opacity * (0.5 + sin(Double(phase) * 2 + ray.angle) * 0.5))
    }
}

// MARK: - Minaret Beam View

struct MinaretBeamView: View {
    let beam: MinaretBeam
    let phase: CGFloat

    var body: some View {
        ZStack {
            // Beam
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [beam.color.opacity(0.2), beam.color.opacity(beam.intensity), beam.color.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: beam.width)
                .frame(height: beam.height)
                .opacity(beam.intensity * (0.7 + CGFloat(sin(Double(phase) * 3)) * 0.3))

            // Beam top light
            Circle()
                .fill(beam.color)
                .frame(width: beam.width * 1.5, height: beam.width * 1.5)
                .position(x: 0, y: -beam.height / 2)
                .blur(radius: 10)
                .scaleEffect(1.0 + CGFloat(sin(Double(phase) * 4)) * 0.3)
        }
        .position(x: beam.x, y: beam.y)
    }
}

// MARK: - Prayer Particle View

struct MosquePrayerParticleView: View {
    let particle: MosquePrayerParticle
    let phase: CGFloat

    var body: some View {
        Group {
            switch particle.shape {
            case .circle:
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)

            case .star:
                MosqueStarShape()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)

            case .hexagon:
                MosqueHexagonShape()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            }
        }
        .position(
            x: particle.x + particle.velocity.x * phase * 30,
            y: particle.y + particle.velocity.y * phase * 30
        )
        .opacity(particle.opacity * (0.5 + sin(Double(phase) * 3) * 0.5))
        .rotationEffect(.degrees(Double(phase) * 180))
    }
}

// MARK: - Calligraphy Pattern View

struct CalligraphyPatternView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let pattern: CalligraphyPattern
    let phase: CGFloat

    var body: some View {
        Text(pattern.text)
            .font(.system(size: pattern.size))
            .foregroundColor(themeManager.textOnPrimaryColor.opacity(pattern.opacity))
            .rotationEffect(.degrees(pattern.rotation))
            .position(x: pattern.x, y: pattern.y)
            .scaleEffect(1.0 + CGFloat(sin(Double(phase) * 0.5)) * 0.1)
            .opacity(pattern.opacity * (0.7 + sin(Double(phase) * 2) * 0.3))
    }
}

// MARK: - Mosque Silhouette View

struct MosqueSilhouetteView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let prayer: PrayerTime
    let phase: CGFloat

    var body: some View {
        ZStack {
            // Main dome
            MosqueDomeShape()
                .fill(themeManager.backgroundColor.opacity(0.8))
                .frame(width: 200, height: 100)
                .position(x: 0, y: -50)

            // Minarets
            MosqueMinaretShape()
                .fill(themeManager.backgroundColor.opacity(0.8))
                .frame(width: 30, height: 250)
                .position(x: -80, y: 0)

            MosqueMinaretShape()
                .fill(themeManager.backgroundColor.opacity(0.8))
                .frame(width: 30, height: 250)
                .position(x: 80, y: 0)

            // Base
            Rectangle()
                .fill(themeManager.backgroundColor.opacity(0.9))
                .frame(width: 300, height: 50)
                .position(x: 0, y: 50)

            // Prayer name
            Text(prayer.prayerType.rawValue)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: prayer.colorHex))
                .position(x: 0, y: 80)
                .scaleEffect(1.0 + CGFloat(sin(Double(phase))) * 0.1)
                .opacity(0.8 + sin(Double(phase) * 2) * 0.2)
        }
        .scaleEffect(1.0 + CGFloat(sin(Double(phase) * 0.5)) * 0.05)
    }
}

// MARK: - Supporting Shapes

struct MosqueDomeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Create dome shape
        path.move(to: CGPoint(x: width / 2, y: height))
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.3),
            control: CGPoint(x: width * 0.8, y: height * 0.8)
        )
        path.addQuadCurve(
            to: CGPoint(x: width / 2, y: 0),
            control: CGPoint(x: width * 0.2, y: height * 0.3)
        )

        return path
    }
}

struct MosqueMinaretShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Create minaret shape
        path.move(to: CGPoint(x: width / 2, y: height))
        path.addLine(to: CGPoint(x: width / 2, y: height * 0.9))
        path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.9))
        path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.7))
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.7))
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.3))
        path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.3))
        path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.1))
        path.addLine(to: CGPoint(x: width / 2, y: height * 0.1))
        path.addLine(to: CGPoint(x: width * 0.3, y: height * 0.1))
        path.addLine(to: CGPoint(x: width * 0.3, y: height * 0.3))
        path.addLine(to: CGPoint(x: width / 2, y: height * 0.5))

        return path
    }
}

struct MosqueStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4

        // Create 5-pointed star
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
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

struct MosqueHexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<6 {
            let angle = Double(i) * .pi / 3
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
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

struct DomeGlowLayer: Identifiable {
    let id: Int
    var radius: CGFloat
    var color: Color
    var opacity: Double
    let pulseSpeed: Double
}

struct MosqueLightRay: Identifiable {
    let id: Int
    let angle: Double
    let length: CGFloat
    let width: CGFloat
    var opacity: Double
    var color: Color
}

struct MinaretBeam: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let height: CGFloat
    let width: CGFloat
    var color: Color
    let intensity: CGFloat
}

struct MosquePrayerParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
    let velocity: CGPoint
    let opacity: Double
    let shape: MosqueParticleShape
}

struct CalligraphyPattern: Identifiable {
    let id: Int
    let text: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let rotation: Double
    let opacity: Double
}

enum MosqueParticleShape {
    case circle, star, hexagon
}

#Preview {
    MosqueGlowEffect(
        prayer: PrayerTime(
            date: Date(),
            prayerType: .maghrib,
            adhanTime: Date(),
            calculationMethod: .mwl
        ),
        isActive: true,
        intensity: 0.8
    )
    .environmentObject(ThemeManager())
}
