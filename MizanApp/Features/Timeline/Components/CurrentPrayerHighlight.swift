//
//  CurrentPrayerHighlight.swift
//  Mizan
//
//  Performance-optimized highlighting wrapper for the currently active prayer.
//  REMOVED: Duplicate badge (card already has one), scale animations that cause layout shifts.
//

import SwiftUI

/// Lightweight highlighting wrapper for the current prayer - static glow only
struct CurrentPrayerHighlight<Content: View>: View {
    let prayerColor: Color
    @ViewBuilder let content: () -> Content

    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Body

    var body: some View {
        content()
            .background(staticGlowBackground)
    }

    // MARK: - Static Glow Background (NO animation)

    private var staticGlowBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(prayerColor.opacity(0.25))
            .blur(radius: 20)
            .padding(-8)
    }
}

// MARK: - Minimal Highlight Modifier

/// A lighter-weight current prayer indicator for compact views
struct CurrentPrayerIndicatorModifier: ViewModifier {
    let prayerColor: Color
    let isActive: Bool

    @EnvironmentObject var themeManager: ThemeManager
    @State private var glowIntensity: Double = 0.3

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isActive {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(prayerColor.opacity(glowIntensity), lineWidth: 2)
                            .blur(radius: 3)
                    }
                }
            )
            .onAppear {
                if isActive {
                    withAnimation(MZAnimation.prayerBreathing) {
                        glowIntensity = 0.6
                    }
                }
            }
    }
}

extension View {
    /// Applies current prayer highlight effect
    func currentPrayerHighlight(color: Color, isActive: Bool) -> some View {
        modifier(CurrentPrayerIndicatorModifier(prayerColor: color, isActive: isActive))
    }
}

// MARK: - Preview

#Preview {
    let themeManager = ThemeManager()
    return VStack(spacing: 24) {
        Text("Current Prayer Highlight")
            .font(.headline)
            .foregroundColor(themeManager.textPrimaryColor)

        CurrentPrayerHighlight(prayerColor: themeManager.primaryColor) {
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.primaryColor.opacity(0.2))
                .frame(height: 150)
                .overlay(
                    Text("Fajr Prayer Card")
                        .foregroundColor(themeManager.textOnPrimaryColor)
                )
        }
        .padding(.horizontal)

        Divider()

        Text("Modifier Version")
            .font(.headline)
            .foregroundColor(themeManager.textPrimaryColor)

        RoundedRectangle(cornerRadius: 16)
            .fill(themeManager.warningColor.opacity(0.2))
            .frame(height: 100)
            .overlay(Text("Dhuhr Card").foregroundColor(themeManager.textOnPrimaryColor))
            .currentPrayerHighlight(color: themeManager.warningColor, isActive: true)
            .padding(.horizontal)
    }
    .padding()
    .background(themeManager.backgroundColor)
    .environmentObject(themeManager)
}
