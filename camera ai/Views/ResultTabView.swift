//
//  ResultTabView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI
import QuickLook

enum ResultTabSelection: Int, CaseIterable {
    case summary = 0
    case lecture = 1

    var title: String {
        switch self {
        case .summary: return "⚡ Tóm Tắt Ôn Tập"
        case .lecture: return "📚 Bố Cục Bài Giảng"
        }
    }
}

struct ResultTabView: View {
    let session: ScanSession
    let onDismiss: () -> Void

    @State private var selectedTab: ResultTabSelection = .summary
    @State private var showExportSheet: Bool = false
    @State private var shareItems: [Any] = []
    @State private var isExporting: Bool = false
    @State private var exportSuccessToast: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Ambient Background
                LinearGradient(
                    colors: [Color(hex: "0D0B1C"), Color(hex: "171630"), Color(hex: "080711")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Export & Quick Action Bar
                    HStack(spacing: 10) {
                        // Export A4 PDF Button
                        ExportActionButton(
                            icon: "doc.text.fill",
                            title: "Xuất PDF (A4)",
                            color: Color(hex: "00CEC9")
                        ) {
                            exportPDF(format: .documentA4)
                        }

                        // Export 16:9 Presentation Slides
                        ExportActionButton(
                            icon: "rectangle.inset.filled.and.person.filled",
                            title: "Xuất Slide PDF",
                            color: Color(hex: "6C5CE7")
                        ) {
                            exportPDF(format: .presentation16x9)
                        }

                        // Export Markdown (.md)
                        ExportActionButton(
                            icon: "arrow.down.doc.fill",
                            title: "Tệp .MD",
                            color: Color(hex: "FD79A8")
                        ) {
                            exportMarkdownFile()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                    // Custom Segmented Control
                    HStack(spacing: 6) {
                        ForEach(ResultTabSelection.allCases, id: \.self) { tab in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    selectedTab = tab
                                }
                            } label: {
                                Text(tab.title)
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        ZStack {
                                            if selectedTab == tab {
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: tab == .summary ?
                                                                [Color(hex: "6C5CE7"), Color(hex: "FD79A8")] :
                                                                [Color(hex: "6C5CE7"), Color(hex: "00CEC9")],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .shadow(color: Color(hex: "6C5CE7").opacity(0.4), radius: 8, x: 0, y: 4)
                                            }
                                        }
                                    )
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    // Tab Pages
                    TabView(selection: $selectedTab) {
                        SummaryTabView(summaryPoints: session.summaryPoints)
                            .tag(ResultTabSelection.summary)

                        LectureTabView(formattedContent: session.formattedContent)
                            .tag(ResultTabSelection.lecture)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }

                // Toast Notification
                if let toast = exportSuccessToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: "00CEC9"))
                            Text(toast)
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color(hex: "1F1D36").opacity(0.95))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(hex: "00CEC9").opacity(0.5), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.3), radius: 10, y: 4)
                        .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Tài Liệu Số Hóa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Chụp mới")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "00CEC9"))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        exportShareText()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(items: shareItems)
            }
        }
    }

    // MARK: - Export Logic

    private func exportPDF(format: PDFExportService.ExportFormat) {
        let pdfData = PDFExportService.generatePDF(from: session, format: format)
        let tempFileName = format == .documentA4 ? "Tai_Lieu_Bai_Giang_A4.pdf" : "Slide_Bai_Giang_16x9.pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(tempFileName)

        do {
            try pdfData.write(to: tempURL)
            shareItems = [tempURL]
            showExportSheet = true
            showToast(format == .documentA4 ? "Đã tạo file PDF A4 sẵn sàng lưu/chia sẻ!" : "Đã tạo file Slide PDF 16:9!")
        } catch {
            print("Failed to save PDF: \(error)")
        }
    }

    private func exportMarkdownFile() {
        let mdContent = """
        # TÀI LIỆU BÀI GIẢNG ĐÃ SỐ HÓA
        *Ngày tạo: \(Date().formatted())*

        ## ⚡ TÓM TẮT CỐT LÕI (ÔN THI)
        \(session.summaryPoints.enumerated().map { "- \($1)" }.joined(separator: "\n"))

        ---

        ## 📚 BỐ CỤC BÀI GIẢNG CHI TIẾT
        \(session.formattedContent)
        """

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Bai_Giang_So_Hoa.md")
        do {
            try mdContent.write(to: tempURL, atomically: true, encoding: .utf8)
            shareItems = [tempURL]
            showExportSheet = true
            showToast("Đã tạo file Markdown (.md)!")
        } catch {
            print("Failed to save Markdown: \(error)")
        }
    }

    private func exportShareText() {
        let shareText = """
        === TÀI LIỆU BÀI GIẢNG ĐÃ SỐ HÓA ===

        ⚡ TÓM TẮT ÔN TẬP:
        \(session.summaryPoints.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n"))

        📚 NỘI DUNG CHI TIẾT:
        \(session.formattedContent)
        """
        shareItems = [shareText]
        showExportSheet = true
    }

    private func showToast(_ message: String) {
        withAnimation {
            exportSuccessToast = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                exportSuccessToast = nil
            }
        }
    }
}

// MARK: - Export Action Button

private struct ExportActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption2.bold())
            }
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(color.opacity(0.25), lineWidth: 1)
            )
        }
    }
}

// Helper for UIActivityViewController
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
