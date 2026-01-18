//
//  TaskCompletionCelebration.swift
//  Mizan
//
//  Dramatic task completion celebration with confetti and checkmark animation
//

import SwiftUI

// MARK: - Celebration Overlay

struct TaskCompletionCelebration: View {
    @Binding var isPresented: Bool
    var message: String = "أحسنت!"

    @EnvironmentObject var themeManager: ThemeManager
    @State private var ringProgress: CGFloat = 0
    @State private var checkmarkVisible = false
    @State private var textVisible = false
    @State private var confettiTrigger = false

    var body: some View {
        if isPresented {
            ZStack {
                // Dimmed background
                themeManager.overlayColor.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }

                VStack(spacing: MZSpacing.lg) {
                    // Animated checkmark circle
                    ZStack {
                        // Ring progress
                        Circle()
                            .stroke(themeManager.successColor.opacity(0.3), lineWidth: 8)
                            .frame(width: 120, height: 120)

                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(themeManager.successColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))

                        // Checkmark
                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(themeManager.successColor)
                            .scaleEffect(checkmarkVisible ? 1.0 : 0.3)
                            .opacity(checkmarkVisible ? 1.0 : 0.0)
                    }

                    // Celebration text
                    Text(message)
                        .font(MZTypography.headlineMedium)
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .opacity(textVisible ? 1 : 0)
                        .scaleEffect(textVisible ? 1 : 0.8)
                }

                // Confetti particles
                ConfettiView(trigger: confettiTrigger)
            }
            .onAppear {
                runCelebration()
            }
        }
    }

    private func runCelebration() {
        // Haptic burst
        HapticManager.shared.trigger(.success)

        // Ring fills
        withAnimation(.easeOut(duration: 0.4)) {
            ringProgress = 1.0
        }

        // Checkmark bounces in
        withAnimation(MZAnimation.bouncy.delay(0.3)) {
            checkmarkVisible = true
        }

        // Text fades in
        withAnimation(MZAnimation.gentle.delay(0.5)) {
            textVisible = true
        }

        // Confetti burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            confettiTrigger = true
        }

        // Auto-dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(MZAnimation.snappy) {
            isPresented = false
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    let trigger: Bool

    @EnvironmentObject var themeManager: ThemeManager
    @State private var particles: [ConfettiParticle] = []

    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var scale: CGFloat
        let color: Color
        let shape: ConfettiShape
    }

    enum ConfettiShape {
        case circle, square, star

        @ViewBuilder
        func view(color: Color, size: CGFloat) -> some View {
            switch self {
            case .circle:
                Circle().fill(color).frame(width: size, height: size)
            case .square:
                Rectangle().fill(color).frame(width: size, height: size)
            case .star:
                Image(systemName: "star.fill")
                    .font(.system(size: size))
                    .foregroundColor(color)
            }
        }
    }

    // Theme-aware celebration colors
    private var colors: [Color] {
        [
            themeManager.successColor,
            themeManager.warningColor,
            themeManager.primaryColor,
            themeManager.errorColor,
            themeManager.primaryColor.opacity(0.7),
            themeManager.successColor.opacity(0.8)
        ]
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { particle in
                particle.shape.view(color: particle.color, size: 10 * particle.scale)
                    .position(x: particle.x, y: particle.y)
                    .rotationEffect(.degrees(particle.rotation))
            }
        }
        .onChange(of: trigger) { _, newValue in
            if newValue {
                burstConfetti()
            }
        }
    }

    private func burstConfetti() {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2 - 50

        // Generate particles at center
        particles = (0..<40).map { _ in
            ConfettiParticle(
                x: centerX,
                y: centerY,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.8...1.5),
                color: colors.randomElement() ?? .green,
                shape: [.circle, .square, .star].randomElement() ?? .circle
            )
        }

        // Animate explosion
        withAnimation(.easeOut(duration: 1.0)) {
            for i in particles.indices {
                particles[i].x += CGFloat.random(in: -150...150)
                particles[i].y += CGFloat.random(in: -200...300)
                particles[i].rotation += Double.random(in: 180...720)
            }
        }

        // Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                for i in particles.indices {
                    particles[i].scale = 0
                }
            }
        }

        // Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            particles = []
        }
    }
}

// MARK: - Inline Checkmark Animation

struct AnimatedCheckmark: View {
    @Binding var isChecked: Bool
    var size: CGFloat = 24
    var color: Color? = nil

    @EnvironmentObject var themeManager: ThemeManager
    @State private var animationProgress: CGFloat = 0

    private var checkmarkColor: Color {
        color ?? themeManager.successColor
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(isChecked ? checkmarkColor : themeManager.textSecondaryColor.opacity(0.3))
                .frame(width: size, height: size)

            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(themeManager.textOnPrimaryColor)
                    .scaleEffect(animationProgress)
            }
        }
        .onChange(of: isChecked) { _, newValue in
            if newValue {
                HapticManager.shared.trigger(.success)
                withAnimation(MZAnimation.bouncy) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 0
            }
        }
        .onTapGesture {
            isChecked.toggle()
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var showCelebration = true
        let themeManager = ThemeManager()

        var body: some View {
            ZStack {
                themeManager.surfaceSecondaryColor.ignoresSafeArea()

                Button("Celebrate!") {
                    showCelebration = true
                }
                .foregroundColor(themeManager.textPrimaryColor)

                TaskCompletionCelebration(isPresented: $showCelebration)
            }
            .environmentObject(themeManager)
        }
    }

    return PreviewWrapper()
}
