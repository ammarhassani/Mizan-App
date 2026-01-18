//
//  IconPickerSheet.swift
//  Mizan
//
//  Searchable SF Symbols picker organized by category
//

import SwiftUI

struct IconPickerSheet: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    @State private var searchText = ""
    @State private var selectedCategory: IconCategory = .all

    // MARK: - Icon Categories

    enum IconCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case recent = "Recent"
        case study = "Study"
        case fitness = "Fitness"
        case health = "Health"
        case work = "Work"
        case social = "Social"
        case food = "Food"
        case travel = "Travel"
        case home = "Home"
        case nature = "Nature"
        case objects = "Objects"

        var id: String { rawValue }

        var icons: [String] {
            switch self {
            case .all:
                return IconCategory.allCases.filter { $0 != .all && $0 != .recent }.flatMap { $0.icons }
            case .recent:
                return [] // Populated from UserDefaults
            case .study:
                return [
                    "book.fill", "book.closed.fill", "books.vertical.fill",
                    "text.book.closed.fill", "graduationcap.fill", "pencil",
                    "pencil.line", "highlighter", "note.text", "doc.text.fill",
                    "folder.fill", "archivebox.fill", "tray.full.fill"
                ]
            case .fitness:
                return [
                    "figure.walk", "figure.run", "figure.hiking", "figure.pool.swim",
                    "figure.outdoor.cycle", "figure.yoga", "figure.strengthtraining.traditional",
                    "figure.mixed.cardio", "sportscourt.fill", "dumbbell.fill",
                    "bicycle", "skateboard.fill"
                ]
            case .health:
                return [
                    "heart.fill", "heart.circle.fill", "cross.case.fill",
                    "pills.fill", "bandage.fill", "stethoscope",
                    "brain.head.profile", "lungs.fill", "allergens",
                    "medical.thermometer.fill", "bed.double.fill"
                ]
            case .work:
                return [
                    "briefcase.fill", "building.2.fill", "desktopcomputer",
                    "laptopcomputer", "keyboard.fill", "printer.fill",
                    "envelope.fill", "phone.fill", "video.fill",
                    "chart.bar.fill", "chart.pie.fill", "calendar"
                ]
            case .social:
                return [
                    "person.2.fill", "person.3.fill", "figure.2.and.child.holdinghands",
                    "person.crop.circle.fill", "bubble.left.fill", "bubble.right.fill",
                    "hand.wave.fill", "gift.fill", "party.popper.fill",
                    "birthday.cake.fill", "hands.clap.fill"
                ]
            case .food:
                return [
                    "fork.knife", "cup.and.saucer.fill", "mug.fill",
                    "wineglass.fill", "carrot.fill", "leaf.fill",
                    "flame.fill", "takeoutbag.and.cup.and.straw.fill",
                    "popcorn.fill", "birthday.cake.fill"
                ]
            case .travel:
                return [
                    "car.fill", "bus.fill", "tram.fill", "airplane",
                    "ferry.fill", "bicycle", "scooter", "fuelpump.fill",
                    "map.fill", "mappin.and.ellipse", "globe.americas.fill",
                    "suitcase.fill", "ticket.fill"
                ]
            case .home:
                return [
                    "house.fill", "house.and.flag.fill", "bed.double.fill",
                    "sofa.fill", "chair.fill", "lamp.desk.fill",
                    "washer.fill", "refrigerator.fill", "oven.fill",
                    "sink.fill", "shower.fill", "bathtub.fill"
                ]
            case .nature:
                return [
                    "sun.max.fill", "moon.fill", "moon.stars.fill",
                    "cloud.fill", "cloud.sun.fill", "snowflake",
                    "leaf.fill", "tree.fill", "mountain.2.fill",
                    "water.waves", "flame.fill", "sparkles"
                ]
            case .objects:
                return [
                    "circle.fill", "square.fill", "triangle.fill",
                    "star.fill", "bell.fill", "tag.fill",
                    "bookmark.fill", "flag.fill", "pin.fill",
                    "paperclip", "link", "lock.fill",
                    "key.fill", "lightbulb.fill", "bolt.fill"
                ]
            }
        }
    }

    // MARK: - Recent Icons

    @AppStorage("recentIcons") private var recentIconsData: Data = Data()

    private var recentIcons: [String] {
        (try? JSONDecoder().decode([String].self, from: recentIconsData)) ?? []
    }

    private func addToRecent(_ icon: String) {
        var recent = recentIcons
        recent.removeAll { $0 == icon }
        recent.insert(icon, at: 0)
        if recent.count > 12 {
            recent = Array(recent.prefix(12))
        }
        if let data = try? JSONEncoder().encode(recent) {
            recentIconsData = data
        }
    }

    // MARK: - Filtered Icons

    private var displayedIcons: [String] {
        let categoryIcons: [String]

        if selectedCategory == .recent {
            categoryIcons = recentIcons
        } else {
            categoryIcons = selectedCategory.icons
        }

        if searchText.isEmpty {
            return categoryIcons
        } else {
            return categoryIcons.filter { icon in
                icon.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Category tabs
                categoryTabs

                // Icons grid
                iconsGrid
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: MZSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.textSecondaryColor)

            ZStack(alignment: .leading) {
                // Custom placeholder for theme compliance
                if searchText.isEmpty {
                    Text("Search icons...")
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(themeManager.textSecondaryColor)
                }

                TextField("", text: $searchText)
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
            }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }
        }
        .padding(MZSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                .fill(themeManager.surfaceColor)
        )
        .padding(.horizontal, MZSpacing.md)
        .padding(.vertical, MZSpacing.sm)
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MZSpacing.sm) {
                ForEach(IconCategory.allCases) { category in
                    categoryTab(category)
                }
            }
            .padding(.horizontal, MZSpacing.md)
        }
        .padding(.vertical, MZSpacing.sm)
    }

    private func categoryTab(_ category: IconCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
            HapticManager.shared.trigger(.selection)
        } label: {
            Text(category.rawValue)
                .font(MZTypography.labelMedium)
                .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
                .padding(.horizontal, MZSpacing.md)
                .padding(.vertical, MZSpacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
                )
        }
    }

    // MARK: - Icons Grid

    private var iconsGrid: some View {
        ScrollView {
            if displayedIcons.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 60), spacing: MZSpacing.md)
                ], spacing: MZSpacing.md) {
                    ForEach(displayedIcons, id: \.self) { icon in
                        iconCell(icon)
                    }
                }
                .padding(MZSpacing.md)
            }
        }
    }

    private func iconCell(_ icon: String) -> some View {
        let isSelected = selectedIcon == icon

        return Button {
            selectedIcon = icon
            addToRecent(icon)
            HapticManager.shared.trigger(.selection)
            dismiss()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .fill(isSelected ? themeManager.primaryColor : themeManager.surfaceColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .stroke(isSelected ? themeManager.primaryColor : Color.clear, lineWidth: 2)
                )
        }
    }

    private var emptyState: some View {
        VStack(spacing: MZSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(themeManager.textSecondaryColor)

            Text("No icons found")
                .font(MZTypography.bodyMedium)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Preview

#Preview {
    IconPickerSheet(selectedIcon: .constant("book.fill"))
        .environmentObject(ThemeManager())
}
