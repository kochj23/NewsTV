//
//  CustomFeedsView.swift
//  NewsTV
//
//  Manage custom RSS feeds
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct CustomFeedsView: View {
    @ObservedObject private var customFeeds = CustomFeedManager.shared
    @ObservedObject private var settings = SettingsManager.shared
    @State private var showAddFeed = false
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header

            HStack(spacing: 0) {
                // Feed list
                feedList
                    .frame(width: 450)

                Divider()
                    .background(Color.white.opacity(0.2))

                // Articles from custom feeds
                if customFeeds.customArticles.isEmpty && !customFeeds.isLoading {
                    emptyArticlesView
                } else {
                    articlesView
                }
            }
        }
        .sheet(isPresented: $showAddFeed) {
            AddCustomFeedView()
        }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
        .onAppear {
            Task {
                await customFeeds.fetchAllCustomFeeds()
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.square.on.square")
                        .font(.system(size: 28))
                        .foregroundColor(.green)

                    Text("Custom Feeds")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Add your own RSS feeds")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Button {
                showAddFeed = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Feed")
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.green)
                .cornerRadius(25)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
        .background(Color.black.opacity(0.3))
    }

    private var feedList: some View {
        VStack(spacing: 0) {
            if settings.settings.customFeeds.isEmpty {
                suggestedFeedsView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(settings.settings.customFeeds) { feed in
                            CustomFeedRow(feed: feed)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private var suggestedFeedsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Suggested Feeds")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.top, 20)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(CustomFeedManager.suggestedFeeds, id: \.name) { suggestion in
                        SuggestedFeedRow(
                            name: suggestion.name,
                            category: suggestion.category
                        ) {
                            if let url = URL(string: suggestion.url) {
                                customFeeds.addFeed(name: suggestion.name, url: url, category: suggestion.category)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var emptyArticlesView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "newspaper")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))

            Text("No Articles")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            Text("Add feeds to see articles here")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.5))

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var articlesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Articles")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if customFeeds.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Button {
                    Task {
                        await customFeeds.fetchAllCustomFeeds()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(customFeeds.customArticles) { article in
                        Button {
                            selectedArticle = article
                        } label: {
                            ArticleCard(article: article, isFocused: false)
                        }
                        .buttonStyle(.card)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

struct CustomFeedRow: View {
    let feed: CustomRSSFeed
    @ObservedObject private var customFeeds = CustomFeedManager.shared
    // @Environment(\.isFocused) removed for tvOS 26.3 beta
    private let isFocused = false

    var body: some View {
        HStack(spacing: 12) {
            // Enable toggle
            Button {
                customFeeds.toggleFeed(id: feed.id, enabled: !feed.isEnabled)
            } label: {
                Image(systemName: feed.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(feed.isEnabled ? .green : .gray)
            }
            .buttonStyle(.plain)

            // Feed info
            VStack(alignment: .leading, spacing: 4) {
                Text(feed.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(feed.isEnabled ? .white : .white.opacity(0.5))

                HStack(spacing: 8) {
                    Image(systemName: feed.category.icon)
                        .foregroundColor(Color(hex: feed.category.color))

                    Text(feed.category.rawValue)
                        .foregroundColor(Color(hex: feed.category.color))

                    if feed.articleCount > 0 {
                        Text("• \(feed.articleCount) articles")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .font(.system(size: 14))

                if let lastFetch = feed.lastFetchDate {
                    Text("Updated \(lastFetch.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            // Delete button
            Button {
                customFeeds.removeFeed(id: feed.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 20))
                    .foregroundColor(.red.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isFocused ? Color.green.opacity(0.2) : Color.white.opacity(0.05))
        )
    }
}

struct SuggestedFeedRow: View {
    let name: String
    let category: NewsCategory
    let action: () -> Void
    // @Environment(\.isFocused) removed for tvOS 26.3 beta
    private let isFocused = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                        Text(category.rawValue)
                    }
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: category.color))
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.green.opacity(0.2) : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Custom Feed View

struct AddCustomFeedView: View {
    @ObservedObject private var customFeeds = CustomFeedManager.shared
    @State private var feedName = ""
    @State private var feedURL = ""
    @State private var selectedCategory: NewsCategory = .topStories
    @State private var isValidating = false
    @State private var validationError: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Feed name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Feed Name")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    TextField("My Custom Feed", text: $feedName)
                        .font(.system(size: 20))
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }

                // Feed URL
                VStack(alignment: .leading, spacing: 8) {
                    Text("RSS Feed URL")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    TextField("https://example.com/feed.xml", text: $feedURL)
                        .font(.system(size: 20))
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)

                    if let error = validationError {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                }

                // Category picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(NewsCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(height: 150)
                }

                Spacer()

                // Add button
                Button {
                    addFeed()
                } label: {
                    HStack {
                        if isValidating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text("Add Feed")
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isFormValid ? Color.green : Color.gray)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!isFormValid || isValidating)
            }
            .padding(40)
            .navigationTitle("Add Custom Feed")
        }
    }

    private var isFormValid: Bool {
        !feedName.isEmpty && !feedURL.isEmpty && URL(string: feedURL) != nil
    }

    private func addFeed() {
        guard let url = URL(string: feedURL) else {
            validationError = "Invalid URL"
            return
        }

        isValidating = true
        validationError = nil

        Task {
            let isValid = await customFeeds.validateFeedURL(url)

            if isValid {
                customFeeds.addFeed(name: feedName, url: url, category: selectedCategory)
                dismiss()
            } else {
                validationError = "Could not parse RSS feed at this URL"
            }

            isValidating = false
        }
    }
}

#Preview {
    CustomFeedsView()
        .preferredColorScheme(.dark)
}
