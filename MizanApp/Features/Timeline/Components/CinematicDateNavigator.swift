//
//  CinematicDateNavigator.swift
//  Mizan
//
//  Cinematic date navigation with push transitions and haptic feedback
//

import SwiftUI

struct CinematicDateNavigator: View {
    @Binding var selectedDate: Date
    var hijriDate: String?

    @State private var transitionDirection: TransitionDirection = .forward
    @EnvironmentObject var themeManager: ThemeManager

    enum TransitionDirection {
        case forward, backward
    }

    var body: some View {
        HStack(spacing: MZSpacing.sm) {
            // Previous day (RTL: right arrow goes back)
            NavigationArrowButton(direction: .right) {
                navigateBack()
            }
            .environmentObject(themeManager)

            Spacer()

            // Date display with push transition
            VStack(spacing: MZSpacing.xxs) {
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .id("date-\(selectedDate.timeIntervalSince1970)")
                    .transition(dateTransition)

                if let hijri = hijriDate {
                    Text(hijri)
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            Spacer()

            // Next day (RTL: left arrow goes forward)
            NavigationArrowButton(direction: .left) {
                navigateForward()
            }
            .environmentObject(themeManager)

            // Today button (appears when not on today)
            if !Calendar.current.isDateInToday(selectedDate) {
                Button {
                    navigateToToday()
                } label: {
                    Text("اليوم")
                        .font(MZTypography.labelLarge)
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .padding(.horizontal, MZSpacing.md)
                        .padding(.vertical, MZSpacing.xs)
                        .background(
                            Capsule()
                                .fill(themeManager.primaryColor)
                        )
                }
                .buttonStyle(PressableButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, MZSpacing.screenPadding)
        .padding(.vertical, MZSpacing.sm)
        .background(themeManager.surfaceColor)
    }

    // MARK: - Transition

    private var dateTransition: AnyTransition {
        .asymmetric(
            insertion: .push(from: transitionDirection == .forward ? .trailing : .leading).combined(with: .opacity),
            removal: .push(from: transitionDirection == .forward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    // MARK: - Navigation

    private func navigateForward() {
        transitionDirection = .forward
        HapticManager.shared.trigger(.selection)
        withAnimation(MZAnimation.bouncy) {
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        }
    }

    private func navigateBack() {
        transitionDirection = .backward
        HapticManager.shared.trigger(.selection)
        withAnimation(MZAnimation.bouncy) {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    private func navigateToToday() {
        let today = Date()
        transitionDirection = selectedDate > today ? .backward : .forward
        HapticManager.shared.trigger(.medium)
        withAnimation(MZAnimation.gentle) {
            selectedDate = today
        }
    }
}

// MARK: - Navigation Arrow Button

struct NavigationArrowButton: View {
    let direction: Direction
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    enum Direction {
        case left, right

        var icon: String {
            switch self {
            case .left: return "chevron.left"
            case .right: return "chevron.right"
            }
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: direction.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.primaryColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(themeManager.primaryColor.opacity(0.1))
                )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    CinematicDateNavigator(
        selectedDate: .constant(Date()),
        hijriDate: "١٥ رجب ١٤٤٦"
    )
    .environmentObject(ThemeManager())
}
