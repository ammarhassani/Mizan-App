//
//  ImplosionEffect.swift
//  MizanApp
//
//  Gravitational implosion effect for task/prayer completion.
//

import SwiftUI

struct ImplosionEffect: ViewModifier {
    @Binding var isActive: Bool
    let onComplete: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var blur: CGFloat = 0
    @State private var showFlash: Bool = false

    func body(content: Content) -> some View {
        ZStack {
            content
                .scaleEffect(scale)
                .opacity(opacity)
                .blur(radius: blur)

            // Flash effect
            if showFlash {
                Circle()
                    .fill(Color.white)
                    .scaleEffect(showFlash ? 2 : 0)
                    .opacity(showFlash ? 0 : 1)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                performImplosion()
            }
        }
    }

    private func performImplosion() {
        // Phase 1: Initial squeeze (0-0.15s)
        withAnimation(.easeIn(duration: 0.15)) {
            scale = 0.95
        }

        // Phase 2: Rapid collapse (0.15-0.4s)
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: 150_000_000)
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.25)) {
                    scale = 0.0
                    blur = 5
                }
            }

            // Phase 3: Flash (0.4s)
            try? await _Concurrency.Task.sleep(nanoseconds: 250_000_000)
            await MainActor.run {
                showFlash = true
                withAnimation(.easeOut(duration: 0.15)) {
                    showFlash = false
                }
                opacity = 0
            }

            // Complete
            try? await _Concurrency.Task.sleep(nanoseconds: 150_000_000)
            await MainActor.run {
                onComplete()
            }
        }
    }
}

extension View {
    func implosionEffect(isActive: Binding<Bool>, onComplete: @escaping () -> Void) -> some View {
        modifier(ImplosionEffect(isActive: isActive, onComplete: onComplete))
    }
}

// Simplified ripple effect for immediate use
struct ImplosionRipple: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isVisible: Bool
    let position: CGPoint

    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        if isVisible {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(scale)
                .opacity(opacity)
                .position(position)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.4)) {
                        scale = 1.5
                        opacity = 0
                    }

                    _Concurrency.Task {
                        try? await _Concurrency.Task.sleep(nanoseconds: 400_000_000)
                        await MainActor.run {
                            isVisible = false
                        }
                    }
                }
        }
    }
}
