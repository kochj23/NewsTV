//
//  BackgroundRefreshManager.swift
//  NewsTV
//
//  Manages automatic background refresh of news feeds
//  Created by Jordan Koch on 2026-01-30.
//  Updated: 2026-01-31 - Enabled BGTaskScheduler for iOS/iPad
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import BackgroundTasks

@MainActor
class BackgroundRefreshManager: ObservableObject {
    static let shared = BackgroundRefreshManager()

    @Published var lastRefreshDate: Date?
    @Published var isRefreshing = false
    @Published var nextScheduledRefresh: Date?

    private var refreshTimer: Timer?
    private let taskIdentifier = "com.jordankoch.NewsTV.refresh"

    private init() {
        // Enable BGTaskScheduler on iOS (disabled on tvOS 26.3 beta due to crashes)
        #if os(iOS)
        setupBackgroundRefresh()
        #endif
    }

    // MARK: - Setup

    private func setupBackgroundRefresh() {
        // Register background task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            Task { @MainActor in
                guard let refreshTask = task as? BGAppRefreshTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                await self.handleBackgroundRefresh(task: refreshTask)
            }
        }
    }

    func startAutoRefresh() {
        guard SettingsManager.shared.settings.enableBackgroundRefresh else {
            stopAutoRefresh()
            return
        }

        let interval = SettingsManager.shared.settings.backgroundRefreshInterval

        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performRefresh()
            }
        }

        scheduleNextRefresh()
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        nextScheduledRefresh = nil
    }

    // MARK: - Refresh

    func performRefresh() async {
        guard !isRefreshing else { return }

        isRefreshing = true
        defer {
            isRefreshing = false
            lastRefreshDate = Date()
        }

        // Refresh main news
        await NewsAggregator.shared.fetchAllNews()

        // Refresh local news if configured
        if SettingsManager.shared.settings.localNewsLocation != nil ||
           SettingsManager.shared.settings.localNewsZipCode != nil {
            await LocalNewsService.shared.fetchLocalNews()
        }

        // Update story clusters
        let articles = NewsAggregator.shared.articles
        _ = await StoryClusterEngine.shared.clusterArticles(articles)

        // Update trending topics
        TrendingTopicsEngine.shared.analyzeTrends(from: articles)

        // Check keyword alerts
        KeywordAlertManager.shared.checkAlerts(against: articles)

        // Sync watch later from cloud
        await WatchLaterManager.shared.syncFromCloud()
    }

    // MARK: - Background Task

    private func handleBackgroundRefresh(task: BGAppRefreshTask) async {
        scheduleNextRefresh()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        await performRefresh()
        task.setTaskCompleted(success: true)
    }

    private func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        let interval = SettingsManager.shared.settings.backgroundRefreshInterval
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)

        do {
            try BGTaskScheduler.shared.submit(request)
            nextScheduledRefresh = request.earliestBeginDate
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
    }

    // MARK: - Manual Refresh

    func refreshNow() async {
        await performRefresh()
        scheduleNextRefresh()
    }
}
