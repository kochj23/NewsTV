//
//  ScreensaverView.swift
//  NewsTV
//
//  Beautiful screensaver mode with rotating headlines
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ScreensaverView: View {
    @ObservedObject private var screensaver = ScreensaverManager.shared
    @State private var showInfo = true

    var body: some View {
        ZStack {
            // Background image
            backgroundImage

            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content
            VStack {
                Spacer()

                if showInfo, let article = screensaver.currentArticle {
                    articleOverlay(article)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(60)

            // Clock
            VStack {
                HStack {
                    Spacer()
                    clockView
                        .padding(40)
                }
                Spacer()
            }
        }
        .onTapGesture {
            screensaver.deactivate()
        }
        .onAppear {
            startInfoCycle()
        }
    }

    private var backgroundImage: some View {
        Group {
            if let imageURL = screensaver.backgroundImageURL {
                TimedAsyncImage(url: imageURL, timeout: 10) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .ignoresSafeArea()
                    case .failure, .empty:
                        gradientBackground
                    @unknown default:
                        gradientBackground
                    }
                }
                .frame(minWidth: 1920, minHeight: 1080)
            } else {
                gradientBackground
            }
        }
    }

    private var gradientBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func articleOverlay(_ article: NewsArticle) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category badge
            HStack(spacing: 8) {
                Image(systemName: article.category.icon)
                Text(article.category.rawValue)
            }
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(Color(hex: article.category.color))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: article.category.color).opacity(0.2))
            .cornerRadius(20)

            // Title
            Text(article.title)
                .font(.system(size: 48, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .lineLimit(3)
                .shadow(color: .black.opacity(0.5), radius: 10)

            // Source and time
            HStack(spacing: 16) {
                Text(article.source.name)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                Text("•")
                    .foregroundColor(.white.opacity(0.5))

                Text(article.timeAgoString)
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .opacity(0.8)
        )
        .animation(.easeInOut(duration: 1.0), value: article.id)
    }

    private var clockView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(Date(), style: .time)
                .font(.system(size: 64, weight: .light, design: .rounded))
                .foregroundColor(.white)

            Text(Date(), style: .date)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .opacity(0.6)
        )
    }

    private func startInfoCycle() {
        // Periodically show/hide info for visual interest
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                showInfo.toggle()
            }

            // Show again after brief hidden period
            if !showInfo {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showInfo = true
                    }
                }
            }
        }
    }
}

// MARK: - TimedAsyncImage

/// AsyncImage wrapper that falls back after a timeout.
private struct TimedAsyncImage<Content: View>: View {
    let url: URL
    let timeout: TimeInterval
    @ViewBuilder let content: (AsyncImagePhase) -> Content

    @State private var timedOut = false

    var body: some View {
        if timedOut {
            content(.empty)
        } else {
            AsyncImage(url: url) { phase in
                content(phase)
            }
            .task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if !Task.isCancelled {
                    timedOut = true
                }
            }
        }
    }
}

#Preview {
    ScreensaverView()
}
