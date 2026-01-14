//
//  MZFloatingTextField.swift
//  Mizan
//
//  Organic floating label text field with micro-interactions
//

import SwiftUI

/// A text field with an elegant floating label animation
struct MZFloatingTextField: View {
    @Binding var text: String
    let placeholder: String
    var icon: String? = nil

    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var isFocused: Bool

    // MARK: - Computed Properties

    private var isFloating: Bool {
        isFocused || !text.isEmpty
    }

    private var borderColor: Color {
        if isFocused {
            return themeManager.primaryColor
        }
        return themeManager.surfaceSecondaryColor
    }

    private var borderWidth: CGFloat {
        isFocused ? MZInteraction.focusBorderWidth : MZInteraction.defaultBorderWidth
    }

    private var labelColor: Color {
        if isFocused {
            return themeManager.primaryColor
        }
        return themeManager.textSecondaryColor
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .fill(themeManager.surfaceSecondaryColor)

            // Border with glow
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .stroke(borderColor, lineWidth: borderWidth)
                .shadow(
                    color: isFocused ? themeManager.primaryColor.opacity(MZInteraction.glowOpacity) : .clear,
                    radius: isFocused ? MZInteraction.glowRadius : 0
                )

            // Content
            HStack(spacing: MZSpacing.sm) {
                // Optional icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isFocused ? themeManager.primaryColor : themeManager.textSecondaryColor)
                        .animation(MZAnimation.focusBorder, value: isFocused)
                }

                // Text field with floating label
                ZStack(alignment: .leading) {
                    // Floating label
                    Text(placeholder)
                        .font(isFloating ? MZTypography.labelMedium : MZTypography.bodyLarge)
                        .foregroundColor(labelColor.opacity(isFloating ? 1.0 : 0.6))
                        .offset(y: isFloating ? MZInteraction.floatingLabelOffset : 0)
                        .scaleEffect(isFloating ? MZInteraction.floatingLabelScale : 1.0, anchor: .leading)
                        .animation(MZAnimation.floatingLabel, value: isFloating)

                    // Text field
                    TextField("", text: $text)
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(themeManager.textPrimaryColor)
                        .focused($isFocused)
                        .offset(y: 4) // Slight offset to make room for floated label
                }
            }
            .padding(.horizontal, MZSpacing.md)
            .padding(.vertical, MZSpacing.md + 4) // Extra vertical for floating label space
        }
        .frame(height: 64) // Fixed height for consistency
        .animation(MZAnimation.focusBorder, value: isFocused)
        .onTapGesture {
            isFocused = true
        }
    }
}

// MARK: - Convenience Initializers

extension MZFloatingTextField {
    /// Creates a floating text field without an icon
    init(text: Binding<String>, placeholder: String) {
        self._text = text
        self.placeholder = placeholder
        self.icon = nil
    }

    /// Creates a floating text field with an icon
    init(text: Binding<String>, placeholder: String, icon: String) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: MZSpacing.lg) {
        MZFloatingTextField(text: .constant(""), placeholder: "العنوان")
        MZFloatingTextField(text: .constant("مراجعة المشروع"), placeholder: "العنوان")
        MZFloatingTextField(text: .constant(""), placeholder: "العنوان", icon: "pencil")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager())
}
