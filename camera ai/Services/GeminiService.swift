//
//  GeminiService.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import Foundation

/// Available Gemini models
struct GeminiModelOption: Identifiable, Hashable {
    let id: String
    let displayName: String
    let description: String
    let badge: String
}

/// Service for processing OCR text through the Gemini REST API.
/// Uses native URLSession — no third-party SDK required.
/// Includes automatic fallback across models to prevent API 404 errors.
@MainActor
final class GeminiService {

    // MARK: - API Key & Model Storage
    static let apiKeyStorageKey = "gemini_user_api_key"
    static let modelStorageKey = "gemini_selected_model"

    static let availableModels: [GeminiModelOption] = [
        GeminiModelOption(
            id: "gemini-2.0-flash",
            displayName: "Gemini 2.0 Flash",
            description: "Khuyên dùng • Tốc độ siêu tốc, ổn định nhất hiện tại",
            badge: "Khuyên dùng"
        ),
        GeminiModelOption(
            id: "gemini-1.5-flash",
            displayName: "Gemini 1.5 Flash",
            description: "Rất ổn định • Hỗ trợ mọi API key miễn phí",
            badge: "Ổn định"
        ),
        GeminiModelOption(
            id: "gemini-2.5-flash",
            displayName: "Gemini 2.5 Flash",
            description: "Thế hệ 2.5 • Phân tích chi tiết và nhanh",
            badge: "Mới"
        ),
        GeminiModelOption(
            id: "gemini-3.0-flash",
            displayName: "Gemini 3.0 Flash",
            description: "Thế hệ 3.x • Tự động fallback nếu endpoint chưa mở",
            badge: "Mới 3.x"
        ),
        GeminiModelOption(
            id: "gemini-3.0-pro",
            displayName: "Gemini 3.0 Pro",
            description: "Thế hệ 3.x cao cấp • Suy luận sâu",
            badge: "Flagship 3.0"
        ),
        GeminiModelOption(
            id: "gemini-1.5-pro",
            displayName: "Gemini 1.5 Pro",
            description: "Chuyên sâu • Phân tích logic và văn bản học thuật",
            badge: "Chuyên sâu"
        )
    ]

    /// Retrieve the user-configured API key from UserDefaults.
    static var storedApiKey: String {
        get {
            UserDefaults.standard.string(forKey: apiKeyStorageKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: apiKeyStorageKey)
        }
    }

