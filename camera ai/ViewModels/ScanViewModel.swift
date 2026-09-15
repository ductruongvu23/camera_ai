//
//  ScanViewModel.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI
import PhotosUI

/// Main ViewModel using the Swift Observation framework.
/// Manages the entire pipeline: Image selection (camera/library) ➔ On-Device OCR ➔ Gemini Batch AI ➔ Dual-Tab UI
@MainActor
@Observable
final class ScanViewModel {

    // MARK: - Services
    private let ocrService = OCRService()
    private let geminiService = GeminiService()

    // MARK: - App State
    var selectedImages: [UIImage] = []
    var processingState: ProcessingState = .idle
    var currentSession: ScanSession?
    var errorMessage: String?
    var showErrorAlert: Bool = false

    // MARK: - UI Navigation Sheets
    var showCamera = false
    var showPhotoLibrary = false
    var showResults = false
    var showSettings = false
    var showApiKeyPrompt = false

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
            return "Đã hoàn tất xử lý!"
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
            return 0.1 + (Double(current) / Double(total)) * 0.5
        case .processingAI:
            return 0.8
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
    }

    func reset() {
        selectedImages.removeAll()
        processingState = .idle
        currentSession = nil
        errorMessage = nil
        showResults = false
    }

    // MARK: - Core Pipeline Execution

    /// Starts the end-to-end pipeline:
    /// [Ảnh Slide Bài Giảng] ➔ [1. Vision OCR (On-Device)] ➔ [2. Gemini API (Batch)] ➔ [3. Dual-View UI]
    func processAllSlides() async {
        guard !selectedImages.isEmpty else { return }

        // Check if API key is configured
        if !apiKeyConfigured {
            showApiKeyPrompt = true
            return
        }

        errorMessage = nil
        showErrorAlert = false

        do {
            // STEP 1: Vision OCR (On-Device, Batch) - Fully Swift 6 MainActor compliant
            var rawTexts: [String] = []
            let totalImages = selectedImages.count

            for (index, image) in selectedImages.enumerated() {
                processingState = .scanningOCR(current: index + 1, total: totalImages)
                let text = try await ocrService.recognizeText(from: image)
                rawTexts.append(text)
            }

            // Combine all raw slide texts into one batch payload
            let mergedText = rawTexts.enumerated().map { index, text in
                """
                === TRANG VĂN BẢN SỐ \(index + 1) ===
                \(text.isEmpty ? "(Trang không có văn bản nhận diện được)" : text)
                """
            }.joined(separator: "\n\n")

            // STEP 2: Gemini API Processing (temperature = 0.0, structured JSON)
            processingState = .processingAI

            let geminiResult = try await geminiService.processLectureText(mergedText)

            // STEP 3: Display Dual-View Results
            let session = ScanSession(
                images: selectedImages,
                rawTexts: rawTexts,
                mergedRawText: mergedText,
                formattedContent: geminiResult.formattedLecture,
                summaryPoints: geminiResult.summaryPoints,
                createdAt: .now
            )

            currentSession = session
            processingState = .completed
            showResults = true

        } catch {
            processingState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    /// Load demonstration mode for testing without requiring a live Gemini API key
    func runDemoMode() {
        processingState = .completed
        let sample = GeminiService.createSampleResponse()
        currentSession = ScanSession(
            images: selectedImages,
            rawTexts: ["Trang 1: Giới thiệu AI", "Trang 2: Machine Learning", "Trang 3: Deep Learning"],
            mergedRawText: "Nội dung mẫu thử nghiệm",
            formattedContent: sample.formattedLecture,
            summaryPoints: sample.summaryPoints,
            createdAt: .now
        )
        showResults = true
    }
}
