//
//  MesmerizingPrayerCountdown.swift
//  Mizan
//
//  A breathtaking prayer countdown experience with dramatic visual effects
//  that creates anticipation and spiritual connection
//

import SwiftUI
import Combine

struct MesmerizingPrayerCountdown: View {
    @EnvironmentObject var themeManager: ThemeManager
    let prayer: PrayerTime
    let isActive: Bool
    var onDismiss: (() -> Void)? = nil

    @State private var timeRemaining: TimeInterval = 0
    @State private var countdownPhase: CGFloat = 0
    @State private var pulseIntensity: CGFloat = 0
    @State private var ringProgress: CGFloat = 0
    @State private var particles: [CountdownParticle] = []
    @State private var lightBeams: [CountdownLightBeam] = []
    @State private var celestialOrbs: [CelestialOrb] = []
    @State private var isUrgent = false
    @State private var showDivineMessage = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background with prayer-specific atmosphere
            CountdownAtmosphereBackground(
                prayer: prayer,
                intensity: pulseIntensity,
                phase: countdownPhase
            )
            .environmentObject(themeManager)

            // Divine light beams
            ForEach(lightBeams) { beam in
                CountdownBeamView(beam: beam, phase: countdownPhase)
                    .environmentObject(themeManager)
            }

            // Celestial orbs
            ForEach(celestialOrbs) { orb in
                CountdownOrbView(orb: orb, phase: countdownPhase)
                    .environmentObject(themeManager)
            }

            // Main countdown display
            VStack(spacing: MZSpacing.lg) {
                // Dismiss button at top
                if onDismiss != nil {
                    HStack {
                        Spacer()
                        Button(action: { onDismiss?() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.7))
                        }
                        .padding(MZSpacing.md)
                    }
                }

                Spacer()

                // Prayer name with divine glow
                CountdownPrayerNameDisplay(
                    prayer: prayer,
                    phase: countdownPhase,
                    isUrgent: isUrgent
                )
                .environmentObject(themeManager)

                // Countdown rings
                CountdownRingsDisplay(
                    progress: ringProgress,
                    prayer: prayer,
                    phase: countdownPhase,
                    isUrgent: isUrgent
                )
                .environmentObject(themeManager)

                // Time display
                CountdownTimeDisplay(
                    timeRemaining: timeRemaining,
                    phase: countdownPhase,
                    isUrgent: isUrgent
                )
                .environmentObject(themeManager)

                // Divine message
                if showDivineMessage {
                    CountdownDivineMessageView(
                        prayer: prayer,
                        phase: countdownPhase
                    )
                    .environmentObject(themeManager)
                }

                Spacer()
            }

            // Floating particles
            ForEach(particles) { particle in
                CountdownParticleView(particle: particle, phase: countdownPhase)
                    .environmentObject(themeManager)
            }
        }
        .onReceive(timer) { _ in
            updateTimeRemaining()
        }
        .onAppear {
            initializeCountdownEffects()
            startCountdownAnimation()
        }
        .onDisappear {
            stopCountdownAnimation()
        }
        .onChange(of: isActive) { _, active in
            if active {
                startCountdownAnimation()
            } else {
                stopCountdownAnimation()
            }
        }
    }

    // MARK: - Countdown Logic

    private func updateTimeRemaining() {
        let now = Date()
        let interval = prayer.adhanTime.timeIntervalSince(now)

        if interval > 0 {
            timeRemaining = interval

            // Update urgency state
            let wasUrgent = isUrgent
            isUrgent = interval <= 300 // 5 minutes

            // Trigger haptic on urgency change
            if !wasUrgent && isUrgent {
                HapticManager.shared.trigger(.warning)
                withAnimation(MZAnimation.celebration) {
                    showDivineMessage = true
                }
            }

            // Update ring progress (based on 1 hour before prayer)
            let totalDuration: TimeInterval = 3600 // 1 hour
            ringProgress = max(0, min(1, 1 - (interval / totalDuration)))

            // Update pulse intensity based on urgency
            pulseIntensity = isUrgent ? 1.0 : 0.5 + CGFloat(interval / 3600) * 0.5
        } else {
            timeRemaining = 0
            ringProgress = 1.0
            triggerPrayerTimeEffect()
        }
    }

    // MARK: - Animation Control

    private func startCountdownAnimation() {
        // Smooth back-and-forth animation for continuous mesmerizing effect
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            countdownPhase = 1.0
        }
    }

    private func stopCountdownAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            countdownPhase = 0
        }
    }

    // MARK: - Effect Initialization

    private func initializeCountdownEffects() {
        let screenSize = UIScreen.main.bounds

        // Initialize light beams (color will be applied from theme at render time)
        lightBeams = (0..<6).map { index in
            CountdownLightBeam(
                id: index,
                angle: Double(index) * 60,
                intensity: 0.3,
                width: 3
            )
        }

        // Initialize celestial orbs (color will be applied from theme at render time)
        celestialOrbs = (0..<8).map { index in
            CelestialOrb(
                id: index,
                x: CGFloat.random(in: 50...screenSize.width - 50),
                y: CGFloat.random(in: 100...screenSize.height - 100),
                size: CGFloat.random(in: 20...50),
                orbitRadius: CGFloat.random(in: 30...80),
                orbitSpeed: Double.random(in: 1...3)
            )
        }

        // Initialize particles (color will be applied from theme at render time)
        particles = (0..<30).map { _ in
            CountdownParticle(
                x: CGFloat.random(in: 0...screenSize.width),
                y: CGFloat.random(in: 0...screenSize.height),
                size: CGFloat.random(in: 2...6),
                velocity: CGPoint(
                    x: CGFloat.random(in: -1...1),
                    y: CGFloat.random(in: -2...0)
                ),
                opacity: Double.random(in: 0.3...0.8)
            )
        }
    }

    private func triggerPrayerTimeEffect() {
        HapticManager.shared.trigger(.success)
    }
}

