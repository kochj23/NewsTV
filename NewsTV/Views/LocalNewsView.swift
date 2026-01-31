//
//  LocalNewsView.swift
//  NewsTV
//
//  Local news based on ZIP code or city
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct LocalNewsView: View {
    @ObservedObject private var localNews = LocalNewsService.shared
    @ObservedObject private var settings = SettingsManager.shared
    @State private var selectedArticle: NewsArticle?
    @State private var showLocationPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header

            if localNews.currentLocation == nil {
                setupPrompt
            } else if localNews.isLoading {
                loadingView
            } else if localNews.localArticles.isEmpty {
                emptyState
            } else {
                articlesList
            }
        }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView()
        }
        .onAppear {
            if localNews.currentLocation != nil {
                Task {
                    await localNews.fetchLocalNews()
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.orange)

                    Text("Local News")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }

                if let location = localNews.currentLocation {
                    Text("News for \(location)")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            Button {
                showLocationPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(localNews.currentLocation ?? "Set Location")
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.3))
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
        .background(Color.black.opacity(0.3))
    }

    private var setupPrompt: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.circle")
                .font(.system(size: 80))
                .foregroundColor(.orange.opacity(0.5))

            Text("Set Your Location")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Enter your ZIP code or city to see local news")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.6))

            Button {
                showLocationPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Location")
                }
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.orange)
                .cornerRadius(25)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading local news...")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "newspaper")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))

            Text("No Local News Found")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            Text("Try a different location")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.5))

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var articlesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(localNews.localArticles) { article in
                    Button {
                        selectedArticle = article
                    } label: {
                        ArticleCard(article: article, isFocused: false)
                    }
                    .buttonStyle(.card)
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Location Picker

struct LocationPickerView: View {
    @ObservedObject private var localNews = LocalNewsService.shared
    @State private var zipCode = ""
    @State private var selectedCity: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // ZIP Code entry
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter ZIP Code")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    TextField("ZIP Code", text: $zipCode)
                        .font(.system(size: 24))
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .frame(maxWidth: 200)

                    Button {
                        if !zipCode.isEmpty {
                            localNews.setLocation(zipCode: zipCode)
                            dismiss()
                        }
                    } label: {
                        Text("Use ZIP Code")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                    .disabled(zipCode.isEmpty)
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Popular cities
                VStack(alignment: .leading, spacing: 16) {
                    Text("Or Select a City")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(LocalNewsService.popularCities, id: \.self) { city in
                            Button {
                                localNews.setLocation(city: city)
                                dismiss()
                            } label: {
                                Text(city)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()

                // Clear location button
                if localNews.currentLocation != nil {
                    Button {
                        localNews.clearLocation()
                        dismiss()
                    } label: {
                        Text("Clear Location")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(40)
            .navigationTitle("Set Location")
        }
    }
}

#Preview {
    LocalNewsView()
        .preferredColorScheme(.dark)
}
