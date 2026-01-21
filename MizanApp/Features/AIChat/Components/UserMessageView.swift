//
//  UserMessageView.swift
//  Mizan
//
//  User message component with right-aligned avatar
//

import SwiftUI

/// User message view with right-aligned avatar
struct UserMessageView: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// The message to display
    let message: ChatMessage

    /// Whether to show the timestamp
    var showTimestamp: Bool = false

    /// Optional user initial for avatar
    var userInitial: String?

    var body: some View {
        // In RTL: .trailing = LEFT, last HStack element goes to LEFT
        VStack(alignment: .trailing, spacing: MZSpacing.xxs) {
            // Message content
            HStack(alignment: .top, spacing: MZSpacing.sm) {
                // Content area FIRST (appears on RIGHT in RTL)
                Text(message.content)
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .padding(.horizontal, MZSpacing.md)
                    .padding(.vertical, MZSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                            .fill(themeManager.surfaceSecondaryColor)
                    )

                // User Avatar LAST (appears on LEFT in RTL)
                UserAvatar(size: 28, initial: userInitial)
            }

            // Timestamp
            if showTimestamp {
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textTertiaryColor)
                    .padding(.trailing, 28 + MZSpacing.sm) // Align with content
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - Preview

#Preview("User Message") {
    VStack(spacing: MZSpacing.md) {
        UserMessageView(
            message: ChatMessage(
                id: UUID(),
                role: .user,
                content: "أضف مهمة دراسة غداً الساعة 8 صباحاً",
                timestamp: Date()
            ),
            showTimestamp: true,
            userInitial: "م"
        )

        UserMessageView(
            message: ChatMessage(
                id: UUID(),
                role: .user,
                content: "ما هي مهامي اليوم؟",
                timestamp: Date()
            ),
            userInitial: "A"
        )

        UserMessageView(
            message: ChatMessage(
                id: UUID(),
                role: .user,
                content: "احذف المهمة الأخيرة",
                timestamp: Date()
            )
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager())
}
