import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationView {
            Form {
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

                Section("المظهر") {
                    NavigationLink("اختيار الثيم") {
                        Text("Theme Selection - Coming Soon")
                    }
                }

                Section("عن التطبيق") {
                    NavigationLink("معلومات") {
                        AboutView()
                            .environmentObject(appEnvironment)
                    }
                }
            }
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
}
