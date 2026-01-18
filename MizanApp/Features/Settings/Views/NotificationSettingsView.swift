//
//  NotificationSettingsView.swift
//  Mizan
//
//  Notification settings and preferences
//

import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showAdhanPicker = false

    private var notificationManager: NotificationManager {
        appEnvironment.notificationManager
    }

    private var userSettings: UserSettings {
        appEnvironment.userSettings
    }

    private var notificationsEnabled: Binding<Bool> {
        Binding(
            get: { userSettings.notificationsEnabled },
            set: { newValue in
                userSettings.notificationsEnabled = newValue
                appEnvironment.save()
                HapticManager.shared.trigger(.selection)

                if newValue {
                    // Reschedule notifications when enabled
                    _Concurrency.Task {
                        await rescheduleAllNotifications()
                    }
                } else {
                    // Remove all notifications when disabled
                    notificationManager.removeAllNotifications()
                }
            }
        )
    }

    private var prayerNotificationsEnabled: Binding<Bool> {
        Binding(
            get: { userSettings.prayerNotificationsEnabled },
            set: { newValue in
                userSettings.prayerNotificationsEnabled = newValue
                appEnvironment.save()
                HapticManager.shared.trigger(.selection)

                _Concurrency.Task {
                    if newValue {
                        await notificationManager.schedulePrayerNotifications(
                            for: appEnvironment.prayerTimeService.todayPrayers,
                            userSettings: userSettings
                        )
                    } else {
                        notificationManager.removeAllPrayerNotifications()
                    }
                }
            }
        )
    }

    private var taskNotificationsEnabled: Binding<Bool> {
        Binding(
            get: { userSettings.taskNotificationsEnabled },
            set: { newValue in
                userSettings.taskNotificationsEnabled = newValue
                appEnvironment.save()
                HapticManager.shared.trigger(.selection)

                if !newValue {
                    notificationManager.removeAllTaskNotifications()
                }
            }
        )
    }

    var body: some View {
        Form {
            // Authorization Status Section
            authorizationSection

            // Master Toggle Section
            masterToggleSection

            if userSettings.notificationsEnabled {
                // Prayer Notifications Section
                prayerNotificationsSection

                // Task Notifications Section
                taskNotificationsSection

                // Adhan Sound Section
                adhanSoundSection

                // Test Notifications Section (Debug)
                #if DEBUG
                testNotificationsSection
                #endif
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle("الإشعارات")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdhanPicker) {
            AdhanSoundPicker()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
        }
        .onAppear {
            _Concurrency.Task {
                await notificationManager.checkAuthorizationStatus()
            }
        }
    }

    // MARK: - Authorization Section

    @ViewBuilder
    private var authorizationSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: authorizationIcon)
                    .font(.system(size: 24))
                    .foregroundColor(authorizationColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("حالة الإذن")
                        .font(.system(size: 15))
                        .foregroundColor(themeManager.textSecondaryColor)

                    Text(authorizationStatusText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.textPrimaryColor)
                }

                Spacer()

                if notificationManager.authorizationStatus == .denied {
                    Button {
                        openSettings()
                    } label: {
                        Text("فتح الإعدادات")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.textOnPrimaryColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(themeManager.primaryColor)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.vertical, 4)
        } footer: {
            if notificationManager.authorizationStatus == .denied {
                Text("يجب تفعيل الإشعارات من إعدادات الجهاز للحصول على تنبيهات الصلاة والمهام")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.textSecondaryColor)
            }
        }
    }

    private var authorizationIcon: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        default:
            return "bell.circle.fill"
        }
    }

    private var authorizationColor: Color {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return themeManager.successColor
        case .denied:
            return themeManager.errorColor
        case .notDetermined:
            return themeManager.warningColor
        default:
            return themeManager.primaryColor
        }
    }

    private var authorizationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "مفعّل"
        case .denied:
            return "مرفوض"
        case .notDetermined:
            return "غير محدد"
        case .provisional:
            return "مؤقت"
        case .ephemeral:
            return "مؤقت"
        @unknown default:
            return "غير معروف"
        }
    }

    // MARK: - Master Toggle Section

    @ViewBuilder
    private var masterToggleSection: some View {
        Section {
            Toggle(isOn: notificationsEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.primaryColor)
                        .frame(width: 28)

                    Text("تفعيل الإشعارات")
                        .font(.system(size: 17))
                }
            }
            .tint(themeManager.primaryColor)
        } header: {
            Text("عام")
        } footer: {
            Text("تفعيل أو إيقاف جميع إشعارات التطبيق")
                .font(.system(size: 13))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }

    // MARK: - Prayer Notifications Section

    @ViewBuilder
    private var prayerNotificationsSection: some View {
        Section {
            Toggle(isOn: prayerNotificationsEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.primaryColor)
                        .frame(width: 28)

                    Text("إشعارات الصلاة")
                        .font(.system(size: 17))
                }
            }
            .tint(themeManager.primaryColor)

            if userSettings.prayerNotificationsEnabled {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.primaryColor)
                            .frame(width: 28)

                        Text("التذكير قبل الأذان")
                            .font(.system(size: 17))
                    }

                    Spacer()

                    Picker("", selection: Binding(
                        get: { userSettings.prayerReminderMinutes },
                        set: { newValue in
                            userSettings.prayerReminderMinutes = newValue
                            appEnvironment.save()
                            HapticManager.shared.trigger(.selection)
                        }
                    )) {
                        Text("5 دقائق").tag(5)
                        Text("10 دقائق").tag(10)
                        Text("15 دقيقة").tag(15)
                        Text("30 دقيقة").tag(30)
                    }
                    .pickerStyle(.menu)
                    .tint(themeManager.primaryColor)
                }
            }
        } header: {
            Text("الصلاة")
        } footer: {
            Text("ستتلقى إشعارًا قبل الأذان، وعند الأذان، وعند الإقامة")
                .font(.system(size: 13))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }

    // MARK: - Task Notifications Section

    @ViewBuilder
    private var taskNotificationsSection: some View {
        Section {
            Toggle(isOn: taskNotificationsEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.primaryColor)
                        .frame(width: 28)

                    Text("إشعارات المهام")
                        .font(.system(size: 17))
                }
            }
            .tint(themeManager.primaryColor)

            if userSettings.taskNotificationsEnabled {
                // Pro feature: Reminder before task
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(userSettings.isPro ? themeManager.primaryColor : themeManager.textSecondaryColor)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("التذكير قبل المهمة")
                                    .font(.system(size: 17))
                                    .foregroundColor(userSettings.isPro ? themeManager.textPrimaryColor : themeManager.textSecondaryColor)

                                if !userSettings.isPro {
                                    ProBadge()
                                        .environmentObject(themeManager)
                                }
                            }

                            if !userSettings.isPro {
                                Text("ميزة Pro")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.textSecondaryColor)
                            }
                        }
                    }

                    Spacer()

                    if userSettings.isPro {
                        Picker("", selection: Binding(
                            get: { userSettings.taskReminderMinutes },
                            set: { newValue in
                                userSettings.taskReminderMinutes = newValue
                                appEnvironment.save()
                                HapticManager.shared.trigger(.selection)
                            }
                        )) {
                            Text("5 دقائق").tag(5)
                            Text("10 دقائق").tag(10)
                            Text("15 دقيقة").tag(15)
                            Text("30 دقيقة").tag(30)
                        }
                        .pickerStyle(.menu)
                        .tint(themeManager.primaryColor)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }
            }
        } header: {
            Text("المهام")
        } footer: {
            Text("ستتلقى إشعارًا عند وقت بدء المهمة المجدولة")
                .font(.system(size: 13))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }

    // MARK: - Adhan Sound Section

    @ViewBuilder
    private var adhanSoundSection: some View {
        Section {
            Button {
                showAdhanPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.primaryColor)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("صوت الأذان")
                            .font(.system(size: 17))
                            .foregroundColor(themeManager.textPrimaryColor)

                        Text(currentAdhanName)
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.textSecondaryColor)
                    }

                    Spacer()

                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }
        } header: {
            Text("صوت الأذان")
        }
    }

    private var currentAdhanName: String {
        let adhanOptions = ConfigurationManager.shared.notificationConfig.sounds.adhanOptions
        let selectedId = userSettings.selectedAdhanAudio.replacingOccurrences(of: ".mp3", with: "")

        if let adhan = adhanOptions.first(where: { $0.id == selectedId || $0.filename == userSettings.selectedAdhanAudio }) {
            return adhan.nameArabic
        }
        return "الأذان الافتراضي"
    }

    // MARK: - Test Notifications Section

    #if DEBUG
    @ViewBuilder
    private var testNotificationsSection: some View {
        Section {
            Button {
                _Concurrency.Task {
                    await notificationManager.scheduleTestNotifications(userSettings: userSettings)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.warningColor)
                        .frame(width: 28)

                    Text("اختبار الإشعارات")
                        .font(.system(size: 17))
                        .foregroundColor(themeManager.textPrimaryColor)

                    Spacer()
                }
            }
        } header: {
            Text("اختبار")
        } footer: {
            Text("سيتم إرسال 3 إشعارات تجريبية بعد 10 و 20 و 30 ثانية")
                .font(.system(size: 13))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }
    #endif

    // MARK: - Actions

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func rescheduleAllNotifications() async {
        // Reschedule prayer notifications
        if userSettings.prayerNotificationsEnabled {
            await notificationManager.schedulePrayerNotifications(
                for: appEnvironment.prayerTimeService.todayPrayers,
                userSettings: userSettings
            )
        }
    }
}

