//
//  StoryClusterEngine.swift
//  NewsTV
//
//  Groups related articles from multiple sources for perspective comparison
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import NaturalLanguage

@MainActor
class StoryClusterEngine: ObservableObject {
    static let shared = StoryClusterEngine()

    @Published var clusters: [StoryCluster] = []
    @Published var isProcessing = false

    private let similarityThreshold: Double = 0.6

    private init() {}

    // MARK: - Clustering

    func clusterArticles(_ articles: [NewsArticle]) async -> [StoryCluster] {
        isProcessing = true
        defer { isProcessing = false }

        var remainingArticles = articles
        var newClusters: [StoryCluster] = []

        while !remainingArticles.isEmpty {
            let seed = remainingArticles.removeFirst()
            var clusterArticles = [seed]

            // Find similar articles
            var indicesToRemove: [Int] = []
            for (index, article) in remainingArticles.enumerated() {
                if areSimilar(seed, article) {
                    clusterArticles.append(article)
                    indicesToRemove.append(index)
                }
            }

            // Remove matched articles (in reverse to maintain indices)
            for index in indicesToRemove.reversed() {
                remainingArticles.remove(at: index)
            }

            // Only create cluster if multiple sources
            if clusterArticles.count > 1 {
                let uniqueSources = Set(clusterArticles.map { $0.source.id })
                if uniqueSources.count > 1 {
                    let topic = extractTopic(from: clusterArticles)
                    let perspectives = analyzePerspectives(clusterArticles)
                    let cluster = StoryCluster(
                        topic: topic,
                        articles: clusterArticles,
                        perspectives: perspectives
                    )
                    newClusters.append(cluster)
                }
            }
        }

        // Sort by article count (bigger stories first)
        clusters = newClusters.sorted { $0.articleCount > $1.articleCount }
        return clusters
    }

    // MARK: - Similarity Detection

    private func areSimilar(_ a: NewsArticle, _ b: NewsArticle) -> Bool {
        // Quick check: same category
        guard a.category == b.category else { return false }

        // Time proximity check (within 48 hours)
        let timeDiff = abs(a.publishedDate.timeIntervalSince(b.publishedDate))
        guard timeDiff < 172800 else { return false }

        // Title similarity using NLP
        let embedding1 = getEmbedding(for: a.title)
        let embedding2 = getEmbedding(for: b.title)

        if let e1 = embedding1, let e2 = embedding2 {
            let similarity = cosineSimilarity(e1, e2)
            return similarity > similarityThreshold
        }

        // Fallback: keyword overlap
        let keywords1 = extractKeywords(from: a.title)
        let keywords2 = extractKeywords(from: b.title)
        let overlap = keywords1.intersection(keywords2)
        let overlapRatio = Double(overlap.count) / Double(max(keywords1.count, keywords2.count, 1))

        return overlapRatio > 0.4
    }

    private func getEmbedding(for text: String) -> [Double]? {
        let embedding = NLEmbedding.sentenceEmbedding(for: .english)
        return embedding?.vector(for: text)
    }

    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0 }

        var dotProduct: Double = 0
        var normA: Double = 0
        var normB: Double = 0

        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }

        let denominator = sqrt(normA) * sqrt(normB)
        return denominator > 0 ? dotProduct / denominator : 0
    }

    private func extractKeywords(from text: String) -> Set<String> {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text.lowercased()

        var keywords: Set<String> = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
            if let tag = tag, tag == .noun || tag == .verb || tag == .adjective {
                let word = String(text[range]).lowercased()
                if word.count > 3 { // Skip short words
                    keywords.insert(word)
                }
            }
            return true
        }

        return keywords
    }

    // MARK: - Topic Extraction

    private func extractTopic(from articles: [NewsArticle]) -> String {
        // Combine all titles
        let combinedText = articles.map { $0.title }.joined(separator: " ")

        // Find most common significant words
        var wordCounts: [String: Int] = [:]
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = combinedText

        tagger.enumerateTags(in: combinedText.startIndex..<combinedText.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, range in
            if let tag = tag, tag == .noun {
                let word = String(combinedText[range])
                if word.count > 2 {
                    wordCounts[word, default: 0] += 1
                }
            }
            return true
        }

        // Get top keywords for topic
        let topWords = wordCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }

        return topWords.isEmpty ? articles.first?.title ?? "Story" : topWords.joined(separator: " ")
    }

    // MARK: - Perspective Analysis

    private func analyzePerspectives(_ articles: [NewsArticle]) -> PerspectiveBreakdown? {
        // Group by source bias
        var leftArticles: [NewsArticle] = []
        var centerArticles: [NewsArticle] = []
        var rightArticles: [NewsArticle] = []

        for article in articles {
            switch article.source.bias {
            case .farLeft, .left, .leanLeft:
                leftArticles.append(article)
            case .center:
                centerArticles.append(article)
            case .leanRight, .right, .farRight:
                rightArticles.append(article)
            }
        }

        // Extract perspectives from each group
        let leftPerspective = leftArticles.first?.rssDescription
        let centerPerspective = centerArticles.first?.rssDescription
        let rightPerspective = rightArticles.first?.rssDescription

        // Find shared facts (common words across all perspectives)
        let allDescriptions = articles.compactMap { $0.rssDescription }
        let sharedFacts = findCommonPhrases(in: allDescriptions)

        // Find contentions (words that appear in some but not all)
        let contentions = findDifferingPhrases(in: allDescriptions)

        return PerspectiveBreakdown(
            leftPerspective: leftPerspective,
            centerPerspective: centerPerspective,
            rightPerspective: rightPerspective,
            sharedFacts: sharedFacts,
            contentions: contentions
        )
    }

    private func findCommonPhrases(in texts: [String]) -> [String] {
        guard texts.count > 1 else { return [] }

        var wordSets: [Set<String>] = []
        for text in texts {
            wordSets.append(extractKeywords(from: text))
        }

        var common = wordSets[0]
        for set in wordSets.dropFirst() {
            common = common.intersection(set)
        }

        return Array(common.prefix(5))
    }

    private func findDifferingPhrases(in texts: [String]) -> [String] {
        guard texts.count > 1 else { return [] }

        var allWords: Set<String> = []
        var wordSets: [Set<String>] = []

        for text in texts {
            let keywords = extractKeywords(from: text)
            wordSets.append(keywords)
            allWords.formUnion(keywords)
        }

        // Words that appear in some but not all
        var differing: Set<String> = []
        for word in allWords {
            let appearsIn = wordSets.filter { $0.contains(word) }.count
            if appearsIn > 0 && appearsIn < wordSets.count {
                differing.insert(word)
            }
        }

        return Array(differing.prefix(5))
    }

    // MARK: - Query

    func cluster(for article: NewsArticle) -> StoryCluster? {
        clusters.first { $0.articles.contains(where: { $0.id == article.id }) }
    }

    func topClusters(count: Int = 5) -> [StoryCluster] {
        Array(clusters.prefix(count))
    }
}
