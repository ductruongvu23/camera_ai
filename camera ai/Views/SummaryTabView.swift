//
//  SummaryTabView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI

struct SummaryTabView: View {
    let summaryPoints: [String]
    @State private var copiedIndex: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Banner
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hex: "FD79A8").opacity(0.18))
                            .frame(width: 44, height: 44)

                        Image(systemName: "bolt.fill")
                            .font(.title3.bold())
                            .foregroundStyle(Color(hex: "FD79A8"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Điểm Nhấn Ôn Thi Cấp Tốc")
                            .font(.headline.bold())
                            .foregroundStyle(.white)

                        Text("Các khái niệm cốt lõi & định nghĩa được AI chắt lọc ngắn gọn.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()
                }
                .padding(14)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

                if summaryPoints.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("Không có nội dung tóm tắt.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.vertical, 60)
                } else {
                    // Summary Point Cards
                    ForEach(Array(summaryPoints.enumerated()), id: \.offset) { index, point in
                        SummaryCardView(
                            index: index + 1,
                            text: point,
                            isCopied: copiedIndex == index
                        ) {
                            UIPasteboard.general.string = point
                            withAnimation {
                                copiedIndex = index
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                if copiedIndex == index {
                                    copiedIndex = nil
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 30)
        }
    }
}

private struct SummaryCardView: View {
    let index: Int
    let text: String
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Badge
                HStack(spacing: 4) {
                    Image(systemName: "number.circle.fill")
                        .font(.caption2)
                    Text("Ý CỐT LÕI \(index)")
                        .font(.caption2.bold())
                }
                .foregroundStyle(Color(hex: "A29BFE"))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: "6C5CE7").opacity(0.2))
                .clipShape(Capsule())

                Spacer()

                // Copy Action Button
                Button(action: onCopy) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                        Text(isCopied ? "Đã chép" : "Sao chép")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(isCopied ? Color(hex: "00CEC9") : .white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
            }

            // Bullet Point Text
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "6C5CE7"), Color(hex: "00CEC9")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                Text(text)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "17162C").opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "6C5CE7").opacity(0.4), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}
