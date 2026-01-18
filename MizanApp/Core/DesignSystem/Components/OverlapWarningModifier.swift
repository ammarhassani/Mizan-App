//
//  OverlapWarningModifier.swift
//  Mizan
//
//  Visual warning modifier for overlapping tasks.
//  Shows warning border, background tint, badge, and pulsing glow.
//

import SwiftUI

/// Visual warning modifier for overlapping tasks
struct OverlapWarningModifier: ViewModifier {
    let hasOverlap: Bool
    let overlapCount: Int
    @EnvironmentObject var themeManager: ThemeManager

    @State private var pulsePhase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            // Warning border
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        hasOverlap ? themeManager.warningColor : Color.clear,
                        lineWidth: hasOverlap ? 2 : 0
                    )
            )
            // Subtle warning background tint
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(hasOverlap
                        ? themeManager.warningColor.opacity(0.08)
                        : Color.clear)
            )
            // Warning badge overlay
            .overlay(alignment: .topLeading) {
                if hasOverlap {
                    warningBadge
                        .offset(x: -6, y: -6)
                }
            }
            // Pulsing glow effect
            .shadow(
                color: hasOverlap
                    ? themeManager.warningColor.opacity(0.3 + pulsePhase * 0.2)
                    : Color.clear,
                radius: hasOverlap ? 8 : 0
            )
            .onAppear {
                if hasOverlap {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulsePhase = 1.0
                    }
                }
            }
    }

    private var warningBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10, weight: .bold))

            if overlapCount > 1 {
                Text("×\(overlapCount)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
            }
        }
        .foregroundColor(themeManager.textOnPrimaryColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(themeManager.warningColor)
                .shadow(color: themeManager.warningColor.opacity(0.4), radius: 4, y: 2)
        )
    }
}

// MARK: - View Extension

extension View {
    /// Apply visual warning effect for overlapping tasks
    /// - Parameters:
    ///   - hasOverlap: Whether this task overlaps with others
    ///   - overlapCount: Number of overlapping tasks (for badge display)
    func overlapWarning(hasOverlap: Bool, overlapCount: Int = 1) -> some View {
        self.modifier(OverlapWarningModifier(
            hasOverlap: hasOverlap,
            overlapCount: overlapCount
        ))
    }
}

// MARK: - Preview

#Preview {
    let themeManager = ThemeManager()
    VStack(spacing: 20) {
        // Normal card
        RoundedRectangle(cornerRadius: 14)
            .fill(themeManager.surfaceSecondaryColor.opacity(0.3))
            .frame(height: 80)
            .overlay(Text("Normal Task").foregroundColor(themeManager.textPrimaryColor))
            .overlapWarning(hasOverlap: false)

        // Overlapping card (single)
        RoundedRectangle(cornerRadius: 14)
            .fill(themeManager.surfaceSecondaryColor.opacity(0.3))
            .frame(height: 80)
            .overlay(Text("Overlapping Task").foregroundColor(themeManager.textPrimaryColor))
            .overlapWarning(hasOverlap: true, overlapCount: 1)

        // Overlapping card (multiple)
        RoundedRectangle(cornerRadius: 14)
            .fill(themeManager.surfaceSecondaryColor.opacity(0.3))
            .frame(height: 80)
            .overlay(Text("Multiple Overlaps").foregroundColor(themeManager.textPrimaryColor))
            .overlapWarning(hasOverlap: true, overlapCount: 3)
    }
    .padding(30)
    .background(themeManager.overlayColor.opacity(0.05))
    .environmentObject(themeManager)
}
