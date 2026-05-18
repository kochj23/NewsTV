//
//  BreakingNewsBanner.swift
//  NewsTV
//
//  Breaking news alert banner
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct BreakingNewsBanner: View {
    let article: NewsArticle

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 20) {
            // Alert icon
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolEffect(.pulse, isActive: isAnimating)
                Text("BREAKING")
                    .font(.system(size: 18, weight: .black))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.red)
            .cornerRadius(8)

            // Headline
            Text(article.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            // Source
            Text(article.source.name)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.cyan)

            // Time
            Text(article.timeAgoString)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [Color.red.opacity(0.3), Color.black.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview

#Preview {
    BreakingNewsBanner(
        article: NewsArticle(
            title: "Major Earthquake Strikes Pacific Region",
            source: NewsSource(
                id: "reuters",
                name: "Reuters",
                rssURL: URL(string: "https://reuters.com/feed")!,
                category: .world,
                bias: .center
            ),
            url: URL(string: "https://example.com")!,
            publishedDate: Date(),
            category: .world,
            isBreakingNews: true
        )
    )
    .background(Color.black)
}
