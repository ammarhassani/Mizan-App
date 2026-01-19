//
//  EnhancedFAB.swift
//  Mizan
//
//  Enhanced Floating Action Button with glow and bounce effects
//  Supports tap for quick add and long-press for AI Chat
//

import SwiftUI

struct EnhancedFAB: View {
    let action: () -> Void
    var icon: String = "plus"
    var onLongPress: (() -> Void)? = nil

    @State private var isPressed = false
    @State private var showMenu = false
    @EnvironmentObject var themeManager: ThemeManager

    /// Glass style values for glow effects
    private var glassValues: GlassStyleValues {
        themeManager.glassStyle(.standard)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Expanded menu (shown on long press)
            if showMenu {
                expandedMenu
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            // Main FAB button
            mainButton
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showMenu)
    }

    // MARK: - Main Button

    private var mainButton: some View {
        Image(systemName: showMenu ? "xmark" : icon)
            .font(.system(size: 24, weight: .semibold))
            .foregroundColor(themeManager.textOnPrimaryColor)
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(showMenu ? themeManager.textSecondaryColor : themeManager.primaryColor)
                    .shadow(
                        color: themeManager.primaryColor.opacity(glassValues.glowOpacity ?? 0.4),
                        radius: glassValues.glowRadius ?? 12,
                        y: 6
                    )
            )
            .symbolEffect(.bounce, value: isPressed)
            .accessibilityLabel("إضافة مهمة جديدة")
            .accessibilityHint("اضغط لإضافة مهمة جديدة، أو اضغط مطولاً لفتح قائمة الخيارات")
            .onTapGesture {
                if showMenu {
                    showMenu = false
                } else {
                    HapticManager.shared.trigger(.medium)
                    action()
                }
            }
            .onLongPressGesture(minimumDuration: 0.4) {
                if onLongPress != nil {
                    HapticManager.shared.trigger(.heavy)
                    showMenu.toggle()
                }
            }
    }

    // MARK: - Expanded Menu

    private var expandedMenu: some View {
        VStack(spacing: 12) {
            // AI Chat option
            fabMenuItem(
                icon: "sparkles",
                label: "مساعد ذكي",
                color: themeManager.warningColor
            ) {
                showMenu = false
                HapticManager.shared.trigger(.medium)
                onLongPress?()
            }

            // Manual add option
            fabMenuItem(
                icon: "square.and.pencil",
                label: "إضافة يدوية",
                color: themeManager.primaryColor
            ) {
                showMenu = false
                HapticManager.shared.trigger(.medium)
                action()
            }
        }
        .padding(.bottom, 72) // Space for main FAB
    }

    // MARK: - Menu Item

    private func fabMenuItem(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.textPrimaryColor)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.textOnPrimaryColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(color)
                    )
            }
            .padding(.leading, 12)
            .padding(.trailing, 4)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(themeManager.surfaceColor)
                    .shadow(color: themeManager.textPrimaryColor.opacity(0.1), radius: 8, y: 4)
            )
        }
    }
}

#Preview {
    EnhancedFAB {
        // FAB action
    }
    .environmentObject(ThemeManager())
}
