//
//  TimelineBackgroundAmbience.swift
//  Mizan
//
//  Subtle prayer-aware ambient background for the timeline
//

import SwiftUI

/// Ambient background that subtly reflects the current prayer time
struct TimelineBackgroundAmbience: View {
    let currentPrayer: PrayerType?
    var isScrolling: Bool = false

    @EnvironmentObject var themeManager: ThemeManager
    @State private var gradientOpacity: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Base theme background
            themeManager.backgroundColor

            // Ambient prayer gradient (disabled during scroll)
            if !isScrolling, let prayer = currentPrayer {
                ambientGradient(for: prayer)
                    .opacity(gradientOpacity)
                    .animation(MZAnimation.atmosphereTransition, value: currentPrayer)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                gradientOpacity = 1.0
            }
        }
        .onChange(of: currentPrayer) { _, _ in
            // Smooth transition when prayer changes
            withAnimation(MZAnimation.atmosphereTransition) {
                gradientOpacity = 1.0
            }
        }
    }

    // MARK: - Ambient Gradient

    private func ambientGradient(for prayer: PrayerType) -> some View {
        let colorHex = ConfigurationManager.shared.prayerConfig.defaults[prayer.rawValue]?.colorHex ?? prayer.defaultColorHex
        let prayerColor = Color(hex: colorHex)

        return LinearGradient(
            stops: [
                .init(color: prayerColor.opacity(0.08), location: 0),
                .init(color: prayerColor.opacity(0.04), location: 0.3),
                .init(color: Color.clear, location: 0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Radial Ambience Variant

/// An alternative ambient background with radial glow effect
struct RadialTimelineAmbience: View {
    let currentPrayer: PrayerType?
    var isScrolling: Bool = false

    @EnvironmentObject var themeManager: ThemeManager
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            themeManager.backgroundColor

            if !isScrolling, let prayer = currentPrayer {
                radialGlow(for: prayer)
            }
        }
        .ignoresSafeArea()
    }

    private func radialGlow(for prayer: PrayerType) -> some View {
        let colorHex = ConfigurationManager.shared.prayerConfig.defaults[prayer.rawValue]?.colorHex ?? prayer.defaultColorHex
        let prayerColor = Color(hex: colorHex)

        return GeometryReader { geometry in
            ZStack {
                // Upper ambient glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                prayerColor.opacity(0.1),
                                prayerColor.opacity(0.03),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.7
                        )
                    )
                    .scaleEffect(pulseScale)
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.1)
                    .blur(radius: 30)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

// MARK: - Mesh Gradient Ambience (iOS 18+)

/// A premium mesh gradient ambient background for iOS 18+
@available(iOS 18.0, *)
struct MeshTimelineAmbience: View {
    let currentPrayer: PrayerType?
    var isScrolling: Bool = false

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            themeManager.backgroundColor

            if !isScrolling, let prayer = currentPrayer {
                meshGradient(for: prayer)
                    .opacity(0.15)
            }
        }
        .ignoresSafeArea()
    }

    private func meshGradient(for prayer: PrayerType) -> some View {
        let colorHex = ConfigurationManager.shared.prayerConfig.defaults[prayer.rawValue]?.colorHex ?? prayer.defaultColorHex
        let prayerColor = Color(hex: colorHex)
        let bgColor = themeManager.backgroundColor

        return MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                prayerColor, prayerColor.opacity(0.5), bgColor,
                prayerColor.opacity(0.3), bgColor, bgColor,
                bgColor, bgColor, bgColor
            ]
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        Text("Timeline Ambience")
            .font(.headline)
            .foregroundColor(.white)
            .padding()

        ZStack {
            TimelineBackgroundAmbience(currentPrayer: .fajr)

            VStack {
                Text("Fajr Ambience")
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
        }
        .frame(height: 200)

        ZStack {
            TimelineBackgroundAmbience(currentPrayer: .dhuhr)

            VStack {
                Text("Dhuhr Ambience")
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
        }
        .frame(height: 200)

        ZStack {
            TimelineBackgroundAmbience(currentPrayer: .maghrib)

            VStack {
                Text("Maghrib Ambience")
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
        }
        .frame(height: 200)
    }
    .environmentObject(ThemeManager())
}
