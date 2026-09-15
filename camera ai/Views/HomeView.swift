//
//  HomeView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: ScanViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [Color(hex: "0B0A17"), Color(hex: "171530"), Color(hex: "080710")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Top Branding Header
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Color(hex: "00CEC9"))
                                Text("TÓM TẮT VĂN BẢN AI")
                                    .font(.caption2.bold())
                                    .tracking(1.5)
                                    .foregroundStyle(Color(hex: "A29BFE"))

                                Button {
                                    viewModel.showSettings = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(hex: "00CEC9"))
                                            .frame(width: 6, height: 6)
                                        Text(GeminiService.storedModelId)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())

                            Text("Tóm Tắt Văn Bản Thông Minh")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Quét chữ On-Device không tốn mạng, AI phân tích bố cục chuẩn & trích xuất ý chính ngắn gọn.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 10)

                        // Feature Quick Badges (PDF, Slides, Markdown)
                        HStack(spacing: 8) {
                            FeaturePill(icon: "doc.text.fill", text: "Xuất PDF A4")
                            FeaturePill(icon: "rectangle.inset.filled.and.person.filled", text: "Xuất Slide 16:9")
                            FeaturePill(icon: "arrow.down.doc.fill", text: "Tệp Markdown")
                        }
                        .padding(.horizontal, 20)

                        // Capture Source Buttons (Camera & Photo Library)
                        HStack(spacing: 14) {
                            // Camera Button
                            ActionButtonCard(
                                icon: "camera.viewfinder",
                                title: "Chụp Văn Bản",
                                subtitle: "Quét trực tiếp qua Camera",
                                gradientColors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")]
                            ) {
                                viewModel.showCamera = true
                            }

                            // Photo Library Button (Batch)
                            ActionButtonCard(
                                icon: "photo.stack.fill",
                                title: "Chọn Thư Viện",
                                subtitle: "Chọn nhiều ảnh cùng lúc",
                                gradientColors: [Color(hex: "00CEC9"), Color(hex: "0984E3")]
                            ) {
                                viewModel.showPhotoLibrary = true
                            }
                        }
                        .padding(.horizontal, 20)

                        // Selected Slides Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Danh Sách Trang Cần Tóm Tắt")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)

                                Spacer()

                                if viewModel.hasImages {
                                    Text("\(viewModel.selectedImages.count) trang")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color(hex: "00CEC9"))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color(hex: "00CEC9").opacity(0.15))
                                        .clipShape(Capsule())

                                    Button("Xoá hết") {
                                        withAnimation {
                                            viewModel.clearImages()
                                        }
                                    }
                                    .font(.caption.bold())
                                    .foregroundStyle(Color(hex: "FD79A8"))
                                }
                            }
                            .padding(.horizontal, 20)

                            if viewModel.selectedImages.isEmpty {
                                EmptySlidePlaceholder {
                                    viewModel.showPhotoLibrary = true
                                }
                                .padding(.horizontal, 20)
                            } else {
                                // Horizontal Slides Carousel
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                                            SlideThumbnailCard(
                                                index: index + 1,
                                                image: image
                                            ) {
                                                withAnimation {
                                                    viewModel.removeImage(at: index)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        // OCR On-Device Highlight Banner
                        if viewModel.hasImages {
                            HStack(spacing: 12) {
                                Image(systemName: "text.viewfinder")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "00CEC9"))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bước 1: Trích Xuất Văn Bản Trên Máy")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color(hex: "00CEC9"))
                                    Text("Toàn bộ \(viewModel.selectedImages.count) trang sẽ được nhận diện chữ offline. Bạn sẽ được xem và chỉnh sửa trước khi tóm tắt AI.")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(Color(hex: "00CEC9").opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color(hex: "00CEC9").opacity(0.25), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }

                        // Action CTA: Start Image to Text OCR
                        VStack(spacing: 12) {
                            Button {
                                Task {
                                    await viewModel.scanImagesToText()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.headline)
                                    Text(viewModel.hasImages ? "Chuyển \(viewModel.selectedImages.count) Trang Thành Văn Bản" : "Hãy Chụp Hoặc Chọn Văn Bản")
                                        .font(.system(.headline, design: .rounded).bold())
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: viewModel.hasImages ?
                                            [Color(hex: "6C5CE7"), Color(hex: "00CEC9")] :
                                            [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(
                                    color: viewModel.hasImages ? Color(hex: "6C5CE7").opacity(0.4) : .clear,
                                    radius: 12, x: 0, y: 6
                                )
                            }
                            .disabled(!viewModel.hasImages)

                            // Demo Mode Button (instant preview)
                            Button {
                                viewModel.runDemoMode()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.circle.fill")
                                    Text("Xem Mẫu Thử Nghiệm & Xuất File (Demo)")
                                }
                                .font(.footnote.bold())
                                .foregroundStyle(Color(hex: "A29BFE"))
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 36)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showSettings = true
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(viewModel.apiKeyConfigured ? Color(hex: "00CEC9") : Color(hex: "FD79A8"))
                                .frame(width: 8, height: 8)
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(.white)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCamera) {
                CameraPickerView { image in
                    withAnimation {
                        viewModel.addImage(image)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showPhotoLibrary) {
                PhotoLibraryPickerView { images in
                    withAnimation {
                        viewModel.addImages(images)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $viewModel.showTextReview) {
                TextReviewView(viewModel: viewModel)
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
                Text("Vui lòng dán Gemini API Key từ Google AI Studio vào Cài đặt để phân tích bài giảng trực tiếp, hoặc chọn Xem Thử Nghiệm Ngay.")
            }
            .alert("Thông Báo Lỗi", isPresented: $viewModel.showErrorAlert) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Đã xảy ra lỗi không xác định.")
            }
        }
    }
}

// MARK: - Feature Pill

private struct FeaturePill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Action Button Card

private struct ActionButtonCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)

                    Image(systemName: icon)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
}

// MARK: - Slide Thumbnail Card

private struct SlideThumbnailCard: View {
    let index: Int
    let image: UIImage
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 100)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack {
                    Text("Trang \(index)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            .padding(8)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )

            // Delete Button
            Button(action: onDelete) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "FD79A8"))
                        .frame(width: 24, height: 24)
                    Image(systemName: "xmark")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
            }
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Empty State Placeholder

private struct EmptySlidePlaceholder: View {
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 64, height: 64)

                    Image(systemName: "plus.rectangle.on.rectangle")
                        .font(.title2)
                        .foregroundStyle(Color(hex: "A29BFE"))
                }

                Text("Chưa có văn bản nào được chọn")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.85))

                Text("Chụp ảnh văn bản hoặc chọn nhiều ảnh từ thư viện để bắt đầu")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        Color.white.opacity(0.1),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 6])
                    )
            )
        }
    }
}
