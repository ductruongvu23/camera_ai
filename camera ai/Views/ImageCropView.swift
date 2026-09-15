//
//  ImageCropView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI

/// View that allows user to crop an image and select a specific region of text.
struct ImageCropView: View {
    let originalImage: UIImage
    let onCrop: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentImage: UIImage
    @State private var cropRect: CGRect = .zero
    @State private var imageDisplayRect: CGRect = .zero
    @State private var isInitialized: Bool = false

    init(image: UIImage, onCrop: @escaping (UIImage) -> Void) {
        self.originalImage = image
        self._currentImage = State(initialValue: image)
        self.onCrop = onCrop
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Main Cropping Canvas
                    GeometryReader { geo in
                        let containerSize = geo.size

                        ZStack {
                            // Displayed Image
                            Image(uiImage: currentImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: containerSize.width, height: containerSize.height)

                            // Semi-transparent Dimming Overlay outside crop box
                            if isInitialized && cropRect.width > 0 && cropRect.height > 0 {
                                CropDimmingOverlay(cropRect: cropRect, containerSize: containerSize)

                                // The Interactive Crop Box & Handles
                                CropSelectionBox(
                                    cropRect: $cropRect,
                                    bounds: imageDisplayRect
                                )
                            }
                        }
                        .frame(width: containerSize.width, height: containerSize.height)
                        .onAppear {
                            setupDisplayRect(containerSize: containerSize)
                        }
                        .onChange(of: currentImage) { _, _ in
                            setupDisplayRect(containerSize: containerSize)
                        }
                    }
                    .clipped()

                    // Bottom Control Toolbar
                    bottomToolbar
                }
            }
            .navigationTitle("Cắt & Chọn Vùng Chữ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        applyCrop()
                    } label: {
                        Text("Xác nhận")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color(hex: "00CEC9"))
                    }
                }
            }
        }
    }

    // MARK: - Toolbar

    private var bottomToolbar: some View {
        VStack(spacing: 12) {
            Text("Kéo 4 góc hoặc di chuyển khung viền để chọn vùng chữ cần trích xuất")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 20) {
                // Rotate 90 degrees
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentImage = currentImage.rotated90Degrees()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rotate.right")
                        Text("Xoay 90°")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }

                // Reset to Full Image
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        cropRect = imageDisplayRect
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                        Text("Chọn Toàn Bộ")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "A29BFE"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "11101D").opacity(0.95))
    }

    // MARK: - Helper Methods

    private func setupDisplayRect(containerSize: CGSize) {
        guard containerSize.width > 0 && containerSize.height > 0 else { return }
        let imgSize = currentImage.size
        guard imgSize.width > 0 && imgSize.height > 0 else { return }

        let imgRatio = imgSize.width / imgSize.height
        let containerRatio = containerSize.width / containerSize.height

        let displayedW: CGFloat
        let displayedH: CGFloat

        if imgRatio > containerRatio {
            displayedW = containerSize.width
            displayedH = containerSize.width / imgRatio
        } else {
            displayedH = containerSize.height
            displayedW = containerSize.height * imgRatio
        }

        let originX = (containerSize.width - displayedW) / 2
        let originY = (containerSize.height - displayedH) / 2

        let displayRect = CGRect(x: originX, y: originY, width: displayedW, height: displayedH)
        self.imageDisplayRect = displayRect

        // Initialize crop rect to 85% centered in the displayed image
        let insetW = displayedW * 0.08
        let insetH = displayedH * 0.08
        self.cropRect = displayRect.insetBy(dx: insetW, dy: insetH)
        self.isInitialized = true
    }

    private func applyCrop() {
        guard imageDisplayRect.width > 0, imageDisplayRect.height > 0 else {
            dismiss()
            return
        }

        // Calculate normalized coordinates [0.0 ... 1.0]
        let normX = max(0, min(1, (cropRect.origin.x - imageDisplayRect.origin.x) / imageDisplayRect.size.width))
        let normY = max(0, min(1, (cropRect.origin.y - imageDisplayRect.origin.y) / imageDisplayRect.size.height))
        let normW = max(0.01, min(1 - normX, cropRect.size.width / imageDisplayRect.size.width))
        let normH = max(0.01, min(1 - normY, cropRect.size.height / imageDisplayRect.size.height))

        let normalizedRect = CGRect(x: normX, y: normY, width: normW, height: normH)
        let cropped = currentImage.cropped(to: normalizedRect)

        onCrop(cropped)
        dismiss()
    }
}

// MARK: - Crop Dimming Overlay

private struct CropDimmingOverlay: View {
    let cropRect: CGRect
    let containerSize: CGSize

    var body: some View {
        Canvas { context, size in
            // Fill background with semi-transparent black
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color.black.opacity(0.65)))

            // Clear the cropRect area
            context.blendMode = .clear
            context.fill(Path(cropRect), with: .color(.black))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Crop Selection Box with 4 Draggable Corners

private struct CropSelectionBox: View {
    @Binding var cropRect: CGRect
    let bounds: CGRect

    @State private var dragInitialRect: CGRect = .zero

    private let minDimension: CGFloat = 60

