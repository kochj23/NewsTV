//
//  TrendingTopicsEngine.swift
//  NewsTV
//
//  Analyzes articles to identify trending topics
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import NaturalLanguage

@MainActor
class TrendingTopicsEngine: ObservableObject {
    static let shared = TrendingTopicsEngine()

    @Published var trendingTopics: [TrendingTopic] = []
    @Published var isAnalyzing = false

    private var lastAnalysis: Date?
    private let analysisInterval: TimeInterval = 300 // 5 minutes

    private init() {}

    // MARK: - Analysis

    func analyzeTrends(from articles: [NewsArticle]) {
        // Rate limit analysis
        if let last = lastAnalysis, Date().timeIntervalSince(last) < analysisInterval {
            return
        }

        isAnalyzing = true
        defer {
            isAnalyzing = false
            lastAnalysis = Date()
        }

        // Extract entities and keywords from all articles
        var topicCounts: [String: (count: Int, sources: Set<String>, sentiment: Double)] = [:]

        for article in articles {
            let topics = extractTopics(from: article.title)

            for topic in topics {
                let normalized = topic.lowercased().capitalized
                var current = topicCounts[normalized] ?? (count: 0, sources: [], sentiment: 0)
                current.count += 1
                current.sources.insert(article.source.name)
                if let sentiment = article.sentiment?.score {
                    current.sentiment = (current.sentiment + sentiment) / 2
                }
                topicCounts[normalized] = current
            }
        }

        // Filter and sort by count
        let trending = topicCounts
            .filter { $0.value.count >= 2 && $0.value.sources.count >= 2 } // At least 2 articles from 2 sources
            .sorted { $0.value.count > $1.value.count }
            .prefix(10)
            .map { (topic, data) in
                TrendingTopic(
                    topic: topic,
                    articleCount: data.count,
                    sources: Array(data.sources),
                    sentiment: data.sentiment
                )
            }

        trendingTopics = Array(trending)
    }

    private func extractTopics(from text: String) -> [String] {
        var topics: [String] = []

        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

        // Extract named entities (people, places, organizations)
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            if let tag = tag {
                switch tag {
                case .personalName, .organizationName, .placeName:
                    let entity = String(text[range])
                    if entity.count > 2 && !isCommonWord(entity) {
                        topics.append(entity)
                    }
                default:
                    break
                }
            }
            return true
        }

        // Also extract significant nouns
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
            if tag == .noun {
                let word = String(text[range])
                if word.count > 4 && word.first?.isUppercase == true && !isCommonWord(word) {
                    topics.append(word)
                }
            }
            return true
        }

        return topics
    }

    private func isCommonWord(_ word: String) -> Bool {
        let common = Set([
            "the", "and", "for", "are", "but", "not", "you", "all", "can", "her",
            "was", "one", "our", "out", "day", "had", "has", "his", "how", "its",
            "may", "new", "now", "old", "see", "way", "who", "did", "get", "let",
            "say", "she", "too", "use", "says", "said", "news", "report", "reports",
            "today", "year", "years", "time", "week", "month", "people", "first",
            "last", "after", "before", "more", "most", "some", "what", "when",
            "where", "which", "while", "about", "could", "would", "their", "there",
            "these", "those", "being", "other", "video", "watch", "live", "update"
        ])
        return common.contains(word.lowercased())
    }

    // MARK: - Query

    func articlesForTopic(_ topic: TrendingTopic, from articles: [NewsArticle]) -> [NewsArticle] {
        let topicLower = topic.topic.lowercased()
        return articles.filter { article in
            article.title.lowercased().contains(topicLower) ||
            (article.rssDescription?.lowercased().contains(topicLower) ?? false)
        }
    }

    func topTrending(count: Int = 5) -> [TrendingTopic] {
        Array(trendingTopics.prefix(count))
    }

    func tickerText() -> String {
        trendingTopics.prefix(5).map { "\($0.topic) (\($0.articleCount))" }.joined(separator: "  •  ")
    }
}
