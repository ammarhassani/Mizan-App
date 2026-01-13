//
//  LocationManager.swift
//  Mizan
//
//  Manages location services for prayer time calculations
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdatingLocation = false
    @Published var error: LocationError?

    // MARK: - Computed Properties
    var currentLatitude: Double? {
        currentLocation?.coordinate.latitude
    }

    var currentLongitude: Double? {
        currentLocation?.coordinate.longitude
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var locationUpdateContinuation: CheckedContinuation<CLLocation, Error>?

    // MARK: - Initialization
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // 100m accuracy is sufficient for prayer times
        locationManager.distanceFilter = 50_000 // Only update if moved 50km
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Public Methods

    /// Request location permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Get current location (one-time fetch)
    func getCurrentLocation() async throws -> CLLocation {
        guard isAuthorized else {
            throw LocationError.permissionDenied
        }

        isUpdatingLocation = true
        error = nil

        return try await withCheckedThrowingContinuation { continuation in
            locationUpdateContinuation = continuation
            locationManager.requestLocation()
        }
    }

    /// Start monitoring significant location changes
    func startMonitoringLocation() {
        guard isAuthorized else {
            print("⚠️ Location permission not granted")
            return
        }

        locationManager.startMonitoringSignificantLocationChanges()
        print("📍 Started monitoring significant location changes")
    }

    /// Stop monitoring location
    func stopMonitoringLocation() {
        locationManager.stopMonitoringSignificantLocationChanges()
        print("📍 Stopped monitoring location")
    }

    /// Get location from coordinates
    func getLocationName(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                return formatPlacemark(placemark)
            }
        } catch {
            print("❌ Geocoding failed: \(error)")
        }

        return nil
    }

    /// Check if location services are available
    static func isLocationServicesAvailable() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    /// Get country code from coordinates
    func getCountryCode(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first?.isoCountryCode
        } catch {
            print("❌ Failed to get country code: \(error)")
            return nil
        }
    }

    // MARK: - Private Methods

    private func formatPlacemark(_ placemark: CLPlacemark) -> String {
        var components: [String] = []

        if let locality = placemark.locality {
            components.append(locality)
        }

        if let country = placemark.country {
            components.append(country)
        }

        return components.isEmpty ? "Unknown Location" : components.joined(separator: ", ")
    }

    /// Calculate distance between two locations
    func distance(from location1: CLLocation, to location2: CLLocation) -> Double {
        return location1.distance(from: location2)
    }

    /// Check if moved significantly (>50km)
    func hasMovedSignificantly(from oldLocation: CLLocation?, to newLocation: CLLocation) -> Bool {
        guard let oldLocation = oldLocation else { return true }
        let distance = oldLocation.distance(from: newLocation)
        return distance > 50_000 // 50km
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            print("📍 Location authorization changed: \(authorizationStatus.description)")

            switch authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                startMonitoringLocation()
            case .denied, .restricted:
                error = .permissionDenied
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }

            currentLocation = location
            isUpdatingLocation = false

            print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")

            // Resume continuation if waiting
            locationUpdateContinuation?.resume(returning: location)
            locationUpdateContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isUpdatingLocation = false

            let locationError: LocationError
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    locationError = .permissionDenied
                case .network:
                    locationError = .networkError
                case .locationUnknown:
                    locationError = .locationUnavailable
                default:
                    locationError = .unknown(error)
                }
            } else {
                locationError = .unknown(error)
            }

            self.error = locationError
            print("❌ Location error: \(locationError)")

            // Resume continuation with error
            locationUpdateContinuation?.resume(throwing: locationError)
            locationUpdateContinuation = nil
        }
    }
}

// MARK: - Location Errors

enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationUnavailable
    case networkError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable location services in Settings."
        case .locationUnavailable:
            return "Unable to determine your location. Please try again."
        case .networkError:
            return "Network error while fetching location. Check your internet connection."
        case .unknown(let error):
            return "Location error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Go to Settings > Privacy > Location Services and enable location access for Mizan."
        case .locationUnavailable:
            return "Make sure you're not in airplane mode and have a clear view of the sky."
        case .networkError:
            return "Connect to Wi-Fi or cellular data and try again."
        case .unknown:
            return "Try restarting the app or your device."
        }
    }
}

// MARK: - CLAuthorizationStatus Extension

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Authorized Always"
        case .authorizedWhenInUse:
            return "Authorized When In Use"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - Manual Location Selection

struct ManualLocation: Codable, Identifiable {
    let id = UUID()
    let name: String
    let nameArabic: String
    let latitude: Double
    let longitude: Double
    let countryCode: String
    let timezone: String
}

extension LocationManager {
    /// Popular cities for manual selection
    static let popularCities: [ManualLocation] = [
        // Saudi Arabia
        ManualLocation(name: "Makkah", nameArabic: "مكة المكرمة", latitude: 21.4225, longitude: 39.8262, countryCode: "SA", timezone: "Asia/Riyadh"),
        ManualLocation(name: "Madinah", nameArabic: "المدينة المنورة", latitude: 24.5247, longitude: 39.5692, countryCode: "SA", timezone: "Asia/Riyadh"),
        ManualLocation(name: "Riyadh", nameArabic: "الرياض", latitude: 24.7136, longitude: 46.6753, countryCode: "SA", timezone: "Asia/Riyadh"),
        ManualLocation(name: "Jeddah", nameArabic: "جدة", latitude: 21.5433, longitude: 39.1728, countryCode: "SA", timezone: "Asia/Riyadh"),

        // UAE
        ManualLocation(name: "Dubai", nameArabic: "دبي", latitude: 25.2048, longitude: 55.2708, countryCode: "AE", timezone: "Asia/Dubai"),
        ManualLocation(name: "Abu Dhabi", nameArabic: "أبو ظبي", latitude: 24.4539, longitude: 54.3773, countryCode: "AE", timezone: "Asia/Dubai"),

        // Egypt
        ManualLocation(name: "Cairo", nameArabic: "القاهرة", latitude: 30.0444, longitude: 31.2357, countryCode: "EG", timezone: "Africa/Cairo"),
        ManualLocation(name: "Alexandria", nameArabic: "الإسكندرية", latitude: 31.2001, longitude: 29.9187, countryCode: "EG", timezone: "Africa/Cairo"),

        // USA
        ManualLocation(name: "New York", nameArabic: "نيويورك", latitude: 40.7128, longitude: -74.0060, countryCode: "US", timezone: "America/New_York"),
        ManualLocation(name: "Los Angeles", nameArabic: "لوس أنجلوس", latitude: 34.0522, longitude: -118.2437, countryCode: "US", timezone: "America/Los_Angeles"),

        // UK
        ManualLocation(name: "London", nameArabic: "لندن", latitude: 51.5074, longitude: -0.1278, countryCode: "GB", timezone: "Europe/London"),

        // Turkey
        ManualLocation(name: "Istanbul", nameArabic: "إسطنبول", latitude: 41.0082, longitude: 28.9784, countryCode: "TR", timezone: "Europe/Istanbul"),

        // Pakistan
        ManualLocation(name: "Karachi", nameArabic: "كراتشي", latitude: 24.8607, longitude: 67.0011, countryCode: "PK", timezone: "Asia/Karachi"),

        // Malaysia
        ManualLocation(name: "Kuala Lumpur", nameArabic: "كوالالمبور", latitude: 3.1390, longitude: 101.6869, countryCode: "MY", timezone: "Asia/Kuala_Lumpur"),
    ]
}
