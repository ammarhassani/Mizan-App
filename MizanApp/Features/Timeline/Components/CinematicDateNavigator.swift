//
//  CinematicDateNavigator.swift
//  Mizan
//
//  Lightweight date navigator with liquid glass effect.
//  Performance-optimized: NO continuous animations.
//

import SwiftUI

struct CinematicDateNavigator: View {
    @Binding var selectedDate: Date
    var hijriDate: String?
    var currentPrayerPeriod: PrayerPeriod?

    @State private var transitionDirection: TransitionDirection = .forward
    @State private var dateScale: CGFloat = 1.0
    @State private var dateOpacity: Double = 1.0
    @State private var showAIChat = false
    @EnvironmentObject var themeManager: ThemeManager

    enum TransitionDirection {
        case forward, backward
    }

    var body: some View {
        // Transparent container - no background fill, just content
        contentLayer
            .frame(height: 56)
            .sheet(isPresented: $showAIChat) {
                AIChatSheet()
                    .environmentObject(themeManager)
            }
    }

    // MARK: - Content Layer

    private var contentLayer: some View {
        HStack(spacing: MZSpacing.sm) {
            // AI Chat button
            aiButton

            // Previous day (RTL: right arrow goes back)
            SimpleNavigationArrow(direction: .right) {
                navigateBack()
            }
            .environmentObject(themeManager)

            Spacer()

            // Date display (flexible width)
            dateDisplay

            Spacer()

            // Next day (RTL: left arrow goes forward)
            SimpleNavigationArrow(direction: .left) {
                navigateForward()
            }
            .environmentObject(themeManager)

            // Today button (appears when not on today)
            if !Calendar.current.isDateInToday(selectedDate) {
                todayButton
            }
        }
        .padding(.horizontal, MZSpacing.screenPadding)
        .padding(.vertical, MZSpacing.sm)
    }

    // MARK: - AI Button

    private var aiButton: some View {
        Button {
            HapticManager.shared.trigger(.light)
            showAIChat = true
        } label: {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.primaryColor)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("مساعد ميزان الذكي")
        .accessibilityHint("اضغط لفتح المحادثة مع المساعد الذكي")
    }

    // MARK: - Date Display

    private var dateDisplay: some View {
        VStack(spacing: MZSpacing.xxs) {
            Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                .font(MZTypography.titleMedium)
                .foregroundColor(themeManager.textPrimaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .id("date-\(selectedDate.timeIntervalSince1970)")
                .transition(dateTransition)
                .scaleEffect(dateScale)
                .opacity(dateOpacity)

            // Hijri date with crescent accent
            if let hijri = hijriDate {
                HStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.primaryColor.opacity(0.7))

                    Text(hijri)
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textSecondaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .scaleEffect(dateScale)
                .opacity(dateOpacity)
            }
        }
        .padding(.horizontal, MZSpacing.md)
        .padding(.vertical, MZSpacing.sm)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
        .layoutPriority(-1) // Allow this to shrink when space is tight
    }

    // MARK: - Today Button

    private var todayButton: some View {
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
                .shadow(color: themeManager.primaryColor.opacity(0.3), radius: 6, y: 2)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("العودة لليوم الحالي")
        .accessibilityHint("اضغط للعودة لتاريخ اليوم")
        .transition(.scale.combined(with: .opacity))
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
        animateDateChange {
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        }
    }

    private func navigateBack() {
        transitionDirection = .backward
        HapticManager.shared.trigger(.selection)
        animateDateChange {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    private func navigateToToday() {
        let today = Date()
        transitionDirection = selectedDate > today ? .backward : .forward
        HapticManager.shared.trigger(.medium)
        animateDateChange {
            selectedDate = today
        }
    }

    private func animateDateChange(_ change: @escaping () -> Void) {
        // Scale down + fade out
        withAnimation(.easeIn(duration: 0.1)) {
            dateScale = 0.95
            dateOpacity = 0.5
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(MZAnimation.dateTransition) {
                change()
                dateScale = 1.0
                dateOpacity = 1.0
            }
        }
    }
}

// MARK: - Simple Navigation Arrow

/// Lightweight arrow button with NO continuous animations
struct SimpleNavigationArrow: View {
    let direction: Direction
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @State private var isPressed: Bool = false

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
        Button {
            action()
        } label: {
            // Transparent background - just icon with tap area
            Image(systemName: direction.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.primaryColor)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .scaleEffect(isPressed ? 0.85 : 1.0)
                .opacity(isPressed ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(direction == .left ? "اليوم التالي" : "اليوم السابق")
        .accessibilityHint(direction == .left ? "اضغط للانتقال لليوم التالي" : "اضغط للانتقال لليوم السابق")
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(MZAnimation.cardPress) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Legacy Compatibility

struct DivineDateArrow: View {
    let direction: SimpleNavigationArrow.Direction
    let glowIntensity: Double
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        SimpleNavigationArrow(direction: direction, action: action)
            .environmentObject(themeManager)
    }
}

struct NavigationArrowButton: View {
    let direction: SimpleNavigationArrow.Direction
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        SimpleNavigationArrow(direction: direction, action: action)
            .environmentObject(themeManager)
    }
}

struct GlassNavigationArrow: View {
    let direction: SimpleNavigationArrow.Direction
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        SimpleNavigationArrow(direction: direction, action: action)
            .environmentObject(themeManager)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        CinematicDateNavigator(
            selectedDate: .constant(Date()),
            hijriDate: "١٥ رجب ١٤٤٦",
            currentPrayerPeriod: .dhuhr
        )
        .environmentObject(ThemeManager())

        CinematicDateNavigator(
            selectedDate: .constant(Calendar.current.date(byAdding: .day, value: 1, to: Date())!),
            hijriDate: "١٦ رجب ١٤٤٦",
            currentPrayerPeriod: .maghrib
        )
        .environmentObject(ThemeManager())
    }
    .background(ThemeManager().overlayColor)
}