// MARK: - Pro Badge

struct ProBadge: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(themeManager.textOnPrimaryColor)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                LinearGradient(
                    colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(4)
    }
}

// MARK: - Adhan Sound Picker

struct AdhanSoundPicker: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var playingAdhanId: String?

    private var adhanOptions: [AdhanOption] {
        ConfigurationManager.shared.notificationConfig.sounds.adhanOptions
    }

    private var userSettings: UserSettings {
        appEnvironment.userSettings
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(adhanOptions) { adhan in
                    AdhanOptionRow(
                        adhan: adhan,
                        isSelected: isSelected(adhan),
                        isPlaying: playingAdhanId == adhan.id,
                        onSelect: { selectAdhan(adhan) },
                        onPlayToggle: { togglePlay(adhan) }
                    )
                    .environmentObject(themeManager)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("اختيار صوت الأذان")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("تم") {
                        stopAllPlayback()
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            stopAllPlayback()
        }
    }

    private func isSelected(_ adhan: AdhanOption) -> Bool {
        let selectedId = userSettings.selectedAdhanAudio.replacingOccurrences(of: ".mp3", with: "")
        return adhan.id == selectedId || adhan.filename == userSettings.selectedAdhanAudio
    }

    private func selectAdhan(_ adhan: AdhanOption) {
        // Check if Pro is required
        if adhan.pro && !userSettings.isPro {
            HapticManager.shared.trigger(.warning)
            return
        }

        userSettings.selectedAdhanAudio = adhan.filename
        appEnvironment.save()
        HapticManager.shared.trigger(.success)
    }

    private func togglePlay(_ adhan: AdhanOption) {
        if playingAdhanId == adhan.id {
            stopAllPlayback()
        } else {
            playingAdhanId = adhan.id
            appEnvironment.notificationManager.playAdhan(style: adhan.id)
        }
    }

    private func stopAllPlayback() {
        playingAdhanId = nil
        appEnvironment.notificationManager.stopAdhan()
    }
}

