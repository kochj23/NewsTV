//
//  CustomFeedManager.swift
//  NewsTV
//
//  Manages user-added custom RSS feeds
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

@MainActor
class CustomFeedManager: ObservableObject {
    static let shared = CustomFeedManager()

    @Published var customArticles: [NewsArticle] = []
    @Published var isLoading = false

    private let parser = RSSParser.shared

    private init() {}

    // MARK: - Feed Management

    func addFeed(name: String, url: URL, category: NewsCategory = .topStories) {
        var settings = SettingsManager.shared.settings
        guard !settings.customFeeds.contains(where: { $0.url == url }) else { return }

        let feed = CustomRSSFeed(name: name, url: url, category: category)
        settings.customFeeds.append(feed)
        SettingsManager.shared.settings = settings

        Task { await fetchFeed(feed) }
    }

    func removeFeed(id: UUID) {
        var settings = SettingsManager.shared.settings
        settings.customFeeds.removeAll { $0.id == id }
        SettingsManager.shared.settings = settings

        // Remove articles from this feed
        customArticles.removeAll { article in
            settings.customFeeds.allSatisfy { $0.name != article.source.name }
        }
    }

    func toggleFeed(id: UUID, enabled: Bool) {
        var settings = SettingsManager.shared.settings
        if let index = settings.customFeeds.firstIndex(where: { $0.id == id }) {
            settings.customFeeds[index].isEnabled = enabled
            SettingsManager.shared.settings = settings
        }
    }

    func updateFeedCategory(id: UUID, category: NewsCategory) {
        var settings = SettingsManager.shared.settings
        if let index = settings.customFeeds.firstIndex(where: { $0.id == id }) {
            settings.customFeeds[index].category = category
            SettingsManager.shared.settings = settings
        }
    }

    // MARK: - Fetching

    func fetchAllCustomFeeds() async {
        let enabledFeeds = SettingsManager.shared.settings.customFeeds.filter { $0.isEnabled }
        guard !enabledFeeds.isEmpty else {
            customArticles = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        var allArticles: [NewsArticle] = []

        await withTaskGroup(of: (UUID, [NewsArticle]).self) { group in
            for feed in enabledFeeds {
                group.addTask {
                    let articles = await self.fetchFeedArticles(feed)
                    return (feed.id, articles)
                }
            }

            for await (feedId, articles) in group {
                allArticles.append(contentsOf: articles)

                // Update article count in settings
                var settings = SettingsManager.shared.settings
                if let index = settings.customFeeds.firstIndex(where: { $0.id == feedId }) {
                    settings.customFeeds[index].articleCount = articles.count
                    settings.customFeeds[index].lastFetchDate = Date()
                    SettingsManager.shared.settings = settings
                }
            }
        }

        customArticles = allArticles.sorted { $0.publishedDate > $1.publishedDate }
    }

    private func fetchFeed(_ feed: CustomRSSFeed) async {
        let articles = await fetchFeedArticles(feed)

        var settings = SettingsManager.shared.settings
        if let index = settings.customFeeds.firstIndex(where: { $0.id == feed.id }) {
            settings.customFeeds[index].articleCount = articles.count
            settings.customFeeds[index].lastFetchDate = Date()
            SettingsManager.shared.settings = settings
        }

        // Add to custom articles
        let existingIds = Set(customArticles.map { $0.id })
        let newArticles = articles.filter { !existingIds.contains($0.id) }
        customArticles.append(contentsOf: newArticles)
        customArticles.sort { $0.publishedDate > $1.publishedDate }
    }

    private func fetchFeedArticles(_ feed: CustomRSSFeed) async -> [NewsArticle] {
        let source = NewsSource(
            id: "custom-\(feed.id.uuidString)",
            name: feed.name,
            rssURL: feed.url,
            category: feed.category,
            bias: .center,
            reliability: 0.7
        )

        do {
            return try await parser.parseFeed(from: source)
        } catch {
            print("Failed to fetch custom feed \(feed.name): \(error)")
            return []
        }
    }

    // MARK: - Validation

    func validateFeedURL(_ url: URL) async -> Bool {
        let source = NewsSource(
            id: "validation",
            name: "Validation",
            rssURL: url,
            category: .topStories
        )

        do {
            let articles = try await parser.parseFeed(from: source)
            return !articles.isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Suggested Feeds

    static let suggestedFeeds: [(name: String, url: String, category: NewsCategory)] = [
        ("Hacker News", "https://hnrss.org/frontpage", .technology),
        ("Reddit Technology", "https://www.reddit.com/r/technology/.rss", .technology),
        ("NASA", "https://www.nasa.gov/rss/dyn/breaking_news.rss", .science),
        ("Wired", "https://www.wired.com/feed/rss", .technology),
        ("The Atlantic", "https://www.theatlantic.com/feed/all/", .topStories),
        ("Polygon", "https://www.polygon.com/rss/index.xml", .entertainment),
        ("IGN", "https://feeds.feedburner.com/ign/all", .entertainment),
        ("MacRumors", "https://feeds.macrumors.com/MacRumors-All", .technology),
        ("9to5Mac", "https://9to5mac.com/feed/", .technology),
        ("Engadget", "https://www.engadget.com/rss.xml", .technology)
    ]
}
