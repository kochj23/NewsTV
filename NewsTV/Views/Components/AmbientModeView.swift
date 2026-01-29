//
//  AmbientModeView.swift
//  NewsTV
//
//  Ambient screensaver-style news display
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct AmbientModeView: View {
    let articles: [NewsArticle]

    @State private var currentIndex = 0
    @State private var opacity: Double = 1.0

    private let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.08),
                    Color(red: 0.05, green: 0.05, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if !articles.isEmpty {
                VStack(spacing: 40) {
                    Spacer()

                    // Current article
                    articleDisplay(articles[currentIndex])
                        .opacity(opacity)

                    Spacer()

                    // Progress dots
                    progressIndicator

                    // Ticker
                    newsTickerView
                }
                .padding(60)
            }

            // NewsTV watermark
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "newspaper.fill")
                        Text("NewsTV")
                    }
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .padding()
                }
                Spacer()
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentIndex = (currentIndex + 1) % max(1, articles.count)
                withAnimation(.easeIn(duration: 0.5)) {
                    opacity = 1
                }
            }
        }
    }

    // MARK: - Article Display

    private func articleDisplay(_ article: NewsArticle) -> some View {
        VStack(spacing: 32) {
            // Category and source
            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Image(systemName: article.category.icon)
                    Text(article.category.rawValue)
                }
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(hex: article.category.color))

                Text("•")
                    .foregroundColor(.white.opacity(0.4))

                Text(article.source.name)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.cyan)

                Text("•")
                    .foregroundColor(.white.opacity(0.4))

                Text(article.timeAgoString)
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Title
            Text(article.title)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(4)

            // Description
            if let description = article.rssDescription {
                Text(description)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            // Bias indicator
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: article.source.bias.color))
                    .frame(width: 16, height: 16)

                Text(article.source.bias.rawValue)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: article.source.bias.color))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .cornerRadius(25)
        }
        .frame(maxWidth: 1400)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<min(articles.count, 10), id: \.self) { index in
                Circle()
                    .fill(index == currentIndex % min(articles.count, 10) ? Color.cyan : Color.white.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
    }

    // MARK: - News Ticker

    private var newsTickerView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 60) {
                ForEach(articles.prefix(20)) { article in
                    TickerItemView(article: article)
                }
            }
            .padding(.horizontal, 60)
        }
        .frame(height: 50)
        .background(Color.black.opacity(0.5))
    }
}

// MARK: - Ticker Item View

struct TickerItemView: View {
    let article: NewsArticle

    var body: some View {
        HStack(spacing: 12) {
            Text(article.source.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.cyan)

            Text(article.title)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
    }
}

// MARK: - Preview

#Preview {
    AmbientModeView(articles: [])
}
