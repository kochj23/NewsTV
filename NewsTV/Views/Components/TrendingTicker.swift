//
//  TrendingTicker.swift
//  NewsTV
//
//  Scrolling ticker showing trending topics
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct TrendingTicker: View {
    @ObservedObject private var trendingEngine = TrendingTopicsEngine.shared
    @ObservedObject private var settings = SettingsManager.shared

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0

    private let animationDuration: Double = 30

    var body: some View {
        if settings.settings.enableTrendingTicker && !trendingEngine.trendingTopics.isEmpty {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    tickerContent
                        .background(
                            GeometryReader { textGeometry in
                                Color.clear.preference(
                                    key: TextWidthPreferenceKey.self,
                                    value: textGeometry.size.width
                                )
                            }
                        )

                    // Duplicate for seamless loop
                    tickerContent
                }
                .offset(x: offset)
                .onAppear {
                    startAnimation(screenWidth: geometry.size.width)
                }
                .onPreferenceChange(TextWidthPreferenceKey.self) { width in
                    textWidth = width
                }
            }
            .frame(height: 36)
            .background(Color.black.opacity(0.5))
            .clipped()
        }
    }

    private var tickerContent: some View {
        HStack(spacing: 40) {
            ForEach(trendingEngine.trendingTopics) { topic in
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)

                    Text(topic.topic)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("(\(topic.articleCount))")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))

                    if let sentiment = topic.sentiment {
                        sentimentIndicator(sentiment)
                    }
                }
            }

            Spacer()
                .frame(width: 100)
        }
        .padding(.horizontal, 20)
    }

    private func sentimentIndicator(_ sentiment: Double) -> some View {
        Circle()
            .fill(sentimentColor(sentiment))
            .frame(width: 8, height: 8)
    }

    private func sentimentColor(_ sentiment: Double) -> Color {
        if sentiment > 0.2 { return .green }
        if sentiment < -0.2 { return .red }
        return .yellow
    }

    private func startAnimation(screenWidth: CGFloat) {
        offset = screenWidth

        withAnimation(
            .linear(duration: animationDuration)
            .repeatForever(autoreverses: false)
        ) {
            offset = -textWidth - 100
        }
    }
}

private struct TextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    TrendingTicker()
        .preferredColorScheme(.dark)
}
