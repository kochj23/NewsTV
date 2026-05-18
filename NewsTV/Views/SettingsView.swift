//
//  SettingsView.swift
//  NewsTV
//
//  Settings and preferences view
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.12),
                        Color(red: 0.1, green: 0.1, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 40) {
                        // Header
                        headerSection

                        // Settings sections
                        displaySettingsSection
                        personalizationSection
                        localNewsSection
                        weatherSection
                        syncSection
                        audioSettingsSection
                        newsSettingsSection
                        screensaverSection
                        aboutSection
                    }
                    .padding(60)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundColor(.cyan)

            Text("Settings")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    // MARK: - Display Settings

    private var displaySettingsSection: some View {
        settingsCard(title: "Display", icon: "display") {
            // Theme
            settingRow(
                title: "Theme",
                subtitle: settingsManager.settings.theme.rawValue
            ) {
                Picker("", selection: $settingsManager.settings.theme) {
                    ForEach(NewsTVSettings.AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }

            Divider().background(Color.white.opacity(0.2))

            // Font size
            settingRow(
                title: "Font Size",
                subtitle: settingsManager.settings.fontSize.rawValue
            ) {
                Picker("", selection: $settingsManager.settings.fontSize) {
                    ForEach(NewsTVSettings.FontSize.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 400)
            }

            Divider().background(Color.white.opacity(0.2))

            // Rotation interval
            settingRow(
                title: "Auto-Rotate Interval",
                subtitle: "\(Int(settingsManager.settings.rotationInterval)) seconds"
            ) {
                Picker("", selection: $settingsManager.settings.rotationInterval) {
                    Text("5s").tag(5.0 as TimeInterval)
                    Text("10s").tag(10.0 as TimeInterval)
                    Text("15s").tag(15.0 as TimeInterval)
                    Text("30s").tag(30.0 as TimeInterval)
                    Text("60s").tag(60.0 as TimeInterval)
                }
                .pickerStyle(.segmented)
                .frame(width: 350)
            }

            Divider().background(Color.white.opacity(0.2))

            // Sentiment colors
            settingToggle(
                title: "Show Sentiment Colors",
                subtitle: "Color-code articles by sentiment",
                isOn: $settingsManager.settings.enableSentimentColors
            )

            Divider().background(Color.white.opacity(0.2))

            // Bias indicators
            settingToggle(
                title: "Show Bias Indicators",
                subtitle: "Display source bias badges",
                isOn: $settingsManager.settings.enableBiasIndicators
            )

            Divider().background(Color.white.opacity(0.2))

            // Trending ticker
            settingToggle(
                title: "Trending Topics Ticker",
                subtitle: "Show scrolling trending topics bar",
                isOn: $settingsManager.settings.enableTrendingTicker
            )
        }
    }

    // MARK: - Personalization Section

    private var personalizationSection: some View {
        settingsCard(title: "Personalization", icon: "sparkles") {
            // Personalized feed
            settingToggle(
                title: "Personalized Feed",
                subtitle: "Learn from your reading habits",
                isOn: $settingsManager.settings.enablePersonalizedFeed
            )

            Divider().background(Color.white.opacity(0.2))

            // Reset profile
            Button {
                PersonalizationEngine.shared.resetProfile()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Learning Profile")
                }
                .foregroundColor(.orange)
            }
            .font(.system(size: 18))
        }
    }

    // MARK: - Local News Section

    private var localNewsSection: some View {
        settingsCard(title: "Local News", icon: "location.fill") {
            // Current location
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Text(settingsManager.settings.localNewsLocation ?? settingsManager.settings.localNewsZipCode ?? "Not set")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                NavigationLink {
                    LocationPickerView()
                } label: {
                    Text("Change")
                        .foregroundColor(.cyan)
                }
            }
        }
    }

    // MARK: - Weather Section

    private var weatherSection: some View {
        settingsCard(title: "Weather", icon: "cloud.sun.fill") {
            // Enable weather widget
            settingToggle(
                title: "Show Weather Widget",
                subtitle: "Display weather in top bar",
                isOn: $settingsManager.settings.enableWeatherWidget
            )

            Divider().background(Color.white.opacity(0.2))

            // Temperature unit
            settingRow(
                title: "Temperature Unit",
                subtitle: settingsManager.settings.temperatureUnit.rawValue
            ) {
                Picker("", selection: $settingsManager.settings.temperatureUnit) {
                    ForEach(NewsTVSettings.TemperatureUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
            }
        }
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        settingsCard(title: "Sync & Refresh", icon: "arrow.triangle.2.circlepath") {
            // iCloud sync
            settingToggle(
                title: "iCloud Sync",
                subtitle: "Sync Watch Later and preferences across devices",
                isOn: $settingsManager.settings.enableiCloudSync
            )

            Divider().background(Color.white.opacity(0.2))

            // Background refresh
            settingToggle(
                title: "Background Refresh",
                subtitle: "Auto-refresh news while idle",
                isOn: $settingsManager.settings.enableBackgroundRefresh
            )

            Divider().background(Color.white.opacity(0.2))

            // Refresh interval
            settingRow(
                title: "Refresh Interval",
                subtitle: "\(Int(settingsManager.settings.backgroundRefreshInterval / 60)) minutes"
            ) {
                Picker("", selection: $settingsManager.settings.backgroundRefreshInterval) {
                    Text("5 min").tag(300.0 as TimeInterval)
                    Text("10 min").tag(600.0 as TimeInterval)
                    Text("15 min").tag(900.0 as TimeInterval)
                    Text("30 min").tag(1800.0 as TimeInterval)
                }
                .pickerStyle(.segmented)
                .frame(width: 350)
            }

            Divider().background(Color.white.opacity(0.2))

            // Manual sync
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync Now")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Force sync with iCloud")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Button {
                    Task {
                        await CloudSyncManager.shared.syncSettings()
                        await WatchLaterManager.shared.syncFromCloud()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Sync")
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }

    // MARK: - Screensaver Section

    private var screensaverSection: some View {
        settingsCard(title: "Screensaver", icon: "moon.stars.fill") {
            // Enable screensaver
            settingToggle(
                title: "Screensaver Mode",
                subtitle: "Show beautiful headlines when idle",
                isOn: $settingsManager.settings.enableScreensaverMode
            )

            Divider().background(Color.white.opacity(0.2))

            // Idle time
            settingRow(
                title: "Idle Time Before Screensaver",
                subtitle: "\(Int(settingsManager.settings.screensaverIdleTime / 60)) minutes"
            ) {
                Picker("", selection: $settingsManager.settings.screensaverIdleTime) {
                    Text("2 min").tag(120.0 as TimeInterval)
                    Text("5 min").tag(300.0 as TimeInterval)
                    Text("10 min").tag(600.0 as TimeInterval)
                    Text("15 min").tag(900.0 as TimeInterval)
                }
                .pickerStyle(.segmented)
                .frame(width: 350)
            }

            Divider().background(Color.white.opacity(0.2))

            // Ambient mode (legacy)
            settingToggle(
                title: "Ambient Mode",
                subtitle: "Alternative relaxed display mode",
                isOn: $settingsManager.settings.ambientModeEnabled
            )
        }
    }

    // MARK: - Audio Settings

    private var audioSettingsSection: some View {
        settingsCard(title: "Audio", icon: "speaker.wave.2") {
            // Enable audio briefings
            settingToggle(
                title: "Audio Briefings",
                subtitle: "Enable text-to-speech news reading",
                isOn: $settingsManager.settings.enableAudioBriefings
            )

            Divider().background(Color.white.opacity(0.2))

            // Speech rate
            settingRow(
                title: "Speech Rate",
                subtitle: speechRateLabel
            ) {
                Picker("", selection: $settingsManager.settings.speechRate) {
                    Text("Slow").tag(0.35 as Float)
                    Text("Normal").tag(0.5 as Float)
                    Text("Fast").tag(0.65 as Float)
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
        }
    }

    private var speechRateLabel: String {
        switch settingsManager.settings.speechRate {
        case ..<0.4: return "Slow"
        case 0.4..<0.55: return "Normal"
        default: return "Fast"
        }
    }

    // MARK: - News Settings

    private var newsSettingsSection: some View {
        settingsCard(title: "News", icon: "newspaper") {
            // Breaking news alerts
            settingToggle(
                title: "Breaking News Alerts",
                subtitle: "Show breaking news banner",
                isOn: $settingsManager.settings.enableBreakingNewsAlerts
            )

            Divider().background(Color.white.opacity(0.2))

            // Keyword alerts count
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keyword Alerts")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(settingsManager.settings.keywordAlerts.count) keywords configured")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                NavigationLink {
                    KeywordAlertsView()
                } label: {
                    Text("Manage")
                        .foregroundColor(.cyan)
                }
            }

            Divider().background(Color.white.opacity(0.2))

            // Custom feeds count
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom RSS Feeds")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(settingsManager.settings.customFeeds.count) feeds configured")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                NavigationLink {
                    CustomFeedsView()
                } label: {
                    Text("Manage")
                        .foregroundColor(.cyan)
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        settingsCard(title: "About", icon: "info.circle") {
            VStack(spacing: 16) {
                HStack {
                    Text("Version")
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("2.0.0")
                        .foregroundColor(.white)
                }

                Divider().background(Color.white.opacity(0.2))

                HStack {
                    Text("Developer")
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("Jordan Koch")
                        .foregroundColor(.white)
                }

                Divider().background(Color.white.opacity(0.2))

                HStack {
                    Text("Features")
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("14 new features")
                        .foregroundColor(.cyan)
                }

                Divider().background(Color.white.opacity(0.2))

                HStack {
                    Text("ML Frameworks")
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("NaturalLanguage, Vision, Core ML")
                        .foregroundColor(.cyan)
                }

                Divider().background(Color.white.opacity(0.2))

                Button {
                    settingsManager.resetToDefaults()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Defaults")
                    }
                    .foregroundColor(.orange)
                }
            }
            .font(.system(size: 18))
        }
    }

    // MARK: - Helpers

    private func settingsCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 20) {
                content()
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .cornerRadius(20)
    }

    private func settingRow<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            control()
        }
    }

    private func settingToggle(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .tint(.cyan)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
