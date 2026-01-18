//
//  DurationPickerSheet.swift
//  Mizan
//
//  Custom duration picker with hours/minutes wheels and preset chips
//  Matches Structured app's duration picker design
//

import SwiftUI

struct DurationPickerSheet: View {
    @Binding var duration: Int // in minutes
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - State

    @State private var hours: Int = 0
    @State private var minutes: Int = 30

    // MARK: - Presets

    @AppStorage("durationPresets") private var presetsData: Data = {
        let defaults = [1, 15, 30, 45, 60, 90]
        return (try? JSONEncoder().encode(defaults)) ?? Data()
    }()

    private var presets: [Int] {
        (try? JSONDecoder().decode([Int].self, from: presetsData)) ?? [1, 15, 30, 45, 60, 90]
    }

    private func savePresets(_ newPresets: [Int]) {
        if let data = try? JSONEncoder().encode(newPresets) {
            presetsData = data
        }
    }

    var body: some View {
        VStack(spacing: MZSpacing.lg) {
            // Header
            headerView

            // Duration Picker Wheels
            durationWheels

            // Presets Section
            presetsSection

            Spacer()
        }
        .padding(MZSpacing.lg)
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .onAppear {
            // Initialize from current duration
            hours = duration / 60
            minutes = duration % 60
        }
        .onChange(of: hours) { _, _ in updateDuration() }
        .onChange(of: minutes) { _, _ in updateDuration() }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Duration")
                .font(MZTypography.headlineMedium)
                .foregroundColor(themeManager.textPrimaryColor)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(themeManager.textSecondaryColor)
            }
        }
    }

    // MARK: - Duration Wheels

    private var durationWheels: some View {
        HStack(spacing: 0) {
            // Hours picker
            Picker("Hours", selection: $hours) {
                ForEach(0..<13, id: \.self) { h in
                    Text("\(h)")
                        .font(MZTypography.titleLarge)
                        .foregroundColor(themeManager.textPrimaryColor)
                        .tag(h)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)

            Text("hours")
                .font(MZTypography.bodyMedium)
                .foregroundColor(themeManager.textSecondaryColor)
                .frame(width: 50)

            // Minutes picker
            Picker("Minutes", selection: $minutes) {
                ForEach(0..<60, id: \.self) { m in
                    Text("\(m)")
                        .font(MZTypography.titleLarge)
                        .foregroundColor(themeManager.textPrimaryColor)
                        .tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)

            Text("min")
                .font(MZTypography.bodyMedium)
                .foregroundColor(themeManager.textSecondaryColor)
                .frame(width: 40)
        }
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                .fill(themeManager.surfaceColor)
        )
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.md) {
            HStack {
                Text("Presets")
                    .font(MZTypography.labelLarge)
                    .foregroundColor(themeManager.textSecondaryColor)

                Spacer()

                Button {
                    resetPresets()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                        Text("Reset")
                            .font(MZTypography.labelMedium)
                    }
                    .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            // Preset chips in a flex layout
            FlexibleView(
                data: presets,
                spacing: MZSpacing.sm,
                alignment: .leading
            ) { preset in
                presetChip(minutes: preset)
            }
        }
    }

    private func presetChip(minutes presetMinutes: Int) -> some View {
        let isSelected = duration == presetMinutes

        return HStack(spacing: 4) {
            Text(formatPreset(presetMinutes))
                .font(MZTypography.labelLarge)
                .foregroundColor(isSelected ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)

            // Remove button
            Button {
                removePreset(presetMinutes)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? themeManager.textOnPrimaryColor.opacity(0.7) : themeManager.textSecondaryColor)
            }
        }
        .padding(.horizontal, MZSpacing.md)
        .padding(.vertical, MZSpacing.sm)
        .background(
            Capsule()
                .fill(isSelected ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
        )
        .onTapGesture {
            selectPreset(presetMinutes)
        }
    }

    // MARK: - Helpers

    private func formatPreset(_ totalMinutes: Int) -> String {
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        } else if totalMinutes % 60 == 0 {
            return "\(totalMinutes / 60)h"
        } else {
            let h = totalMinutes / 60
            let m = totalMinutes % 60
            return "\(h)h \(m)m"
        }
    }

    private func updateDuration() {
        duration = hours * 60 + minutes
    }

    private func selectPreset(_ presetMinutes: Int) {
        hours = presetMinutes / 60
        minutes = presetMinutes % 60
        HapticManager.shared.trigger(.selection)
    }

    private func removePreset(_ presetMinutes: Int) {
        var current = presets
        current.removeAll { $0 == presetMinutes }
        savePresets(current)
        HapticManager.shared.trigger(.light)
    }

    private func resetPresets() {
        savePresets([1, 15, 30, 45, 60, 90])
        HapticManager.shared.trigger(.medium)
    }
}

// MARK: - Flexible View (for wrapping chips)

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    @State private var availableWidth: CGFloat = 0

    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }

            _FlexibleView(
                availableWidth: availableWidth,
                data: data,
                spacing: spacing,
                alignment: alignment,
                content: content
            )
        }
    }
}

struct _FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    @State private var elementsSize: [Data.Element: CGSize] = [:]

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowElements in
                HStack(spacing: spacing) {
                    ForEach(rowElements, id: \.self) { element in
                        content(element)
                            .fixedSize()
                            .readSize { size in
                                elementsSize[element] = size
                            }
                    }
                }
            }
        }
    }

    func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRowWidth: CGFloat = 0

        for element in data {
            let elementSize = elementsSize[element, default: CGSize(width: 80, height: 30)]

            if currentRowWidth + elementSize.width + spacing > availableWidth {
                rows.append([element])
                currentRowWidth = elementSize.width
            } else {
                rows[rows.count - 1].append(element)
                currentRowWidth += elementSize.width + spacing
            }
        }

        return rows
    }
}

// MARK: - Size Reader

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

// MARK: - Preview

#Preview {
    DurationPickerSheet(duration: .constant(45))
        .environmentObject(ThemeManager())
}
