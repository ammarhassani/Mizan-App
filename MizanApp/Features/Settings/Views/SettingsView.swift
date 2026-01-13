import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showPaywall = false
    @State private var showClearDataAlert = false

    var body: some View {
        NavigationView {
            Form {
                // Pro Section (show upgrade if not Pro)
                if !appEnvironment.userSettings.isPro {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.yellow)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("الترقية إلى Pro")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(themeManager.textPrimaryColor)

                                    Text("ثيمات، نوافل، وميزات إضافية")
                                        .font(.system(size: 13))
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }

                                Spacer()

                                Image(systemName: "chevron.left")
                                    .foregroundColor(themeManager.textSecondaryColor)
                            }
                        }
                    }
                } else {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 24))
                                .foregroundColor(themeManager.primaryColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("ميزان Pro")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(themeManager.textPrimaryColor)

                                Text("شكرًا لدعمك!")
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.textSecondaryColor)
                            }
                        }
                    }
                }

                Section("أوقات الصلاة") {
                    NavigationLink("طريقة الحساب") {
                        PrayerSettingsView()
                            .environmentObject(appEnvironment)
                            .environmentObject(themeManager)
                    }
                }

                Section("الإشعارات") {
                    NavigationLink("إعدادات الإشعارات") {
                        NotificationSettingsView()
                            .environmentObject(appEnvironment)
                            .environmentObject(themeManager)
                    }
                }

                Section("النوافل") {
                    NavigationLink {
                        NawafilSettingsView()
                            .environmentObject(appEnvironment)
                            .environmentObject(themeManager)
                    } label: {
                        HStack {
                            Text("إعدادات النوافل")
                            Spacer()
                            if !appEnvironment.userSettings.isPro {
                                ProBadge()
                            }
                        }
                    }
                }

                Section("المظهر") {
                    NavigationLink("اختيار الثيم") {
                        ThemeSelectionView()
                            .environmentObject(appEnvironment)
                            .environmentObject(themeManager)
                    }
                }

                Section("عن التطبيق") {
                    NavigationLink("معلومات") {
                        AboutView()
                            .environmentObject(appEnvironment)
                            .environmentObject(themeManager)
                    }
                }

                Section("البيانات") {
                    Button {
                        showClearDataAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                            Text("إعادة تحميل بيانات الصلاة")
                                .foregroundColor(themeManager.textPrimaryColor)
                        }
                    }
                }
            }
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
