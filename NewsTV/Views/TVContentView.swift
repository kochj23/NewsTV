//
//  TVContentView.swift
//  NewsTV
//
//  Main content view for tvOS
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct TVContentView: View {
    @StateObject private var newsAggregator = NewsAggregator.shared
    @StateObject private var sentimentAnalyzer = SentimentAnalyzer.shared
    @StateObject private var ttsManager = TTSManager.shared
    @StateObject private var settingsManager = SettingsManager.shared

    @State private var selectedCategory: NewsCategory = .topStories
    @State private var selectedArticle: NewsArticle?
    @State private var showSettings = false
    @State private var showAudioBriefing = false
    @State private var isAmbientMode = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                backgroundGradient

                if newsAggregator.isLoading && newsAggregator.articles.isEmpty {
                    loadingView
                } else if isAmbientMode {
                    AmbientModeView(articles: newsAggregator.topStories(count: 20))
                } else {
                    mainContentView
                }

                // Breaking news overlay
                if let breakingNews = newsAggregator.breakingNews().first, !isAmbientMode {
                    VStack {
                        BreakingNewsBanner(article: breakingNews)
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await newsAggregator.fetchAllNews()
            }
        }
        .onPlayPauseCommand {
            toggleAudioBriefing()
        }
    }

    // MARK: - Views

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.12),
                Color(red: 0.1, green: 0.1, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
            // Category tabs
            categoryTabBar

            // Content
            TabView(selection: $selectedCategory) {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    CategoryNewsView(
                        category: category,
                        articles: newsAggregator.articles(for: category),
                        selectedArticle: $selectedArticle
                    )
                    .tag(category)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
        .sheet(isPresented: $showAudioBriefing) {
            AudioBriefingView(articles: newsAggregator.topStories(count: 10))
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var categoryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedCategory == category,
                        articleCount: newsAggregator.articles(for: category).count
                    )
                    .focusable()
                    .onTapGesture {
                        withAnimation {
                            selectedCategory = category
                        }
                    }
                }

                // Audio briefing button
                Button {
                    showAudioBriefing = true
                } label: {
                    HStack {
                        Image(systemName: ttsManager.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                        Text("Audio Briefing")
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.cyan.opacity(0.2))
                    .cornerRadius(25)
                }

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
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 20)
        }
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Actions

    private func toggleAudioBriefing() {
        if ttsManager.isSpeaking {
            ttsManager.pause()
        } else if !newsAggregator.articles.isEmpty {
            ttsManager.startBriefing(articles: newsAggregator.topStories(count: 10))
        }
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let category: NewsCategory
    let isSelected: Bool
    let articleCount: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                Text(category.rawValue)

                if articleCount > 0 {
                    Text("\(articleCount)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.cyan : Color.white.opacity(0.5))
                        .cornerRadius(10)
                }
            }
            .font(.system(size: 22, weight: isSelected ? .bold : .medium))
            .foregroundColor(isSelected ? .cyan : .white.opacity(0.7))

            Rectangle()
                .fill(isSelected ? Color.cyan : Color.clear)
                .frame(height: 3)
                .cornerRadius(1.5)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    TVContentView()
}
