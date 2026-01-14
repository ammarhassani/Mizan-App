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

    var body: some View {
        Button {
            HapticManager.shared.trigger(.medium)
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(themeManager.primaryColor)
                        .shadow(
                            color: themeManager.primaryColor.opacity(0.4),
                            radius: 12,
                            y: 6
                        )
                )
                .symbolEffect(.bounce, value: isPressed)
        }
        .buttonStyle(BouncyButtonStyle())
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