    /// Retrieve the selected model ID from UserDefaults (defaults to gemini-2.0-flash).
    static var storedModelId: String {
        get {
            let saved = UserDefaults.standard.string(forKey: modelStorageKey) ?? ""
            return saved.isEmpty ? "gemini-2.0-flash" : saved
        }
        set {
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: modelStorageKey)
        }
    }

    /// Process raw/edited text through Gemini with automatic fallback if a model is unavailable.
    func processLectureText(
        _ text: String,
        apiKeyOverride: String? = nil,
        modelIdOverride: String? = nil
    ) async throws -> GeminiResponse {
        let key = (apiKeyOverride ?? Self.storedApiKey).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !key.isEmpty else {
            throw GeminiError.missingApiKey
        }

        let primaryModelId = (modelIdOverride ?? Self.storedModelId).trimmingCharacters(in: .whitespacesAndNewlines)

        // Candidate fallback order: user chosen model -> gemini-2.0-flash -> gemini-1.5-flash -> gemini-2.5-flash -> gemini-1.5-pro
        let fallbackSequence = ["gemini-2.0-flash", "gemini-1.5-flash", "gemini-2.5-flash", "gemini-1.5-pro"]
        var candidateModels = [primaryModelId]
        for fb in fallbackSequence {
            if !candidateModels.contains(fb) {
                candidateModels.append(fb)
            }
        }

        var lastError: Error = GeminiError.emptyResponse

        for modelId in candidateModels {
            do {
                return try await callGeminiAPI(text: text, modelId: modelId, apiKey: key)
            } catch GeminiError.modelUnavailable(let failedModel, let msg) {
                print("Gemini model \(failedModel) unavailable (\(msg)), trying fallback...")
                lastError = GeminiError.modelUnavailable(modelId: failedModel, message: msg)
                continue
            } catch let GeminiError.httpError(code) where code == 404 {
                lastError = GeminiError.httpError(404)
                continue
            } catch {
                throw error
            }
        }

        throw lastError
    }

    private func callGeminiAPI(text: String, modelId: String, apiKey: String) async throws -> GeminiResponse {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelId):generateContent?key=\(apiKey)") else {
            throw GeminiError.invalidEndpoint
        }

        let prompt = buildPrompt(rawText: text)

        let requestPayload: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.0,
                "responseMimeType": "application/json"
            ]
        ]

        let requestBody = try JSONSerialization.data(withJSONObject: requestPayload, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBody
        request.timeoutInterval = 45

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError("Phản hồi mạng không hợp lệ")
        }

        guard httpResponse.statusCode == 200 else {
            var errorMsg = "Mã phản hồi HTTP \(httpResponse.statusCode)"
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDetail = errorObj["error"] as? [String: Any],
               let message = errorDetail["message"] as? String {
                errorMsg = message
            }

            let lower = errorMsg.lowercased()
            if httpResponse.statusCode == 404 || lower.contains("not found") || lower.contains("not supported") || lower.contains("models/") {
                throw GeminiError.modelUnavailable(modelId: modelId, message: errorMsg)
            }

            if httpResponse.statusCode == 400 {
                throw GeminiError.httpError(400)
            } else if httpResponse.statusCode == 403 {
                throw GeminiError.httpError(403)
            } else if httpResponse.statusCode == 429 {
                throw GeminiError.httpError(429)
            }

            throw GeminiError.apiError(errorMsg)
        }

        let geminiAPIResponse = try JSONDecoder().decode(GeminiAPIEnvelope.self, from: data)

        guard let rawCandidateText = geminiAPIResponse.candidates?.first?.content?.parts?.first?.text else {
            throw GeminiError.emptyResponse
        }

        // Try JSON parsing
        let cleaned = cleanMarkdownCodeBlock(rawCandidateText)
        if let cleanData = cleaned.data(using: .utf8),
           let cleanResult = try? JSONDecoder().decode(GeminiResponse.self, from: cleanData) {
            return cleanResult
        }

        // Graceful fallback if Gemini returned markdown directly
        return parseFallbackMarkdown(rawCandidateText)
    }

    /// Intelligent fallback: if AI output wasn't strict JSON, format as markdown & bullet points
    private func parseFallbackMarkdown(_ text: String) -> GeminiResponse {
        let lines = text.components(separatedBy: .newlines)
        var bullets: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                let point = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if !point.isEmpty && bullets.count < 8 {
                    bullets.append(point)
                }
            }
        }

        if bullets.isEmpty {
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.count > 15 && !trimmed.hasPrefix("#") && bullets.count < 5 {
                    bullets.append(trimmed)
                }
            }
        }

        if bullets.isEmpty {
            bullets = ["Đã hoàn thành phân tích nội dung văn bản."]
        }

        return GeminiResponse(
            formattedLecture: text,
            summaryPoints: bullets
        )
    }

    /// Build the strict prompt instructing Gemini to return JSON with 2 distinct fields.
    private func buildPrompt(rawText: String) -> String {
        return """
        Bạn là một trợ lý số hóa và tóm tắt tài liệu chuyên nghiệp.
        Nhiệm vụ của bạn là tiếp nhận văn bản đã được người dùng chỉnh sửa và trích xuất tóm tắt.

        QUY TẮC BẮT BUỘC:
        1. Temperature = 0.0: Bám sát nội dung văn bản được cung cấp, không bịa đặt.
        2. Chuẩn hóa lại bố cục theo phân cấp Markdown mạch lạc.
        3. Giữ nguyên ngôn ngữ gốc của văn bản.

        BẮT BUỘC TRẢ VỀ ĐÚNG ĐỊNH DẠNG JSON GỒM 2 TRƯỜNG:
        {
          "formatted_lecture": "<Chuỗi Markdown hoàn chỉnh>",
          "summary_points": ["<Ý cốt lõi 1>", "<Ý cốt lõi 2>", ...]
        }

        CHI TIẾT 2 TRƯỜNG DỮ LIỆU:
        - "formatted_lecture": Toàn bộ nội dung văn bản được cấu trúc lại thành Markdown chuẩn:
          + Tiêu đề (#)
          + Các mục chính/phụ (##, ###)
          + Danh sách gạch đầu dòng (- )
          + In đậm các thuật ngữ quan trọng (**từ khóa**)

        - "summary_points": Mảng gồm 4-8 gạch đầu dòng ngắn gọn, cô đọng nhất:
          + Khái niệm định nghĩa cốt lõi
          + Điểm nhấn quan trọng để ôn tập nhanh.

        VĂN BẢN ĐÃ CUNG CẤP:
        ---
        \(rawText)
        ---
        """
    }

    private func cleanMarkdownCodeBlock(_ text: String) -> String {
        var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("```json") {
            clean = String(clean.dropFirst(7))
        } else if clean.hasPrefix("```") {
            clean = String(clean.dropFirst(3))
        }
        if clean.hasSuffix("```") {
            clean = String(clean.dropLast(3))
        }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Generates sample demonstration data
    static func createSampleResponse() -> GeminiResponse {
        GeminiResponse(
            formattedLecture: """
            # Giới Thiệu Về Trí Tuệ Nhân Tạo & Học Máy (AI & ML)

            ## 1. Khái Niệm Cơ Bản
            - **Trí tuệ nhân tạo (AI)**: Khả năng của máy móc mô phỏng hành vi và tư duy thông minh của con người.
            - **Machine Learning (Học máy)**: Tập con của AI, cho phép hệ thống học tập từ dữ liệu mà không cần lập trình tường minh.
            - **Deep Learning (Học sâu)**: Dựa trên mạng nơ-ron nhân tạo nhiều lớp (Deep Neural Networks), giải quyết các bài toán phức tạp như thị giác máy tính và xử lý ngôn ngữ tự nhiên.

            ## 2. Quy Trình Huấn Luyện Mô Hình
            - **Thu thập dữ liệu**: Chuẩn bị dataset sạch và đa dạng.
            - **Tiền xử lý**: Làm sạch nhiễu, chuẩn hóa kích thước, gán nhãn (labeling).
            - **Huấn luyện (Training)**: Cập nhật trọng số thông qua thuật toán lan truyền ngược (Backpropagation) và Gradient Descent.
            - **Đánh giá (Evaluation)**: Kiểm thử trên tập dữ liệu Test với các chỉ số Accuracy, Precision, Recall, F1-Score.

            ## 3. Ứng Dụng Thực Tiễn
            - Nhận dạng giọng nói và khuôn mặt (FaceID, Siri).
            - Xe tự hành và robot công nghiệp.
            - Xử lý ảnh và OCR (quét slide bài giảng tự động).
            """,
            summaryPoints: [
                "AI mô phỏng trí tuệ con người; Machine Learning là tập con học từ dữ liệu; Deep Learning dựa trên mạng nơ-ron sâu.",
                "Quy trình xây dựng mô hình: Thu thập dữ liệu ➔ Tiền xử lý ➔ Huấn luyện (Backpropagation) ➔ Đánh giá.",
                "Các chỉ số đánh giá quan trọng: Accuracy, Precision, Recall và F1-Score.",
                "Ứng dụng hàng đầu: Thị giác máy tính (OCR), Xử lý ngôn ngữ tự nhiên (NLP) và Tự động hóa."
            ]
        )
    }
}

