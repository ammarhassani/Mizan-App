//
//  MZValidationFeedback.swift
//  Mizan
//
//  Elegant inline validation feedback with animations
//

import SwiftUI

/// Validation states for form inputs
enum ValidationState: Equatable {
    case idle
    case validating
    case success
    case error(String)
    case warning(String)
}

/// Animated validation feedback component
struct MZValidationFeedback: View {
    let state: ValidationState

    @EnvironmentObject var themeManager: ThemeManager
    @State private var isVisible = false
    @State private var shakeOffset: CGFloat = 0

    // MARK: - Body

    var body: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()

            case .validating:
                validatingView

            case .success:
                successView

            case .error(let message):
                errorView(message: message)

            case .warning(let message):
                warningView(message: message)
            }
        }
        .animation(MZAnimation.gentle, value: state)
        .onChange(of: state) { oldValue, newValue in
            handleStateChange(from: oldValue, to: newValue)
        }
    }

    // MARK: - Validating View

    private var validatingView: some View {
        HStack(spacing: MZSpacing.xs) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(themeManager.textSecondaryColor)

            Text("جاري التحقق...")
                .font(MZTypography.labelSmall)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(MZAnimation.gentle.delay(0.1)) {
                isVisible = true
            }
        }
    }

    // MARK: - Success View

    private var successView: some View {
        HStack(spacing: MZSpacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(themeManager.successColor)
                .scaleEffect(isVisible ? 1 : 0.5)

            Text("تم التحقق")
                .font(MZTypography.labelSmall)
                .foregroundColor(themeManager.successColor)
        }
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(MZAnimation.bouncy.delay(0.1)) {
                isVisible = true
            }
            HapticManager.shared.trigger(.success)

            // Auto-hide after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(MZAnimation.gentle) {
                    isVisible = false
                }
            }
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        HStack(spacing: MZSpacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(themeManager.errorColor)

            Text(message)
                .font(MZTypography.labelSmall)
                .foregroundColor(themeManager.errorColor)
        }
        .offset(x: shakeOffset)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(MZAnimation.gentle) {
                isVisible = true
            }
            triggerShake()
        }
    }

    // MARK: - Warning View

    private func warningView(message: String) -> some View {
        HStack(spacing: MZSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(themeManager.warningColor)

            Text(message)
                .font(MZTypography.labelSmall)
                .foregroundColor(themeManager.warningColor)
        }
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(MZAnimation.gentle.delay(0.1)) {
                isVisible = true
            }
        }
    }

    // MARK: - Shake Animation

    private func triggerShake() {
        HapticManager.shared.trigger(.warning)

        let amplitude = MZInteraction.shakeAmplitude
        let oscillations = MZInteraction.shakeOscillations

        // Create shake keyframes manually
        withAnimation(MZAnimation.validationShake) {
            shakeOffset = amplitude
        }

        // Oscillate back and forth
        for i in 1...oscillations * 2 {
            let delay = Double(i) * 0.08
            let offset = i % 2 == 0 ? amplitude : -amplitude
            let dampedOffset = offset * (1 - CGFloat(i) / CGFloat(oscillations * 2 + 1))

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(MZAnimation.validationShake) {
                    shakeOffset = dampedOffset
                }
            }
        }

        // Return to center
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(oscillations * 2 + 1) * 0.08) {
            withAnimation(MZAnimation.validationShake) {
                shakeOffset = 0
            }
        }
    }

    // MARK: - State Change Handler

    private func handleStateChange(from oldValue: ValidationState, to newValue: ValidationState) {
        // Reset visibility for new state
        isVisible = false
        shakeOffset = 0
    }
}

// MARK: - View Modifier

/// Modifier to attach validation feedback below a view
struct ValidationFeedbackModifier: ViewModifier {
    let state: ValidationState

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            content

            MZValidationFeedback(state: state)
                .padding(.leading, MZSpacing.xs)
        }
    }
}

extension View {
    /// Adds validation feedback below the view
    func validationFeedback(_ state: ValidationState) -> some View {
        modifier(ValidationFeedbackModifier(state: state))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: MZSpacing.xl) {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("Idle State")
            MZValidationFeedback(state: .idle)
        }

        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("Validating State")
            MZValidationFeedback(state: .validating)
        }

        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("Success State")
            MZValidationFeedback(state: .success)
        }

        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("Error State")
            MZValidationFeedback(state: .error("العنوان مطلوب"))
        }

        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            Text("Warning State")
            MZValidationFeedback(state: .warning("المدة قصيرة جداً"))
        }
    }
    .padding()
    .environmentObject(ThemeManager())
}
