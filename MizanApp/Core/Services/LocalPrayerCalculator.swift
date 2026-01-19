//
//  LocalPrayerCalculator.swift
//  Mizan
//
//  Offline prayer time calculation using Adhan-Swift
//  High-precision astronomical calculations for any date
//

import Foundation
import Adhan
import os.log

final class LocalPrayerCalculator {

    /// Calculate prayer times for a specific date and location
    /// - Parameters:
    ///   - date: The date to calculate prayer times for
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    ///   - method: Calculation method to use
    /// - Returns: Dictionary of prayer types to their times, or nil if calculation fails
    func calculatePrayerTimes(
        for date: Date,
        latitude: Double,
        longitude: Double,
        method: CalculationMethod
    ) -> [PrayerType: Date]? {
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let coordinates = Coordinates(latitude: latitude, longitude: longitude)

        var params = method.adhanParams
        params.madhab = .shafi  // Match existing app default (school=0 in API)

        guard let prayers = PrayerTimes(
            coordinates: coordinates,
            date: dateComponents,
            calculationParameters: params
        ) else {
            MizanLogger.shared.prayer.error("Failed to calculate prayer times for \(date)")
            return nil
        }

        return [
            .fajr: prayers.fajr,
            .dhuhr: prayers.dhuhr,
            .asr: prayers.asr,
            .maghrib: prayers.maghrib,
            .isha: prayers.isha
        ]
    }

    /// Get sunrise time for a specific date and location
    func getSunrise(
        for date: Date,
        latitude: Double,
        longitude: Double,
        method: CalculationMethod
    ) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let coordinates = Coordinates(latitude: latitude, longitude: longitude)

        let params = method.adhanParams

        guard let prayers = PrayerTimes(
            coordinates: coordinates,
            date: dateComponents,
            calculationParameters: params
        ) else {
            return nil
        }

        return prayers.sunrise
    }

    /// Calculate Qibla direction from a location
    func getQiblaDirection(latitude: Double, longitude: Double) -> Double {
        let coordinates = Coordinates(latitude: latitude, longitude: longitude)
        let qibla = Qibla(coordinates: coordinates)
        return qibla.direction
    }
}
