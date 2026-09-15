//
//  ScanSession.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI

/// Represents one complete scan session: multiple slide images → OCR → AI processing
struct ScanSession: Identifiable {
    let id = UUID()
    var images: [UIImage]
    var rawTexts: [String]           // OCR text per slide
    var mergedRawText: String        // All raw texts joined
    var formattedContent: String     // Markdown-formatted lecture content from Gemini
    var summaryPoints: [String]      // Key summary bullet points from Gemini
    var createdAt: Date

    init(
        images: [UIImage] = [],
        rawTexts: [String] = [],
        mergedRawText: String = "",
        formattedContent: String = "",
        summaryPoints: [String] = [],
        createdAt: Date = .now
    ) {
        self.images = images
        self.rawTexts = rawTexts
        self.mergedRawText = mergedRawText
        self.formattedContent = formattedContent
        self.summaryPoints = summaryPoints
        self.createdAt = createdAt
    }
}

/// The JSON structure Gemini returns
struct GeminiResponse: Codable {
    let formattedLecture: String
    let summaryPoints: [String]

    enum CodingKeys: String, CodingKey {
        case formattedLecture = "formatted_lecture"
        case summaryPoints = "summary_points"
    }
}

/// Processing state machine
enum ProcessingState: Equatable {
    case idle
    case scanningOCR(current: Int, total: Int)
    case processingAI
    case completed
    case error(String)
}
