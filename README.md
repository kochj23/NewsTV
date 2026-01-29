# NewsTV - AI-Powered News for Apple TV

**On-Device Machine Learning News Reader with Sentiment Analysis and Text-to-Speech**

![Platform](https://img.shields.io/badge/platform-tvOS%2017.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-1.0.0-success)
![ML](https://img.shields.io/badge/ML-NaturalLanguage%20%7C%20Vision%20%7C%20Core%20ML-purple)

---

## Overview

NewsTV brings AI-powered news analysis to your Apple TV. Using Apple's on-device machine learning frameworks (NaturalLanguage, Vision, Core ML), it provides real-time sentiment analysis, named entity recognition, and intelligent text-to-speech briefings - all without requiring cloud services.

Built as a companion to the macOS News Summary app, NewsTV is optimized for the lean-back, 10-foot viewing experience of your living room.

---

## Features

### On-Device Machine Learning

| Feature | Framework | Description |
|---------|-----------|-------------|
| **Sentiment Analysis** | NaturalLanguage | Color-coded sentiment indicators for headlines |
| **Named Entity Recognition** | NaturalLanguage | Automatically identifies people, organizations, locations |
| **Image Classification** | Vision | Analyzes news article images |
| **Face Detection** | Vision | Detects faces in news photos |
| **Text Recognition** | Vision | OCR for text in images |

### TV-Optimized Features

- **Multi-Category News Browser** - US, World, Business, Technology, Science, Health, Sports, Entertainment, Politics
- **Audio Briefings** - Text-to-Speech news reading with play/pause/skip controls
- **Breaking News Alerts** - Full-screen banners for major news
- **Source Bias Indicators** - Visual badges showing Left/Center/Right bias
- **Ambient Mode** - Screensaver-style news rotation
- **Siri Remote Optimized** - Focus-based navigation with card-style buttons
- **Large Typography** - Configurable font sizes for comfortable viewing

### News Analysis

- **Sentiment Coloring** - Headlines color-coded by positive/negative/neutral sentiment
- **Entity Extraction** - See who and what is mentioned in each article
- **Source Reliability** - Reliability scores for news sources
- **Bias Spectrum** - Visual indicator showing political leaning

---

## What It Can Do

✅ **Aggregate news** from 20+ RSS sources across 10 categories
✅ **Analyze sentiment** of headlines using on-device NLP
✅ **Extract entities** (people, organizations, places) from articles
✅ **Read articles aloud** with built-in text-to-speech
✅ **Show breaking news** with prominent alerts
✅ **Indicate source bias** with Left/Center/Right badges
✅ **Display in ambient mode** as a screensaver
✅ **Work offline** - all ML processing happens on-device
✅ **Protect privacy** - no data sent to cloud services

---

## What It Cannot Do

❌ **Display full web pages** - tvOS doesn't support WebKit
❌ **Show article images inline** - displays category icons instead
❌ **Provide AI summaries** - requires cloud AI (see macOS News Summary)
❌ **Fact-check claims** - requires cloud AI
❌ **Multi-perspective analysis** - requires cloud AI
❌ **Deep article scraping** - limited to RSS descriptions
❌ **User accounts/sync** - standalone app (no cloud sync)

---

## Installation

### From Xcode

1. Clone the repository:
   ```bash
   git clone https://github.com/kochj23/NewsTV.git
   cd NewsTV
   ```

2. Generate Xcode project (if needed):
   ```bash
   xcodegen generate
   ```

3. Open in Xcode:
   ```bash
   open NewsTV.xcodeproj
   ```

4. Select your Apple TV as the destination
5. Build and run (⌘R)

### From Command Line

```bash
# Build for tvOS device
xcodebuild -project NewsTV.xcodeproj \
  -target NewsTV \
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

### Navigation

- **Swipe Left/Right** - Change categories
- **Swipe Up/Down** - Browse articles
- **Select (Press)** - Open article detail
- **Play/Pause** - Start/stop audio briefing
- **Menu** - Go back / Close

### Audio Briefing

1. Navigate to any category
2. Press Play/Pause on Siri Remote
3. News will be read aloud in order
4. Use play/pause to control playback
5. Swipe to skip articles

### Settings

- **Font Size** - Medium, Large, Extra Large
- **Rotation Interval** - 5s to 60s for ambient mode
- **Sentiment Colors** - Toggle on/off
- **Bias Indicators** - Toggle on/off
- **Breaking News Alerts** - Toggle on/off
- **Audio Briefings** - Toggle on/off
- **Speech Rate** - Slow, Normal, Fast

---

## Architecture

```
NewsTV/
├── Shared/
│   ├── Models/
│   │   └── NewsModels.swift      # Data models
│   └── Services/
│       ├── RSSParser.swift       # RSS feed parsing
│       └── NewsAggregator.swift  # News aggregation
│
└── NewsTV/
    ├── ML/
    │   ├── SentimentAnalyzer.swift   # NaturalLanguage sentiment
    │   ├── EntityExtractor.swift     # NaturalLanguage NER
    │   └── ImageAnalyzer.swift       # Vision framework
    ├── Services/
    │   ├── TTSManager.swift          # Text-to-Speech
    │   └── SettingsManager.swift     # User preferences
    └── Views/
        ├── TVContentView.swift       # Main view
        ├── CategoryNewsView.swift    # Category browser
        ├── ArticleDetailView.swift   # Article detail
        ├── AudioBriefingView.swift   # Audio player
        ├── SettingsView.swift        # Settings
        └── Components/
            ├── ArticleCard.swift     # Article card
            ├── AmbientModeView.swift # Screensaver
            └── BreakingNewsBanner.swift
```

---

## News Sources

### Default Sources (20+)

| Category | Sources |
|----------|---------|
| Top Stories | Associated Press, Reuters, NPR |
| US | NY Times, WSJ |
| World | BBC, The Guardian |
| Technology | TechCrunch, Ars Technica, The Verge |
| Business | CNBC, Bloomberg |
| Science | Science Daily, Nature |
| Health | Medical News Today |
| Sports | ESPN |
| Entertainment | Variety |
| Politics | Politico, The Hill |

---

## ML Frameworks Used

### NaturalLanguage Framework
- **Sentiment Analysis** - `NLTagger` with `.sentimentScore` scheme
- **Named Entity Recognition** - `NLTagger` with `.nameType` scheme
- Detects: People, Organizations, Places

### Vision Framework
- **Image Classification** - `VNClassifyImageRequest`
- **Face Detection** - `VNDetectFaceRectanglesRequest`
- **Text Recognition** - `VNRecognizeTextRequest`
- **Color Analysis** - Custom pixel sampling

### AVFoundation
- **Text-to-Speech** - `AVSpeechSynthesizer`
- Background audio playback support

---

## Requirements

- **tvOS 17.0** or later
- **Apple TV 4K** (2nd generation or later recommended)
- **Xcode 15.0** or later (for building)
- **xcodegen** (optional, for project generation)

---

## Privacy

NewsTV respects your privacy:

- **No cloud AI** - All ML processing happens on your Apple TV
- **No analytics** - No usage tracking or telemetry
- **No accounts** - No sign-in required
- **No data collection** - News is fetched directly from RSS feeds
- **Open source** - Full source code available for inspection

---

## Known Limitations

1. **No web content** - tvOS doesn't support WebKit, so full articles cannot be displayed
2. **RSS descriptions only** - Article content limited to RSS feed descriptions
3. **No images** - Article images not displayed (category icons shown instead)
4. **No cloud AI** - Advanced features like summarization require cloud APIs
5. **Memory constraints** - Large feed lists may cause performance issues

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

- Apple's NaturalLanguage and Vision frameworks
- RSS feed providers for news content
- SwiftUI for the beautiful UI framework

---

*NewsTV v1.0.0 - AI-Powered News for Your Living Room*

© 2026 Jordan Koch. All rights reserved.
