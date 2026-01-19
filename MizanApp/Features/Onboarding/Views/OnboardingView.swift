//
//  OnboardingView.swift
//  Mizan
//
//  Story-driven onboarding with choreographed animations
//

import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var currentStep = 0
    @State private var selectedMethod: CalculationMethod?
    @State private var isProcessing = false
    @State private var locationSuccess = false
    @State private var notificationSuccess = false

    private let totalSteps = 4

    var body: some View {
        ZStack {
            // Animated background gradient
            AnimatedOnboardingBackground()

            VStack(spacing: 0) {
                // Custom page indicator at top
                OnboardingPageIndicator(totalPages: totalSteps, currentPage: currentStep)
                    .padding(.top, MZSpacing.xl)

                // Content area
                TabView(selection: $currentStep) {
                    welcomeChapter
                        .tag(0)

                    locationChapter
                        .tag(1)

                    methodChapter
                        .tag(2)

                    notificationChapter
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(MZAnimation.gentle, value: currentStep)
            }
        }
    }

    // MARK: - Chapter 1: Welcome

    private var welcomeChapter: some View {
        VStack(spacing: MZSpacing.xl) {
            Spacer()

            // Dramatic header with animations
            OnboardingChapterHeader(
                icon: "moon.stars.fill",
                title: "ميزان",
                subtitle: "خطط يومك حول ما يهم حقًا"
            )

            // Staggered feature rows
            VStack(spacing: MZSpacing.md) {
                OnboardingFeatureRow(
                    icon: "calendar",
                    title: "جدول زمني تفاعلي",
                    description: "نظّم مهامك حول أوقات الصلاة",
                    delay: 0.6
                )

                OnboardingFeatureRow(
                    icon: "bell.badge",
                    title: "إشعارات ذكية",
                    description: "تنبيهات للصلوات والمهام",
                    delay: 0.75
                )

                OnboardingFeatureRow(
                    icon: "hand.draw",
                    title: "سهولة الاستخدام",
                    description: "اسحب وأفلت المهام بسهولة",
                    delay: 0.9
                )
            }
            .padding(.horizontal, MZSpacing.xl)

            Spacer()

            // Action buttons
            VStack(spacing: MZSpacing.md) {
                OnboardingPrimaryButton(title: "ابدأ", icon: "arrow.left") {
                    advanceToStep(1)
                }
                .accessibilityIdentifier("onboarding_start_button")
            }
            .padding(.horizontal, MZSpacing.xl)
            .padding(.bottom, MZSpacing.xxxl)
        }
        .accessibilityIdentifier("onboarding_welcome_step")
    }

    // MARK: - Chapter 2: Location

    private var locationChapter: some View {
        VStack(spacing: MZSpacing.xl) {
            Spacer()

            OnboardingChapterHeader(
                icon: "location.circle.fill",
                title: "تحديد الموقع",
                subtitle: "نحتاج موقعك لحساب أوقات الصلاة بدقة حسب منطقتك"
            )

            // Location status
            if locationManager.isAuthorized || locationSuccess {
                OnboardingSuccessBadge(
                    title: "تم تفعيل الموقع",
                    subtitle: locationManager.currentLocation.map {
                        String(format: "%.4f, %.4f", $0.coordinate.latitude, $0.coordinate.longitude)
                    }
                )
                .padding(.horizontal, MZSpacing.xl)
            }

            Spacer()

            // Action buttons
            VStack(spacing: MZSpacing.md) {
                if !locationManager.isAuthorized && !locationSuccess {
                    OnboardingPrimaryButton(
                        title: "تفعيل الموقع",
                        icon: "location.fill",
                        isLoading: isProcessing
                    ) {
                        requestLocation()
                    }
                    .accessibilityIdentifier("onboarding_enable_location_button")
                } else {
                    OnboardingPrimaryButton(title: "التالي", icon: "arrow.left") {
                        advanceToStep(2)
                    }
                    .accessibilityIdentifier("onboarding_location_next_button")
                }

                OnboardingSkipButton(title: "تخطي (إدخال يدوي لاحقًا)") {
                    advanceToStep(2)
                }
                .accessibilityIdentifier("onboarding_skip_location_button")
            }
            .padding(.horizontal, MZSpacing.xl)
            .padding(.bottom, MZSpacing.xxxl)
        }
        .accessibilityIdentifier("onboarding_location_step")
    }

    // MARK: - Chapter 3: Calculation Method

    private var methodChapter: some View {
        VStack(spacing: MZSpacing.lg) {
            Spacer()
                .frame(height: MZSpacing.xl)

            OnboardingChapterHeader(
                icon: "calendar.badge.clock",
                title: "طريقة الحساب",
                subtitle: "اختر الطريقة المناسبة لحساب أوقات الصلاة"
            )

            // Method selection cards
            ScrollView {
                VStack(spacing: MZSpacing.sm) {
                    ForEach(CalculationMethod.allCases, id: \.self) { method in
                        MethodSelectionCard(
                            method: method,
                            isSelected: isMethodSelected(method)
                        ) {
                            selectMethod(method)
                        }
                    }
                }
                .padding(.horizontal, MZSpacing.xl)
            }
            .frame(maxHeight: 280)

            Spacer()

            // Action buttons
            VStack(spacing: MZSpacing.md) {
                OnboardingPrimaryButton(title: "التالي", icon: "arrow.left") {
                    applyCalculationMethod()
                    advanceToStep(3)
                }
                .accessibilityIdentifier("onboarding_method_next_button")
            }
            .padding(.horizontal, MZSpacing.xl)
            .padding(.bottom, MZSpacing.xxxl)
        }
        .accessibilityIdentifier("onboarding_method_step")
    }

    // MARK: - Chapter 4: Notifications

    private var notificationChapter: some View {
        VStack(spacing: MZSpacing.xl) {
            Spacer()

            OnboardingChapterHeader(
                icon: "bell.badge.fill",
                title: "الإشعارات",
                subtitle: "احصل على تنبيهات لأوقات الصلاة والمهام المجدولة"
            )

            // Notification features
            VStack(spacing: MZSpacing.md) {
                OnboardingFeatureRow(
                    icon: "clock.badge",
                    title: "قبل الأذان بـ 10 دقائق",
                    description: "تذكير بقرب وقت الصلاة",
                    delay: 0.6
                )

                OnboardingFeatureRow(
                    icon: "speaker.wave.2",
                    title: "صوت الأذان",
                    description: "إشعار مع صوت الأذان عند دخول الوقت",
                    delay: 0.75
                )

                OnboardingFeatureRow(
                    icon: "checkmark.circle",
                    title: "تنبيهات المهام",
                    description: "تذكيرات عند موعد بدء المهام",
                    delay: 0.9
                )
            }
            .padding(.horizontal, MZSpacing.xl)

            // Success badge
            if notificationSuccess {
                OnboardingSuccessBadge(
                    title: "تم تفعيل الإشعارات",
                    subtitle: nil
                )
                .padding(.horizontal, MZSpacing.xl)
            }

            Spacer()

            // Action buttons
            VStack(spacing: MZSpacing.md) {
                if !notificationSuccess {
                    OnboardingPrimaryButton(
                        title: "تفعيل الإشعارات",
                        icon: "bell.fill",
                        isLoading: isProcessing
                    ) {
                        requestNotifications()
                    }
                    .accessibilityIdentifier("onboarding_enable_notifications_button")
                } else {
                    OnboardingPrimaryButton(title: "ابدأ الرحلة", icon: "checkmark") {
                        completeOnboarding()
                    }
                    .accessibilityIdentifier("onboarding_complete_button")
                }

                if !notificationSuccess {
                    OnboardingSkipButton(title: "تخطي (يمكن التفعيل لاحقًا)") {
                        completeOnboarding()
                    }
                    .accessibilityIdentifier("onboarding_skip_notifications_button")
                }
            }
            .padding(.horizontal, MZSpacing.xl)
            .padding(.bottom, MZSpacing.xxxl)
        }
        .accessibilityIdentifier("onboarding_notifications_step")
    }

    // MARK: - Helpers

    private func isMethodSelected(_ method: CalculationMethod) -> Bool {
        if let selected = selectedMethod {
            return selected == method
        }
        return method == appEnvironment.userSettings.calculationMethod
    }

    private func selectMethod(_ method: CalculationMethod) {
        withAnimation(MZAnimation.bouncy) {
            selectedMethod = method
        }
        HapticManager.shared.trigger(.selection)
    }

    private func advanceToStep(_ step: Int) {
        HapticManager.shared.trigger(.light)
        withAnimation(MZAnimation.gentle) {
            currentStep = step
        }
    }

    // MARK: - Actions

    private func requestLocation() {
        isProcessing = true
        locationManager.requestPermission()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
            if locationManager.isAuthorized {
                withAnimation(MZAnimation.bouncy) {
                    locationSuccess = true
                }
                HapticManager.shared.trigger(.success)
            }
        }
    }

    private func applyCalculationMethod() {
        if let method = selectedMethod {
            appEnvironment.userSettings.updateCalculationMethod(method)
            appEnvironment.save()
        }
    }

    private func requestNotifications() {
        isProcessing = true

        _Concurrency.Task {
            let granted = await appEnvironment.notificationManager.requestAuthorization()

            await MainActor.run {
                isProcessing = false

                if granted {
                    appEnvironment.userSettings.notificationsEnabled = true
                    appEnvironment.save()

                    withAnimation(MZAnimation.bouncy) {
                        notificationSuccess = true
                    }
                    HapticManager.shared.trigger(.success)
                }
            }
        }
    }

    private func completeOnboarding() {
        _Concurrency.Task {
            await appEnvironment.markOnboardingComplete()
            HapticManager.shared.trigger(.success)
        }
    }
}

// MARK: - Animated Background

struct AnimatedOnboardingBackground: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            // Base gradient using theme colors
            LinearGradient(
                colors: [
                    themeManager.primaryColor,
                    themeManager.primaryColor.opacity(0.85),
                    themeManager.primaryColor.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Animated overlay circles
            GeometryReader { geometry in
                Circle()
                    .fill(themeManager.textOnPrimaryColor.opacity(0.05))
                    .frame(width: 400, height: 400)
                    .blur(radius: 60)
                    .offset(
                        x: geometry.size.width * 0.3 + sin(phase) * 30,
                        y: geometry.size.height * 0.2 + cos(phase) * 20
                    )

                Circle()
                    .fill(themeManager.textOnPrimaryColor.opacity(0.03))
                    .frame(width: 300, height: 300)
                    .blur(radius: 40)
                    .offset(
                        x: geometry.size.width * 0.7 + cos(phase * 0.8) * 25,
                        y: geometry.size.height * 0.7 + sin(phase * 0.8) * 30
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().locationManager)
        .environmentObject(AppEnvironment.preview().themeManager)
}
