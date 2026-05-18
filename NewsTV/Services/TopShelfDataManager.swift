//
//  TopShelfDataManager.swift
//  NewsTV
//
//  Created by Jordan Koch
//  Manages data sharing between the main app and Top Shelf extension
//

import Foundation
import TVServices

/// Manages data synchronization between the main app and the Top Shelf extension
final class TopShelfDataManager {

    // MARK: - Singleton
    static let shared = TopShelfDataManager()

    // MARK: - Constants
    private let appGroupIdentifier = "group.com.jordankoch.newstv"

    private enum Keys {
        static let topShelfHeadlines = "topShelfHeadlines"
        static let lastUpdateTime = "topShelfLastUpdateTime"
    }

    // MARK: - Properties
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Public Methods

    /// Updates the Top Shelf with the latest headlines
    /// - Parameter headlines: Array of CachedHeadline objects
    func updateHeadlines(_ headlines: [CachedHeadline]) {
        if let data = try? JSONEncoder().encode(headlines) {
            sharedDefaults?.set(data, forKey: Keys.topShelfHeadlines)
        }
        sharedDefaults?.set(Date(), forKey: Keys.lastUpdateTime)
        notifyTopShelfUpdate()
    }

    /// Notifies the system that Top Shelf content has changed
    func notifyTopShelfUpdate() {
        TVTopShelfContentProvider.topShelfContentDidChange()
    }

    /// Clears all Top Shelf data
    func clearTopShelfData() {
        sharedDefaults?.removeObject(forKey: Keys.topShelfHeadlines)
        sharedDefaults?.removeObject(forKey: Keys.lastUpdateTime)
        notifyTopShelfUpdate()
    }

    // MARK: - Convenience Methods

    /// Updates Top Shelf with articles from the news aggregator
    func updateFromArticles(_ articles: [Article]) {
        let headlines = articles.prefix(10).enumerated().map { index, article -> CachedHeadline in
            return CachedHeadline(
                id: "\(index)",
                title: article.title,
                category: article.category,
                imageURLString: article.imageURL?.absoluteString
            )
        }
        updateHeadlines(headlines)
    }
}

// MARK: - CachedHeadline Model (shared with Top Shelf extension)

struct CachedHeadline: Codable {
    let id: String
    let title: String
    let category: String
    let imageURLString: String?

    var imageURL: URL? {
        guard let urlString = imageURLString else { return nil }
        return URL(string: urlString)
    }
}

// MARK: - Article placeholder (adjust to match your actual model)

struct Article {
    let title: String
    let category: String
    let imageURL: URL?
}
