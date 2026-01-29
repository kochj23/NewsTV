//
//  NewsAggregator.swift
//  NewsTV
//
//  Aggregates news from multiple RSS sources
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

@MainActor
class NewsAggregator: ObservableObject {
    static let shared = NewsAggregator()

    @Published var articles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var lastRefresh: Date?
    @Published var error: String?

    private let parser = RSSParser.shared

    // MARK: - Default Sources

    let defaultSources: [NewsSource] = [
        // Top Stories
        NewsSource(id: "ap", name: "Associated Press", rssURL: URL(string: "https://rsshub.app/apnews/topics/apf-topnews")!, category: .topStories, bias: .center, reliability: 0.95),
        NewsSource(id: "reuters", name: "Reuters", rssURL: URL(string: "https://rsshub.app/reuters/world")!, category: .topStories, bias: .center, reliability: 0.95),
        NewsSource(id: "npr", name: "NPR", rssURL: URL(string: "https://feeds.npr.org/1001/rss.xml")!, category: .topStories, bias: .leanLeft, reliability: 0.9),

        // US News
        NewsSource(id: "nyt-us", name: "NY Times US", rssURL: URL(string: "https://rss.nytimes.com/services/xml/rss/nyt/US.xml")!, category: .us, bias: .leanLeft, reliability: 0.9),
        NewsSource(id: "wsj-us", name: "WSJ US", rssURL: URL(string: "https://feeds.a]wsj.com/wsj/xml/rss/3_7011.xml")!, category: .us, bias: .leanRight, reliability: 0.9),

        // World
        NewsSource(id: "bbc-world", name: "BBC World", rssURL: URL(string: "https://feeds.bbci.co.uk/news/world/rss.xml")!, category: .world, bias: .center, reliability: 0.9),
        NewsSource(id: "guardian-world", name: "The Guardian", rssURL: URL(string: "https://www.theguardian.com/world/rss")!, category: .world, bias: .left, reliability: 0.85),

        // Technology
        NewsSource(id: "techcrunch", name: "TechCrunch", rssURL: URL(string: "https://techcrunch.com/feed/")!, category: .technology, bias: .center, reliability: 0.85),
        NewsSource(id: "arstechnica", name: "Ars Technica", rssURL: URL(string: "https://feeds.arstechnica.com/arstechnica/index")!, category: .technology, bias: .center, reliability: 0.9),
        NewsSource(id: "verge", name: "The Verge", rssURL: URL(string: "https://www.theverge.com/rss/index.xml")!, category: .technology, bias: .leanLeft, reliability: 0.85),

        // Business
        NewsSource(id: "cnbc", name: "CNBC", rssURL: URL(string: "https://www.cnbc.com/id/100003114/device/rss/rss.html")!, category: .business, bias: .center, reliability: 0.85),
        NewsSource(id: "bloomberg", name: "Bloomberg", rssURL: URL(string: "https://feeds.bloomberg.com/markets/news.rss")!, category: .business, bias: .center, reliability: 0.9),

        // Science
        NewsSource(id: "science-daily", name: "Science Daily", rssURL: URL(string: "https://www.sciencedaily.com/rss/all.xml")!, category: .science, bias: .center, reliability: 0.95),
        NewsSource(id: "nature", name: "Nature", rssURL: URL(string: "https://www.nature.com/nature.rss")!, category: .science, bias: .center, reliability: 0.98),

        // Health
        NewsSource(id: "medical-news", name: "Medical News Today", rssURL: URL(string: "https://www.medicalnewstoday.com/newsfeeds/rss/medical_news.xml")!, category: .health, bias: .center, reliability: 0.85),

        // Sports
        NewsSource(id: "espn", name: "ESPN", rssURL: URL(string: "https://www.espn.com/espn/rss/news")!, category: .sports, bias: .center, reliability: 0.85),

        // Entertainment
        NewsSource(id: "variety", name: "Variety", rssURL: URL(string: "https://variety.com/feed/")!, category: .entertainment, bias: .center, reliability: 0.85),

        // Politics
        NewsSource(id: "politico", name: "Politico", rssURL: URL(string: "https://rss.politico.com/politics-news.xml")!, category: .politics, bias: .center, reliability: 0.85),
        NewsSource(id: "hill", name: "The Hill", rssURL: URL(string: "https://thehill.com/feed/")!, category: .politics, bias: .center, reliability: 0.85),
    ]

    private init() {}

    // MARK: - Fetch All

    func fetchAllNews() async {
        isLoading = true
        error = nil

        var allArticles: [NewsArticle] = []

        await withTaskGroup(of: [NewsArticle].self) { group in
            for source in defaultSources {
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
                allArticles.append(contentsOf: sourceArticles)
            }
        }

        // Sort by date, breaking news first
        articles = allArticles.sorted { a, b in
            if a.isBreakingNews != b.isBreakingNews {
                return a.isBreakingNews
            }
            return a.publishedDate > b.publishedDate
        }

        lastRefresh = Date()
        isLoading = false
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
