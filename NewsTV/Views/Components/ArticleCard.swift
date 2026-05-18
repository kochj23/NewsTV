//
//  ArticleCard.swift
//  NewsTV
//
//  Card view for displaying a news article
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ArticleCard: View {
    let article: NewsArticle
    let isFocused: Bool

    @StateObject private var sentimentAnalyzer = SentimentAnalyzer.shared

    private var sentiment: SentimentResult {
        sentimentAnalyzer.analyzeArticle(article)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Image
            ZStack(alignment: .topTrailing) {
                if let imageURL = article.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        case .failure:
                            imagePlaceholder
                        case .empty:
                            imagePlaceholder
                                .overlay(ProgressView())
                        @unknown default:
                            imagePlaceholder
                        }
                    }
                } else {
                    imagePlaceholder
                }

                // Breaking news badge
                if article.isBreakingNews {
                    Text("BREAKING")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .cornerRadius(4)
                        .padding(12)
                }
            }
            .frame(height: 180)
            .clipped()
            .cornerRadius(12)

            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Source and time
                HStack {
                    // Source with bias indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: article.source.bias.color))
                            .frame(width: 8, height: 8)

                        Text(article.source.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.cyan)
                    }

                    Spacer()

                    // Time ago
                    Text(article.timeAgoString)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }

                // Title
                Text(article.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Description preview
                if let description = article.rssDescription {
                    Text(description)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }

                // Bottom row: sentiment + category
                HStack {
                    // Sentiment indicator
                    HStack(spacing: 4) {
                        Image(systemName: sentiment.label.icon)
                        Text(sentiment.label.rawValue)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: sentiment.label.color))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: sentiment.label.color).opacity(0.2))
                    .cornerRadius(12)

                    Spacer()

                    // Bias label
                    Text(article.source.bias.shortLabel)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: article.source.bias.color))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isFocused ? 0.15 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused ? Color.cyan : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(color: isFocused ? .cyan.opacity(0.3) : .clear, radius: 20)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: article.category.color).opacity(0.3),
                        Color(hex: article.category.color).opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: article.category.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
            )
    }
}

// Color extension is in PlatformHelpers.swift

// MARK: - Preview

#Preview {
    ArticleCard(
        article: NewsArticle(
            title: "Apple Announces New AI Features for iOS 19",
            source: NewsSource(
                id: "techcrunch",
                name: "TechCrunch",
                rssURL: URL(string: "https://techcrunch.com/feed/")!,
                category: .technology,
                bias: .center
            ),
            url: URL(string: "https://example.com")!,
            publishedDate: Date(),
            category: .technology,
            rssDescription: "Apple unveiled groundbreaking AI features at WWDC, including enhanced Siri capabilities and on-device machine learning improvements.",
            isBreakingNews: true
        ),
        isFocused: true
    )
    .frame(width: 400)
    .padding()
    .background(Color.black)
}
