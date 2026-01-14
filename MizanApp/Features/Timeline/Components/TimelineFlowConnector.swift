//
//  TimelineFlowConnector.swift
//  Mizan
//
//  Organic flowing connectors between timeline segments
//

import SwiftUI

/// A flowing connector between timeline segments with animated shimmer
struct TimelineFlowConnector: View {
    let height: CGFloat
    var startColor: Color? = nil
    var endColor: Color? = nil
    var showDuration: Bool = false
    var durationText: String = ""

    @EnvironmentObject var themeManager: ThemeManager
    @State private var shimmerOffset: CGFloat = -100

    // MARK: - Computed Properties

    private var flowColor: Color {
        themeManager.textSecondaryColor.opacity(0.2)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Flowing line
            flowingLine

            // Duration badge (if showing collapsed gap)
            if showDuration && !durationText.isEmpty {
                durationBadge
            }
        }
        .frame(height: height)
        .onAppear {
            startShimmerAnimation()
        }
    }

    // MARK: - Flowing Line

    private var flowingLine: some View {
        GeometryReader { geometry in
            Path { path in
                let midX = geometry.size.width * 0.15 // Align with time column
                let controlOffset: CGFloat = 10

                // Bezier curve flowing downward
                path.move(to: CGPoint(x: midX, y: 0))

                // Gentle curve
                path.addCurve(
                    to: CGPoint(x: midX, y: height),
                    control1: CGPoint(x: midX + controlOffset, y: height * 0.25),
                    control2: CGPoint(x: midX - controlOffset, y: height * 0.75)
                )
            }
            .stroke(
                LinearGradient(
                    colors: [
                        startColor ?? flowColor,
                        flowColor,
                        endColor ?? flowColor
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )

            // Shimmer overlay
            shimmerOverlay(in: geometry)
        }
    }

    // MARK: - Shimmer Overlay

    private func shimmerOverlay(in geometry: GeometryProxy) -> some View {
        Path { path in
            let midX = geometry.size.width * 0.15
            let controlOffset: CGFloat = 10

            path.move(to: CGPoint(x: midX, y: 0))
            path.addCurve(
                to: CGPoint(x: midX, y: height),
                control1: CGPoint(x: midX + controlOffset, y: height * 0.25),
                control2: CGPoint(x: midX - controlOffset, y: height * 0.75)
            )
        }
        .stroke(
            LinearGradient(
                colors: [
                    Color.clear,
                    themeManager.textOnPrimaryColor.opacity(0.3),
                    Color.clear
                ],
                startPoint: UnitPoint(x: 0.5, y: (shimmerOffset / height)),
                endPoint: UnitPoint(x: 0.5, y: (shimmerOffset + 50) / height)
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )
        .mask(
            Rectangle()
                .frame(height: height)
        )
    }

    // MARK: - Duration Badge

    private var durationBadge: some View {
        VStack {
            Spacer()

            HStack(spacing: 4) {
                Text("···")
                    .font(.system(size: 12, weight: .bold))
                Text(durationText)
                    .font(MZTypography.labelSmall)
            }
            .foregroundColor(themeManager.textSecondaryColor.opacity(0.6))
            .padding(.horizontal, MZSpacing.sm)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(themeManager.surfaceSecondaryColor.opacity(0.8))
            )

            Spacer()
        }
    }

    // MARK: - Animation

    private func startShimmerAnimation() {
        withAnimation(MZAnimation.flowShimmer) {
            shimmerOffset = height + 100
        }
    }
}

// MARK: - Simple Flow Connector

/// A simpler flow connector without shimmer for performance
struct SimpleFlowConnector: View {
    let height: CGFloat

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Top dot
            Circle()
                .fill(themeManager.textSecondaryColor.opacity(0.3))
                .frame(width: 4, height: 4)

            // Dashed line
            Rectangle()
                .fill(themeManager.textSecondaryColor.opacity(0.15))
                .frame(width: 1, height: max(0, height - 8))

            // Bottom dot
            Circle()
                .fill(themeManager.textSecondaryColor.opacity(0.3))
                .frame(width: 4, height: 4)
        }
        .frame(height: height)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        // Sample content block
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.blue.opacity(0.2))
            .frame(height: 80)
            .overlay(Text("Prayer Block"))

        // Flow connector
        TimelineFlowConnector(
            height: 60,
            showDuration: true,
            durationText: "30 دقيقة"
        )

        // Another content block
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.green.opacity(0.2))
            .frame(height: 60)
            .overlay(Text("Task Block"))

        // Simple connector
        SimpleFlowConnector(height: 40)

        // Another block
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.purple.opacity(0.2))
            .frame(height: 50)
            .overlay(Text("Nawafil Block"))
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager())
}