// MARK: - Adhan Option Row

struct AdhanOptionRow: View {
    let adhan: AdhanOption
    let isSelected: Bool
    let isPlaying: Bool
    let onSelect: () -> Void
    let onPlayToggle: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appEnvironment: AppEnvironment

    private var isLocked: Bool {
        adhan.pro && !appEnvironment.userSettings.isPro
    }

    private var isAudioAvailable: Bool {
        appEnvironment.notificationManager.isAdhanAvailable(id: adhan.id)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Play button (preview available for all users)
            Button {
                if isAudioAvailable {
                    onPlayToggle()
                }
            } label: {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(!isAudioAvailable ? themeManager.disabledColor : themeManager.primaryColor)
            }
            .buttonStyle(.plain)
            .disabled(!isAudioAvailable)

            // Adhan info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(adhan.nameArabic)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isLocked ? themeManager.textSecondaryColor : themeManager.textPrimaryColor)

                    if adhan.pro {
                        ProBadge()
                    }
                }

                if !isAudioAvailable {
                    Text("الملف غير متوفر")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.warningColor)
                } else {
                    Text(adhan.nameEnglish)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            Spacer()

            // Selection/Lock indicator
            if isLocked {
                Image(systemName: "lock.fill")
                    .foregroundColor(themeManager.textSecondaryColor)
            } else {
                Button {
                    onSelect()
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? themeManager.primaryColor : themeManager.textSecondaryColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isLocked {
                onSelect()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NotificationSettingsView()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
}