// MARK: - Countdown Atmosphere Background

struct CountdownAtmosphereBackground: View {
    @EnvironmentObject var themeManager: ThemeManager
    let prayer: PrayerTime
    let intensity: CGFloat
    let phase: CGFloat

    var body: some View {
        ZStack {
            // Base gradient using theme colors
            LinearGradient(
                colors: prayerBackgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Blurred background overlay for depth - increased for dreamy effect
            Circle()
                .fill(themeManager.primaryColor.opacity(0.25))
                .frame(width: 450, height: 450)
                .blur(radius: 100)

            // Pulsing prayer aura - increased blur for ethereal feel
            Circle()
                .fill(themeManager.primaryColor.opacity(0.2))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .scaleEffect(1.0 + sin(Double(phase) * .pi * 2) * intensity * 0.3)

            // Divine rays
            ForEach(0..<8, id: \.self) { index in
                CountdownDivineRay(
                    angle: Double(index) * 45 + Double(phase) * 10,
                    color: themeManager.primaryColor,
                    intensity: intensity,
                    length: 200
                )
            }
        }
        .ignoresSafeArea()
    }

    private var prayerBackgroundColors: [Color] {
        let baseColor = themeManager.backgroundColor

        return [
            baseColor,
            themeManager.primaryColor.opacity(0.3),
            baseColor
        ]
    }
}

// MARK: - Prayer Name Display

struct CountdownPrayerNameDisplay: View {
    @EnvironmentObject var themeManager: ThemeManager
    let prayer: PrayerTime
    let phase: CGFloat
    let isUrgent: Bool

    var body: some View {
        VStack(spacing: MZSpacing.sm) {
            // WCAG2 compliant: white text with shadow for maximum readability
            Text(prayer.displayName)
                .font(MZTypography.displayMedium)
                .foregroundColor(.white)
                .scaleEffect(1.0 + sin(Double(phase) * .pi * 2) * 0.05)
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                .shadow(color: themeManager.primaryColor.opacity(0.6), radius: 15)

            Text(isUrgent ? "اقترب وقت الصلاة" : "الصلاة القادمة")
                .font(MZTypography.bodyLarge)
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
        .padding(.horizontal, MZSpacing.lg)
        .padding(.vertical, MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                .fill(themeManager.surfaceColor.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: themeManager.backgroundColor.opacity(0.3), radius: 10, y: 5)
        )
        .scaleEffect(isUrgent ? 1.0 + sin(Double(phase) * .pi * 6) * 0.05 : 1.0)
    }
}

// MARK: - Countdown Rings

struct CountdownRingsDisplay: View {
    @EnvironmentObject var themeManager: ThemeManager
    let progress: CGFloat
    let prayer: PrayerTime
    let phase: CGFloat
    let isUrgent: Bool

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(themeManager.primaryColor.opacity(0.2), lineWidth: 8)
                .frame(width: 200, height: 200)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .scaleEffect(1.0 + sin(Double(phase) * .pi * 2) * 0.05)

            // Urgent pulse ring
            if isUrgent {
                Circle()
                    .stroke(themeManager.errorColor.opacity(0.6), lineWidth: 2)
                    .frame(width: 220, height: 220)
                    .scaleEffect(1.0 + sin(Double(phase) * .pi * 8) * 0.1)
                    .opacity(0.5 + sin(Double(phase) * .pi * 8) * 0.5)
            }

            // Inner ring
            Circle()
                .stroke(themeManager.primaryColor.opacity(0.1), lineWidth: 4)
                .frame(width: 180, height: 180)
        }
    }
}

// MARK: - Time Display

struct CountdownTimeDisplay: View {
    @EnvironmentObject var themeManager: ThemeManager
    let timeRemaining: TimeInterval
    let phase: CGFloat
    let isUrgent: Bool

