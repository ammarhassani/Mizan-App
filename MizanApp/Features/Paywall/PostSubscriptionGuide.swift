//
//  PostSubscriptionGuide.swift
//  Mizan
//
//  Shows unlocked Pro features after successful subscription
//

import SwiftUI

struct PostSubscriptionGuide: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentFeature = 0
    @State private var showCongrats = true
    @State private var isRevealed = false

    private var unlockedFeatures: [(icon: String, title: String, description: String, color: Color)] {
        [
            ("paintpalette.fill", "ثيمات حصرية", "الآن يمكنك اختيار من 4 ثيمات إضافية: ليل، فجر، صحراء، ورمضان", themeManager.primaryColor),
            ("moon.stars.fill", "النوافل", "تابع 9 أنواع من النوافل: الضحى، التهجد، الوتر، والرواتب قبل وبعد الصلاة", themeManager.successColor),
            ("repeat", "المهام المتكررة", "أنشئ مهام تتكرر يوميًا أو أسبوعيًا أو شهريًا تلقائيًا", themeManager.warningColor),
            ("bell.badge.fill", "إشعارات متقدمة", "احصل على تذكير قبل 5، 10، 15، أو 30 دقيقة من مهامك", themeManager.errorColor),
            ("speaker.wave.3.fill", "أصوات الأذان", "اختر صوت المؤذن المفضل من مكة أو المدينة أو مصر", themeManager.warningColor)
        ]
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: MZSpacing.xl) {
                if showCongrats {
                    congratsView
                } else {
                    featuresView
                }
            }
            .padding(MZSpacing.screenPadding)
        }
        .onAppear {
            withAnimation(MZAnimation.bouncy.delay(0.2)) {
                isRevealed = true
            }
            HapticManager.shared.trigger(.success)

            // Auto-advance from congrats after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(MZAnimation.gentle) {
                    showCongrats = false
                }
            }
        }
    }

    // MARK: - Congrats View

    private var congratsView: some View {
        VStack(spacing: MZSpacing.lg) {
            Spacer()

            // Celebration icon
            ZStack {
                Circle()
                    .fill(themeManager.textOnPrimaryColor.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                    .scaleEffect(isRevealed ? 1 : 0.5)

                Image(systemName: "crown.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [themeManager.textOnPrimaryColor, themeManager.warningColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.bounce.byLayer, value: isRevealed)
                    .scaleEffect(isRevealed ? 1 : 0.3)
            }

            VStack(spacing: MZSpacing.sm) {
                Text("مبروك!")
                    .font(MZTypography.displayLarge)
                    .foregroundColor(themeManager.textOnPrimaryColor)

                Text("أنت الآن عضو Pro")
                    .font(MZTypography.titleLarge)
                    .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.9))

                Text("استكشف الميزات الجديدة")
                    .font(MZTypography.bodyLarge)
                    .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.7))
            }
            .opacity(isRevealed ? 1 : 0)
            .offset(y: isRevealed ? 0 : 20)

            Spacer()
        }
    }

    // MARK: - Features View

    private var featuresView: some View {
        VStack(spacing: MZSpacing.lg) {
            // Header
            VStack(spacing: MZSpacing.sm) {
                Text("الميزات المفعّلة")
                    .font(MZTypography.headlineLarge)
                    .foregroundColor(themeManager.textOnPrimaryColor)

                Text("\(currentFeature + 1) من \(unlockedFeatures.count)")
                    .font(MZTypography.labelLarge)
                    .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.7))
            }

            Spacer()

            // Feature card
            let feature = unlockedFeatures[currentFeature]
            VStack(spacing: MZSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(feature.color.opacity(0.3))
                        .frame(width: 120, height: 120)

                    Image(systemName: feature.icon)
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .symbolEffect(.bounce.byLayer, value: currentFeature)
                }

                VStack(spacing: MZSpacing.sm) {
                    Text(feature.title)
                        .font(MZTypography.titleLarge)
                        .foregroundColor(themeManager.textOnPrimaryColor)

                    Text(feature.description)
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(MZSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.textOnPrimaryColor.opacity(0.15))
            )
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                removal: .opacity
            ))
            .id(currentFeature)
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width

                        // RTL-aware: swipe left = next, swipe right = previous
                        if horizontalAmount < -50 && currentFeature < unlockedFeatures.count - 1 {
                            // Swipe left → next
                            withAnimation(MZAnimation.snappy) {
                                currentFeature += 1
                            }
                            HapticManager.shared.trigger(.selection)
                        } else if horizontalAmount > 50 && currentFeature > 0 {
                            // Swipe right → previous
                            withAnimation(MZAnimation.snappy) {
                                currentFeature -= 1
                            }
                            HapticManager.shared.trigger(.selection)
                        }
                    }
            )

            Spacer()

            // Navigation
            HStack(spacing: MZSpacing.lg) {
                if currentFeature > 0 {
                    Button {
                        withAnimation(MZAnimation.snappy) {
                            currentFeature -= 1
                        }
                        HapticManager.shared.trigger(.selection)
                    } label: {
                        HStack(spacing: MZSpacing.xs) {
                            Image(systemName: "chevron.right")
                            Text("السابق")
                        }
                        .font(MZTypography.labelLarge)
                        .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.8))
                    }
                } else {
                    Spacer()
                }

                Spacer()

                if currentFeature < unlockedFeatures.count - 1 {
                    Button {
                        withAnimation(MZAnimation.snappy) {
                            currentFeature += 1
                        }
                        HapticManager.shared.trigger(.selection)
                    } label: {
                        HStack(spacing: MZSpacing.xs) {
                            Text("التالي")
                            Image(systemName: "chevron.left")
                        }
                        .font(MZTypography.labelLarge)
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .padding(.horizontal, MZSpacing.lg)
                        .padding(.vertical, MZSpacing.sm)
                        .background(
                            Capsule()
                                .fill(themeManager.textOnPrimaryColor.opacity(0.25))
                        )
                    }
                } else {
                    Button {
                        HapticManager.shared.trigger(.medium)
                        dismiss()
                    } label: {
                        HStack(spacing: MZSpacing.xs) {
                            Text("ابدأ الآن")
                            Image(systemName: "arrow.left")
                        }
                        .font(MZTypography.titleSmall)
                        .foregroundColor(themeManager.primaryColor)
                        .padding(.horizontal, MZSpacing.lg)
                        .padding(.vertical, MZSpacing.sm)
                        .background(
                            Capsule()
                                .fill(themeManager.textOnPrimaryColor)
                        )
                    }
                }
            }

            // Page indicator
            HStack(spacing: MZSpacing.xs) {
                ForEach(0..<unlockedFeatures.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentFeature ? themeManager.textOnPrimaryColor : themeManager.textOnPrimaryColor.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .animation(MZAnimation.snappy, value: currentFeature)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PostSubscriptionGuide()
        .environmentObject(AppEnvironment.preview().themeManager)
}
