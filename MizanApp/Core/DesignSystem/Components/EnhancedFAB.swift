//
//  EnhancedFAB.swift
//  Mizan
//
//  Enhanced Floating Action Button with glow and bounce effects
//

import SwiftUI

struct EnhancedFAB: View {
    let action: () -> Void
    var icon: String = "plus"

    @State private var isPressed = false
    @EnvironmentObject var themeManager: ThemeManager

    /// Glass style values for glow effects
    private var glassValues: GlassStyleValues {
        themeManager.glassStyle(.standard)
    }

    var body: some View {
        Button {
            HapticManager.shared.trigger(.medium)
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(themeManager.textOnPrimaryColor)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(themeManager.primaryColor)
                        .shadow(
                            color: themeManager.primaryColor.opacity(glassValues.glowOpacity ?? 0.4),
                            radius: glassValues.glowRadius ?? 12,
                            y: 6
                        )
                )
                .symbolEffect(.bounce, value: isPressed)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("إضافة مهمة جديدة")
        .accessibilityHint("اضغط لإضافة مهمة جديدة")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    EnhancedFAB {
        print("FAB tapped")
    }
    .environmentObject(ThemeManager())
}
