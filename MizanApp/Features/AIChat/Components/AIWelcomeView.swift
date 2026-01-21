//
//  AIWelcomeView.swift
//  Mizan
//
//  Welcome screen for AI chat with avatar, greeting, and quick suggestions
//

import SwiftUI

/// Welcome screen shown when AI chat is empty
struct AIWelcomeView: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// Quick suggestions to display
    let suggestions: [String]

    /// Callback when a suggestion is tapped
    var onSuggestionTap: ((String) -> Void)?

    // MARK: - State

    @State private var appeared = false

    var body: some View {
        VStack(spacing: MZSpacing.xl) {
            Spacer()

            // Avatar and greeting
            VStack(spacing: MZSpacing.lg) {
                // Large AI Avatar
                MizanAIAvatarLarge(size: 72)
                    .scaleEffect(appeared ? 1.0 : 0.8)
                    .opacity(appeared ? 1.0 : 0)

                // Greeting text
                VStack(spacing: MZSpacing.xs) {
                    Text("مرحباً، أنا مساعد ميزان")
                        .font(MZTypography.titleLarge)
                        .foregroundColor(themeManager.textPrimaryColor)

                    Text("كيف يمكنني مساعدتك اليوم؟")
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1.0 : 0)
                .offset(y: appeared ? 0 : 10)
            }

            // Quick suggestions
            if !suggestions.isEmpty {
                VStack(spacing: MZSpacing.sm) {
                    // Suggestions grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: MZSpacing.xs),
                            GridItem(.flexible(), spacing: MZSpacing.xs)
                        ],
                        spacing: MZSpacing.xs
                    ) {
                        ForEach(suggestions.prefix(4), id: \.self) { suggestion in
                            SuggestionChip(
                                text: suggestion,
                                onTap: {
                                    onSuggestionTap?(suggestion)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, MZSpacing.md)
                }
                .opacity(appeared ? 1.0 : 0)
                .offset(y: appeared ? 0 : 20)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Suggestion Chip

/// Quick suggestion chip button
private struct SuggestionChip: View {
    @EnvironmentObject var themeManager: ThemeManager

    let text: String
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            HapticManager.shared.trigger(.light)
            onTap?()
        } label: {
            HStack(spacing: MZSpacing.xs) {
                Image(systemName: suggestionIcon)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.primaryColor)

                Text(text)
                    .font(MZTypography.labelMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, MZSpacing.sm)
            .padding(.vertical, MZSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                    .fill(themeManager.surfaceColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                    .stroke(themeManager.primaryColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Icon Detection

    private var suggestionIcon: String {
        if text.contains("أضف") || text.contains("add") {
            return "plus.circle"
        } else if text.contains("مهام") || text.contains("tasks") || text.contains("ما هي") {
            return "list.bullet"
        } else if text.contains("رتب") || text.contains("arrange") || text.contains("جدول") {
            return "calendar.badge.clock"
        } else if text.contains("احذف") || text.contains("delete") {
            return "trash"
        } else if text.contains("وقت") || text.contains("time") || text.contains("فارغ") {
            return "clock"
        } else {
            return "sparkles"
        }
    }
}

// MARK: - Preview

#Preview("AI Welcome") {
    AIWelcomeView(
        suggestions: [
            "أضف مهمة دراسة",
            "ما هي مهامي غداً؟",
            "رتب مهامي اليوم",
            "هل يوجد وقت فارغ؟"
        ],
        onSuggestionTap: { suggestion in
            print("Tapped: \(suggestion)")
        }
    )
    .background(Color.gray.opacity(0.05))
    .environmentObject(ThemeManager())
}
