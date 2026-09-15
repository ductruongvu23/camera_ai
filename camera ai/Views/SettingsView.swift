//
//  SettingsView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//  Redesigned following Apple Human Interface Guidelines (Apple Design System)
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKeyInput: String = ""
    @State private var selectedModelId: String = "gemini-3.5-flash"
    @State private var liveModels: [GeminiModelOption] = GeminiService.availableModels
    @State private var isScanningModels: Bool = false
    @State private var scanResultText: String? = nil
    @State private var showSavedAlert: Bool = false
    @State private var isShowingKey: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Model Selection Section
                Section {
                    ForEach(liveModels) { model in
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                selectedModelId = model.id
                            }
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(model.displayName)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(AppleTheme.primaryText)

                                        Text(model.badge)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(model.id == "gemini-3.5-flash" ? AppleTheme.blue : AppleTheme.secondaryText)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                (model.id == "gemini-3.5-flash" ? AppleTheme.blue : AppleTheme.secondaryText).opacity(0.12)
                                            )
                                            .clipShape(Capsule())
                                    }

                                    Text(model.description)
                                        .font(.caption)
                                        .foregroundStyle(AppleTheme.secondaryText)
                                        .lineLimit(2)
                                }

                                Spacer()

                                if selectedModelId == model.id {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppleTheme.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Custom Model ID Option
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundStyle(AppleTheme.secondaryText)
                        TextField("Tùy chỉnh model ID (ví dụ: gemini-3.5-flash)", text: $selectedModelId)
                            .font(.subheadline)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    // Scan Google Models Button
                    Button {
                        Task {
                            isScanningModels = true
                            scanResultText = nil
                            let fetched = await GeminiService.fetchLiveModels(apiKey: apiKeyInput)
                            liveModels = fetched
                            isScanningModels = false
                            scanResultText = "Đã quét thấy \(fetched.count) mô hình khả dụng trên API Key của bạn!"
                        }
                    } label: {
                        HStack {
                            if isScanningModels {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text("Quét danh sách mô hình từ Google AI Studio")
                        }
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppleTheme.blue)
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isScanningModels)

                    if let scanResultText {
                        Text(scanResultText)
                            .font(.caption)
                            .foregroundStyle(AppleTheme.green)
                    }
                } header: {
                    Text("Mô Hình Trí Tuệ Nhân Tạo (Gemini)")
                } footer: {
                    Text("Bạn có thể linh hoạt chọn bất kỳ model nào. Nếu một model bị quá tải tạm thời (lỗi 503 capacity), ứng dụng sẽ tự động chuyển sang mô hình ổn định để hoàn tất bài học.")
                }

                // MARK: - API Key Section
                Section {
                    HStack {
                        if isShowingKey {
                            TextField("Dán khóa API (AIzaSy...)", text: $apiKeyInput)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Dán khóa API (AIzaSy...)", text: $apiKeyInput)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }

                        Button {
                            isShowingKey.toggle()
                        } label: {
                            Image(systemName: isShowingKey ? "eye.slash" : "eye")
                                .foregroundStyle(AppleTheme.secondaryText)
                        }

                        if !apiKeyInput.isEmpty {
                            Button {
                                apiKeyInput = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppleTheme.tertiaryText)
                            }
                        }
                    }

                    Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                        HStack {
                            Text("Lấy API Key miễn phí tại Google AI Studio")
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                        }
                        .font(.footnote)
                        .foregroundStyle(AppleTheme.blue)
                    }
                } header: {
                    Text("Google AI Studio API Key")
                } footer: {
                    Text("Khóa API được lưu trữ an toàn trên thiết bị của bạn và chỉ gửi trực tiếp tới máy chủ Google.")
                }

                // MARK: - About Section
                Section("Thông Tin Ứng Dụng") {
                    HStack {
                        Text("Phiên bản")
                        Spacer()
                        Text("1.2 (Apple Design System)")
                            .foregroundStyle(AppleTheme.secondaryText)
                    }

                    HStack {
                        Text("Công nghệ OCR")
                        Spacer()
                        Text("Apple Vision (Offline On-Device)")
                            .foregroundStyle(AppleTheme.secondaryText)
                    }

                    HStack {
                        Text("Thiết kế")
                        Spacer()
                        Text("Apple HIG Compliant")
                            .foregroundStyle(AppleTheme.secondaryText)
                    }
                }
            }
            .navigationTitle("Cài Đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lưu") {
                        let cleanModel = selectedModelId.trimmingCharacters(in: .whitespacesAndNewlines)
                        GeminiService.storedApiKey = apiKeyInput
                        GeminiService.storedModelId = cleanModel.isEmpty ? "gemini-3.5-flash" : cleanModel
                        showSavedAlert = true
                    }
                    .font(.body.weight(.bold))
                }
            }
            .onAppear {
                apiKeyInput = GeminiService.storedApiKey
                selectedModelId = GeminiService.storedModelId
                liveModels = GeminiService.availableModels
            }
            .alert("Đã Lưu Cấu Hình", isPresented: $showSavedAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Mô hình \(selectedModelId) và API Key đã được cập nhật.")
            }
        }
    }
}
