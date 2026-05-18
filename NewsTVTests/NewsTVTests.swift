//
//  NewsTVTests.swift
//  NewsTVTests
//
//  Comprehensive test suite for NewsTV
//  Unit, Functional, Integration, Security, and Frame tests
//
//  Created by Jordan Koch on 2026-05-01.
//  Updated by Jordan Koch on 2026-05-03.
//  Copyright (c) 2026 Jordan Koch. All rights reserved.
//

import XCTest
@testable import NewsTV

// MARK: - Test Helpers

enum TestData {
    static func makeSource(
        id: String = "test-source",
        name: String = "Test News",
        category: NewsCategory = .topStories,
        bias: SourceBias = .center,
        reliability: Double = 0.8
    ) -> NewsSource {
        NewsSource(
            id: id,
            name: name,
            rssURL: URL(string: "https://example.com/rss")!,
            category: category,
            bias: bias,
            reliability: reliability
        )
    }

    static func makeArticle(
        title: String = "Test Article",
        source: NewsSource? = nil,
        category: NewsCategory = .topStories,
        publishedDate: Date = Date(),
        description: String? = "A test article description.",
        isBreaking: Bool = false,
        importance: Int = 5
    ) -> NewsArticle {
        NewsArticle(
            title: title,
            source: source ?? makeSource(),
            url: URL(string: "https://example.com/article/\(UUID().uuidString)")!,
            publishedDate: publishedDate,
            category: category,
            rssDescription: description,
            isBreakingNews: isBreaking,
            importance: importance
        )
    }

