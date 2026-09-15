//
//  SummaryTabView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//  Redesigned following Apple Human Interface Guidelines (Apple Design System)
//

import SwiftUI

struct SummaryTabView: View {
    let summaryPoints: [String]
    @State private var copiedIndex: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Header Banner
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppleTheme.blue.opacity(0.12))
                            .frame(width: 40, height: 40)

                        Image(systemName: "bolt.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppleTheme.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Điểm Nhấn Ôn Tập Cốt Lõi")
                            .font(.headline)
                            .foregroundStyle(AppleTheme.primaryText)

                        Text("Các khái niệm định nghĩa và ý chính được chắt lọc ngắn gọn.")
                            .font(.footnote)
                            .foregroundStyle(AppleTheme.secondaryText)
                    }

                    Spacer()
                }
                .appleCardStyle(padding: 12)

                if summaryPoints.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundStyle(AppleTheme.secondaryText.opacity(0.5))
                        Text("Không có nội dung tóm tắt.")
                            .font(.subheadline)
                            .foregroundStyle(AppleTheme.secondaryText)
                    }
                    .padding(.vertical, 40)
                } else {
                    // Summary Cards
                    ForEach(Array(summaryPoints.enumerated()), id: \.offset) { index, point in
                        AppleSummaryCard(
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
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
    }
}

private struct AppleSummaryCard: View {
    let index: Int
    let text: String
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Number Indicator Pill
                HStack(spacing: 4) {
                    Text("\(index)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppleTheme.blue)
                        .frame(width: 18, height: 18)
                        .background(AppleTheme.blue.opacity(0.12))
                        .clipShape(Circle())

                    Text("Ý CỐT LÕI")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppleTheme.secondaryText)
                }

                Spacer()

                // Copy Button
                Button(action: onCopy) {
                    HStack(spacing: 3) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.caption2)
                        Text(isCopied ? "Đã chép" : "Chép")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(isCopied ? AppleTheme.green : AppleTheme.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isCopied ? AppleTheme.green.opacity(0.1) : AppleTheme.blue.opacity(0.08))
                    .clipShape(Capsule())
                }
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppleTheme.primaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appleCardStyle(padding: 14)
    }
}
