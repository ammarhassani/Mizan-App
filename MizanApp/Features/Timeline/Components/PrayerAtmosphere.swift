//
//  PrayerAtmosphere.swift
//  Mizan
//
//  Atmospheric effects for prayer times - pulsing glow, countdown badges
//

import SwiftUI
import Combine

// MARK: - Prayer Countdown Badge

struct PrayerCountdownBadge: View {
    let minutes: Int
    var seconds: Int = 0
    @EnvironmentObject var themeManager: ThemeManager
    @State private var pulseScale: CGFloat = 1.0

    private var countdownText: String {
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)ث"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12))
            Text(countdownText)
                .font(MZTypography.labelMedium)
                .monospacedDigit()
        }
        .foregroundColor(themeManager.textOnPrimaryColor)
        .padding(.horizontal, MZSpacing.sm)
        .padding(.vertical, MZSpacing.xs)
        .background(
            Capsule()
                .fill(urgencyColor)
                .scaleEffect(pulseScale)
        )
        .onAppear {
            if minutes <= 5 {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.1
                }
            }
        }
    }

    private var urgencyColor: Color {
        if minutes <= 1 {
            return themeManager.urgencyColor(.critical)
        } else if minutes <= 5 {
            return themeManager.urgencyColor(.high)
        } else if minutes <= 15 {
            return themeManager.urgencyColor(.medium)
        } else {
            return themeManager.urgencyColor(.low)
        }
    }
}

// MARK: - Atmospheric Glow Border

struct AtmosphericGlowBorder: View {
    let colorHex: String
    let isActive: Bool

    @State private var pulsePhase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color(hex: colorHex), lineWidth: isActive ? 2 + pulsePhase * 2 : 1)
            .blur(radius: isActive ? 4 + pulsePhase * 4 : 0)
            .opacity(isActive ? 0.6 - pulsePhase * 0.3 : 0.3)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        pulsePhase = 1.0
                    }
                }
            }
    }
}

// MARK: - Time-of-Day Background

struct TimeOfDayBackground: View {
    let date: Date

    private var gradientColors: [Color] {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 4..<6: // Fajr time
            return [Color(hex: "#1a1a2e"), Color(hex: "#16213e"), Color(hex: "#0f3460")]
        case 6..<8: // Sunrise
            return [Color(hex: "#ff9966"), Color(hex: "#ff5e62"), Color(hex: "#ff9966").opacity(0.7)]
        case 8..<12: // Morning
            return [Color(hex: "#a8edea"), Color(hex: "#fed6e3")]
        case 12..<15: // Dhuhr
            return [Color(hex: "#ffecd2"), Color(hex: "#fcb69f")]
        case 15..<17: // Asr
            return [Color(hex: "#fbc2eb"), Color(hex: "#a6c1ee")]
        case 17..<19: // Maghrib
            return [Color(hex: "#fa709a"), Color(hex: "#fee140"), Color(hex: "#fa709a").opacity(0.5)]
        case 19..<21: // Isha early
            return [Color(hex: "#2c3e50"), Color(hex: "#4ca1af")]
        default: // Night
            return [Color(hex: "#0f0c29"), Color(hex: "#302b63"), Color(hex: "#24243e")]
        }
    }

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 1.0), value: Calendar.current.component(.hour, from: date))
    }
}

// MARK: - Prayer Approaching Indicator

struct PrayerApproachingIndicator: View {
    let prayerName: String
    let prayerTime: Date
    let colorHex: String

    @EnvironmentObject var themeManager: ThemeManager
    @State private var isVisible = false
    @State private var currentMinutes: Int = 0
    @State private var currentSeconds: Int = 0

    // Timer to update countdown every second
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private func calculateTimeUntil() -> (minutes: Int, seconds: Int) {
        let totalSeconds = max(0, Int(prayerTime.timeIntervalSince(Date())))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return (minutes, seconds)
    }

    private var countdownText: String {
        if currentMinutes > 0 {
            return String(format: "%d:%02d", currentMinutes, currentSeconds)
        } else {
            return "\(currentSeconds)s"
        }
    }

    var body: some View {
        if currentMinutes <= 30 && (currentMinutes > 0 || currentSeconds > 0) {
            HStack(spacing: MZSpacing.sm) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 16))
                    .symbolEffect(.bounce.byLayer, value: isVisible)

                Text(prayerName)
                    .font(.system(size: 15, weight: .bold))

                Text("بعد")
                    .font(.system(size: 14, weight: .medium))
                    .opacity(0.9)

