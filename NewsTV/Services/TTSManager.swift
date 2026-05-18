//
//  TTSManager.swift
//  NewsTV
//
//  Text-to-Speech service for audio briefings
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import AVFoundation

@MainActor
class TTSManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = TTSManager()

    @Published var isSpeaking = false
    @Published var currentArticleIndex = 0
    @Published var progress: Double = 0

    private let synthesizer = AVSpeechSynthesizer()
    private var articles: [NewsArticle] = []
    private var completionHandler: (() -> Void)?

    override private init() {
        super.init()
        synthesizer.delegate = self
    }

    private var audioSessionConfigured = false

    private func ensureAudioSession() {
        guard !audioSessionConfigured else { return }
        audioSessionConfigured = true
        setupAudioSession()
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    // MARK: - Speak Single Article

    func speakArticle(_ article: NewsArticle, rate: Float = 0.5) {
        ensureAudioSession()
        stop()

        let text = buildSpeechText(for: article)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    // MARK: - Audio Briefing

    func startBriefing(articles: [NewsArticle], rate: Float = 0.5, completion: (() -> Void)? = nil) {
        ensureAudioSession()
        stop()

        self.articles = articles
        self.completionHandler = completion
        currentArticleIndex = 0

        if !articles.isEmpty {
            speakCurrentArticle(rate: rate)
        }
    }

    private func speakCurrentArticle(rate: Float) {
        guard currentArticleIndex < articles.count else {
            finishBriefing()
            return
        }

        let article = articles[currentArticleIndex]

        // Add transition for subsequent articles
        var text = ""
        if currentArticleIndex > 0 {
            text = "Next story. "
        } else {
            text = "Starting your news briefing. "
        }

        text += buildSpeechText(for: article)

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.preUtteranceDelay = 0.5
        utterance.postUtteranceDelay = 1.0

        isSpeaking = true
        synthesizer.speak(utterance)

        progress = Double(currentArticleIndex) / Double(articles.count)
    }

    private func buildSpeechText(for article: NewsArticle) -> String {
        var text = ""

        // Source and category
        text += "From \(article.source.name). "

        if article.isBreakingNews {
            text += "Breaking news. "
        }

        // Title
        text += article.title + ". "

        // Summary or description
        if let summary = article.summary {
            text += summary
        } else if let description = article.rssDescription {
            text += description
        }

        return text
    }

    // MARK: - Controls

    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
            isSpeaking = false
        }
    }

    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isSpeaking = true
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        articles = []
        currentArticleIndex = 0
        progress = 0
    }

    func skipToNext() {
        synthesizer.stopSpeaking(at: .immediate)
        currentArticleIndex += 1
        if currentArticleIndex < articles.count {
            speakCurrentArticle(rate: 0.5)
        } else {
            finishBriefing()
        }
    }

    func skipToPrevious() {
        synthesizer.stopSpeaking(at: .immediate)
        currentArticleIndex = max(0, currentArticleIndex - 1)
        speakCurrentArticle(rate: 0.5)
    }

    private func finishBriefing() {
        isSpeaking = false
        progress = 1.0

        let utterance = AVSpeechUtterance(string: "End of news briefing.")
        utterance.rate = 0.5
        synthesizer.speak(utterance)

        completionHandler?()
        completionHandler = nil
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            if !self.articles.isEmpty && self.currentArticleIndex < self.articles.count - 1 {
                self.currentArticleIndex += 1
                self.speakCurrentArticle(rate: 0.5)
            } else if !self.articles.isEmpty {
                self.finishBriefing()
            } else {
                self.isSpeaking = false
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
