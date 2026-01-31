//
//  iPadNewsView.swift
//  NewsTV
//
//  iPad-optimized news view with sidebar navigation
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

#if os(iOS)
import SwiftUI

struct iPadNewsView: View {
    @ObservedObject private var newsAggregator = NewsAggregator.shared
    @ObservedObject private var settingsManager = SettingsManager.shared

    @State private var selectedSidebarItem: SidebarItem? = .news
    @State private var selectedCategory: NewsCategory = .topStories
    @State private var selectedArticle: NewsArticle?
    @State private var showSettings = false
    @State private var searchText = ""
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    enum SidebarItem: String, CaseIterable, Identifiable {
        case news = "News"
        case forYou = "For You"
        case local = "Local"
        case watchLater = "Saved"
        case clusters = "Multi-Source"
        case alerts = "Alerts"
        case customFeeds = "My Feeds"

        var id: String { rawValue }

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

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
        } content: {
            contentListView
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $searchText, prompt: "Search articles")
        .refreshable {
            await refreshNews()
        }
        .onAppear {
            setupApp()
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                iPadSettingsView()
            }
        }
    }

    // MARK: - Setup

    private func setupApp() {
        Task {
            await newsAggregator.fetchAllNews()
            _ = await StoryClusterEngine.shared.clusterArticles(newsAggregator.articles)
            TrendingTopicsEngine.shared.analyzeTrends(from: newsAggregator.articles)
            KeywordAlertManager.shared.checkAlerts(against: newsAggregator.articles)
            await WeatherService.shared.fetchWeather()
            await LocalNewsService.shared.fetchLocalNews()
            await CustomFeedManager.shared.fetchAllCustomFeeds()
            await WatchLaterManager.shared.syncFromCloud()

            // Enable background refresh on iPad
            BackgroundRefreshManager.shared.startAutoRefresh()
        }
    }

    private func refreshNews() async {
        await BackgroundRefreshManager.shared.performRefresh()
    }

    // MARK: - Sidebar

    private var sidebarContent: some View {
        List(selection: $selectedSidebarItem) {
            Section("Browse") {
                ForEach(SidebarItem.allCases) { item in
                    NavigationLink(value: item) {
                        Label {
                            HStack {
                                Text(item.rawValue)
                                Spacer()
                                if badgeCount(for: item) > 0 {
                                    Text("\(badgeCount(for: item))")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(item.color)
                                        .clipShape(Capsule())
                                }
                            }
                        } icon: {
                            Image(systemName: item.icon)
                                .foregroundColor(item.color)
                        }
                    }
                }
            }

            Section("Categories") {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    Button {
                        selectedSidebarItem = .news
                        selectedCategory = category
                    } label: {
                        Label {
                            HStack {
                                Text(category.rawValue)
                                Spacer()
                                Text("\(newsAggregator.articles(for: category).count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: category.icon)
                        }
                    }
                    .tint(.primary)
                }
            }

            Section {
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("NewsTV")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await refreshNews() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    // MARK: - Content List

    @ViewBuilder
    private var contentListView: some View {
        if let item = selectedSidebarItem {
            switch item {
            case .news:
                categoryArticlesList
            case .forYou:
                forYouList
            case .local:
                localNewsList
            case .watchLater:
                watchLaterList
            case .clusters:
                clustersList
            case .alerts:
                alertsList
            case .customFeeds:
                customFeedsList
            }
        } else {
            ContentUnavailableView("Select a Section", systemImage: "sidebar.left", description: Text("Choose a section from the sidebar"))
        }
    }

    private var categoryArticlesList: some View {
        let articles = filteredArticles(newsAggregator.articles(for: selectedCategory))
        return List(articles, selection: $selectedArticle) { article in
            ArticleRowView(article: article)
                .tag(article)
        }
        .listStyle(.plain)
        .navigationTitle(selectedCategory.rawValue)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(NewsCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 400)
            }
        }
    }

    private var forYouList: some View {
        let articles = filteredArticles(PersonalizationEngine.shared.recommendations(from: newsAggregator.articles))
        return List(articles, selection: $selectedArticle) { article in
            ArticleRowView(article: article)
                .tag(article)
        }
        .listStyle(.plain)
        .navigationTitle("For You")
    }

    private var localNewsList: some View {
        let articles = filteredArticles(LocalNewsService.shared.localArticles)
        return List(articles, selection: $selectedArticle) { article in
            ArticleRowView(article: article)
                .tag(article)
        }
        .listStyle(.plain)
        .navigationTitle("Local News")
    }

    private var watchLaterList: some View {
        let items = WatchLaterManager.shared.items
        return List(items, selection: Binding(
            get: { items.first { $0.article == selectedArticle }?.article },
            set: { selectedArticle = $0 }
        )) { item in
            ArticleRowView(article: item.article)
                .tag(item.article)
        }
        .listStyle(.plain)
        .navigationTitle("Saved Articles")
    }

    private var clustersList: some View {
        List(StoryClusterEngine.shared.clusters) { cluster in
            ClusterRowView(cluster: cluster)
        }
        .listStyle(.plain)
        .navigationTitle("Multi-Source Stories")
    }

    private var alertsList: some View {
        List(KeywordAlertManager.shared.alerts) { alert in
            AlertRowView(alert: alert)
        }
        .listStyle(.plain)
        .navigationTitle("Keyword Alerts")
    }

    private var customFeedsList: some View {
        let articles = filteredArticles(CustomFeedManager.shared.customArticles)
        return List(articles, selection: $selectedArticle) { article in
            ArticleRowView(article: article)
                .tag(article)
        }
        .listStyle(.plain)
        .navigationTitle("Custom Feeds")
    }

    // MARK: - Detail View

    @ViewBuilder
    private var detailView: some View {
        if let article = selectedArticle {
            iPadArticleDetailView(article: article)
        } else {
            ContentUnavailableView("Select an Article", systemImage: "doc.text", description: Text("Choose an article to read"))
        }
    }

    // MARK: - Helpers

    private func filteredArticles(_ articles: [NewsArticle]) -> [NewsArticle] {
        guard !searchText.isEmpty else { return articles }
        return articles.filter { article in
            article.title.localizedCaseInsensitiveContains(searchText) ||
            article.description.localizedCaseInsensitiveContains(searchText) ||
            article.source.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func badgeCount(for item: SidebarItem) -> Int {
        switch item {
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

// MARK: - Article Row View

struct ArticleRowView: View {
    let article: NewsArticle

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: article.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                default:
                    ProgressView()
                }
            }
            .frame(width: 80, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .background(Color.secondary.opacity(0.1))

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(article.source.name)
                        .font(.caption)
                        .foregroundColor(Color(hex: article.source.bias.color))

                    Text(article.publishedAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if article.sentimentScore != 0 {
                        SentimentBadge(score: article.sentimentScore)
                    }
                }
            }

            Spacer()

            // Save button
            Button {
                toggleSaved(article)
            } label: {
                Image(systemName: isSaved(article) ? "bookmark.fill" : "bookmark")
                    .foregroundColor(isSaved(article) ? .yellow : .secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    private func isSaved(_ article: NewsArticle) -> Bool {
        WatchLaterManager.shared.items.contains { $0.article.id == article.id }
    }

    private func toggleSaved(_ article: NewsArticle) {
        if isSaved(article) {
            WatchLaterManager.shared.remove(articleId: article.id)
        } else {
            WatchLaterManager.shared.add(article: article)
        }
    }
}

// MARK: - Sentiment Badge

struct SentimentBadge: View {
    let score: Double

    var body: some View {
        let color: Color = score > 0.2 ? .green : (score < -0.2 ? .red : .gray)
        let icon = score > 0.2 ? "arrow.up.circle.fill" : (score < -0.2 ? "arrow.down.circle.fill" : "minus.circle.fill")

        Image(systemName: icon)
            .font(.caption)
            .foregroundColor(color)
    }
}

// MARK: - Cluster Row View

struct ClusterRowView: View {
    let cluster: StoryCluster

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(cluster.topic)
                .font(.headline)

            HStack(spacing: 12) {
                Label("\(cluster.sourceCount) sources", systemImage: "newspaper")
                Label("\(cluster.articleCount) articles", systemImage: "doc.text")
                Text(cluster.lastUpdated.formatted(.relative(presentation: .named)))
            }
            .font(.caption)
            .foregroundColor(.secondary)

            // Source badges
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(cluster.articles.prefix(5)) { article in
                        Text(article.source.name)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: article.source.bias.color).opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Alert Row View

struct AlertRowView: View {
    let alert: KeywordAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(alert.keyword)
                    .font(.headline)

                Spacer()

                if alert.matchCount > 0 {
                    Text("\(alert.matchCount) matches")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            if let lastMatch = alert.lastMatchDate {
                Text("Last match: \(lastMatch.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - iPad Article Detail View

struct iPadArticleDetailView: View {
    let article: NewsArticle
    @Environment(\.openURL) private var openURL
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header image
                if let imageURL = article.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                        default:
                            ProgressView()
                        }
                    }
                    .frame(height: 300)
                    .clipped()
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(article.title)
                        .font(.largeTitle.bold())

                    // Meta info
                    HStack(spacing: 16) {
                        Label(article.source.name, systemImage: "newspaper")
                            .foregroundColor(Color(hex: article.source.bias.color))

                        Label(article.publishedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                            .foregroundColor(.secondary)

                        if article.sentimentScore != 0 {
                            Label(
                                article.sentimentScore > 0.2 ? "Positive" : (article.sentimentScore < -0.2 ? "Negative" : "Neutral"),
                                systemImage: article.sentimentScore > 0.2 ? "arrow.up" : (article.sentimentScore < -0.2 ? "arrow.down" : "minus")
                            )
                            .foregroundColor(article.sentimentScore > 0.2 ? .green : (article.sentimentScore < -0.2 ? .red : .gray))
                        }
                    }
                    .font(.subheadline)

                    Divider()

                    // Description
                    Text(article.description)
                        .font(.body)
                        .lineSpacing(4)

                    // Entities
                    if !article.entities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Key Topics")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(article.entities, id: \.self) { entity in
                                    Text(entity)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.cyan.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Actions
                    HStack(spacing: 16) {
                        Button {
                            openURL(article.url)
                        } label: {
                            Label("Read Full Article", systemImage: "safari")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            toggleSaved()
                        } label: {
                            Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                        }
                        .buttonStyle(.bordered)
                        .tint(isSaved ? .yellow : nil)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .navigationTitle(article.source.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [article.url])
        }
    }

    private var isSaved: Bool {
        WatchLaterManager.shared.items.contains { $0.article.id == article.id }
    }

    private func toggleSaved() {
        if isSaved {
            WatchLaterManager.shared.remove(articleId: article.id)
        } else {
            WatchLaterManager.shared.add(article: article)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

// MARK: - iPad Settings View

struct iPadSettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $settingsManager.settings.theme) {
                    Text("Dark").tag(AppTheme.dark)
                    Text("Light").tag(AppTheme.light)
                    Text("System").tag(AppTheme.system)
                }
            }

            Section("Background Refresh") {
                Toggle("Enable Background Refresh", isOn: $settingsManager.settings.enableBackgroundRefresh)

                if settingsManager.settings.enableBackgroundRefresh {
                    Picker("Refresh Interval", selection: $settingsManager.settings.backgroundRefreshInterval) {
                        Text("15 minutes").tag(TimeInterval(15 * 60))
                        Text("30 minutes").tag(TimeInterval(30 * 60))
                        Text("1 hour").tag(TimeInterval(60 * 60))
                        Text("2 hours").tag(TimeInterval(2 * 60 * 60))
                    }
                }
            }

            Section("Local News") {
                TextField("ZIP Code", text: Binding(
                    get: { settingsManager.settings.localNewsZipCode ?? "" },
                    set: { settingsManager.settings.localNewsZipCode = $0.isEmpty ? nil : $0 }
                ))
                .keyboardType(.numberPad)
            }

            Section("Content") {
                Toggle("Show Breaking News Banner", isOn: $settingsManager.settings.showBreakingNews)
                Toggle("Show Sentiment Analysis", isOn: $settingsManager.settings.showSentiment)
                Toggle("Show Source Bias", isOn: $settingsManager.settings.showBias)
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    iPadNewsView()
}
#endif
