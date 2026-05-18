//
//  PersonalizationEngine.swift
//  NewsTV
//
//  Learns from viewing habits to personalize the feed
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

@MainActor
class PersonalizationEngine: ObservableObject {
    static let shared = PersonalizationEngine()

    @Published var profile: UserPreferenceProfile
    @Published var personalizedArticles: [NewsArticle] = []

    private let profileKey = "NewsTV.userProfile"
    private var viewStartTimes: [UUID: Date] = [:]

    private init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserPreferenceProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = UserPreferenceProfile()
        }
    }

    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }

    // MARK: - View Tracking

    func startViewing(_ article: NewsArticle) {
        viewStartTimes[article.id] = Date()
    }

    func stopViewing(_ article: NewsArticle) {
        guard let startTime = viewStartTimes[article.id] else { return }
        let duration = Date().timeIntervalSince(startTime)
        viewStartTimes.removeValue(forKey: article.id)

        // Only count views longer than 3 seconds
        if duration > 3 {
            profile.recordView(article: article, duration: duration)
            saveProfile()
        }
    }

    // MARK: - Personalization

    func personalizedFeed(from articles: [NewsArticle]) -> [NewsArticle] {
        guard SettingsManager.shared.settings.enablePersonalizedFeed else {
            return articles
        }

        // Score and sort articles by relevance
        let scored = articles.map { article -> (NewsArticle, Double) in
            let score = profile.relevanceScore(for: article)
            // Boost unread articles
            let unreadBoost = profile.readArticleIds.contains(article.id) ? 0.0 : 0.2
            return (article, score + unreadBoost)
        }

        let sorted = scored.sorted { $0.1 > $1.1 }
        personalizedArticles = sorted.map { $0.0 }
        return personalizedArticles
    }

    func forYouFeed(from articles: [NewsArticle], count: Int = 20) -> [NewsArticle] {
        let personalized = personalizedFeed(from: articles)
        return Array(personalized.prefix(count))
    }

    // MARK: - Topic Learning

    func recordTopicInterest(_ topic: String, weight: Double = 0.1) {
        profile.topicInterests[topic.lowercased(), default: 0.5] += weight
        profile.topicInterests[topic.lowercased()] = min(profile.topicInterests[topic.lowercased()]!, 1.0)
        saveProfile()
    }

    func topInterests(count: Int = 5) -> [String] {
        profile.topicInterests
            .sorted { $0.value > $1.value }
            .prefix(count)
            .map { $0.key }
    }

    // MARK: - Recommendations

    func recommendedCategories() -> [NewsCategory] {
        profile.categoryWeights
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }

    func recommendedSources() -> [String] {
        profile.sourceWeights
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }

    // MARK: - Reset

    func resetProfile() {
        profile = UserPreferenceProfile()
        saveProfile()
    }
}
