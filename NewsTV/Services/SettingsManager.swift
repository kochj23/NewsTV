//
//  SettingsManager.swift
//  NewsTV
//
//  Persistent settings management
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var settings: NewsTVSettings {
        didSet {
            saveSettings()
        }
    }

    private let settingsKey = "NewsTV.settings"

    private init() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(NewsTVSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = NewsTVSettings()
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }

    func resetToDefaults() {
        settings = NewsTVSettings()
    }
}
