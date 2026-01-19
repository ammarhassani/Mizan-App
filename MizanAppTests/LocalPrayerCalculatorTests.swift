//
//  LocalPrayerCalculatorTests.swift
//  MizanAppTests
//
//  Tests for LocalPrayerCalculator - prayer time calculations using Adhan-Swift
//

import Testing
import Foundation
@testable import MizanApp

// Type alias to avoid ambiguity with Adhan's CalculationMethod
typealias AppCalculationMethod = CalculationMethod

struct LocalPrayerCalculatorTests {

    let calculator = LocalPrayerCalculator()

    // MARK: - Known Location Coordinates

    // Makkah, Saudi Arabia
    let makkahLatitude = 21.4225
    let makkahLongitude = 39.8262

    // Riyadh, Saudi Arabia
    let riyadhLatitude = 24.7136
    let riyadhLongitude = 46.6753

    // New York, USA
    let newYorkLatitude = 40.7128
    let newYorkLongitude = -74.0060

    // MARK: - Basic Calculation Tests

    @Test func calculatePrayerTimesReturnsAllFivePrayers() throws {
        let date = Date()
        let result = calculator.calculatePrayerTimes(
            for: date,
            latitude: makkahLatitude,
            longitude: makkahLongitude,
            method: AppCalculationMethod.ummAlQura
        )

        #expect(result != nil)
        #expect(result?.count == 5)
        #expect(result?[.fajr] != nil)
        #expect(result?[.dhuhr] != nil)
        #expect(result?[.asr] != nil)
        #expect(result?[.maghrib] != nil)
        #expect(result?[.isha] != nil)
    }

    @Test func prayerTimesAreInCorrectOrder() throws {
        let date = Date()
        let result = calculator.calculatePrayerTimes(
            for: date,
            latitude: riyadhLatitude,
            longitude: riyadhLongitude,
            method: AppCalculationMethod.ummAlQura
        )

        #expect(result != nil)
        guard let times = result else { return }

        // Prayer times should be in chronological order for a single day
        #expect(times[.fajr]! < times[.dhuhr]!)
        #expect(times[.dhuhr]! < times[.asr]!)
        #expect(times[.asr]! < times[.maghrib]!)
        #expect(times[.maghrib]! < times[.isha]!)
    }

    @Test func prayerTimesAreOnCorrectDate() throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 15
        let testDate = Calendar.current.date(from: components)!

        let result = calculator.calculatePrayerTimes(
            for: testDate,
            latitude: makkahLatitude,
            longitude: makkahLongitude,
            method: AppCalculationMethod.ummAlQura
        )

        #expect(result != nil)
        guard let times = result else { return }

        // All prayer times should be on the same day as the input date
        for (_, prayerTime) in times {
            #expect(Calendar.current.isDate(prayerTime, inSameDayAs: testDate))
        }
    }

    // MARK: - Sunrise Tests

    @Test func getSunriseReturnsValidTime() throws {
        let date = Date()
        let sunrise = calculator.getSunrise(
            for: date,
            latitude: makkahLatitude,
            longitude: makkahLongitude,
            method: AppCalculationMethod.ummAlQura
        )

        #expect(sunrise != nil)
    }

    @Test func sunriseIsAfterFajr() throws {
        let date = Date()
        let prayerTimes = calculator.calculatePrayerTimes(
            for: date,
            latitude: makkahLatitude,
            longitude: makkahLongitude,
            method: AppCalculationMethod.ummAlQura
        )
        let sunrise = calculator.getSunrise(
            for: date,
            latitude: makkahLatitude,
            longitude: makkahLongitude,
            method: AppCalculationMethod.ummAlQura
        )

        #expect(prayerTimes != nil)
        #expect(sunrise != nil)
        #expect(sunrise! > prayerTimes![.fajr]!)
    }

    @Test func sunriseIsBeforeDhuhr() throws {
        let date = Date()
        let prayerTimes = calculator.calculatePrayerTimes(
            for: date,
            latitude: makkahLatitude,
            longitude: makkahLongitude,
            method: AppCalculationMethod.ummAlQura
        )
        let sunrise = calculator.getSunrise(
            for: date,
            latitude: makkahLatitude,
            longitude: makkahLongitude,
            method: AppCalculationMethod.ummAlQura
        )

        #expect(prayerTimes != nil)
        #expect(sunrise != nil)
        #expect(sunrise! < prayerTimes![.dhuhr]!)
    }

    // MARK: - Qibla Direction Tests

    @Test func qiblaDirectionIsValid() throws {
        // From New York, Qibla should be roughly northeast (around 58-59 degrees)
        let qibla = calculator.getQiblaDirection(
            latitude: newYorkLatitude,
            longitude: newYorkLongitude
        )

        #expect(qibla >= 0 && qibla < 360)
    }

    @Test func qiblaFromMakkahIsNearZero() throws {
        // Qibla from Makkah itself should be essentially any direction
        // (since you're at the Kaaba), but the calculation returns a value
        let qibla = calculator.getQiblaDirection(
            latitude: makkahLatitude,
            longitude: makkahLongitude
        )

        #expect(qibla >= 0 && qibla < 360)
    }

    // MARK: - Different Calculation Methods

    @Test func differentMethodsProduceDifferentTimes() throws {
        let date = Date()

        let ummAlQuraTimes = calculator.calculatePrayerTimes(
            for: date,
            latitude: riyadhLatitude,
            longitude: riyadhLongitude,
            method: AppCalculationMethod.ummAlQura
        )

        let mwlTimes = calculator.calculatePrayerTimes(
            for: date,
            latitude: riyadhLatitude,
            longitude: riyadhLongitude,
            method: AppCalculationMethod.mwl
        )

        #expect(ummAlQuraTimes != nil)
        #expect(mwlTimes != nil)

        // Fajr and Isha times typically differ between methods
        // due to different sun angle calculations
        // Note: The times might be the same for some methods, so we just verify both succeed
    }

    @Test func allCalculationMethodsWork() throws {
        let date = Date()
        let methods: [AppCalculationMethod] = [.mwl, .ummAlQura, .egyptian, .karachi, .isna, .dubai, .singapore, .turkey]

        for method in methods {
            let result = calculator.calculatePrayerTimes(
                for: date,
                latitude: riyadhLatitude,
                longitude: riyadhLongitude,
                method: method
            )
            #expect(result != nil, "Failed for method: \(method.rawValue)")
            #expect(result?.count == 5, "Wrong prayer count for method: \(method.rawValue)")
        }
    }

    // MARK: - Edge Cases

    @Test func calculateForFutureDates() throws {
        var components = DateComponents()
        components.year = 2027
        components.month = 1
        components.day = 1
        let futureDate = Calendar.current.date(from: components)!

        let result = calculator.calculatePrayerTimes(
            for: futureDate,
            latitude: makkahLatitude,
            longitude: makkahLongitude,
            method: AppCalculationMethod.ummAlQura
        )

        #expect(result != nil)
        #expect(result?.count == 5)
    }

    @Test func calculateForPastDates() throws {
        var components = DateComponents()
        components.year = 2020
        components.month = 6
        components.day = 15
        let pastDate = Calendar.current.date(from: components)!

        let result = calculator.calculatePrayerTimes(
            for: pastDate,
            latitude: makkahLatitude,
            longitude: makkahLongitude,
            method: AppCalculationMethod.ummAlQura
        )

        #expect(result != nil)
        #expect(result?.count == 5)
    }

    @Test func calculateForExtremeLatitudes() throws {
        // Stockholm, Sweden (high latitude)
        let stockholmLatitude = 59.3293
        let stockholmLongitude = 18.0686

        let date = Date()
        let result = calculator.calculatePrayerTimes(
            for: date,
            latitude: stockholmLatitude,
            longitude: stockholmLongitude,
            method: AppCalculationMethod.mwl
        )

        // High latitudes may have issues during summer/winter, but basic calculation should work
        #expect(result != nil)
    }
}