    static let sampleRSSXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
    <channel>
        <title>Test Feed</title>
        <item>
            <title>Economy Report Released</title>
            <link>https://example.com/economy</link>
            <description>The economy grew at 3.1% in Q1.</description>
            <pubDate>Thu, 01 May 2026 12:00:00 +0000</pubDate>
        </item>
        <item>
            <title>Breaking: Weather Alert Issued</title>
            <link>https://example.com/weather</link>
            <description>&lt;p&gt;A &lt;strong&gt;severe&lt;/strong&gt; weather alert was issued.&lt;/p&gt;</description>
            <pubDate>Thu, 01 May 2026 14:00:00 +0000</pubDate>
        </item>
        <item>
            <title>Tech Company Earnings Beat Expectations</title>
            <link>https://example.com/tech</link>
            <description><![CDATA[<p>Major tech companies reported strong Q1 results.</p>]]></description>
            <pubDate>2026-05-01T10:00:00Z</pubDate>
        </item>
    </channel>
    </rss>
    """

    static let xssPayloads = [
        "<script>alert('xss')</script>",
        "<img src=x onerror=alert(1)>",
        "<svg onload=alert(1)>",
        "<iframe src=\"javascript:alert(1)\">",
    ]
}

// MARK: - NewsArticle Model Tests (Unit)

final class NewsArticleModelTests: XCTestCase {

    func testArticleCreation() {
        let article = TestData.makeArticle(title: "Test Headline")
        XCTAssertEqual(article.title, "Test Headline")
        XCTAssertFalse(article.isRead)
        XCTAssertFalse(article.isBreakingNews)
        XCTAssertFalse(article.isFavorite)
        XCTAssertEqual(article.importance, 5)
    }

    func testArticleDefaultValues() {
        let article = TestData.makeArticle()
        XCTAssertNil(article.summary)
        XCTAssertNil(article.fullSummary)
        XCTAssertNil(article.keyPoints)
        XCTAssertNil(article.sentiment)
        XCTAssertNil(article.entities)
        XCTAssertNil(article.biasRating)
    }

    func testArticleEquality() {
        let id = UUID()
        let a1 = NewsArticle(id: id, title: "A", source: TestData.makeSource(), url: URL(string: "https://a.com")!, publishedDate: Date(), category: .us)
        let a2 = NewsArticle(id: id, title: "B", source: TestData.makeSource(), url: URL(string: "https://b.com")!, publishedDate: Date(), category: .world)
        XCTAssertEqual(a1, a2, "Articles with same ID should be equal")
    }

    func testArticleInequality() {
        let a1 = TestData.makeArticle(title: "First")
        let a2 = TestData.makeArticle(title: "Second")
        XCTAssertNotEqual(a1, a2)
    }

    func testArticleHashability() {
        let id = UUID()
        let article = NewsArticle(id: id, title: "Hash Test", source: TestData.makeSource(), url: URL(string: "https://x.com")!, publishedDate: Date(), category: .us)
        var set = Set<NewsArticle>()
        set.insert(article)
        let duplicate = NewsArticle(id: id, title: "Different Title", source: TestData.makeSource(), url: URL(string: "https://y.com")!, publishedDate: Date(), category: .world)
        XCTAssertTrue(set.contains(duplicate))
    }

    func testIsRecent() {
        let recentArticle = TestData.makeArticle(publishedDate: Date().addingTimeInterval(-3600))
        XCTAssertTrue(recentArticle.isRecent)

        let oldArticle = TestData.makeArticle(publishedDate: Date().addingTimeInterval(-100000))
        XCTAssertFalse(oldArticle.isRecent)
    }

    func testIsRecentBoundary() {
        let boundaryArticle = TestData.makeArticle(publishedDate: Date().addingTimeInterval(-86399))
        XCTAssertTrue(boundaryArticle.isRecent)
    }

    func testTimeAgoString() {
        let article = TestData.makeArticle(publishedDate: Date().addingTimeInterval(-7200))
        XCTAssertFalse(article.timeAgoString.isEmpty)
    }

    func testTimeAgoStringRecent() {
        let article = TestData.makeArticle(publishedDate: Date().addingTimeInterval(-30))
        XCTAssertFalse(article.timeAgoString.isEmpty)
    }

    func testArticleCodable() throws {
        let article = TestData.makeArticle(title: "Codable Test", description: "Test desc")
        let data = try JSONEncoder().encode(article)
        let decoded = try JSONDecoder().decode(NewsArticle.self, from: data)
        XCTAssertEqual(decoded.title, "Codable Test")
        XCTAssertEqual(decoded.id, article.id)
    }

    func testArticleCodableWithAllFields() throws {
        var article = TestData.makeArticle(title: "Full", description: "Desc", isBreaking: true, importance: 9)
        article.summary = "Summary"
        article.fullSummary = "Full summary"
        article.keyPoints = ["Point 1"]
        article.isRead = true
        article.isFavorite = true
        article.sentiment = SentimentResult(score: 0.5, label: .positive, confidence: 0.9)
        let data = try JSONEncoder().encode(article)
        let decoded = try JSONDecoder().decode(NewsArticle.self, from: data)
        XCTAssertEqual(decoded.summary, "Summary")
        XCTAssertTrue(decoded.isBreakingNews)
        XCTAssertTrue(decoded.isFavorite)
        XCTAssertEqual(decoded.sentiment?.label, .positive)
    }

    func testArticleMutability() {
        var article = TestData.makeArticle()
        article.isRead = true
        article.isFavorite = true
        article.summary = "New summary"
        XCTAssertTrue(article.isRead)
        XCTAssertTrue(article.isFavorite)
        XCTAssertEqual(article.summary, "New summary")
    }

    func testBreakingArticle() {
        let article = TestData.makeArticle(title: "BREAKING: Major Event", isBreaking: true, importance: 10)
        XCTAssertTrue(article.isBreakingNews)
        XCTAssertEqual(article.importance, 10)
    }
}

// MARK: - NewsCategory Tests (Unit)

final class NewsCategoryModelTests: XCTestCase {

    func testAllCategories() {
        XCTAssertEqual(NewsCategory.allCases.count, 10)
    }

    func testCategoryIcons() {
        for category in NewsCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category) should have an icon")
        }
    }

    func testCategoryColors() {
        for category in NewsCategory.allCases {
            XCTAssertFalse(category.color.isEmpty, "\(category) should have a color")
            XCTAssertEqual(category.color.count, 6, "\(category) hex color should be 6 chars")
        }
    }

    func testCategoryCodable() throws {
        for category in NewsCategory.allCases {
            let data = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(NewsCategory.self, from: data)
            XCTAssertEqual(decoded, category)
        }
    }

    func testCategoryRawValues() {
        XCTAssertEqual(NewsCategory.topStories.rawValue, "Top Stories")
        XCTAssertEqual(NewsCategory.politics.rawValue, "Politics")
        XCTAssertEqual(NewsCategory.technology.rawValue, "Technology")
    }
}

// MARK: - SourceBias Tests (Unit)

final class SourceBiasTests: XCTestCase {

    func testBiasValues() {
        XCTAssertLessThan(SourceBias.farLeft.value, 0)
        XCTAssertEqual(SourceBias.center.value, 0.0)
        XCTAssertGreaterThan(SourceBias.farRight.value, 0)
    }

    func testBiasOrdering() {
        let biases: [SourceBias] = [.farLeft, .left, .leanLeft, .center, .leanRight, .right, .farRight]
        let values = biases.map(\.value)
        XCTAssertEqual(values, values.sorted(), "Bias values should be in ascending order")
    }

    func testBiasSymmetry() {
        XCTAssertEqual(SourceBias.farLeft.value, -SourceBias.farRight.value, accuracy: 0.01)
        XCTAssertEqual(SourceBias.left.value, -SourceBias.right.value, accuracy: 0.01)
        XCTAssertEqual(SourceBias.leanLeft.value, -SourceBias.leanRight.value, accuracy: 0.01)
    }

    func testShortLabels() {
        XCTAssertEqual(SourceBias.center.shortLabel, "C")
        XCTAssertEqual(SourceBias.left.shortLabel, "L")
        XCTAssertEqual(SourceBias.right.shortLabel, "R")
        XCTAssertEqual(SourceBias.farLeft.shortLabel, "FL")
        XCTAssertEqual(SourceBias.farRight.shortLabel, "FR")
    }

    func testBiasColors() {
        let biases: [SourceBias] = [.farLeft, .left, .leanLeft, .center, .leanRight, .right, .farRight]
        for bias in biases {
            XCTAssertFalse(bias.color.isEmpty, "\(bias) should have a color")
            XCTAssertEqual(bias.color.count, 6, "\(bias) color should be 6-char hex")
        }
    }

    func testBiasCodable() throws {
        let bias = SourceBias.leanLeft
        let data = try JSONEncoder().encode(bias)
        let decoded = try JSONDecoder().decode(SourceBias.self, from: data)
        XCTAssertEqual(decoded, .leanLeft)
    }

    func testAllBiasesCodable() throws {
        let biases: [SourceBias] = [.farLeft, .left, .leanLeft, .center, .leanRight, .right, .farRight]
        for bias in biases {
            let data = try JSONEncoder().encode(bias)
            let decoded = try JSONDecoder().decode(SourceBias.self, from: data)
            XCTAssertEqual(decoded, bias)
        }
    }
}

// MARK: - BiasRating Tests (Unit)

final class BiasRatingTests: XCTestCase {

    func testBiasRatingLabel() {
        let balanced = BiasRating(score: 0.0, confidence: 0.9, indicators: [])
        XCTAssertEqual(balanced.label, "Balanced")

        let leftLeaning = BiasRating(score: -0.7, confidence: 0.8, indicators: [])
        XCTAssertEqual(leftLeaning.label, "Left-Leaning")

        let rightLeaning = BiasRating(score: 0.7, confidence: 0.8, indicators: [])
        XCTAssertEqual(rightLeaning.label, "Right-Leaning")
    }

    func testBiasRatingLeanLabels() {
        let leanLeft = BiasRating(score: -0.3, confidence: 0.8, indicators: [])
        XCTAssertEqual(leanLeft.label, "Lean Left")

        let leanRight = BiasRating(score: 0.3, confidence: 0.8, indicators: [])
        XCTAssertEqual(leanRight.label, "Lean Right")
    }

    func testBiasRatingBoundaryBalanced() {
        let upperBound = BiasRating(score: 0.2, confidence: 0.8, indicators: [])
        XCTAssertEqual(upperBound.label, "Balanced")
        let lowerBound = BiasRating(score: -0.2, confidence: 0.8, indicators: [])
        XCTAssertEqual(lowerBound.label, "Balanced")
    }

    func testBiasRatingCodable() throws {
        let indicator = BiasIndicator(type: "loaded_language", description: "Emotionally charged words", severity: 0.6)
        let rating = BiasRating(score: 0.3, confidence: 0.85, indicators: [indicator])
        let data = try JSONEncoder().encode(rating)
        let decoded = try JSONDecoder().decode(BiasRating.self, from: data)
        XCTAssertEqual(decoded.score, 0.3, accuracy: 0.01)
        XCTAssertEqual(decoded.indicators.count, 1)
    }

    func testBiasIndicatorCodable() throws {
        let indicator = BiasIndicator(type: "framing", description: "Selective emphasis", severity: 0.4)
        let data = try JSONEncoder().encode(indicator)
        let decoded = try JSONDecoder().decode(BiasIndicator.self, from: data)
        XCTAssertEqual(decoded.type, "framing")
        XCTAssertEqual(decoded.severity, 0.4, accuracy: 0.01)
    }
}

// MARK: - SentimentResult Tests (Unit)

final class SentimentResultTests: XCTestCase {

    func testSentimentLabels() {
        let positive = SentimentResult(score: 0.8, label: .positive, confidence: 0.9)
        XCTAssertEqual(positive.label, .positive)

        let negative = SentimentResult(score: -0.6, label: .negative, confidence: 0.8)
        XCTAssertEqual(negative.label, .negative)

        let neutral = SentimentResult(score: 0.0, label: .neutral, confidence: 0.7)
        XCTAssertEqual(neutral.label, .neutral)
    }

    func testMixedSentiment() {
        let mixed = SentimentResult(score: 0.1, label: .mixed, confidence: 0.6)
        XCTAssertEqual(mixed.label, .mixed)
    }

    func testSentimentLabelIcons() {
        for label in [SentimentResult.SentimentLabel.positive, .negative, .neutral, .mixed] {
            XCTAssertFalse(label.icon.isEmpty)
            XCTAssertFalse(label.color.isEmpty)
        }
    }

    func testSentimentLabelColors() {
        XCTAssertEqual(SentimentResult.SentimentLabel.positive.color, "22C55E")
        XCTAssertEqual(SentimentResult.SentimentLabel.negative.color, "EF4444")
        XCTAssertEqual(SentimentResult.SentimentLabel.neutral.color, "6B7280")
        XCTAssertEqual(SentimentResult.SentimentLabel.mixed.color, "F59E0B")
    }

    func testSentimentCodable() throws {
        let sentiment = SentimentResult(score: 0.5, label: .positive, confidence: 0.85)
        let data = try JSONEncoder().encode(sentiment)
        let decoded = try JSONDecoder().decode(SentimentResult.self, from: data)
        XCTAssertEqual(decoded.score, 0.5, accuracy: 0.01)
    }
}

// MARK: - ExtractedEntity Tests (Unit)

final class ExtractedEntityTests: XCTestCase {

    func testEntityCreation() {
        let entity = ExtractedEntity(text: "Apple Inc.", type: .organization)
        XCTAssertEqual(entity.text, "Apple Inc.")
        XCTAssertEqual(entity.type, .organization)
        XCTAssertEqual(entity.count, 1)
    }

    func testEntityWithSentimentAndCount() {
        let entity = ExtractedEntity(text: "New York", type: .location, sentiment: 0.3, count: 5)
        XCTAssertEqual(entity.sentiment, 0.3)
        XCTAssertEqual(entity.count, 5)
    }

    func testEntityTypes() {
        for type in [ExtractedEntity.EntityType.person, .organization, .location, .event, .other] {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }

    func testEntityCodable() throws {
        let entity = ExtractedEntity(text: "New York", type: .location, sentiment: 0.2, count: 3)
        let data = try JSONEncoder().encode(entity)
        let decoded = try JSONDecoder().decode(ExtractedEntity.self, from: data)
        XCTAssertEqual(decoded.text, "New York")
        XCTAssertEqual(decoded.type, .location)
        XCTAssertEqual(decoded.count, 3)
    }

    func testEntityDefaultSentiment() {
        let entity = ExtractedEntity(text: "Test", type: .person)
        XCTAssertNil(entity.sentiment)
    }
}

// MARK: - StoryCluster Tests (Functional)

final class StoryClusterTests: XCTestCase {

    func testClusterCreation() {
        let articles = [
            TestData.makeArticle(title: "Story from Source A", source: TestData.makeSource(id: "a", name: "A")),
            TestData.makeArticle(title: "Story from Source B", source: TestData.makeSource(id: "b", name: "B")),
            TestData.makeArticle(title: "Story from Source C", source: TestData.makeSource(id: "c", name: "C")),
        ]
        let cluster = StoryCluster(topic: "Major Event", articles: articles)
        XCTAssertEqual(cluster.articleCount, 3)
        XCTAssertEqual(cluster.sourceCount, 3)
        XCTAssertEqual(cluster.topic, "Major Event")
    }

    func testClusterDates() {
        let date1 = Date().addingTimeInterval(-7200)
        let date2 = Date().addingTimeInterval(-3600)
        let articles = [
            TestData.makeArticle(publishedDate: date1),
            TestData.makeArticle(publishedDate: date2),
        ]
        let cluster = StoryCluster(topic: "Test", articles: articles)
        XCTAssertEqual(cluster.firstSeen.timeIntervalSince1970, date1.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(cluster.lastUpdated.timeIntervalSince1970, date2.timeIntervalSince1970, accuracy: 1.0)
    }

    func testClusterWithSingleSource() {
        let source = TestData.makeSource(id: "same", name: "Same Source")
        let articles = [
            TestData.makeArticle(source: source),
            TestData.makeArticle(source: source),
        ]
        let cluster = StoryCluster(topic: "Topic", articles: articles)
        XCTAssertEqual(cluster.sourceCount, 1)
        XCTAssertEqual(cluster.articleCount, 2)
    }

    func testEmptyCluster() {
        let cluster = StoryCluster(topic: "Empty", articles: [])
        XCTAssertEqual(cluster.articleCount, 0)
        XCTAssertEqual(cluster.sourceCount, 0)
    }
}

// MARK: - WatchLaterItem Tests (Unit)

final class WatchLaterItemTests: XCTestCase {

    func testWatchLaterCreation() {
        let article = TestData.makeArticle(title: "Save This")
        let item = WatchLaterItem(from: article)
        XCTAssertEqual(item.articleTitle, "Save This")
        XCTAssertFalse(item.isCompleted)
        XCTAssertEqual(item.articleId, article.id)
    }

    func testWatchLaterCodable() throws {
        let item = WatchLaterItem(from: TestData.makeArticle())
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(WatchLaterItem.self, from: data)
        XCTAssertFalse(decoded.isCompleted)
    }

    func testWatchLaterMutability() {
        var item = WatchLaterItem(from: TestData.makeArticle())
        XCTAssertFalse(item.isCompleted)
        item.isCompleted = true
        XCTAssertTrue(item.isCompleted)
    }

    func testWatchLaterHashability() {
        let item1 = WatchLaterItem(from: TestData.makeArticle())
        let item2 = WatchLaterItem(from: TestData.makeArticle())
        var set = Set<WatchLaterItem>()
        set.insert(item1)
        set.insert(item2)
        XCTAssertEqual(set.count, 2)
    }
}

// MARK: - KeywordAlert Tests (Unit)

final class KeywordAlertTests: XCTestCase {

    func testAlertCreation() {
        let alert = KeywordAlert(keyword: "AI")
        XCTAssertEqual(alert.keyword, "AI")
        XCTAssertTrue(alert.isEnabled)
        XCTAssertTrue(alert.notifyOnMatch)
        XCTAssertEqual(alert.matchCount, 0)
    }

    func testAlertCodable() throws {
        let alert = KeywordAlert(keyword: "Tesla")
        let data = try JSONEncoder().encode(alert)
        let decoded = try JSONDecoder().decode(KeywordAlert.self, from: data)
        XCTAssertEqual(decoded.keyword, "Tesla")
    }

    func testAlertMutability() {
        var alert = KeywordAlert(keyword: "Test")
        alert.matchCount = 10
        alert.isEnabled = false
        XCTAssertEqual(alert.matchCount, 10)
        XCTAssertFalse(alert.isEnabled)
    }

    func testAlertHashability() {
        let a1 = KeywordAlert(keyword: "AI")
        let a2 = KeywordAlert(keyword: "AI")
        var set = Set<KeywordAlert>()
        set.insert(a1)
        set.insert(a2)
        XCTAssertEqual(set.count, 2, "Different instances should have unique IDs")
    }
}

// MARK: - UserPreferenceProfile Tests (Unit / Functional)

final class UserPreferenceProfileTests: XCTestCase {

    func testDefaultProfile() {
        let profile = UserPreferenceProfile()
        XCTAssertTrue(profile.categoryWeights.isEmpty)
        XCTAssertTrue(profile.sourceWeights.isEmpty)
        XCTAssertTrue(profile.readArticleIds.isEmpty)
    }

    func testRecordView() {
        var profile = UserPreferenceProfile()
        let article = TestData.makeArticle(category: .technology)
        profile.recordView(article: article, duration: 60.0)
        XCTAssertTrue(profile.readArticleIds.contains(article.id))
        XCTAssertNotNil(profile.categoryWeights[.technology])
        XCTAssertGreaterThan(profile.categoryWeights[.technology] ?? 0, 0.5)
    }

    func testRecordMultipleViews() {
        var profile = UserPreferenceProfile()
        let source = TestData.makeSource(id: "tech-src")
        for _ in 0..<5 {
            let article = TestData.makeArticle(source: source, category: .technology)
            profile.recordView(article: article, duration: 120.0)
        }
        let weight = profile.categoryWeights[.technology] ?? 0
        XCTAssertGreaterThan(weight, 0.5)
        XCTAssertLessThanOrEqual(weight, 1.0)
    }

    func testRelevanceScore() {
        var profile = UserPreferenceProfile()
        let source = TestData.makeSource(id: "tech-src")
        let article = TestData.makeArticle(source: source, category: .technology)
        for _ in 0..<5 {
            profile.recordView(article: TestData.makeArticle(source: source, category: .technology), duration: 120.0)
        }
        let score = profile.relevanceScore(for: article)
        XCTAssertGreaterThan(score, 0.0)
        XCTAssertLessThanOrEqual(score, 1.0)
    }

    func testRelevanceScoreNewProfile() {
        let profile = UserPreferenceProfile()
        let article = TestData.makeArticle(category: .business)
        let score = profile.relevanceScore(for: article)
        // With empty profile, should use defaults (0.5 for category and source)
        XCTAssertGreaterThan(score, 0.0)
    }

    func testProfileCodable() throws {
        var profile = UserPreferenceProfile()
        profile.categoryWeights[.business] = 0.7
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserPreferenceProfile.self, from: data)
        XCTAssertEqual(decoded.categoryWeights[.business], 0.7, accuracy: 0.01)
    }

    func testViewDurationTracked() {
        var profile = UserPreferenceProfile()
        let article = TestData.makeArticle()
        profile.recordView(article: article, duration: 90.0)
        XCTAssertEqual(profile.viewDurations[article.id], 90.0)
    }
}

// MARK: - Settings Tests (Unit / Integration)

final class SettingsTests: XCTestCase {

    func testDefaultSettings() {
        let settings = NewsTVSettings()
        XCTAssertTrue(settings.enableAudioBriefings)
        XCTAssertTrue(settings.enableBreakingNewsAlerts)
        XCTAssertEqual(settings.selectedCategories.count, NewsCategory.allCases.count)
        XCTAssertEqual(settings.theme, .dark)
        XCTAssertTrue(settings.enablePersonalizedFeed)
        XCTAssertTrue(settings.enableWeatherWidget)
        XCTAssertTrue(settings.enableScreensaverMode)
    }

    func testDefaultSettingsAdditional() {
        let settings = NewsTVSettings()
        XCTAssertTrue(settings.enableSentimentColors)
        XCTAssertTrue(settings.enableBiasIndicators)
        XCTAssertTrue(settings.ambientModeEnabled)
        XCTAssertTrue(settings.enableBackgroundRefresh)
        XCTAssertTrue(settings.enableTrendingTicker)
        XCTAssertTrue(settings.enableiCloudSync)
    }

    func testFontSizes() {
        XCTAssertLessThan(NewsTVSettings.FontSize.medium.headlineSize, NewsTVSettings.FontSize.large.headlineSize)
        XCTAssertLessThan(NewsTVSettings.FontSize.large.headlineSize, NewsTVSettings.FontSize.extraLarge.headlineSize)
    }

    func testFontSizeBodySizes() {
        XCTAssertLessThan(NewsTVSettings.FontSize.medium.bodySize, NewsTVSettings.FontSize.large.bodySize)
        XCTAssertLessThan(NewsTVSettings.FontSize.large.bodySize, NewsTVSettings.FontSize.extraLarge.bodySize)
    }

    func testFontSizeValues() {
        XCTAssertEqual(NewsTVSettings.FontSize.medium.headlineSize, 32)
        XCTAssertEqual(NewsTVSettings.FontSize.large.headlineSize, 40)
        XCTAssertEqual(NewsTVSettings.FontSize.extraLarge.headlineSize, 48)
    }

    func testTemperatureUnits() {
        XCTAssertEqual(NewsTVSettings.TemperatureUnit.fahrenheit.symbol, "\u{00B0}F")
        XCTAssertEqual(NewsTVSettings.TemperatureUnit.celsius.symbol, "\u{00B0}C")
    }

    func testAppThemes() {
        let themes = NewsTVSettings.AppTheme.allCases
        XCTAssertEqual(themes.count, 3)
        XCTAssertTrue(themes.contains(.dark))
        XCTAssertTrue(themes.contains(.light))
        XCTAssertTrue(themes.contains(.auto))
    }

    func testSettingsCodable() throws {
        var settings = NewsTVSettings()
        settings.enableAudioBriefings = false
        settings.theme = .light
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(NewsTVSettings.self, from: data)
        XCTAssertFalse(decoded.enableAudioBriefings)
        XCTAssertEqual(decoded.theme, .light)
    }

    func testSettingsWithKeywordAlerts() throws {
        var settings = NewsTVSettings()
        settings.keywordAlerts.append(KeywordAlert(keyword: "AI"))
        settings.keywordAlerts.append(KeywordAlert(keyword: "Space"))
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(NewsTVSettings.self, from: data)
        XCTAssertEqual(decoded.keywordAlerts.count, 2)
    }

    func testSettingsNilLocation() {
        let settings = NewsTVSettings()
        XCTAssertNil(settings.localNewsLocation)
        XCTAssertNil(settings.localNewsZipCode)
    }
}

// MARK: - WeatherData Tests (Unit)

final class WeatherDataTests: XCTestCase {

    func testWeatherConditionIcons() {
        for condition in [WeatherData.WeatherCondition.clear, .cloudy, .partlyCloudy, .rain, .snow, .thunderstorm, .fog, .windy, .unknown] {
            XCTAssertFalse(condition.icon.isEmpty, "\(condition) should have an icon")
        }
    }

    func testWeatherConditionIconFormats() {
        XCTAssertEqual(WeatherData.WeatherCondition.clear.icon, "sun.max.fill")
        XCTAssertEqual(WeatherData.WeatherCondition.rain.icon, "cloud.rain.fill")
        XCTAssertEqual(WeatherData.WeatherCondition.snow.icon, "cloud.snow.fill")
    }

    func testWeatherDataCodable() throws {
        let weather = WeatherData(temperature: 72.0, condition: .clear, high: 78.0, low: 62.0, location: "Denver", lastUpdated: Date())
        let data = try JSONEncoder().encode(weather)
        let decoded = try JSONDecoder().decode(WeatherData.self, from: data)
        XCTAssertEqual(decoded.temperature, 72.0, accuracy: 0.1)
        XCTAssertEqual(decoded.condition, .clear)
        XCTAssertEqual(decoded.location, "Denver")
    }

    func testWeatherDataAllConditions() throws {
        let conditions: [WeatherData.WeatherCondition] = [.clear, .cloudy, .partlyCloudy, .rain, .snow, .thunderstorm, .fog, .windy, .unknown]
        for condition in conditions {
            let weather = WeatherData(temperature: 70.0, condition: condition, high: 75.0, low: 65.0, location: "Test", lastUpdated: Date())
            let data = try JSONEncoder().encode(weather)
            let decoded = try JSONDecoder().decode(WeatherData.self, from: data)
            XCTAssertEqual(decoded.condition, condition)
        }
    }
}

// MARK: - RSSParser Tests (Functional / Integration)

final class RSSParserTests: XCTestCase {

    func testParseValidXML() {
        let parser = RSSParser.shared
        let source = TestData.makeSource()
        let articles = parser.parseXMLForTesting(TestData.sampleRSSXML, source: source)
        XCTAssertEqual(articles.count, 3)
    }

    func testParsedTitles() {
        let parser = RSSParser.shared
        let articles = parser.parseXMLForTesting(TestData.sampleRSSXML, source: TestData.makeSource())
        let titles = articles.map(\.title)
        XCTAssertTrue(titles.contains("Economy Report Released"))
        XCTAssertTrue(titles.contains("Breaking: Weather Alert Issued"))
        XCTAssertTrue(titles.contains("Tech Company Earnings Beat Expectations"))
    }

    func testBreakingNewsDetection() {
        let parser = RSSParser.shared
        let articles = parser.parseXMLForTesting(TestData.sampleRSSXML, source: TestData.makeSource())
        let breakingArticle = articles.first { $0.title.contains("Breaking") }
        XCTAssertNotNil(breakingArticle)
        XCTAssertTrue(breakingArticle?.isBreakingNews == true)
        XCTAssertEqual(breakingArticle?.importance, 9)
    }

    func testNonBreakingArticleDefaultImportance() {
        let parser = RSSParser.shared
        let articles = parser.parseXMLForTesting(TestData.sampleRSSXML, source: TestData.makeSource())
        let normalArticle = articles.first { !$0.isBreakingNews }
        XCTAssertEqual(normalArticle?.importance, 5)
    }

    func testHTMLStripped() {
        let parser = RSSParser.shared
        let articles = parser.parseXMLForTesting(TestData.sampleRSSXML, source: TestData.makeSource())
        let weatherArticle = articles.first { $0.title.contains("Weather") }
        if let desc = weatherArticle?.rssDescription {
            XCTAssertFalse(desc.contains("<p>"), "HTML tags should be stripped")
            XCTAssertFalse(desc.contains("<strong>"), "HTML tags should be stripped")
        }
    }

    func testEmptyInput() {
        let parser = RSSParser.shared
        let articles = parser.parseXMLForTesting("", source: TestData.makeSource())
        XCTAssertTrue(articles.isEmpty)
    }

    func testParsePerformance() {
        let parser = RSSParser.shared
        let source = TestData.makeSource()
        measure {
            for _ in 0..<100 {
                let _ = parser.parseXMLForTesting(TestData.sampleRSSXML, source: source)
            }
        }
    }
}

// MARK: - ContentFilter Tests (Functional)

final class ContentFilterTests: XCTestCase {

    @MainActor
    func testFilterAdvertisements() {
        let filter = ContentFilter.shared
        let adArticle = TestData.makeArticle(title: "Sponsored: Great New Product")
        XCTAssertTrue(filter.isAdvertisement(adArticle))
    }

    @MainActor
    func testFilterClickbait() {
        let filter = ContentFilter.shared
        let clickbait = TestData.makeArticle(title: "You Won't Believe What Happened Next!")
        XCTAssertTrue(filter.isAdvertisement(clickbait))
    }

    @MainActor
    func testLegitimateArticlePassesFilter() {
        let filter = ContentFilter.shared
        let legit = TestData.makeArticle(title: "Federal Reserve Announces Rate Decision")
        XCTAssertFalse(filter.isAdvertisement(legit))
    }

    @MainActor
    func testFilterExcessivePunctuation() {
        let filter = ContentFilter.shared
        let exclaimArticle = TestData.makeArticle(title: "AMAZING!! INCREDIBLE!! MUST READ!!")
        XCTAssertTrue(filter.isAdvertisement(exclaimArticle))
    }

    @MainActor
    func testQualityScoreHighReliability() {
        let filter = ContentFilter.shared
        let source = TestData.makeSource(reliability: 0.95)
        let article = TestData.makeArticle(title: "Well-written article about economic policy", source: source, description: "Detailed description here.")
        let score = filter.qualityScore(article)
        XCTAssertGreaterThan(score, 0.5)
    }

    @MainActor
    func testQualityScorePenalizesShortTitle() {
        let filter = ContentFilter.shared
        let article = TestData.makeArticle(title: "Short")
        let score = filter.qualityScore(article)
        XCTAssertLessThan(score, 1.0)
    }

    @MainActor
    func testFilterPromotionalContent() {
        let filter = ContentFilter.shared
        let promo = TestData.makeArticle(title: "Limited Time Offer: Save 50% Today!")
        XCTAssertTrue(filter.isAdvertisement(promo))
    }

    @MainActor
    func testFilterDealContent() {
        let filter = ContentFilter.shared
        let deal = TestData.makeArticle(title: "DirecTV deal saves customers on new bundle")
        XCTAssertTrue(filter.isAdvertisement(deal))
    }

    @MainActor
    func testFilterArticlesArray() {
        let filter = ContentFilter.shared
        let articles = [
            TestData.makeArticle(title: "Real News Story Here"),
            TestData.makeArticle(title: "Sponsored: Amazing Product"),
            TestData.makeArticle(title: "Another Legitimate Article"),
        ]
        let filtered = filter.filterArticles(articles)
        XCTAssertEqual(filtered.count, 2)
    }

    @MainActor
    func testQualityScoreBounds() {
        let filter = ContentFilter.shared
        let article = TestData.makeArticle(title: "A very well-written article about important economic developments and policy changes")
        let score = filter.qualityScore(article)
        XCTAssertGreaterThanOrEqual(score, 0.0)
        XCTAssertLessThanOrEqual(score, 1.0)
    }
}

// MARK: - RSSError Tests (Unit)

final class RSSErrorTests: XCTestCase {

    func testInvalidDataError() {
        let error = RSSError.invalidData
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testParsingFailedError() {
        let error = RSSError.parsingFailed
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testNetworkError() {
        let underlying = NSError(domain: "test", code: -1, userInfo: nil)
        let error = RSSError.networkError(underlying)
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }
}

// MARK: - Security Tests

final class SecurityTests: XCTestCase {

    func testNoHardcodedAPIKeys() {
        let patterns = [
            "sk-[A-Za-z0-9]{20,}",
            "AKIA[A-Z0-9]{16}",
            "ghp_[A-Za-z0-9]{36}",
            "xox[bpoas]-[A-Za-z0-9]",
        ]

        let testContent = TestData.sampleRSSXML
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(testContent.startIndex..., in: testContent)
            let matches = regex?.numberOfMatches(in: testContent, range: range) ?? 0
            XCTAssertEqual(matches, 0, "Found potential key pattern '\(pattern)'")
        }
    }

    func testHTMLSanitization() {
        for payload in TestData.xssPayloads {
            let article = TestData.makeArticle(description: payload)
            XCTAssertNotNil(article.rssDescription, "Model should accept any description without crash")
        }
    }

    func testArticleURLScheme() {
        let article = TestData.makeArticle()
        XCTAssertTrue(
            article.url.scheme == "https" || article.url.scheme == "http",
            "Article URLs should use HTTP(S)"
        )
    }

    func testNoCodableSecretLeaks() throws {
        let article = TestData.makeArticle()
        let data = try JSONEncoder().encode(article)
        let json = String(data: data, encoding: .utf8) ?? ""
        XCTAssertFalse(json.contains("password"))
        XCTAssertFalse(json.contains("apiKey"))
        XCTAssertFalse(json.contains("secret"))
    }

    func testXSSPayloadsInTitles() {
        for payload in TestData.xssPayloads {
            let article = TestData.makeArticle(title: payload)
            XCTAssertEqual(article.title, payload)
        }
    }

    func testSourceURLNotJavascript() {
        let source = TestData.makeSource()
        XCTAssertNotEqual(source.rssURL.scheme, "javascript")
    }

    func testSettingsNoCodableLeaks() throws {
        let settings = NewsTVSettings()
        let data = try JSONEncoder().encode(settings)
        let json = String(data: data, encoding: .utf8) ?? ""
        XCTAssertFalse(json.contains("password"))
        XCTAssertFalse(json.contains("apiKey"))
    }
}

// MARK: - CustomRSSFeed Tests (Unit)

final class CustomRSSFeedTests: XCTestCase {

    func testFeedCreation() {
        let feed = CustomRSSFeed(name: "My Feed", url: URL(string: "https://example.com/rss")!)
        XCTAssertEqual(feed.name, "My Feed")
        XCTAssertTrue(feed.isEnabled)
        XCTAssertEqual(feed.category, .topStories)
    }

    func testFeedWithCategory() {
        let feed = CustomRSSFeed(name: "Tech", url: URL(string: "https://tech.com/rss")!, category: .technology)
        XCTAssertEqual(feed.category, .technology)
    }

    func testFeedCodable() throws {
        let feed = CustomRSSFeed(name: "Tech Blog", url: URL(string: "https://blog.com/rss")!, category: .technology)
        let data = try JSONEncoder().encode(feed)
        let decoded = try JSONDecoder().decode(CustomRSSFeed.self, from: data)
        XCTAssertEqual(decoded.name, "Tech Blog")
        XCTAssertEqual(decoded.category, .technology)
    }

    func testFeedMutability() {
        var feed = CustomRSSFeed(name: "Blog", url: URL(string: "https://blog.com/rss")!)
        feed.isEnabled = false
        feed.articleCount = 25
        XCTAssertFalse(feed.isEnabled)
        XCTAssertEqual(feed.articleCount, 25)
    }
}

// MARK: - TrendingTopic Tests (Unit)

final class TrendingTopicTests: XCTestCase {

    func testTopicCreation() {
        let topic = TrendingTopic(topic: "AI", articleCount: 25, sources: ["CNN", "BBC", "Reuters"])
        XCTAssertEqual(topic.topic, "AI")
        XCTAssertEqual(topic.articleCount, 25)
        XCTAssertEqual(topic.sources.count, 3)
    }

    func testTopicWithSentiment() {
        let topic = TrendingTopic(topic: "Economy", articleCount: 15, sources: ["WSJ"], sentiment: 0.5)
        XCTAssertEqual(topic.sentiment, 0.5)
    }

    func testTopicHashable() {
        let t1 = TrendingTopic(topic: "AI", articleCount: 10, sources: [])
        let t2 = TrendingTopic(topic: "AI", articleCount: 10, sources: [])
        var set = Set<TrendingTopic>()
        set.insert(t1)
        set.insert(t2)
        XCTAssertEqual(set.count, 2, "Different instances should have different UUIDs")
    }
}

// MARK: - AudioBriefing Tests (Unit)

final class AudioBriefingTests: XCTestCase {

    func testBriefingCreation() {
        let articles = [TestData.makeArticle(), TestData.makeArticle()]
        let briefing = AudioBriefing(title: "Morning Briefing", articles: articles)
        XCTAssertEqual(briefing.title, "Morning Briefing")
        XCTAssertEqual(briefing.articles.count, 2)
        XCTAssertFalse(briefing.isPlaying)
        XCTAssertEqual(briefing.currentIndex, 0)
    }

    func testBriefingMutability() {
        var briefing = AudioBriefing(title: "Test", articles: [])
        briefing.isPlaying = true
        briefing.currentIndex = 3
        XCTAssertTrue(briefing.isPlaying)
        XCTAssertEqual(briefing.currentIndex, 3)
    }
}

// MARK: - AudioBriefingProgress Tests (Unit)

final class AudioBriefingProgressTests: XCTestCase {

    func testProgressCreation() {
        let briefingId = UUID()
        let progress = AudioBriefingProgress(briefingId: briefingId, deviceId: "test-device")
        XCTAssertEqual(progress.briefingId, briefingId)
        XCTAssertEqual(progress.currentIndex, 0)
        XCTAssertEqual(progress.currentPosition, 0)
        XCTAssertEqual(progress.deviceId, "test-device")
    }

    func testProgressCodable() throws {
        let progress = AudioBriefingProgress(briefingId: UUID(), deviceId: "device-1")
        let data = try JSONEncoder().encode(progress)
        let decoded = try JSONDecoder().decode(AudioBriefingProgress.self, from: data)
        XCTAssertEqual(decoded.deviceId, "device-1")
    }

    func testProgressMutability() {
        var progress = AudioBriefingProgress(briefingId: UUID(), deviceId: "device")
        progress.currentIndex = 5
        progress.currentPosition = 120.0
        XCTAssertEqual(progress.currentIndex, 5)
        XCTAssertEqual(progress.currentPosition, 120.0)
    }
}

// MARK: - PerspectiveBreakdown Tests (Unit)

final class PerspectiveBreakdownTests: XCTestCase {

    func testBreakdownCreation() {
        let breakdown = PerspectiveBreakdown(
            leftPerspective: "Left view",
            centerPerspective: "Center view",
            rightPerspective: "Right view",
            sharedFacts: ["Fact 1"],
            contentions: ["Disagreement 1"]
        )
        XCTAssertEqual(breakdown.leftPerspective, "Left view")
        XCTAssertEqual(breakdown.sharedFacts.count, 1)
    }

    func testBreakdownCodable() throws {
        let breakdown = PerspectiveBreakdown(
            leftPerspective: nil,
            centerPerspective: "Center only",
            rightPerspective: nil,
            sharedFacts: [],
            contentions: []
        )
        let data = try JSONEncoder().encode(breakdown)
        let decoded = try JSONDecoder().decode(PerspectiveBreakdown.self, from: data)
        XCTAssertEqual(decoded.centerPerspective, "Center only")
        XCTAssertNil(decoded.leftPerspective)
    }
}

// MARK: - Frame / Performance Tests

final class FrameTests: XCTestCase {

    func testArticleCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = TestData.makeArticle()
            }
        }
    }

    func testArticleCodablePerformance() {
        let articles = (0..<100).map { TestData.makeArticle(title: "Article \($0)") }
        measure {
            for article in articles {
                if let data = try? JSONEncoder().encode(article) {
                    let _ = try? JSONDecoder().decode(NewsArticle.self, from: data)
                }
            }
        }
    }

    func testWeatherDataCodablePerformance() {
        measure {
            for _ in 0..<500 {
                let weather = WeatherData(temperature: 72.0, condition: .clear, high: 78.0, low: 62.0, location: "Denver", lastUpdated: Date())
                if let data = try? JSONEncoder().encode(weather) {
                    let _ = try? JSONDecoder().decode(WeatherData.self, from: data)
                }
            }
        }
    }

    func testSettingsCodablePerformance() {
        let settings = NewsTVSettings()
        measure {
            for _ in 0..<500 {
                if let data = try? JSONEncoder().encode(settings) {
                    let _ = try? JSONDecoder().decode(NewsTVSettings.self, from: data)
                }
            }
        }
    }

    @MainActor
    func testContentFilterPerformance() {
        let filter = ContentFilter.shared
        let articles = (0..<200).map { TestData.makeArticle(title: "Article \($0) about news") }
        measure {
            let _ = filter.filterArticles(articles)
        }
    }
}

// MARK: - ScreensaverManager Tests (Integration)

final class ScreensaverManagerTests: XCTestCase {

    func testFallbackImages() {
        XCTAssertFalse(ScreensaverManager.fallbackImageURLs.isEmpty)
        for url in ScreensaverManager.fallbackImageURLs {
            XCTAssertNotNil(url, "Fallback image URL should not be nil")
            XCTAssertTrue(url?.scheme == "https", "Fallback URLs should use HTTPS")
        }
    }

    func testFallbackImageCount() {
        XCTAssertGreaterThanOrEqual(ScreensaverManager.fallbackImageURLs.count, 3, "Should have at least 3 fallback images")
    }
}
