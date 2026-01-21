//
//  MizanLogo.swift
//  Mizan
//
//  The Mizan app logo as a SwiftUI component - scalable and animatable
//

import SwiftUI

/// The Mizan logo rendered as SwiftUI paths
/// Represents a balance scale (mizan) with task bars
struct MizanLogo: View {
    // MARK: - Properties

    /// The size of the logo (width and height)
    let size: CGFloat

    /// Primary color for the pillars and design
    var designColor: Color = .white

    /// Optional secondary color for task bars (defaults to designColor)
    var accentColor: Color?

    /// Whether to animate the logo on appear
    var animated: Bool = false

    /// Glow effect intensity (0 = none, 1 = full)
    var glowIntensity: CGFloat = 0

    // MARK: - State

    @State private var pillarsRevealed = false
    @State private var barsRevealed = false
    @State private var glowPulse: CGFloat = 0

    // MARK: - Computed

    private var taskBarColor: Color {
        accentColor ?? designColor
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Glow effect (optional)
            if glowIntensity > 0 {
                MizanLogoPillarsShape()
                    .fill(designColor.opacity(0.3))
                    .frame(width: size, height: size)
                    .blur(radius: size * 0.1)
                    .scaleEffect(1 + glowPulse * 0.1)
                    .opacity(glowIntensity)
            }

            // Main logo
            Canvas { context, canvasSize in
                let scale = min(canvasSize.width, canvasSize.height) / 1024

                // Draw pillars
                let pillarsPath = createPillarsPath(scale: scale)
                context.fill(pillarsPath, with: .color(designColor))

                // Draw task bars
                let barsPath = createTaskBarsPath(scale: scale)
                context.fill(barsPath, with: .color(taskBarColor))
            }
            .frame(width: size, height: size)
            .scaleEffect(animated ? (pillarsRevealed ? 1 : 0.5) : 1)
            .opacity(animated ? (pillarsRevealed ? 1 : 0) : 1)
        }
        .onAppear {
            if animated {
                startAnimation()
            }
            if glowIntensity > 0 {
                startGlowAnimation()
            }
        }
    }

    // MARK: - Path Creation

    /// Creates the two pillars that form the balance/mizan shape
    private func createPillarsPath(scale: CGFloat) -> Path {
        var path = Path()

        // Left pillar
        path.move(to: CGPoint(x: 280 * scale, y: 760 * scale))
        path.addLine(to: CGPoint(x: 280 * scale, y: 360 * scale))
        path.addQuadCurve(
            to: CGPoint(x: 360 * scale, y: 260 * scale),
            control: CGPoint(x: 280 * scale, y: 280 * scale)
        )
        path.addLine(to: CGPoint(x: 512 * scale, y: 200 * scale))
        path.addLine(to: CGPoint(x: 512 * scale, y: 320 * scale))
        path.addLine(to: CGPoint(x: 400 * scale, y: 360 * scale))
        path.addLine(to: CGPoint(x: 400 * scale, y: 760 * scale))
        path.closeSubpath()

        // Right pillar
        path.move(to: CGPoint(x: 744 * scale, y: 760 * scale))
        path.addLine(to: CGPoint(x: 744 * scale, y: 360 * scale))
        path.addQuadCurve(
            to: CGPoint(x: 664 * scale, y: 260 * scale),
            control: CGPoint(x: 744 * scale, y: 280 * scale)
        )
        path.addLine(to: CGPoint(x: 512 * scale, y: 200 * scale))
        path.addLine(to: CGPoint(x: 512 * scale, y: 320 * scale))
        path.addLine(to: CGPoint(x: 624 * scale, y: 360 * scale))
        path.addLine(to: CGPoint(x: 624 * scale, y: 760 * scale))
        path.closeSubpath()

        return path
    }

    /// Creates the three horizontal task bars
    private func createTaskBarsPath(scale: CGFloat) -> Path {
        var path = Path()

        // Task bar 1
        path.addRoundedRect(
            in: CGRect(x: 440 * scale, y: 450 * scale, width: 144 * scale, height: 40 * scale),
            cornerSize: CGSize(width: 20 * scale, height: 20 * scale)
        )

        // Task bar 2
        path.addRoundedRect(
            in: CGRect(x: 440 * scale, y: 520 * scale, width: 144 * scale, height: 40 * scale),
            cornerSize: CGSize(width: 20 * scale, height: 20 * scale)
        )

        // Task bar 3
        path.addRoundedRect(
            in: CGRect(x: 440 * scale, y: 590 * scale, width: 144 * scale, height: 40 * scale),
            cornerSize: CGSize(width: 20 * scale, height: 20 * scale)
        )

        return path
    }

    // MARK: - Animation

    private func startAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            pillarsRevealed = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
            barsRevealed = true
        }
    }

    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowPulse = 1.0
        }
    }
}

