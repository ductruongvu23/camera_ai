//
//  LectureTabView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI

struct LectureTabView: View {
    let formattedContent: String
    @State private var isCopied: Bool = false

    private var parsedBlocks: [MarkdownBlock] {
        MarkdownRenderer.renderFull(formattedContent)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Header Info Banner
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hex: "00CEC9").opacity(0.18))
                            .frame(width: 44, height: 44)

                        Image(systemName: "books.vertical.fill")
                            .font(.title3.bold())
                            .foregroundStyle(Color(hex: "00CEC9"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bố Cục Chi Tiết Bài Giảng")
                            .font(.headline.bold())
                            .foregroundStyle(.white)

                        Text("Phân cấp tiêu đề (#, ##) & gạch đầu dòng chuẩn chỉnh để ghi chép.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    Button {
                        UIPasteboard.general.string = formattedContent
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
                .padding(14)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

                // Rendered Markdown Content
                VStack(alignment: .leading, spacing: 8) {
                    if parsedBlocks.isEmpty {
                        Text(formattedContent)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineSpacing(6)
                    } else {
                        ForEach(parsedBlocks) { block in
                            MarkdownBlockView(block: block)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(hex: "17162C").opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }
            .padding(16)
            .padding(.bottom, 30)
        }
    }
}
