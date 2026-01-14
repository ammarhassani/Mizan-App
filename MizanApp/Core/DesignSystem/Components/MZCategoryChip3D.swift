//
//  MZCategoryChip3D.swift
//  Mizan
//
//  3D depth effect category chips with glow selection
//

import SwiftUI

/// A category chip with 3D depth effects and selection glow
struct MZCategoryChip3D<Category: CategoryRepresentable>: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @State private var isPressed = false

    private var categoryColor: Color {
        Color(hex: category.colorHex)
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: MZSpacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .symbolEffect(.bounce, value: isSelected)

                Text(category.displayName)
                    .font(MZTypography.labelLarge)
            }
            .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : categoryColor)
            .padding(.horizontal, MZSpacing.md)
            .padding(.vertical, MZSpacing.sm)
            .background(chipBackground)
            .clipShape(Capsule())
            .overlay(chipOverlay)
            // 3D shadow effects
            .shadow(
                color: isSelected ? categoryColor.opacity(0.4) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
            .scaleEffect(isPressed ? MZInteraction.pressedScale : (isSelected ? 1.02 : 1.0))
        }
        .buttonStyle(.plain)
        .animation(MZAnimation.bouncy, value: isSelected)
        .animation(MZAnimation.stiff, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Background

    @ViewBuilder
    private var chipBackground: some View {
        if isSelected {
            // Selected: solid category color with inner shadow effect
            ZStack {
                categoryColor

                // Inner shadow (top-left highlight)
                LinearGradient(
                    colors: [
                        themeManager.textOnPrimaryColor.opacity(0.15),
                        Color.clear,
                        Color.black.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            // Unselected: subtle category color tint
            categoryColor.opacity(0.15)
        }
    }

    // MARK: - Overlay

    @ViewBuilder
    private var chipOverlay: some View {
        if isSelected {
            // Outer glow ring
            Capsule()
                .stroke(categoryColor.opacity(0.5), lineWidth: 2)
                .blur(radius: 2)
                .padding(-2)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Category Protocol

/// Protocol for category types to work with MZCategoryChip3D
protocol CategoryRepresentable {
    var icon: String { get }
    var colorHex: String { get }
    var displayName: String { get }
}

// MARK: - TaskCategory Conformance

extension TaskCategory: CategoryRepresentable {
    var colorHex: String {
        self.defaultColorHex
    }

    var displayName: String {
        self.nameArabic
    }
}

// MARK: - UserCategory Conformance

extension UserCategory: CategoryRepresentable {
    // icon, colorHex, and displayName already exist in UserCategory
}

// MARK: - Convenience Initializers for Legacy Support

/// Legacy category chip using TaskCategory enum
struct MZTaskCategoryChip3D: View {
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        MZCategoryChip3D(category: category, isSelected: isSelected, action: action)
            .environmentObject(themeManager)
    }
}

/// User category chip using UserCategory model
struct MZUserCategoryChip3D: View {
    let category: UserCategory
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        MZCategoryChip3D(category: category, isSelected: isSelected, action: action)
            .environmentObject(themeManager)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: MZSpacing.lg) {
        Text("Unselected")
            .font(MZTypography.labelMedium)

        HStack(spacing: MZSpacing.sm) {
            MZTaskCategoryChip3D(category: .work, isSelected: false, action: {})
            MZTaskCategoryChip3D(category: .personal, isSelected: false, action: {})
            MZTaskCategoryChip3D(category: .worship, isSelected: false, action: {})
        }

        Text("Selected")
            .font(MZTypography.labelMedium)

        HStack(spacing: MZSpacing.sm) {
            MZTaskCategoryChip3D(category: .work, isSelected: true, action: {})
            MZTaskCategoryChip3D(category: .personal, isSelected: true, action: {})
            MZTaskCategoryChip3D(category: .worship, isSelected: true, action: {})
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager())
}
