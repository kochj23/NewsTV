//
//  StoryClusterView.swift
//  NewsTV
//
//  Multi-source story comparison view
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct StoryClusterView: View {
    let cluster: StoryCluster
    @State private var selectedArticleIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Content split view
            HStack(spacing: 0) {
                // Source list
                sourceList
                    .frame(width: 400)

                Divider()
                    .background(Color.white.opacity(0.2))

                // Article detail
                if selectedArticleIndex < cluster.articles.count {
                    articleDetail(cluster.articles[selectedArticleIndex])
                }
            }

            // Perspective breakdown
            if let perspectives = cluster.perspectives {
                perspectiveView(perspectives)
            }
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 24))
                    .foregroundColor(.cyan)

                Text("Multi-Source Story")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.cyan)

                Spacer()

                Text("\(cluster.sourceCount) sources • \(cluster.articleCount) articles")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }

            Text(cluster.topic)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(24)
        .background(Color.black.opacity(0.3))
    }

    private var sourceList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(cluster.articles.enumerated()), id: \.element.id) { index, article in
                    Button {
                        selectedArticleIndex = index
                    } label: {
                        SourceRow(
                            article: article,
                            isSelected: index == selectedArticleIndex
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private func articleDetail(_ article: NewsArticle) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Source badge
                HStack {
                    Text(article.source.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: article.category.color).opacity(0.3))
                        .cornerRadius(8)

                    Spacer()

                    BiasIndicatorBadge(bias: article.source.bias)
                }

                // Title
                Text(article.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                // Description
                if let description = article.rssDescription {
                    Text(description)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(4)
                }

                // Sentiment
                if let sentiment = article.sentiment {
                    SentimentBadge(sentiment: sentiment)
                }

                // Actions
                HStack(spacing: 16) {
                    WatchLaterButton(article: article)

                    Button {
                        // Open full article
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text("Read Full Article")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.cyan.opacity(0.3)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
    }

    private func perspectiveView(_ perspectives: PerspectiveBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Perspective Analysis")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 20) {
                // Left perspective
                if let left = perspectives.leftPerspective {
                    PerspectiveCard(
                        title: "Left-Leaning",
                        content: left,
                        color: .blue
                    )
                }

                // Center perspective
                if let center = perspectives.centerPerspective {
                    PerspectiveCard(
                        title: "Center",
                        content: center,
                        color: .purple
                    )
                }

                // Right perspective
                if let right = perspectives.rightPerspective {
                    PerspectiveCard(
                        title: "Right-Leaning",
                        content: right,
                        color: .red
                    )
                }
            }

            // Shared facts
            if !perspectives.sharedFacts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shared Facts")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)

                    ForEach(perspectives.sharedFacts, id: \.self) { fact in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(fact)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .font(.system(size: 14))
                    }
                }
            }

            // Contentions
            if !perspectives.contentions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Points of Contention")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)

                    ForEach(perspectives.contentions, id: \.self) { contention in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(contention)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .font(.system(size: 14))
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.05))
    }
}

// MARK: - Supporting Views

struct SourceRow: View {
    let article: NewsArticle
    let isSelected: Bool
    // @Environment(\.isFocused) removed for tvOS 26.3 beta
    private let isFocused = false

    var body: some View {
        HStack(spacing: 12) {
            // Bias indicator
            Rectangle()
                .fill(Color(hex: article.source.bias.color))
                .frame(width: 4)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 4) {
                Text(article.source.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text(article.timeAgoString)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.cyan)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected || isFocused ? Color.cyan.opacity(0.2) : Color.white.opacity(0.05))
        )
    }
}

struct PerspectiveCard: View {
    let title: String
    let content: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)

            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct BiasIndicatorBadge: View {
    let bias: SourceBias

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: bias.color))
                .frame(width: 8, height: 8)

            Text(bias.rawValue)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: bias.color))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(hex: bias.color).opacity(0.15))
        .cornerRadius(12)
    }
}

struct SentimentBadge: View {
    let sentiment: SentimentResult

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: sentiment.label.icon)
                .foregroundColor(Color(hex: sentiment.label.color))

            Text(sentiment.label.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: sentiment.label.color))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: sentiment.label.color).opacity(0.15))
        .cornerRadius(8)
    }
}

#Preview {
    StoryClusterView(
        cluster: StoryCluster(
            topic: "Sample Story Cluster",
            articles: []
        )
    )
    .preferredColorScheme(.dark)
}
