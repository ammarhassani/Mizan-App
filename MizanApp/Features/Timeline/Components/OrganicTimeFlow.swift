//
//  OrganicTimeFlow.swift
//  Mizan
//
//  A fluid organic connector between timeline segments with
//  flowing gradient and glassmorphic duration badge
//

import SwiftUI

/// Organic flowing connector between timeline segments
struct OrganicTimeFlow: View {
    let height: CGFloat
    var startColor: Color? = nil
    var endColor: Color? = nil
    var duration: TimeInterval = 0
    var isCollapsed: Bool = false

    @EnvironmentObject var themeManager: ThemeManager
    @State private var shimmerOffset: CGFloat = -100

    // MARK: - Computed Properties

    private var durationText: String {
        if duration < 60 {
            return "\(Int(duration)) ث"
        } else if duration < 3600 {
            let minutes = Int(duration / 60)
            return "\(minutes) د"
        } else {
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            return minutes > 0 ? "\(hours) س \(minutes) د" : "\(hours) س"
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Organic flowing path
            organicPath

            // Duration badge for collapsed gaps
            if isCollapsed && duration > 0 {
                durationBadge
            }
        }
        .frame(height: height)
        .onAppear {
            startShimmerAnimation()
        }
    }

    // MARK: - Organic Path

    private var organicPath: some View {
        let effectiveStartColor = startColor ?? themeManager.textSecondaryColor.opacity(0.3)
        let effectiveEndColor = endColor ?? themeManager.textSecondaryColor.opacity(0.3)
        let midColor = themeManager.textSecondaryColor.opacity(0.15)

        return HStack(spacing: 0) {
            // Wave positioned at left edge with fixed width
            ZStack {
                // Main flowing line
                OrganicWavePath(height: height)
                    .stroke(
                        LinearGradient(
                            colors: [effectiveStartColor, midColor, effectiveEndColor],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )

                // Shimmer effect
                OrganicWavePath(height: height)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                themeManager.textOnPrimaryColor.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: UnitPoint(x: 0.5, y: max(0, (shimmerOffset - 30) / height)),
                            endPoint: UnitPoint(x: 0.5, y: min(1, (shimmerOffset + 30) / height))
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
            }
            .frame(width: 20, height: height)

            Spacer()
        }
    }

    // MARK: - Duration Badge

    private var durationBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "wave.3.right")
                .font(.system(size: 10, weight: .medium))

            Text(durationText)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(themeManager.textSecondaryColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(themeManager.surfaceColor.opacity(0.85))
                .overlay(
                    Capsule()
                        .stroke(themeManager.textSecondaryColor.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: themeManager.backgroundColor.opacity(0.3), radius: 4, y: 2)
        )
    }

    // MARK: - Animation

    private func startShimmerAnimation() {
        withAnimation(MZAnimation.flowShimmer) {
            shimmerOffset = height + 100
        }
    }
}

// MARK: - Organic Wave Path Shape

struct OrganicWavePath: Shape {
    let height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let amplitude: CGFloat = 6
        let segments = max(10, Int(height / 4))

        for i in 0...segments {
            let progress = CGFloat(i) / CGFloat(segments)
            let y = progress * height

            // Gentle sine wave
            let waveOffset = sin(progress * .pi * 2) * amplitude
            let x = midX + waveOffset

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

// MARK: - Compact Flow Dot

/// A minimal dot connector for very short gaps
struct CompactFlowDot: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(themeManager.textSecondaryColor.opacity(0.5))
                .frame(width: 3, height: 3)

            Circle()
                .fill(themeManager.textSecondaryColor.opacity(0.4))
                .frame(width: 2, height: 2)

            Circle()
                .fill(themeManager.textSecondaryColor.opacity(0.5))
                .frame(width: 3, height: 3)
        }
    }
}

// MARK: - Preview

#Preview {
    let themeManager = ThemeManager()
    ScrollView {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.primaryColor.opacity(0.3))
                .frame(height: 100)
                .overlay(Text("Fajr").foregroundColor(themeManager.textOnPrimaryColor))

            OrganicTimeFlow(
                height: 50,
                startColor: themeManager.primaryColor.opacity(0.4),
                endColor: themeManager.warningColor.opacity(0.4),
                duration: 1800
            )

            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.warningColor.opacity(0.3))
                .frame(height: 60)
                .overlay(Text("Task").foregroundColor(themeManager.textOnPrimaryColor))

            OrganicTimeFlow(
                height: 60,
                startColor: themeManager.warningColor.opacity(0.4),
                endColor: themeManager.categoryColor(.worship).opacity(0.4),
                duration: 7200,
                isCollapsed: true
            )

            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.categoryColor(.worship).opacity(0.3))
                .frame(height: 50)
                .overlay(Text("Duha").foregroundColor(themeManager.textOnPrimaryColor))

            CompactFlowDot()
                .frame(height: 20)

            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.successColor.opacity(0.3))
                .frame(height: 100)
                .overlay(Text("Dhuhr").foregroundColor(themeManager.textOnPrimaryColor))
        }
        .padding()
    }
    .background(themeManager.overlayColor.opacity(0.95))
    .environmentObject(themeManager)
}
