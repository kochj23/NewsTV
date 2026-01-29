//
//  NewsModels.swift
//  NewsTV
//
//  Core data models for news articles
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

// MARK: - News Article

struct NewsArticle: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let source: NewsSource
    let url: URL
    let publishedDate: Date
    let category: NewsCategory
    let rssDescription: String?
    let imageURL: URL?
    var summary: String?
    var fullSummary: String?
    var keyPoints: [String]?
    var sentiment: SentimentResult?
    var entities: [ExtractedEntity]?
    var biasRating: BiasRating?
    var isRead: Bool
    var isBreakingNews: Bool
    var importance: Int
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        title: String,
        source: NewsSource,
        url: URL,
        publishedDate: Date,
        category: NewsCategory,
        rssDescription: String? = nil,
        imageURL: URL? = nil,
        summary: String? = nil,
        fullSummary: String? = nil,
        keyPoints: [String]? = nil,
        sentiment: SentimentResult? = nil,
        entities: [ExtractedEntity]? = nil,
        biasRating: BiasRating? = nil,
        isRead: Bool = false,
        isBreakingNews: Bool = false,
        importance: Int = 5,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.source = source
        self.url = url
        self.publishedDate = publishedDate
        self.category = category
        self.rssDescription = rssDescription
        self.imageURL = imageURL
        self.summary = summary
        self.fullSummary = fullSummary
        self.keyPoints = keyPoints
        self.sentiment = sentiment
        self.entities = entities
        self.biasRating = biasRating
        self.isRead = isRead
        self.isBreakingNews = isBreakingNews
        self.importance = importance
        self.isFavorite = isFavorite
    }

    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedDate, relativeTo: Date())
    }

    var isRecent: Bool {
        Date().timeIntervalSince(publishedDate) < 86400
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: NewsArticle, rhs: NewsArticle) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - News Source

struct NewsSource: Codable, Hashable {
    let id: String
    let name: String
    let rssURL: URL
    let category: NewsCategory
    let bias: SourceBias
    let reliability: Double
    let logoURL: URL?

    init(
        id: String,
        name: String,
        rssURL: URL,
        category: NewsCategory,
        bias: SourceBias = .center,
        reliability: Double = 0.8,
        logoURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.rssURL = rssURL
        self.category = category
        self.bias = bias
        self.reliability = reliability
        self.logoURL = logoURL
    }
}

// MARK: - News Category

enum NewsCategory: String, CaseIterable, Codable {
    case topStories = "Top Stories"
    case us = "US"
    case world = "World"
    case business = "Business"
    case technology = "Technology"
    case science = "Science"
    case health = "Health"
    case sports = "Sports"
    case entertainment = "Entertainment"
    case politics = "Politics"

    var icon: String {
        switch self {
        case .topStories: return "star.fill"
        case .us: return "flag.fill"
        case .world: return "globe"
        case .business: return "chart.line.uptrend.xyaxis"
        case .technology: return "cpu"
        case .science: return "atom"
        case .health: return "heart.fill"
        case .sports: return "sportscourt.fill"
        case .entertainment: return "film"
        case .politics: return "building.columns.fill"
        }
    }

    var color: String {
        switch self {
        case .topStories: return "FFD700"
        case .us: return "FF6B6B"
        case .world: return "4ECDC4"
        case .business: return "45B7D1"
        case .technology: return "96CEB4"
        case .science: return "DDA0DD"
        case .health: return "FF69B4"
        case .sports: return "98D8C8"
        case .entertainment: return "F7DC6F"
        case .politics: return "BB8FCE"
        }
    }
}

// MARK: - Source Bias

enum SourceBias: String, Codable {
    case farLeft = "Far Left"
    case left = "Left"
    case leanLeft = "Lean Left"
    case center = "Center"
    case leanRight = "Lean Right"
    case right = "Right"
    case farRight = "Far Right"

    var value: Double {
        switch self {
        case .farLeft: return -1.0
        case .left: return -0.66
        case .leanLeft: return -0.33
        case .center: return 0.0
        case .leanRight: return 0.33
        case .right: return 0.66
        case .farRight: return 1.0
        }
    }

    var color: String {
        switch self {
        case .farLeft, .left: return "3B82F6"
        case .leanLeft: return "60A5FA"
        case .center: return "A855F7"
        case .leanRight: return "F87171"
        case .right, .farRight: return "EF4444"
        }
    }

    var shortLabel: String {
        switch self {
        case .farLeft: return "FL"
        case .left: return "L"
        case .leanLeft: return "LL"
        case .center: return "C"
        case .leanRight: return "LR"
        case .right: return "R"
        case .farRight: return "FR"
        }
    }
}

// MARK: - Bias Rating (Content-Level)

struct BiasRating: Codable, Hashable {
    let score: Double // -1.0 (left) to 1.0 (right)
    let confidence: Double // 0.0 to 1.0
    let indicators: [BiasIndicator]

    var label: String {
        switch score {
        case ..<(-0.5): return "Left-Leaning"
        case -0.5..<(-0.2): return "Lean Left"
        case -0.2...0.2: return "Balanced"
        case 0.2..<0.5: return "Lean Right"
        default: return "Right-Leaning"
        }
    }
}

