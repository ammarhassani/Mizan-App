//
//  PremiumTaskCard.swift
//  Mizan
//
//  A premium task card with neubrutalist 3D depth and glass effects
//

import SwiftUI

/// Premium task card with neubrutalist accents and glassmorphism
struct PremiumTaskCard: View {
    let task: Task
    let minHeight: CGFloat
    var hasTaskOverlap: Bool = false
    var overlappingTaskCount: Int = 0
    var onToggleCompletion: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @EnvironmentObject var themeManager: ThemeManager
    @State private var isPressed: Bool = false
    @State private var checkScale: CGFloat = 1.0
    @State private var completionGlow: CGFloat = 0
    @State private var appearOffset: CGFloat = 20
    @State private var appearOpacity: Double = 0

    private var taskColor: Color {
        Color(hex: task.colorHex)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Time row above the card
            timeRow

            // Main card with neubrutalist accent
            mainCard
        }
        .frame(minHeight: minHeight)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .offset(x: appearOffset)
        .opacity(appearOpacity)
        .onAppear {
            withAnimation(MZAnimation.cardAppear) {
                appearOffset = 0
                appearOpacity = 1.0
            }
        }
    }

    // MARK: - Time Row

    private var timeRow: some View {
        HStack(spacing: 6) {
            Text(task.startTime.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(taskColor)

            Text("•")
                .font(.system(size: 8))
                .foregroundColor(themeManager.textTertiaryColor)

            Text(task.duration.formattedDuration)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .padding(.leading, 4)
    }

    // MARK: - Main Card

    private var mainCard: some View {
        HStack(spacing: 0) {
            // Neubrutalist left accent bar
            accentBar

            // Glass content area
            cardContent
        }
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(glassBorder)
        .overlay(completionOverlay)
        .overlapWarning(hasOverlap: hasTaskOverlap, overlapCount: overlappingTaskCount)
        .shadow(color: taskColor.opacity(0.08), radius: 8, y: 3)
        .shadow(color: themeManager.backgroundColor.opacity(0.4), radius: 2, x: 2, y: 2) // Neubrutalist hard shadow
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .opacity(task.isCompleted ? 0.7 : 1.0)
        .animation(MZAnimation.cardPress, value: isPressed)
        .contentShape(Rectangle()) // Make entire card tappable
        .onTapGesture {
            if let onTap = onTap {
                HapticManager.shared.trigger(.light)
                onTap()
            }
        }
        .contextMenu {
            // Edit option
            Button {
                onTap?()
            } label: {
                Label("تعديل", systemImage: "pencil")
            }

            // Toggle completion
            Button {
                onToggleCompletion?()
            } label: {
                Label(task.isCompleted ? "إلغاء الإكمال" : "إكمال", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
            }

            Divider()

            // Delete option
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("حذف", systemImage: "trash")
            }
        }
    }

    // MARK: - Accent Bar (Neubrutalist)

    private var accentBar: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [taskColor, taskColor.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        HStack(spacing: 12) {
            // 3D Checkbox
            premiumCheckbox

            // Task info
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.textPrimaryColor)
                    .strikethrough(task.isCompleted, color: themeManager.textSecondaryColor)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    // Category chip
                    HStack(spacing: 4) {
                        Image(systemName: task.category.icon)
                            .font(.system(size: 9))
                        Text(task.category.displayName)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(taskColor.opacity(0.9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(taskColor.opacity(0.12))
                    )

                    if task.isCompleted {
                        completedBadge
                    }
                }
            }

            Spacer()

            // Duration ring
            durationRing
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Premium Checkbox

    private var premiumCheckbox: some View {
        Button {
            toggleCompletion()
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        task.isCompleted ? themeManager.successColor : taskColor.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 24, height: 24)

                // Inner fill (when completed)
                if task.isCompleted {
                    Circle()
                        .fill(themeManager.successColor)
                        .frame(width: 18, height: 18)

                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(themeManager.textOnPrimaryColor)
                }

                // 3D bevel highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.textOnPrimaryColor.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 22, height: 22)
            }
            .scaleEffect(checkScale)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completed Badge

    private var completedBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 8))
            Text("تم")
                .font(.system(size: 9, weight: .semibold))
        }
        .foregroundColor(themeManager.successColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(themeManager.successColor.opacity(0.15))
        )
    }

    // MARK: - Duration Ring

    private var durationRing: some View {
        ZStack {
            Circle()
                .stroke(taskColor.opacity(0.15), lineWidth: 3)
                .frame(width: 32, height: 32)

            Circle()
                .trim(from: 0, to: task.isCompleted ? 1.0 : 0)
                .stroke(themeManager.successColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-90))

            Text(task.duration.formattedDuration)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        ZStack {
            themeManager.surfaceColor.opacity(0.7)

            LinearGradient(
                colors: [
                    themeManager.textOnPrimaryColor.opacity(0.06),
                    themeManager.textOnPrimaryColor.opacity(0.02),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )

            taskColor.opacity(0.04)
        }
    }

    // MARK: - Glass Border

    private var glassBorder: some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(
                LinearGradient(
                    colors: [
                        taskColor.opacity(0.3),
                        taskColor.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // MARK: - Completion Overlay

    @ViewBuilder
    private var completionOverlay: some View {
        if completionGlow > 0 {
            RoundedRectangle(cornerRadius: 14)
                .stroke(themeManager.successColor.opacity(completionGlow), lineWidth: 2)
                .blur(radius: 3)
        }
    }

    // MARK: - Toggle Completion

    private func toggleCompletion() {
        // Checkbox animation
        withAnimation(MZAnimation.bouncy) {
            checkScale = 0.7
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(MZAnimation.bouncy) {
                checkScale = 1.15
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(MZAnimation.bouncy) {
                checkScale = 1.0
            }
        }

        // Glow pulse on completion
        if !task.isCompleted {
            withAnimation(.easeOut(duration: 0.3)) {
                completionGlow = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.5)) {
                    completionGlow = 0
                }
            }
        }

        HapticManager.shared.trigger(.success)
        onToggleCompletion?()
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            PremiumTaskCard(
                task: {
                    let task = Task(
                        title: "مراجعة القرآن",
                        duration: 30,
                        category: .worship
                    )
                    task.scheduledStartTime = Date()
                    return task
                }(),
                minHeight: 80
            )

            PremiumTaskCard(
                task: {
                    let task = Task(
                        title: "اجتماع العمل",
                        duration: 60,
                        category: .work
                    )
                    task.scheduledStartTime = Date().addingTimeInterval(3600)
                    return task
                }(),
                minHeight: 80
            )

            PremiumTaskCard(
                task: {
                    let task = Task(
                        title: "تمارين رياضية",
                        duration: 45,
                        category: .health
                    )
                    task.scheduledStartTime = Date().addingTimeInterval(7200)
                    task.isCompleted = true
                    return task
                }(),
                minHeight: 80
            )
        }
        .padding()
    }
    .background(Color.black.opacity(0.9))
    .environmentObject(ThemeManager())
}
