//
//  TVContentView.swift
//  NewsTV
//
//  Main content view for tvOS
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
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
    // Defer initialization to avoid crashes on tvOS 26.3 beta
    @State private var newsAggregator: NewsAggregator?
    @State private var ttsManager: TTSManager?
    @State private var settingsManager: SettingsManager?
    @State private var screensaverManager: ScreensaverManager?
    @State private var backgroundRefresh: BackgroundRefreshManager?
    @State private var alertManager: KeywordAlertManager?

    @State private var selectedMainTab: MainTab = .news
    @State private var selectedCategory: NewsCategory = .topStories
    @State private var selectedArticle: NewsArticle?
    @State private var showSettings = false
    @State private var showAudioBriefing = false
    @State private var isAmbientMode = false
    @State private var isReady = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                backgroundGradient

                if !isReady {
                    // Simple loading state to test basic rendering
                    VStack(spacing: 20) {
                        Image(systemName: "newspaper.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.cyan)
                        Text("NewsTV")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                } else if screensaverManager?.isActive == true {
                    ScreensaverView()
                } else if newsAggregator?.isLoading == true && (newsAggregator?.articles.isEmpty ?? true) {
                    loadingView
                } else if isAmbientMode {
                    AmbientModeView(articles: newsAggregator?.topStories(count: 20) ?? [])
                } else {
                    mainContentView
                }
            }
        }
        .task {
            // Delayed initialization to avoid crashes on tvOS 26.3 beta
            try? await Task.sleep(for: .seconds(1))

            // Initialize managers with delays between each
            settingsManager = SettingsManager.shared
            try? await Task.sleep(for: .seconds(0.2))

            newsAggregator = NewsAggregator.shared
            try? await Task.sleep(for: .seconds(0.2))

            ttsManager = TTSManager.shared
            screensaverManager = ScreensaverManager.shared
            alertManager = KeywordAlertManager.shared
            try? await Task.sleep(for: .seconds(0.2))

            backgroundRefresh = BackgroundRefreshManager.shared

            isReady = true
            setupApp()
        }
        .onPlayPauseCommand {
            toggleAudioBriefing()
        }
        .onChange(of: selectedMainTab) { _, _ in
            screensaverManager?.resetIdleTimer()
        }
        .onChange(of: selectedCategory) { _, _ in
            screensaverManager?.resetIdleTimer()
        }
    }

    // MARK: - Setup

    private func setupApp() {
        Task {
            await newsAggregator?.fetchAllNews()

            // Cluster articles for multi-source view
            _ = await StoryClusterEngine.shared.clusterArticles(newsAggregator?.articles ?? [])

            // Analyze trending topics
            TrendingTopicsEngine.shared.analyzeTrends(from: newsAggregator?.articles ?? [])

            // Check keyword alerts
            alertManager?.checkAlerts(against: newsAggregator?.articles ?? [])

            // Fetch weather
            await WeatherService.shared.fetchWeather()

            // Fetch local news if configured
            await LocalNewsService.shared.fetchLocalNews()

            // Fetch custom feeds
            await CustomFeedManager.shared.fetchAllCustomFeeds()

            // Sync from iCloud
            await WatchLaterManager.shared.syncFromCloud()
        }

        // Start background refresh
        backgroundRefresh?.startAutoRefresh()

        // Start screensaver idle timer
        screensaverManager?.startIdleTimer()

        // Donate Siri shortcuts
        SiriIntentsManager.shared.donateShortcuts()
    }

    // MARK: - Views

    private var backgroundGradient: some View {
        Group {
            if settingsManager?.settings.theme == .light {
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
        }
    }

    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Top bar with weather and trending
            topBar

            // Trending ticker
            TrendingTicker()

            // Breaking news banner - disabled for tvOS 26.3 beta
            // if let breakingNews = newsAggregator?.breakingNews().first {
            //     BreakingNewsBanner(article: breakingNews)
            // }

            // Main tab bar
            mainTabBar

            // Static content for tvOS 26.3 beta
            // Full tabContent crashes on this beta version
            Text("NewsTV - Loading articles...")
                .font(.title2)
                .foregroundColor(.white.opacity(0.7))
                .padding()

            Spacer()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
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

            // Weather widget
            WeatherWidget()

            // Alert indicator
            if alertManager?.hasNewMatches == true {
                Button {
                    selectedMainTab = .alerts
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.red)
                        Text("\(alertManager?.totalMatchCount() ?? 0)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }

            // Audio briefing button
            Button {
                showAudioBriefing = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: ttsManager?.isSpeaking == true ? "speaker.wave.3.fill" : "speaker.wave.2")
                    Text("Briefing")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.cyan)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.cyan.opacity(0.2))
                .cornerRadius(20)
            }
            .buttonStyle(.plain)

            // Settings button
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.3))
    }

    private var mainTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    MainTabButton(
                        tab: tab,
                        isSelected: selectedMainTab == tab,
                        badgeCount: badgeCount(for: tab)
                    )
                    // .focusable() - disabled for tvOS 26.3 beta
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMainTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 16)
        }
        .background(Color.black.opacity(0.2))
    }

    @ViewBuilder
    private var tabContent: some View {
        // Simplified for tvOS 26.3 beta testing
        Text("Tab: \(selectedMainTab.rawValue)")
            .font(.title)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        /* Original tab content - crashes on tvOS 26.3 beta
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
        */
    }

    private var newsTabContent: some View {
        VStack(spacing: 0) {
            // Category tabs
            categoryTabBar

            // Content
            TabView(selection: $selectedCategory) {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    CategoryNewsView(
                        category: category,
                        articles: newsAggregator?.articles(for: category) ?? [],
                        selectedArticle: $selectedArticle
                    )
                    .tag(category)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private var categoryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedCategory == category,
                        articleCount: newsAggregator?.articles(for: category).count ?? 0
                    )
                    .focusable()
                    .onTapGesture {
                        withAnimation {
                            selectedCategory = category
                        }
                    }
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
                            .focusable()
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Helpers

    private func badgeCount(for tab: MainTab) -> Int {
        // Disabled for tvOS 26.3 beta - accessing singletons causes crash
        return 0
        /*
        switch tab {
        case .watchLater:
            return WatchLaterManager.shared.items.count
        case .alerts:
            return alertManager?.totalMatchCount() ?? 0
        case .customFeeds:
            return CustomFeedManager.shared.customArticles.count
        default:
            return 0
        }
        */
    }

    private func toggleAudioBriefing() {
        if ttsManager?.isSpeaking == true {
            ttsManager?.pause()
        } else if !(newsAggregator?.articles.isEmpty ?? true) {
            ttsManager?.startBriefing(articles: newsAggregator?.topStories(count: 10) ?? [])
        }
    }
}

// MARK: - Main Tab Button

struct MainTabButton: View {
    let tab: MainTab
    let isSelected: Bool
    let badgeCount: Int

    // Removed @Environment(\.isFocused) due to tvOS 26.3 beta crash

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
    @Environment(\.isFocused) private var isFocused
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
                    .fill(isFocused ? Color.green.opacity(0.2) : Color.white.opacity(0.08))
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
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

    @Environment(\.isFocused) private var isFocused

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
                    .fill(highlightColor)
            )
            .scaleEffect(isFocused ? 1.08 : 1.0)

            Rectangle()
                .fill(isSelected ? Color.cyan : Color.clear)
                .frame(height: 2)
                .cornerRadius(1)
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.12), value: isFocused)
    }

    private var highlightColor: Color {
        if isFocused {
            return Color.cyan.opacity(0.3)
        } else if isSelected {
            return Color.cyan.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Preview

#Preview {
    TVContentView()
}
