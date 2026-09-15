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
            id: "gemini-2.5-flash",
            displayName: "Gemini 2.5 Flash",
            description: "Khuyên dùng • Tốc độ siêu nhanh, máy chủ ổn định 100%, không lo nghẽn",
            badge: "Khuyên dùng"
        ),
        GeminiModelOption(
            id: "gemini-2.0-flash",
            displayName: "Gemini 2.0 Flash",
            description: "Thế hệ 2.0 • Ổn định và phản hồi tức thì",
            badge: "2.0 Flash"
        ),
        GeminiModelOption(
            id: "gemini-1.5-flash",
            displayName: "Gemini 1.5 Flash",
            description: "Thế hệ 1.5 • Dung lượng máy chủ lớn nhất toàn cầu",
            badge: "1.5 Flash"
        ),
        GeminiModelOption(
            id: "gemini-2.5-pro",
            displayName: "Gemini 2.5 Pro",
            description: "Chuyên sâu • Phân tích tài liệu học thuật phức tạp",
            badge: "2.5 Pro"
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

    /// Retrieve the selected model ID from UserDefaults (defaults to gemini-2.5-flash).
    static var storedModelId: String {
        get {
            let saved = UserDefaults.standard.string(forKey: modelStorageKey) ?? ""
            let clean = cleanModelId(saved)
            // If empty, contains 3.8 (server capacity failure), 3.0, or not in verified models, enforce gemini-2.5-flash
            if clean.isEmpty || clean.contains("3.8") || clean.contains("3.0") || !availableModels.contains(where: { $0.id == clean }) {
                UserDefaults.standard.set("gemini-2.5-flash", forKey: modelStorageKey)
                return "gemini-2.5-flash"
            }
            return clean
        }
        set {
            var clean = cleanModelId(newValue)
            if clean.contains("3.8") || clean.contains("3.0") || clean.isEmpty {
                clean = "gemini-2.5-flash"
            }
            UserDefaults.standard.set(clean, forKey: modelStorageKey)
        }
    }

    /// Helper to strip any 'models/' prefix or whitespace from model IDs
    static func cleanModelId(_ raw: String) -> String {
        var clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while clean.hasPrefix("models/") {
            clean = String(clean.dropFirst(7))
        }
        return clean
    }

    /// Dynamically query Google AI Studio ListModels endpoint for models available to this API key.
    static func fetchLiveModels(apiKey: String) async -> [GeminiModelOption] {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty,
              let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(key)") else {
            return availableModels
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let decoded = try? JSONDecoder().decode(GoogleListModelsResponse.self, from: data),
              let models = decoded.models else {
            return availableModels
        }

        let validModels = models.filter { item in
            guard let methods = item.supportedGenerationMethods else { return false }
            let clean = cleanModelId(item.name)
            // Filter out 3.8 models that currently suffer from Google 503 capacity outages
            return methods.contains("generateContent") && !clean.contains("3.8")
        }

        guard !validModels.isEmpty else { return availableModels }

        let options: [GeminiModelOption] = validModels.map { item in
            let cleanId = cleanModelId(item.name)
            let isFlash = cleanId.contains("flash")
            let badge = isFlash ? "Flash" : "Pro"
            return GeminiModelOption(
                id: cleanId,
                displayName: item.displayName ?? cleanId,
                description: item.description ?? "Hỗ trợ generateContent trên API Key của bạn",
                badge: badge
            )
        }

        // Sort Flash models first, with highest versions prioritized
        return options.sorted { a, b in
            if a.id.contains("flash") && !b.id.contains("flash") { return true }
            if !a.id.contains("flash") && b.id.contains("flash") { return false }
            return a.id > b.id
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

        let rawModelId = (modelIdOverride ?? Self.storedModelId)
        var cleanPrimary = Self.cleanModelId(rawModelId)
        if cleanPrimary.contains("3.8") || cleanPrimary.isEmpty {
            cleanPrimary = "gemini-2.5-flash"
        }

        // Candidate fallback order: user chosen model -> 2.5-flash -> 2.0-flash -> 1.5-flash -> 2.5-pro
        let fallbackSequence = [
            "gemini-2.5-flash",
            "gemini-2.0-flash",
            "gemini-1.5-flash",
            "gemini-2.5-pro"
        ]
        var candidateModels = [cleanPrimary]
        for fb in fallbackSequence {
            if !candidateModels.contains(fb) {
                candidateModels.append(fb)
            }
        }

        var lastError: Error = GeminiError.emptyResponse

        for modelId in candidateModels {
            do {
                let response = try await callGeminiAPI(text: text, modelId: modelId, apiKey: key)
                // Persist the working model
                Self.storedModelId = modelId
                return response
            } catch GeminiError.modelUnavailable(let failedModel, let msg) {
                print("Gemini model \(failedModel) unavailable (\(msg)), trying fallback...")
                lastError = GeminiError.modelUnavailable(modelId: failedModel, message: msg)
                continue
            } catch let GeminiError.httpError(code) where code == 404 || code == 503 {
                lastError = GeminiError.httpError(code)
                continue
            } catch GeminiError.apiError(let msg) {
                let lower = msg.lowercased()
                if lower.contains("capacity") || lower.contains("unavailable") || lower.contains("503") || lower.contains("overloaded") || lower.contains("not found") {
                    lastError = GeminiError.apiError(msg)
                    continue
                }
                throw GeminiError.apiError(msg)
            } catch {
                throw error
            }
        }

        // Dynamic fallback: Query Google's live list of models for this API key
        let liveOptions = await Self.fetchLiveModels(apiKey: key)
        for live in liveOptions where !candidateModels.contains(live.id) {
            do {
                let response = try await callGeminiAPI(text: text, modelId: live.id, apiKey: key)
                Self.storedModelId = live.id
                return response
            } catch {
                continue
            }
        }

        throw lastError
    }

    private func callGeminiAPI(text: String, modelId: String, apiKey: String) async throws -> GeminiResponse {
        let cleanId = Self.cleanModelId(modelId)
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(cleanId):generateContent?key=\(apiKey)") else {
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
            if httpResponse.statusCode == 404 || httpResponse.statusCode == 503 || lower.contains("not found") || lower.contains("not supported") || lower.contains("models/") || lower.contains("listmodels") || lower.contains("capacity") || lower.contains("unavailable") || lower.contains("overloaded") {
                throw GeminiError.modelUnavailable(modelId: cleanId, message: errorMsg)
            }

            if httpResponse.statusCode == 400 {
                if lower.contains("model") || lower.contains("supported") {
                    throw GeminiError.modelUnavailable(modelId: cleanId, message: errorMsg)
                }
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

    /// Intelligent fallback: if AI output wasn't strict JSON, format as markdown, bullet points & mind map tree
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

        let fallbackMindMap = MindMapBuilder.buildFallback(formattedContent: text, summaryPoints: bullets)

        return GeminiResponse(
            formattedLecture: text,
            summaryPoints: bullets,
            mindmap: fallbackMindMap
        )
    }

    /// Build the strict prompt instructing Gemini to return JSON with 3 distinct fields including Mind Map.
    private func buildPrompt(rawText: String) -> String {
        return """
        Bạn là một chuyên gia số hóa, tổ chức kiến thức và tạo sơ đồ tư duy (Mind Map) chuyên nghiệp.
        Nhiệm vụ của bạn là tiếp nhận văn bản đã được người dùng chỉnh sửa, trích xuất tóm tắt và xây dựng Sơ Đồ Tư Duy phân cấp.

        QUY TẮC BẮT BUỘC:
        1. Temperature = 0.0: Bám sát nội dung văn bản được cung cấp, không bịa đặt.
        2. Chuẩn hóa lại bố cục theo phân cấp Markdown mạch lạc.
        3. Giữ nguyên ngôn ngữ gốc của văn bản.

        BẮT BUỘC TRẢ VỀ ĐÚNG ĐỊNH DẠNG JSON GỒM 3 TRƯỜNG:
        {
          "formatted_lecture": "<Chuỗi Markdown hoàn chỉnh>",
          "summary_points": ["<Ý cốt lõi 1>", "<Ý cốt lõi 2>", ...],
          "mindmap": {
            "title": "<Chủ đề trung tâm>",
            "children": [
              {
                "title": "<Nhánh chính 1>",
                "details": "<Mô tả ngắn nếu có>",
                "children": [
                  { "title": "<Ý con 1.1>" },
                  { "title": "<Ý con 1.2>" }
                ]
              },
              {
                "title": "<Nhánh chính 2>",
                "details": "<Mô tả ngắn nếu có>",
                "children": [
                  { "title": "<Ý con 2.1>" }
                ]
              }
            ]
          }
        }

        CHI TIẾT 3 TRƯỜNG DỮ LIỆU:
        - "formatted_lecture": Toàn bộ nội dung văn bản được cấu trúc lại thành Markdown chuẩn:
          + Tiêu đề (#)
          + Các mục chính/phụ (##, ###)
          + Danh sách gạch đầu dòng (- )
          + In đậm các thuật ngữ quan trọng (**từ khóa**)

        - "summary_points": Mảng gồm 4-8 gạch đầu dòng ngắn gọn, cô đọng nhất để ôn thi nhanh.

        - "mindmap": Cấu trúc cây Sơ Đồ Tư Duy:
          + "title": Tên bài học / chủ đề trung tâm (ngắn gọn, súc tích, dưới 7 từ).
          + "children": 3 đến 6 nhánh chính (cấp 1), mỗi nhánh chính có 2 đến 5 nhánh con (cấp 2).
          + "details": Tùy chọn, giải thích hoặc từ khóa bổ trợ ngắn gọn.

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
        let sampleMindMap = MindMapNode(
            title: "Trí Tuệ Nhân Tạo & Học Máy",
            children: [
                MindMapNode(
                    title: "1. Khái Niệm Cốt Lõi",
                    details: "Phân cấp từ AI đến Deep Learning",
                    children: [
                        MindMapNode(title: "AI: Máy móc mô phỏng tư duy con người"),
                        MindMapNode(title: "Machine Learning: Học tự động từ dữ liệu"),
                        MindMapNode(title: "Deep Learning: Mạng nơ-ron sâu nhiều tầng")
                    ]
                ),
                MindMapNode(
                    title: "2. Quy Trình Huấn Luyện",
                    details: "4 bước chuẩn mực từ dữ liệu đến mô hình",
                    children: [
                        MindMapNode(title: "Thu thập & làm sạch dữ liệu"),
                        MindMapNode(title: "Tiền xử lý & gán nhãn"),
                        MindMapNode(title: "Huấn luyện (Backpropagation & Gradient Descent)"),
                        MindMapNode(title: "Đánh giá hiệu năng kiểm thử")
                    ]
                ),
                MindMapNode(
                    title: "3. Chỉ Số Đánh Giá",
                    details: "Metrics đo lường độ tin cậy",
                    children: [
                        MindMapNode(title: "Accuracy: Tỷ lệ đoán đúng tổng thể"),
                        MindMapNode(title: "Precision & Recall: Độ chính xác & bao phủ"),
                        MindMapNode(title: "F1-Score: Trung bình điều hòa")
                    ]
                ),
                MindMapNode(
                    title: "4. Ứng Dụng Thực Tiễn",
                    details: "Triển khai trong đời sống số",
                    children: [
                        MindMapNode(title: "Nhận dạng giọng nói (Siri) & khuôn mặt (FaceID)"),
                        MindMapNode(title: "Xe tự hành & Robot công nghiệp"),
                        MindMapNode(title: "Thị giác máy tính & OCR quét tài liệu")
                    ]
                )
            ]
        )

        return GeminiResponse(
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
            ],
            mindmap: sampleMindMap
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

// MARK: - ListModels Response Structure

struct GoogleListModelsResponse: Codable {
    let models: [GoogleModelItem]?

    struct GoogleModelItem: Codable {
        let name: String
        let displayName: String?
        let description: String?
        let supportedGenerationMethods: [String]?
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
