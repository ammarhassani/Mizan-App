//
//  PrayerSettingsView.swift
//  Mizan
//
//  Prayer time configuration and manual adjustments
//

import SwiftUI
import SwiftData

struct PrayerSettingsView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    @State private var showMethodPicker = false
    @State private var refreshingPrayers = false

    @Query(sort: \PrayerTime.adhanTime) private var allPrayers: [PrayerTime]

    private var todayPrayers: [PrayerTime] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return allPrayers.filter { prayer in
            prayer.date >= today && prayer.date < tomorrow
        }
    }

    var body: some View {
        Form {
            // Calculation Method Section
            Section {
                Button {
                    showMethodPicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("طريقة الحساب")
                                .font(.system(size: 15))
                                .foregroundColor(themeManager.textSecondaryColor)

                            Text(appEnvironment.userSettings.calculationMethod.nameArabic)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(themeManager.textPrimaryColor)
                        }

                        Spacer()

                        Image(systemName: "chevron.left")
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }

                Button {
                    _Concurrency.Task {
                        await refreshPrayerTimes()
                    }
                } label: {
                    HStack {
                        if refreshingPrayers {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(themeManager.primaryColor)
                        }
                        Text("تحديث أوقات الصلاة")
                            .foregroundColor(themeManager.textPrimaryColor)
                    }
                }
                .disabled(refreshingPrayers)
            } header: {
                Text("الإعدادات")
            }

            // Manual Adjustments Section
            Section {
                ForEach(todayPrayers) { prayer in
                    PrayerAdjustmentRow(prayer: prayer)
                        .environmentObject(themeManager)
                }
            } header: {
                Text("تعديل يدوي (±دقائق)")
            } footer: {
                Text("استخدم التعديل اليدوي إذا كانت الأوقات غير دقيقة في منطقتك")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.textSecondaryColor)
            }

            // Location Section
            if let lat = appEnvironment.userSettings.lastKnownLatitude,
               let lon = appEnvironment.userSettings.lastKnownLongitude {
                Section("الموقع") {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(themeManager.primaryColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("الإحداثيات")
                                .font(.system(size: 15))
                                .foregroundColor(themeManager.textSecondaryColor)
                            Text(String(format: "%.4f, %.4f", lat, lon))
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle("أوقات الصلاة")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMethodPicker) {
            CalculationMethodPicker()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
        }
    }

    // MARK: - Actions

    private func refreshPrayerTimes() async {
        refreshingPrayers = true
        await appEnvironment.refreshPrayerTimes()
        refreshingPrayers = false
        HapticManager.shared.trigger(.success)
    }
}

// MARK: - Prayer Adjustment Row

struct PrayerAdjustmentRow: View {
    let prayer: PrayerTime

    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 16) {
            // Prayer icon and name
            HStack(spacing: 12) {
                Image(systemName: prayer.prayerType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: prayer.colorHex))
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(prayer.displayName)
                        .font(.system(size: 16, weight: .semibold))
                    Text(prayer.adhanTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            Spacer()

            // Adjustment controls
            HStack(spacing: 8) {
                Button {
                    adjustPrayer(by: -1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.primaryColor)
                }

                Text("\(prayer.manualOffset > 0 ? "+" : "")\(prayer.manualOffset)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(themeManager.textPrimaryColor)
                    .frame(width: 40)

                Button {
                    adjustPrayer(by: 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.primaryColor)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func adjustPrayer(by minutes: Int) {
        prayer.manualOffset += minutes
        prayer.manualOffset = max(-30, min(30, prayer.manualOffset)) // Clamp to ±30 min
        try? modelContext.save()
        HapticManager.shared.trigger(.selection)
    }
}

// MARK: - Calculation Method Picker

struct CalculationMethodPicker: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(CalculationMethod.allCases, id: \.self) { method in
                    Button {
                        selectMethod(method)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(method.nameArabic)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(themeManager.textPrimaryColor)

                                Text(method.nameEnglish)
                                    .font(.system(size: 14))
                                    .foregroundColor(themeManager.textSecondaryColor)
                            }

                            Spacer()

                            if method == appEnvironment.userSettings.calculationMethod {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(themeManager.primaryColor)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("طريقة الحساب")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("تم") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func selectMethod(_ method: CalculationMethod) {
        appEnvironment.userSettings.updateCalculationMethod(method)
        appEnvironment.save()

        _Concurrency.Task {
            await appEnvironment.refreshPrayerTimes()
        }

        HapticManager.shared.trigger(.success)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    PrayerSettingsView()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
}
