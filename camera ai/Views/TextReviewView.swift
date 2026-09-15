//
//  TextReviewView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//  Redesigned following Apple Human Interface Guidelines (Apple Design System)
//

import SwiftUI

struct TextReviewView: View {
    @Bindable var viewModel: ScanViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isCopied: Bool = false
    @State private var showShareSheet: Bool = false

    var wordCount: Int {
        let words = viewModel.scannedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count
    }

    var charCount: Int {
        viewModel.scannedText.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Quick Model & Stats Bar (Apple Inset Style)
                    modelAndStatsHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    // Text Editor in Apple Inset Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("NỘI DUNG VĂN BẢN")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppleTheme.secondaryText)
                            Spacer()
                            Text("Chạm để chỉnh sửa")
                                .font(.caption2)
                                .foregroundStyle(AppleTheme.tertiaryText)
                        }
                        .padding(.horizontal, 4)

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: AppleTheme.cardRadius, style: .continuous)
                                .fill(AppleTheme.secondaryBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppleTheme.cardRadius, style: .continuous)
                                        .stroke(AppleTheme.separator.opacity(0.2), lineWidth: 0.5)
                                )

                            TextEditor(text: $viewModel.scannedText)
                                .scrollContentBackground(.hidden)
                                .font(.system(.body, design: .default))
                                .foregroundStyle(AppleTheme.primaryText)
                                .lineSpacing(4)
                                .padding(12)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    // Bottom Floating Action Card
                    bottomActionCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
            .navigationTitle("Kiểm Tra Văn Bản")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .foregroundStyle(AppleTheme.secondaryText)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.summarizeEditedText()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("Tóm Tắt")
                                .font(.headline.weight(.semibold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppleTheme.blue)
                    .controlSize(.small)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [viewModel.scannedText])
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $viewModel.showResults) {
                if let session = viewModel.currentSession {
                    ResultTabView(session: session) {
                        viewModel.showResults = false
                    }
                }
            }
            .overlay {
                if viewModel.isProcessing {
                    ProcessingView(
                        state: viewModel.processingState,
                        progress: viewModel.processingProgress,
                        statusText: viewModel.processingStatusText
                    )
                    .transition(.opacity)
                }
            }
            .alert("Chưa Có Gemini API Key", isPresented: $viewModel.showApiKeyPrompt) {
                Button("Mở Cài Đặt") {
                    viewModel.showSettings = true
                }
                Button("Xem Thử Nghiệm Ngay", role: .none) {
                    viewModel.runDemoMode()
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Vui lòng nhập Gemini API Key từ Google AI Studio trong Cài Đặt để sử dụng tính năng tóm tắt AI, hoặc chọn Xem Thử Nghiệm Ngay.")
            }
            .alert("Thông Báo AI", isPresented: $viewModel.showErrorAlert) {
                Button("Đổi Mô Hình AI") {
                    viewModel.showSettings = true
                }
                Button("Đóng", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Đã xảy ra lỗi khi gọi mô hình AI.")
            }
        }
    }

    // MARK: - Subviews

    private var modelAndStatsHeader: some View {
        HStack(spacing: 10) {
            // Model Selector Pill
            Button {
                viewModel.showSettings = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "cpu")
                        .font(.caption2)
                    Text(GeminiService.storedModelId)
                        .font(.caption.weight(.semibold))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9))
                }
                .foregroundStyle(AppleTheme.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppleTheme.blue.opacity(0.1))
                .clipShape(Capsule())
            }

            // Word & Char Count
            HStack(spacing: 6) {
                Text("\(wordCount) từ")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppleTheme.primaryText)
                Text("•")
                    .foregroundStyle(AppleTheme.tertiaryText)
                Text("\(charCount) ký tự")
                    .font(.caption)
                    .foregroundStyle(AppleTheme.secondaryText)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(AppleTheme.secondaryBackground)
            .clipShape(Capsule())

            Spacer()

            // Copy Button
            Button {
                UIPasteboard.general.string = viewModel.scannedText
                withAnimation { isCopied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation { isCopied = false }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    Text(isCopied ? "Đã chép" : "Chép")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(isCopied ? AppleTheme.green : AppleTheme.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppleTheme.secondaryBackground)
                .clipShape(Capsule())
            }
        }
    }

    private var bottomActionCard: some View {
        VStack(spacing: 10) {
            // Primary AI Summarize Button
            Button {
                Task {
                    await viewModel.summarizeEditedText()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.headline)
                    Text("Tóm Tắt & Tạo Sơ Đồ Tư Duy")
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppleTheme.blue)
            .clipShape(RoundedRectangle(cornerRadius: AppleTheme.buttonRadius, style: .continuous))

            // Secondary Share Raw Text
            Button {
                showShareSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Chia sẻ văn bản đã trích xuất (Không dùng AI)")
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppleTheme.secondaryText)
            }
        }
        .appleCardStyle(padding: 12)
    }
}

// Helper for UIActivityViewController
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
