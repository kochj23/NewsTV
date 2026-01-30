//
//  SiriIntentsManager.swift
//  NewsTV
//
//  Handles Siri shortcuts and voice commands
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import Intents

@MainActor
class SiriIntentsManager: ObservableObject {
    static let shared = SiriIntentsManager()

    @Published var donatedShortcuts: [String] = []

    private init() {
        donateShortcuts()
    }

    // MARK: - Shortcut Donation

    func donateShortcuts() {
        // Donate category shortcuts
        for category in NewsCategory.allCases {
            donateViewCategory(category)
        }

        // Donate common actions
        donateReadHeadlines()
        donateStartBriefing()
        donateCheckTrending()
    }

    private func donateViewCategory(_ category: NewsCategory) {
        let activity = NSUserActivity(activityType: "com.jordankoch.NewsTV.viewCategory")
        activity.title = "View \(category.rawValue) News"
        activity.userInfo = ["category": category.rawValue]
        activity.isEligibleForSearch = true
        #if !os(tvOS)
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "Show me \(category.rawValue.lowercased()) news"
        #endif

        activity.becomeCurrent()
        donatedShortcuts.append(category.rawValue)
    }

    private func donateReadHeadlines() {
        let activity = NSUserActivity(activityType: "com.jordankoch.NewsTV.readHeadlines")
        activity.title = "Read Today's Headlines"
        activity.isEligibleForSearch = true
        #if !os(tvOS)
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "What's in the news?"
        #endif

        activity.becomeCurrent()
        donatedShortcuts.append("Headlines")
    }

    private func donateStartBriefing() {
        let activity = NSUserActivity(activityType: "com.jordankoch.NewsTV.startBriefing")
        activity.title = "Start News Briefing"
        activity.isEligibleForSearch = true
        #if !os(tvOS)
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "Start my news briefing"
        #endif

        activity.becomeCurrent()
        donatedShortcuts.append("Briefing")
    }

    private func donateCheckTrending() {
        let activity = NSUserActivity(activityType: "com.jordankoch.NewsTV.checkTrending")
        activity.title = "Check Trending Topics"
        activity.isEligibleForSearch = true
        #if !os(tvOS)
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "What's trending?"
        #endif

        activity.becomeCurrent()
        donatedShortcuts.append("Trending")
    }

    // MARK: - Intent Handling

    func handleActivity(_ activity: NSUserActivity) -> SiriAction? {
        switch activity.activityType {
        case "com.jordankoch.NewsTV.viewCategory":
            if let categoryName = activity.userInfo?["category"] as? String,
               let category = NewsCategory(rawValue: categoryName) {
                return .viewCategory(category)
            }

        case "com.jordankoch.NewsTV.readHeadlines":
            return .readHeadlines

        case "com.jordankoch.NewsTV.startBriefing":
            return .startBriefing

        case "com.jordankoch.NewsTV.checkTrending":
            return .checkTrending

        default:
            break
        }

        return nil
    }

    // MARK: - Action Enum

    enum SiriAction {
        case viewCategory(NewsCategory)
        case readHeadlines
        case startBriefing
        case checkTrending
    }
}
