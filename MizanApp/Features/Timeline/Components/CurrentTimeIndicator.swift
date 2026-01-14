//
//  CurrentTimeIndicator.swift
//  Mizan
//
//  Animated "now" line indicator for the timeline
//

import SwiftUI

/// A pulsing current time indicator for the timeline
struct CurrentTimeIndicator: View {
    @EnvironmentObject var themeManager: ThemeManager

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // Time label with pulsing dot
            HStack(spacing: MZSpacing.xs) {
                // Pulsing dot
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(themeManager.primaryColor.opacity(glowOpacity))
                        .frame(width: 16, height: 16)
                        .blur(radius: 4)

                    // Core dot
                    Circle()
                        .fill(themeManager.primaryColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseScale)
                }

                // Current time label
                Text(Date().formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(themeManager.primaryColor)
                    .padding(.horizontal, MZSpacing.xs)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(themeManager.primaryColor.opacity(0.15))
                    )
            }
            .frame(width: 85, alignment: .trailing)

            // Horizontal line with gradient fade
            LinearGradient(
                colors: [
                    themeManager.primaryColor,
                    themeManager.primaryColor.opacity(0.5),
                    themeManager.primaryColor.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 2)
        }
        .onAppear {
            startPulseAnimation()
        }
    }

    // MARK: - Animation

    private func startPulseAnimation() {
        withAnimation(MZAnimation.timePulse) {
            pulseScale = 1.3
            glowOpacity = 0.7
        }
    }
}

// MARK: - Timeline Position Calculator

extension CurrentTimeIndicator {
    /// Calculates the Y position for the current time indicator within a timeline
    /// - Parameters:
    ///   - timelineBounds: The start and end dates of the visible timeline
    ///   - totalHeight: Total height of the timeline scroll content
    /// - Returns: Y offset where the indicator should be positioned
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
struct CurrentTimeIndicatorCompact: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isGlowing = false

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
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                isGlowing = true
            }
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
    VStack(spacing: MZSpacing.xl) {
        Text("Current Time Indicator")
            .font(MZTypography.titleSmall)

        CurrentTimeIndicator()
            .padding(.horizontal)

        Divider()

        Text("Compact Variant")
            .font(MZTypography.titleSmall)

        CurrentTimeIndicatorCompact()
            .padding(.horizontal)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager())
}
