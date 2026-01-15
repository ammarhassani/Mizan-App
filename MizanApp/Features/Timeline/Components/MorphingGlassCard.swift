//
//  MorphingGlassCard.swift
//  Mizan
//
//  Cards that flow and morph like liquid mercury.
//  Every surface breathes with divine luminescence.
//

import SwiftUI

// MARK: - Morphing Glass Card

struct MorphingGlassCard<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager

    let content: Content

    var accentColor: Color?
    var isPressed: Bool = false
    var isHighlighted: Bool = false
    var showEdgeGlow: Bool = true
    var breathingIntensity: Double = 1.0
    var cornerRadius: CGFloat = 20

    @State private var phase: Double = 0
    @State private var ripplePoint: CGPoint?
    @State private var showRipple: Bool = false

    init(
        accentColor: Color? = nil,
        isPressed: Bool = false,
        isHighlighted: Bool = false,
        showEdgeGlow: Bool = true,
        breathingIntensity: Double = 1.0,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.accentColor = accentColor
        self.isPressed = isPressed
        self.isHighlighted = isHighlighted
        self.showEdgeGlow = showEdgeGlow
        self.breathingIntensity = breathingIntensity
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    private var effectiveAccent: Color {
        accentColor ?? themeManager.primaryColor
    }

    private var breathingRadius: CGFloat {
        let baseRadius = cornerRadius
        let breathe = sin(phase * 2) * 2 * breathingIntensity
        return baseRadius + breathe
    }

    var body: some View {
        ZStack {
            // Layer 1: Shadow/Glow base
            if isHighlighted {
                highlightGlow
            }

            // Layer 2: Glass background
            glassBackground

            // Layer 3: Edge aurora
            if showEdgeGlow {
                edgeAurora
            }

            // Layer 4: Surface ripple
            if showRipple, let point = ripplePoint {
                surfaceRipple(at: point)
            }

            // Layer 5: Content
            content
                .padding(MZSpacing.md)
        }
        .clipShape(RoundedRectangle(cornerRadius: breathingRadius, style: .continuous))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(MZAnimation.snappy, value: isPressed)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        ZStack {
            // Base glass
            RoundedRectangle(cornerRadius: breathingRadius, style: .continuous)
                .fill(themeManager.surfaceColor.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: breathingRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                )

            // Inner highlight (top edge glow)
            RoundedRectangle(cornerRadius: breathingRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.textOnPrimaryColor.opacity(0.15),
                            themeManager.textOnPrimaryColor.opacity(0.05),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            // Accent tint
            RoundedRectangle(cornerRadius: breathingRadius, style: .continuous)
                .fill(effectiveAccent.opacity(0.05))

            // Border
            RoundedRectangle(cornerRadius: breathingRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            themeManager.textOnPrimaryColor.opacity(0.2),
                            themeManager.textOnPrimaryColor.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Highlight Glow

    private var highlightGlow: some View {
        RoundedRectangle(cornerRadius: breathingRadius + 4, style: .continuous)
            .fill(effectiveAccent.opacity(0.3))
            .blur(radius: 12)
            .scaleEffect(1 + sin(phase * 3) * 0.02)
    }

    // MARK: - Edge Aurora

    private var edgeAurora: some View {
        GeometryReader { geometry in
            let size = geometry.size

            Canvas { context, canvasSize in
                // Flowing edge glow
                let path = RoundedRectangle(cornerRadius: breathingRadius, style: .continuous)
                    .path(in: CGRect(origin: .zero, size: canvasSize))

                // Create shimmering effect along the edge
                let shimmerPosition = (phase.truncatingRemainder(dividingBy: 1)) * 2

                // Top edge shimmer
                let shimmerGradient = Gradient(colors: [
                    .clear,
                    effectiveAccent.opacity(0.4 * breathingIntensity),
                    themeManager.textOnPrimaryColor.opacity(0.3 * breathingIntensity),
                    effectiveAccent.opacity(0.4 * breathingIntensity),
                    .clear
                ])

                let shimmerStart = CGPoint(
                    x: size.width * (shimmerPosition - 0.3),
                    y: 0
                )
                let shimmerEnd = CGPoint(
                    x: size.width * shimmerPosition,
                    y: 0
                )

                context.stroke(
                    path,
                    with: .linearGradient(
                        shimmerGradient,
                        startPoint: shimmerStart,
                        endPoint: shimmerEnd
                    ),
                    lineWidth: 2
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Surface Ripple

    @ViewBuilder
    private func surfaceRipple(at point: CGPoint) -> some View {
        GeometryReader { geometry in
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            effectiveAccent.opacity(0.3),
                            effectiveAccent.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .position(point)
                .blur(radius: 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: breathingRadius, style: .continuous))
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            phase = .pi * 2
        }
    }

    // MARK: - Public Methods

    func triggerRipple(at point: CGPoint) {
        ripplePoint = point
        showRipple = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                showRipple = false
            }
        }
    }
}

// MARK: - Morphing Card Style

enum MorphingCardStyle {
    case standard       // Normal glass card
    case elevated       // More prominent shadow/glow
    case prayer         // Prayer-specific styling
    case task           // Task-specific styling
    case divine         // Maximum visual impact

    var breathingIntensity: Double {
        switch self {
        case .standard: return 0.5
        case .elevated: return 0.7
        case .prayer: return 1.0
        case .task: return 0.6
        case .divine: return 1.2
        }
    }

    var showEdgeGlow: Bool {
        switch self {
        case .standard: return false
        case .elevated, .prayer, .task, .divine: return true
        }
    }
}

// MARK: - Convenience Initializer

extension MorphingGlassCard {
    init(
        style: MorphingCardStyle,
        accentColor: Color? = nil,
        isPressed: Bool = false,
        isHighlighted: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            accentColor: accentColor,
            isPressed: isPressed,
            isHighlighted: isHighlighted,
            showEdgeGlow: style.showEdgeGlow,
            breathingIntensity: style.breathingIntensity,
            content: content
        )
    }
}

// MARK: - View Modifier

struct MorphingGlassModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    var style: MorphingCardStyle
    var accentColor: Color?
    var isPressed: Bool
    var isHighlighted: Bool

    func body(content: Content) -> some View {
        MorphingGlassCard(
            style: style,
            accentColor: accentColor,
            isPressed: isPressed,
            isHighlighted: isHighlighted
        ) {
            content
        }
        .environmentObject(themeManager)
    }
}

extension View {
    func morphingGlass(
        style: MorphingCardStyle = .standard,
        accentColor: Color? = nil,
        isPressed: Bool = false,
        isHighlighted: Bool = false
    ) -> some View {
        modifier(MorphingGlassModifier(
            style: style,
            accentColor: accentColor,
            isPressed: isPressed,
            isHighlighted: isHighlighted
        ))
    }
}

// MARK: - Interactive Morphing Card

struct InteractiveMorphingCard<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager

    let content: Content
    var style: MorphingCardStyle = .standard
    var accentColor: Color?
    var onTap: (() -> Void)?

    @State private var isPressed = false

    init(
        style: MorphingCardStyle = .standard,
        accentColor: Color? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.accentColor = accentColor
        self.onTap = onTap
        self.content = content()
    }

    var body: some View {
        MorphingGlassCard(
            style: style,
            accentColor: accentColor,
            isPressed: isPressed
        ) {
            content
        }
        .onTapGesture {
            // Visual feedback
            withAnimation(MZAnimation.snappy) {
                isPressed = true
            }

            HapticManager.shared.trigger(.light)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(MZAnimation.snappy) {
                    isPressed = false
                }
                onTap?()
            }
        }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(MZAnimation.snappy) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    let themeManager = ThemeManager()
    return ScrollView {
        VStack(spacing: 24) {
            // Standard Card
            MorphingGlassCard(style: .standard) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Standard Card")
                        .font(MZTypography.titleMedium)
                        .foregroundColor(themeManager.textPrimaryColor)

                    Text("Subtle breathing effect")
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }
            .frame(width: 300, height: 120)

            // Divine Card
            MorphingGlassCard(
                style: .divine,
                accentColor: themeManager.successColor,
                isHighlighted: true
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .font(.title2)

                        Text("صلاة العشاء")
                            .font(MZTypography.titleLarge)
                    }
                    .foregroundColor(themeManager.textPrimaryColor)

                    Text("الصلاة الحالية")
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }
            .frame(width: 300, height: 140)

            // Interactive Card
            InteractiveMorphingCard(
                style: .elevated,
                onTap: { print("Tapped!") }
            ) {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)

                    VStack(alignment: .leading) {
                        Text("Complete Task")
                            .font(MZTypography.titleSmall)

                        Text("Tap to interact")
                            .font(MZTypography.labelSmall)
                            .opacity(0.7)
                    }

                    Spacer()
                }
                .foregroundColor(themeManager.textPrimaryColor)
            }
            .frame(width: 300, height: 80)
        }
        .padding()
    }
    .background(themeManager.backgroundColor)
    .environmentObject(themeManager)
}
