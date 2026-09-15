//
//  PDFExportService.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import UIKit
import PDFKit

/// Service to generate beautifully styled PDF documents and slide presentations from scanned lecture notes.
final class PDFExportService {

    // MARK: - Export Formats
    enum ExportFormat {
        case documentA4       // A4 Document for printing & study notes
        case presentation16x9 // 16:9 Landscape Slides for presentation
    }

    /// Generates a PDF data object from a ScanSession.
    /// - Parameters:
    ///   - session: The processed scan session containing summary and formatted lecture.
    ///   - format: Document A4 or 16:9 Slide presentation.
    /// - Returns: PDF Data ready to save or share.
    static func generatePDF(from session: ScanSession, format: ExportFormat = .documentA4) -> Data {
        switch format {
        case .documentA4:
            return generateA4Document(from: session)
        case .presentation16x9:
            return generateSlidePresentation(from: session)
        }
    }

    // MARK: - A4 Study Document Generator

    private static func generateA4Document(from session: ScanSession) -> Data {
        // Standard A4: 595.2 x 841.8 points
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 40
        let contentWidth = pageWidth - (margin * 2)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            var currentPage = 1
            context.beginPage()

            var cursorY: CGFloat = margin

            // Draw Header Banner
            drawHeader(
                in: context.cgContext,
                title: "TÀI LIỆU TÓM TẮT & SỐ HÓA VĂN BẢN",
                subtitle: "Ngày tạo: \(formatDate(session.createdAt)) • Số lượng trang: \(session.images.count)",
                rect: CGRect(x: margin, y: cursorY, width: contentWidth, height: 60)
            )
            cursorY += 75

            // Draw Section 1: Summary Cards
            let summaryTitle = "⚡ I. TÓM TẮT CỐT LÕI (ÔN TẬP CẤP TỐC)"
            drawSectionTitle(summaryTitle, at: CGPoint(x: margin, y: cursorY), color: UIColor(red: 0.99, green: 0.47, blue: 0.66, alpha: 1.0))
            cursorY += 26

            for (index, point) in session.summaryPoints.enumerated() {
                let cardHeight = calculateTextHeight(
                    text: "\(index + 1). \(point)",
                    font: UIFont.systemFont(ofSize: 11, weight: .regular),
                    width: contentWidth - 24
                ) + 16

                if cursorY + cardHeight > pageHeight - margin - 30 {
                    drawFooter(page: currentPage, rect: pageRect, margin: margin)
                    currentPage += 1
                    context.beginPage()
                    cursorY = margin
                }

                drawSummaryBox(
                    index: index + 1,
                    text: point,
                    rect: CGRect(x: margin, y: cursorY, width: contentWidth, height: cardHeight)
                )
                cursorY += cardHeight + 8
            }

            cursorY += 15

            // Draw Section 2: Detailed Lecture
            if cursorY + 40 > pageHeight - margin - 30 {
                drawFooter(page: currentPage, rect: pageRect, margin: margin)
                currentPage += 1
                context.beginPage()
                cursorY = margin
            }

            let lectureTitle = "📚 II. BỐ CỤC BÀI GIẢNG CHI TIẾT"
            drawSectionTitle(lectureTitle, at: CGPoint(x: margin, y: cursorY), color: UIColor(red: 0.42, green: 0.36, blue: 0.91, alpha: 1.0))
            cursorY += 30

            // Render Markdown text lines
            let lines = session.formattedContent.components(separatedBy: "\n")
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    cursorY += 8
                    continue
                }

                let (font, textColor, indent, extraSpacing) = styleForMarkdownLine(trimmed)
                let textToDraw = cleanMarkdownPrefixes(trimmed)
                let lineHeight = calculateTextHeight(
                    text: textToDraw,
                    font: font,
                    width: contentWidth - indent
                )

                if cursorY + lineHeight > pageHeight - margin - 30 {
                    drawFooter(page: currentPage, rect: pageRect, margin: margin)
                    currentPage += 1
                    context.beginPage()
                    cursorY = margin
                }

