//
//  MaterializationEffect.swift
//  MizanApp
//
//  Materialization effect for new tasks/items appearing.
//

import SwiftUI

struct MaterializationEffect: ViewModifier {
    let delay: Double

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var blur: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .blur(radius: blur)
            .onAppear {
                _Concurrency.Task {
                    try? await _Concurrency.Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    await MainActor.run {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            scale = 1.0
                            opacity = 1.0
                            blur = 0
                        }
                    }
                }
            }
    }
}

extension View {
    func materialize(delay: Double = 0) -> some View {
        modifier(MaterializationEffect(delay: delay))
    }
}

// Particle burst for materialization celebrations
struct MaterializationBurst: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isVisible: Bool
    let position: CGPoint

    @State private var particles: [MaterializationParticle] = []

    var body: some View {
        if isVisible {
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(themeManager.primaryColor.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .offset(x: particle.offset.width, y: particle.offset.height)
                }
            }
            .position(position)
            .onAppear {
                createParticles()
                animateParticles()
            }
        }
    }

    private func createParticles() {
        particles = (0..<8).map { _ in
            MaterializationParticle(
                id: UUID(),
                offset: .zero,
                size: CGFloat.random(in: 4...8),
                opacity: 1.0,
                angle: CGFloat.random(in: 0...360)
            )
        }
    }

    private func animateParticles() {
        for i in particles.indices {
            let angle = particles[i].angle * .pi / 180
            let distance: CGFloat = CGFloat.random(in: 30...60)

            withAnimation(.easeOut(duration: 0.5)) {
                particles[i].offset = CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                )
                particles[i].opacity = 0
            }
        }

        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                isVisible = false
            }
        }
    }
}

struct MaterializationParticle: Identifiable {
    let id: UUID
    var offset: CGSize
    var size: CGFloat
    var opacity: Double
    var angle: CGFloat
}
