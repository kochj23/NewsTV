//
//  KeywordAlertManager.swift
//  NewsTV
//
//  Manages keyword alerts and notifications
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import UserNotifications

@MainActor
class KeywordAlertManager: ObservableObject {
    static let shared = KeywordAlertManager()

    @Published var matchedArticles: [String: [NewsArticle]] = [:] // keyword -> articles
    @Published var hasNewMatches = false

    private var lastCheckedArticleIds: Set<UUID> = []

    private init() {
        requestNotificationPermission()
    }

    // MARK: - Permission

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    // MARK: - Alert Management

    func addAlert(keyword: String) {
        var settings = SettingsManager.shared.settings
        guard !settings.keywordAlerts.contains(where: { $0.keyword.lowercased() == keyword.lowercased() }) else {
            return
        }
        settings.keywordAlerts.append(KeywordAlert(keyword: keyword))
        SettingsManager.shared.settings = settings
    }

    func removeAlert(id: UUID) {
        var settings = SettingsManager.shared.settings
        settings.keywordAlerts.removeAll { $0.id == id }
        SettingsManager.shared.settings = settings
        matchedArticles.removeValue(forKey: id.uuidString)
    }

    func toggleAlert(id: UUID, enabled: Bool) {
        var settings = SettingsManager.shared.settings
        if let index = settings.keywordAlerts.firstIndex(where: { $0.id == id }) {
            settings.keywordAlerts[index].isEnabled = enabled
            SettingsManager.shared.settings = settings
        }
    }

    // MARK: - Checking

    func checkAlerts(against articles: [NewsArticle]) {
        let settings = SettingsManager.shared.settings
        let enabledAlerts = settings.keywordAlerts.filter { $0.isEnabled }

        guard !enabledAlerts.isEmpty else { return }

        // Find new articles only
        let newArticles = articles.filter { !lastCheckedArticleIds.contains($0.id) }
        guard !newArticles.isEmpty else { return }

        var updatedSettings = settings
        var newMatchesFound = false

        for (index, alert) in enabledAlerts.enumerated() {
            let keyword = alert.keyword.lowercased()

            let matches = newArticles.filter { article in
                article.title.lowercased().contains(keyword) ||
                (article.rssDescription?.lowercased().contains(keyword) ?? false)
            }

            if !matches.isEmpty {
                // Update matched articles
                var existing = matchedArticles[alert.keyword] ?? []
                existing.append(contentsOf: matches)
                matchedArticles[alert.keyword] = existing

                // Update alert stats
                if let settingsIndex = updatedSettings.keywordAlerts.firstIndex(where: { $0.id == alert.id }) {
                    updatedSettings.keywordAlerts[settingsIndex].matchCount += matches.count
                    updatedSettings.keywordAlerts[settingsIndex].lastMatchDate = Date()
                }

                // Send notification if enabled
                if alert.notifyOnMatch {
                    sendNotification(for: alert.keyword, articleCount: matches.count, firstTitle: matches.first?.title)
                }

                newMatchesFound = true
            }
        }

        if newMatchesFound {
            hasNewMatches = true
            SettingsManager.shared.settings = updatedSettings
        }

        // Remember checked articles
        lastCheckedArticleIds.formUnion(newArticles.map { $0.id })

        // Limit memory usage - keep only recent IDs
        if lastCheckedArticleIds.count > 1000 {
            lastCheckedArticleIds = Set(lastCheckedArticleIds.prefix(500))
        }
    }

    private func sendNotification(for keyword: String, articleCount: Int, firstTitle: String?) {
        #if !os(tvOS)
        let content = UNMutableNotificationContent()
        content.title = "Keyword Alert: \(keyword)"
        content.body = articleCount == 1
            ? firstTitle ?? "New article found"
            : "\(articleCount) new articles found"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
        #else
        // On tvOS, just log the notification (no user notifications available)
        print("Keyword Alert [\(keyword)]: \(articleCount) new articles")
        #endif
    }

    // MARK: - Query

    func articles(for keyword: String) -> [NewsArticle] {
        matchedArticles[keyword] ?? []
    }

    func clearMatches(for keyword: String) {
        matchedArticles[keyword] = []
    }

    func clearNewMatchesFlag() {
        hasNewMatches = false
    }

    func totalMatchCount() -> Int {
        matchedArticles.values.reduce(0) { $0 + $1.count }
    }
}
