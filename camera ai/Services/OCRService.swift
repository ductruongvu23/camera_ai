//
//  OCRService.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import Vision
import UIKit

/// On-device text recognition service using Apple Vision Framework.
/// Supports Vietnamese (vi-VN) and English (en-US).
/// Runs entirely on-device — no network required.
@MainActor
final class OCRService {

    /// Recognizes text from a single UIImage.
    /// - Parameter image: The slide image to scan.
    /// - Returns: Recognized text as a single string.
    nonisolated func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                // Sort observations by position (top-to-bottom, left-to-right)
                let sorted = observations.sorted { a, b in
                    let aY = 1.0 - a.boundingBox.midY  // Flip Y (Vision uses bottom-left origin)
                    let bY = 1.0 - b.boundingBox.midY
                    if abs(aY - bY) < 0.02 {
                        return a.boundingBox.midX < b.boundingBox.midX
                    }
                    return aY < bY
                }

                let text = sorted
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: text)
            }

            // Configure for accuracy with Vietnamese + English
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["vi-VN", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Batch OCR: recognizes text from multiple images.
    /// - Parameters:
    ///   - images: Array of slide images.
    ///   - onProgress: Called after each image is processed (current index, total count).
    /// - Returns: Array of recognized texts (one per image).
    nonisolated func recognizeTexts(
        from images: [UIImage],
        onProgress: @Sendable @escaping (Int, Int) -> Void
    ) async throws -> [String] {
        var results: [String] = []

        for (index, image) in images.enumerated() {
            let text = try await recognizeText(from: image)
            results.append(text)
            onProgress(index + 1, images.count)
        }

        return results
    }
}

enum OCRError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Không thể xử lý ảnh. Vui lòng chọn ảnh khác."
        }
    }
}