                Text(countdownText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundColor(themeManager.textOnPrimaryColor)
            .padding(.horizontal, MZSpacing.md)
            .padding(.vertical, MZSpacing.sm + 2)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: colorHex))

                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.textOnPrimaryColor.opacity(0.1),
                                    Color.clear,
                                    Color.black.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Inner border highlight
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(themeManager.textOnPrimaryColor.opacity(0.2), lineWidth: 1)
                }
                .shadow(color: Color(hex: colorHex).opacity(0.4), radius: 8, y: 4)
            )
            .padding(.horizontal, MZSpacing.screenPadding)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
            .onAppear {
                isVisible = true
                let time = calculateTimeUntil()
                currentMinutes = time.minutes
                currentSeconds = time.seconds
                // Haptic when prayer is approaching
                if currentMinutes == 5 || currentMinutes == 1 {
                    HapticManager.shared.trigger(.warning)
                }
            }
            .onReceive(timer) { _ in
                let time = calculateTimeUntil()
                let oldMinutes = currentMinutes
                currentMinutes = time.minutes
                currentSeconds = time.seconds
                // Haptic at key moments
                if currentMinutes != oldMinutes && (currentMinutes == 5 || currentMinutes == 1) {
                    HapticManager.shared.trigger(.warning)
                }
            }
        } else {
            // Hidden but still tracking time
            Color.clear
                .frame(height: 0)
                .onAppear {
                    let time = calculateTimeUntil()
                    currentMinutes = time.minutes
                    currentSeconds = time.seconds
                }
                .onReceive(timer) { _ in
                    let time = calculateTimeUntil()
                    currentMinutes = time.minutes
                    currentSeconds = time.seconds
                }
        }
    }
}

// MARK: - Ambient Particle Effect

/// Subtle floating particles for prayer time atmosphere
struct AmbientParticles: View {
    let prayerType: PrayerType?

    @State private var particles: [AmbientParticle] = []

    private let particleCount = MZInteraction.ambienceParticles

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: particle.size / 3)
                        .position(particle.position)
                }
            }
            .onAppear {
                initializeParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
            .onChange(of: prayerType) { _, _ in
                updateParticleColors()
            }
        }
    }

    // MARK: - Particle Initialization

    private func initializeParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            AmbientParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 2...4),
                opacity: Double.random(in: 0.1...0.2),
                color: particleColor,
                velocity: CGPoint(
                    x: CGFloat.random(in: -0.3...0.3),
                    y: CGFloat.random(in: -0.5 ... -0.1) // Drift upward
                )
            )
        }
    }

    private func animateParticles(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { _ in
            for i in particles.indices {
                var particle = particles[i]

                // Update position
                particle.position.x += particle.velocity.x
                particle.position.y += particle.velocity.y

                // Wrap around edges
                if particle.position.y < -10 {
                    particle.position.y = size.height + 10
                    particle.position.x = CGFloat.random(in: 0...size.width)
                }
                if particle.position.x < -10 {
                    particle.position.x = size.width + 10
                }
                if particle.position.x > size.width + 10 {
                    particle.position.x = -10
                }

                // Subtle opacity fluctuation
                particle.opacity = max(0.1, min(0.2, particle.opacity + Double.random(in: -0.005...0.005)))

                particles[i] = particle
            }
        }
    }

    private func updateParticleColors() {
        let newColor = particleColor
        for i in particles.indices {
            particles[i].color = newColor
        }
    }

    private var particleColor: Color {
        guard let prayer = prayerType else {
            return Color.white.opacity(0.5)
        }

        switch prayer {
        case .fajr:
            return Color(hex: "#E8D5B7") // Soft cream/gold for dawn
        case .dhuhr:
            return Color(hex: "#FFE4B5") // Golden
        case .asr:
            return Color(hex: "#DDA0DD") // Soft purple
        case .maghrib:
            return Color(hex: "#FF6B6B") // Warm coral
        case .isha:
            return Color(hex: "#B8C4CE") // Cool silver/blue
        }
    }
}

// MARK: - Ambient Particle Model

struct AmbientParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var color: Color
    var velocity: CGPoint
}

// MARK: - Prayer Time Ambience

/// Complete prayer time atmosphere with gradient and particles
struct PrayerTimeAmbience: View {
    let currentPrayer: PrayerType?
    var showParticles: Bool = true

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            // Background gradient
            if let prayer = currentPrayer {
                prayerGradient(for: prayer)
                    .animation(MZAnimation.atmosphereTransition, value: currentPrayer)
            }

            // Subtle particles
            if showParticles {
                AmbientParticles(prayerType: currentPrayer)
            }
        }
        .ignoresSafeArea()
    }

    private func prayerGradient(for prayer: PrayerType) -> some View {
        let colors = gradientColors(for: prayer)
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(0.15) // Very subtle
    }

    private func gradientColors(for prayer: PrayerType) -> [Color] {
        switch prayer {
        case .fajr:
            return [Color(hex: "#1a1a2e"), Color(hex: "#16213e"), Color(hex: "#0f3460")]
        case .dhuhr:
            return [Color(hex: "#ffecd2"), Color(hex: "#fcb69f")]
        case .asr:
            return [Color(hex: "#fbc2eb"), Color(hex: "#a6c1ee")]
        case .maghrib:
            return [Color(hex: "#fa709a"), Color(hex: "#fee140")]
        case .isha:
            return [Color(hex: "#0f0c29"), Color(hex: "#302b63")]
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PrayerCountdownBadge(minutes: 3, seconds: 45)
        PrayerCountdownBadge(minutes: 0, seconds: 30)
        PrayerApproachingIndicator(
            prayerName: "المغرب",
            prayerTime: Date().addingTimeInterval(5 * 60), // 5 minutes from now
            colorHex: "#FF6B6B"
        )
    }
    .padding()
    .background(Color.black)
    .environmentObject(ThemeManager())
}

#Preview("Ambient Particles") {
    ZStack {
        Color.black
        AmbientParticles(prayerType: .fajr)
    }
}

#Preview("Prayer Ambience") {
    PrayerTimeAmbience(currentPrayer: .maghrib)
        .environmentObject(ThemeManager())
}
