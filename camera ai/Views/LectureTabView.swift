//
//  LectureTabView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//  Redesigned following Apple Human Interface Guidelines (Apple Design System)
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
                // Header Banner
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppleTheme.indigo.opacity(0.12))
                            .frame(width: 40, height: 40)

                        Image(systemName: "book.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppleTheme.indigo)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bố Cục Chi Tiết Bài Giảng")
                            .font(.headline)
                            .foregroundStyle(AppleTheme.primaryText)

                        Text("Định dạng phân cấp tiêu đề Markdown chuẩn chỉnh.")
                            .font(.footnote)
                            .foregroundStyle(AppleTheme.secondaryText)
                    }

                    Spacer()

                    Button {
                        UIPasteboard.general.string = formattedContent
                        withAnimation { isCopied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { isCopied = false }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            Text(isCopied ? "Đã chép" : "Sao chép")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(isCopied ? AppleTheme.green : AppleTheme.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isCopied ? AppleTheme.green.opacity(0.1) : AppleTheme.blue.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }
                .appleCardStyle(padding: 12)

                // Reader Card
                VStack(alignment: .leading, spacing: 10) {
                    if parsedBlocks.isEmpty {
                        Text(formattedContent)
                            .font(.body)
                            .foregroundStyle(AppleTheme.primaryText)
                            .lineSpacing(5)
                    } else {
                        ForEach(parsedBlocks) { block in
                            MarkdownBlockView(block: block)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appleCardStyle(padding: 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
    }
}