    private var formattedTime: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = Int(timeRemaining) % 3600 / 60
        let seconds = Int(timeRemaining) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private var timeUnitText: String {
        // Use proper Arabic pluralization
        if timeRemaining <= 60 {
            let seconds = Int(timeRemaining)
            return seconds.arabicSeconds
        } else if timeRemaining <= 3600 {
            let minutes = Int(timeRemaining) / 60
            return minutes.arabicMinutes
        } else {
            let hours = Int(timeRemaining) / 3600
            return hours.arabicHours
        }
    }

    var body: some View {
        VStack(spacing: MZSpacing.sm) {
            // WCAG2 compliant: white text with shadow for maximum contrast
            Text(formattedTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(isUrgent ? themeManager.errorColor : .white)
                .scaleEffect(1.0 + sin(Double(phase) * .pi * 4) * 0.02)
                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                .shadow(color: (isUrgent ? themeManager.errorColor : themeManager.primaryColor).opacity(0.5), radius: 15)

            Text(timeUnitText)
                .font(MZTypography.bodyMedium)
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
        .padding(.horizontal, MZSpacing.lg)
        .padding(.vertical, MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .fill(themeManager.backgroundColor.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .stroke(
                            isUrgent ? themeManager.errorColor.opacity(0.6) : .white.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Divine Message

struct CountdownDivineMessageView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let prayer: PrayerTime
    let phase: CGFloat

    @State private var messageOpacity: Double = 0
    @State private var messageScale: Double = 0.8

    var body: some View {
        VStack(spacing: MZSpacing.sm) {
            Text("استعد للصلاة")
                .font(MZTypography.headlineMedium)
                .foregroundColor(themeManager.primaryColor)

            Text("حان وقت التوجه إلى الله")
                .font(MZTypography.bodyMedium)
                .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, MZSpacing.lg)
        .padding(.vertical, MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                .fill(themeManager.primaryColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                        .stroke(themeManager.primaryColor.opacity(0.5), lineWidth: 2)
                )
        )
        .scaleEffect(messageScale)
        .opacity(messageOpacity)
        .onAppear {
            withAnimation(MZAnimation.celebration) {
                messageOpacity = 1.0
                messageScale = 1.0
            }
        }
    }
}

// MARK: - Countdown Particle View

struct CountdownParticleView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let particle: CountdownParticle
    let phase: CGFloat

    var body: some View {
        Circle()
            .fill(themeManager.primaryColor)
            .frame(width: particle.size, height: particle.size)
            .position(
                x: particle.x + sin(Double(phase) * .pi * 2) * particle.velocity.x * 20,
                y: particle.y + phase * particle.velocity.y * 10
            )
            .opacity(particle.opacity * (0.5 + sin(Double(phase) * .pi * 4) * 0.5))
    }
}

// MARK: - Countdown Light Beam View

struct CountdownBeamView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let beam: CountdownLightBeam
    let phase: CGFloat

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [themeManager.primaryColor.opacity(0), themeManager.primaryColor.opacity(beam.intensity), themeManager.primaryColor.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: beam.width)
            .frame(height: UIScreen.main.bounds.height)
            .rotationEffect(.degrees(beam.angle))
            .opacity(0.3 + sin(Double(phase) * .pi * 2 + beam.angle * .pi / 180) * 0.2)
    }
}

// MARK: - Celestial Orb View

struct CountdownOrbView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let orb: CelestialOrb
    let phase: CGFloat

    var body: some View {
        ZStack {
            // Glow - increased blur for dreamy effect
            Circle()
                .fill(themeManager.primaryColor.opacity(0.4))
                .frame(width: orb.size * 2.5, height: orb.size * 2.5)
                .blur(radius: 35)

            // Main orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: orb.size / 2
                    )
                )
                .frame(width: orb.size, height: orb.size)
        }
        .position(
            x: orb.x + cos(Double(phase) * .pi * 2 * orb.orbitSpeed) * orb.orbitRadius,
            y: orb.y + sin(Double(phase) * .pi * 2 * orb.orbitSpeed) * orb.orbitRadius
        )
        .scaleEffect(1.0 + sin(Double(phase) * .pi * 4) * 0.2)
    }
}

// MARK: - Divine Ray

struct CountdownDivineRay: View {
    let angle: Double
    let color: Color
    let intensity: CGFloat
    let length: CGFloat

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0), color.opacity(Double(intensity)), color.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2, height: length)
            .rotationEffect(.degrees(angle))
            .opacity(0.5)
    }
}

// MARK: - Data Models

struct CountdownParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let velocity: CGPoint
    let opacity: Double
}

struct CountdownLightBeam: Identifiable {
    let id: Int
    let angle: Double
    var intensity: Double
    let width: CGFloat
}

struct CelestialOrb: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let orbitRadius: CGFloat
    let orbitSpeed: Double
}

#Preview {
    MesmerizingPrayerCountdown(
        prayer: PrayerTime(
            date: Date(),
            prayerType: .maghrib,
            adhanTime: Date().addingTimeInterval(300),
            calculationMethod: .mwl
        ),
        isActive: true
    )
    .environmentObject(ThemeManager())
}
