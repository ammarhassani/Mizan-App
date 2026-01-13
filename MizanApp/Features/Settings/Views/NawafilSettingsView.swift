//
//  NawafilSettingsView.swift
//  Mizan
//
//  Nawafil (voluntary prayers) settings - Pro feature
//

import SwiftUI

struct NawafilSettingsView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager

    private var userSettings: UserSettings {
        appEnvironment.userSettings
    }

    private var nawafilTypes: [NawafilType] {
        ConfigurationManager.shared.nawafilConfig.nawafilTypes
    }

    private var rawatibTypes: [String] {
        ConfigurationManager.shared.nawafilConfig.rawatib.types
    }

    private var isPro: Bool {
        userSettings.isPro
    }

    // Separate nawafil into categories
    private var rawatibNawafil: [NawafilType] {
        nawafilTypes.filter { rawatibTypes.contains($0.type) }
    }

    private var otherNawafil: [NawafilType] {
        nawafilTypes.filter { !rawatibTypes.contains($0.type) }
    }

    var body: some View {
        Form {
            // Pro Feature Notice (if not Pro)
            if !isPro {
                proNoticeSection
            }

            // Master Toggle
            masterToggleSection

            if isPro && userSettings.nawafilEnabled {
                // Rawatib Section
                rawatibSection

                // Other Nawafil Section
                otherNawafilSection
            }
        }
        .navigationTitle("النوافل")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pro Notice Section

    @ViewBuilder
    private var proNoticeSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text("ميزة Pro")
                        .font(.system(size: 17, weight: .semibold))

                    Text("اشترك في Pro لتفعيل النوافل وإضافتها للجدول")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Master Toggle Section

    @ViewBuilder
    private var masterToggleSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isPro ? themeManager.primaryColor : .gray)
                    .frame(width: 32)

                Toggle(isOn: Binding(
                    get: { userSettings.nawafilEnabled },
                    set: { newValue in
                        if isPro {
                            userSettings.nawafilEnabled = newValue
                            appEnvironment.save()
                            appEnvironment.refreshNawafil()
                            HapticManager.shared.trigger(.selection)
                        }
                    }
                )) {
                    Text("تفعيل النوافل")
                        .font(.system(size: 17))
                        .foregroundColor(isPro ? themeManager.textPrimaryColor : .gray)
                }
                .disabled(!isPro)
                .tint(themeManager.primaryColor)
            }
        } header: {
            Text("عام")
        } footer: {
            Text("عند التفعيل، ستظهر النوافل المختارة في الجدول اليومي")
                .font(.system(size: 13))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }

    // MARK: - Rawatib Section

    @ViewBuilder
    private var rawatibSection: some View {
        Section {
            // Toggle All Rawatib
            Toggle(isOn: Binding(
                get: { areAllRawatibEnabled },
                set: { newValue in
                    toggleAllRawatib(enabled: newValue)
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("جميع السنن الرواتب")
                        .font(.system(size: 17, weight: .medium))

                    Text("12 ركعة يوميًا")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }
            .tint(themeManager.primaryColor)

            // Individual Rawatib
            ForEach(rawatibNawafil) { nawafil in
                NawafilToggleRow(nawafil: nawafil)
                    .environmentObject(appEnvironment)
                    .environmentObject(themeManager)
            }
        } header: {
            Text("السنن الرواتب")
        } footer: {
            Text("السنن الرواتب هي الصلوات المرتبطة بالفرائض الخمس")
                .font(.system(size: 13))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }

    // MARK: - Other Nawafil Section

    @ViewBuilder
    private var otherNawafilSection: some View {
        Section {
            ForEach(otherNawafil) { nawafil in
                NawafilToggleRow(nawafil: nawafil)
                    .environmentObject(appEnvironment)
                    .environmentObject(themeManager)
            }
        } header: {
            Text("نوافل أخرى")
        } footer: {
            Text("هذه النوافل اختيارية ويمكنك تفعيلها حسب رغبتك")
                .font(.system(size: 13))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }

    // MARK: - Helpers

    private var areAllRawatibEnabled: Bool {
        rawatibTypes.allSatisfy { userSettings.enabledNawafil.contains($0) }
    }

    private func toggleAllRawatib(enabled: Bool) {
        if enabled {
            // Add all rawatib types
            var newEnabled = userSettings.enabledNawafil
            for type in rawatibTypes {
                if !newEnabled.contains(type) {
                    newEnabled.append(type)
                }
            }
            userSettings.enabledNawafil = newEnabled
        } else {
            // Remove all rawatib types
            userSettings.enabledNawafil = userSettings.enabledNawafil.filter { !rawatibTypes.contains($0) }
        }
        appEnvironment.save()
        appEnvironment.refreshNawafil()
        HapticManager.shared.trigger(.selection)
    }
}

// MARK: - Nawafil Toggle Row

struct NawafilToggleRow: View {
    let nawafil: NawafilType

    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isExpanded = false
    @State private var selectedTime: Date = Date()

    private var userSettings: UserSettings {
        appEnvironment.userSettings
    }

    private var isEnabled: Bool {
        userSettings.enabledNawafil.contains(nawafil.type)
    }

    /// Whether this nawafil has configurable rakaat or time
    private var isConfigurable: Bool {
        nawafil.rakaat.userConfigurable == true ||
        nawafil.rakaat.options != nil ||
        (nawafil.rakaat.min != nil && nawafil.rakaat.max != nil) ||
        nawafil.durationOptions != nil ||
        hasConfigurableTime
    }

    /// Whether this nawafil has configurable time (non-attached nawafil)
    private var hasConfigurableTime: Bool {
        // Nawafil with free timing (not attached to a specific prayer)
        ["duha", "witr", "tahajjud"].contains(nawafil.type)
    }

    /// Current rakaat count (user preference or default)
    private var currentRakaat: Int {
        userSettings.nawafilRakaatPreferences[nawafil.type] ??
        nawafil.rakaat.default ??
        nawafil.rakaat.fixed ?? 2
    }

    /// Current time as minutes since midnight
    private var currentTimeMinutes: Int? {
        userSettings.nawafilTimePreferences[nawafil.type]
    }

    /// Get a display time for the current setting
    private var displayTimeString: String {
        if let minutes = currentTimeMinutes {
            return UserSettings.minutesToTimeString(minutes)
        }
        return defaultTimeString
    }

    /// Get the default time string based on nawafil type
    private var defaultTimeString: String {
        switch nawafil.type {
        case "duha":
            return "الوقت المقترح" // Mid-morning
        case "witr":
            return "بعد العشاء"
        case "tahajjud":
            return "الثلث الأخير"
        default:
            return ""
        }
    }

    var body: some View {
        if isConfigurable && isEnabled {
            // Expandable row with config
            DisclosureGroup(isExpanded: $isExpanded) {
                configurableContent
                    .padding(.top, 8)
            } label: {
                toggleRow
            }
        } else {
            // Simple toggle row
            toggleRow
        }
    }

    // MARK: - Toggle Row

    private var toggleRow: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: nawafil.icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: nawafil.colorHex))
                .frame(width: 28)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(nawafil.arabicName)
                    .font(.system(size: 16, weight: .medium))

                Text(rakaatText)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.textSecondaryColor)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    toggleNawafil(enabled: newValue)
                }
            ))
            .tint(themeManager.primaryColor)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Configurable Content

    @ViewBuilder
    private var configurableContent: some View {
        VStack(spacing: 12) {
            // Rakaat picker/stepper
            if let options = nawafil.rakaat.options {
                // Discrete options (e.g., Witr: 1, 3, 5, 7, 9, 11)
                rakaatPicker(options: options)
            } else if let min = nawafil.rakaat.min, let max = nawafil.rakaat.max {
                // Range stepper (e.g., Duha: 2-12, Tahajjud: 2-20)
                rakaatStepper(min: min, max: max)
            } else if let durationOptions = nawafil.durationOptions {
                // Duration picker for time blocks (e.g., Qiyam: 30, 60, 90, 120 min)
                durationPicker(options: durationOptions)
            }

            // Time picker for configurable nawafil
            if hasConfigurableTime {
                timePicker
            }

            // Time info
            timeInfoText
        }
        .padding(.vertical, 4)
    }

    // MARK: - Time Picker

    /// Get today's prayer times from the service
    private var todayPrayers: [PrayerTime] {
        appEnvironment.prayerTimeService.todayPrayers
    }

    /// Get valid time range for this nawafil type
    private var validTimeRange: ClosedRange<Date>? {
        let calendar = Calendar.current
        let today = Date()

        switch nawafil.type {
        case "duha":
            // Duha: from sunrise (~30 min after Fajr) until Dhuhr athan
            guard let fajr = todayPrayers.first(where: { $0.prayerType == .fajr }),
                  let dhuhr = todayPrayers.first(where: { $0.prayerType == .dhuhr }) else {
                return nil
            }
            // Sunrise is approximately 30 minutes after Fajr, add 15 min buffer
            let sunriseApprox = fajr.adhanTime.addingTimeInterval(45 * 60)
            // End 10 minutes before Dhuhr athan
            let dhuhrMinus10 = dhuhr.adhanTime.addingTimeInterval(-10 * 60)

            // Convert to today's date for the picker
            let startMinutes = UserSettings.dateToMinutesSinceMidnight(sunriseApprox)
            let endMinutes = UserSettings.dateToMinutesSinceMidnight(dhuhrMinus10)

            guard let startDate = calendar.date(bySettingHour: startMinutes / 60, minute: startMinutes % 60, second: 0, of: today),
                  let endDate = calendar.date(bySettingHour: endMinutes / 60, minute: endMinutes % 60, second: 0, of: today) else {
                return nil
            }
            return startDate...endDate

        case "witr":
            // Witr: after Isha until before Fajr (next morning)
            guard let isha = todayPrayers.first(where: { $0.prayerType == .isha }),
                  let fajr = todayPrayers.first(where: { $0.prayerType == .fajr }) else {
                return nil
            }
            // Start after Isha prayer ends (iqama end time + 10 min buffer)
            let ishaEnd = isha.iqamaEndTime.addingTimeInterval(10 * 60)
            // End 15 minutes before Fajr athan
            let fajrMinus15 = fajr.adhanTime.addingTimeInterval(-15 * 60)

            let startMinutes = UserSettings.dateToMinutesSinceMidnight(ishaEnd)
            var endMinutes = UserSettings.dateToMinutesSinceMidnight(fajrMinus15)

            // Handle overnight: if Fajr is before Isha (crossing midnight), we need to handle this specially
            // For the picker, we'll show two ranges: evening (after Isha) or early morning (before Fajr)
            // Since DatePicker doesn't support disjoint ranges, we'll use midnight split

            // If end is before start, Fajr is next day - allow full night range
            if endMinutes < startMinutes {
                // Allow from Isha end to 11:59 PM OR 12:00 AM to before Fajr
                // For simplicity, extend end to include early morning
                endMinutes += 24 * 60 // Add 24 hours worth of minutes (this is a workaround)
            }

            // For witr, allow evening hours (after isha) or early morning (before fajr)
            // We'll set a practical range: 8 PM to 5 AM
            guard let startDate = calendar.date(bySettingHour: max(20, startMinutes / 60), minute: 0, second: 0, of: today),
                  let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: today) else {
                return nil
            }
            return startDate...endDate

        case "tahajjud":
            // Tahajjud/Qiyam: last third of night (from ~1-2 AM until before Fajr)
            guard let fajr = todayPrayers.first(where: { $0.prayerType == .fajr }),
                  let maghrib = todayPrayers.first(where: { $0.prayerType == .maghrib }) else {
                return nil
            }

            // Calculate last third of night
            var nightDuration: TimeInterval
            if fajr.adhanTime < maghrib.adhanTime {
                let nextDayFajr = fajr.adhanTime.addingTimeInterval(24 * 60 * 60)
                nightDuration = nextDayFajr.timeIntervalSince(maghrib.adhanTime)
            } else {
                nightDuration = fajr.adhanTime.timeIntervalSince(maghrib.adhanTime)
            }

            // Last third starts at 2/3 of the night (calculated but not used as UI shows simplified midnight-to-fajr range)
            _ = UserSettings.dateToMinutesSinceMidnight(
                maghrib.adhanTime.addingTimeInterval(nightDuration * 2 / 3)
            )
            let fajrMinus15 = fajr.adhanTime.addingTimeInterval(-15 * 60)
            let endMinutes = UserSettings.dateToMinutesSinceMidnight(fajrMinus15)

            // For night prayers crossing midnight, use early morning hours (12 AM - before Fajr)
            guard let startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: today),
                  let endDate = calendar.date(bySettingHour: min(endMinutes / 60, 5), minute: endMinutes % 60, second: 0, of: today) else {
                return nil
            }
            return startDate...endDate

        default:
            return nil
        }
    }

    /// Human-readable time range description
    private var validTimeRangeDescription: String? {
        switch nawafil.type {
        case "duha":
            if let fajr = todayPrayers.first(where: { $0.prayerType == .fajr }),
               let dhuhr = todayPrayers.first(where: { $0.prayerType == .dhuhr }) {
                let sunrise = fajr.adhanTime.addingTimeInterval(45 * 60)
                let sunriseStr = sunrise.formatted(date: .omitted, time: .shortened)
                let dhuhrStr = dhuhr.adhanTime.formatted(date: .omitted, time: .shortened)
                return "من \(sunriseStr) إلى \(dhuhrStr)"
            }
        case "witr":
            if let isha = todayPrayers.first(where: { $0.prayerType == .isha }),
               let fajr = todayPrayers.first(where: { $0.prayerType == .fajr }) {
                let ishaEnd = isha.iqamaEndTime.addingTimeInterval(10 * 60)
                let ishaStr = ishaEnd.formatted(date: .omitted, time: .shortened)
                let fajrStr = fajr.adhanTime.formatted(date: .omitted, time: .shortened)
                return "من \(ishaStr) إلى \(fajrStr)"
            }
        case "tahajjud":
            if let fajr = todayPrayers.first(where: { $0.prayerType == .fajr }) {
                let fajrStr = fajr.adhanTime.formatted(date: .omitted, time: .shortened)
                return "حتى \(fajrStr)"
            }
        default:
            break
        }
        return nil
    }

    /// Whether prayer times are available for validation
    private var hasPrayerTimes: Bool {
        !todayPrayers.isEmpty
    }

    @ViewBuilder
    private var timePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("وقت البدء")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textSecondaryColor)

                Spacer()

                if currentTimeMinutes != nil {
                    // Show clear button when custom time is set
                    Button {
                        userSettings.nawafilTimePreferences.removeValue(forKey: nawafil.type)
                        appEnvironment.save()
                        appEnvironment.refreshNawafil()
                        HapticManager.shared.trigger(.selection)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.textSecondaryColor.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }

                if hasPrayerTimes, let range = validTimeRange {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: {
                                if let minutes = currentTimeMinutes {
                                    let calendar = Calendar.current
                                    return calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? defaultDateForTimePicker
                                }
                                return defaultDateForTimePicker
                            },
                            set: { newDate in
                                let minutes = UserSettings.dateToMinutesSinceMidnight(newDate)
                                userSettings.setTimeForNawafil(nawafil.type, minutesSinceMidnight: minutes)
                                appEnvironment.save()
                                appEnvironment.refreshNawafil()
                                HapticManager.shared.trigger(.selection)
                            }
                        ),
                        in: range,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .tint(Color(hex: nawafil.colorHex))
                } else {
                    // Fallback when no prayer times available
                    DatePicker(
                        "",
                        selection: Binding(
                            get: {
                                if let minutes = currentTimeMinutes {
                                    let calendar = Calendar.current
                                    return calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? defaultDateForTimePicker
                                }
                                return defaultDateForTimePicker
                            },
                            set: { newDate in
                                let minutes = UserSettings.dateToMinutesSinceMidnight(newDate)
                                userSettings.setTimeForNawafil(nawafil.type, minutesSinceMidnight: minutes)
                                appEnvironment.save()
                                appEnvironment.refreshNawafil()
                                HapticManager.shared.trigger(.selection)
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .tint(Color(hex: nawafil.colorHex))
                }
            }

            // Show valid time range
            if let rangeDesc = validTimeRangeDescription {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(rangeDesc)
                        .font(.system(size: 11))
                }
                .foregroundColor(Color(hex: nawafil.colorHex).opacity(0.8))
            }
        }
    }

    /// Default date for time picker based on nawafil type
    private var defaultDateForTimePicker: Date {
        let calendar = Calendar.current
        switch nawafil.type {
        case "duha":
            // Mid-morning: 9:00 AM
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        case "witr":
            // After Isha: 9:00 PM
            return calendar.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
        case "tahajjud":
            // Last third of night: 3:00 AM
            return calendar.date(bySettingHour: 3, minute: 0, second: 0, of: Date()) ?? Date()
        default:
            return Date()
        }
    }

    // Picker for discrete options
    private func rakaatPicker(options: [Int]) -> some View {
        HStack {
            Text("عدد الركعات")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textSecondaryColor)

            Spacer()

            Picker("", selection: Binding(
                get: { currentRakaat },
                set: { newValue in
                    userSettings.setRakaatForNawafil(nawafil.type, rakaat: newValue)
                    appEnvironment.save()
                    appEnvironment.refreshNawafil()
                    HapticManager.shared.trigger(.selection)
                }
            )) {
                ForEach(options, id: \.self) { count in
                    Text("\(count) ركعة").tag(count)
                }
            }
            .pickerStyle(.menu)
            .tint(Color(hex: nawafil.colorHex))
        }
    }

    // Stepper for range
    private func rakaatStepper(min: Int, max: Int) -> some View {
        let step = nawafil.rakaat.mustBeEven == true ? 2 : 1
        return HStack {
            Text("عدد الركعات")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textSecondaryColor)

            Spacer()

            Stepper(
                "\(currentRakaat) ركعة",
                value: Binding(
                    get: { currentRakaat },
                    set: { newValue in
                        userSettings.setRakaatForNawafil(nawafil.type, rakaat: newValue)
                        appEnvironment.save()
                        appEnvironment.refreshNawafil()
                        HapticManager.shared.trigger(.selection)
                    }
                ),
                in: min...max,
                step: step
            )
            .font(.system(size: 14, weight: .medium))
        }
    }

    // Duration picker for time blocks
    private func durationPicker(options: [Int]) -> some View {
        HStack {
            Text("المدة")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textSecondaryColor)

            Spacer()

            Picker("", selection: Binding(
                get: { nawafil.durationMinutes ?? options.first ?? 60 },
                set: { _ in
                    // Duration changes would require different storage
                    // For now, this is read-only display
                }
            )) {
                ForEach(options, id: \.self) { mins in
                    Text("\(mins) دقيقة").tag(mins)
                }
            }
            .pickerStyle(.menu)
            .tint(Color(hex: nawafil.colorHex))
            .disabled(true) // Duration changes not yet supported
        }
    }

    // Time info based on nawafil type
    @ViewBuilder
    private var timeInfoText: some View {
        switch nawafil.type {
        case "duha":
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                Text("من بعد الشروق حتى قبل الظهر")
                    .font(.system(size: 12))
            }
            .foregroundColor(themeManager.textSecondaryColor.opacity(0.8))

        case "tahajjud":
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                Text("من بعد العشاء حتى قبل الفجر")
                    .font(.system(size: 12))
            }
            .foregroundColor(themeManager.textSecondaryColor.opacity(0.8))

        case "witr":
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                Text("آخر صلاة في الليل")
                    .font(.system(size: 12))
            }
            .foregroundColor(themeManager.textSecondaryColor.opacity(0.8))

        default:
            EmptyView()
        }
    }

    // MARK: - Helpers

    private var rakaatText: String {
        if let fixed = nawafil.rakaat.fixed {
            return "\(fixed) ركعات"
        } else if nawafil.rakaat.options != nil || (nawafil.rakaat.min != nil && nawafil.rakaat.max != nil) {
            // Show user's current selection for configurable nawafil
            return "\(currentRakaat) ركعة"
        } else if nawafil.isTimeBlock == true {
            if let duration = nawafil.durationMinutes {
                return "\(duration) دقيقة"
            }
            return "وقت للعبادة"
        }
        return ""
    }

    private func toggleNawafil(enabled: Bool) {
        if enabled {
            if !userSettings.enabledNawafil.contains(nawafil.type) {
                userSettings.enabledNawafil.append(nawafil.type)
            }
        } else {
            userSettings.enabledNawafil.removeAll { $0 == nawafil.type }
        }
        appEnvironment.save()
        appEnvironment.refreshNawafil()
        HapticManager.shared.trigger(.selection)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        NawafilSettingsView()
            .environmentObject(AppEnvironment.preview())
            .environmentObject(AppEnvironment.preview().themeManager)
    }
}