    var body: some View {
        ZStack {
            // Glowing Border & Grid
            Rectangle()
                .stroke(Color(hex: "00CEC9"), lineWidth: 2)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
                .overlay {
                    // Rule of thirds grid
                    RuleOfThirdsGrid(rect: cropRect)
                }

            // Move Entire Box Gesture Area
            Color.white.opacity(0.001)
                .frame(width: max(0, cropRect.width - 40), height: max(0, cropRect.height - 40))
                .position(x: cropRect.midX, y: cropRect.midY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if dragInitialRect == .zero {
                                dragInitialRect = cropRect
                            }
                            var newX = dragInitialRect.origin.x + value.translation.width
                            var newY = dragInitialRect.origin.y + value.translation.height

                            // Clamp within image bounds
                            newX = max(bounds.minX, min(newX, bounds.maxX - cropRect.width))
                            newY = max(bounds.minY, min(newY, bounds.maxY - cropRect.height))

                            cropRect.origin = CGPoint(x: newX, y: newY)
                        }
                        .onEnded { _ in
                            dragInitialRect = .zero
                        }
                )

            // Top-Left Handle
            CornerHandle(position: CGPoint(x: cropRect.minX, y: cropRect.minY)) { translation in
                dragCorner(translation: translation, isLeft: true, isTop: true)
            }

            // Top-Right Handle
            CornerHandle(position: CGPoint(x: cropRect.maxX, y: cropRect.minY)) { translation in
                dragCorner(translation: translation, isLeft: false, isTop: true)
            }

            // Bottom-Left Handle
            CornerHandle(position: CGPoint(x: cropRect.minX, y: cropRect.maxY)) { translation in
                dragCorner(translation: translation, isLeft: true, isTop: false)
            }

            // Bottom-Right Handle
            CornerHandle(position: CGPoint(x: cropRect.maxX, y: cropRect.maxY)) { translation in
                dragCorner(translation: translation, isLeft: false, isTop: false)
            }
        }
    }

    private func dragCorner(translation: CGSize, isLeft: Bool, isTop: Bool) {
        if dragInitialRect == .zero {
            dragInitialRect = cropRect
        }

        var newX = cropRect.origin.x
        var newY = cropRect.origin.y
        var newW = cropRect.size.width
        var newH = cropRect.size.height

        if isLeft {
            let proposedX = dragInitialRect.origin.x + translation.width
            let clampedX = max(bounds.minX, min(proposedX, dragInitialRect.maxX - minDimension))
            newX = clampedX
            newW = dragInitialRect.maxX - clampedX
        } else {
            let proposedW = dragInitialRect.width + translation.width
            let maxW = bounds.maxX - dragInitialRect.minX
            newW = max(minDimension, min(proposedW, maxW))
        }

        if isTop {
            let proposedY = dragInitialRect.origin.y + translation.height
            let clampedY = max(bounds.minY, min(proposedY, dragInitialRect.maxY - minDimension))
            newY = clampedY
            newH = dragInitialRect.maxY - clampedY
        } else {
            let proposedH = dragInitialRect.height + translation.height
            let maxH = bounds.maxY - dragInitialRect.minY
            newH = max(minDimension, min(proposedH, maxH))
        }

        cropRect = CGRect(x: newX, y: newY, width: newW, height: newH)
    }
}

// MARK: - Draggable Corner Handle

private struct CornerHandle: View {
    let position: CGPoint
    let onDrag: (CGSize) -> Void

    @State private var isDragging: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 24, height: 24)
                .shadow(color: Color.black.opacity(0.5), radius: 4)

            Circle()
                .fill(Color(hex: "00CEC9"))
                .frame(width: 14, height: 14)
        }
        .position(position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    onDrag(value.translation)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}

// MARK: - Rule of Thirds Grid Lines

private struct RuleOfThirdsGrid: View {
    let rect: CGRect

    var body: some View {
        GeometryReader { _ in
            Path { path in
                // Two horizontal lines
                let oneThirdH = rect.height / 3
                path.move(to: CGPoint(x: 0, y: oneThirdH))
                path.addLine(to: CGPoint(x: rect.width, y: oneThirdH))

                path.move(to: CGPoint(x: 0, y: oneThirdH * 2))
                path.addLine(to: CGPoint(x: rect.width, y: oneThirdH * 2))

                // Two vertical lines
                let oneThirdW = rect.width / 3
                path.move(to: CGPoint(x: oneThirdW, y: 0))
                path.addLine(to: CGPoint(x: oneThirdW, y: rect.height))

                path.move(to: CGPoint(x: oneThirdW * 2, y: 0))
                path.addLine(to: CGPoint(x: oneThirdW * 2, y: rect.height))
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 1)
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        .allowsHitTesting(false)
    }
}

// MARK: - UIImage Cropping & Rotation Extension

extension UIImage {
    /// Fixes image orientation to standard .up
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return normalized
    }

    /// Crops the image using normalized coordinates [0.0 ... 1.0]
    func cropped(to normalizedRect: CGRect) -> UIImage {
        let fixed = self.fixedOrientation()
        let pixelWidth = fixed.size.width * fixed.scale
        let pixelHeight = fixed.size.height * fixed.scale

        let cropX = max(0, normalizedRect.origin.x * pixelWidth)
        let cropY = max(0, normalizedRect.origin.y * pixelHeight)
        let cropW = min(pixelWidth - cropX, normalizedRect.size.width * pixelWidth)
        let cropH = min(pixelHeight - cropY, normalizedRect.size.height * pixelHeight)

        let pixelCropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)

        guard let cgImage = fixed.cgImage,
              let croppedCG = cgImage.cropping(to: pixelCropRect) else {
            return self
        }
        return UIImage(cgImage: croppedCG, scale: fixed.scale, orientation: .up)
    }

    /// Rotates image 90 degrees clockwise
    func rotated90Degrees() -> UIImage {
        let newSize = CGSize(width: size.height, height: size.width)
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return self }

        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: .pi / 2)
        draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))

        let rotated = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return rotated
    }
}
