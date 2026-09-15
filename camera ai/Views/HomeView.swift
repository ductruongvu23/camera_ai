//
//  HomeView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//  Redesigned following Apple Human Interface Guidelines (Apple Design System)
//

import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: ScanViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                // Apple System Grouped Background (Adaptive Light/Dark)
                AppleTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Status Card (Apple Inset Style)
                        headerStatusCard

                        // Quick Capture Actions (Camera & Library)
                        actionCardsSection

                        // Scanned Pages Section
                        scannedPagesSection

                        // Offline OCR Step Indicator Banner
                        if viewModel.hasImages {
                            ocrInfoBanner
                        }

                        // Primary Call to Action
                        primaryActionButtonSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Tài Liệu AI")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showSettings = true
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(viewModel.apiKeyConfigured ? AppleTheme.green : AppleTheme.orange)
                                .frame(width: 8, height: 8)
                            Image(systemName: "gearshape")
                                .font(.body.weight(.medium))
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCamera) {
                CameraPickerView { image in
                    withAnimation(.spring(response: 0.35)) {
                        viewModel.addImage(image)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showPhotoLibrary) {
                PhotoLibraryPickerView { images in
                    withAnimation(.spring(response: 0.35)) {
                        viewModel.addImages(images)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $viewModel.showCropEditor) {
                if let index = viewModel.imageIndexToCrop, viewModel.selectedImages.indices.contains(index) {
                    ImageCropView(image: viewModel.selectedImages[index]) { cropped in
                        viewModel.updateCroppedImage(cropped)
                    }
                }
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
                Text("Vui lòng nhập Gemini API Key từ Google AI Studio trong Cài Đặt để tóm tắt bài giảng bằng AI, hoặc chọn Xem Thử Nghiệm Ngay.")
            }
            .alert("Thông Báo", isPresented: $viewModel.showErrorAlert) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Đã xảy ra lỗi không xác định.")
            }
        }
    }

    // MARK: - Subviews

    private var headerStatusCard: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppleTheme.blue.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppleTheme.blue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Quét & Tóm Tắt Bài Giảng")
                    .font(.headline)
                    .foregroundStyle(AppleTheme.primaryText)

                Text("Nhận diện chữ On-Device offline • Tóm tắt & Sơ đồ tư duy AI")
                    .font(.footnote)
                    .foregroundStyle(AppleTheme.secondaryText)
            }

            Spacer()

            Button {
                viewModel.showSettings = true
            } label: {
                HStack(spacing: 4) {
                    Text(GeminiService.storedModelId)
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(AppleTheme.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppleTheme.blue.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .appleCardStyle(padding: 14)
    }

    private var actionCardsSection: some View {
        HStack(spacing: 12) {
            // Camera Card
            Button {
                viewModel.showCamera = true
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppleTheme.blue)
                            .frame(width: 44, height: 44)

                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chụp Ảnh")
                            .font(.headline)
                            .foregroundStyle(AppleTheme.primaryText)

                        Text("Quét trực tiếp")
                            .font(.subheadline)
                            .foregroundStyle(AppleTheme.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appleCardStyle(padding: 16)
            }
            .buttonStyle(.plain)

            // Photo Library Card
            Button {
                viewModel.showPhotoLibrary = true
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppleTheme.indigo)
                            .frame(width: 44, height: 44)

                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Thư Viện")
                            .font(.headline)
                            .foregroundStyle(AppleTheme.primaryText)

                        Text("Chọn nhiều ảnh")
                            .font(.subheadline)
                            .foregroundStyle(AppleTheme.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appleCardStyle(padding: 16)
            }
            .buttonStyle(.plain)
        }
    }

    private var scannedPagesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(viewModel.hasImages ? "TRANG ĐÃ CHỌN (\(viewModel.selectedImages.count))" : "TRANG ĐÃ CHỌN")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppleTheme.secondaryText)

                Spacer()

                if viewModel.hasImages {
                    Button(role: .destructive) {
                        withAnimation {
                            viewModel.clearImages()
                        }
                    } label: {
                        Text("Xóa tất cả")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(AppleTheme.red)
                    }
                }
            }
            .padding(.horizontal, 4)

            if viewModel.selectedImages.isEmpty {
                Button {
                    viewModel.showPhotoLibrary = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                            .font(.system(size: 32))
                            .foregroundStyle(AppleTheme.secondaryText.opacity(0.6))

                        VStack(spacing: 2) {
                            Text("Chưa chọn hình ảnh nào")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppleTheme.primaryText)

                            Text("Chụp văn bản hoặc chọn ảnh tài liệu để bắt đầu")
                                .font(.footnote)
                                .foregroundStyle(AppleTheme.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .appleCardStyle(padding: 16)
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                            AppleSlideThumbnailCard(
                                index: index + 1,
                                image: image,
                                onCrop: { viewModel.startCropping(at: index) },
                                onDelete: {
                                    withAnimation {
                                        viewModel.removeImage(at: index)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var ocrInfoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "text.viewfinder")
                .font(.title3)
                .foregroundStyle(AppleTheme.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Bước 1: Trích xuất chữ trên máy (Offline)")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(AppleTheme.primaryText)

                Text("Nhận diện văn bản trên thiết bị không cần mạng. Bạn có thể chỉnh sửa trước khi tóm tắt.")
                    .font(.caption)
                    .foregroundStyle(AppleTheme.secondaryText)
            }

            Spacer()
        }
        .appleCardStyle(padding: 12)
    }

    private var primaryActionButtonSection: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await viewModel.scanImagesToText()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.body.bold())
                    Text(viewModel.hasImages ? "Chuyển \(viewModel.selectedImages.count) Trang Thành Văn Bản" : "Chụp Hoặc Chọn Văn Bản")
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppleTheme.blue)
            .clipShape(RoundedRectangle(cornerRadius: AppleTheme.buttonRadius, style: .continuous))
            .disabled(!viewModel.hasImages)

            Button {
                viewModel.runDemoMode()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "play.circle")
                    Text("Xem bài giảng thử nghiệm & Sơ đồ tư duy (Demo)")
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppleTheme.blue)
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Apple Thumbnail Card

private struct AppleSlideThumbnailCard: View {
    let index: Int
    let image: UIImage
    let onCrop: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onCrop) {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 95)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        // Crop Pill
                        HStack(spacing: 3) {
                            Image(systemName: "crop")
                                .font(.system(size: 9, weight: .bold))
                            Text("Cắt")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(5)
                    }

                    HStack {
                        Text("Trang \(index)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppleTheme.primaryText)
                        Spacer()
                        Image(systemName: "pencil")
                            .font(.caption2)
                            .foregroundStyle(AppleTheme.secondaryText)
                    }
                    .padding(.horizontal, 2)
                }
                .appleCardStyle(padding: 8)
            }
            .buttonStyle(.plain)

            // Delete Badge Button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(uiColor: .systemGray2))
                    .background(Circle().fill(Color(uiColor: .systemBackground)))
            }
            .offset(x: 6, y: -6)
        }
    }
}
