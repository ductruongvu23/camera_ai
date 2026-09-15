//
//  TextReviewView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI

struct TextReviewView: View {
    @Bindable var viewModel: ScanViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isCopied: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var showResetConfirm: Bool = false

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
                // Background Gradient
                LinearGradient(
                    colors: [Color(hex: "0D0B1C"), Color(hex: "171630"), Color(hex: "080711")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Info Bar
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text.viewfinder")
                                .foregroundStyle(Color(hex: "00CEC9"))
                            Text("\(viewModel.selectedImages.count) trang quét")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())

                        HStack(spacing: 6) {
                            Text("\(wordCount) từ")
                                .font(.caption.bold())
                                .foregroundStyle(Color(hex: "A29BFE"))
                            Text("•")
                                .foregroundStyle(.white.opacity(0.4))
                            Text("\(charCount) ký tự")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Capsule())

                        Spacer()

                        // Copy Button
                        Button {
                            UIPasteboard.general.string = viewModel.scannedText
                            withAnimation { isCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                isCopied = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Đã chép" : "Sao chép")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(isCopied ? Color(hex: "00CEC9") : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.2))

                    // Text Editor Container
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Chỉnh Sửa Văn Bản:")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                            Text("Chạm vào văn bản để sửa")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "00CEC9").opacity(0.8))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )

                            TextEditor(text: $viewModel.scannedText)
                                .scrollContentBackground(.hidden)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.white.opacity(0.95))
                                .lineSpacing(5)
                                .padding(12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    // Bottom Action Bar
                    VStack(spacing: 10) {
                        // AI Summarize CTA Button (Optional add-on)
                        Button {
                            Task {
                                await viewModel.summarizeEditedText()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.headline)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("⚡ Tóm Tắt Bằng AI (Tuỳ Chọn Thêm)")
                                        .font(.system(.subheadline, design: .rounded).bold())
                                    Text("Dùng \(GeminiService.storedModelId) để cô đọng ý chính & định dạng Markdown")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "6C5CE7"), Color(hex: "00CEC9")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color(hex: "6C5CE7").opacity(0.4), radius: 10, y: 4)
                        }

                        // Share Raw Text Button
                        Button {
                            showShareSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Lưu / Chia Sẻ Văn Bản Đã Sửa (Không Cần AI)")
                            }
                            .font(.footnote.bold())
                            .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .background(Color.black.opacity(0.3))
                }
            }
            .navigationTitle("Văn Bản Đã Trích Xuất")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.white)
                    }
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
                Text("Vui lòng dán Gemini API Key từ Google AI Studio (aistudio.google.com) vào Cài Đặt để sử dụng tính năng tóm tắt thông minh, hoặc chọn Xem Thử Nghiệm Ngay.")
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
}

// Helper for UIActivityViewController
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
