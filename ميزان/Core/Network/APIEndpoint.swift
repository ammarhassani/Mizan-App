//
//  APIEndpoint.swift
//  Mizan
//
//  API endpoint definitions for Aladhan prayer times API
//

import Foundation

enum APIEndpoint {
    case prayerTimes(date: Date, latitude: Double, longitude: Double, method: Int)
    case prayerTimesMonth(month: Int, year: Int, latitude: Double, longitude: Double, method: Int)
    case hijriCalendar(month: Int, year: Int)

    // MARK: - Base URL

    var baseURL: String {
        ConfigurationManager.shared.prayerConfig.api.baseUrl
    }

    // MARK: - Path

    var path: String {
        let endpoints = ConfigurationManager.shared.prayerConfig.api.endpoints

        switch self {
        case .prayerTimes:
            return endpoints["timings"] ?? "/timings"
        case .prayerTimesMonth:
            return endpoints["calendar"] ?? "/calendar"
        case .hijriCalendar:
            return endpoints["hijri_calendar"] ?? "/hijriCalendar"
        }
    }

    // MARK: - Query Parameters

    var queryItems: [URLQueryItem] {
        switch self {
        case .prayerTimes(let date, let latitude, let longitude, let method):
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
            let dateString = dateFormatter.string(from: date)

            return [
                URLQueryItem(name: "date", value: dateString),
                URLQueryItem(name: "latitude", value: String(format: "%.6f", latitude)),
                URLQueryItem(name: "longitude", value: String(format: "%.6f", longitude)),
                URLQueryItem(name: "method", value: "\(method)"),
                URLQueryItem(name: "school", value: "0") // Shafi for Asr
            ]

        case .prayerTimesMonth(let month, let year, let latitude, let longitude, let method):
            return [
                URLQueryItem(name: "month", value: "\(month)"),
                URLQueryItem(name: "year", value: "\(year)"),
                URLQueryItem(name: "latitude", value: String(format: "%.6f", latitude)),
                URLQueryItem(name: "longitude", value: String(format: "%.6f", longitude)),
                URLQueryItem(name: "method", value: "\(method)"),
                URLQueryItem(name: "school", value: "0")
            ]

        case .hijriCalendar(let month, let year):
            return [
                URLQueryItem(name: "month", value: "\(month)"),
                URLQueryItem(name: "year", value: "\(year)")
            ]
        }
    }

    // MARK: - URL Request

    func urlRequest() throws -> URLRequest {
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mizan/1.0", forHTTPHeaderField: "User-Agent")

        return request
    }
}

// MARK: - Response Models

struct AladhanResponse: Codable {
    let code: Int
    let status: String
    let data: AladhanData
}

struct AladhanData: Codable {
    let timings: AladhanTimings
    let date: AladhanDate
    let meta: AladhanMeta
}

struct AladhanTimings: Codable {
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let sunset: String
    let maghrib: String
    let isha: String
    let imsak: String
    let midnight: String
    let firstthird: String?
    let lastthird: String?

    enum CodingKeys: String, CodingKey {
        case fajr = "Fajr"
        case sunrise = "Sunrise"
        case dhuhr = "Dhuhr"
        case asr = "Asr"
        case sunset = "Sunset"
        case maghrib = "Maghrib"
        case isha = "Isha"
        case imsak = "Imsak"
        case midnight = "Midnight"
        case firstthird = "Firstthird"
        case lastthird = "Lastthird"
    }
}

struct AladhanDate: Codable {
    let readable: String
    let timestamp: String
    let gregorian: GregorianDate
    let hijri: HijriDate
}

struct GregorianDate: Codable {
    let date: String
    let format: String
    let day: String
    let weekday: Weekday
    let month: Month
    let year: String
    let designation: Designation
}

struct HijriDate: Codable {
    let date: String
    let format: String
    let day: String
    let weekday: Weekday
    let month: HijriMonth
    let year: String
    let designation: Designation
    let holidays: [String]?
}

struct Weekday: Codable {
    let en: String
    let ar: String?
}

struct Month: Codable {
    let number: Int
    let en: String
    let ar: String?
}

struct HijriMonth: Codable {
    let number: Int
    let en: String
    let ar: String
}

struct Designation: Codable {
    let abbreviated: String
    let expanded: String
}

struct AladhanMeta: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let method: Method
    let latitudeAdjustmentMethod: String?
    let midnightMode: String?
    let school: String?
    let offset: [String: Int]?
}

struct Method: Codable {
    let id: Int
    let name: String
    let params: MethodParams?
}

struct MethodParams: Codable {
    let fajr: Double?
    let isha: Double?
    let maghrib: String?
    let midnight: String?

    enum CodingKeys: String, CodingKey {
        case fajr = "Fajr"
        case isha = "Isha"
        case maghrib = "Maghrib"
        case midnight = "Midnight"
    }
}

// MARK: - Monthly Calendar Response

struct AladhanMonthlyResponse: Codable {
    let code: Int
    let status: String
    let data: [AladhanData]
}

// MARK: - Helper Extensions

extension AladhanTimings {
    func time(for prayer: PrayerType) -> String? {
        switch prayer {
        case .fajr: return fajr
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        }
    }
}

extension AladhanData {
    /// Parse time string (HH:mm) to Date on a given day
    func parseTime(_ timeString: String, on date: Date) -> Date? {
        let components = timeString.components(separatedBy: " ")
        let timeOnly = components.first ?? timeString

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        guard let time = formatter.date(from: timeOnly) else {
            return nil
        }

        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute

        return calendar.date(from: dateComponents)
    }

    /// Get all prayer times as dictionary
    func prayerTimesDictionary(on date: Date) -> [PrayerType: Date] {
        var times: [PrayerType: Date] = [:]

        for prayerType in PrayerType.allCases {
            if let timeString = timings.time(for: prayerType),
               let time = parseTime(timeString, on: date) {
                times[prayerType] = time
            }
        }

        return times
    }
}
