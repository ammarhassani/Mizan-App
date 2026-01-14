//
//  GlassmorphicTimeBlock.swift
//  Mizan
//
//  Glass morphism effect wrapper for timeline blocks
//

import SwiftUI

/// A container view with glassmorphism effect for timeline blocks
struct GlassmorphicTimeBlock<Content: View>: View {
    let accentColor: Color
    var isElevated: Bool = false
    @ViewBuilder let content: () -> Content

    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Body

    var body: some View {
        content()
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium)))
            .overlay(glassOverlay)
            .shadow(
                color: isElevated ? accentColor.opacity(0.3) : accentColor.opacity(0.1),
                radius: isElevated ? 12 : 4,
                y: isElevated ? 6 : 2
            )
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        ZStack {
            // Base translucent layer
            themeManager.surfaceColor.opacity(0.7)
                .blur(radius: 0.5)

            // Top highlight gradient
            LinearGradient(
                colors: [
                    themeManager.textOnPrimaryColor.opacity(0.08),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )

            // Subtle accent tint
            accentColor.opacity(0.05)
        }
    }

    // MARK: - Glass Overlay

    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
            .stroke(
                LinearGradient(
                    colors: [
                        accentColor.opacity(0.4),
                        accentColor.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - View Modifier

/// Modifier to apply glassmorphism effect to any view
struct GlassmorphicModifier: ViewModifier {
    let accentColor: Color
    var isElevated: Bool = false

    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    themeManager.surfaceColor.opacity(0.7)
                        .blur(radius: 0.5)

                    LinearGradient(
                        colors: [
                            themeManager.textOnPrimaryColor.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )

                    accentColor.opacity(0.05)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.4),
                                accentColor.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isElevated ? accentColor.opacity(0.3) : accentColor.opacity(0.1),
                radius: isElevated ? 12 : 4,
                y: isElevated ? 6 : 2
            )
    }
}

extension View {
    /// Applies glassmorphism effect to the view
    func glassmorphic(accentColor: Color, isElevated: Bool = false) -> some View {
        modifier(GlassmorphicModifier(accentColor: accentColor, isElevated: isElevated))
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

                        Text("\(task.duration) دقيقة")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.textSecondaryColor)
                    }

                    Spacer()

                    // Category icon
                    Image(systemName: task.category.icon)
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

        GlassmorphicTimeBlock(accentColor: .blue) {
            HStack {
                Image(systemName: "briefcase.fill")
                Text("Sample Task Block")
                Spacer()
            }
            .padding()
        }

        GlassmorphicTimeBlock(accentColor: .purple, isElevated: true) {
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
        .glassmorphic(accentColor: .red)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
    .environmentObject(ThemeManager())
}