                let textRect = CGRect(
                    x: margin + indent,
                    y: cursorY,
                    width: contentWidth - indent,
                    height: lineHeight
                )

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: textColor
                ]
                (textToDraw as NSString).draw(in: textRect, withAttributes: attrs)
                cursorY += lineHeight + extraSpacing
            }

            drawFooter(page: currentPage, rect: pageRect, margin: margin)
        }
    }

    // MARK: - 16:9 Slide Presentation Generator

    private static func generateSlidePresentation(from session: ScanSession) -> Data {
        // 16:9 Presentation: 960 x 540 points
        let slideWidth: CGFloat = 960
        let slideHeight: CGFloat = 540
        let slideRect = CGRect(x: 0, y: 0, width: slideWidth, height: slideHeight)
        let margin: CGFloat = 48

        let renderer = UIGraphicsPDFRenderer(bounds: slideRect)

        return renderer.pdfData { context in
            // Slide 1: Cover Slide
            context.beginPage()
            drawSlideBackground(rect: slideRect)

            let coverTitle = "TỔNG HỢP & TÓM TẮT BÀI GIẢNG"
            let coverTitleRect = CGRect(x: margin, y: 160, width: slideWidth - (margin * 2), height: 80)
            let coverTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 34, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            (coverTitle as NSString).draw(in: coverTitleRect, withAttributes: coverTitleAttrs)

            let coverSub = "Số hóa tự động từ \(session.images.count) trang văn bản • Ngày \(formatDate(session.createdAt))"
            let coverSubRect = CGRect(x: margin, y: 250, width: slideWidth - (margin * 2), height: 40)
            let coverSubAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor(red: 0.64, green: 0.61, blue: 1.0, alpha: 1.0)
            ]
            (coverSub as NSString).draw(in: coverSubRect, withAttributes: coverSubAttrs)

            // Slide 2..N: Summary Cards Slide
            if !session.summaryPoints.isEmpty {
                context.beginPage()
                drawSlideBackground(rect: slideRect)

                let sumSlideTitle = "⚡ Ý CỐT LÕI ÔN THI CẤP TỐC"
                drawSlideHeader(title: sumSlideTitle, rect: slideRect, margin: margin)

                var cardY: CGFloat = 110
                let cardWidth = slideWidth - (margin * 2)

                for (idx, pt) in session.summaryPoints.prefix(4).enumerated() {
                    let cardRect = CGRect(x: margin, y: cardY, width: cardWidth, height: 74)
                    drawSlideSummaryItem(index: idx + 1, text: pt, rect: cardRect)
                    cardY += 88
                }
            }

            // Slide 3+: Lecture Content Breakdown
            let sections = splitContentIntoSections(session.formattedContent)
            for (idx, section) in sections.enumerated() {
                context.beginPage()
                drawSlideBackground(rect: slideRect)

                let sectionTitle = "📚 PHẦN \(idx + 1): \(section.title)"
                drawSlideHeader(title: sectionTitle, rect: slideRect, margin: margin)

                let bodyRect = CGRect(x: margin, y: 120, width: slideWidth - (margin * 2), height: 360)
                let bodyAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                    .foregroundColor: UIColor(white: 0.9, alpha: 1.0)
                ]
                (section.body as NSString).draw(in: bodyRect, withAttributes: bodyAttrs)
            }
        }
    }

    // MARK: - Drawing Helpers

    private static func drawHeader(in ctx: CGContext, title: String, subtitle: String, rect: CGRect) {
        let bgPath = UIBezierPath(roundedRect: rect, cornerRadius: 8)
        UIColor(red: 0.42, green: 0.36, blue: 0.91, alpha: 0.12).setFill()
        bgPath.fill()

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(red: 0.42, green: 0.36, blue: 0.91, alpha: 1.0)
        ]
        (title as NSString).draw(at: CGPoint(x: rect.minX + 14, y: rect.minY + 12), withAttributes: titleAttrs)

        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        (subtitle as NSString).draw(at: CGPoint(x: rect.minX + 14, y: rect.minY + 36), withAttributes: subAttrs)
    }

    private static func drawSectionTitle(_ title: String, at point: CGPoint, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: color
        ]
        (title as NSString).draw(at: point, withAttributes: attrs)
    }

    private static func drawSummaryBox(index: Int, text: String, rect: CGRect) {
        let box = UIBezierPath(roundedRect: rect, cornerRadius: 6)
        UIColor(white: 0.96, alpha: 1.0).setFill()
        box.fill()
        UIColor(red: 0.42, green: 0.36, blue: 0.91, alpha: 0.25).setStroke()
        box.lineWidth = 1
        box.stroke()

        let badgeText = "Ý \(index): "
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: UIColor(red: 0.42, green: 0.36, blue: 0.91, alpha: 1.0)
        ]

        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.black
        ]

        let fullText = NSMutableAttributedString(string: badgeText, attributes: badgeAttrs)
        fullText.append(NSAttributedString(string: text, attributes: bodyAttrs))

        let textRect = CGRect(x: rect.minX + 10, y: rect.minY + 8, width: rect.width - 20, height: rect.height - 16)
        fullText.draw(in: textRect)
    }

    private static func drawFooter(page: Int, rect: CGRect, margin: CGFloat) {
        let footerText = "Trang \(page) • Xuất từ ứng dụng Tóm Tắt Bài Giảng"
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        let textSize = (footerText as NSString).size(withAttributes: footerAttrs)
        let footerX = (rect.width - textSize.width) / 2
        let footerY = rect.height - margin + 10
        (footerText as NSString).draw(at: CGPoint(x: footerX, y: footerY), withAttributes: footerAttrs)
    }

    private static func drawSlideBackground(rect: CGRect) {
        // Dark futuristic background for slides
        UIColor(red: 0.07, green: 0.06, blue: 0.13, alpha: 1.0).setFill()
        UIRectFill(rect)

        // Accent top bar
        let topBar = CGRect(x: 0, y: 0, width: rect.width, height: 6)
        UIColor(red: 0.42, green: 0.36, blue: 0.91, alpha: 1.0).setFill()
        UIRectFill(topBar)
    }

    private static func drawSlideHeader(title: String, rect: CGRect, margin: CGFloat) {
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        (title as NSString).draw(at: CGPoint(x: margin, y: 44), withAttributes: headerAttrs)

        // Subtle divider line
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: margin, y: 80))
        divider.addLine(to: CGPoint(x: rect.width - margin, y: 80))
        UIColor.white.withAlphaComponent(0.15).setStroke()
        divider.lineWidth = 1
        divider.stroke()
    }

    private static func drawSlideSummaryItem(index: Int, text: String, rect: CGRect) {
        let box = UIBezierPath(roundedRect: rect, cornerRadius: 12)
        UIColor(white: 1.0, alpha: 0.08).setFill()
        box.fill()
        UIColor(red: 0.42, green: 0.36, blue: 0.91, alpha: 0.4).setStroke()
        box.lineWidth = 1
        box.stroke()

        let badge = "● Ý \(index)"
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: UIColor(red: 0.0, green: 0.81, blue: 0.79, alpha: 1.0)
        ]
        (badge as NSString).draw(at: CGPoint(x: rect.minX + 16, y: rect.minY + 12), withAttributes: badgeAttrs)

        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor(white: 0.95, alpha: 1.0)
        ]
        let bodyRect = CGRect(x: rect.minX + 16, y: rect.minY + 34, width: rect.width - 32, height: rect.height - 40)
        (text as NSString).draw(in: bodyRect, withAttributes: bodyAttrs)
    }

    private static func styleForMarkdownLine(_ line: String) -> (UIFont, UIColor, CGFloat, CGFloat) {
        if line.hasPrefix("# ") {
            return (UIFont.systemFont(ofSize: 14, weight: .bold), UIColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1.0), 0, 8)
        } else if line.hasPrefix("## ") {
            return (UIFont.systemFont(ofSize: 12, weight: .bold), UIColor(red: 0.42, green: 0.36, blue: 0.91, alpha: 1.0), 4, 6)
        } else if line.hasPrefix("### ") {
            return (UIFont.systemFont(ofSize: 11, weight: .semibold), UIColor.darkGray, 8, 4)
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            return (UIFont.systemFont(ofSize: 10, weight: .regular), UIColor.black, 16, 3)
        } else {
            return (UIFont.systemFont(ofSize: 10, weight: .regular), UIColor(white: 0.15, alpha: 1.0), 4, 3)
        }
    }

    private static func cleanMarkdownPrefixes(_ text: String) -> String {
        var clean = text
        if clean.hasPrefix("### ") { clean = String(clean.dropFirst(4)) }
        else if clean.hasPrefix("## ") { clean = String(clean.dropFirst(3)) }
        else if clean.hasPrefix("# ") { clean = String(clean.dropFirst(2)) }
        else if clean.hasPrefix("- ") || clean.hasPrefix("* ") {
            clean = "• " + String(clean.dropFirst(2))
        }
        return clean.replacingOccurrences(of: "**", with: "")
    }

    private static func calculateTextHeight(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        let rect = (text as NSString).boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(rect.height)
    }

    private static func splitContentIntoSections(_ markdown: String) -> [(title: String, body: String)] {
        var sections: [(title: String, body: String)] = []
        let lines = markdown.components(separatedBy: "\n")
        var currentTitle = "Nội Dung Chính"
        var currentBodyLines: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") || trimmed.hasPrefix("## ") {
                if !currentBodyLines.isEmpty {
                    sections.append((title: currentTitle, body: currentBodyLines.joined(separator: "\n")))
                    currentBodyLines.removeAll()
                }
                currentTitle = cleanMarkdownPrefixes(trimmed)
            } else if !trimmed.isEmpty {
                currentBodyLines.append(cleanMarkdownPrefixes(trimmed))
            }
        }

        if !currentBodyLines.isEmpty {
            sections.append((title: currentTitle, body: currentBodyLines.joined(separator: "\n")))
        }

        return sections.isEmpty ? [(title: "Nội Dung Bài Giảng", body: markdown)] : sections
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}
