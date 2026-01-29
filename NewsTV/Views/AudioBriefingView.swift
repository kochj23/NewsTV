//
//  AudioBriefingView.swift
//  NewsTV
//
//  Audio news briefing interface
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct AudioBriefingView: View {
    let articles: [NewsArticle]

    @StateObject private var ttsManager = TTSManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.15),
                    Color(red: 0.1, green: 0.12, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.cyan)
                        .symbolEffect(.pulse, isActive: ttsManager.isSpeaking)

                    Text("Audio Briefing")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("\(articles.count) stories")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Current article
                if ttsManager.isSpeaking || ttsManager.currentArticleIndex > 0,
                   ttsManager.currentArticleIndex < articles.count {
                    currentArticleCard
                }

                // Progress
                VStack(spacing: 12) {
                    ProgressView(value: ttsManager.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                        .frame(width: 600)

                    Text("Story \(ttsManager.currentArticleIndex + 1) of \(articles.count)")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Controls
                controlButtons

                // Article list
                articleListSection
            }
            .padding(60)
        }
        .onAppear {
            if !ttsManager.isSpeaking {
                ttsManager.startBriefing(articles: articles)
            }
        }
        .onDisappear {
            // Don't stop - let it continue in background
        }
    }

    // MARK: - Current Article Card

    private var currentArticleCard: some View {
        let article = articles[ttsManager.currentArticleIndex]

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color(hex: article.source.bias.color))
                    .frame(width: 12, height: 12)

                Text(article.source.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.cyan)

                Spacer()

                Text(article.category.rawValue)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: article.category.color))
            }

            Text(article.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            if let description = article.rssDescription {
                Text(description)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(32)
        .frame(width: 800)
        .background(Color.white.opacity(0.08))
        .cornerRadius(20)
    }

    // MARK: - Controls

    private var controlButtons: some View {
        HStack(spacing: 40) {
            // Previous
            Button {
                ttsManager.skipToPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 70, height: 70)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(ttsManager.currentArticleIndex == 0)

            // Play/Pause
            Button {
                if ttsManager.isSpeaking {
                    ttsManager.pause()
                } else {
                    ttsManager.resume()
                }
            } label: {
                Image(systemName: ttsManager.isSpeaking ? "pause.fill" : "play.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.black)
                    .frame(width: 100, height: 100)
                    .background(Color.cyan)
                    .clipShape(Circle())
            }

            // Next
            Button {
                ttsManager.skipToNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 70, height: 70)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(ttsManager.currentArticleIndex >= articles.count - 1)

            // Stop
            Button {
                ttsManager.stop()
                dismiss()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.red)
                    .frame(width: 70, height: 70)
                    .background(Color.red.opacity(0.2))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Article List

    private var articleListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Up Next")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(articles.indices, id: \.self) { index in
                        UpNextCardView(
                            article: articles[index],
                            index: index,
                            currentIndex: ttsManager.currentArticleIndex
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Up Next Card View

struct UpNextCardView: View {
    let article: NewsArticle
    let index: Int
    let currentIndex: Int

    private var isCurrent: Bool { index == currentIndex }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 24, height: 24)
                    .background(isCurrent ? Color.cyan : Color.white.opacity(0.5))
                    .clipShape(Circle())

                Text(article.source.name)
                    .font(.system(size: 14))
                    .foregroundColor(.cyan)
            }

            Text(article.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(16)
        .frame(width: 250)
        .background(isCurrent ? Color.cyan.opacity(0.2) : Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrent ? Color.cyan : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    AudioBriefingView(articles: [])
}
