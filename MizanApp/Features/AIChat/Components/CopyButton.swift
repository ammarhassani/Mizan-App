//
//  CopyButton.swift
//  Mizan
//
//  Animated copy button with success feedback
//

import SwiftUI

/// Animated copy button with checkmark confirmation
struct CopyButton: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// The text to copy
    let textToCopy: String

    /// Button size
    var size: CGFloat = 20

    /// Whether to show label text
    var showLabel: Bool = false

    // MARK: - State

    @State private var copied = false

    var body: some View {
        Button {
            copyToClipboard()
        } label: {
            HStack(spacing: MZSpacing.xxs) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: size * 0.7))
                    .foregroundColor(copied ? themeManager.successColor : themeManager.textSecondaryColor)
                    .scaleEffect(copied ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: copied)

                if showLabel {
                    Text(copied ? "تم النسخ" : "نسخ")
                        .font(MZTypography.labelSmall)
                        .foregroundColor(copied ? themeManager.successColor : themeManager.textSecondaryColor)
                }
            }
            .padding(.horizontal, showLabel ? MZSpacing.xs : MZSpacing.xxs)
            .padding(.vertical, MZSpacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.small))
                    .fill(themeManager.surfaceSecondaryColor.opacity(copied ? 0.8 : 0.5))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func copyToClipboard() {
        UIPasteboard.general.string = textToCopy
        HapticManager.shared.trigger(.light)

        withAnimation {
            copied = true
        }

        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                copied = false
            }
        }
    }
}

// MARK: - Compact Variant

/// Minimal copy button for inline use (code blocks, etc.)
struct CopyButtonCompact: View {
    @EnvironmentObject var themeManager: ThemeManager

    let textToCopy: String

    @State private var copied = false

    var body: some View {
        Button {
            copyToClipboard()
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 12))
                .foregroundColor(copied ? themeManager.successColor : themeManager.textTertiaryColor)
                .scaleEffect(copied ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: copied)
        }
        .buttonStyle(.plain)
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = textToCopy
        HapticManager.shared.trigger(.light)

        withAnimation {
            copied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                copied = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Copy Button") {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            CopyButton(textToCopy: "Hello World")
            CopyButton(textToCopy: "Hello World", showLabel: true)
        }

        HStack(spacing: 16) {
            CopyButtonCompact(textToCopy: "Code snippet")
            Text("Compact variant")
                .font(.caption)
        }
    }
    .padding()
    .environmentObject(ThemeManager())
}
