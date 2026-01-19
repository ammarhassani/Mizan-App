//
//  TimelineGestureHandler.swift
//  Mizan
//
//  Gesture handler for pinch-to-zoom and long-press interactions
//

import SwiftUI

/// A view modifier that adds pinch-to-zoom and long-press gestures to the timeline
struct TimelineGestureHandler: ViewModifier {
    @Binding var scale: CGFloat
    var onLongPress: ((CGPoint) -> Void)?

    @State private var lastScale: CGFloat = 1.0
    @State private var longPressLocation: CGPoint = .zero

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            // Note: Don't apply scaleEffect here - the scale value is used
            // by the parent view to calculate segment heights dynamically
            .gesture(pinchGesture)
            .simultaneousGesture(longPressGesture)
    }

    // MARK: - Pinch Gesture

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value

                // Clamp to min/max
                let clampedScale = min(max(newScale, MZInteraction.pinchMinScale), MZInteraction.pinchMaxScale)

                // Check for detent haptics
                checkScaleDetent(clampedScale)

                withAnimation(MZAnimation.zoomSnap) {
                    scale = clampedScale
                }
            }
            .onEnded { _ in
                // Snap to nearest detent
                let snappedScale = snapToNearestDetent(scale)

                withAnimation(MZAnimation.zoomSnap) {
                    scale = snappedScale
                }

                lastScale = snappedScale
                HapticManager.shared.trigger(.light)
            }
    }

    // MARK: - Long Press Gesture

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: MZInteraction.longPressDuration)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onEnded { value in
                switch value {
                case .second(true, let drag):
                    if let location = drag?.location {
                        HapticManager.shared.trigger(.medium)
                        onLongPress?(location)
                    }
                default:
                    break
                }
            }
    }

    // MARK: - Helpers

    private func checkScaleDetent(_ newScale: CGFloat) {
        for detent in MZInteraction.scaleDetents {
            if abs(newScale - detent) < 0.05 && abs(scale - detent) >= 0.05 {
                HapticManager.shared.trigger(.light)
                break
            }
        }
    }

    private func snapToNearestDetent(_ value: CGFloat) -> CGFloat {
        var nearestDetent = MZInteraction.scaleDetents[0]
        var minDistance = abs(value - nearestDetent)

        for detent in MZInteraction.scaleDetents {
            let distance = abs(value - detent)
            if distance < minDistance {
                minDistance = distance
                nearestDetent = detent
            }
        }

        return nearestDetent
    }
}

// MARK: - View Extension

extension View {
    /// Adds pinch-to-zoom and long-press gestures to the view
    func timelineGestures(
        scale: Binding<CGFloat>,
        onLongPress: ((CGPoint) -> Void)? = nil
    ) -> some View {
        modifier(TimelineGestureHandler(
            scale: scale,
            onLongPress: onLongPress
        ))
    }
}

// MARK: - Scale Indicator

/// A visual indicator showing the current zoom level
struct TimelineScaleIndicator: View {
    let scale: CGFloat

    @EnvironmentObject var themeManager: ThemeManager
    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: MZSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))

                Text("\(Int(scale * 100))%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(themeManager.textPrimaryColor)
            .padding(.horizontal, MZSpacing.sm)
            .padding(.vertical, MZSpacing.xs)
            .background(
                Capsule()
                    .fill(themeManager.surfaceColor)
                    .shadow(color: themeManager.textPrimaryColor.opacity(0.1), radius: 8, y: 2)
            )
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                // Auto-hide after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(MZAnimation.gentle) {
                        isVisible = false
                    }
                }
            }
        }
    }
}

// MARK: - Zoom Controls

/// Manual zoom controls for accessibility
struct TimelineZoomControls: View {
    @Binding var scale: CGFloat

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: MZSpacing.sm) {
            // Zoom out
            Button {
                zoomOut()
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(scale <= MZInteraction.pinchMinScale ? themeManager.textSecondaryColor : themeManager.primaryColor)
                    .frame(width: 36, height: 36)
                    .background(themeManager.surfaceSecondaryColor)
                    .clipShape(Circle())
            }
            .disabled(scale <= MZInteraction.pinchMinScale)
            .accessibilityLabel("تصغير العرض")
            .accessibilityHint("اضغط مرتين لتصغير الجدول الزمني")

            // Reset
            Button {
                resetZoom()
            } label: {
                Text("100%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(scale == 1.0 ? themeManager.textSecondaryColor : themeManager.primaryColor)
                    .padding(.horizontal, MZSpacing.sm)
                    .padding(.vertical, MZSpacing.xs)
                    .background(themeManager.surfaceSecondaryColor)
                    .clipShape(Capsule())
            }
            .disabled(scale == 1.0)
            .accessibilityLabel("إعادة ضبط التكبير إلى 100%")

            // Zoom in
            Button {
                zoomIn()
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(scale >= MZInteraction.pinchMaxScale ? themeManager.textSecondaryColor : themeManager.primaryColor)
                    .frame(width: 36, height: 36)
                    .background(themeManager.surfaceSecondaryColor)
                    .clipShape(Circle())
            }
            .disabled(scale >= MZInteraction.pinchMaxScale)
            .accessibilityLabel("تكبير العرض")
            .accessibilityHint("اضغط مرتين لتكبير الجدول الزمني")
        }
    }

    // MARK: - Actions

    private func zoomIn() {
        let currentIndex = MZInteraction.scaleDetents.firstIndex(where: { $0 >= scale }) ?? 0
        let nextIndex = min(currentIndex + 1, MZInteraction.scaleDetents.count - 1)

        withAnimation(MZAnimation.zoomSnap) {
            scale = MZInteraction.scaleDetents[nextIndex]
        }
        HapticManager.shared.trigger(.light)
    }

    private func zoomOut() {
        let currentIndex = MZInteraction.scaleDetents.lastIndex(where: { $0 <= scale }) ?? MZInteraction.scaleDetents.count - 1
        let prevIndex = max(currentIndex - 1, 0)

        withAnimation(MZAnimation.zoomSnap) {
            scale = MZInteraction.scaleDetents[prevIndex]
        }
        HapticManager.shared.trigger(.light)
    }

    private func resetZoom() {
        withAnimation(MZAnimation.zoomSnap) {
            scale = 1.0
        }
        HapticManager.shared.trigger(.selection)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var scale: CGFloat = 1.0
        @StateObject private var themeManager = ThemeManager()

        var body: some View {
            VStack(spacing: MZSpacing.xl) {
                Text("Timeline Gestures Demo")
                    .font(MZTypography.titleMedium)

                Text("Scale: \(Int(scale * 100))%")
                    .font(MZTypography.bodyLarge)

                // Content with gestures
                VStack(spacing: 8) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.primaryColor.opacity(0.2))
                            .frame(height: 60)
                            .overlay(Text("Block \(i + 1)"))
                    }
                }
                .timelineGestures(scale: $scale) { _ in
                    // Long press action
                }

                TimelineZoomControls(scale: $scale)

                if scale != 1.0 {
                    TimelineScaleIndicator(scale: scale)
                }
            }
            .padding()
            .environmentObject(themeManager)
        }
    }

    return PreviewWrapper()
}
