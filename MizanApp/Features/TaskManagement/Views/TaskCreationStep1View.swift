//
//  TaskCreationStep1View.swift
//  Mizan
//
//  Step 1 of task creation: Title + Intelligent Icon + Suggestions
//

import SwiftUI
import SwiftData

struct TaskCreationStep1View: View {
    // MARK: - Bindings (shared with parent)
    @Binding var title: String
    @Binding var icon: String
    @Binding var duration: Int
    @Binding var scheduledTime: Date

    let onContinue: () -> Void
    let onSelectSuggestion: (Task) -> Void

    // MARK: - Environment
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    // MARK: - State
    @State private var showIconPicker = false
    @FocusState private var isTitleFocused: Bool

    // MARK: - Queries
    @Query(sort: \Task.updatedAt, order: .reverse) private var allTasks: [Task]

    // MARK: - Suggestions

    private var suggestions: [Task] {
        // Get unique tasks by title, sorted by most recent
        var seenTitles: Set<String> = []
        var uniqueTasks: [Task] = []

        for task in allTasks {
            let normalizedTitle = task.title.lowercased().trimmingCharacters(in: .whitespaces)
            if !seenTitles.contains(normalizedTitle) && task.scheduledStartTime != nil {
                seenTitles.insert(normalizedTitle)
                uniqueTasks.append(task)
            }
            if uniqueTasks.count >= 10 {
                break
            }
        }

        return uniqueTasks
    }

    // MARK: - Computed

    private var canContinue: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var timeRangePreview: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US")

        let startStr = formatter.string(from: scheduledTime)
        let endTime = scheduledTime.addingTimeInterval(TimeInterval(duration * 60))
        let endStr = formatter.string(from: endTime)

        return "\(startStr) - \(endStr) (\(formatDuration(duration)))"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with icon + time preview + title
            headerSection

            Divider()
                .background(themeManager.surfaceSecondaryColor)

            // Suggestions list
            suggestionsSection

            Spacer()

            // Continue button
            continueButton
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .sheet(isPresented: $showIconPicker) {
            IconPickerSheet(selectedIcon: $icon)
                .environmentObject(themeManager)
        }
        .onChange(of: title) { _, newTitle in
            // Auto-detect icon as user types
            let detectedIcon = TaskIconDetector.shared.detectIcon(from: newTitle)
            if detectedIcon != "circle.fill" {
                icon = detectedIcon
            }
        }
        .onAppear {
            isTitleFocused = true
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: MZSpacing.md) {
            HStack(alignment: .center, spacing: MZSpacing.md) {
                // Icon picker button
                iconPickerButton

                // Title field + time preview
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeRangePreview)
                        .font(MZTypography.labelSmall)
                        .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.8))

                    ZStack(alignment: .leading) {
                        // Custom placeholder for theme compliance
                        if title.isEmpty {
                            Text("Task name")
                                .font(MZTypography.titleMedium)
                                .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.5))
                        }

                        TextField("", text: $title)
                            .font(MZTypography.titleMedium)
                            .foregroundColor(themeManager.textOnPrimaryColor)
                            .focused($isTitleFocused)
                            .textFieldStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, MZSpacing.lg)
            .padding(.vertical, MZSpacing.xl)
        }
        .background(themeManager.primaryColor)
    }

    private var iconPickerButton: some View {
        Button {
            showIconPicker = true
            HapticManager.shared.trigger(.selection)
        } label: {
            ZStack {
                Circle()
                    .fill(themeManager.textOnPrimaryColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.textOnPrimaryColor)
            }
        }
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            if !suggestions.isEmpty {
                Text("Suggestions")
                    .font(MZTypography.labelMedium)
                    .foregroundColor(themeManager.textSecondaryColor)
                    .padding(.horizontal, MZSpacing.lg)
                    .padding(.top, MZSpacing.md)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(suggestions) { task in
                            suggestionRow(task)
                        }
                    }
                    .background(themeManager.surfaceColor)
                    .cornerRadius(themeManager.cornerRadius(.large))
                    .padding(.horizontal, MZSpacing.md)
                }
            }
        }
    }

    private func suggestionRow(_ task: Task) -> some View {
        VStack(spacing: 0) {
            Button {
                selectSuggestion(task)
            } label: {
                HStack(spacing: MZSpacing.md) {
                    // Icon
                    Image(systemName: task.icon)
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.primaryColor)
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)

                    // Title + Time
                    VStack(alignment: .leading, spacing: 2) {
                        if let startTime = task.scheduledStartTime {
                            Text(formatTimeRange(startTime, duration: task.duration))
                                .font(MZTypography.labelSmall)
                                .foregroundColor(themeManager.textSecondaryColor)
                        }

                        Text(task.title)
                            .font(MZTypography.bodyMedium)
                            .foregroundColor(themeManager.textPrimaryColor)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(.horizontal, MZSpacing.md)
                .padding(.vertical, MZSpacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.title)
            .accessibilityHint("اضغط لتحديد هذه المهمة")

            Divider()
                .padding(.leading, 68)
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            onContinue()
            HapticManager.shared.trigger(.medium)
        } label: {
            Text("Continue")
                .font(MZTypography.titleMedium)
                .foregroundColor(canContinue ? themeManager.textOnPrimaryColor : themeManager.textSecondaryColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MZSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                        .fill(canContinue ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
                )
        }
        .disabled(!canContinue)
        .padding(.horizontal, MZSpacing.lg)
        .padding(.bottom, MZSpacing.xl)
    }

    // MARK: - Helpers

    private func selectSuggestion(_ task: Task) {
        title = task.title
        icon = task.icon
        duration = task.duration
        if let startTime = task.scheduledStartTime {
            // Keep just the time component, apply to today
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
            var todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            todayComponents.hour = timeComponents.hour
            todayComponents.minute = timeComponents.minute
            if let newTime = calendar.date(from: todayComponents) {
                scheduledTime = newTime
            }
        }
        HapticManager.shared.trigger(.selection)
        onSelectSuggestion(task)
    }

    private func formatTimeRange(_ startTime: Date, duration: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US")

        let startStr = formatter.string(from: startTime)
        let endTime = startTime.addingTimeInterval(TimeInterval(duration * 60))
        let endStr = formatter.string(from: endTime)

        return "\(startStr) - \(endStr) (\(formatDuration(duration)))"
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else if minutes % 60 == 0 {
            let hours = minutes / 60
            return "\(hours) hr"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours) hr, \(mins) min"
        }
    }
}

// MARK: - Preview

#Preview {
    TaskCreationStep1View(
        title: .constant(""),
        icon: .constant("circle.fill"),
        duration: .constant(30),
        scheduledTime: .constant(Date()),
        onContinue: {},
        onSelectSuggestion: { _ in }
    )
    .environmentObject(ThemeManager())
    .modelContainer(for: Task.self, inMemory: true)
}
