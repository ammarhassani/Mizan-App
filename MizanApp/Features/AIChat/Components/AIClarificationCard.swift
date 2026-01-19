//
//  AIClarificationCard.swift
//  Mizan
//
//  UI for AI clarification questions with selectable options
//

import SwiftUI

// MARK: - AI Clarification Card

struct AIClarificationCard: View {
    let request: ClarificationRequest
    var onOptionSelected: ((ClarificationOption) -> Void)?
    var onFreeTextSubmit: ((String) -> Void)?

    @EnvironmentObject var themeManager: ThemeManager
    @State private var customInput: String = ""
    @State private var showCustomInput: Bool = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            // Question with icon inline
            HStack(spacing: MZSpacing.xs) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.warningColor)

                Text(request.question)
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .lineLimit(2)
            }

            // Options as compact chips
            if let options = request.options, !options.isEmpty {
                optionsView(options)
            }

            // Partial data preview (compact)
            if let partialData = request.partialData {
                partialDataView(partialData)
            }

            // Custom input
            if request.freeTextAllowed {
                if showCustomInput {
                    customInputView
                } else {
                    showCustomInputButton
                }
            }
        }
        .padding(MZSpacing.sm)
        .background(themeManager.surfaceColor)
        .cornerRadius(themeManager.cornerRadius(.medium))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: MZSpacing.sm) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(themeManager.warningColor)

            Text("أحتاج توضيح")
                .font(MZTypography.titleMedium)
                .foregroundColor(themeManager.textPrimaryColor)

            Spacer()
        }
    }

    // MARK: - Options View

    private func optionsView(_ options: [ClarificationOption]) -> some View {
        VStack(spacing: MZSpacing.xxs) {
            ForEach(options, id: \.value) { option in
                Button {
                    onOptionSelected?(option)
                } label: {
                    HStack(spacing: MZSpacing.xs) {
                        Text(option.label)
                            .font(MZTypography.labelMedium)
                            .foregroundColor(themeManager.textPrimaryColor)
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "chevron.left")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.textTertiaryColor)
                    }
                    .padding(.horizontal, MZSpacing.sm)
                    .padding(.vertical, MZSpacing.xs)
                    .background(themeManager.surfaceSecondaryColor)
                    .cornerRadius(themeManager.cornerRadius(.small))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Partial Data View (Compact inline)

    private func partialDataView(_ data: PartialTaskData) -> some View {
        HStack(spacing: MZSpacing.xs) {
            if let title = data.title {
                Text(title)
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            if let duration = data.duration {
                Text("• \(duration)د")
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textTertiaryColor)
            }
            if let date = data.scheduledDate {
                Text("• \(date)")
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textTertiaryColor)
            }
        }
    }

    // MARK: - Custom Input

    private var showCustomInputButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCustomInput = true
                isInputFocused = true
            }
        } label: {
            HStack(spacing: MZSpacing.xs) {
                Image(systemName: "text.cursor")
                    .font(.system(size: 14))
                Text("إدخال آخر")
                    .font(MZTypography.labelMedium)
            }
            .foregroundColor(themeManager.primaryColor)
            .padding(.vertical, MZSpacing.xs)
        }
    }

    private var customInputView: some View {
        HStack(spacing: MZSpacing.xs) {
            TextField("اكتب هنا...", text: $customInput)
                .font(MZTypography.labelMedium)
                .foregroundColor(themeManager.textPrimaryColor)
                .padding(.horizontal, MZSpacing.sm)
                .padding(.vertical, MZSpacing.xs)
                .background(themeManager.surfaceSecondaryColor)
                .cornerRadius(themeManager.cornerRadius(.small))
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    submitCustomInput()
                }

            Button {
                submitCustomInput()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(customInput.isEmpty ? themeManager.textTertiaryColor : themeManager.primaryColor)
            }
            .disabled(customInput.isEmpty)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCustomInput = false
                    customInput = ""
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.textTertiaryColor)
            }
        }
    }

    private func submitCustomInput() {
        guard !customInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onFreeTextSubmit?(customInput)
        customInput = ""
        showCustomInput = false
    }
}

// MARK: - Task Disambiguation Card

struct AITaskDisambiguationCard: View {
    let question: String
    let tasks: [TaskSummary]
    var onTaskSelected: ((TaskSummary) -> Void)?

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: MZSpacing.md) {
            // Header
            HStack(spacing: MZSpacing.sm) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.warningColor)

                Text(question)
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.textPrimaryColor)

                Spacer()
            }

            // Task options
            VStack(spacing: MZSpacing.sm) {
                ForEach(tasks, id: \.id) { task in
                    Button {
                        onTaskSelected?(task)
                    } label: {
                        HStack(spacing: MZSpacing.sm) {
                            // Icon
                            Image(systemName: task.icon)
                                .font(.system(size: 16))
                                .foregroundColor(categoryColor(for: task.category))
                                .frame(width: 24)

                            // Task info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(MZTypography.bodyMedium)
                                    .foregroundColor(themeManager.textPrimaryColor)
                                    .lineLimit(1)

                                HStack(spacing: MZSpacing.xs) {
                                    if let time = task.scheduledTime {
                                        Text(time)
                                            .font(MZTypography.labelSmall)
                                            .foregroundColor(themeManager.textSecondaryColor)
                                    }
                                    Text("• \(task.duration) د")
                                        .font(MZTypography.labelSmall)
                                        .foregroundColor(themeManager.textTertiaryColor)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.textTertiaryColor)
                        }
                        .padding(MZSpacing.sm)
                        .background(themeManager.surfaceSecondaryColor)
                        .cornerRadius(themeManager.cornerRadius(.medium))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(MZSpacing.md)
        .background(themeManager.surfaceColor)
        .cornerRadius(themeManager.cornerRadius(.large))
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.large))
                .stroke(themeManager.warningColor.opacity(0.3), lineWidth: 1)
        )
    }

    private func categoryColor(for category: String) -> Color {
        let taskCategory = TaskCategory(rawValue: category) ?? .personal
        return Color(hex: taskCategory.defaultColorHex)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AIClarificationCard(
            request: ClarificationRequest(
                question: "متى تريد جدولة \"الدراسة\"؟",
                options: [
                    ClarificationOption(label: "الآن", value: "now", icon: "clock.fill"),
                    ClarificationOption(label: "بعد صلاة الظهر", value: "after_dhuhr", icon: "sun.max.fill"),
                    ClarificationOption(label: "غداً", value: "tomorrow", icon: "calendar"),
                    ClarificationOption(label: "اختيار وقت محدد", value: "custom", icon: "calendar.badge.clock")
                ],
                freeTextAllowed: true,
                partialData: PartialTaskData(title: "الدراسة", duration: 45)
            )
        )

        AITaskDisambiguationCard(
            question: "أي مهمة تقصد؟",
            tasks: [
                TaskSummary(id: "1", title: "دراسة الرياضيات", icon: "book.fill", scheduledTime: "2:00 م", duration: 45, category: "study"),
                TaskSummary(id: "2", title: "دراسة الفيزياء", icon: "book.fill", scheduledTime: "4:00 م", duration: 60, category: "study")
            ]
        )
    }
    .padding()
    .background(ThemeManager().surfaceSecondaryColor)
    .environmentObject(ThemeManager())
}
