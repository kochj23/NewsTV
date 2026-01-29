//
//  NewsTVApp.swift
//  NewsTV
//
//  AI-Powered News for Apple TV
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//
//  Features:
//  - On-device ML with NaturalLanguage and Vision frameworks
//  - Sentiment analysis for news headlines
//  - Named Entity Recognition (people, orgs, places)
//  - Text-to-Speech audio briefings
//  - Breaking news alerts
//  - Multi-category news browsing
//  - Ambient screensaver mode
//  - Source bias indicators
//

import SwiftUI

@main
struct NewsTVApp: App {
    @StateObject private var newsAggregator = NewsAggregator.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var ttsManager = TTSManager.shared

    var body: some Scene {
        WindowGroup {
            TVContentView()
                .environmentObject(newsAggregator)
                .environmentObject(settingsManager)
                .environmentObject(ttsManager)
                .preferredColorScheme(.dark)
        }
    }
}
