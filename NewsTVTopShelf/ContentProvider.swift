//
//  ContentProvider.swift
//  NewsTVTopShelf
//
//  Created by Jordan Koch
//

import TVServices

class ContentProvider: TVTopShelfContentProvider {

    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        // Load cached headlines from shared UserDefaults
        let headlines = loadCachedHeadlines()

        if headlines.isEmpty {
            // Return sectioned content with placeholder
            let placeholderItem = TVTopShelfSectionedItem(identifier: "placeholder")
            placeholderItem.title = "Tap to see latest news"
            placeholderItem.setImageURL(createNewsImageURL(), for: .screenScale1x)

            let section = TVTopShelfItemCollection(items: [placeholderItem])
            section.title = "NewsTV"

            let content = TVTopShelfSectionedContent(sections: [section])
            completionHandler(content)
            return
        }

        // Create sectioned content with news headlines
        var items: [TVTopShelfSectionedItem] = []

        for (index, headline) in headlines.prefix(10).enumerated() {
            let item = TVTopShelfSectionedItem(identifier: "headline_\(index)")
            item.title = headline.title
            item.setImageURL(headline.imageURL, for: .screenScale1x)

            // Deep link to specific article
            if let articleURL = URL(string: "newstv://article/\(headline.id)") {
                item.displayAction = TVTopShelfAction(url: articleURL)
                item.playAction = TVTopShelfAction(url: articleURL)
            }

            items.append(item)
        }

        // Create sections by category
        let worldNews = items.filter { $0.identifier.contains("world") }
        let techNews = items.filter { $0.identifier.contains("tech") }
        let allNews = items

        var sections: [TVTopShelfItemCollection<TVTopShelfSectionedItem>] = []

        if !allNews.isEmpty {
            let mainSection = TVTopShelfItemCollection(items: Array(allNews.prefix(5)))
            mainSection.title = "Top Stories"
            sections.append(mainSection)
        }

        if allNews.count > 5 {
            let moreSection = TVTopShelfItemCollection(items: Array(allNews.suffix(from: 5)))
            moreSection.title = "More News"
            sections.append(moreSection)
        }

        let content = TVTopShelfSectionedContent(sections: sections)
        completionHandler(content)
    }

    private func loadCachedHeadlines() -> [CachedHeadline] {
        let userDefaults = UserDefaults(suiteName: "group.com.jordankoch.newstv")

        guard let data = userDefaults?.data(forKey: "topShelfHeadlines"),
              let headlines = try? JSONDecoder().decode([CachedHeadline].self, from: data) else {
            return []
        }

        return headlines
    }

    private func createNewsImageURL() -> URL? {
        // Return a default news icon URL or nil
        return nil
    }
}

// MARK: - Cached Headline Model
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
