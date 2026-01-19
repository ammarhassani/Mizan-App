//
//  PaywallSheet.swift
//  Mizan
//
//  Pro upgrade paywall with feature carousel
//

import SwiftUI
import StoreKit

struct PaywallSheet: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPage = 0
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPostSubscriptionGuide = false

    private var features: [ProFeature] {
        [
            ProFeature(
                icon: "paintpalette.fill",
                title: "ثيمات حصرية",
                subtitle: "4 ثيمات إضافية",
                description: "ليل، فجر، صحراء، ورمضان",
                gradient: [themeManager.primaryColor, themeManager.primaryColor.opacity(0.7)]
            ),
            ProFeature(
                icon: "moon.stars.fill",
                title: "النوافل",
                subtitle: "9 أنواع من النوافل",
                description: "الضحى، التهجد، الوتر، والرواتب",
                gradient: [themeManager.successColor, themeManager.successColor.opacity(0.7)]
            ),
            ProFeature(
                icon: "repeat",
                title: "المهام المتكررة",
                subtitle: "يومي، أسبوعي، شهري",
                description: "جدول مهامك تلقائيًا",
                gradient: [themeManager.warningColor, themeManager.errorColor]
            ),
            ProFeature(
                icon: "bell.badge.fill",
                title: "إشعارات متقدمة",
                subtitle: "تذكير قبل المهمة",
                description: "5، 10، 15، أو 30 دقيقة قبل",
                gradient: [themeManager.errorColor, themeManager.primaryColor]
            ),
            ProFeature(
                icon: "speaker.wave.3.fill",
                title: "أصوات الأذان",
                subtitle: "مكة، المدينة، مصر",
                description: "اختر صوت المؤذن المفضل",
                gradient: [themeManager.warningColor, themeManager.warningColor.opacity(0.7)]
            )
        ]
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                themeManager.backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Feature Carousel
                        featureCarousel

                        // Page Indicator
                        pageIndicator

                        // Pricing Cards
                        pricingSection

                        // Restore Button
                        restoreButton

                        // Terms
                        termsText
                    }
                    .padding()
                }
            }
            .navigationTitle("ميزان Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                    .accessibilityLabel("إغلاق نافذة الاشتراك")
                    .accessibilityIdentifier("paywall_close_button")
                }
            }
            .alert("خطأ", isPresented: $showError) {
                Button("حسنًا", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Pre-select annual as best value
                selectedProduct = storeManager.annualProduct
            }
            .fullScreenCover(isPresented: $showPostSubscriptionGuide, onDismiss: {
                dismiss()
            }) {
                PostSubscriptionGuide()
                    .environmentObject(themeManager)
            }
        }
    }

    // MARK: - Feature Carousel

    @ViewBuilder
    private var featureCarousel: some View {
        TabView(selection: $selectedPage) {
            ForEach(features.indices, id: \.self) { index in
                FeatureCard(feature: features[index])
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 220)
    }

    // MARK: - Page Indicator

    @ViewBuilder
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(features.indices, id: \.self) { index in
                Circle()
                    .fill(index == selectedPage ? themeManager.primaryColor : themeManager.textSecondaryColor.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: selectedPage)
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Pricing Section

    @ViewBuilder
    private var pricingSection: some View {
        VStack(spacing: 12) {
            Text("اختر خطتك")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.textPrimaryColor)

            if storeManager.isLoading && storeManager.products.isEmpty {
                ProgressView()
                    .padding()
            } else if storeManager.products.isEmpty {
                Text("تعذر تحميل الأسعار")
                    .foregroundColor(themeManager.errorColor)
                    .padding()

                Button("إعادة المحاولة") {
                    _Concurrency.Task {
                        await storeManager.loadProducts()
                    }
                }
                .foregroundColor(themeManager.primaryColor)
            } else {
                // Annual (Best Value)
                if let annual = storeManager.annualProduct {
                    PricingCard(
                        product: annual,
                        isSelected: selectedProduct?.id == annual.id,
                        badge: "الأفضل قيمة",
                        savingsPercent: storeManager.annualSavingsPercent,
                        onSelect: { selectedProduct = annual }
                    )
                    .environmentObject(themeManager)
                }

                // Monthly
                if let monthly = storeManager.monthlyProduct {
                    PricingCard(
                        product: monthly,
                        isSelected: selectedProduct?.id == monthly.id,
                        badge: nil,
                        savingsPercent: 0,
                        onSelect: { selectedProduct = monthly }
                    )
                    .environmentObject(themeManager)
                }

                // Lifetime
                if let lifetime = storeManager.lifetimeProduct {
                    PricingCard(
                        product: lifetime,
                        isSelected: selectedProduct?.id == lifetime.id,
                        badge: "دفعة واحدة",
                        savingsPercent: 0,
                        onSelect: { selectedProduct = lifetime }
                    )
                    .environmentObject(themeManager)
                }

                // Purchase Button
                purchaseButton
            }
        }
    }

    // MARK: - Purchase Button

    @ViewBuilder
    private var purchaseButton: some View {
        Button {
            purchase()
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(themeManager.textOnPrimaryColor)
                } else {
                    Text("اشترك الآن")
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(themeManager.textOnPrimaryColor)
            .cornerRadius(16)
        }
        .disabled(selectedProduct == nil || isPurchasing)
        .padding(.top, 8)
        .accessibilityIdentifier("paywall_purchase_button")
    }

    // MARK: - Restore Button

    @ViewBuilder
    private var restoreButton: some View {
        Button {
            _Concurrency.Task {
                await storeManager.restorePurchases()
                if storeManager.isPro {
                    appEnvironment.userSettings.isPro = true
                    appEnvironment.save()
                    dismiss()
                }
            }
        } label: {
            Text("استعادة المشتريات")
                .font(.system(size: 15))
                .foregroundColor(themeManager.primaryColor)
        }
        .accessibilityIdentifier("paywall_restore_button")
    }

    // MARK: - Terms

    @ViewBuilder
    private var termsText: some View {
        VStack(spacing: 4) {
            Text("الاشتراك يتجدد تلقائيًا. يمكنك الإلغاء في أي وقت من إعدادات الجهاز.")
                .font(.system(size: 11))
                .foregroundColor(themeManager.textSecondaryColor)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Button("سياسة الخصوصية") {
                    if let url = URL(string: "https://mizanapp.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }

                Text("•")

                Button("شروط الاستخدام") {
                    if let url = URL(string: "https://mizanapp.com/terms") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .font(.system(size: 11))
            .foregroundColor(themeManager.primaryColor)
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func purchase() {
        guard let product = selectedProduct else { return }

        isPurchasing = true

        _Concurrency.Task {
            do {
                let success = try await storeManager.purchase(product)
                if success {
                    appEnvironment.userSettings.isPro = true
                    appEnvironment.save()
                    HapticManager.shared.trigger(.success)
                    // Show the post-subscription guide instead of dismissing immediately
                    showPostSubscriptionGuide = true
                }
            } catch {
                errorMessage = "فشل الشراء - حاول مرة أخرى"
                showError = true
                HapticManager.shared.trigger(.error)
            }
            isPurchasing = false
        }
    }
}

// MARK: - Pro Feature Model

struct ProFeature {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let gradient: [Color]
}

// MARK: - Feature Card

struct FeatureCard: View {
    let feature: ProFeature

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: feature.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)

                Image(systemName: feature.icon)
                    .font(.system(size: 32))
                    .foregroundColor(themeManager.textOnPrimaryColor)
            }

            // Text
            VStack(spacing: 6) {
                Text(feature.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(themeManager.textPrimaryColor)

                Text(feature.subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.textSecondaryColor)

                Text(feature.description)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textSecondaryColor.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let savingsPercent: Int
    let onSelect: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? themeManager.primaryColor : themeManager.textSecondaryColor)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.isLifetime ? "مدى الحياة" : product.periodText)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(themeManager.textPrimaryColor)

                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(themeManager.textOnPrimaryColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [themeManager.warningColor, themeManager.errorColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(4)
                        }
                    }

                    if savingsPercent > 0 {
                        Text("وفّر \(savingsPercent)%")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.successColor)
                    }
                }

                Spacer()

                // Price
                Text(product.localizedPrice)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeManager.textPrimaryColor)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? themeManager.primaryColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(product.isLifetime ? "مدى الحياة" : product.periodText)، \(product.localizedPrice)\(badge != nil ? "، \(badge!)" : "")")
        .accessibilityValue(isSelected ? "محدد" : "غير محدد")
        .accessibilityHint("اضغط مرتين للاختيار")
    }
}

// MARK: - Preview

#Preview {
    PaywallSheet()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
}
