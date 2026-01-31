//
//  NewsTVApp.swift
//  NewsTV
//
//  AI-Powered News for Apple TV and iPad
//  Created by Jordan Koch on 2026-01-28.
//  Updated: 2026-01-31 - Added iPad support with NavigationSplitView
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
//  - iPad: Sidebar navigation, share sheets, keyboard shortcuts
//

import SwiftUI

@main
struct NewsTVApp: App {
    var body: some Scene {
        WindowGroup {
            contentView
                .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        #if os(iOS)
        iPadNewsView()
        #else
        TVContentView()
        #endif
    }
}
