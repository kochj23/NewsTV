//
//  WeatherService.swift
//  NewsTV
//
//  Weather widget integration using WeatherKit
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherService: ObservableObject {
    static let shared = WeatherService()

    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    @Published var error: String?

    private let weatherService = WeatherKit.WeatherService.shared
    private let geocoder = CLGeocoder()
    private var lastFetch: Date?

    private init() {}

    // MARK: - Fetch Weather

    func fetchWeather() async {
        guard SettingsManager.shared.settings.enableWeatherWidget else {
            currentWeather = nil
            return
        }

        // Rate limit - fetch at most every 10 minutes
        if let last = lastFetch, Date().timeIntervalSince(last) < 600 {
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        // Get location from settings
        let settings = SettingsManager.shared.settings
        var location: CLLocation?

        if let zipCode = settings.localNewsZipCode, !zipCode.isEmpty {
            location = await geocode(zipCode)
        } else if let city = settings.localNewsLocation, !city.isEmpty {
            location = await geocode(city)
        }

        // Default to a location if none set (New York)
        if location == nil {
            location = CLLocation(latitude: 40.7128, longitude: -74.0060)
        }

        guard let loc = location else {
            error = "Could not determine location"
            return
        }

        do {
            let weather = try await weatherService.weather(for: loc)
            let current = weather.currentWeather

            let condition = mapCondition(current.condition)
            let locationName = settings.localNewsLocation ?? settings.localNewsZipCode ?? "New York"

            let temp = settings.temperatureUnit == .celsius
                ? current.temperature.converted(to: .celsius).value
                : current.temperature.converted(to: .fahrenheit).value

            let high = settings.temperatureUnit == .celsius
                ? weather.dailyForecast.first?.highTemperature.converted(to: .celsius).value ?? temp
                : weather.dailyForecast.first?.highTemperature.converted(to: .fahrenheit).value ?? temp

            let low = settings.temperatureUnit == .celsius
                ? weather.dailyForecast.first?.lowTemperature.converted(to: .celsius).value ?? temp
                : weather.dailyForecast.first?.lowTemperature.converted(to: .fahrenheit).value ?? temp

            currentWeather = WeatherData(
                temperature: temp,
                condition: condition,
                high: high,
                low: low,
                location: locationName,
                lastUpdated: Date()
            )

            lastFetch = Date()

        } catch {
            self.error = "Weather unavailable"
            print("Weather fetch error: \(error)")
        }
    }

    // MARK: - Helpers

    private func geocode(_ address: String) async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            geocoder.geocodeAddressString(address) { placemarks, error in
                continuation.resume(returning: placemarks?.first?.location)
            }
        }
    }

    private func mapCondition(_ condition: WeatherCondition) -> WeatherData.WeatherCondition {
        switch condition {
        case .clear, .mostlyClear, .hot:
            return .clear
        case .cloudy, .mostlyCloudy:
            return .cloudy
        case .partlyCloudy:
            return .partlyCloudy
        case .rain, .drizzle, .heavyRain, .freezingRain:
            return .rain
        case .snow, .flurries, .heavySnow, .sleet, .freezingDrizzle, .wintryMix, .blizzard:
            return .snow
        case .thunderstorms, .tropicalStorm, .hurricane, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms:
            return .thunderstorm
        case .foggy, .haze, .smoky:
            return .fog
        case .windy, .breezy, .blowingDust:
            return .windy
        default:
            return .unknown
        }
    }

    // MARK: - Display Helpers

    var temperatureString: String {
        guard let weather = currentWeather else { return "--" }
        let unit = SettingsManager.shared.settings.temperatureUnit
        return String(format: "%.0f%@", weather.temperature, unit.symbol)
    }

    var highLowString: String {
        guard let weather = currentWeather else { return "" }
        return String(format: "H:%.0f° L:%.0f°", weather.high, weather.low)
    }

    var conditionIcon: String {
        currentWeather?.condition.icon ?? "questionmark.circle"
    }

    var locationString: String {
        currentWeather?.location ?? "Unknown"
    }
}
