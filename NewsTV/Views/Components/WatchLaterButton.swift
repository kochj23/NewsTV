//
//  WatchLaterButton.swift
//  NewsTV
//
//  Button to add/remove articles from Watch Later queue
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct WatchLaterButton: View {
    let article: NewsArticle
    @ObservedObject private var watchLater = WatchLaterManager.shared
    @State private var showConfirmation = false

    var body: some View {
        Button {
            toggleWatchLater()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isInWatchLater ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 20))

                if showConfirmation {
                    Text(isInWatchLater ? "Saved" : "Removed")
                        .font(.system(size: 16, weight: .medium))
                        .transition(.opacity)
                }
            }
            .foregroundColor(isInWatchLater ? .yellow : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }

    private var isInWatchLater: Bool {
        watchLater.contains(article)
    }

    private func toggleWatchLater() {
        if isInWatchLater {
            watchLater.remove(article)
        } else {
            watchLater.add(article)
        }

        showConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showConfirmation = false
            }
        }
    }
}

// MARK: - Watch Later List View

struct WatchLaterListView: View {
    @ObservedObject private var watchLater = WatchLaterManager.shared
    @State private var selectedItem: WatchLaterItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.yellow)

                Text("Watch Later")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                if !watchLater.items.isEmpty {
                    Button("Clear Completed") {
                        watchLater.clearCompleted()
                    }
                    .font(.system(size: 18))
                    .foregroundColor(.red.opacity(0.8))
                }
            }
            .padding(.horizontal, 48)
            .padding(.top, 24)

            if watchLater.items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(watchLater.items) { item in
                            WatchLaterItemRow(item: item)
                        }
                    }
                    .padding(.horizontal, 48)
                }
            }

            if watchLater.isSyncing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Syncing with iCloud...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            Task {
                await watchLater.syncFromCloud()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bookmark")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))

            Text("No Saved Articles")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            Text("Articles you save will appear here")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.5))

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct WatchLaterItemRow: View {
    let item: WatchLaterItem
    @ObservedObject private var watchLater = WatchLaterManager.shared
    // @Environment(\.isFocused) removed for tvOS 26.3 beta
    private let isFocused = false

    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            Image(systemName: item.category.icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: item.category.color))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.articleTitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(item.isCompleted ? .white.opacity(0.5) : .white)
                    .lineLimit(2)
                    .strikethrough(item.isCompleted)

                HStack(spacing: 12) {
                    Text(item.source)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))

                    Text("•")
                        .foregroundColor(.white.opacity(0.4))

                    Text(item.addedDate.formatted(.relative(presentation: .named)))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
                if !item.isCompleted {
                    Button {
                        watchLater.markCompleted(item)
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    watchLater.remove(item)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 24))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isFocused ? Color.cyan.opacity(0.3) : Color.white.opacity(0.1))
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

#Preview {
    WatchLaterListView()
        .preferredColorScheme(.dark)
}
