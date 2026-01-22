//
//  SettingsView.swift
//  Mizan
//
//  Enhanced settings with grouped cards and animated components
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showPaywall = false
    @State private var showClearDataAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: MZSpacing.lg) {
                    // Pro Section
                    if !appEnvironment.userSettings.isPro {
                        ProUpgradeCard {
                            showPaywall = true
                        }
                        .environmentObject(themeManager)
                        .accessibilityIdentifier("settings_pro_upgrade_card")
                    } else {
                        // Pro badge for subscribers
                        SettingsCard {
                            HStack(spacing: MZSpacing.md) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("ميزان Pro")
                                        .font(MZTypography.titleMedium)
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("شكرًا لدعمك!")
                                        .font(MZTypography.labelMedium)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                                Spacer()
                            }
                            .padding(MZSpacing.md)
                        }
                        .environmentObject(themeManager)
                        .accessibilityIdentifier("settings_pro_badge")

                        // Gamification Section (Pro only)
                        VStack(alignment: .leading, spacing: MZSpacing.sm) {
                            SettingsSectionHeader(icon: "chart.line.uptrend.xyaxis", title: "التقدم", iconColor: themeManager.successColor)
                                .environmentObject(themeManager)

                            SettingsCard {
                                NavigationLink {
                                    GamificationDashboardView()
                                        .environmentObject(appEnvironment)
                                        .environmentObject(themeManager)
                                } label: {
                                    HStack(spacing: MZSpacing.md) {
                                        // Orbit level badge
                                        ZStack {
                                            Circle()
                                                .fill(themeManager.primaryColor)
                                                .frame(width: 32, height: 32)
                                            Text("\(appEnvironment.progressionService.currentOrbit)")
                                                .font(MZTypography.labelMedium)
                                                .foregroundColor(themeManager.textOnPrimaryColor)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("المدار والتقدم")
                                                .font(MZTypography.bodyLarge)
                                                .foregroundColor(themeManager.textPrimaryColor)

                                            if let orbit = appEnvironment.progressionService.getCurrentOrbitConfig() {
                                                Text(orbit.localizedTitle)
                                                    .font(MZTypography.labelSmall)
                                                    .foregroundColor(themeManager.textSecondaryColor)
                                            }
                                        }

                                        Spacer()

                                        // Mass display
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("\(Int(appEnvironment.progressionService.currentMass))")
                                                .font(MZTypography.dataMedium)
                                                .foregroundColor(themeManager.primaryColor)
                                            Text("Mass")
                                                .font(MZTypography.labelSmall)
                                                .foregroundColor(themeManager.textTertiaryColor)
                                        }

                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 14))
                                            .foregroundColor(themeManager.textTertiaryColor)
                                    }
                                    .padding(MZSpacing.md)
                                }
                                .buttonStyle(.plain)
                            }
                            .environmentObject(themeManager)
                        }
                    }

                    // Prayer & Notifications Section
                    VStack(alignment: .leading, spacing: MZSpacing.sm) {
                        SettingsSectionHeader(icon: "moon.fill", title: "الصلاة والإشعارات", iconColor: themeManager.primaryColor)
                            .environmentObject(themeManager)

                        SettingsCard {
                            NavigationLink {
                                PrayerSettingsView()
                                    .environmentObject(appEnvironment)
                                    .environmentObject(themeManager)
                            } label: {
                                SettingsRow(icon: "clock.fill", iconColor: themeManager.infoColor, title: "طريقة الحساب", subtitle: "تخصيص أوقات الصلاة")
                                    .environmentObject(themeManager)
                            }
                            .buttonStyle(.plain)

                            SettingsDivider().environmentObject(themeManager)

                            NavigationLink {
                                NotificationSettingsView()
                                    .environmentObject(appEnvironment)
                                    .environmentObject(themeManager)
                            } label: {
                                SettingsRow(icon: "bell.badge.fill", iconColor: themeManager.errorColor, title: "الإشعارات", subtitle: "تنبيهات الأذان والمهام")
                                    .environmentObject(themeManager)
                            }
                            .buttonStyle(.plain)

                            SettingsDivider().environmentObject(themeManager)

                            NavigationLink {
                                NawafilSettingsView()
                                    .environmentObject(appEnvironment)
                                    .environmentObject(themeManager)
                            } label: {
                                SettingsRow(
                                    icon: "moon.stars.fill",
                                    iconColor: themeManager.primaryColor,
                                    title: "النوافل",
                                    subtitle: "السنن والرواتب",
                                    showProBadge: !appEnvironment.userSettings.isPro
                                )
                                .environmentObject(themeManager)
                            }
                            .buttonStyle(.plain)
                        }
                        .environmentObject(themeManager)
                    }

                    // Appearance Section
                    VStack(alignment: .leading, spacing: MZSpacing.sm) {
                        SettingsSectionHeader(icon: "paintbrush.fill", title: "المظهر", iconColor: themeManager.primaryColor)
                            .environmentObject(themeManager)

                        SettingsCard {
                            // Hijri Date Toggle
                            HStack {
                                HStack(spacing: MZSpacing.sm) {
                                    Image(systemName: "moon.stars.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(themeManager.primaryColor)
                                        .frame(width: 32, height: 32)
                                        .background(themeManager.primaryColor.opacity(0.15))
                                        .cornerRadius(8)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("التاريخ الهجري")
                                            .font(MZTypography.bodyLarge)
                                            .foregroundColor(themeManager.textPrimaryColor)
                                        Text("عرض التاريخ الهجري في الجدول")
                                            .font(MZTypography.labelSmall)
                                            .foregroundColor(themeManager.textSecondaryColor)
                                    }
                                }

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { appEnvironment.userSettings.showHijriDate },
                                    set: { newValue in
                                        appEnvironment.userSettings.showHijriDate = newValue
                                        appEnvironment.save()
                                        HapticManager.shared.trigger(.selection)
                                    }
                                ))
                                .tint(themeManager.primaryColor)
                                .labelsHidden()
                                .accessibilityLabel("التاريخ الهجري")
                                .accessibilityValue(appEnvironment.userSettings.showHijriDate ? "مفعّل" : "متوقف")
                                .accessibilityIdentifier("settings_hijri_toggle")
                            }
                            .padding(MZSpacing.md)
                        }
                        .environmentObject(themeManager)
                    }

                    // About & Data Section
                    VStack(alignment: .leading, spacing: MZSpacing.sm) {
                        SettingsSectionHeader(icon: "info.circle.fill", title: "عام", iconColor: themeManager.textSecondaryColor)
                            .environmentObject(themeManager)

                        SettingsCard {
                            NavigationLink {
                                AboutView()
                                    .environmentObject(appEnvironment)
                                    .environmentObject(themeManager)
                            } label: {
                                SettingsRow(icon: "info.circle.fill", iconColor: themeManager.textSecondaryColor, title: "عن التطبيق")
                                    .environmentObject(themeManager)
                            }
                            .buttonStyle(.plain)

                            SettingsDivider().environmentObject(themeManager)

                            Button {
                                showClearDataAlert = true
                                HapticManager.shared.trigger(.warning)
                            } label: {
                                SettingsRow(icon: "arrow.clockwise", iconColor: themeManager.warningColor, title: "إعادة تحميل البيانات", subtitle: "تحديث أوقات الصلاة", showChevron: false)
                                    .environmentObject(themeManager)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                        .environmentObject(themeManager)
                    }

                    // Version
                    Text("الإصدار 1.0.0")
                        .font(MZTypography.labelSmall)
                        .foregroundColor(themeManager.textTertiaryColor)
                        .padding(.top, MZSpacing.md)
                }
                .padding(MZSpacing.screenPadding)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallSheet()
                    .environmentObject(appEnvironment)
                    .environmentObject(themeManager)
            }
            .alert("إعادة تحميل البيانات", isPresented: $showClearDataAlert) {
                Button("إلغاء", role: .cancel) { }
                Button("إعادة تحميل", role: .destructive) {
                    clearAndRefreshPrayerData()
                }
            } message: {
                Text("سيتم حذف بيانات الصلاة المحفوظة وإعادة تحميلها من الخادم. هذا قد يصلح مشاكل العرض.")
            }
        }
    }

    private func clearAndRefreshPrayerData() {
        // Clear all cached prayer data
        appEnvironment.prayerTimeService.clearCache()

        // Refresh prayers
        _Concurrency.Task {
            // First refresh today's prayers
            await appEnvironment.refreshPrayerTimes()

            // Also prefetch next 7 days so user can navigate
            if let lat = appEnvironment.userSettings.lastKnownLatitude,
               let lon = appEnvironment.userSettings.lastKnownLongitude {
                await appEnvironment.prayerTimeService.prefetchPrayerTimes(
                    days: 7,
                    latitude: lat,
                    longitude: lon,
                    method: appEnvironment.userSettings.calculationMethod
                )
            }

            // Regenerate nawafil
            appEnvironment.refreshNawafil()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
}
