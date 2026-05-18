//
//  LocalNewsService.swift
//  NewsTV
//
//  Provides location-based local news using ZIP code or city
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import CoreLocation

@MainActor
class LocalNewsService: ObservableObject {
    static let shared = LocalNewsService()

    @Published var localArticles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var currentLocation: String?

    private let parser = RSSParser.shared
    private let geocoder = CLGeocoder()

    private init() {}

    // MARK: - Fetch Local News

    func fetchLocalNews() async {
        let settings = SettingsManager.shared.settings

        // Determine location query
        var locationQuery: String?

        if let zipCode = settings.localNewsZipCode, !zipCode.isEmpty {
            locationQuery = zipCode
            currentLocation = zipCode
        } else if let location = settings.localNewsLocation, !location.isEmpty {
            locationQuery = location
            currentLocation = location
        }

        guard let query = locationQuery else {
            localArticles = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Create Google News RSS URL for local news
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://news.google.com/rss/search?q=\(encodedQuery)+local+news&hl=en-US&gl=US&ceid=US:en"

        guard let url = URL(string: urlString) else {
            return
        }

        let source = NewsSource(
            id: "local-news",
            name: "Local News",
            rssURL: url,
            category: .us,
            bias: .center,
            reliability: 0.8
        )

        do {
            var articles = try await parser.parseFeed(from: source)

            // Re-categorize as local (we'll add a local category)
            articles = articles.map { article in
                var updated = article
                // Keep as US category but mark in summary
                if updated.summary == nil {
                    updated.summary = "Local news for \(query)"
                }
                return updated
            }

            localArticles = articles
        } catch {
            print("Failed to fetch local news: \(error)")
            localArticles = []
        }
    }

    // MARK: - Location Helpers

    func cityName(for zipCode: String) async -> String? {
        return await withCheckedContinuation { continuation in
            geocoder.geocodeAddressString(zipCode) { placemarks, error in
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? placemark.administrativeArea ?? zipCode
                    continuation.resume(returning: city)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func setLocation(city: String) {
        SettingsManager.shared.settings.localNewsLocation = city
        SettingsManager.shared.settings.localNewsZipCode = nil
        currentLocation = city
        Task { await fetchLocalNews() }
    }

    func setLocation(zipCode: String) {
        SettingsManager.shared.settings.localNewsZipCode = zipCode
        SettingsManager.shared.settings.localNewsLocation = nil
        currentLocation = zipCode
        Task { await fetchLocalNews() }
    }

    func clearLocation() {
        SettingsManager.shared.settings.localNewsLocation = nil
        SettingsManager.shared.settings.localNewsZipCode = nil
        currentLocation = nil
        localArticles = []
    }

    // MARK: - Suggested Locations

    static let popularCities = [
        "New York, NY",
        "Los Angeles, CA",
        "Chicago, IL",
        "Houston, TX",
        "Phoenix, AZ",
        "Philadelphia, PA",
        "San Antonio, TX",
        "San Diego, CA",
        "Dallas, TX",
        "San Jose, CA",
        "Austin, TX",
        "Jacksonville, FL",
        "Fort Worth, TX",
        "Columbus, OH",
        "Charlotte, NC",
        "San Francisco, CA",
        "Indianapolis, IN",
        "Seattle, WA",
        "Denver, CO",
        "Washington, DC"
    ]
}
