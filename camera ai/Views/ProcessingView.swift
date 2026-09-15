//
//  ProcessingView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI

struct ProcessingView: View {
    let state: ProcessingState
    let progress: Double
    let statusText: String

    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            // Dark Blur Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)

            VStack(spacing: 28) {
                // Animated AI Scanner Visual
                ZStack {
                    // Outer pulsing glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "6C5CE7").opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(pulseScale)

                    // Spinning gradient ring
                    Circle()
                        .trim(from: 0.0, to: 0.75)
                        .stroke(
                            AngularGradient(
                                colors: [Color(hex: "6C5CE7"), Color(hex: "00CEC9"), Color(hex: "A29BFE")],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(rotationAngle))

                    // Center icon based on state
                    ZStack {
                        Circle()
                            .fill(Color(hex: "1F1D36"))
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(hex: "6C5CE7").opacity(0.4), radius: 10)

                        switch state {
                        case .scanningOCR:
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(Color(hex: "00CEC9"))
                        case .processingAI:
                            Image(systemName: "sparkles")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(Color(hex: "A29BFE"))
                        default:
                            Image(systemName: "cpu")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.top, 10)

                // Status & Description
                VStack(spacing: 10) {
                    Text(statusText)
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // Subtitle explaining pipeline stage
                    Text(pipelineStageDescription)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }

                // Progress Bar
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 8)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "6C5CE7"), Color(hex: "00CEC9")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(16, geo.size.width * progress), height: 8)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 40)

                    HStack {
                        Text("On-Device OCR")
                            .font(.caption2.bold())
                            .foregroundStyle(Color(hex: "00CEC9"))
                        Spacer()
                        Text("Gemini Batch AI")
                            .font(.caption2.bold())
                            .foregroundStyle(Color(hex: "A29BFE"))
                    }
                    .padding(.horizontal, 42)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(hex: "13122B").opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "6C5CE7").opacity(0.6), Color(hex: "00CEC9").opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }

    private var pipelineStageDescription: String {
        switch state {
        case .scanningOCR:
            return "Vision Framework đang quét chữ (Việt & Anh) trên thiết bị, không tốn dữ liệu mạng..."
        case .processingAI:
            return "Gemini API (temperature = 0.0) đang tái cấu trúc bài giảng và trích xuất ý cốt lõi..."
        case .completed:
            return "Đã hoàn thành! Đang mở bảng kết quả..."
        default:
            return "Đang khởi chạy luồng xử lý..."
        }
    }
}