struct BiasIndicator: Codable, Hashable {
    let type: String
    let description: String
    let severity: Double
}

// MARK: - Sentiment Result

struct SentimentResult: Codable, Hashable {
    let score: Double // -1.0 (negative) to 1.0 (positive)
    let label: SentimentLabel
    let confidence: Double

    enum SentimentLabel: String, Codable {
        case positive = "Positive"
        case negative = "Negative"
        case neutral = "Neutral"
        case mixed = "Mixed"

        var icon: String {
            switch self {
            case .positive: return "face.smiling"
            case .negative: return "face.dashed"
            case .neutral: return "minus.circle"
            case .mixed: return "arrow.left.arrow.right"
            }
        }

        var color: String {
            switch self {
            case .positive: return "22C55E"
            case .negative: return "EF4444"
            case .neutral: return "6B7280"
            case .mixed: return "F59E0B"
            }
        }
    }
}

// MARK: - Extracted Entity

struct ExtractedEntity: Codable, Hashable, Identifiable {
    let id: UUID
    let text: String
    let type: EntityType
    let sentiment: Double?
    let count: Int

    init(id: UUID = UUID(), text: String, type: EntityType, sentiment: Double? = nil, count: Int = 1) {
        self.id = id
        self.text = text
        self.type = type
        self.sentiment = sentiment
        self.count = count
    }

    enum EntityType: String, Codable {
        case person = "Person"
        case organization = "Organization"
        case location = "Location"
        case event = "Event"
        case other = "Other"

        var icon: String {
            switch self {
            case .person: return "person.fill"
            case .organization: return "building.2.fill"
            case .location: return "mappin.circle.fill"
            case .event: return "calendar"
            case .other: return "tag.fill"
            }
        }
    }
}

// MARK: - Story Cluster

struct StoryCluster: Identifiable {
    let id: UUID
    let topic: String
    let articles: [NewsArticle]
    let perspectives: PerspectiveBreakdown?
    let firstSeen: Date
    let lastUpdated: Date

    init(id: UUID = UUID(), topic: String, articles: [NewsArticle], perspectives: PerspectiveBreakdown? = nil) {
        self.id = id
        self.topic = topic
        self.articles = articles
        self.perspectives = perspectives
        self.firstSeen = articles.map { $0.publishedDate }.min() ?? Date()
        self.lastUpdated = articles.map { $0.publishedDate }.max() ?? Date()
    }

    var articleCount: Int { articles.count }
    var sourceCount: Int { Set(articles.map { $0.source.id }).count }
}

// MARK: - Perspective Breakdown

struct PerspectiveBreakdown: Codable {
    let leftPerspective: String?
    let centerPerspective: String?
    let rightPerspective: String?
    let sharedFacts: [String]
    let contentions: [String]
}

// MARK: - Audio Briefing

struct AudioBriefing: Identifiable {
    let id: UUID
    let title: String
    let articles: [NewsArticle]
    let generatedDate: Date
    let duration: TimeInterval
    var isPlaying: Bool
    var currentIndex: Int

    init(id: UUID = UUID(), title: String, articles: [NewsArticle], duration: TimeInterval = 0) {
        self.id = id
        self.title = title
        self.articles = articles
        self.generatedDate = Date()
        self.duration = duration
        self.isPlaying = false
        self.currentIndex = 0
    }
}

// MARK: - App Settings

struct NewsTVSettings: Codable {
    var rotationInterval: TimeInterval
    var enableAudioBriefings: Bool
    var enableBreakingNewsAlerts: Bool
    var selectedCategories: [NewsCategory]
    var preferredVoice: String
    var speechRate: Float
    var enableSentimentColors: Bool
    var enableBiasIndicators: Bool
    var ambientModeEnabled: Bool
    var fontSize: FontSize

    init(
        rotationInterval: TimeInterval = 15,
        enableAudioBriefings: Bool = true,
        enableBreakingNewsAlerts: Bool = true,
        selectedCategories: [NewsCategory] = NewsCategory.allCases,
        preferredVoice: String = "com.apple.voice.compact.en-US.Samantha",
        speechRate: Float = 0.5,
        enableSentimentColors: Bool = true,
        enableBiasIndicators: Bool = true,
        ambientModeEnabled: Bool = true,
        fontSize: FontSize = .large
    ) {
        self.rotationInterval = rotationInterval
        self.enableAudioBriefings = enableAudioBriefings
        self.enableBreakingNewsAlerts = enableBreakingNewsAlerts
        self.selectedCategories = selectedCategories
        self.preferredVoice = preferredVoice
        self.speechRate = speechRate
        self.enableSentimentColors = enableSentimentColors
        self.enableBiasIndicators = enableBiasIndicators
        self.ambientModeEnabled = ambientModeEnabled
        self.fontSize = fontSize
    }

    enum FontSize: String, Codable, CaseIterable {
        case medium = "Medium"
        case large = "Large"
        case extraLarge = "Extra Large"

        var headlineSize: CGFloat {
            switch self {
            case .medium: return 32
            case .large: return 40
            case .extraLarge: return 48
            }
        }

        var bodySize: CGFloat {
            switch self {
            case .medium: return 24
            case .large: return 28
            case .extraLarge: return 32
            }
        }
    }
}
