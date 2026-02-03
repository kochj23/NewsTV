//
//  TVContentView.swift
//  NewsTV
//
//  Main content view for tvOS
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//
//  tvOS 26.3 beta compatibility notes:
//  - No @FocusState (crashes)
//  - No @Environment(\.isFocused) (crashes)
//  - No .focusable() modifier (crashes) - use Button controls instead
//  - BGTaskScheduler disabled in BackgroundRefreshManager
//

import SwiftUI

enum MainTab: String, CaseIterable {
    case news = "News"
    case forYou = "For You"
    case local = "Local"
    case watchLater = "Watch Later"
    case clusters = "Multi-Source"
    case alerts = "Alerts"
    case customFeeds = "My Feeds"

    var icon: String {
        switch self {
        case .news: return "newspaper.fill"
        case .forYou: return "sparkles"
        case .local: return "location.fill"
        case .watchLater: return "bookmark.fill"
        case .clusters: return "square.stack.3d.up"
        case .alerts: return "bell.badge.fill"
        case .customFeeds: return "plus.square.on.square"
        }
    }

    var color: Color {
        switch self {
        case .news: return .cyan
        case .forYou: return .purple
        case .local: return .orange
        case .watchLater: return .yellow
        case .clusters: return .green
        case .alerts: return .red
        case .customFeeds: return .mint
        }
    }
}

struct TVContentView: View {
    @ObservedObject private var newsAggregator = NewsAggregator.shared
    @ObservedObject private var settingsManager = SettingsManager.shared

    @State private var selectedMainTab: MainTab = .news
    @State private var selectedCategory: NewsCategory = .topStories
    @State private var selectedArticle: NewsArticle?
    @State private var isInitialLoad = true

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                backgroundGradient

                if isInitialLoad {
                    loadingView
                } else {
                    mainContentView
                }
            }
        }
        .task {
            await runSetup()
        }
    }

    // MARK: - Setup

    private func runSetup() async {
        // Fetch news
        await newsAggregator.fetchAllNews()

        // Fetch local news if ZIP code is configured
        await LocalNewsService.shared.fetchLocalNews()

        // Mark initial load complete - this MUST happen to show content
        isInitialLoad = false
    }

    // MARK: - Views

    private var backgroundGradient: some View {
        Group {
            if settingsManager.settings.theme == .light {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97),
                        Color(red: 0.9, green: 0.9, blue: 0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.12),
                        Color(red: 0.1, green: 0.1, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }

    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(2)
                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))

            Text("Loading News...")
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))

            Text("Fetching from \(newsAggregator.defaultSources.count) sources")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar

            // Main tab bar
            mainTabBar

            // Content based on selected tab
            tabContent
        }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
    }

    private var topBar: some View {
        HStack(spacing: 20) {
            // App title
            HStack(spacing: 12) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.cyan)

                Text("NewsTV")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            Text("\(newsAggregator.articles.count) articles")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.6))

            // Settings are now in Apple TV Settings app
            Text("Settings in TV Settings")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.3))
    }

    private var mainTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMainTab = tab
                        }
                    } label: {
                        MainTabButton(
                            tab: tab,
                            isSelected: selectedMainTab == tab,
                            badgeCount: badgeCount(for: tab)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 16)
        }
        .background(Color.black.opacity(0.2))
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedMainTab {
        case .news:
            newsTabContent
        case .forYou:
            ForYouView()
        case .local:
            LocalNewsView()
        case .watchLater:
            WatchLaterListView()
        case .clusters:
            storyClustersView
        case .alerts:
            KeywordAlertsView()
        case .customFeeds:
            CustomFeedsView()
        }
    }

    private var newsTabContent: some View {
        VStack(spacing: 0) {
            // Category tabs
            categoryTabBar

            // Content
            CategoryNewsView(
                category: selectedCategory,
                articles: newsAggregator.articles(for: selectedCategory),
                selectedArticle: $selectedArticle
            )
        }
    }

    private var categoryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation {
                            selectedCategory = category
                        }
                    } label: {
                        CategoryTab(
                            category: category,
                            isSelected: selectedCategory == category,
                            articleCount: newsAggregator.articles(for: category).count
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 12)
        }
        .background(Color.black.opacity(0.15))
    }

    private var storyClustersView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 28))
                    .foregroundColor(.green)

                Text("Multi-Source Stories")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(StoryClusterEngine.shared.clusters.count) stories from multiple sources")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 20)
            .background(Color.black.opacity(0.3))

            // Clusters list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(StoryClusterEngine.shared.clusters) { cluster in
                        StoryClusterCard(cluster: cluster)
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Helpers

    private func badgeCount(for tab: MainTab) -> Int {
        switch tab {
        case .watchLater:
            return WatchLaterManager.shared.items.count
        case .alerts:
            return KeywordAlertManager.shared.totalMatchCount()
        case .customFeeds:
            return CustomFeedManager.shared.customArticles.count
        default:
            return 0
        }
    }
}

// MARK: - Main Tab Button

struct MainTabButton: View {
    let tab: MainTab
    let isSelected: Bool
    let badgeCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: tab.icon)
                .font(.system(size: 20))

            Text(tab.rawValue)
                .font(.system(size: 18, weight: isSelected ? .bold : .medium))

            if badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tab.color)
                    .cornerRadius(8)
            }
        }
        .foregroundColor(isSelected ? tab.color : .white.opacity(0.7))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? tab.color.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? tab.color : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Story Cluster Card

struct StoryClusterCard: View {
    let cluster: StoryCluster
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 20) {
                // Bias spectrum indicator
                VStack(spacing: 4) {
                    ForEach(biasColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text(cluster.topic)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    HStack(spacing: 16) {
                        Label("\(cluster.sourceCount) sources", systemImage: "newspaper")
                        Label("\(cluster.articleCount) articles", systemImage: "doc.text")
                        Label(cluster.lastUpdated.formatted(.relative(presentation: .named)), systemImage: "clock")
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))

                    // Source badges
                    HStack(spacing: 8) {
                        ForEach(cluster.articles.prefix(4)) { article in
                            Text(article.source.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: article.source.bias.color).opacity(0.3))
                                .cornerRadius(12)
                        }

                        if cluster.articles.count > 4 {
                            Text("+\(cluster.articles.count - 4)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            StoryClusterView(cluster: cluster)
        }
    }

    private var biasColors: [Color] {
        let biases = Set(cluster.articles.map { $0.source.bias })
        return biases.sorted { $0.value < $1.value }.map { Color(hex: $0.color) }
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let category: NewsCategory
    let isSelected: Bool
    let articleCount: Int

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                Text(category.rawValue)

                if articleCount > 0 {
                    Text("\(articleCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.cyan : Color.white.opacity(0.5))
                        .cornerRadius(8)
                }
            }
            .font(.system(size: 18, weight: isSelected ? .bold : .medium))
            .foregroundColor(isSelected ? .cyan : .white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.cyan.opacity(0.1) : Color.clear)
            )

            Rectangle()
                .fill(isSelected ? Color.cyan : Color.clear)
                .frame(height: 2)
                .cornerRadius(1)
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    TVContentView()
}
