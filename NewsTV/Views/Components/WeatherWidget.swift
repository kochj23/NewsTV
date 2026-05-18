//
//  WeatherWidget.swift
//  NewsTV
//
//  Compact weather display widget
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct WeatherWidget: View {
    @ObservedObject private var weatherService = WeatherService.shared
    @ObservedObject private var settings = SettingsManager.shared

    var body: some View {
        if settings.settings.enableWeatherWidget, let weather = weatherService.currentWeather {
            HStack(spacing: 12) {
                Image(systemName: weather.condition.icon)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(weatherService.temperatureString)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(weather.location)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text(weather.condition.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))

                    Text(weatherService.highLowString)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .onAppear {
                Task {
                    await weatherService.fetchWeather()
                }
            }
        }
    }

    private var iconColor: Color {
        guard let condition = weatherService.currentWeather?.condition else {
            return .white
        }

        switch condition {
        case .clear: return .yellow
        case .cloudy, .partlyCloudy: return .gray
        case .rain: return .blue
        case .snow: return .cyan
        case .thunderstorm: return .purple
        case .fog: return .gray
        case .windy: return .teal
        case .unknown: return .white
        }
    }
}

#Preview {
    WeatherWidget()
        .preferredColorScheme(.dark)
}
