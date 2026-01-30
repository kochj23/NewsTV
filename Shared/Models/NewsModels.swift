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
    case disney = "Disney"
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
        case .disney: return "sparkles"
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
        case .disney: return "1E90FF"
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

// MARK: - Watch Later Item

struct WatchLaterItem: Identifiable, Codable, Hashable {
    let id: UUID
    let articleId: UUID
    let articleTitle: String
    let articleURL: URL
    let source: String
    let category: NewsCategory
    let addedDate: Date
    var isCompleted: Bool

    init(from article: NewsArticle) {
        self.id = UUID()
        self.articleId = article.id
        self.articleTitle = article.title
        self.articleURL = article.url
        self.source = article.source.name
        self.category = article.category
        self.addedDate = Date()
        self.isCompleted = false
    }
}

// MARK: - Keyword Alert

struct KeywordAlert: Identifiable, Codable, Hashable {
    let id: UUID
    var keyword: String
    var isEnabled: Bool
    var notifyOnMatch: Bool
    var matchCount: Int
    var lastMatchDate: Date?

    init(keyword: String) {
        self.id = UUID()
        self.keyword = keyword
        self.isEnabled = true
        self.notifyOnMatch = true
        self.matchCount = 0
        self.lastMatchDate = nil
    }
}

// MARK: - Trending Topic

struct TrendingTopic: Identifiable, Hashable {
    let id: UUID
    let topic: String
    let articleCount: Int
    let sources: [String]
    let sentiment: Double?
    let firstSeen: Date

    init(topic: String, articleCount: Int, sources: [String], sentiment: Double? = nil) {
        self.id = UUID()
        self.topic = topic
        self.articleCount = articleCount
        self.sources = sources
        self.sentiment = sentiment
        self.firstSeen = Date()
    }
}

// MARK: - User Preference Profile

struct UserPreferenceProfile: Codable {
    var categoryWeights: [NewsCategory: Double]
    var sourceWeights: [String: Double]
    var topicInterests: [String: Double]
    var readArticleIds: Set<UUID>
    var viewDurations: [UUID: TimeInterval]

    init() {
        self.categoryWeights = [:]
        self.sourceWeights = [:]
        self.topicInterests = [:]
        self.readArticleIds = []
        self.viewDurations = [:]
    }

    mutating func recordView(article: NewsArticle, duration: TimeInterval) {
        readArticleIds.insert(article.id)
        viewDurations[article.id] = duration

        // Boost category weight based on view duration
        let boost = min(duration / 60.0, 1.0) * 0.1
        categoryWeights[article.category, default: 0.5] += boost
        categoryWeights[article.category] = min(categoryWeights[article.category]!, 1.0)

        // Boost source weight
        sourceWeights[article.source.id, default: 0.5] += boost * 0.5
        sourceWeights[article.source.id] = min(sourceWeights[article.source.id]!, 1.0)
    }

    func relevanceScore(for article: NewsArticle) -> Double {
        let categoryScore = categoryWeights[article.category] ?? 0.5
        let sourceScore = sourceWeights[article.source.id] ?? 0.5
        let recencyScore = max(0, 1.0 - (Date().timeIntervalSince(article.publishedDate) / 86400))

        return (categoryScore * 0.4) + (sourceScore * 0.3) + (recencyScore * 0.3)
    }
}

// MARK: - Custom RSS Feed

struct CustomRSSFeed: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var url: URL
    var category: NewsCategory
    var isEnabled: Bool
    var lastFetchDate: Date?
    var articleCount: Int

    init(name: String, url: URL, category: NewsCategory = .topStories) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.category = category
        self.isEnabled = true
        self.lastFetchDate = nil
        self.articleCount = 0
    }
}

// MARK: - Weather Data

struct WeatherData: Codable {
    let temperature: Double
    let condition: WeatherCondition
    let high: Double
    let low: Double
    let location: String
    let lastUpdated: Date

    enum WeatherCondition: String, Codable {
        case clear = "Clear"
        case cloudy = "Cloudy"
        case partlyCloudy = "Partly Cloudy"
        case rain = "Rain"
        case snow = "Snow"
        case thunderstorm = "Thunderstorm"
        case fog = "Fog"
        case windy = "Windy"
        case unknown = "Unknown"

        var icon: String {
            switch self {
            case .clear: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .partlyCloudy: return "cloud.sun.fill"
            case .rain: return "cloud.rain.fill"
            case .snow: return "cloud.snow.fill"
            case .thunderstorm: return "cloud.bolt.fill"
            case .fog: return "cloud.fog.fill"
            case .windy: return "wind"
            case .unknown: return "questionmark.circle"
            }
        }
    }
}

// MARK: - Audio Briefing Progress

struct AudioBriefingProgress: Codable {
    var briefingId: UUID
    var currentIndex: Int
    var currentPosition: TimeInterval
    var lastUpdated: Date
    var deviceId: String

    init(briefingId: UUID, deviceId: String) {
        self.briefingId = briefingId
        self.currentIndex = 0
        self.currentPosition = 0
        self.lastUpdated = Date()
        self.deviceId = deviceId
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

    // New settings for features
    var enablePersonalizedFeed: Bool
    var enableBackgroundRefresh: Bool
    var backgroundRefreshInterval: TimeInterval
    var localNewsLocation: String?
    var localNewsZipCode: String?
    var enableWeatherWidget: Bool
    var temperatureUnit: TemperatureUnit
    var theme: AppTheme
    var enableTrendingTicker: Bool
    var enableiCloudSync: Bool
    var screensaverIdleTime: TimeInterval
    var enableScreensaverMode: Bool
    var keywordAlerts: [KeywordAlert]
    var customFeeds: [CustomRSSFeed]

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
        fontSize: FontSize = .large,
        enablePersonalizedFeed: Bool = true,
        enableBackgroundRefresh: Bool = true,
        backgroundRefreshInterval: TimeInterval = 300,
        localNewsLocation: String? = nil,
        localNewsZipCode: String? = nil,
        enableWeatherWidget: Bool = false,  // Disabled by default - WeatherKit crashes on tvOS beta
        temperatureUnit: TemperatureUnit = .fahrenheit,
        theme: AppTheme = .dark,
        enableTrendingTicker: Bool = true,
        enableiCloudSync: Bool = true,
        screensaverIdleTime: TimeInterval = 300,
        enableScreensaverMode: Bool = true,
        keywordAlerts: [KeywordAlert] = [],
        customFeeds: [CustomRSSFeed] = []
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
        self.enablePersonalizedFeed = enablePersonalizedFeed
        self.enableBackgroundRefresh = enableBackgroundRefresh
        self.backgroundRefreshInterval = backgroundRefreshInterval
        self.localNewsLocation = localNewsLocation
        self.localNewsZipCode = localNewsZipCode
        self.enableWeatherWidget = enableWeatherWidget
        self.temperatureUnit = temperatureUnit
        self.theme = theme
        self.enableTrendingTicker = enableTrendingTicker
        self.enableiCloudSync = enableiCloudSync
        self.screensaverIdleTime = screensaverIdleTime
        self.enableScreensaverMode = enableScreensaverMode
        self.keywordAlerts = keywordAlerts
        self.customFeeds = customFeeds
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

    enum TemperatureUnit: String, Codable, CaseIterable {
        case fahrenheit = "Fahrenheit"
        case celsius = "Celsius"

        var symbol: String {
            switch self {
            case .fahrenheit: return "°F"
            case .celsius: return "°C"
            }
        }
    }

    enum AppTheme: String, Codable, CaseIterable {
        case dark = "Dark"
        case light = "Light"
        case auto = "Auto"
    }
}
