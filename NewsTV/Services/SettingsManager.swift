//
//  SettingsManager.swift
//  NewsTV
//
//  Persistent settings management - syncs with Apple TV Settings app
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import Combine

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var settings: NewsTVSettings

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Load settings from UserDefaults (populated by Settings.bundle)
        self.settings = SettingsManager.loadFromUserDefaults()

        // Watch for changes from Settings app
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.settings = SettingsManager.loadFromUserDefaults()
                }
            }
            .store(in: &cancellables)
    }

    private static func loadFromUserDefaults() -> NewsTVSettings {
        let defaults = UserDefaults.standard

        // Register defaults
        defaults.register(defaults: [
            "theme_dark": true,
            "font_size": "large",
            "enable_sentiment_colors": true,
            "enable_bias_indicators": true,
            "enable_breaking_news": true,
            "enable_personalized_feed": true,
            "enable_trending_ticker": true,
            "enable_audio_briefings": true,
            "speech_rate": 0.5,
            "enable_weather_widget": true,
            "temperature_unit": "fahrenheit",
            "enable_screensaver": true,
            "screensaver_idle_time": 300.0,
            "enable_icloud_sync": true,
            "enable_background_refresh": true
        ])

        // Map font size string to enum
        let fontSizeString = defaults.string(forKey: "font_size") ?? "large"
        let fontSize: NewsTVSettings.FontSize = {
            switch fontSizeString {
            case "medium": return .medium
            case "large": return .large
            case "extraLarge": return .extraLarge
            default: return .large
            }
        }()

        // Map temperature unit
        let tempUnitString = defaults.string(forKey: "temperature_unit") ?? "fahrenheit"
        let tempUnit: NewsTVSettings.TemperatureUnit = tempUnitString == "celsius" ? .celsius : .fahrenheit

        // Map theme
        let theme: NewsTVSettings.AppTheme = defaults.bool(forKey: "theme_dark") ? .dark : .light

        return NewsTVSettings(
            rotationInterval: 15,
            enableAudioBriefings: defaults.bool(forKey: "enable_audio_briefings"),
            enableBreakingNewsAlerts: defaults.bool(forKey: "enable_breaking_news"),
            selectedCategories: NewsCategory.allCases,
            preferredVoice: "com.apple.voice.compact.en-US.Samantha",
            speechRate: defaults.float(forKey: "speech_rate"),
            enableSentimentColors: defaults.bool(forKey: "enable_sentiment_colors"),
            enableBiasIndicators: defaults.bool(forKey: "enable_bias_indicators"),
            ambientModeEnabled: true,
            fontSize: fontSize,
            enablePersonalizedFeed: defaults.bool(forKey: "enable_personalized_feed"),
            enableBackgroundRefresh: defaults.bool(forKey: "enable_background_refresh"),
            backgroundRefreshInterval: 300,
            localNewsLocation: nil,
            localNewsZipCode: defaults.string(forKey: "local_news_zipcode"),
            enableWeatherWidget: defaults.bool(forKey: "enable_weather_widget"),
            temperatureUnit: tempUnit,
            theme: theme,
            enableTrendingTicker: defaults.bool(forKey: "enable_trending_ticker"),
            enableiCloudSync: defaults.bool(forKey: "enable_icloud_sync"),
            screensaverIdleTime: defaults.double(forKey: "screensaver_idle_time"),
            enableScreensaverMode: defaults.bool(forKey: "enable_screensaver"),
            keywordAlerts: [],
            customFeeds: []
        )
    }

    func resetToDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "theme_dark")
        defaults.removeObject(forKey: "font_size")
        defaults.removeObject(forKey: "enable_sentiment_colors")
        defaults.removeObject(forKey: "enable_bias_indicators")
        defaults.removeObject(forKey: "enable_breaking_news")
        defaults.removeObject(forKey: "enable_personalized_feed")
        defaults.removeObject(forKey: "enable_trending_ticker")
        defaults.removeObject(forKey: "enable_audio_briefings")
        defaults.removeObject(forKey: "speech_rate")
        defaults.removeObject(forKey: "enable_weather_widget")
        defaults.removeObject(forKey: "temperature_unit")
        defaults.removeObject(forKey: "local_news_zipcode")
        defaults.removeObject(forKey: "enable_screensaver")
        defaults.removeObject(forKey: "screensaver_idle_time")
        defaults.removeObject(forKey: "enable_icloud_sync")
        defaults.removeObject(forKey: "enable_background_refresh")
        settings = SettingsManager.loadFromUserDefaults()
    }
}
