//
//  WatchLaterManager.swift
//  NewsTV
//
//  Watch Later queue management with iCloud sync
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import CloudKit

@MainActor
class WatchLaterManager: ObservableObject {
    static let shared = WatchLaterManager()

    @Published var items: [WatchLaterItem] = []
    @Published var isSyncing = false

    private let localKey = "NewsTV.watchLater"
    private let container = CKContainer(identifier: "iCloud.com.jordankoch.NewsTV")
    private let recordType = "WatchLaterItem"

    private init() {
        loadLocal()
    }

    // MARK: - Local Storage

    private func loadLocal() {
        if let data = UserDefaults.standard.data(forKey: localKey),
           let decoded = try? JSONDecoder().decode([WatchLaterItem].self, from: data) {
            items = decoded
        }
    }

    private func saveLocal() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: localKey)
        }
    }

    // MARK: - Queue Management

    func add(_ article: NewsArticle) {
        guard !contains(article) else { return }
        let item = WatchLaterItem(from: article)
        items.insert(item, at: 0)
        saveLocal()
        Task { await syncToCloud(item) }
    }

    func remove(_ item: WatchLaterItem) {
        items.removeAll { $0.id == item.id }
        saveLocal()
        Task { await deleteFromCloud(item) }
    }

    func remove(_ article: NewsArticle) {
        if let item = items.first(where: { $0.articleId == article.id }) {
            remove(item)
        }
    }

    func markCompleted(_ item: WatchLaterItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted = true
            saveLocal()
            Task { await syncToCloud(items[index]) }
        }
    }

    func contains(_ article: NewsArticle) -> Bool {
        items.contains { $0.articleId == article.id }
    }

    func clearCompleted() {
        let completed = items.filter { $0.isCompleted }
        items.removeAll { $0.isCompleted }
        saveLocal()
        Task {
            for item in completed {
                await deleteFromCloud(item)
            }
        }
    }

    // MARK: - iCloud Sync

    func syncFromCloud() async {
        guard SettingsManager.shared.settings.enableiCloudSync else { return }

        isSyncing = true
        defer { isSyncing = false }

        let database = container.privateCloudDatabase
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "addedDate", ascending: false)]

        do {
            let (results, _) = try await database.records(matching: query)
            var cloudItems: [WatchLaterItem] = []

            for (_, result) in results {
                if case .success(let record) = result {
                    if let item = watchLaterItem(from: record) {
                        cloudItems.append(item)
                    }
                }
            }

            // Merge with local - cloud wins for conflicts
            let localIds = Set(items.map { $0.id })
            let cloudIds = Set(cloudItems.map { $0.id })

            // Keep local items not in cloud, add all cloud items
            let localOnly = items.filter { !cloudIds.contains($0.id) }
            items = cloudItems + localOnly
            items.sort { $0.addedDate > $1.addedDate }
            saveLocal()

        } catch {
            print("CloudKit sync error: \(error)")
        }
    }

    private func syncToCloud(_ item: WatchLaterItem) async {
        guard SettingsManager.shared.settings.enableiCloudSync else { return }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: item.id.uuidString)
        let record = CKRecord(recordType: recordType, recordID: recordID)

        record["articleId"] = item.articleId.uuidString
        record["articleTitle"] = item.articleTitle
        record["articleURL"] = item.articleURL.absoluteString
        record["source"] = item.source
        record["category"] = item.category.rawValue
        record["addedDate"] = item.addedDate
        record["isCompleted"] = item.isCompleted ? 1 : 0

        do {
            try await database.save(record)
        } catch {
            print("CloudKit save error: \(error)")
        }
    }

    private func deleteFromCloud(_ item: WatchLaterItem) async {
        guard SettingsManager.shared.settings.enableiCloudSync else { return }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: item.id.uuidString)

        do {
            try await database.deleteRecord(withID: recordID)
        } catch {
            print("CloudKit delete error: \(error)")
        }
    }

    private func watchLaterItem(from record: CKRecord) -> WatchLaterItem? {
        guard let articleIdString = record["articleId"] as? String,
              let articleId = UUID(uuidString: articleIdString),
              let articleTitle = record["articleTitle"] as? String,
              let articleURLString = record["articleURL"] as? String,
              let articleURL = URL(string: articleURLString),
              let source = record["source"] as? String,
              let categoryString = record["category"] as? String,
              let category = NewsCategory(rawValue: categoryString),
              let addedDate = record["addedDate"] as? Date else {
            return nil
        }

        let isCompleted = (record["isCompleted"] as? Int ?? 0) == 1

        return WatchLaterItem(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            articleId: articleId,
            articleTitle: articleTitle,
            articleURL: articleURL,
            source: source,
            category: category,
            addedDate: addedDate,
            isCompleted: isCompleted
        )
    }
}

// Extension for WatchLaterItem to allow memberwise init
extension WatchLaterItem {
    init(id: UUID, articleId: UUID, articleTitle: String, articleURL: URL, source: String, category: NewsCategory, addedDate: Date, isCompleted: Bool) {
        self.id = id
        self.articleId = articleId
        self.articleTitle = articleTitle
        self.articleURL = articleURL
        self.source = source
        self.category = category
        self.addedDate = addedDate
        self.isCompleted = isCompleted
    }
}
