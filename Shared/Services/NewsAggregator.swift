//
//  NewsAggregator.swift
//  NewsTV
//
//  Aggregates news from multiple RSS sources
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

/// Tracks consecutive failures per feed and marks unhealthy feeds for cooldown.
private class FeedHealthTracker {
    struct FeedState {
        var consecutiveFailures: Int = 0
        var unhealthySince: Date? = nil
    }

    private var states: [String: FeedState] = [:]
    private let maxFailures = 3
    private let cooldownInterval: TimeInterval = 3600 // 1 hour

    /// Returns true if the source should be skipped (unhealthy and still in cooldown).
    func shouldSkip(_ source: NewsSource) -> Bool {
        guard let state = states[source.id], let since = state.unhealthySince else {
            return false
        }
        if Date().timeIntervalSince(since) >= cooldownInterval {
            // Cooldown expired, allow retry
            return false
        }
        return true
    }

    func recordSuccess(_ source: NewsSource) {
        states[source.id] = FeedState()
    }

    func recordFailure(_ source: NewsSource) {
        var state = states[source.id] ?? FeedState()
        state.consecutiveFailures += 1
        if state.consecutiveFailures >= maxFailures {
            state.unhealthySince = Date()
            print("[FeedHealth] \(source.name) marked unhealthy after \(state.consecutiveFailures) consecutive failures")
        }
        states[source.id] = state
    }
}

@MainActor
class NewsAggregator: ObservableObject {
    static let shared = NewsAggregator()

    @Published var articles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var lastRefresh: Date?
    @Published var error: String?

    private let parser = RSSParser.shared
    private let feedHealth = FeedHealthTracker()

    // MARK: - Default Sources

    let defaultSources: [NewsSource] = [
        // Top Stories - using direct feeds instead of rsshub proxies
        NewsSource(id: "npr", name: "NPR", rssURL: URL(string: "https://feeds.npr.org/1001/rss.xml")!, category: .topStories, bias: .leanLeft, reliability: 0.9),
        NewsSource(id: "abc-news", name: "ABC News", rssURL: URL(string: "https://abcnews.go.com/abcnews/topstories")!, category: .topStories, bias: .center, reliability: 0.85),
        NewsSource(id: "cbs-news", name: "CBS News", rssURL: URL(string: "https://www.cbsnews.com/latest/rss/main")!, category: .topStories, bias: .center, reliability: 0.85),


        // US News
        NewsSource(id: "nyt-us", name: "NY Times US", rssURL: URL(string: "https://rss.nytimes.com/services/xml/rss/nyt/US.xml")!, category: .us, bias: .leanLeft, reliability: 0.9),
        NewsSource(id: "usa-today", name: "USA Today", rssURL: URL(string: "https://rssfeeds.usatoday.com/usatoday-NewsTopStories")!, category: .us, bias: .center, reliability: 0.85),

        // World
        NewsSource(id: "bbc-world", name: "BBC World", rssURL: URL(string: "https://feeds.bbci.co.uk/news/world/rss.xml")!, category: .world, bias: .center, reliability: 0.9),
        NewsSource(id: "guardian-world", name: "The Guardian", rssURL: URL(string: "https://www.theguardian.com/world/rss")!, category: .world, bias: .left, reliability: 0.85),
        NewsSource(id: "nyt-world", name: "NY Times World", rssURL: URL(string: "https://rss.nytimes.com/services/xml/rss/nyt/World.xml")!, category: .world, bias: .leanLeft, reliability: 0.9),

        // Technology
        NewsSource(id: "techcrunch", name: "TechCrunch", rssURL: URL(string: "https://techcrunch.com/feed/")!, category: .technology, bias: .center, reliability: 0.85),
        NewsSource(id: "arstechnica", name: "Ars Technica", rssURL: URL(string: "https://feeds.arstechnica.com/arstechnica/index")!, category: .technology, bias: .center, reliability: 0.9),
        NewsSource(id: "verge", name: "The Verge", rssURL: URL(string: "https://www.theverge.com/rss/index.xml")!, category: .technology, bias: .leanLeft, reliability: 0.85),
        NewsSource(id: "wired", name: "Wired", rssURL: URL(string: "https://www.wired.com/feed/rss")!, category: .technology, bias: .center, reliability: 0.85),

        // Business
        NewsSource(id: "cnbc", name: "CNBC", rssURL: URL(string: "https://www.cnbc.com/id/100003114/device/rss/rss.html")!, category: .business, bias: .center, reliability: 0.85),
        NewsSource(id: "nyt-business", name: "NY Times Business", rssURL: URL(string: "https://rss.nytimes.com/services/xml/rss/nyt/Business.xml")!, category: .business, bias: .leanLeft, reliability: 0.9),

        // Science
        NewsSource(id: "science-daily", name: "Science Daily", rssURL: URL(string: "https://www.sciencedaily.com/rss/all.xml")!, category: .science, bias: .center, reliability: 0.95),
        NewsSource(id: "nyt-science", name: "NY Times Science", rssURL: URL(string: "https://rss.nytimes.com/services/xml/rss/nyt/Science.xml")!, category: .science, bias: .leanLeft, reliability: 0.9),

        // Health
        NewsSource(id: "nyt-health", name: "NY Times Health", rssURL: URL(string: "https://rss.nytimes.com/services/xml/rss/nyt/Health.xml")!, category: .health, bias: .leanLeft, reliability: 0.9),

        // Sports
        NewsSource(id: "espn", name: "ESPN", rssURL: URL(string: "https://www.espn.com/espn/rss/news")!, category: .sports, bias: .center, reliability: 0.85),
        NewsSource(id: "nyt-sports", name: "NY Times Sports", rssURL: URL(string: "https://rss.nytimes.com/services/xml/rss/nyt/Sports.xml")!, category: .sports, bias: .leanLeft, reliability: 0.9),

        // Entertainment
        NewsSource(id: "variety", name: "Variety", rssURL: URL(string: "https://variety.com/feed/")!, category: .entertainment, bias: .center, reliability: 0.85),
        NewsSource(id: "ew", name: "Entertainment Weekly", rssURL: URL(string: "https://ew.com/feed/")!, category: .entertainment, bias: .center, reliability: 0.8),

        // Politics
        NewsSource(id: "politico", name: "Politico", rssURL: URL(string: "https://rss.politico.com/politics-news.xml")!, category: .politics, bias: .center, reliability: 0.85),
        NewsSource(id: "nyt-politics", name: "NY Times Politics", rssURL: URL(string: "https://rss.nytimes.com/services/xml/rss/nyt/Politics.xml")!, category: .politics, bias: .leanLeft, reliability: 0.9),
    ]

