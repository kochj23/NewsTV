# NewsTV - AI-Powered News for Apple TV

![Build](https://github.com/kochj23/NewsTV/actions/workflows/build.yml/badge.svg)

**On-Device Machine Learning News Reader with Sentiment Analysis, Multi-Source Comparison, and Smart Personalization**

![Platform](https://img.shields.io/badge/platform-tvOS%2017.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-2.0.0-success)
![ML](https://img.shields.io/badge/ML-NaturalLanguage%20%7C%20Vision%20%7C%20Core%20ML-purple)

---

## Overview

NewsTV brings AI-powered news analysis to your Apple TV. Using Apple's on-device machine learning frameworks (NaturalLanguage, Vision, Core ML), it provides real-time sentiment analysis, named entity recognition, multi-source story comparison, and intelligent text-to-speech briefings - all without requiring cloud services.

Built as a companion to the macOS News Summary app, NewsTV is optimized for the lean-back, 10-foot viewing experience of your living room.

---

## What's New in v2.0

### Major New Features

| Feature | Description |
|---------|-------------|
| **Watch Later Queue** | Bookmark articles for later with iCloud sync across devices |
| **Personalized "For You" Feed** | AI learns your reading habits to surface relevant stories |
| **Multi-Source Story View** | Compare how different sources cover the same story with bias analysis |
| **Local News** | Enter your ZIP code or city to see local news |
| **Keyword Alerts** | Get notified when specific topics appear in the news |
| **Custom RSS Feeds** | Add your own RSS feeds to the app |
| **Weather Widget** | Current weather conditions in your location |
| **Trending Topics Bar** | See what's trending across all news sources |
| **Screensaver Mode** | Beautiful rotating headlines when idle |
| **Content Filter** | Automatically removes advertisements and sponsored content |
| **Background Auto-Refresh** | News updates automatically in the background |
| **iCloud Sync** | Settings and reading progress sync across Apple TVs |

---

## Features

### On-Device Machine Learning

| Feature | Framework | Description |
|---------|-----------|-------------|
| **Sentiment Analysis** | NaturalLanguage | Color-coded sentiment indicators for headlines |
| **Named Entity Recognition** | NaturalLanguage | Automatically identifies people, organizations, locations |
| **Topic Extraction** | NaturalLanguage | Identifies trending topics across feeds |
| **Story Clustering** | NaturalLanguage | Groups related articles from different sources |
| **Personalization Engine** | Core ML | Learns your preferences over time |
| **Image Classification** | Vision | Analyzes news article images |
| **Face Detection** | Vision | Detects faces in news photos |
| **Text Recognition** | Vision | OCR for text in images |

### TV-Optimized Features

- **For You Personalized Feed** - AI-curated articles based on your viewing habits
- **Watch Later Queue** - Save articles to read later, synced via iCloud
- **Multi-Source Comparison** - See how different outlets cover the same story
- **Local News** - News from your city or ZIP code
- **Audio Briefings** - Text-to-Speech news reading with play/pause/skip controls
- **Breaking News Alerts** - Full-screen banners for major news
- **Source Bias Indicators** - Visual badges showing Left/Center/Right bias
- **Trending Ticker** - Scrolling bar of trending topics
- **Weather Widget** - Current conditions at a glance
- **Screensaver Mode** - Elegant headline rotation when idle
- **Siri Remote Optimized** - Focus-based navigation with card-style buttons
- **Large Typography** - Configurable font sizes for comfortable viewing

### Smart Features

- **Content Filtering** - Automatically removes ads, sponsored content, and clickbait
- **Keyword Alerts** - Monitor for specific topics (e.g., "Apple", "Tesla", "AI")
- **Custom Feeds** - Add any RSS feed to your news mix
- **Background Refresh** - News updates automatically, even when not watching
- **iCloud Sync** - Settings, watch later list, and reading progress sync across devices

### News Analysis

- **Sentiment Coloring** - Headlines color-coded by positive/negative/neutral sentiment
- **Entity Extraction** - See who and what is mentioned in each article
- **Perspective Analysis** - Compare left, center, and right coverage of stories
- **Shared Facts** - See what facts all sources agree on
- **Points of Contention** - See where sources disagree
- **Source Reliability** - Reliability scores for news sources
- **Bias Spectrum** - Visual indicator showing political leaning

---

## What It Can Do

**News Aggregation**
- Aggregate news from 25+ RSS sources across 11 categories
- Add unlimited custom RSS feeds
- Filter out advertisements and sponsored content
- Cluster related stories from multiple sources

**AI Analysis**
- Analyze sentiment of headlines using on-device NLP
- Extract entities (people, organizations, places) from articles
- Identify trending topics across all feeds
- Learn your preferences to personalize your feed
- Compare coverage across political spectrum

**User Experience**
- Read articles aloud with built-in text-to-speech
- Show breaking news with prominent alerts
- Display local news for your area
- Beautiful screensaver mode with rotating headlines
- Weather widget showing current conditions

**Sync & Personalization**
- iCloud sync of watch later queue
- Sync settings across multiple Apple TVs
- Track reading progress across devices
- Keyword alerts for topics you care about

**Privacy & Offline**
- Work offline - all ML processing happens on-device
- Protect privacy - no data sent to cloud services

---

## What It Cannot Do

- **Display full web pages** - tvOS doesn't support WebKit
- **Show article images inline** - displays category icons instead
- **Provide AI summaries** - requires cloud AI (see macOS News Summary)
- **Fact-check claims** - requires cloud AI
- **Deep article scraping** - limited to RSS descriptions

---

## Installation

### From Xcode

1. Clone the repository:
   ```bash
   git clone https://github.com/kochj23/NewsTV.git
   cd NewsTV
   ```

2. Open in Xcode:
   ```bash
   open NewsTV.xcodeproj
   ```

3. Select your Apple TV as the destination
4. Build and run (Cmd+R)

### From Command Line

```bash
# Build for tvOS device
xcodebuild -project NewsTV.xcodeproj \
  -scheme NewsTV \
  -sdk appletvos \
  -configuration Release \
  SYMROOT=build build

# Install on Apple TV (replace DEVICE_ID with your device)
xcrun devicectl device install app \
  --device DEVICE_ID \
  build/Release-appletvos/NewsTV.app

# Launch
xcrun devicectl device process launch \
  --device DEVICE_ID \
  com.jordankoch.NewsTV
```

---

## Using NewsTV

### Main Navigation

| Tab | Description |
|-----|-------------|
| **Home** | All categories with weather and trending topics |
| **For You** | Personalized feed based on your reading habits |
| **Watch Later** | Saved articles queue |
| **Local** | News from your ZIP code or city |
| **Alerts** | Keyword alert management and matches |
| **Feeds** | Custom RSS feed management |
| **Settings** | App preferences and sync options |

### Remote Controls

- **Swipe Left/Right** - Change categories/tabs
- **Swipe Up/Down** - Browse articles
- **Select (Press)** - Open article detail
- **Play/Pause** - Start/stop audio briefing
- **Menu** - Go back / Close

### Watch Later

1. Navigate to any article
2. Press the bookmark button (or long-press on article card)
3. Article is saved to Watch Later queue
4. Access saved articles from Watch Later tab
5. Syncs automatically via iCloud

### Multi-Source Stories

1. Stories covered by multiple sources show a "Multi-Source" badge
2. Select to see all coverage
3. Compare left, center, and right perspectives
4. See shared facts and points of contention
5. Navigate between sources to read each take

### Keyword Alerts

1. Go to Alerts tab
2. Add keywords you want to track (e.g., "Apple", "Tesla")
3. The app monitors all feeds for matches
4. New matches are highlighted
5. Tap a keyword to see all matching articles

### Local News

1. Go to Local tab
2. Enter your ZIP code or select a city
3. News from local sources will appear
4. Location is saved for future sessions

### Custom Feeds

1. Go to Feeds tab
2. Tap "Add Feed"
3. Enter feed name and RSS URL
4. Select a category
5. Feed articles appear in your news mix

### Settings

| Section | Options |
|---------|---------|
| **Display** | Font size, theme, sentiment colors, bias indicators |
| **Audio** | Speech rate, auto-play briefings |
| **Personalization** | Enable/disable AI personalization |
| **Local News** | Set location (ZIP or city) |
| **Weather** | Enable/disable weather widget |
| **Sync** | iCloud sync for watch later and settings |
| **Content** | Filter ads, filter clickbait, sources to exclude |
| **Screensaver** | Auto-enable, timing, style |
| **Refresh** | Background refresh interval |

---

## Architecture

```
NewsTV/
├── Shared/
│   ├── Models/
│   │   └── NewsModels.swift           # Core data models
│   └── Services/
│       ├── RSSParser.swift            # RSS feed parsing
│       └── NewsAggregator.swift       # News aggregation
│
└── NewsTV/
    ├── ML/
    │   ├── SentimentAnalyzer.swift    # NaturalLanguage sentiment
    │   ├── EntityExtractor.swift      # NaturalLanguage NER
    │   └── ImageAnalyzer.swift        # Vision framework
    │
    ├── Services/
    │   ├── TTSManager.swift           # Text-to-Speech
    │   ├── SettingsManager.swift      # User preferences
    │   ├── WatchLaterManager.swift    # Watch later queue + iCloud
    │   ├── PersonalizationEngine.swift # AI personalization
    │   ├── StoryClusterEngine.swift   # Multi-source grouping
    │   ├── LocalNewsService.swift     # Local news by location
    │   ├── KeywordAlertManager.swift  # Keyword monitoring
    │   ├── TrendingTopicsEngine.swift # Trending analysis
    │   ├── WeatherService.swift       # WeatherKit integration
    │   ├── CustomFeedManager.swift    # Custom RSS feeds
    │   ├── ContentFilter.swift        # Ad/spam filtering
    │   ├── CloudSyncManager.swift     # iCloud sync
    │   ├── BackgroundRefreshManager.swift # Auto-refresh
    │   ├── ScreensaverManager.swift   # Screensaver mode
    │   └── SiriIntentsManager.swift   # Siri shortcuts
    │
    └── Views/
        ├── TVContentView.swift        # Main tab view
        ├── CategoryNewsView.swift     # Category browser
        ├── ArticleDetailView.swift    # Article detail
        ├── AudioBriefingView.swift    # Audio player
        ├── ForYouView.swift           # Personalized feed
        ├── StoryClusterView.swift     # Multi-source comparison
        ├── LocalNewsView.swift        # Local news
        ├── KeywordAlertsView.swift    # Keyword alerts
        ├── CustomFeedsView.swift      # Custom feeds
        ├── ScreensaverView.swift      # Screensaver
        ├── SettingsView.swift         # Settings
        └── Components/
            ├── ArticleCard.swift      # Article card
            ├── WeatherWidget.swift    # Weather display
            ├── TrendingTicker.swift   # Trending topics bar
            ├── WatchLaterButton.swift # Bookmark button
            ├── AmbientModeView.swift  # Legacy screensaver
            └── BreakingNewsBanner.swift
```

---

## News Sources

### Default Sources (25+)

| Category | Sources |
|----------|---------|
| **Top Stories** | Associated Press, Reuters, NPR |
| **US** | NY Times, WSJ |
| **World** | BBC, The Guardian |
| **Technology** | TechCrunch, Ars Technica, The Verge |
| **Business** | CNBC, Bloomberg |
| **Science** | Science Daily, Nature |
| **Health** | Medical News Today |
| **Sports** | ESPN |
| **Entertainment** | Variety |
| **Politics** | Politico, The Hill |

### Custom Feeds

Add any RSS feed from:
- News websites
- Blogs
- Podcasts
- YouTube channels (via RSS)
- Reddit subreddits (via RSS)

---

## ML Frameworks Used

### NaturalLanguage Framework
- **Sentiment Analysis** - `NLTagger` with `.sentimentScore` scheme
- **Named Entity Recognition** - `NLTagger` with `.nameType` scheme
- **Topic Extraction** - `NLTagger` with `.lexicalClass` scheme
- **Story Clustering** - Cosine similarity on extracted topics
- Detects: People, Organizations, Places, Topics

### Vision Framework
- **Image Classification** - `VNClassifyImageRequest`
- **Face Detection** - `VNDetectFaceRectanglesRequest`
- **Text Recognition** - `VNRecognizeTextRequest`
- **Color Analysis** - Custom pixel sampling

### AVFoundation
- **Text-to-Speech** - `AVSpeechSynthesizer`
- Background audio playback support

### CloudKit
- **iCloud Sync** - Settings, watch later queue, reading progress
- Private database for user data

### WeatherKit
- **Current Conditions** - Temperature, conditions, humidity
- Location-based weather data

---

## Requirements

- **tvOS 17.0** or later
- **Apple TV 4K** (2nd generation or later recommended)
- **Xcode 15.0** or later (for building)
- **iCloud account** (optional, for sync features)
- **Location Services** (optional, for local news and weather)

---

## Security

NewsTV follows secure coding practices:

- **Safe type casting** - All background task handlers use guard-let safe casting instead of force casts, preventing potential runtime crashes from unexpected task types
- **JavaScript disabled** - No web content execution (tvOS limitation, but also a security benefit)
- **No external dependencies** - Uses only Apple first-party frameworks
- **Input validation** - RSS feed parsing validates all input data
- **No credential storage** - No API keys, tokens, or passwords required

---

## Privacy

NewsTV respects your privacy:

- **No cloud AI** - All ML processing happens on your Apple TV
- **No analytics** - No usage tracking or telemetry
- **No accounts** - No sign-in required (iCloud optional)
- **No data collection** - News is fetched directly from RSS feeds
- **iCloud sync is optional** - Works fully offline
- **Open source** - Full source code available for inspection

---

## Known Limitations

1. **No web content** - tvOS doesn't support WebKit, so full articles cannot be displayed
2. **RSS descriptions only** - Article content limited to RSS feed descriptions
3. **No images** - Article images not displayed (category icons shown instead)
4. **No cloud AI** - Advanced features like summarization require cloud APIs
5. **No push notifications** - tvOS doesn't support user notifications

---

## Version History

### v2.0.0 (January 2026)
- Added Watch Later queue with iCloud sync
- Added personalized "For You" feed
- Added multi-source story comparison with bias analysis
- Added local news by ZIP code/city
- Added keyword alerts
- Added custom RSS feeds
- Added weather widget
- Added trending topics ticker
- Added screensaver mode
- Added content filtering (removes ads)
- Added background auto-refresh
- Added iCloud settings sync
- Improved UI with new tab-based navigation

### v1.0.0 (January 2026)
- Initial release
- On-device sentiment analysis
- Named entity recognition
- Audio briefings with TTS
- Source bias indicators
- Breaking news alerts
- Ambient mode

---

## Related Projects

- **[News Summary](https://github.com/kochj23/NewsSummary)** - Full-featured macOS news app with cloud AI

---

## Contributing

Contributions welcome! Please read the contributing guidelines before submitting PRs.

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Author

**Jordan Koch** ([@kochj23](https://github.com/kochj23))

---

## Acknowledgments

- Apple's NaturalLanguage, Vision, WeatherKit, and CloudKit frameworks
- RSS feed providers for news content
- SwiftUI for the beautiful UI framework

---

*NewsTV v2.0.0 - AI-Powered News for Your Living Room*

© 2026 Jordan Koch. All rights reserved.

---

> **Disclaimer:** This is a personal project created on my own time. It is not affiliated with, endorsed by, or representative of my employer.
