//
//  AccentColorView.swift
//  MizanApp
//
//  Accent color customization view for Pro users.
//  Part of the Dark Matter economy - users can unlock more colors.
//

import SwiftUI

struct AccentColorView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appEnvironment: AppEnvironment

    // Predefined accent colors
    private let defaultColors: [AccentColorOption] = [
        AccentColorOption(id: "teal", color: Color(hex: "#14746F") ?? .teal, name: "Teal", nameAr: "فيروزي"),
        AccentColorOption(id: "blue", color: Color(hex: "#0066CC") ?? .blue, name: "Ocean", nameAr: "محيطي"),
        AccentColorOption(id: "purple", color: Color(hex: "#6B4EAA") ?? .purple, name: "Amethyst", nameAr: "بنفسجي"),
        AccentColorOption(id: "green", color: Color(hex: "#2E8B57") ?? .green, name: "Emerald", nameAr: "زمردي"),
        AccentColorOption(id: "gold", color: Color(hex: "#D4AF37") ?? .yellow, name: "Gold", nameAr: "ذهبي"),
    ]

    // Premium colors (require Dark Matter)
    private let premiumColors: [AccentColorOption] = [
        AccentColorOption(id: "rose", color: Color(hex: "#E91E63") ?? .pink, name: "Rose", nameAr: "وردي", darkMatterCost: 50),
        AccentColorOption(id: "crimson", color: Color(hex: "#DC143C") ?? .red, name: "Crimson", nameAr: "قرمزي", darkMatterCost: 50),
        AccentColorOption(id: "sunset", color: Color(hex: "#FF6B35") ?? .orange, name: "Sunset", nameAr: "غروب", darkMatterCost: 75),
        AccentColorOption(id: "midnight", color: Color(hex: "#191970") ?? .indigo, name: "Midnight", nameAr: "منتصف الليل", darkMatterCost: 75),
        AccentColorOption(id: "aurora", color: Color(hex: "#00D4AA") ?? .mint, name: "Aurora", nameAr: "شفق", darkMatterCost: 100),
    ]

    @State private var selectedColorId: String = "teal"

    var body: some View {
        ScrollView {
            VStack(spacing: MZSpacing.lg) {
                // Preview card
                colorPreviewCard

                // Default colors section
                VStack(alignment: .leading, spacing: MZSpacing.sm) {
                    Text("Available Colors")
                        .font(MZTypography.titleSmall)
                        .foregroundColor(themeManager.textPrimaryColor)
                        .padding(.horizontal, MZSpacing.screenPadding)

                    colorGrid(colors: defaultColors, isUnlocked: true)
                }

                // Premium colors section
                VStack(alignment: .leading, spacing: MZSpacing.sm) {
                    HStack {
                        Text("Premium Colors")
                            .font(MZTypography.titleSmall)
                            .foregroundColor(themeManager.textPrimaryColor)

                        Spacer()

                        // Dark Matter balance
                        HStack(spacing: MZSpacing.xxs) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                            Text("\(appEnvironment.userSettings.darkMatterBalance)")
                                .font(MZTypography.labelMedium)
                        }
                        .foregroundColor(themeManager.primaryColor)
                    }
                    .padding(.horizontal, MZSpacing.screenPadding)

                    colorGrid(colors: premiumColors, isUnlocked: false)
                }
            }
            .padding(.vertical, MZSpacing.md)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedColorId = themeManager.currentAccentColorId
        }
    }

    private var colorPreviewCard: some View {
        VStack(spacing: MZSpacing.md) {
            // Preview title
            Text("Preview")
                .font(MZTypography.labelSmall)
                .foregroundColor(themeManager.textSecondaryColor)

            // Sample UI with selected color
            let previewColor = getSelectedColor()
            HStack(spacing: MZSpacing.md) {
                // Sample button
                Button {} label: {
                    Text("Button")
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .padding(.horizontal, MZSpacing.lg)
                        .padding(.vertical, MZSpacing.sm)
                        .background(
                            Capsule()
                                .fill(previewColor)
                        )
                }

                // Sample progress
                ZStack {
                    Circle()
                        .stroke(themeManager.surfaceSecondaryColor, lineWidth: 4)
                        .frame(width: 50, height: 50)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(previewColor, lineWidth: 4)
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    Text("70%")
                        .font(MZTypography.labelSmall)
                        .foregroundColor(themeManager.textPrimaryColor)
                }

                // Sample badge
                HStack(spacing: MZSpacing.xxs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                    Text("Level 5")
                        .font(MZTypography.labelSmall)
                }
                .foregroundColor(previewColor)
                .padding(.horizontal, MZSpacing.sm)
                .padding(.vertical, MZSpacing.xxs)
                .background(
                    Capsule()
                        .fill(previewColor.opacity(0.15))
                )
            }
        }
        .padding(MZSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                .fill(themeManager.surfaceColor)
        )
        .padding(.horizontal, MZSpacing.screenPadding)
    }

    private func colorGrid(colors: [AccentColorOption], isUnlocked: Bool) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: MZSpacing.md) {
            ForEach(colors) { colorOption in
                colorCell(option: colorOption, isUnlocked: isUnlocked || isColorUnlocked(colorOption.id))
            }
        }
        .padding(.horizontal, MZSpacing.screenPadding)
    }

    private func colorCell(option: AccentColorOption, isUnlocked: Bool) -> some View {
        let isSelected = selectedColorId == option.id

        return Button {
            if isUnlocked {
                selectColor(option)
            } else {
                // TODO: Show purchase dialog
            }
        } label: {
            VStack(spacing: MZSpacing.xs) {
                ZStack {
                    // Color circle
                    Circle()
                        .fill(option.color)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? themeManager.textOnPrimaryColor : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: option.color.opacity(0.4), radius: isSelected ? 8 : 0, x: 0, y: 0)

                    // Lock or check indicator
                    if !isUnlocked {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 56, height: 56)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    } else if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(themeManager.textOnPrimaryColor)
                    }
                }

                // Color name
                Text(option.nameAr)
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textSecondaryColor)

                // Dark Matter cost (for locked colors)
                if !isUnlocked, let cost = option.darkMatterCost {
                    HStack(spacing: 2) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("\(cost)")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func getSelectedColor() -> Color {
        if let color = defaultColors.first(where: { $0.id == selectedColorId }) {
            return color.color
        }
        if let color = premiumColors.first(where: { $0.id == selectedColorId }) {
            return color.color
        }
        return themeManager.primaryColor
    }

    private func isColorUnlocked(_ colorId: String) -> Bool {
        // Check if this premium color has been unlocked
        appEnvironment.userSettings.unlockedAccentColors.contains(colorId)
    }

    private func selectColor(_ option: AccentColorOption) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedColorId = option.id
        }
        themeManager.setAccentColor(option.color, id: option.id)
        HapticManager.shared.trigger(.selection)
    }
}

// MARK: - Accent Color Option

struct AccentColorOption: Identifiable {
    let id: String
    let color: Color
    let name: String
    let nameAr: String
    var darkMatterCost: Int?

    init(id: String, color: Color, name: String, nameAr: String, darkMatterCost: Int? = nil) {
        self.id = id
        self.color = color
        self.name = name
        self.nameAr = nameAr
        self.darkMatterCost = darkMatterCost
    }
}

// MARK: - ThemeManager Extension

extension ThemeManager {
    var currentAccentColorId: String {
        // Return current accent color ID (implement in ThemeManager)
        "teal"
    }

    func setAccentColor(_ color: Color, id: String) {
        // Set the accent color (implement in ThemeManager)
        // This would update the primaryColor
    }
}

// MARK: - UserSettings Extension

extension UserSettings {
    var darkMatterBalance: Int {
        // Return dark matter balance (implement in UserSettings)
        0
    }

    var unlockedAccentColors: [String] {
        // Return list of unlocked premium color IDs
        []
    }
}
