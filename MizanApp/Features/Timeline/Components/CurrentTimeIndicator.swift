//
//  CurrentTimeIndicator.swift
//  Mizan
//
//  Performance-optimized current time indicator.
//  SINGLE animation only - pulsing dot.
//

import SwiftUI

/// Simple current time indicator - pulsing dot + gradient line
struct CinematicCurrentTimeIndicator: View {
    @EnvironmentObject var themeManager: ThemeManager

    var showDivineEffects: Bool = true // Kept for API compatibility

    @State private var pulseScale: CGFloat = 1.0
    @State private var isAnimating: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: MZSpacing.xs) {
            // Pulsing orb marker
            pulsingOrb

            // Time label
            timeLabel

            // Gradient line
            timeLine
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("الوقت الحالي")
        .accessibilityValue(Date().formatted(date: .omitted, time: .shortened))
        .onAppear {
            isAnimating = true
            startPulseAnimation()
        }
        .onDisappear {
            isAnimating = false
            pulseScale = 1.0
        }
    }

    // MARK: - Pulsing Orb

    private var pulsingOrb: some View {
        // Fixed-size container prevents scaleEffect from affecting layout
        ZStack {
            // Glow ring - animated but contained
            Circle()
                .stroke(themeManager.primaryColor.opacity(0.3), lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .scaleEffect(pulseScale)

            // Static glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            themeManager.primaryColor.opacity(0.4),
                            themeManager.primaryColor.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 12
                    )
                )
                .frame(width: 24, height: 24)

            // Core dot - animated but contained
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            themeManager.textOnPrimaryColor.opacity(0.9),
                            themeManager.primaryColor
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: 5
                    )
                )
                .frame(width: 10, height: 10)
                .scaleEffect(pulseScale)

            // Highlight
            Circle()
                .fill(themeManager.textOnPrimaryColor)
                .frame(width: 3, height: 3)
                .offset(x: -1.5, y: -1.5)
                .blur(radius: 0.5)
        }
        .frame(width: 28, height: 28) // Fixed container size prevents layout shifts
    }

    // MARK: - Time Label

    private var timeLabel: some View {
        Text(Date().formatted(date: .omitted, time: .shortened))
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .monospacedDigit() // Prevents layout shift when digits change
            .foregroundColor(themeManager.primaryColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(themeManager.surfaceColor.opacity(0.8))
                    .overlay(
                        Capsule()
                            .stroke(themeManager.primaryColor.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: themeManager.primaryColor.opacity(0.15), radius: 3, y: 1)
            )
    }

    // MARK: - Time Line

    private var timeLine: some View {
        LinearGradient(
            colors: [
                themeManager.primaryColor,
                themeManager.primaryColor.opacity(0.5),
                themeManager.primaryColor.opacity(0.1),
                themeManager.primaryColor.opacity(0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 2)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Single Animation (Cancellable)

    private func startPulseAnimation() {
        guard isAnimating else { return }

        // Animate to expanded
        withAnimation(.easeInOut(duration: 1.5)) {
            pulseScale = 1.15
        }

        // Schedule return to normal
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard isAnimating else { return }
            withAnimation(.easeInOut(duration: 1.5)) {
                pulseScale = 1.0
            }

            // Continue animation loop
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                startPulseAnimation()
            }
        }
    }
}

// MARK: - Timeline Position Calculator

extension CinematicCurrentTimeIndicator {
    /// Calculates the Y position for the current time indicator within a timeline
    static func yPosition(
        in timelineBounds: (start: Date, end: Date),
        totalHeight: CGFloat,
        hourHeight: CGFloat
    ) -> CGFloat? {
        let now = Date()

        // Only show if current time is within timeline bounds
        guard now >= timelineBounds.start && now <= timelineBounds.end else {
            return nil
        }

        // Calculate position based on time
        let totalDuration = timelineBounds.end.timeIntervalSince(timelineBounds.start)
        let elapsed = now.timeIntervalSince(timelineBounds.start)
        let progress = elapsed / totalDuration

        return CGFloat(progress) * totalHeight
    }
}

// MARK: - Compact Variant

/// A minimal current time indicator for compact views
struct CinematicCurrentTimeIndicatorCompact: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isGlowing = false
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 0) {
            // Triangle pointer
            Triangle()
                .fill(themeManager.primaryColor)
                .frame(width: 8, height: 8)
                .rotationEffect(.degrees(90))

            // Line
            Rectangle()
                .fill(themeManager.primaryColor)
                .frame(height: 1)
        }
        .opacity(isGlowing ? 1.0 : 0.7)
        .onAppear {
            isAnimating = true
            startGlowAnimation()
        }
        .onDisappear {
            isAnimating = false
        }
    }

    private func startGlowAnimation() {
        guard isAnimating else { return }

        withAnimation(.easeInOut(duration: 1.0)) {
            isGlowing.toggle()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            startGlowAnimation()
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    let themeManager = ThemeManager()
    VStack(spacing: MZSpacing.xl) {
        Text("Current Time Indicator")
            .font(MZTypography.titleSmall)

        CinematicCurrentTimeIndicator()
            .padding(.horizontal)

        Divider()
            .background(themeManager.dividerColor)

        Text("Compact Variant")
            .font(MZTypography.titleSmall)

        CinematicCurrentTimeIndicatorCompact()
            .padding(.horizontal)
    }
    .padding()
    .background(themeManager.surfaceSecondaryColor.opacity(0.1))
    .environmentObject(themeManager)
}
