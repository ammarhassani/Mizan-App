//
//  OnboardingComponents.swift
//  Mizan
//
//  Reusable onboarding components with animations
//

import SwiftUI

// MARK: - Custom Page Indicator

struct OnboardingPageIndicator: View {
    let totalPages: Int
    let currentPage: Int

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: MZSpacing.xs) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? themeManager.textOnPrimaryColor : themeManager.textOnPrimaryColor.opacity(0.4))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(MZAnimation.bouncy, value: currentPage)
            }
        }
    }
}

// MARK: - Onboarding Chapter Header

struct OnboardingChapterHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    @EnvironmentObject var themeManager: ThemeManager
    @State private var iconRevealed = false
    @State private var textRevealed = false

    var body: some View {
        VStack(spacing: MZSpacing.lg) {
            // Animated icon
            ZStack {
                // Glow
                Circle()
                    .fill(themeManager.textOnPrimaryColor.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                    .scaleEffect(iconRevealed ? 1 : 0.5)
                    .opacity(iconRevealed ? 1 : 0)

                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundStyle(themeManager.textOnPrimaryColor)
                    .symbolEffect(.bounce, value: iconRevealed)
                    .scaleEffect(iconRevealed ? 1 : 0.3)
                    .opacity(iconRevealed ? 1 : 0)
            }

            VStack(spacing: MZSpacing.sm) {
                Text(title)
                    .font(MZTypography.headlineLarge)
                    .foregroundColor(themeManager.textOnPrimaryColor)
                    .opacity(textRevealed ? 1 : 0)
                    .offset(y: textRevealed ? 0 : 20)

                Text(subtitle)
                    .font(MZTypography.bodyLarge)
                    .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(textRevealed ? 1 : 0)
                    .offset(y: textRevealed ? 0 : 10)
            }
            .padding(.horizontal, MZSpacing.xl)
        }
        .onAppear {
            withAnimation(MZAnimation.dramatic.delay(0.2)) {
                iconRevealed = true
            }
            withAnimation(MZAnimation.gentle.delay(0.4)) {
                textRevealed = true
            }
        }
    }
}

// MARK: - Onboarding Feature Row (Enhanced)

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var delay: Double = 0

    @EnvironmentObject var themeManager: ThemeManager
    @State private var isRevealed = false

    var body: some View {
        HStack(alignment: .center, spacing: MZSpacing.md) {
            // Icon with background - fixed size container to prevent misalignment
            ZStack {
                Circle()
                    .fill(themeManager.textOnPrimaryColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.textOnPrimaryColor)
            }
            .frame(width: 44, height: 44)
            .scaleEffect(isRevealed ? 1 : 0.5)
            .opacity(isRevealed ? 1 : 0)

            VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                Text(title)
                    .font(MZTypography.titleSmall)
                    .foregroundColor(themeManager.textOnPrimaryColor)

                Text(description)
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.8))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(isRevealed ? 1 : 0)
            .offset(x: isRevealed ? 0 : 20)
        }
        .onAppear {
            withAnimation(MZAnimation.bouncy.delay(delay)) {
                isRevealed = true
            }
        }
    }
}

// MARK: - Onboarding Primary Button

struct OnboardingPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    init(title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.shared.trigger(.medium)
            action()
        } label: {
            HStack(spacing: MZSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.primaryColor))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(title)
                        .font(MZTypography.titleSmall)
                }
            }
            .foregroundColor(themeManager.primaryColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MZSpacing.md)
            .background(
                Capsule()
                    .fill(themeManager.textOnPrimaryColor)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isLoading)
    }
}

// MARK: - Onboarding Skip Button

struct OnboardingSkipButton: View {
    let title: String
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button {
            HapticManager.shared.trigger(.light)
            action()
        } label: {
            Text(title)
                .font(MZTypography.labelLarge)
                .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.8))
        }
    }
}

// MARK: - Onboarding Success Badge

struct OnboardingSuccessBadge: View {
    let title: String
    let subtitle: String?

    @EnvironmentObject var themeManager: ThemeManager
    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: MZSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(themeManager.successColor)
                .symbolEffect(.bounce, value: isRevealed)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MZTypography.titleSmall)
                    .foregroundColor(themeManager.textOnPrimaryColor)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.8))
                }
            }
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.textOnPrimaryColor.opacity(0.2))
        )
        .scaleEffect(isRevealed ? 1 : 0.8)
        .opacity(isRevealed ? 1 : 0)
        .onAppear {
            withAnimation(MZAnimation.bouncy) {
                isRevealed = true
            }
            HapticManager.shared.trigger(.success)
        }
    }
}

// MARK: - Method Selection Card

struct MethodSelectionCard: View {
    let method: CalculationMethod
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                    Text(method.nameArabic)
                        .font(MZTypography.titleSmall)
                        .foregroundColor(themeManager.textOnPrimaryColor)

                    Text(method.nameEnglish)
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.7))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.textOnPrimaryColor.opacity(isSelected ? 0.3 : 0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.textOnPrimaryColor.opacity(isSelected ? 0.5 : 0), lineWidth: 2)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "#14746F"), Color(hex: "#52B788")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 30) {
            OnboardingPageIndicator(totalPages: 4, currentPage: 1)

            OnboardingChapterHeader(
                icon: "moon.stars.fill",
                title: "ميزان",
                subtitle: "خطط يومك حول ما يهم حقًا"
            )

            OnboardingFeatureRow(
                icon: "calendar",
                title: "جدول تفاعلي",
                description: "نظّم مهامك حول أوقات الصلاة"
            )

            OnboardingPrimaryButton(title: "ابدأ", icon: "arrow.left") { }

            OnboardingSkipButton(title: "تخطي") { }
        }
        .padding()
    }
    .environmentObject(ThemeManager())
}
