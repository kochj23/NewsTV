//
//  ArticleDetailView.swift
//  NewsTV
//
//  Detailed view of a news article
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ArticleDetailView: View {
    let article: NewsArticle

    @StateObject private var sentimentAnalyzer = SentimentAnalyzer.shared
    @StateObject private var entityExtractor = EntityExtractor.shared
    @StateObject private var ttsManager = TTSManager.shared

    @State private var entities: [ExtractedEntity] = []
    @Environment(\.dismiss) private var dismiss

    private var sentiment: SentimentResult {
        sentimentAnalyzer.analyzeArticle(article)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header with image
                headerSection

                // Main content
                HStack(alignment: .top, spacing: 40) {
                    // Article content (left side)
                    VStack(alignment: .leading, spacing: 24) {
                        titleSection
                        descriptionSection

                        if let summary = article.summary {
                            aiSummarySection(summary)
                        }

                        // Key points
                        if let keyPoints = article.keyPoints, !keyPoints.isEmpty {
                            keyPointsSection(keyPoints)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Sidebar (right side)
                    VStack(spacing: 24) {
                        analysisCard
                        entitiesCard
                        sourceInfoCard
                    }
                    .frame(width: 400)
                }
                .padding(.horizontal, 60)

                // Action buttons
                actionButtons
            }
            .padding(.bottom, 60)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.1, green: 0.1, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            entities = entityExtractor.extractFromArticle(article)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageURL = article.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        categoryGradient
                    }
                }
            } else {
                categoryGradient
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Category badge
            HStack {
                Image(systemName: article.category.icon)
                Text(article.category.rawValue)
            }
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: article.category.color).opacity(0.8))
            .cornerRadius(20)
            .padding(30)
        }
        .frame(height: 400)
        .clipped()
    }

    private var categoryGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: article.category.color).opacity(0.6),
                Color(hex: article.category.color).opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: article.category.icon)
                .font(.system(size: 100))
                .foregroundColor(.white.opacity(0.2))
        )
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Source and time
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: article.source.bias.color))
                        .frame(width: 12, height: 12)
                    Text(article.source.name)
                        .foregroundColor(.cyan)
                }

                Text("•")
                    .foregroundColor(.white.opacity(0.5))

                Text(article.timeAgoString)
                    .foregroundColor(.white.opacity(0.5))

                if article.isBreakingNews {
                    Text("BREAKING")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(4)
                }
            }
            .font(.system(size: 18, weight: .medium))

            // Title
            Text(article.title)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var descriptionSection: some View {
        Group {
            if let description = article.rssDescription {
                Text(description)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(8)
            }
        }
    }

    private func aiSummarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                Text("AI Summary")
            }
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.cyan)

            Text(summary)
                .font(.system(size: 22))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
        }
        .padding(24)
        .background(Color.cyan.opacity(0.1))
        .cornerRadius(16)
    }

    private func keyPointsSection(_ points: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.circle.fill")
                Text("Key Points")
            }
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)

            ForEach(points, id: \.self) { point in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 8, height: 8)
                        .padding(.top, 10)

                    Text(point)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
    }

    // MARK: - Cards

    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Analysis")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            // Sentiment
            HStack {
                Image(systemName: sentiment.label.icon)
                    .foregroundColor(Color(hex: sentiment.label.color))
                VStack(alignment: .leading) {
                    Text("Sentiment")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    Text(sentiment.label.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: sentiment.label.color))
                }
                Spacer()
                Text("\(Int(sentiment.confidence * 100))%")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Bias
            HStack {
                Circle()
                    .fill(Color(hex: article.source.bias.color))
                    .frame(width: 20, height: 20)
                VStack(alignment: .leading) {
                    Text("Source Bias")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    Text(article.source.bias.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            // Bias spectrum
            BiasSpectrumView(value: article.source.bias.value)
        }
        .padding(24)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }

    private var entitiesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mentioned")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            if entities.isEmpty {
                Text("Analyzing...")
                    .foregroundColor(.white.opacity(0.5))
            } else {
                ForEach(entities.prefix(6)) { entity in
                    HStack {
                        Image(systemName: entity.type.icon)
                            .foregroundColor(.cyan)
                            .frame(width: 24)

                        Text(entity.text)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))

                        Spacer()

                        if entity.count > 1 {
                            Text("×\(entity.count)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }

    private var sourceInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Source Info")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Name")
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(article.source.name)
                        .foregroundColor(.white)
                }

                HStack {
                    Text("Reliability")
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("\(Int(article.source.reliability * 100))%")
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Category")
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(article.category.rawValue)
                        .foregroundColor(Color(hex: article.category.color))
                }
            }
            .font(.system(size: 16))
        }
        .padding(24)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 30) {
            Button {
                ttsManager.speakArticle(article)
            } label: {
                HStack {
                    Image(systemName: ttsManager.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                    Text(ttsManager.isSpeaking ? "Stop Reading" : "Read Aloud")
                }
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.cyan)
                .padding(.horizontal, 30)
                .padding(.vertical, 16)
                .background(Color.cyan.opacity(0.2))
                .cornerRadius(30)
            }

            Button {
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "xmark")
                    Text("Close")
                }
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 30)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.1))
                .cornerRadius(30)
            }
        }
        .padding(.horizontal, 60)
    }
}

// MARK: - Bias Spectrum View

struct BiasSpectrumView: View {
    let value: Double // -1.0 (left) to 1.0 (right)

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Spectrum gradient
                LinearGradient(
                    colors: [.blue, .purple, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 8)
                .cornerRadius(4)

                // Indicator
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .shadow(radius: 2)
                    .offset(x: CGFloat((value + 1) / 2) * (geometry.size.width - 16))
            }
        }
        .frame(height: 16)
    }
}

// MARK: - Preview

#Preview {
    ArticleDetailView(
        article: NewsArticle(
            title: "Major Tech Companies Announce AI Partnership",
            source: NewsSource(
                id: "reuters",
                name: "Reuters",
                rssURL: URL(string: "https://reuters.com/feed")!,
                category: .technology,
                bias: .center,
                reliability: 0.95
            ),
            url: URL(string: "https://example.com")!,
            publishedDate: Date(),
            category: .technology,
            rssDescription: "Several major technology companies have announced a groundbreaking partnership focused on developing ethical AI systems. The collaboration aims to establish industry standards for artificial intelligence development.",
            summary: "Tech giants form AI ethics alliance to develop responsible AI standards.",
            keyPoints: [
                "Partnership includes five major tech companies",
                "Focus on ethical AI development",
                "New industry standards expected by 2027"
            ],
            isBreakingNews: false,
            importance: 8
        )
    )
}
