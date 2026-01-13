//
//  OnboardingView.swift
//  Mizan
//
//  Complete 4-step onboarding flow
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

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "#14746F"),
                    Color(hex: "#52B788")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Content
            TabView(selection: $currentStep) {
                // Step 1: Welcome
                welcomeStep
                    .tag(0)

                // Step 2: Location
                locationStep
                    .tag(1)

                // Step 3: Calculation Method
                methodStep
                    .tag(2)

                // Step 4: Notifications
                notificationStep
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 40) {
            Spacer()

            // App icon animation
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 100))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.3), radius: 20)

            // App name and tagline
            VStack(spacing: 16) {
                Text("ميزان")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                Text("خطط يومك حول ما يهم حقًا")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Features
            VStack(alignment: .leading, spacing: 20) {
                OnboardingFeature(
                    icon: "calendar",
                    title: "جدول زمني تفاعلي",
                    description: "نظّم مهامك حول أوقات الصلاة"
                )

                OnboardingFeature(
                    icon: "bell.badge",
                    title: "إشعارات ذكية",
                    description: "تنبيهات للصلوات والمهام"
                )

                OnboardingFeature(
                    icon: "hand.draw",
                    title: "سهولة الاستخدام",
                    description: "اسحب وأفلت المهام بسهولة"
                )
            }
            .padding(.horizontal, 40)

            Spacer()

            // Next button
            Button {
                withAnimation {
                    currentStep = 1
                }
            } label: {
                Text("ابدأ")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#14746F"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 2: Location

    private var locationStep: some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)

            // Title and description
            VStack(spacing: 16) {
                Text("تحديد الموقع")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text("نحتاج موقعك لحساب أوقات الصلاة بدقة حسب منطقتك")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Location status
            if locationManager.isAuthorized {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("تم تفعيل الموقع")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        if let location = locationManager.currentLocation {
                            Text(String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude))
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding()
                .background(.white.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal, 40)
            }

            Spacer()

            VStack(spacing: 16) {
                // Request location button
                if !locationManager.isAuthorized {
                    Button {
                        requestLocation()
                    } label: {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#14746F")))
                            } else {
                                Image(systemName: "location.fill")
                                Text("تفعيل الموقع")
                            }
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "#14746F"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                    .padding(.horizontal, 40)
                }

                // Continue button
                if locationManager.isAuthorized {
                    Button {
                        withAnimation {
                            currentStep = 2
                        }
                    } label: {
                        Text("التالي")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "#14746F"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }

                // Skip button
                Button {
                    withAnimation {
                        currentStep = 2
                    }
                } label: {
                    Text("تخطي (إدخال يدوي لاحقًا)")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 3: Calculation Method

    private var methodStep: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(.white)

            // Title and description
            VStack(spacing: 16) {
                Text("طريقة الحساب")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text("اختر الطريقة المناسبة لحساب أوقات الصلاة")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Method selection
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(CalculationMethod.allCases, id: \.self) { method in
                        Button {
                            selectedMethod = method
                            HapticManager.shared.trigger(.selection)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(method.nameArabic)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text(method.nameEnglish)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }

                                Spacer()

                                if selectedMethod == method || (selectedMethod == nil && method == appEnvironment.userSettings.calculationMethod) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(.white.opacity(selectedMethod == method || (selectedMethod == nil && method == appEnvironment.userSettings.calculationMethod) ? 0.3 : 0.15))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            .frame(maxHeight: 300)

            Spacer()

            // Continue button
            Button {
                applyCalculationMethod()
                withAnimation {
                    currentStep = 3
                }
            } label: {
                Text("التالي")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#14746F"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 4: Notifications

    private var notificationStep: some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)

            // Title and description
            VStack(spacing: 16) {
                Text("الإشعارات")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text("احصل على تنبيهات لأوقات الصلاة والمهام المجدولة")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Features
            VStack(alignment: .leading, spacing: 20) {
                OnboardingFeature(
                    icon: "clock.badge",
                    title: "قبل الأذان بـ 10 دقائق",
                    description: "تذكير بقرب وقت الصلاة"
                )

                OnboardingFeature(
                    icon: "speaker.wave.2",
                    title: "صوت الأذان",
                    description: "إشعار مع صوت الأذان عند دخول الوقت"
                )

                OnboardingFeature(
                    icon: "checkmark.circle",
                    title: "تنبيهات المهام",
                    description: "تذكيرات عند موعد بدء المهام"
                )
            }
            .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 16) {
                // Enable notifications button
                Button {
                    requestNotifications()
                } label: {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#14746F")))
                        } else {
                            Image(systemName: "bell.fill")
                            Text("تفعيل الإشعارات")
                        }
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#14746F"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .cornerRadius(12)
                }
                .disabled(isProcessing)
                .padding(.horizontal, 40)

                // Skip button
                Button {
                    completeOnboarding()
                } label: {
                    Text("تخطي (يمكن التفعيل لاحقًا)")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Actions

    private func requestLocation() {
        isProcessing = true
        locationManager.requestPermission()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
            if locationManager.isAuthorized {
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
            isProcessing = false

            if granted {
                appEnvironment.userSettings.notificationsEnabled = true
                appEnvironment.save()
                HapticManager.shared.trigger(.success)

                // Small delay then complete onboarding
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completeOnboarding()
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

// MARK: - Onboarding Feature

struct OnboardingFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(2)
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
