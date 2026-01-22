//
//  WarpTransition.swift
//  Mizan
//
//  View transition with motion blur warp effect for tab switching
//

import SwiftUI
import UIKit

// MARK: - WarpDirection

/// Direction of warp transition
enum WarpDirection {
    case left
    case right
    case up
    case down

    var offset: CGSize {
        switch self {
        case .left: return CGSize(width: -UIScreen.main.bounds.width, height: 0)
        case .right: return CGSize(width: UIScreen.main.bounds.width, height: 0)
        case .up: return CGSize(width: 0, height: -UIScreen.main.bounds.height)
        case .down: return CGSize(width: 0, height: UIScreen.main.bounds.height)
        }
    }

    var opposite: WarpDirection {
        switch self {
        case .left: return .right
        case .right: return .left
        case .up: return .down
        case .down: return .up
        }
    }

    /// Edge for SwiftUI transitions
    var edge: Edge {
        switch self {
        case .left: return .leading
        case .right: return .trailing
        case .up: return .top
        case .down: return .bottom
        }
    }
}

// MARK: - WarpTransitionModifier

/// Warp transition view modifier with motion blur effect
struct WarpTransitionModifier: ViewModifier {
    let direction: WarpDirection
    let isActive: Bool

    @State private var blur: CGFloat = 0
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .offset(offset)
            .scaleEffect(scale)
            .onChange(of: isActive) { _, active in
                if active {
                    performWarpOut()
                } else {
                    performWarpIn()
                }
            }
    }

    private func performWarpOut() {
        // Phase 1: Motion blur starts
        withAnimation(.easeIn(duration: 0.1)) {
            blur = 20
            scale = 0.98
        }

        // Phase 2: Slide out
        withAnimation(.easeIn(duration: 0.15).delay(0.1)) {
            offset = direction.offset
        }
    }

    private func performWarpIn() {
        // Reset to opposite side
        offset = direction.opposite.offset
        blur = 15
        scale = 0.98

        // Phase 1: Slide in with blur
        withAnimation(.easeOut(duration: 0.15)) {
            offset = .zero
        }

        // Phase 2: Clear blur and settle
        withAnimation(CinematicAnimation.snappy.delay(0.1)) {
            blur = 0
            scale = 1.0
        }
    }
}

// MARK: - WarpTransitionContainer

/// Container that handles warp transitions between child views
struct WarpTransitionContainer<Content: View>: View {
    let selection: Int
    @ViewBuilder let content: () -> Content

    @State private var currentSelection: Int
    @State private var isTransitioning = false
    @State private var transitionDirection: WarpDirection = .right

    init(selection: Int, @ViewBuilder content: @escaping () -> Content) {
        self.selection = selection
        self._currentSelection = State(initialValue: selection)
        self.content = content
    }

    var body: some View {
        ZStack {
            // Void background (visible during transition)
            CinematicColors.voidBlack

            // Content with transition
            content()
                .modifier(WarpTransitionModifier(
                    direction: transitionDirection,
                    isActive: isTransitioning
                ))
        }
        .onChange(of: selection) { oldValue, newValue in
            if oldValue != newValue {
                performTransition(from: oldValue, to: newValue)
            }
        }
    }

    private func performTransition(from oldIndex: Int, to newIndex: Int) {
        transitionDirection = newIndex > oldIndex ? .left : .right
        isTransitioning = true

        // Wait for warp-out animation to complete (0.1s blur + 0.15s slide = 0.25s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentSelection = newIndex
            isTransitioning = false
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply warp transition effect
    /// - Parameters:
    ///   - direction: Direction of the warp movement
    ///   - isActive: Whether the transition is currently active
    func warpTransition(direction: WarpDirection, isActive: Bool) -> some View {
        modifier(WarpTransitionModifier(direction: direction, isActive: isActive))
    }
}

// MARK: - AnyTransition Extension

/// SwiftUI Transition for use with .transition()
extension AnyTransition {
    /// Warp transition with motion blur effect
    /// - Parameter direction: Direction of the warp movement
    static func warp(direction: WarpDirection) -> AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: direction == .left ? .trailing : .leading)),
            removal: .opacity.combined(with: .move(edge: direction == .left ? .leading : .trailing))
        )
    }

    /// Horizontal warp with automatic direction based on comparison
    static var warpHorizontal: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        )
    }

    /// Vertical warp for up/down transitions
    static var warpVertical: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity.combined(with: .move(edge: .top))
        )
    }
}

// MARK: - Preview

#if DEBUG
struct WarpTransition_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var selection = 0

        var body: some View {
            ZStack {
                CinematicColors.voidBlack.ignoresSafeArea()

                VStack {
                    ZStack {
                        if selection == 0 {
                            CinematicColors.accentCyan.opacity(0.3)
                                .overlay(
                                    Text("Tab 1")
                                        .foregroundColor(CinematicColors.textPrimary)
                                )
                                .transition(.warp(direction: .left))
                        } else if selection == 1 {
                            CinematicColors.success.opacity(0.3)
                                .overlay(
                                    Text("Tab 2")
                                        .foregroundColor(CinematicColors.textPrimary)
                                )
                                .transition(.warp(direction: .left))
                        } else {
                            CinematicColors.accentMagenta.opacity(0.3)
                                .overlay(
                                    Text("Tab 3")
                                        .foregroundColor(CinematicColors.textPrimary)
                                )
                                .transition(.warp(direction: .left))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(CinematicAnimation.warp, value: selection)

                    HStack(spacing: 20) {
                        ForEach(0..<3) { index in
                            Button("Tab \(index + 1)") {
                                withAnimation(CinematicAnimation.warp) {
                                    selection = index
                                }
                            }
                            .foregroundColor(
                                selection == index
                                    ? CinematicColors.accentCyan
                                    : CinematicColors.textSecondary
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        selection == index
                                            ? CinematicColors.surface
                                            : Color.clear
                                    )
                            )
                        }
                    }
                    .padding()
                    .background(CinematicColors.surfaceSecondary)
                }
            }
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .previewDisplayName("Warp Transition")
    }
}
#endif
