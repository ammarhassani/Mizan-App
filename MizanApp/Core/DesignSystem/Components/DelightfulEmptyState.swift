//
//  DelightfulEmptyState.swift
//  Mizan
//
//  Animated empty state with concentric circles and bouncing icons
//

import SwiftUI

struct DelightfulEmptyState: View {
    let type: EmptyStateType
    let action: (() -> Void)?

    @State private var isAnimating = false
    @State private var iconBounce = false
    @EnvironmentObject var themeManager: ThemeManager

    init(type: EmptyStateType, action: (() -> Void)? = nil) {
        self.type = type
        self.action = action
    }

    enum EmptyStateType {
        case inbox
        case timeline
        case completed

        var icon: String {
            switch self {
            case .inbox: return "tray"
            case .timeline: return "calendar.badge.plus"
            case .completed: return "checkmark.seal"
            }
        }

        var title: String {
            switch self {
            case .inbox: return "صندوق الوارد فارغ"
            case .timeline: return "لا توجد مهام مجدولة"
            case .completed: return "لا توجد مهام مكتملة"
            }
        }

        var subtitle: String {
            switch self {
            case .inbox: return "أضف مهمة جديدة لتبدأ"
            case .timeline: return "اسحب مهمة من صندوق الوارد"
            case .completed: return "أكمل مهمة لتراها هنا"
            }
        }

        var buttonTitle: String? {
            switch self {
            case .inbox: return "إضافة مهمة"
            case .timeline: return "عرض المهام"
            case .completed: return nil
            }
        }
    }

    var body: some View {
        VStack(spacing: MZSpacing.lg) {
            // Animated concentric circles with icon
            ZStack {
                // Ripple circles
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(themeManager.textSecondaryColor.opacity(0.1), lineWidth: 1)
                        .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 0.5 : 0.2)
                        .animation(
                            .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                            value: isAnimating
                        )
                }

                // Center icon
                Image(systemName: type.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(themeManager.textSecondaryColor)
                    .symbolEffect(.bounce.byLayer, value: iconBounce)
            }
            .accessibilityHidden(true)

            // Text content
            VStack(spacing: MZSpacing.xs) {
                Text(type.title)
                    .font(MZTypography.titleLarge)
                    .foregroundColor(themeManager.textPrimaryColor)

                Text(type.subtitle)
                    .font(MZTypography.bodyMedium)
                    .foregroundColor(themeManager.textSecondaryColor)
                    .multilineTextAlignment(.center)
            }

            // Action button
            if let buttonTitle = type.buttonTitle, let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(MZTypography.titleSmall)
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .padding(.horizontal, MZSpacing.lg)
                        .padding(.vertical, MZSpacing.sm)
                        .background(
                            Capsule()
                                .fill(themeManager.primaryColor)
                                .shadow(
                                    color: themeManager.primaryColor.opacity(0.4),
                                    radius: 8,
                                    y: 4
                                )
                        )
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel(buttonTitle)
                .accessibilityHint(type == .inbox ? "اضغط لإضافة مهمة جديدة" : "اضغط لعرض المهام المتاحة")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
            // Start periodic icon bounce
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                iconBounce.toggle()
            }
        }
    }
}

#Preview {
    DelightfulEmptyState(type: .inbox) {
        // Add task action
    }
    .environmentObject(ThemeManager())
}