// MARK: - Gradient Version

/// MizanLogo with gradient fill support
struct MizanLogoGradient: View {
    let size: CGFloat
    var designGradient: LinearGradient
    var accentGradient: LinearGradient?
    var animated: Bool = false
    var glowColor: Color?
    var glowIntensity: CGFloat = 0

    @State private var revealed = false
    @State private var glowPulse: CGFloat = 0

    private var taskBarGradient: LinearGradient {
        accentGradient ?? designGradient
    }

    var body: some View {
        ZStack {
            // Glow effect
            if let glow = glowColor, glowIntensity > 0 {
                Canvas { context, canvasSize in
                    let scale = min(canvasSize.width, canvasSize.height) / 1024

                    var pillarsPath = Path()
                    pillarsPath.move(to: CGPoint(x: 280 * scale, y: 760 * scale))
                    pillarsPath.addLine(to: CGPoint(x: 280 * scale, y: 360 * scale))
                    pillarsPath.addQuadCurve(to: CGPoint(x: 360 * scale, y: 260 * scale), control: CGPoint(x: 280 * scale, y: 280 * scale))
                    pillarsPath.addLine(to: CGPoint(x: 512 * scale, y: 200 * scale))
                    pillarsPath.addLine(to: CGPoint(x: 512 * scale, y: 320 * scale))
                    pillarsPath.addLine(to: CGPoint(x: 400 * scale, y: 360 * scale))
                    pillarsPath.addLine(to: CGPoint(x: 400 * scale, y: 760 * scale))
                    pillarsPath.closeSubpath()
                    pillarsPath.move(to: CGPoint(x: 744 * scale, y: 760 * scale))
                    pillarsPath.addLine(to: CGPoint(x: 744 * scale, y: 360 * scale))
                    pillarsPath.addQuadCurve(to: CGPoint(x: 664 * scale, y: 260 * scale), control: CGPoint(x: 744 * scale, y: 280 * scale))
                    pillarsPath.addLine(to: CGPoint(x: 512 * scale, y: 200 * scale))
                    pillarsPath.addLine(to: CGPoint(x: 512 * scale, y: 320 * scale))
                    pillarsPath.addLine(to: CGPoint(x: 624 * scale, y: 360 * scale))
                    pillarsPath.addLine(to: CGPoint(x: 624 * scale, y: 760 * scale))
                    pillarsPath.closeSubpath()

                    context.fill(pillarsPath, with: .color(glow.opacity(0.4)))
                }
                .frame(width: size, height: size)
                .blur(radius: size * 0.08)
                .scaleEffect(1 + glowPulse * 0.15)
                .opacity(glowIntensity)
            }

            // Main logo with gradient
            ZStack {
                // Pillars
                MizanLogoPillarsShape()
                    .fill(designGradient)
                    .frame(width: size, height: size)

                // Task bars
                MizanLogoTaskBarsShape()
                    .fill(taskBarGradient)
                    .frame(width: size, height: size)
            }
            .scaleEffect(animated ? (revealed ? 1 : 0.5) : 1)
            .opacity(animated ? (revealed ? 1 : 0) : 1)
        }
        .onAppear {
            if animated {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                    revealed = true
                }
            }
            if glowIntensity > 0 {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowPulse = 1.0
                }
            }
        }
    }
}

// MARK: - Shape Components (for gradient fills)

