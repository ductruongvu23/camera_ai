//
//  SettingsView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKeyInput: String = ""
    @State private var selectedModelId: String = "gemini-2.5-flash"
    @State private var showSavedAlert: Bool = false
    @State private var isShowingKey: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                        modelSectionView
                        apiKeySectionView
                        saveButtonView
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Cài Đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .onAppear {
                apiKeyInput = GeminiService.storedApiKey
                selectedModelId = GeminiService.storedModelId
            }
            .alert("Đã Lưu Thành Công", isPresented: $showSavedAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("API Key và mô hình \(selectedModelId) đã được cập nhật thành công.")
            }
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(hex: "0F0C20"), Color(hex: "1A1B35"), Color(hex: "0B0B14")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: Color(hex: "6C5CE7").opacity(0.5), radius: 16, x: 0, y: 8)

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
            }

            Text("Cài Đặt & Cấu Hình AI")
                .font(.system(.title2, design: .rounded).bold())
                .foregroundStyle(.white)

            Text("Tùy chỉnh mô hình Gemini và API Key để tối ưu tốc độ & chất lượng tóm tắt.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }

    private var modelSectionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "cpu.fill")
                    .foregroundStyle(Color(hex: "00CEC9"))
                Text("Mô Hình Gemini AI (Phiên bản 2026)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.9))
            }

            ForEach(GeminiService.availableModels) { model in
                ModelOptionRow(
                    model: model,
                    isSelected: selectedModelId == model.id
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedModelId = model.id
                    }
                }
            }

            // Custom Model ID option
            HStack(spacing: 8) {
                Image(systemName: "pencil.and.outline")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "FD79A8"))
                TextField("Tùy chỉnh model ID (ví dụ: gemini-3.5-pro)", text: $selectedModelId)
                    .font(.caption)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(.white)
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private var apiKeySectionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(Color(hex: "A29BFE"))
                Text("Google AI Studio API Key")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                Button {
                    isShowingKey.toggle()
                } label: {
                    Image(systemName: isShowingKey ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(Color(hex: "A29BFE"))
                }
            }

            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(Color(hex: "6C5CE7"))

                if isShowingKey {
                    TextField("Dán API Key (AIzaSy...)", text: $apiKeyInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.white)
                } else {
                    SecureField("Dán API Key (AIzaSy...)", text: $apiKeyInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.white)
                }

                if !apiKeyInput.isEmpty {
                    Button {
                        apiKeyInput = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )

            // Direct link to Google AI Studio
            Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.square")
                    Text("Lấy API Key miễn phí tại Google AI Studio")
                }
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "00CEC9"))
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private var saveButtonView: some View {
        Button {
            GeminiService.storedApiKey = apiKeyInput
            GeminiService.storedModelId = selectedModelId
            showSavedAlert = true
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Lưu Cấu Hình")
            }
            .font(.headline.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "6C5CE7"), Color(hex: "00CEC9")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color(hex: "6C5CE7").opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }
}

// MARK: - Model Option Row (Extracted to prevent compiler type-check timeout)

private struct ModelOptionRow: View {
    let model: GeminiModelOption
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                selectionIndicator

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(model.displayName)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)

                        Text(model.badge)
                            .font(.caption2.bold())
                            .foregroundStyle(isSelected ? Color(hex: "00CEC9") : Color.white.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }

                    Text(model.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()
            }
            .padding(14)
            .background(isSelected ? Color(hex: "6C5CE7").opacity(0.18) : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color(hex: "6C5CE7").opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color(hex: "00CEC9") : Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: 22, height: 22)

            if isSelected {
                Circle()
                    .fill(Color(hex: "00CEC9"))
                    .frame(width: 12, height: 12)
            }
        }
    }
}
