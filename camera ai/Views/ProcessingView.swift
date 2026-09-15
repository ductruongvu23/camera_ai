//
//  ProcessingView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//  Redesigned following Apple Human Interface Guidelines (Apple Design System)
//

import SwiftUI

struct ProcessingView: View {
    let state: ProcessingState
    let progress: Double
    let statusText: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Apple Activity Indicator / Icon
                ZStack {
                    Circle()
                        .fill(AppleTheme.blue.opacity(0.12))
                        .frame(width: 64, height: 64)

                    switch state {
                    case .scanningOCR:
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(AppleTheme.blue)
                    case .processingAI:
                        Image(systemName: "sparkles")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(AppleTheme.blue)
                    default:
                        ProgressView()
                            .controlSize(.large)
                            .tint(AppleTheme.blue)
                    }
                }

                VStack(spacing: 6) {
                    Text(statusText)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppleTheme.primaryText)
                        .multilineTextAlignment(.center)

                    Text(pipelineStageDescription)
                        .font(.footnote)
                        .foregroundStyle(AppleTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }

                // Apple Native Progress Bar
                ProgressView(value: progress, total: 1.0)
                    .tint(AppleTheme.blue)
                    .padding(.horizontal, 8)
            }
            .padding(24)
            .frame(maxWidth: 300)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppleTheme.separator.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)
        }
    }

    private var pipelineStageDescription: String {
        switch state {
        case .idle:
            return "Đang chờ tác vụ..."
        case .scanningOCR:
            return "Đang nhận diện văn bản On-Device không cần mạng..."
        case .processingAI:
            return "AI đang phân tích bố cục, trích xuất ý chính & sơ đồ tư duy..."
        case .completed:
            return "Hoàn tất xử lý!"
        case .error(let msg):
            return msg
        }
    }
}
