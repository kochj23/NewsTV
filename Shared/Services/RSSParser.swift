//
//  RSSParser.swift
//  NewsTV
//
//  RSS feed parser for news sources
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

class RSSParser: @unchecked Sendable {
    static let shared = RSSParser()

    private let session: URLSession

    private init() {
        // Configure URL session with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15  // 15 second timeout per request
        config.timeoutIntervalForResource = 30 // 30 second total timeout
        self.session = URLSession(configuration: config)
    }

    // MARK: - Parse Feed

    func parseFeed(from source: NewsSource) async throws -> [NewsArticle] {
        let (data, _) = try await session.data(from: source.rssURL)

        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw RSSError.invalidData
        }

        return parseXML(xmlString, source: source)
    }

    // MARK: - XML Parsing

    private func parseXML(_ xml: String, source: NewsSource) -> [NewsArticle] {
        var articles: [NewsArticle] = []

        // Extract items
        let itemPattern = #"<item>(.*?)</item>"#
        let itemRegex = try? NSRegularExpression(pattern: itemPattern, options: [.dotMatchesLineSeparators])
        let itemMatches = itemRegex?.matches(in: xml, range: NSRange(xml.startIndex..., in: xml)) ?? []

        for match in itemMatches {
            guard let itemRange = Range(match.range(at: 1), in: xml) else { continue }
            let itemXML = String(xml[itemRange])

            if let article = parseItem(itemXML, source: source) {
                articles.append(article)
            }
        }

        return articles
    }

    private func parseItem(_ itemXML: String, source: NewsSource) -> NewsArticle? {
        let title = extractTag("title", from: itemXML)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let link = extractTag("link", from: itemXML)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = extractTag("description", from: itemXML)
        let pubDateString = extractTag("pubDate", from: itemXML)
        let mediaContent = extractAttribute("url", fromTag: "media:content", in: itemXML)
            ?? extractAttribute("url", fromTag: "enclosure", in: itemXML)
            ?? extractImageFromDescription(description)

        guard let title = title, !title.isEmpty,
              let link = link, let url = URL(string: link) else {
            return nil
        }

        let pubDate = parseDate(pubDateString) ?? Date()
        let imageURL = mediaContent.flatMap { URL(string: $0) }

        // Clean description
        let cleanDescription = description?
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for breaking news indicators
        let isBreaking = title.lowercased().contains("breaking") ||
                         title.lowercased().contains("just in") ||
                         title.lowercased().contains("developing")

        return NewsArticle(
            title: title,
            source: source,
            url: url,
            publishedDate: pubDate,
            category: source.category,
            rssDescription: cleanDescription,
            imageURL: imageURL,
            isBreakingNews: isBreaking,
            importance: isBreaking ? 9 : 5
        )
    }

    // MARK: - Helpers

    private func extractTag(_ tag: String, from xml: String) -> String? {
        // Try CDATA first
        let cdataPattern = "<\(tag)>\\s*<!\\[CDATA\\[(.+?)\\]\\]>\\s*</\(tag)>"
        if let match = xml.range(of: cdataPattern, options: .regularExpression) {
            let content = String(xml[match])
            let cleanPattern = "<\(tag)>\\s*<!\\[CDATA\\[|\\]\\]>\\s*</\(tag)>"
            return content.replacingOccurrences(of: cleanPattern, with: "", options: .regularExpression)
        }

        // Regular tag
        let pattern = "<\(tag)>(.+?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
              let range = Range(match.range(at: 1), in: xml) else {
            return nil
        }

        return String(xml[range])
    }

    private func extractAttribute(_ attr: String, fromTag tag: String, in xml: String) -> String? {
        let pattern = "<\(tag)[^>]*\(attr)=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
              let range = Range(match.range(at: 1), in: xml) else {
            return nil
        }

        return String(xml[range])
    }

    private func extractImageFromDescription(_ description: String?) -> String? {
        guard let description = description else { return nil }

        let pattern = #"<img[^>]+src=\"([^\"]+)\""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: description, range: NSRange(description.startIndex..., in: description)),
              let range = Range(match.range(at: 1), in: description) else {
            return nil
        }

        return String(description[range])
    }

    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }

        let formatters: [DateFormatter] = [
            createFormatter("EEE, dd MMM yyyy HH:mm:ss Z"),
            createFormatter("yyyy-MM-dd'T'HH:mm:ssZ"),
            createFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSZ"),
            createFormatter("EEE, dd MMM yyyy HH:mm:ss zzz"),
        ]

        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    private func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}

// MARK: - RSS Error

enum RSSError: Error {
    case invalidData
    case parsingFailed
    case networkError(Error)

    var localizedDescription: String {
        switch self {
        case .invalidData:
            return "Invalid RSS data received"
        case .parsingFailed:
            return "Failed to parse RSS feed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
