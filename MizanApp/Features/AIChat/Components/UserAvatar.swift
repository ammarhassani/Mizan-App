//
//  UserAvatar.swift
//  Mizan
//
//  User avatar component for chat messages
//  Displays user initial or person icon
//

import SwiftUI

/// User avatar for chat messages
struct UserAvatar: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// Size of the avatar
    var size: CGFloat = 28

    /// Optional user initial to display (if nil, shows person icon)
    var initial: String?

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(themeManager.surfaceSecondaryColor)
                .frame(width: size, height: size)

            // Content
            if let initial = initial, !initial.isEmpty {
                // User initial
                Text(String(initial.prefix(1)).uppercased())
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundColor(themeManager.textSecondaryColor)
            } else {
                // Person icon fallback
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundColor(themeManager.textSecondaryColor)
            }
        }
    }
}

// MARK: - Preview

#Preview("User Avatar") {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            UserAvatar(size: 28)
            UserAvatar(size: 28, initial: "م")
            UserAvatar(size: 28, initial: "A")
        }

        HStack(spacing: 16) {
            UserAvatar(size: 32)
            UserAvatar(size: 32, initial: "ع")
            UserAvatar(size: 32, initial: "J")
        }

        HStack(spacing: 16) {
            UserAvatar(size: 40)
            UserAvatar(size: 40, initial: "س")
        }
    }
    .padding()
    .environmentObject(ThemeManager())
}
