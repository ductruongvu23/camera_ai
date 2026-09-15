//
//  ResultTabView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//  Redesigned following Apple Human Interface Guidelines (Apple Design System)
//

import SwiftUI
import QuickLook

enum ResultTabSelection: Int, CaseIterable {
    case summary = 0
    case lecture = 1
    case mindmap = 2

    var title: String {
        switch self {
        case .summary: return "Tóm Tắt"
        case .lecture: return "Bài Giảng"
        case .mindmap: return "Sơ Đồ Tư Duy"
        }
    }

    var icon: String {
        switch self {
        case .summary: return "bolt.fill"
        case .lecture: return "book.fill"
        case .mindmap: return "brain.head.profile"
        }
    }
}

struct ResultTabView: View {
    let session: ScanSession
    let onDismiss: () -> Void

    @State private var selectedTab: ResultTabSelection = .summary
    @State private var showExportSheet: Bool = false
    @State private var shareItems: [Any] = []
    @State private var exportSuccessToast: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppleTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Fallback notice banner if 503 fallback was triggered
                    if session.isFallbackUsed {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(AppleTheme.orange)
                            Text("Model yêu cầu tạm thời quá tải 503. Đã tự động tóm tắt bằng \(session.modelUsed).")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppleTheme.primaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppleTheme.orange.opacity(0.12))
                    }

                    // Native Apple Segmented Control
                    Picker("Chế độ xem", selection: $selectedTab) {
                        ForEach(ResultTabSelection.allCases, id: \.self) { tab in
                            Label(tab.title, systemImage: tab.icon)
                                .tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    // Tab Pages
                    TabView(selection: $selectedTab) {
                        SummaryTabView(summaryPoints: session.summaryPoints)
                            .tag(ResultTabSelection.summary)

                        LectureTabView(formattedContent: session.formattedContent)
                            .tag(ResultTabSelection.lecture)

                        MindMapTabView(rootNode: session.effectiveMindMap)
                            .tag(ResultTabSelection.mindmap)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }

                // Apple-style Floating Toast
                if let toast = exportSuccessToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppleTheme.green)
                            Text(toast)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppleTheme.primaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppleTheme.separator.opacity(0.2), lineWidth: 0.5))
                        .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
                        .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Tài Liệu Đã Số Hóa")
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
                        .foregroundStyle(AppleTheme.blue)
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Export Menu (Apple HIG Menu style)
                    Menu {
                        Button {
                            exportPDF(format: .documentA4)
                        } label: {
                            Label("Xuất PDF In Ấn (A4)", systemImage: "doc.text")
                        }

                        Button {
                            exportPDF(format: .presentation16x9)
                        } label: {
                            Label("Xuất Slide PDF (16:9)", systemImage: "rectangle.inset.filled.and.person.filled")
                        }

                        Button {
                            exportMarkdownFile()
                        } label: {
                            Label("Xuất Tệp Markdown (.md)", systemImage: "arrow.down.doc")
                        }

                        Divider()

                        Button {
                            exportShareText()
                        } label: {
                            Label("Sao Chép Toàn Bộ Văn Bản", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "arrow.up.doc")
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppleTheme.blue)
                    }

                    // Share button
                    Button {
                        exportShareText()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppleTheme.blue)
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
            showToast(format == .documentA4 ? "Đã tạo file PDF A4 sẵn sàng lưu!" : "Đã tạo file Slide PDF 16:9!")
        } catch {
            print("Failed to save PDF: \(error)")
        }
    }

    private func exportMarkdownFile() {
        let mdContent = """
        # TÀI LIỆU BÀI GIẢNG ĐÃ SỐ HÓA
        *Mô hình xử lý: \(session.modelUsed) • Ngày: \(Date().formatted())*

        ## ⚡ TÓM TẮT CỐT LÕI (ÔN THI)
        \(session.summaryPoints.enumerated().map { "- \($1)" }.joined(separator: "\n"))

        ---

        ## 🧠 SƠ ĐỒ TƯ DUY (MIND MAP)
        \(MindMapBuilder.toOutlineText(session.effectiveMindMap))

        ---

        ## 📚 BỐ CỤC BÀI GIẢNG CHI TIẾT
        \(session.formattedContent)
        """

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Bai_Giang_So_Hoa.md")
        do {
            try mdContent.write(to: tempURL, atomically: true, encoding: .utf8)
            shareItems = [tempURL]
            showExportSheet = true
            showToast("Đã tạo tệp Markdown (.md) thành công!")
        } catch {
            print("Failed to save Markdown: \(error)")
        }
    }

    private func exportShareText() {
        let shareText = """
        === TÀI LIỆU BÀI GIẢNG ĐÃ SỐ HÓA ===

        ⚡ TÓM TẮT ÔN TẬP:
        \(session.summaryPoints.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n"))

        🧠 SƠ ĐỒ TƯ DUY:
        \(MindMapBuilder.toOutlineText(session.effectiveMindMap))

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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation {
                exportSuccessToast = nil
            }
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
