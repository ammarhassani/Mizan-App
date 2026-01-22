//
//  EventHorizonDock.swift
//  Mizan
//
//  Orbital navigation dock for Event Horizon UI
//  Replaces standard TabView with cinematic navigation
//

import SwiftUI
import UIKit

// MARK: - DockDestination

/// Navigation destinations for the orbital dock
enum DockDestination: Int, CaseIterable, Identifiable {
    case timeline = 0
    case inbox = 1
    case mizanAI = 2
    case settings = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .timeline: return "الجدول"
        case .inbox: return "المهام"
        case .mizanAI: return "Mizan AI"
        case .settings: return "الإعدادات"
        }
    }

    var icon: String {
        switch self {
        case .timeline: return "calendar"
        case .inbox: return "tray.fill"
        case .mizanAI: return "sparkles"
        case .settings: return "gearshape.fill"
        }
    }

    /// Position angle on the ellipse (degrees from top)
    var orbitAngle: Double {
        switch self {
        case .timeline: return 0      // Top
        case .inbox: return 90        // Right
        case .mizanAI: return 180     // Bottom
        case .settings: return 270    // Left
        }
    }
}

// MARK: - EventHorizonDock

/// Orbital navigation dock with collapsed and expanded states
struct EventHorizonDock: View {
    @Binding var selection: DockDestination

    @State private var isExpanded = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var orbitRotation: Double = 0
    @State private var autoCollapseTask: _Concurrency.Task<Void, Never>?

    // MARK: - Configuration

    private let collapsedSize: CGFloat = 12
    private let expandedWidth: CGFloat = 280
    private let expandedHeight: CGFloat = 80
    private let iconSize: CGFloat = 24
    private let autoCollapseDelay: Double = 3.0

    // MARK: - Body

    var body: some View {
        ZStack {
            if isExpanded {
                // Placeholder - will be implemented in Task 3
                Text("Expanded")
                    .foregroundColor(CinematicColors.textPrimary)
            } else {
                collapsedView
            }
        }
        .frame(height: isExpanded ? expandedHeight + 60 : collapsedSize + 40)
        .onAppear {
            startPulseAnimation()
        }
        .onDisappear {
            autoCollapseTask?.cancel()
            autoCollapseTask = nil
        }
    }

    // MARK: - Collapsed View

    private var collapsedView: some View {
        Button {
            expandDock()
        } label: {
            ZStack {
                // Outer glow
                Circle()
                    .fill(CinematicColors.accentCyan.opacity(0.3))
                    .frame(width: collapsedSize * 2, height: collapsedSize * 2)
                    .blur(radius: 8)
                    .scaleEffect(pulseScale)

                // Core point
                Circle()
                    .fill(CinematicColors.accentCyan)
                    .frame(width: collapsedSize, height: collapsedSize)

                // Inner bright spot
                Circle()
                    .fill(CinematicColors.textPrimary)
                    .frame(width: collapsedSize * 0.4, height: collapsedSize * 0.4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Expand/Collapse Functions

    private func expandDock() {
        autoCollapseTask?.cancel()

        withAnimation(CinematicAnimation.dockExpand) {
            isExpanded = true
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()

        scheduleAutoCollapse()
        startOrbitRotation()
    }

    private func collapseDock() {
        autoCollapseTask?.cancel()

        withAnimation(CinematicAnimation.dockCollapse) {
            isExpanded = false
        }

        // Reset rotation for next expansion
        orbitRotation = 0
    }

    private func scheduleAutoCollapse() {
        autoCollapseTask = _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(autoCollapseDelay * 1_000_000_000))
            if !_Concurrency.Task.isCancelled {
                await MainActor.run {
                    collapseDock()
                }
            }
        }
    }

    private func startOrbitRotation() {
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }
    }

    private func startPulseAnimation() {
        withAnimation(CinematicAnimation.pulse) {
            pulseScale = 1.2
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        CinematicColors.voidBlack
            .ignoresSafeArea()

        VStack {
            Spacer()
            EventHorizonDock(selection: .constant(.timeline))
        }
    }
}
