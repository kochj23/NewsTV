//
//  KeywordAlertsView.swift
//  NewsTV
//
//  Manage keyword alerts for specific topics
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct KeywordAlertsView: View {
    @ObservedObject private var alertManager = KeywordAlertManager.shared
    @ObservedObject private var settings = SettingsManager.shared
    @State private var newKeyword = ""
    @State private var selectedKeyword: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header

            HStack(spacing: 0) {
                // Keyword list
                keywordList
                    .frame(width: 400)

                Divider()
                    .background(Color.white.opacity(0.2))

                // Matched articles
                if let keyword = selectedKeyword {
                    matchedArticlesView(for: keyword)
                } else {
                    placeholderView
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.yellow)

                    Text("Keyword Alerts")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Get notified when specific topics appear")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if alertManager.hasNewMatches {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    Text("New matches!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                }
                .onTapGesture {
                    alertManager.clearNewMatchesFlag()
                }
            }
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
        .background(Color.black.opacity(0.3))
    }

    private var keywordList: some View {
        VStack(spacing: 16) {
            // Add new keyword
            HStack(spacing: 12) {
                TextField("New keyword...", text: $newKeyword)
                    .font(.system(size: 18))
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)

                Button {
                    if !newKeyword.isEmpty {
                        alertManager.addAlert(keyword: newKeyword)
                        newKeyword = ""
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.yellow)
                }
                .buttonStyle(.plain)
                .disabled(newKeyword.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Keywords
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(settings.settings.keywordAlerts) { alert in
                        Button {
                            selectedKeyword = alert.keyword
                        } label: {
                            KeywordAlertRow(
                                alert: alert,
                                isSelected: selectedKeyword == alert.keyword,
                                matchCount: alertManager.articles(for: alert.keyword).count
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Suggested keywords
            if settings.settings.keywordAlerts.isEmpty {
                suggestedKeywords
            }
        }
    }

    private var suggestedKeywords: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Keywords")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            let suggestions = ["Apple", "Tesla", "AI", "Climate", "Elections", "Entertainment", "SpaceX", "Bitcoin"]

            FlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { keyword in
                    Button {
                        alertManager.addAlert(keyword: keyword)
                    } label: {
                        Text(keyword)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
    }

    private func matchedArticlesView(for keyword: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Articles matching \"\(keyword)\"")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    alertManager.clearMatches(for: keyword)
                } label: {
                    Text("Clear")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            let articles = alertManager.articles(for: keyword)

            if articles.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                    Text("No matches yet")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                    Text("We'll notify you when articles match")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(articles) { article in
                            CompactArticleRow(article: article, highlightKeyword: keyword)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "hand.tap")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            Text("Select a keyword to see matches")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct KeywordAlertRow: View {
    let alert: KeywordAlert
    let isSelected: Bool
    let matchCount: Int
    @ObservedObject private var alertManager = KeywordAlertManager.shared
    // @Environment(\.isFocused) removed for tvOS 26.3 beta
    private let isFocused = false

    var body: some View {
        HStack(spacing: 12) {
            // Enable toggle
            Button {
                alertManager.toggleAlert(id: alert.id, enabled: !alert.isEnabled)
            } label: {
                Image(systemName: alert.isEnabled ? "bell.fill" : "bell.slash")
                    .font(.system(size: 20))
                    .foregroundColor(alert.isEnabled ? .yellow : .gray)
            }
            .buttonStyle(.plain)

            // Keyword
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.keyword)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(alert.isEnabled ? .white : .white.opacity(0.5))

                if let lastMatch = alert.lastMatchDate {
                    Text("Last match: \(lastMatch.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            // Match count badge
            if matchCount > 0 {
                Text("\(matchCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .cornerRadius(12)
            }

            // Delete button
            Button {
                alertManager.removeAlert(id: alert.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected || isFocused ? Color.yellow.opacity(0.2) : Color.white.opacity(0.05))
        )
    }
}

struct CompactArticleRow: View {
    let article: NewsArticle
    let highlightKeyword: String
    // @Environment(\.isFocused) removed for tvOS 26.3 beta
    private let isFocused = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: article.category.icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: article.category.color))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(highlightedTitle)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack {
                    Text(article.source.name)
                    Text("•")
                    Text(article.timeAgoString)
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isFocused ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
        )
    }

    private var highlightedTitle: AttributedString {
        var title = AttributedString(article.title)
        if let range = title.range(of: highlightKeyword, options: .caseInsensitive) {
            title[range].foregroundColor = .yellow
            title[range].font = .system(size: 18, weight: .bold)
        }
        return title
    }
}

// Simple flow layout for suggested keywords
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, proposal: proposal).offsets

        for (subview, offset) in zip(subviews, offsets) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (size: CGSize, offsets: [CGPoint]) {
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for size in sizes {
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), offsets)
    }
}

#Preview {
    KeywordAlertsView()
        .preferredColorScheme(.dark)
}
