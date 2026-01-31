//
//  ForYouView.swift
//  NewsTV
//
//  Personalized feed based on viewing habits
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ForYouView: View {
    @ObservedObject private var personalization = PersonalizationEngine.shared
    @ObservedObject private var newsAggregator = NewsAggregator.shared
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header

            // Recommended categories
            if !personalization.recommendedCategories().isEmpty {
                recommendedCategoriesRow
            }

            // Personalized articles
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(personalizedArticles) { article in
                        Button {
                            selectedArticle = article
                        } label: {
                            PersonalizedArticleCard(article: article)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 20)
            }
        }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
    }

    private var personalizedArticles: [NewsArticle] {
        personalization.forYouFeed(from: newsAggregator.articles, count: 30)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundColor(.purple)

                    Text("For You")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Personalized based on your interests")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Top interests badges
            if !personalization.topInterests().isEmpty {
                HStack(spacing: 8) {
                    ForEach(personalization.topInterests().prefix(3), id: \.self) { interest in
                        Text(interest.capitalized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.3))
                            .cornerRadius(16)
                    }
                }
            }
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
        .background(Color.black.opacity(0.3))
    }

    private var recommendedCategoriesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                Text("Recommended:")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))

                ForEach(personalization.recommendedCategories(), id: \.self) { category in
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                        Text(category.rawValue)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: category.color))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: category.color).opacity(0.15))
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 12)
        }
    }
}

struct PersonalizedArticleCard: View {
    let article: NewsArticle
    @ObservedObject private var personalization = PersonalizationEngine.shared
    // @Environment(\.isFocused) removed for tvOS 26.3 beta
    private let isFocused = false

    var body: some View {
        HStack(spacing: 20) {
            // Relevance indicator
            VStack {
                Circle()
                    .fill(relevanceColor)
                    .frame(width: 12, height: 12)

                Text("\(Int(relevanceScore * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(relevanceColor)
            }
            .frame(width: 40)

            // Article info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(article.source.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: article.category.color))

                    Text("•")
                        .foregroundColor(.white.opacity(0.4))

                    Text(article.timeAgoString)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))

                    Spacer()

                    Image(systemName: article.category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: article.category.color))
                }

                Text(article.title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if let summary = article.summary ?? article.rssDescription {
                    Text(summary)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
            }

            Spacer()

            // Watch later button
            WatchLaterButton(article: article)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isFocused ? Color.purple.opacity(0.3) : Color.white.opacity(0.08))
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .onAppear {
            personalization.startViewing(article)
        }
        .onDisappear {
            personalization.stopViewing(article)
        }
    }

    private var relevanceScore: Double {
        personalization.profile.relevanceScore(for: article)
    }

    private var relevanceColor: Color {
        if relevanceScore > 0.7 { return .green }
        if relevanceScore > 0.4 { return .yellow }
        return .orange
    }
}

#Preview {
    ForYouView()
        .preferredColorScheme(.dark)
}
