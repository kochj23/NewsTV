//
//  SentimentAnalyzer.swift
//  NewsTV
//
//  On-device sentiment analysis using NaturalLanguage framework
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import NaturalLanguage

@MainActor
class SentimentAnalyzer: ObservableObject {
    static let shared = SentimentAnalyzer()

    @Published var isProcessing = false

    private init() {}

    // MARK: - Analyze Text

    func analyzeSentiment(of text: String) -> SentimentResult {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        var totalScore: Double = 0
        var count: Int = 0

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                count += 1
            }
            return true
        }

        let averageScore = count > 0 ? totalScore / Double(count) : 0

        let label: SentimentResult.SentimentLabel
        let confidence: Double

        switch averageScore {
        case 0.3...:
            label = .positive
            confidence = min(averageScore + 0.5, 1.0)
        case ..<(-0.3):
            label = .negative
            confidence = min(abs(averageScore) + 0.5, 1.0)
        case -0.1...0.1:
            label = .neutral
            confidence = 0.8
        default:
            label = .mixed
            confidence = 0.6
        }

        return SentimentResult(score: averageScore, label: label, confidence: confidence)
    }

    // MARK: - Analyze Article

    func analyzeArticle(_ article: NewsArticle) -> SentimentResult {
        var text = article.title

        if let description = article.rssDescription {
            text += " " + description
        }

        return analyzeSentiment(of: text)
    }

    // MARK: - Batch Analysis

    func analyzeBatch(_ articles: [NewsArticle]) async -> [UUID: SentimentResult] {
        isProcessing = true
        defer { isProcessing = false }

        var results: [UUID: SentimentResult] = [:]

        for article in articles {
            let result = analyzeArticle(article)
            results[article.id] = result
        }

        return results
    }

    // MARK: - Headline Sentiment Summary

    func headlineSentimentSummary(_ articles: [NewsArticle]) -> (positive: Int, negative: Int, neutral: Int) {
        var positive = 0
        var negative = 0
        var neutral = 0

        for article in articles {
            let result = analyzeArticle(article)
            switch result.label {
            case .positive:
                positive += 1
            case .negative:
                negative += 1
            case .neutral, .mixed:
                neutral += 1
            }
        }

        return (positive, negative, neutral)
    }
}
