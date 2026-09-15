//
//  ScanViewModel.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI
import PhotosUI

/// Main ViewModel using the Swift Observation framework.
/// Workflow:
/// 1. Image Selection (Camera/Library)
/// 2. On-Device OCR ➔ User views and edits recognized text
/// 3. (Optional / Add-on) AI Summarization via Gemini
@MainActor
@Observable
final class ScanViewModel {

    // MARK: - Services
    private let ocrService = OCRService()
    private let geminiService = GeminiService()

    // MARK: - App State
    var selectedImages: [UIImage] = []
    var scannedText: String = ""
    var processingState: ProcessingState = .idle
    var currentSession: ScanSession?
    var errorMessage: String?
    var showErrorAlert: Bool = false

    // MARK: - UI Navigation Sheets
    var showCamera = false
    var showPhotoLibrary = false
    var showTextReview = false
    var showResults = false
    var showSettings = false
    var showApiKeyPrompt = false
    var showCropEditor = false
    var imageIndexToCrop: Int? = nil

    // MARK: - Computed Properties
    var isProcessing: Bool {
        switch processingState {
        case .scanningOCR, .processingAI:
            return true
        default:
            return false
        }
    }

    var hasImages: Bool {
        !selectedImages.isEmpty
    }

    var apiKeyConfigured: Bool {
        !GeminiService.storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var processingStatusText: String {
        switch processingState {
        case .idle:
            return ""
        case .scanningOCR(let current, let total):
            return "Đang nhận diện chữ trang \(current)/\(total)..."
        case .processingAI:
            return "Gemini (\(GeminiService.storedModelId)) đang tóm tắt..."
        case .completed:
            return "Đã hoàn tất!"
        case .error(let msg):
            return "Lỗi: \(msg)"
        }
    }

    var processingProgress: Double {
        switch processingState {
        case .idle:
            return 0.0
        case .scanningOCR(let current, let total):
            guard total > 0 else { return 0.2 }
            return 0.1 + (Double(current) / Double(total)) * 0.7
        case .processingAI:
            return 0.85
        case .completed:
            return 1.0
        case .error:
            return 0.0
        }
    }

    // MARK: - Actions

    func addImage(_ image: UIImage) {
        selectedImages.append(image)
    }

    func addImages(_ images: [UIImage]) {
        selectedImages.append(contentsOf: images)
    }

    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
    }

    func clearImages() {
        selectedImages.removeAll()
        scannedText = ""
        imageIndexToCrop = nil
        showCropEditor = false
    }

    func startCropping(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        imageIndexToCrop = index
        showCropEditor = true
    }

    func updateCroppedImage(_ croppedImage: UIImage) {
        guard let index = imageIndexToCrop, selectedImages.indices.contains(index) else { return }
        selectedImages[index] = croppedImage
        showCropEditor = false
        imageIndexToCrop = nil
    }

    func reset() {
        selectedImages.removeAll()
        scannedText = ""
        processingState = .idle
        currentSession = nil
        errorMessage = nil
        showTextReview = false
        showResults = false
    }

    // MARK: - STEP 1: On-Device Image to Text (No AI needed)

    /// Converts all captured images into editable text using Vision OCR on-device.
    func scanImagesToText() async {
        guard !selectedImages.isEmpty else { return }

        errorMessage = nil
        showErrorAlert = false

        do {
            processingState = .scanningOCR(current: 0, total: selectedImages.count)

            var rawTexts: [String] = []
            let totalImages = selectedImages.count

            for (index, image) in selectedImages.enumerated() {
                processingState = .scanningOCR(current: index + 1, total: totalImages)
                let text = try await ocrService.recognizeText(from: image)
                rawTexts.append(text)
            }

            // Merge recognized texts with page dividers
            let merged = rawTexts.enumerated().map { index, text in
                if totalImages > 1 {
                    return """
                    === TRANG VĂN BẢN SỐ \(index + 1) ===
                    \(text.isEmpty ? "(Trang này không phát hiện được chữ)" : text)
                    """
                } else {
                    return text
                }
            }.joined(separator: "\n\n")

            scannedText = merged
            processingState = .idle

            // Open the text review & editing screen immediately!
            showTextReview = true

        } catch {
            processingState = .idle
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    // MARK: - STEP 2: (Optional Add-on) AI Summarization

    /// Sends the edited text to Gemini AI for structuring and summarization.
    func summarizeEditedText() async {
        let textToSummarize = scannedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToSummarize.isEmpty else {
            errorMessage = "Văn bản rỗng, không thể tóm tắt."
            showErrorAlert = true
            return
        }

        if !apiKeyConfigured {
            showApiKeyPrompt = true
            return
        }

        errorMessage = nil
        showErrorAlert = false

        do {
            processingState = .processingAI

            let geminiResult = try await geminiService.processLectureText(textToSummarize)

            let session = ScanSession(
                images: selectedImages,
                rawTexts: [textToSummarize],
                mergedRawText: textToSummarize,
                formattedContent: geminiResult.formattedLecture,
                summaryPoints: geminiResult.summaryPoints,
                mindmap: geminiResult.mindmap,
                createdAt: .now
            )

            currentSession = session
            processingState = .idle
            showResults = true

        } catch {
            processingState = .idle
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    /// Load demonstration mode for testing without a live Gemini API key
    func runDemoMode() {
        processingState = .completed
        let sample = GeminiService.createSampleResponse()
        currentSession = ScanSession(
            images: selectedImages,
            rawTexts: ["Trang 1: Giới thiệu AI", "Trang 2: Machine Learning", "Trang 3: Deep Learning"],
            mergedRawText: scannedText.isEmpty ? "Nội dung mẫu thử nghiệm" : scannedText,
            formattedContent: sample.formattedLecture,
            summaryPoints: sample.summaryPoints,
            mindmap: sample.mindmap,
            createdAt: .now
        )
        showResults = true
    }
}