/// The pillars shape of the Mizan logo
struct MizanLogoPillarsShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 1024
        var path = Path()

        // Left pillar
        path.move(to: CGPoint(x: 280 * scale, y: 760 * scale))
        path.addLine(to: CGPoint(x: 280 * scale, y: 360 * scale))
        path.addQuadCurve(
            to: CGPoint(x: 360 * scale, y: 260 * scale),
            control: CGPoint(x: 280 * scale, y: 280 * scale)
        )
        path.addLine(to: CGPoint(x: 512 * scale, y: 200 * scale))
        path.addLine(to: CGPoint(x: 512 * scale, y: 320 * scale))
        path.addLine(to: CGPoint(x: 400 * scale, y: 360 * scale))
        path.addLine(to: CGPoint(x: 400 * scale, y: 760 * scale))
        path.closeSubpath()

        // Right pillar
        path.move(to: CGPoint(x: 744 * scale, y: 760 * scale))
        path.addLine(to: CGPoint(x: 744 * scale, y: 360 * scale))
        path.addQuadCurve(
            to: CGPoint(x: 664 * scale, y: 260 * scale),
            control: CGPoint(x: 744 * scale, y: 280 * scale)
        )
        path.addLine(to: CGPoint(x: 512 * scale, y: 200 * scale))
        path.addLine(to: CGPoint(x: 512 * scale, y: 320 * scale))
        path.addLine(to: CGPoint(x: 624 * scale, y: 360 * scale))
        path.addLine(to: CGPoint(x: 624 * scale, y: 760 * scale))
        path.closeSubpath()

        return path
    }
}

/// The task bars shape of the Mizan logo
struct MizanLogoTaskBarsShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 1024
        var path = Path()

        path.addRoundedRect(
            in: CGRect(x: 440 * scale, y: 450 * scale, width: 144 * scale, height: 40 * scale),
            cornerSize: CGSize(width: 20 * scale, height: 20 * scale)
        )
        path.addRoundedRect(
            in: CGRect(x: 440 * scale, y: 520 * scale, width: 144 * scale, height: 40 * scale),
            cornerSize: CGSize(width: 20 * scale, height: 20 * scale)
        )
        path.addRoundedRect(
            in: CGRect(x: 440 * scale, y: 590 * scale, width: 144 * scale, height: 40 * scale),
            cornerSize: CGSize(width: 20 * scale, height: 20 * scale)
        )

        return path
    }
}

// MARK: - Theme-Aware Version

/// MizanLogo that automatically uses theme colors
struct ThemedMizanLogo: View {
    @EnvironmentObject var themeManager: ThemeManager

    let size: CGFloat
    var animated: Bool = false
    var useGlow: Bool = false

    /// Optional override for theme ID (for icon previews)
    var themeOverride: String?

    private var colors: (background: Color, design: Color, accent: Color) {
        if let themeId = themeOverride,
           let themeColors = themeManager.colorsForTheme(themeId) {
            return (background: themeColors.background, design: themeColors.primary, accent: themeColors.accent)
        }
        // Use current theme colors
        return (
            themeManager.backgroundColor,
            themeManager.primaryColor,
            themeManager.warningColor
        )
    }

    var body: some View {
        MizanLogo(
            size: size,
            designColor: colors.design,
            accentColor: colors.accent,
            animated: animated,
            glowIntensity: useGlow ? 0.5 : 0
        )
    }
}

// MARK: - Preview

#Preview("Logo Variants") {
    @Previewable @StateObject var themeManager = ThemeManager()

    VStack(spacing: 40) {
        // Dark Matter - Standard
        MizanLogo(size: 100, designColor: themeManager.primaryColor, accentColor: themeManager.accentMagentaColor)
            .background(themeManager.backgroundColor)
            .cornerRadius(20)

        // Dark Matter - With glow
        MizanLogo(size: 100, designColor: themeManager.primaryColor, glowIntensity: 0.8)
            .background(themeManager.surfaceColor)
            .cornerRadius(20)

        // Dark Matter - Animated
        MizanLogo(size: 100, designColor: themeManager.prayerGoldColor, animated: true)
            .background(themeManager.surfaceSecondaryColor)
            .cornerRadius(20)

        // Dark Matter - Inverted (for light surfaces)
        MizanLogo(size: 100, designColor: themeManager.textOnPrimaryColor, accentColor: themeManager.primaryColor)
            .background(themeManager.primaryColor)
            .cornerRadius(20)
    }
    .padding()
    .background(themeManager.surfaceSecondaryColor.opacity(0.2))
}
