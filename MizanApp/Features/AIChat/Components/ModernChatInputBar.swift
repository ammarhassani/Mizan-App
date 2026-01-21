//
//  ModernChatInputBar.swift
//  Mizan
//
//  Modern multi-line chat input with expanding text area and animated send button
//

import SwiftUI

/// Modern chat input bar with multi-line support
struct ModernChatInputBar: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// Bound text input
    @Binding var text: String

    /// Whether AI is currently processing
    var isProcessing: Bool

    /// Send action callback
    var onSend: () -> Void

    /// Focus state binding
    @FocusState.Binding var isFocused: Bool

    // MARK: - State

    @State private var textEditorHeight: CGFloat = 40

    // MARK: - Constants

    private let minHeight: CGFloat = 40
    private let maxHeight: CGFloat = 120
    private let lineHeight: CGFloat = 20

    var body: some View {
        HStack(alignment: .bottom, spacing: MZSpacing.sm) {
            // Text input area
            ZStack(alignment: .topLeading) {
                // Placeholder
                if text.isEmpty {
                    Text("اكتب رسالتك...")
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(themeManager.textTertiaryColor)
                        .padding(.horizontal, MZSpacing.md)
                        .padding(.vertical, MZSpacing.sm)
                        .allowsHitTesting(false)
                }

                // Text editor
                TextEditor(text: $text)
                    .font(MZTypography.bodyLarge)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, MZSpacing.sm)
                    .padding(.vertical, MZSpacing.xs)
                    .frame(height: textEditorHeight)
                    .focused($isFocused)
                    .disabled(isProcessing)
                    .onChange(of: text) { _, newValue in
                        updateHeight(for: newValue)
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: min(textEditorHeight / 2, 20))
                    .fill(themeManager.surfaceColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: min(textEditorHeight / 2, 20))
                    .stroke(
                        isFocused ? themeManager.primaryColor.opacity(0.5) : themeManager.textTertiaryColor.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: textEditorHeight)

            // Send button
            sendButton
        }
        .padding(.horizontal, MZSpacing.md)
        .padding(.vertical, MZSpacing.sm)
        .background(themeManager.backgroundColor)
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            onSend()
        } label: {
            ZStack {
                Circle()
                    .fill(canSend ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
                    .frame(width: 40, height: 40)

                Image(systemName: sendButtonIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(canSend ? themeManager.textOnPrimaryColor : themeManager.textTertiaryColor)
            }
        }
        .disabled(!canSend)
        .animation(.easeInOut(duration: 0.2), value: canSend)
    }

    // MARK: - Computed Properties

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }

    private var sendButtonIcon: String {
        if isProcessing {
            return "arrow.trianglehead.2.clockwise"
        } else {
            return "arrow.up"
        }
    }

    // MARK: - Height Calculation

    private func updateHeight(for text: String) {
        let lineCount = text.components(separatedBy: "\n").count
        let textHeight = CGFloat(lineCount) * lineHeight + 16 // padding

        withAnimation(.easeInOut(duration: 0.1)) {
            textEditorHeight = min(max(textHeight, minHeight), maxHeight)
        }
    }
}

// MARK: - Simple Variant (TextField-based)

/// Simple single-line input bar using TextField
struct SimpleChatInputBar: View {
    @EnvironmentObject var themeManager: ThemeManager

    @Binding var text: String
    var isProcessing: Bool
    var placeholder: String = "اكتب رسالتك..."
    var onSend: () -> Void

    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack(spacing: MZSpacing.sm) {
            TextField(placeholder, text: $text)
                .font(MZTypography.bodyLarge)
                .foregroundColor(themeManager.textPrimaryColor)
                .padding(.horizontal, MZSpacing.md)
                .padding(.vertical, MZSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(themeManager.surfaceColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            isFocused ? themeManager.primaryColor.opacity(0.5) : themeManager.textTertiaryColor.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit {
                    if canSend {
                        onSend()
                    }
                }
                .disabled(isProcessing)

            // Send button
            Button {
                onSend()
            } label: {
                ZStack {
                    Circle()
                        .fill(canSend ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
                        .frame(width: 40, height: 40)

                    Image(systemName: isProcessing ? "hourglass" : "arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(canSend ? themeManager.textOnPrimaryColor : themeManager.textTertiaryColor)
                }
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, MZSpacing.md)
        .padding(.vertical, MZSpacing.sm)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }
}

// MARK: - Preview

#Preview("Chat Input Bars") {
    @Previewable @State var text1 = ""
    @Previewable @State var text2 = "هذا نص طويل يمتد على\nعدة أسطر"
    @Previewable @FocusState var focused1: Bool
    @Previewable @FocusState var focused2: Bool
    @Previewable @FocusState var focused3: Bool

    VStack(spacing: 24) {
        Text("Modern (Multi-line)")
            .font(.caption)
        ModernChatInputBar(
            text: $text1,
            isProcessing: false,
            onSend: {},
            isFocused: $focused1
        )

        Divider()

        Text("Modern (With text)")
            .font(.caption)
        ModernChatInputBar(
            text: $text2,
            isProcessing: false,
            onSend: {},
            isFocused: $focused2
        )

        Divider()

        Text("Simple (Single-line)")
            .font(.caption)
        SimpleChatInputBar(
            text: $text1,
            isProcessing: false,
            onSend: {},
            isFocused: $focused3
        )
    }
    .environmentObject(ThemeManager())
}
