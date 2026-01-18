//
//  GlassmorphicTimeBlock.swift
//  Mizan
//
//  Glass morphism effect wrapper for timeline blocks
//  Uses theme-based glassmorphism values from ThemeManager
//

import SwiftUI

// GlassStyle enum is defined in ThemeManager.swift
// Values are loaded from ThemeConfig.json per theme

/// A container view with glassmorphism effect for timeline blocks
struct GlassmorphicTimeBlock<Content: View>: View {
    let accentColor: Color
    var style: GlassStyle = .standard
    var isElevated: Bool = false
    var isPulsing: Bool = false
    var cornerRadius: CGFloat? = nil
    @ViewBuilder let content: () -> Content

    @EnvironmentObject var themeManager: ThemeManager
    @State private var pulsePhase: CGFloat = 0

    private var effectiveCornerRadius: CGFloat {
        cornerRadius ?? themeManager.cornerRadius(.medium)
    }

    // MARK: - Body

    var body: some View {
        content()
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: effectiveCornerRadius))
            .overlay(glassOverlay)
            .overlay(pulsingGlow)
            .shadow(
                color: accentColor.opacity(glassValues.glowOpacity ?? (isElevated ? 0.3 : 0.1)),
                radius: glassValues.glowRadius ?? (isElevated ? 12 : 4),
                y: isElevated ? 6 : 2
            )
            .onAppear {
                if isPulsing {
                    withAnimation(MZAnimation.prayerBreathing) {
                        pulsePhase = 1.0
                    }
                }
            }
    }

    // MARK: - Glass Background

    private var glassValues: GlassStyleValues {
        themeManager.glassStyle(style)
    }

    private var glassBackground: some View {
        ZStack {
            // Base translucent layer with configurable blur
            themeManager.surfaceColor.opacity(glassValues.backgroundOpacity)
                .blur(radius: glassValues.blurRadius)

            // Top highlight gradient (inner glow effect)
            LinearGradient(
                colors: [
                    themeManager.textOnPrimaryColor.opacity(glassValues.highlightOpacity),
                    themeManager.textOnPrimaryColor.opacity(glassValues.highlightOpacity * 0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )

            // Subtle accent tint
            accentColor.opacity(glassValues.accentTintOpacity)
        }
    }

    // MARK: - Glass Overlay (Border)

    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: effectiveCornerRadius)
            .stroke(
                LinearGradient(
                    colors: [
                        accentColor.opacity(glassValues.borderOpacity.leading),
                        accentColor.opacity(glassValues.borderOpacity.trailing)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: style == .prayer ? 1.5 : 1
            )
    }

    // MARK: - Pulsing Glow (for current prayer)

    @ViewBuilder
    private var pulsingGlow: some View {
        if isPulsing {
            // REMOVED scaleEffect to prevent layout shifts
            // Just opacity animation for glow effect
            RoundedRectangle(cornerRadius: effectiveCornerRadius)
                .stroke(accentColor.opacity(0.4 + pulsePhase * 0.4), lineWidth: 2)
                .blur(radius: 4)
        }
    }
}

// MARK: - View Modifier

/// Modifier to apply glassmorphism effect to any view
struct GlassmorphicModifier: ViewModifier {
    let accentColor: Color
    var style: GlassStyle = .standard
    var isElevated: Bool = false
    var cornerRadius: CGFloat = 12

    @EnvironmentObject var themeManager: ThemeManager

    private var glassValues: GlassStyleValues {
        themeManager.glassStyle(style)
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    themeManager.surfaceColor.opacity(glassValues.backgroundOpacity)
                        .blur(radius: glassValues.blurRadius)

                    LinearGradient(
                        colors: [
                            themeManager.textOnPrimaryColor.opacity(glassValues.highlightOpacity),
                            themeManager.textOnPrimaryColor.opacity(glassValues.highlightOpacity * 0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )

                    accentColor.opacity(glassValues.accentTintOpacity)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(glassValues.borderOpacity.leading),
                                accentColor.opacity(glassValues.borderOpacity.trailing)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: style == .prayer ? 1.5 : 1
                    )
            )
            .shadow(
                color: accentColor.opacity(glassValues.glowOpacity ?? (isElevated ? 0.3 : 0.1)),
                radius: glassValues.glowRadius ?? (isElevated ? 12 : 4),
                y: isElevated ? 6 : 2
            )
    }
}

extension View {
    /// Applies glassmorphism effect to the view
    func glassmorphic(
        accentColor: Color,
        style: GlassStyle = .standard,
        isElevated: Bool = false,
        cornerRadius: CGFloat = 12
    ) -> some View {
        modifier(GlassmorphicModifier(
            accentColor: accentColor,
            style: style,
            isElevated: isElevated,
            cornerRadius: cornerRadius
        ))
    }
}

// MARK: - Enhanced Task Block with Glass Effect

/// An enhanced task block that uses glassmorphism
struct GlassmorphicTaskBlock: View {
    let task: Task
    var onToggleCompletion: (() -> Void)?

    @EnvironmentObject var themeManager: ThemeManager
    @State private var checkmarkScale: CGFloat = 1.0
    @State private var borderGlow: CGFloat = 0

    private var taskColor: Color {
        Color(hex: task.colorHex)
    }

    private var blockHeight: CGFloat {
        let contentHeight = CGFloat(task.duration) / 60.0 * MZInteraction.baseHourHeight
        return max(50, contentHeight)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Time label
            Text(task.startTime.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(taskColor)
                .frame(width: 65, alignment: .trailing)

            // Task content with glass effect
            GlassmorphicTimeBlock(accentColor: taskColor) {
                HStack(spacing: 10) {
                    // Completion checkbox
                    Button {
                        toggleCompletion()
                    } label: {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(task.isCompleted ? themeManager.successColor : taskColor)
                            .scaleEffect(checkmarkScale)
                    }
                    .buttonStyle(.plain)

                    // Task details
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.textPrimaryColor)
                            .strikethrough(task.isCompleted)

                        Text(task.duration.formattedDuration)
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.textSecondaryColor)
                    }

                    Spacer()

                    // Task icon
                    Image(systemName: task.icon)
                        .font(.system(size: 14))
                        .foregroundColor(taskColor.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .overlay(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                    .stroke(themeManager.successColor.opacity(borderGlow), lineWidth: 2)
            )
        }
        .frame(height: blockHeight)
        .padding(.horizontal, 4)
        .opacity(task.isCompleted ? 0.7 : 1.0)
    }

    // MARK: - Completion Animation

    private func toggleCompletion() {
        // Animate checkmark
        withAnimation(MZAnimation.bouncy) {
            checkmarkScale = 0.5
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(MZAnimation.bouncy) {
                checkmarkScale = 1.2
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(MZAnimation.bouncy) {
                checkmarkScale = 1.0
            }
        }

        // Brief glow pulse on completion
        if !task.isCompleted {
            withAnimation(.easeOut(duration: 0.3)) {
                borderGlow = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    borderGlow = 0
                }
            }
        }

        HapticManager.shared.trigger(.success)
        onToggleCompletion?()
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: MZSpacing.lg) {
        Text("Glassmorphic Blocks")
            .font(MZTypography.titleSmall)

        GlassmorphicTimeBlock(accentColor: ThemeManager().primaryColor) {
            HStack {
                Image(systemName: "briefcase.fill")
                Text("Sample Task Block")
                Spacer()
            }
            .padding()
        }

        GlassmorphicTimeBlock(accentColor: ThemeManager().categoryColor(.worship), isElevated: true) {
            HStack {
                Image(systemName: "moon.stars.fill")
                Text("Elevated Block")
                Spacer()
            }
            .padding()
        }

        Text("Using Modifier")
            .font(MZTypography.titleSmall)

        HStack {
            Image(systemName: "heart.fill")
            Text("Health Task")
            Spacer()
        }
        .padding()
        .glassmorphic(accentColor: ThemeManager().errorColor)
    }
    .padding()
    .background(ThemeManager().surfaceSecondaryColor.opacity(0.2))
    .environmentObject(ThemeManager())
}
