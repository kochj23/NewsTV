//
//  ImageAnalyzer.swift
//  NewsTV
//
//  Image analysis using Vision framework
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import Vision
import UIKit

@MainActor
class ImageAnalyzer: ObservableObject {
    static let shared = ImageAnalyzer()

    @Published var isProcessing = false

    private init() {}

    // MARK: - Analyze Image

    func analyzeImage(at url: URL) async -> ImageAnalysisResult? {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data),
                  let cgImage = image.cgImage else {
                return nil
            }

            async let labels = classifyImage(cgImage)
            async let faces = detectFaces(cgImage)
            async let text = recognizeText(cgImage)
            async let dominantColors = analyzeDominantColors(cgImage)

            return await ImageAnalysisResult(
                labels: labels,
                faceCount: faces,
                detectedText: text,
                dominantColors: dominantColors
            )
        } catch {
            print("Image analysis failed: \(error)")
            return nil
        }
    }

    // MARK: - Image Classification

    private func classifyImage(_ image: CGImage) async -> [String] {
        await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let topLabels = results
                    .filter { $0.confidence > 0.3 }
                    .prefix(5)
                    .map { $0.identifier }

                continuation.resume(returning: topLabels)
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Face Detection

    private func detectFaces(_ image: CGImage) async -> Int {
        await withCheckedContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                let count = (request.results as? [VNFaceObservation])?.count ?? 0
                continuation.resume(returning: count)
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Text Recognition

    private func recognizeText(_ image: CGImage) async -> [String] {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let results = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let text = results.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Dominant Colors

    private func analyzeDominantColors(_ image: CGImage) async -> [UIColor] {
        // Simple color analysis using image sampling
        let width = image.width
        let height = image.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return []
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return [] }

        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)

        var colorCounts: [String: (color: UIColor, count: Int)] = [:]
        let sampleStep = max(1, (width * height) / 1000) // Sample ~1000 pixels

        for i in stride(from: 0, to: width * height, by: sampleStep) {
            let r = CGFloat(pointer[i * 4]) / 255.0
            let g = CGFloat(pointer[i * 4 + 1]) / 255.0
            let b = CGFloat(pointer[i * 4 + 2]) / 255.0

            // Quantize to reduce unique colors
            let qr = Int(r * 4) * 64
            let qg = Int(g * 4) * 64
            let qb = Int(b * 4) * 64

            let key = "\(qr)-\(qg)-\(qb)"
            let color = UIColor(red: CGFloat(qr) / 255, green: CGFloat(qg) / 255, blue: CGFloat(qb) / 255, alpha: 1)

            if let existing = colorCounts[key] {
                colorCounts[key] = (existing.color, existing.count + 1)
            } else {
                colorCounts[key] = (color, 1)
            }
        }

        return colorCounts.values
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0.color }
    }
}

// MARK: - Image Analysis Result

struct ImageAnalysisResult {
    let labels: [String]
    let faceCount: Int
    let detectedText: [String]
    let dominantColors: [UIColor]

    var hasText: Bool { !detectedText.isEmpty }
    var hasFaces: Bool { faceCount > 0 }

    var description: String {
        var parts: [String] = []

        if !labels.isEmpty {
            parts.append("Content: \(labels.prefix(3).joined(separator: ", "))")
        }

        if faceCount > 0 {
            parts.append("\(faceCount) face\(faceCount > 1 ? "s" : "") detected")
        }

        if hasText {
            parts.append("Contains text")
        }

        return parts.joined(separator: " | ")
    }
}