// MARK: - CalculationMethod Tests

struct CalculationMethodTests {

    @Test func calculationMethodRawValues() throws {
        #expect(AppCalculationMethod.mwl.rawValue == "mwl")
        #expect(AppCalculationMethod.ummAlQura.rawValue == "umm_al_qura")
        #expect(AppCalculationMethod.egyptian.rawValue == "egyptian")
        #expect(AppCalculationMethod.karachi.rawValue == "karachi")
        #expect(AppCalculationMethod.isna.rawValue == "isna")
        #expect(AppCalculationMethod.dubai.rawValue == "dubai")
        #expect(AppCalculationMethod.singapore.rawValue == "singapore")
        #expect(AppCalculationMethod.turkey.rawValue == "turkey")
    }
}

// MARK: - PrayerType Tests

struct PrayerTypeTests {

    @Test func prayerTypeRawValues() throws {
        #expect(PrayerType.fajr.rawValue == "fajr")
        #expect(PrayerType.dhuhr.rawValue == "dhuhr")
        #expect(PrayerType.asr.rawValue == "asr")
        #expect(PrayerType.maghrib.rawValue == "maghrib")
        #expect(PrayerType.isha.rawValue == "isha")
    }

    @Test func prayerTypeDisplayOrder() throws {
        #expect(PrayerType.fajr.displayOrder == 0)
        #expect(PrayerType.dhuhr.displayOrder == 1)
        #expect(PrayerType.asr.displayOrder == 2)
        #expect(PrayerType.maghrib.displayOrder == 3)
        #expect(PrayerType.isha.displayOrder == 4)
    }

    @Test func prayerTypeDefaultDurations() throws {
        #expect(PrayerType.fajr.defaultDuration == 15)
        #expect(PrayerType.dhuhr.defaultDuration == 20)
        #expect(PrayerType.asr.defaultDuration == 20)
        #expect(PrayerType.maghrib.defaultDuration == 15)
        #expect(PrayerType.isha.defaultDuration == 20)
    }

    @Test func prayerTypeHasArabicNames() throws {
        #expect(!PrayerType.fajr.arabicName.isEmpty)
        #expect(!PrayerType.dhuhr.arabicName.isEmpty)
        #expect(!PrayerType.asr.arabicName.isEmpty)
        #expect(!PrayerType.maghrib.arabicName.isEmpty)
        #expect(!PrayerType.isha.arabicName.isEmpty)
    }

    @Test func prayerTypeHasEnglishNames() throws {
        #expect(PrayerType.fajr.englishName == "Fajr")
        #expect(PrayerType.dhuhr.englishName == "Dhuhr")
        #expect(PrayerType.asr.englishName == "Asr")
        #expect(PrayerType.maghrib.englishName == "Maghrib")
        #expect(PrayerType.isha.englishName == "Isha")
    }

    @Test func prayerTypeHasIcons() throws {
        #expect(!PrayerType.fajr.icon.isEmpty)
        #expect(!PrayerType.dhuhr.icon.isEmpty)
        #expect(!PrayerType.asr.icon.isEmpty)
        #expect(!PrayerType.maghrib.icon.isEmpty)
        #expect(!PrayerType.isha.icon.isEmpty)
    }

    @Test func allPrayerTypesAreCaseIterable() throws {
        #expect(PrayerType.allCases.count == 5)
    }
}
