//
//  ContentFilter.swift
//  NewsTV
//
//  Filters out advertisements, sponsored content, and promotional articles
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

@MainActor
class ContentFilter {
    static let shared = ContentFilter()

    private init() {}

    // MARK: - Advertisement Detection

    /// Keywords that indicate promotional/advertising content
    private let adKeywords: Set<String> = [
        "sponsored",
        "advertisement",
        "promoted",
        "partner content",
        "paid post",
        "affiliate",
        "promo code",
        "discount code",
        "limited time offer",
        "special offer",
        "exclusive deal",
        "save now",
        "buy now",
        "shop now",
        "order now",
        "subscribe now",
        "sign up now",
        "free trial",
        "act now",
        "don't miss",
        "hurry",
        "deal alert",
        "price drop"
    ]

    /// Phrases that indicate corporate PR/deals rather than news
    private let prKeywords: Set<String> = [
        "announces partnership",
        "signs deal",
        "reaches agreement",
        "expands service",
        "launches promotion",
        "offers discount",
        "introduces new plan",
        "unveils package",
        "rolls out offer"
    ]

    /// Sources known for mixing ads with content
    private let suspiciousSources: Set<String> = [
        "prnewswire",
        "businesswire",
        "globenewswire",
        "accesswire"
    ]

    /// Companies/brands when mentioned in deal context
    private let dealContextBrands: Set<String> = [
        "directv",
        "dish network",
        "comcast",
        "xfinity",
        "spectrum",
        "at&t",
        "verizon",
        "t-mobile"
    ]

    // MARK: - Filtering

    func filterArticles(_ articles: [NewsArticle]) -> [NewsArticle] {
        articles.filter { !isAdvertisement($0) }
    }

    func isAdvertisement(_ article: NewsArticle) -> Bool {
        let title = article.title.lowercased()
        let description = article.rssDescription?.lowercased() ?? ""
        let source = article.source.id.lowercased()
        let combined = title + " " + description

        // Check for explicit ad keywords
        for keyword in adKeywords {
            if combined.contains(keyword) {
                return true
            }
        }

        // Check for PR/deal announcements
        for keyword in prKeywords {
            if combined.contains(keyword) {
                return true
            }
        }

        // Check suspicious sources
        for suspiciousSource in suspiciousSources {
            if source.contains(suspiciousSource) {
                return true
            }
        }

        // Check for deal/brand context (e.g., "DirecTV deal", "Comcast offers")
        for brand in dealContextBrands {
            if title.contains(brand) {
                // Check if it's a deal/offer context
                let dealWords = ["deal", "offer", "plan", "package", "price", "discount", "save", "bundle", "promotion"]
                for dealWord in dealWords {
                    if title.contains(dealWord) {
                        return true
                    }
                }
            }
        }

        // Check for clickbait patterns
        if isClickbait(title) {
            return true
        }

        return false
    }

    private func isClickbait(_ title: String) -> Bool {
        let clickbaitPatterns = [
            "you won't believe",
            "this one trick",
            "doctors hate",
            "secret revealed",
            "what happened next",
            "mind-blowing",
            "jaw-dropping",
            "game-changer",
            "life-changing",
            "this changes everything"
        ]

        let lower = title.lowercased()
        for pattern in clickbaitPatterns {
            if lower.contains(pattern) {
                return true
            }
        }

        // Excessive punctuation (clickbait indicator)
        let exclamationCount = title.filter { $0 == "!" }.count
        let questionCount = title.filter { $0 == "?" }.count
        if exclamationCount > 1 || questionCount > 1 {
            return true
        }

        // ALL CAPS words (more than 2)
        let words = title.split(separator: " ")
        let capsWords = words.filter { word in
            word.count > 3 && word == word.uppercased() && word.first?.isLetter == true
        }
        if capsWords.count > 2 {
            return true
        }

        return false
    }

    // MARK: - Quality Scoring

    func qualityScore(_ article: NewsArticle) -> Double {
        var score = 1.0

        // Penalize short titles
        if article.title.count < 20 {
            score -= 0.2
        }

        // Penalize missing description
        if article.rssDescription == nil || article.rssDescription?.isEmpty == true {
            score -= 0.1
        }

        // Boost reliable sources
        score += article.source.reliability * 0.3

        // Penalize clickbait-adjacent patterns
        let title = article.title.lowercased()
        if title.contains("!") { score -= 0.1 }
        if title.contains("?") && !title.contains("who") && !title.contains("what") && !title.contains("when") && !title.contains("where") && !title.contains("why") && !title.contains("how") {
            score -= 0.1
        }

        return max(0, min(1, score))
    }
}
