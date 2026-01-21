//
//  AIMessageView.swift
//  Mizan
//
//  Full-width AI message component with avatar, rich markdown, and copy functionality
//

import SwiftUI

/// Full-width AI message view with avatar and markdown content
struct AIMessageView: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// The message to display
    let message: ChatMessage

    /// Whether to show the timestamp
    var showTimestamp: Bool = false

    // MARK: - State

    @State private var showCopyButton = false

    var body: some View {
        // In RTL: .leading = RIGHT, first HStack element goes to RIGHT
        VStack(alignment: .leading, spacing: MZSpacing.xxs) {
            // Message content
            HStack(alignment: .top, spacing: MZSpacing.sm) {
                // AI Avatar FIRST (appears on RIGHT in RTL)
                MizanAIAvatar(size: 28)

                // Content area SECOND (appears on LEFT in RTL)
                VStack(alignment: .leading, spacing: MZSpacing.xs) {
                    // Rich markdown content
                    MarkdownContentView(content: message.content)

                    // Copy button (visible on tap)
                    if showCopyButton {
                        CopyButton(textToCopy: message.content)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                    .fill(themeManager.surfaceColor)
            )
            .overlay(
                // Leading accent border (= RIGHT side in RTL)
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(themeManager.primaryColor.opacity(0.4))
                        .frame(width: 3)
                    Spacer()
                }
                .padding(.vertical, MZSpacing.xs)
                .padding(.leading, MZSpacing.xxs)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCopyButton.toggle()
                }
            }

            // Timestamp
            if showTimestamp {
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textTertiaryColor)
                    .padding(.leading, 28 + MZSpacing.sm) // Align with content
            }
        }
    }
}

// MARK: - Preview

#Preview("AI Message") {
    VStack(spacing: MZSpacing.md) {
        AIMessageView(
            message: ChatMessage(
                id: UUID(),
                role: .assistant,
                content: "مرحباً! كيف يمكنني مساعدتك اليوم؟",
                timestamp: Date()
            ),
            showTimestamp: true
        )

        AIMessageView(
            message: ChatMessage(
                id: UUID(),
                role: .assistant,
                content: """
                ## إليك خطة اليوم

                1. صلاة الفجر - 5:30 ص
                2. مراجعة الدروس - 8:00 ص
                3. اجتماع العمل - 10:00 ص

                ```swift
                let task = Task(title: "مراجعة", duration: 60)
                ```

                هل تريد تعديل أي شيء؟
                """,
                timestamp: Date()
            )
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager())
}
