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
                                SettingsRow(icon: "clock.fill", iconColor: .blue, title: "طريقة الحساب", subtitle: "تخصيص أوقات الصلاة")
                                    .environmentObject(themeManager)
                            }
                            .buttonStyle(.plain)

                            SettingsDivider().environmentObject(themeManager)

                            NavigationLink {
                                NotificationSettingsView()
                                    .environmentObject(appEnvironment)
                                    .environmentObject(themeManager)
                            } label: {
                                SettingsRow(icon: "bell.badge.fill", iconColor: .red, title: "الإشعارات", subtitle: "تنبيهات الأذان والمهام")
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
                                    iconColor: .purple,
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
                        SettingsSectionHeader(icon: "paintbrush.fill", title: "المظهر", iconColor: .pink)
                            .environmentObject(themeManager)

                        SettingsCard {
                            NavigationLink {
                                ThemeSelectionView()
                                    .environmentObject(appEnvironment)
                                    .environmentObject(themeManager)
                            } label: {
                                SettingsRow(icon: "circle.hexagongrid.fill", iconColor: .pink, title: "اختيار الثيم", subtitle: themeManager.currentTheme.name)
                                    .environmentObject(themeManager)
                            }
                            .buttonStyle(.plain)
                        }
                        .environmentObject(themeManager)
                    }

                    // About & Data Section
                    VStack(alignment: .leading, spacing: MZSpacing.sm) {
                        SettingsSectionHeader(icon: "info.circle.fill", title: "عام", iconColor: .gray)
                            .environmentObject(themeManager)

                        SettingsCard {
                            NavigationLink {
                                AboutView()
                                    .environmentObject(appEnvironment)
                                    .environmentObject(themeManager)
                            } label: {
                                SettingsRow(icon: "info.circle.fill", iconColor: .gray, title: "عن التطبيق")
                                    .environmentObject(themeManager)
                            }
                            .buttonStyle(.plain)

                            SettingsDivider().environmentObject(themeManager)

                            Button {
                                showClearDataAlert = true
                                HapticManager.shared.trigger(.warning)
                            } label: {
                                SettingsRow(icon: "arrow.clockwise", iconColor: .orange, title: "إعادة تحميل البيانات", subtitle: "تحديث أوقات الصلاة", showChevron: false)
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
