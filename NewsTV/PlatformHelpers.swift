//
//  PlatformHelpers.swift
//  NewsTV
//
//  Platform-specific helpers for tvOS and iOS (iPad)
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Platform Detection

#if os(tvOS)
private let _isTV = true
private let _isiOS = false
#elseif os(iOS)
private let _isTV = false
private let _isiOS = true
#else
private let _isTV = false
private let _isiOS = false
#endif

// MARK: - Platform Constants

struct PlatformConstants {
    static let isTV: Bool = _isTV
    static let isiOS: Bool = _isiOS

    static var isiPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }

    /// Font size scale factor
    static var fontScale: CGFloat {
        isTV ? 1.5 : 1.0
    }

    /// Padding scale factor
    static var paddingScale: CGFloat {
        isTV ? 2.0 : 1.0
    }

    /// Corner radius for cards
    static var cornerRadius: CGFloat {
        isTV ? 20 : 12
    }

    /// Minimum article card width
    static var minCardWidth: CGFloat {
        isTV ? 400 : (isiPad ? 300 : 160)
    }

    /// Grid spacing
    static var gridSpacing: CGFloat {
        isTV ? 24 : (isiPad ? 16 : 12)
    }

    /// Horizontal padding
    static var horizontalPadding: CGFloat {
        isTV ? 48 : (isiPad ? 24 : 16)
    }
}

// MARK: - Platform-Adaptive Font

extension Font {
    static func platformTitle() -> Font {
        .system(size: PlatformConstants.isTV ? 48 : 28, weight: .bold, design: .rounded)
    }

    static func platformLargeTitle() -> Font {
        .system(size: PlatformConstants.isTV ? 36 : 24, weight: .bold, design: .rounded)
    }

    static func platformHeadline() -> Font {
        .system(size: PlatformConstants.isTV ? 28 : 20, weight: .semibold, design: .rounded)
    }

    static func platformSubheadline() -> Font {
        .system(size: PlatformConstants.isTV ? 24 : 17, weight: .medium)
    }

    static func platformBody() -> Font {
        .system(size: PlatformConstants.isTV ? 22 : 16)
    }

    static func platformCaption() -> Font {
        .system(size: PlatformConstants.isTV ? 18 : 13)
    }

    static func platformFootnote() -> Font {
        .system(size: PlatformConstants.isTV ? 16 : 12)
    }
}

// MARK: - Platform View Modifiers

extension View {
    /// Apply platform-specific padding
    func platformPadding(_ edges: Edge.Set = .all, _ amount: CGFloat = 16) -> some View {
        self.padding(edges, amount * PlatformConstants.paddingScale)
    }

    /// Apply glassmorphic background
    func glassBackground(opacity: Double = 0.1) -> some View {
        self.background(Color.white.opacity(opacity))
            .cornerRadius(PlatformConstants.cornerRadius)
    }

    /// Apply card styling
    func cardStyle() -> some View {
        self
            .background(Color.white.opacity(0.08))
            .cornerRadius(PlatformConstants.cornerRadius)
    }
}

// MARK: - Adaptive Grid Helper

struct AdaptiveGrid {
    /// Calculate optimal number of columns based on available width
    static func columns(for width: CGFloat, minItemWidth: CGFloat? = nil) -> [GridItem] {
        let minWidth = minItemWidth ?? PlatformConstants.minCardWidth
        let spacing = PlatformConstants.gridSpacing
        let availableWidth = width - (PlatformConstants.horizontalPadding * 2)

        let columnCount = max(1, Int(availableWidth / (minWidth + spacing)))

        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
}

// MARK: - Card Button Style (tvOS-compatible)

struct NewsCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == NewsCardButtonStyle {
    static var newsCard: NewsCardButtonStyle { NewsCardButtonStyle() }
}

// MARK: - TV Icon Button Style (for toolbar/action buttons on tvOS)

struct TVIconButtonStyle: ButtonStyle {
    var normalOpacity: Double = 0.7
    var focusedOpacity: Double = 1.0

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.15 : 1.0)
            .opacity(configuration.isPressed ? focusedOpacity : normalOpacity)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == TVIconButtonStyle {
    static var tvIcon: TVIconButtonStyle { TVIconButtonStyle() }
}

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
