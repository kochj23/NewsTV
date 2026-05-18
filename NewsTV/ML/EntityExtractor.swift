//
//  EntityExtractor.swift
//  NewsTV
//
//  Named Entity Recognition using NaturalLanguage framework
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import NaturalLanguage

@MainActor
class EntityExtractor: ObservableObject {
    static let shared = EntityExtractor()

    @Published var isProcessing = false

    private init() {}

    // MARK: - Extract Entities

    func extractEntities(from text: String) -> [ExtractedEntity] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        var entities: [String: (type: ExtractedEntity.EntityType, count: Int)] = [:]

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            guard let tag = tag else { return true }

            let entityText = String(text[tokenRange])
            let entityType: ExtractedEntity.EntityType

            switch tag {
            case .personalName:
                entityType = .person
            case .organizationName:
                entityType = .organization
            case .placeName:
                entityType = .location
            default:
                return true
            }

            if let existing = entities[entityText] {
                entities[entityText] = (existing.type, existing.count + 1)
            } else {
                entities[entityText] = (entityType, 1)
            }

            return true
        }

        return entities.map { key, value in
            ExtractedEntity(text: key, type: value.type, count: value.count)
        }.sorted { $0.count > $1.count }
    }

    // MARK: - Extract from Article

    func extractFromArticle(_ article: NewsArticle) -> [ExtractedEntity] {
        var text = article.title

        if let description = article.rssDescription {
            text += " " + description
        }

        return extractEntities(from: text)
    }

    // MARK: - Batch Extraction

    func extractFromArticles(_ articles: [NewsArticle]) async -> [UUID: [ExtractedEntity]] {
        isProcessing = true
        defer { isProcessing = false }

        var results: [UUID: [ExtractedEntity]] = [:]

        for article in articles {
            let entities = extractFromArticle(article)
            results[article.id] = entities
        }

        return results
    }

    // MARK: - Top Entities Across Articles

    func topEntities(from articles: [NewsArticle], limit: Int = 10) -> [ExtractedEntity] {
        var entityCounts: [String: (type: ExtractedEntity.EntityType, count: Int)] = [:]

        for article in articles {
            let entities = extractFromArticle(article)
            for entity in entities {
                if let existing = entityCounts[entity.text] {
                    entityCounts[entity.text] = (existing.type, existing.count + entity.count)
                } else {
                    entityCounts[entity.text] = (entity.type, entity.count)
                }
            }
        }

        return entityCounts.map { key, value in
            ExtractedEntity(text: key, type: value.type, count: value.count)
        }
        .sorted { $0.count > $1.count }
        .prefix(limit)
        .map { $0 }
    }

    // MARK: - People in the News

    func peopleInTheNews(from articles: [NewsArticle], limit: Int = 5) -> [ExtractedEntity] {
        topEntities(from: articles, limit: 20)
            .filter { $0.type == .person }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Organizations in the News

    func organizationsInTheNews(from articles: [NewsArticle], limit: Int = 5) -> [ExtractedEntity] {
        topEntities(from: articles, limit: 20)
            .filter { $0.type == .organization }
            .prefix(limit)
            .map { $0 }
    }
}
