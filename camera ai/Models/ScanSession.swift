//
//  ScanSession.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI

/// Represents one complete scan session: multiple slide images → OCR → AI processing
struct ScanSession: Identifiable {
    let id = UUID()
    var images: [UIImage]
    var rawTexts: [String]           // OCR text per slide
    var mergedRawText: String        // All raw texts joined
    var formattedContent: String     // Markdown-formatted lecture content from Gemini
    var summaryPoints: [String]      // Key summary bullet points from Gemini
    var mindmap: MindMapNode?        // Mind Map tree structure from Gemini
    var createdAt: Date

    init(
        images: [UIImage] = [],
        rawTexts: [String] = [],
        mergedRawText: String = "",
        formattedContent: String = "",
        summaryPoints: [String] = [],
        mindmap: MindMapNode? = nil,
        createdAt: Date = .now
    ) {
        self.images = images
        self.rawTexts = rawTexts
        self.mergedRawText = mergedRawText
        self.formattedContent = formattedContent
        self.summaryPoints = summaryPoints
        self.mindmap = mindmap
        self.createdAt = createdAt
    }

    /// Returns the AI-generated mind map or automatically builds a fallback tree from formattedContent/summaryPoints
    var effectiveMindMap: MindMapNode {
        if let map = mindmap, !map.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !map.children.isEmpty {
            return map
        }
        return MindMapBuilder.buildFallback(formattedContent: formattedContent, summaryPoints: summaryPoints)
    }
}

/// A node in the hierarchical Mind Map tree
struct MindMapNode: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var title: String
    var details: String?
    var children: [MindMapNode]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case details
        case children
    }

    init(
        id: String = UUID().uuidString,
        title: String,
        details: String? = nil,
        children: [MindMapNode] = []
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.children = children
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.title = (try? container.decode(String.self, forKey: .title)) ?? "Ý chính"
        self.details = try? container.decode(String.self, forKey: .details)
        self.children = (try? container.decode([MindMapNode].self, forKey: .children)) ?? []
    }
}

/// Builder helper to generate MindMapNode fallback trees and text outlines
enum MindMapBuilder {
    /// Constructs a fallback MindMapNode tree by parsing Markdown headings and bullets
    static func buildFallback(formattedContent: String, summaryPoints: [String]) -> MindMapNode {
        let lines = formattedContent.components(separatedBy: .newlines)
        var rootTitle = "Sơ Đồ Tư Duy Bài Giảng"
        var branches: [MindMapNode] = []
        var currentBranch: MindMapNode? = nil

        // Look for main # Title
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") && !trimmed.hasPrefix("## ") {
                let extracted = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if !extracted.isEmpty {
                    rootTitle = extracted
                    break
                }
            }
        }

        // Parse ## Branches and list items
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("## ") {
                if let branch = currentBranch {
                    branches.append(branch)
                }
                let branchTitle = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                currentBranch = MindMapNode(title: branchTitle, children: [])
            } else if trimmed.hasPrefix("### ") {
                let subTitle = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                let subNode = MindMapNode(title: subTitle, children: [])
                if currentBranch != nil {
                    currentBranch?.children.append(subNode)
                } else {
                    currentBranch = MindMapNode(title: "Nội Dung Chính", children: [subNode])
                }
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                var bullet = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                // Clean bold markers
                bullet = bullet.replacingOccurrences(of: "**", with: "")
                if !bullet.isEmpty {
                    let leaf = MindMapNode(title: bullet)
                    if currentBranch != nil {
                        if currentBranch!.children.count < 6 {
                            currentBranch?.children.append(leaf)
                        }
                    } else {
                        currentBranch = MindMapNode(title: "Tổng Quan", children: [leaf])
                    }
                }
            }
        }

        if let branch = currentBranch {
            branches.append(branch)
        }

        // If markdown was sparse, fall back to summaryPoints
        if branches.isEmpty && !summaryPoints.isEmpty {
            for (idx, point) in summaryPoints.prefix(5).enumerated() {
                let parts = point.components(separatedBy: ":")
                if parts.count >= 2 {
                    let branchTitle = parts[0].trimmingCharacters(in: .whitespaces)
                    let leafDesc = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    branches.append(MindMapNode(
                        title: branchTitle,
                        children: [MindMapNode(title: leafDesc)]
                    ))
                } else {
                    branches.append(MindMapNode(
                        title: "Ý chính \(idx + 1)",
                        children: [MindMapNode(title: point)]
                    ))
                }
            }
        }

        if branches.isEmpty {
            branches = [
                MindMapNode(title: "Tổng Quan", children: [
                    MindMapNode(title: "Nội dung văn bản đã được ghi nhận")
                ])
            ]
        }

        return MindMapNode(title: rootTitle, children: branches)
    }

    /// Converts a MindMapNode into a clean indented text outline
    static func toOutlineText(_ node: MindMapNode, indent: Int = 0) -> String {
        let prefix = String(repeating: "  ", count: indent)
        let bullet = indent == 0 ? "🧠 " : (indent == 1 ? "📌 " : "• ")
        var result = "\(prefix)\(bullet)\(node.title)\n"
        if let details = node.details, !details.isEmpty {
            result += "\(prefix)   ↳ \(details)\n"
        }
        for child in node.children {
            result += toOutlineText(child, indent: indent + 1)
        }
        return result
    }
}

/// The JSON structure Gemini returns
struct GeminiResponse: Codable {
    let formattedLecture: String
    let summaryPoints: [String]
    let mindmap: MindMapNode?

    enum CodingKeys: String, CodingKey {
        case formattedLecture = "formatted_lecture"
        case summaryPoints = "summary_points"
        case mindmap = "mindmap"
    }

    init(
        formattedLecture: String,
        summaryPoints: [String],
        mindmap: MindMapNode? = nil
    ) {
        self.formattedLecture = formattedLecture
        self.summaryPoints = summaryPoints
        self.mindmap = mindmap
    }
}

/// Processing state machine
enum ProcessingState: Equatable {
    case idle
    case scanningOCR(current: Int, total: Int)
    case processingAI
    case completed
    case error(String)
}
