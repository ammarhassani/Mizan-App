//
//  AboutView.swift
//  Mizan
//
//  App information and links
//

import SwiftUI

struct AboutView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon & Name
                appHeader

                // Version Info
                versionSection

                // Links
                linksSection

                // Developer Info
                developerSection

                // Legal
                legalSection

                // Debug (only in DEBUG builds)
                #if DEBUG
                debugSection
                #endif

                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle("عن التطبيق")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - App Header

    @ViewBuilder
    private var appHeader: some View {
        VStack(spacing: 12) {
            // App Icon
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.prayerGradient)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 36))
                        .foregroundColor(themeManager.textOnPrimaryColor)
                )

            // App Name
            Text("ميزان")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(themeManager.textPrimaryColor)

            Text("Mizan")
                .font(.system(size: 16))
                .foregroundColor(themeManager.textSecondaryColor)

            // Tagline
            Text("نظّم يومك حول صلاتك")
                .font(.system(size: 15))
                .foregroundColor(themeManager.textSecondaryColor)
                .padding(.top, 4)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Version Section

    @ViewBuilder
    private var versionSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("الإصدار")
                    .foregroundColor(themeManager.textSecondaryColor)
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .foregroundColor(themeManager.textPrimaryColor)
            }

            if appEnvironment.userSettings.isPro {
                HStack {
                    Text("الاشتراك")
                        .foregroundColor(themeManager.textSecondaryColor)
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Pro")
                            .foregroundColor(themeManager.primaryColor)
                            .fontWeight(.semibold)
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(themeManager.primaryColor)
                    }
                }
            }
        }
        .font(.system(size: 15))
        .padding(16)
        .background(themeManager.surfaceColor)
        .cornerRadius(12)
    }

    // MARK: - Links Section

    @ViewBuilder
    private var linksSection: some View {
        VStack(spacing: 0) {
            linkRow(
                icon: "star.fill",
                title: "قيّم التطبيق",
                subtitle: "ساعدنا بتقييمك",
                action: { openAppStore() }
            )

            Divider()
                .background(themeManager.dividerColor)
                .padding(.leading, 52)

            linkRow(
                icon: "square.and.arrow.up",
                title: "شارك التطبيق",
                subtitle: "أخبر أصدقاءك عن ميزان",
                action: { shareApp() }
            )

            Divider()
                .background(themeManager.dividerColor)
                .padding(.leading, 52)

            linkRow(
                icon: "envelope.fill",
                title: "تواصل معنا",
                subtitle: "أرسل ملاحظاتك واقتراحاتك",
                action: { sendFeedback() }
            )

            Divider()
                .background(themeManager.dividerColor)
                .padding(.leading, 52)

            linkRow(
                icon: "questionmark.circle.fill",
                title: "المساعدة",
                subtitle: "الأسئلة الشائعة والدعم",
                action: { openHelp() }
            )
        }
        .background(themeManager.surfaceColor)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func linkRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.primaryColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.textPrimaryColor)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.textSecondaryColor)
                }

                Spacer()

                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            .padding(16)
        }
    }

    // MARK: - Developer Section

    @ViewBuilder
    private var developerSection: some View {
        VStack(spacing: 8) {
            Text("صُنع بـ ❤️ للمسلمين")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textSecondaryColor)

            Text("© 2024 Mizan App")
                .font(.system(size: 13))
                .foregroundColor(themeManager.textSecondaryColor.opacity(0.7))
        }
        .padding(.top, 8)
    }

    // MARK: - Debug Section (for testing)

    #if DEBUG
    @ViewBuilder
    private var debugSection: some View {
        VStack(spacing: 12) {
            Divider()
                .background(themeManager.dividerColor)
                .padding(.vertical, 8)

            Text("🛠️ Debug Options")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.warningColor)

            Toggle(isOn: Binding(
                get: { appEnvironment.userSettings.isPro },
                set: { newValue in
                    appEnvironment.userSettings.isPro = newValue
                    appEnvironment.save()
                    HapticManager.shared.trigger(.success)
                }
            )) {
                Text("Enable Pro (Testing)")
                    .font(.system(size: 14))
            }
            .tint(themeManager.warningColor)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 8)
        .background(themeManager.warningColor.opacity(0.1))
        .cornerRadius(12)
    }
    #endif

    // MARK: - Legal Section

    @ViewBuilder
    private var legalSection: some View {
        HStack(spacing: 16) {
            Button("سياسة الخصوصية") {
                openPrivacyPolicy()
            }
            .font(.system(size: 13))
            .foregroundColor(themeManager.primaryColor)

            Text("•")
                .foregroundColor(themeManager.textSecondaryColor)

            Button("شروط الاستخدام") {
                openTerms()
            }
            .font(.system(size: 13))
            .foregroundColor(themeManager.primaryColor)
        }
    }

    // MARK: - Actions

    private func openAppStore() {
        // Replace with actual App Store URL
        if let url = URL(string: "https://apps.apple.com/app/idXXXXXXXXX") {
            UIApplication.shared.open(url)
        }
    }

    private func shareApp() {
        let text = "جرّب تطبيق ميزان - نظّم يومك حول صلاتك\nhttps://apps.apple.com/app/idXXXXXXXXX"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func sendFeedback() {
        let email = "support@mizanapp.com"
        let subject = "ملاحظات على تطبيق ميزان v\(appVersion)"
        let body = "\n\n---\nالإصدار: \(appVersion) (\(buildNumber))\nالجهاز: \(UIDevice.current.model)\niOS: \(UIDevice.current.systemVersion)"

        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }

    private func openHelp() {
        // Replace with actual help URL
        if let url = URL(string: "https://mizanapp.com/help") {
            UIApplication.shared.open(url)
        }
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://mizanapp.com/privacy") {
            UIApplication.shared.open(url)
        }
    }

    private func openTerms() {
        if let url = URL(string: "https://mizanapp.com/terms") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        AboutView()
            .environmentObject(AppEnvironment.preview())
            .environmentObject(AppEnvironment.preview().themeManager)
    }
}
