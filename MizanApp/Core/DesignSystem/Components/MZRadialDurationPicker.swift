//
//  MZRadialDurationPicker.swift
//  Mizan
//
//  Intuitive circular duration picker with drag gesture
//

import SwiftUI
import Foundation

/// A circular duration picker with intuitive drag-to-select interaction
struct MZRadialDurationPicker: View {
    @Binding var duration: Int // in minutes
    var minDuration: Int = 5
    var maxDuration: Int = 480 // 8 hours

    @EnvironmentObject var themeManager: ThemeManager
    @State private var dragAngle: Angle = .zero
    @GestureState private var isDragging = false
    @State private var lastHapticMinute: Int = 0

    // MARK: - Constants

    private let diameter: CGFloat = MZInteraction.radialPickerDiameter
    private let handleSize: CGFloat = MZInteraction.radialHandleSize
    private let strokeWidth: CGFloat = 12
    private let tickCount: Int = 48 // Every 5 minutes for 4 hours
    private let majorTickInterval: Int = 12 // Every hour

    // MARK: - Computed Properties

    private var radius: CGFloat { diameter / 2 - strokeWidth / 2 - 8 }

    private var progress: Double {
        Double(duration - minDuration) / Double(maxDuration - minDuration)
    }

    private var handleAngle: Angle {
        // Start from 12 o'clock (-90°) and go clockwise
        .degrees(-90 + progress * 360)
    }

    private var handlePosition: CGPoint {
        let angle: CGFloat = CGFloat(handleAngle.radians)
        let centerX: CGFloat = diameter / 2
        let centerY: CGFloat = diameter / 2
        let xOffset: CGFloat = radius * CoreGraphics.cos(angle)
        let yOffset: CGFloat = radius * CoreGraphics.sin(angle)
        return CGPoint(x: centerX + xOffset, y: centerY + yOffset)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: MZSpacing.lg) {
            // Duration display
            durationDisplay

            // Radial picker
            ZStack {
                // Background track
                Circle()
                    .stroke(
                        themeManager.surfaceSecondaryColor,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .frame(width: diameter, height: diameter)

                // Progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                themeManager.primaryColor.opacity(0.7),
                                themeManager.primaryColor
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-90 + 360)
                        ),
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .frame(width: diameter, height: diameter)
                    .rotationEffect(.degrees(-90))

                // Tick marks
                tickMarks

                // Draggable handle
                Circle()
                    .fill(themeManager.primaryColor)
                    .frame(width: handleSize, height: handleSize)
                    .shadow(color: themeManager.primaryColor.opacity(0.5), radius: 8, y: 4)
                    .scaleEffect(isDragging ? 1.15 : 1.0)
                    .position(handlePosition)
                    .gesture(dragGesture)
                    .animation(MZAnimation.snappy, value: isDragging)

                // Center display
                centerDisplay
            }
            .frame(width: diameter, height: diameter)

            // Quick presets
            quickPresets
        }
    }

    // MARK: - Duration Display

    private var durationDisplay: some View {
        Text(formattedDuration)
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(themeManager.primaryColor)
            .contentTransition(.numericText())
            .animation(MZAnimation.snappy, value: duration)
    }

    // MARK: - Center Display

    private var centerDisplay: some View {
        VStack(spacing: 2) {
            Text("\(duration)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)
                .contentTransition(.numericText())

            Text("دقيقة")
                .font(MZTypography.labelMedium)
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }

    // MARK: - Tick Marks

    private var tickMarks: some View {
        ForEach(0..<tickCount, id: \.self) { index in
            tickMark(at: index)
        }
    }

    private func tickMark(at index: Int) -> some View {
        let isMajor = index % majorTickInterval == 0
        let angleDegrees = Double(index) / Double(tickCount) * 360 - 90
        let angleRadians = CGFloat(angleDegrees * .pi / 180)
        let innerRadius = radius - strokeWidth - (isMajor ? 12 : 6)
        let outerRadius = radius - strokeWidth - 2
        let center = diameter / 2

        let startX = center + innerRadius * CoreGraphics.cos(angleRadians)
        let startY = center + innerRadius * CoreGraphics.sin(angleRadians)
        let endX = center + outerRadius * CoreGraphics.cos(angleRadians)
        let endY = center + outerRadius * CoreGraphics.sin(angleRadians)

        return Path { path in
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        .stroke(
            themeManager.textSecondaryColor.opacity(isMajor ? 0.5 : 0.2),
            lineWidth: isMajor ? 2 : 1
        )
    }

    // MARK: - Quick Presets

    private var quickPresets: some View {
        HStack(spacing: MZSpacing.sm) {
            ForEach([15, 30, 60, 90, 120], id: \.self) { preset in
                Button {
                    withAnimation(MZAnimation.bouncy) {
                        duration = preset
                    }
                    HapticManager.shared.trigger(.selection)
                } label: {
                    Text(formatPreset(preset))
                        .font(MZTypography.labelMedium)
                        .foregroundColor(duration == preset ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
                        .padding(.horizontal, MZSpacing.sm)
                        .padding(.vertical, MZSpacing.xs)
                        .background(
                            Capsule()
                                .fill(duration == preset ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
                        )
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                let center = CGPoint(x: diameter / 2, y: diameter / 2)
                let vector = CGPoint(
                    x: value.location.x - center.x,
                    y: value.location.y - center.y
                )

                // Calculate angle from vector (atan2 gives angle from positive x-axis)
                var angle = atan2(vector.y, vector.x)

                // Convert to progress (0 at top, clockwise)
                // atan2 gives: right=0, down=π/2, left=±π, up=-π/2
                // We want: top=0, right=0.25, bottom=0.5, left=0.75
                angle += .pi / 2 // Shift so top is 0
                if angle < 0 { angle += .pi * 2 }
                let newProgress = angle / (.pi * 2)

                // Convert progress to duration
                let newDuration = minDuration + Int(newProgress * Double(maxDuration - minDuration))
                let snappedDuration = snapToInterval(newDuration)

                // Trigger haptic on 15-minute intervals
                if snappedDuration != duration {
                    let snapInterval = MZInteraction.durationSnapInterval
                    if snappedDuration % snapInterval == 0 && snappedDuration / snapInterval != lastHapticMinute / snapInterval {
                        HapticManager.shared.trigger(.selection)
                        lastHapticMinute = snappedDuration
                    }
                    duration = snappedDuration
                }
            }
    }

    // MARK: - Helpers

    private func snapToInterval(_ minutes: Int) -> Int {
        let interval = 5 // Snap to nearest 5 minutes
        return (minutes / interval) * interval
    }

    private var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60

        if hours == 0 {
            return "\(minutes) دقيقة"
        } else if minutes == 0 {
            return hours == 1 ? "ساعة" : "\(hours) ساعات"
        } else {
            return "\(hours):\(String(format: "%02d", minutes))"
        }
    }

    private func formatPreset(_ mins: Int) -> String {
        if mins < 60 {
            return "\(mins) د"
        } else {
            let h = mins / 60
            let m = mins % 60
            if m == 0 {
                return "\(h) س"
            } else {
                return "\(h):\(String(format: "%02d", m))"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var duration = 45

        var body: some View {
            MZRadialDurationPicker(duration: $duration)
                .padding()
                .background(Color.gray.opacity(0.1))
                .environmentObject(ThemeManager())
        }
    }

    return PreviewWrapper()
}
