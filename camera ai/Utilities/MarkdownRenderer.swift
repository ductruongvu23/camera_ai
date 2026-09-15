//
//  MarkdownRenderer.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI

/// Converts Markdown text to styled SwiftUI AttributedString.
struct MarkdownRenderer {

    /// Render markdown string to an AttributedString with proper styling.
    static func render(_ markdown: String) -> AttributedString {
        // Try using Apple's built-in Markdown parser first
        do {
            let result = try AttributedString(markdown: markdown, options: .init(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            ))
            return result
        } catch {
            // Fallback: return plain text
            return AttributedString(markdown)
        }
    }

    /// Render with full markdown support including headings
    static func renderFull(_ markdown: String) -> [MarkdownBlock] {
        let lines = markdown.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                blocks.append(.spacer)
            } else if trimmed.hasPrefix("### ") {
                let content = String(trimmed.dropFirst(4))
                blocks.append(.heading3(content))
            } else if trimmed.hasPrefix("## ") {
                let content = String(trimmed.dropFirst(3))
                blocks.append(.heading2(content))
            } else if trimmed.hasPrefix("# ") {
                let content = String(trimmed.dropFirst(2))
                blocks.append(.heading1(content))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                let content = String(trimmed.dropFirst(2))
                blocks.append(.bullet(content))
            } else if let _ = trimmed.first, trimmed.first!.isNumber,
                      trimmed.contains(". ") {
                let parts = trimmed.split(separator: ".", maxSplits: 1)
                if parts.count == 2 {
                    let content = String(parts[1]).trimmingCharacters(in: .whitespaces)
                    blocks.append(.numbered(content))
                } else {
                    blocks.append(.body(trimmed))
                }
            } else {
                blocks.append(.body(trimmed))
            }
        }

        return blocks
    }
}

/// Represents a parsed Markdown block element.
enum MarkdownBlock: Identifiable {
    case heading1(String)
    case heading2(String)
    case heading3(String)
    case bullet(String)
    case numbered(String)
    case body(String)
    case spacer

    var id: String {
        switch self {
        case .heading1(let t): return "h1_\(t.hashValue)"
        case .heading2(let t): return "h2_\(t.hashValue)"
        case .heading3(let t): return "h3_\(t.hashValue)"
        case .bullet(let t): return "bl_\(t.hashValue)"
        case .numbered(let t): return "nm_\(t.hashValue)"
        case .body(let t): return "bd_\(t.hashValue)"
        case .spacer: return "sp_\(UUID().uuidString)"
        }
    }
}

/// SwiftUI View to render a single MarkdownBlock.
struct MarkdownBlockView: View {
    let block: MarkdownBlock

    var body: some View {
        switch block {
        case .heading1(let text):
            Text(text)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .padding(.top, 12)
                .padding(.bottom, 4)

        case .heading2(let text):
            Text(text)
                .font(.title3.bold())
                .foregroundStyle(Color(hex: "A29BFE"))
                .padding(.top, 8)
                .padding(.bottom, 2)

        case .heading3(let text):
            Text(text)
                .font(.headline)
                .foregroundStyle(Color(hex: "74B9FF"))
                .padding(.top, 6)

        case .bullet(let text):
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Color(hex: "6C5CE7"))
                    .frame(width: 6, height: 6)
                    .padding(.top, 7)
                Text(text)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.leading, 12)

        case .numbered(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.body.bold())
                    .foregroundStyle(Color(hex: "00CEC9"))
                Text(text)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.leading, 12)

        case .body(let text):
            Text(text)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.vertical, 1)

        case .spacer:
            Spacer()
                .frame(height: 8)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
