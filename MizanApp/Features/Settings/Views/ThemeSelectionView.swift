//
//  ThemeSelectionView.swift
//  Mizan
//
//  Theme selection with color previews
//

import SwiftUI

struct ThemeSelectionView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    private var userSettings: UserSettings {
        appEnvironment.userSettings
    }

    private var allThemes: [Theme] {
        themeManager.allThemes()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current theme indicator
                currentThemeSection

                // Free themes
                themesSection(
                    title: "الثيمات المجانية",
                    themes: themeManager.freeThemes()
                )

                // Pro themes
                themesSection(
                    title: "ثيمات Pro",
                    themes: themeManager.proThemes()
                )

                // App Icon Section (Pro feature)
                if userSettings.isPro {
                    appIconSection
                }
            }
            .padding()
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle("اختيار الثيم")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Current Theme Section

    @ViewBuilder
    private var currentThemeSection: some View {
        VStack(spacing: 8) {
            Text("الثيم الحالي")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textSecondaryColor)

            Text(themeManager.currentTheme.nameArabic)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(themeManager.textPrimaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(themeManager.surfaceColor)
        .cornerRadius(16)
    }

    // MARK: - App Icon Section

    @ViewBuilder
    private var appIconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("أيقونة التطبيق")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(themeManager.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 16) {
                // Auto-switch toggle
                Toggle(isOn: $themeManager.autoSwitchAppIcon) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("تغيير تلقائي مع الثيم")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.textPrimaryColor)

                        Text("الأيقونة تتغير عند تغيير الثيم")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }
                .tint(themeManager.primaryColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(themeManager.surfaceColor)
                .cornerRadius(12)

                // Icon grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("اختر أيقونة")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textSecondaryColor)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(ThemeManager.availableIcons, id: \.id) { icon in
                            AppIconButton(
                                iconId: icon.id,
                                iconName: icon.name,
                                alternateIconName: icon.iconName,
                                isSelected: themeManager.isIconActive(icon.iconName),
                                onSelect: {
                                    selectAppIcon(icon.iconName)
                                }
                            )
                        }
                    }
                }
                .padding(16)
                .background(themeManager.surfaceColor)
                .cornerRadius(12)
                .opacity(themeManager.autoSwitchAppIcon ? 0.5 : 1.0)
                .disabled(themeManager.autoSwitchAppIcon)
            }
        }
        .padding(.top, 8)
    }

    private func selectAppIcon(_ iconName: String?) {
        themeManager.setManualIcon(iconName)
        HapticManager.shared.trigger(.success)
    }

    // MARK: - Themes Section

    @ViewBuilder
    private func themesSection(title: String, themes: [Theme]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(themeManager.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ForEach(themes) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: theme.id == themeManager.currentTheme.id,
                        onSelect: { selectTheme(theme) }
                    )
                    .environmentObject(appEnvironment)
                    .environmentObject(themeManager)
                }
            }
        }
    }

    // MARK: - Actions

    private func selectTheme(_ theme: Theme) {
        // Check Pro requirement
        if theme.isPro && !userSettings.isPro {
            HapticManager.shared.trigger(.warning)
            return
        }

        themeManager.switchTheme(to: theme.id, userSettings: userSettings)
        appEnvironment.save()
        HapticManager.shared.trigger(.success)
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: Theme
    let isSelected: Bool
    let onSelect: () -> Void

    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager

    private var isLocked: Bool {
        theme.isPro && !appEnvironment.userSettings.isPro
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Color preview
                colorPreview

                // Theme info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(theme.nameArabic)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isLocked ? themeManager.textSecondaryColor : themeManager.textPrimaryColor)

                        if theme.isPro {
                            ProBadge()
                        }

                        if theme.autoActivateDuringRamadan == true {
                            Text("🌙")
                                .font(.system(size: 14))
                        }
                    }

                    Text(theme.name)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textSecondaryColor)

                    // Special feature hints
                    if let effects = theme.specialEffects {
                        HStack(spacing: 4) {
                            if effects.arabesquePattern == true {
                                featureChip("نقوش")
                            }
                            if effects.starParticles == true {
                                featureChip("نجوم")
                            }
                            if effects.festiveAnimations == true {
                                featureChip("حركات")
                            }
                        }
                    }
                }

                Spacer()

                // Selection indicator
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.textSecondaryColor)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: theme.colors.primary))
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? themeManager.focusedBorderColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .opacity(isLocked ? 0.7 : 1.0)
    }

    @ViewBuilder
    private var colorPreview: some View {
        VStack(spacing: 0) {
            // Background color
            if let gradient = theme.colors.backgroundGradient, !gradient.isEmpty {
                LinearGradient(
                    colors: gradient.map { Color(hex: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color(hex: theme.colors.background)
            }
        }
        .frame(width: 56, height: 56)
        .overlay(
            // Prayer gradient overlay
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: theme.colors.prayerGradientStart),
                            Color(hex: theme.colors.prayerGradientEnd)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func featureChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(themeManager.textSecondaryColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(themeManager.backgroundColor.opacity(0.5))
            .cornerRadius(4)
    }
}

// MARK: - App Icon Button

struct AppIconButton: View {
    let iconId: String
    let iconName: String
    let alternateIconName: String?
    let isSelected: Bool
    let onSelect: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    /// Theme colors for icon preview backgrounds (fetched from ThemeManager)
    private var iconColors: (background: Color, design: Color, accent: Color?) {
        if let colors = themeManager.colorsForTheme(iconId) {
            return (colors.background, colors.primary, colors.accent)
        }
        // Fallback to current theme colors
        return (themeManager.backgroundColor, themeManager.primaryColor, nil)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Icon preview using actual MizanLogo
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(iconColors.background)
                        .frame(width: 72, height: 72)

                    // Actual Mizan logo
                    MizanLogo(
                        size: 56,
                        designColor: iconColors.design,
                        accentColor: iconColors.accent
                    )

                    // Selection overlay
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.primaryColor, lineWidth: 3)
                            .frame(width: 72, height: 72)

                        // Checkmark
                        Circle()
                            .fill(themeManager.primaryColor)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(themeManager.textOnPrimaryColor)
                            )
                            .offset(x: 28, y: -28)
                    }
                }

                // Icon name
                Text(iconName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? themeManager.primaryColor : themeManager.textSecondaryColor)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ThemeSelectionView()
            .environmentObject(AppEnvironment.preview())
            .environmentObject(AppEnvironment.preview().themeManager)
    }
}
