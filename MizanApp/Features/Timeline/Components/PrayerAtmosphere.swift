//
//  PrayerAtmosphere.swift
//  Mizan
//
//  Atmospheric effects for prayer times - pulsing glow, countdown badges
//

import SwiftUI

// MARK: - Prayer Countdown Badge

struct PrayerCountdownBadge: View {
    let minutes: Int
    @EnvironmentObject var themeManager: ThemeManager
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12))
            Text("\(minutes) د")
                .font(MZTypography.labelMedium)
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
    let minutesUntil: Int
    let colorHex: String

    @EnvironmentObject var themeManager: ThemeManager
    @State private var isVisible = false

    var body: some View {
        if minutesUntil <= 30 && minutesUntil > 0 {
            HStack(spacing: MZSpacing.sm) {
                Image(systemName: "bell.badge.fill")
                    .symbolEffect(.bounce.byLayer, value: isVisible)

                Text("\(prayerName) في \(minutesUntil) دقيقة")
                    .font(MZTypography.labelLarge)

                Spacer()

                PrayerCountdownBadge(minutes: minutesUntil)
            }
            .foregroundColor(themeManager.textOnPrimaryColor)
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: colorHex))
                    .shadow(color: Color(hex: colorHex).opacity(0.4), radius: 8, y: 4)
            )
            .padding(.horizontal, MZSpacing.screenPadding)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
            .onAppear {
                isVisible = true
                // Haptic when prayer is approaching
                if minutesUntil == 5 || minutesUntil == 1 {
                    HapticManager.shared.trigger(.warning)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PrayerCountdownBadge(minutes: 3)
        PrayerCountdownBadge(minutes: 15)
        PrayerApproachingIndicator(
            prayerName: "المغرب",
            minutesUntil: 5,
            colorHex: "#FF6B6B"
        )
    }
    .padding()
    .background(Color.black)
}
