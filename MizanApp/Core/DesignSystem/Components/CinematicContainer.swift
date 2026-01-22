//
//  CinematicContainer.swift
//  MizanApp
//
//  Reusable glass shard card component with frosted glass effect,
//  animated cyan border glow, and grain texture for the Dark Matter theme.
//

import SwiftUI

// MARK: - CinematicContainer

/// A reusable glass card component with frosted glass effect,
/// animated border glow, and grain texture overlay.
///
/// Uses the existing `GlassStyle` enum from DarkMatterTheme.swift:
/// - `.standard`: 6% white opacity, cyan border
/// - `.frosted`: 8% opacity, stronger glow (elevated style)
/// - `.subtle`: 4% opacity, no border animation
/// - `.prayer`: 6% opacity, gold-tinted border
struct CinematicContainer<Content: View>: View {
    // MARK: - Properties

    /// The glass style variant
    let style: GlassStyle

    /// Corner radius of the container
    let cornerRadius: CGFloat

    /// Whether to animate the border glow
    let animateBorder: Bool

    /// The content to display inside the container
    @ViewBuilder let content: () -> Content

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var borderGlow: Double = 0.4

    // MARK: - Initializer

    init(
        style: GlassStyle = .standard,
        cornerRadius: CGFloat = 16,
        animateBorder: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.animateBorder = animateBorder
        self.content = content
    }

    // MARK: - Computed Properties

    /// Glass opacity based on style
    private var glassOpacity: Double {
        switch style {
        case .standard, .prayer:
            return 0.06
        case .frosted:
            return 0.08
        case .subtle:
            return 0.04
        }
    }

    /// Border color based on style
    private var borderColor: Color {
        switch style {
        case .standard, .frosted, .subtle:
            return CinematicColors.glassBorder
        case .prayer:
            return CinematicColors.prayerGold
        }
    }

    /// Shadow color based on style
    private var shadowColor: Color {
        switch style {
        case .standard, .frosted, .subtle:
            return CinematicColors.accentCyan
        case .prayer:
            return CinematicColors.prayerGold
        }
    }

    /// Shadow radius based on style
    private var shadowRadius: CGFloat {
        switch style {
        case .frosted:
            return 12
        case .standard, .prayer:
            return 8
        case .subtle:
            return 4
        }
    }

    /// Whether border animation should be active
    private var shouldAnimateBorder: Bool {
        animateBorder && style != .subtle
    }

    // MARK: - Body

    var body: some View {
        content()
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(borderOverlay)
            .shadow(
                color: shadowColor.opacity(0.15),
                radius: shadowRadius,
                x: 0,
                y: 4
            )
            .onAppear {
                if shouldAnimateBorder {
                    startBorderAnimation()
                }
            }
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        ZStack {
            // Base glass layer
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(CinematicColors.glass.opacity(glassOpacity))

            // Grain texture overlay
            GrainTextureView()
                .opacity(0.03)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .drawingGroup() // Rasterize to avoid per-frame pixel rendering
        }
    }

    // MARK: - Border Overlay

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                borderColor.opacity(shouldAnimateBorder ? borderGlow : 0.5),
                lineWidth: 1
            )
    }

    // MARK: - Animation

    private func startBorderAnimation() {
        // Skip animation for reduced motion
        guard !reduceMotion else { return }

        withAnimation(CinematicAnimation.pulse) {
            borderGlow = 0.6
        }
    }
}

// MARK: - GrainTextureView

/// Helper view that renders a subtle noise texture using Canvas
struct GrainTextureView: View {
    var body: some View {
        Canvas { context, size in
            // Create a noise pattern
            let columns = Int(size.width / 2)
            let rows = Int(size.height / 2)

            for row in 0..<rows {
                for column in 0..<columns {
                    // Generate pseudo-random value based on position
                    let seed = row * columns + column
                    let random = pseudoRandom(seed: seed)

                    if random > 0.5 {
                        let x = CGFloat(column) * 2
                        let y = CGFloat(row) * 2
                        let rect = CGRect(x: x, y: y, width: 2, height: 2)

                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(CinematicColors.textPrimary.opacity(random * 0.3))
                        )
                    }
                }
            }
        }
    }

    /// Simple pseudo-random number generator based on seed
    private func pseudoRandom(seed: Int) -> Double {
        let x = sin(Double(seed) * 12.9898 + 78.233) * 43758.5453
        return x - floor(x)
    }
}

// MARK: - View Modifier

/// View modifier for applying cinematic card styling
struct CinematicCardModifier: ViewModifier {
    let style: GlassStyle
    let cornerRadius: CGFloat
    let animateBorder: Bool

    func body(content: Content) -> some View {
        CinematicContainer(
            style: style,
            cornerRadius: cornerRadius,
            animateBorder: animateBorder
        ) {
            content
        }
    }
}

extension View {
    /// Applies the cinematic glass card styling to a view.
    /// - Parameters:
    ///   - style: The glass style variant (default: .standard)
    ///   - cornerRadius: Corner radius of the card (default: 16)
    ///   - animateBorder: Whether to animate the border glow (default: true)
    /// - Returns: A view wrapped in a cinematic glass container
    func cinematicCard(
        style: GlassStyle = .standard,
        cornerRadius: CGFloat = 16,
        animateBorder: Bool = true
    ) -> some View {
        modifier(CinematicCardModifier(
            style: style,
            cornerRadius: cornerRadius,
            animateBorder: animateBorder
        ))
    }
}

// MARK: - Preview

#if DEBUG
struct CinematicContainer_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Void black background
            CinematicColors.voidBlack
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Standard style
                    CinematicContainer(style: .standard) {
                        previewContent(title: "Standard", subtitle: "6% opacity, cyan border")
                    }

                    // Frosted style (elevated)
                    CinematicContainer(style: .frosted) {
                        previewContent(title: "Frosted", subtitle: "8% opacity, stronger glow")
                    }

                    // Subtle style
                    CinematicContainer(style: .subtle) {
                        previewContent(title: "Subtle", subtitle: "4% opacity, no animation")
                    }

                    // Prayer style
                    CinematicContainer(style: .prayer) {
                        previewContent(title: "Prayer", subtitle: "6% opacity, gold border")
                    }

                    // Using view modifier
                    previewContent(title: "View Modifier", subtitle: "Using .cinematicCard()")
                        .cinematicCard(style: .standard)
                }
                .padding(16)
            }
        }
        .previewDisplayName("All Styles")
    }

    @ViewBuilder
    static func previewContent(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(CinematicColors.textPrimary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(CinematicColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
}
#endif