    private init() {}

    // MARK: - Fetch All

    func fetchAllNews() async {
        isLoading = true
        error = nil

        print("📰 NewsAggregator: Starting to fetch \(defaultSources.count) sources...")

        var allArticles: [NewsArticle] = []
        var successCount = 0
        var failCount = 0

        // Filter out unhealthy feeds (3+ consecutive failures, 1 hour cooldown)
        let healthySources = defaultSources.filter { source in
            if feedHealth.shouldSkip(source) {
                print("  Skipping unhealthy feed: \(source.name)")
                return false
            }
            return true
        }

        // Fetch sources in parallel batches of 5 to balance speed and memory
        let batchSize = 5
        await withTaskGroup(of: (NewsSource, Result<[NewsArticle], Error>).self) { group in
            var enqueued = 0

            for source in healthySources {
                // Limit concurrency: wait for one result before adding beyond batchSize
                if enqueued >= batchSize {
                    if let (src, result) = await group.next() {
                        switch result {
                        case .success(let articles):
                            successCount += 1
                            feedHealth.recordSuccess(src)
                            print("  \(src.name): \(articles.count) articles")
                            allArticles.append(contentsOf: articles)
                        case .failure(let error):
                            failCount += 1
                            feedHealth.recordFailure(src)
                            print("  \(src.name): \(error.localizedDescription)")
                        }
                    }
                }

                group.addTask { [parser] in
                    do {
                        let articles = try await parser.parseFeed(from: source)
                        return (source, .success(articles))
                    } catch {
                        return (source, .failure(error))
                    }
                }
                enqueued += 1
            }

            // Collect remaining results
            for await (src, result) in group {
                switch result {
                case .success(let articles):
                    successCount += 1
                    feedHealth.recordSuccess(src)
                    print("  \(src.name): \(articles.count) articles")
                    allArticles.append(contentsOf: articles)
                case .failure(let error):
                    failCount += 1
                    feedHealth.recordFailure(src)
                    print("  \(src.name): \(error.localizedDescription)")
                }
            }
        }

        print("📰 Fetch complete: \(successCount) succeeded, \(failCount) failed, \(allArticles.count) total articles")

        // If all sources failed, set error message
        if allArticles.isEmpty {
            self.error = "Failed to fetch news from any source. Check your internet connection."
            print("⚠️ No articles! Error: \(self.error ?? "unknown")")
        }

        // Filter out advertisements and promotional content
        let filtered = ContentFilter.shared.filterArticles(allArticles)

        // Sort by date, breaking news first
        articles = filtered.sorted { a, b in
            if a.isBreakingNews != b.isBreakingNews {
                return a.isBreakingNews
            }
            return a.publishedDate > b.publishedDate
        }

        lastRefresh = Date()
        isLoading = false

        print("📰 Final article count after filtering: \(articles.count)")
    }

    // MARK: - Fetch by Category

    func fetchNews(for category: NewsCategory) async {
        isLoading = true
        error = nil

        let categorySources = defaultSources.filter { $0.category == category }
        var categoryArticles: [NewsArticle] = []

        await withTaskGroup(of: [NewsArticle].self) { group in
            for source in categorySources {
                group.addTask {
                    do {
                        return try await self.parser.parseFeed(from: source)
                    } catch {
                        print("Failed to fetch \(source.name): \(error)")
                        return []
                    }
                }
            }

            for await sourceArticles in group {
                categoryArticles.append(contentsOf: sourceArticles)
            }
        }

        // Merge with existing articles
        let existingOtherCategories = articles.filter { $0.category != category }
        let sortedCategoryArticles = categoryArticles.sorted { $0.publishedDate > $1.publishedDate }

        articles = (sortedCategoryArticles + existingOtherCategories).sorted { a, b in
            if a.isBreakingNews != b.isBreakingNews {
                return a.isBreakingNews
            }
            return a.publishedDate > b.publishedDate
        }

        lastRefresh = Date()
        isLoading = false
    }

    // MARK: - Filtered Access

    func articles(for category: NewsCategory) -> [NewsArticle] {
        articles.filter { $0.category == category }
    }

    func breakingNews() -> [NewsArticle] {
        articles.filter { $0.isBreakingNews }
    }

    func topStories(count: Int = 10) -> [NewsArticle] {
        Array(articles.prefix(count))
    }

    func recentArticles(hours: Int = 24) -> [NewsArticle] {
        let cutoff = Date().addingTimeInterval(-Double(hours * 3600))
        return articles.filter { $0.publishedDate > cutoff }
    }

    // MARK: - Update Article

    func updateArticle(_ article: NewsArticle, with updates: (inout NewsArticle) -> Void) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            var updated = articles[index]
            updates(&updated)
            articles[index] = updated
        }
    }
}
