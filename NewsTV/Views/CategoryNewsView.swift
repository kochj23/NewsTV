//
//  CategoryNewsView.swift
//  NewsTV
//
//  Grid view of news articles for a category
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct CategoryNewsView: View {
    let category: NewsCategory
    let articles: [NewsArticle]
    @Binding var selectedArticle: NewsArticle?

    @State private var focusedIndex: Int?
    @FocusState private var focusedArticle: Int?

    private let columns = [
        GridItem(.flexible(), spacing: 30),
        GridItem(.flexible(), spacing: 30),
        GridItem(.flexible(), spacing: 30)
    ]

    var body: some View {
        ScrollView {
            if articles.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(0..<articles.count, id: \.self) { index in
                        Button {
                            selectedArticle = articles[index]
                        } label: {
                            ArticleCard(
                                article: articles[index],
                                isFocused: focusedIndex == index
                            )
                        }
                        .buttonStyle(.card)
                        .focused($focusedArticle, equals: index)
                        .onChange(of: focusedArticle) { _, newValue in
                            focusedIndex = newValue
                        }
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 30)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: category.icon)
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.4))

            Text("No \(category.rawValue) articles")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            Text("Pull to refresh or check back later")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(100)
    }
}

// MARK: - Preview

#Preview {
    CategoryNewsView(
        category: .technology,
        articles: [],
        selectedArticle: .constant(nil)
    )
    .background(Color.black)
}
