//
//  ScreensaverManager.swift
//  NewsTV
//
//  Manages screensaver mode with beautiful headline display
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
class ScreensaverManager: ObservableObject {
    static let shared = ScreensaverManager()

    @Published var isActive = false
    @Published var currentArticle: NewsArticle?
    @Published var currentImageURL: URL?

    private var idleTimer: Timer?
    private var rotationTimer: Timer?
    private var lastInteraction: Date = Date()
    private var articleIndex = 0

    private init() {}

    // MARK: - Idle Detection

    func resetIdleTimer() {
        lastInteraction = Date()

        if isActive {
            deactivate()
        }

        startIdleTimer()
    }

    func startIdleTimer() {
        guard SettingsManager.shared.settings.enableScreensaverMode else { return }

        idleTimer?.invalidate()
        let idleTime = SettingsManager.shared.settings.screensaverIdleTime

        idleTimer = Timer.scheduledTimer(withTimeInterval: idleTime, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.activate()
            }
        }
    }

    func stopIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = nil
    }

    // MARK: - Activation

    func activate() {
        guard !isActive else { return }
        guard SettingsManager.shared.settings.enableScreensaverMode else { return }

        isActive = true
        articleIndex = 0
        showNextArticle()
        startRotation()
    }

    func deactivate() {
        isActive = false
        rotationTimer?.invalidate()
        rotationTimer = nil
        currentArticle = nil
        currentImageURL = nil
    }

    // MARK: - Article Rotation

    private func startRotation() {
        let interval = SettingsManager.shared.settings.rotationInterval

        rotationTimer?.invalidate()
        rotationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.showNextArticle()
            }
        }
    }

    private func showNextArticle() {
        let articles = NewsAggregator.shared.topStories(count: 30)
        guard !articles.isEmpty else { return }

        articleIndex = (articleIndex + 1) % articles.count

        withAnimation(.easeInOut(duration: 1.0)) {
            currentArticle = articles[articleIndex]
            currentImageURL = articles[articleIndex].imageURL
        }
    }

    // MARK: - Background Images

    static let fallbackImageURLs = [
        URL(string: "https://images.unsplash.com/photo-1495020689067-958852a7765e?w=1920"),
        URL(string: "https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=1920"),
        URL(string: "https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=1920"),
        URL(string: "https://images.unsplash.com/photo-1557804506-669a67965ba0?w=1920"),
        URL(string: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1920")
    ]

    var backgroundImageURL: URL? {
        currentImageURL ?? Self.fallbackImageURLs.randomElement() ?? nil
    }
}