// MARK: - Internal Response Envelope

private struct GeminiAPIEnvelope: Codable {
    let candidates: [Candidate]?

    struct Candidate: Codable {
        let content: Content?
    }

    struct Content: Codable {
        let parts: [Part]?
    }

    struct Part: Codable {
        let text: String?
    }
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case missingApiKey
    case invalidEndpoint
    case emptyResponse
    case invalidJSON
    case httpError(Int)
    case modelUnavailable(modelId: String, message: String)
    case apiError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Chưa có Gemini API Key. Vui lòng vào Cài Đặt (icon bánh răng) để dán API Key miễn phí từ Google AI Studio (aistudio.google.com)."
        case .invalidEndpoint:
            return "Đường dẫn API không hợp lệ."
        case .emptyResponse:
            return "AI không trả về nội dung. Vui lòng thử lại."
        case .invalidJSON:
            return "Dữ liệu trả về từ AI không đúng cấu trúc JSON yêu cầu. Vui lòng thử lại."
        case .httpError(let code):
            if code == 400 {
                return "Yêu cầu không hợp lệ (Mã 400). Kiểm tra lại định dạng dữ liệu hoặc API Key."
            } else if code == 403 {
                return "API Key không hợp lệ hoặc bị vô hiệu hóa (Mã 403). Hãy kiểm tra lại key từ aistudio.google.com."
            } else if code == 404 {
                return "Model AI này không tìm thấy trên endpoint của bạn (Mã 404). Hệ thống đã tự động thử các model Flash ổn định."
            } else if code == 429 {
                return "Đã đạt giới hạn lượt gọi API miễn phí (Mã 429). Vui lòng đợi 1 phút rồi bấm tóm tắt lại."
            }
            return "Lỗi kết nối Gemini (Mã \(code))."
        case .modelUnavailable(let modelId, let msg):
            return "Mô hình \(modelId) chưa khả dụng trên endpoint: \(msg). Hãy chọn Gemini 2.0 Flash hoặc 1.5 Flash trong Cài Đặt."
        case .apiError(let msg):
            return "Lỗi từ Gemini: \(msg)"
        case .networkError(let msg):
            return "Lỗi kết nối mạng: \(msg). Kiểm tra kết nối Internet trên điện thoại."
        }
    }
}
