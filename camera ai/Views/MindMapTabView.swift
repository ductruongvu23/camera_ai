//
//  MindMapTabView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI

/// Mode for viewing the Mind Map
enum MindMapViewMode: String, CaseIterable {
    case tree = "Sơ Đồ Phân Nhánh"
    case outline = "Danh Sách Thẻ"

    var icon: String {
        switch self {
        case .tree: return "point.3.connected.trianglepath.dotted"
        case .outline: return "list.bullet.indent"
        }
    }
}

/// Interactive Mind Map view supporting visual tree diagram with smooth connections,
/// expandable branches, zoom/pan controls, outline view, and text outline export.
struct MindMapTabView: View {
    let rootNode: MindMapNode

    @State private var viewMode: MindMapViewMode = .tree
    @State private var zoomScale: CGFloat = 1.0
    @State private var collapsedNodeIds: Set<String> = []
    @State private var copyToastMessage: String?
    @State private var showShareSheet: Bool = false
    @State private var shareItems: [Any] = []

    // Palette for distinct branch themes
    private let branchColors: [Color] = [
        Color(hex: "00CEC9"), // Cyan
        Color(hex: "6C5CE7"), // Purple
        Color(hex: "FD79A8"), // Pink
        Color(hex: "FFA502"), // Amber / Orange
        Color(hex: "2ED573"), // Emerald
        Color(hex: "1E90FF")  // Royal Blue
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header controls: View mode switcher & quick actions
            MindMapControlBar(
                viewMode: $viewMode,
                zoomScale: $zoomScale,
                onCopyOutline: copyOutline,
                onShare: shareOutline
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)

            // Content Area based on selected mode
            ZStack {
                if viewMode == .tree {
                    MindMapTreeCanvasView(
                        rootNode: rootNode,
                        branchColors: branchColors,
                        zoomScale: $zoomScale,
                        collapsedNodeIds: $collapsedNodeIds,
                        onToggleCollapse: toggleCollapse
                    )
                } else {
                    MindMapOutlineListView(
                        rootNode: rootNode,
                        branchColors: branchColors,
                        collapsedNodeIds: $collapsedNodeIds,
                        onToggleCollapse: toggleCollapse
                    )
                }

                // Toast notification
                if let toast = copyToastMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: "00CEC9"))
                            Text(toast)
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "1F1D36").opacity(0.95))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(hex: "00CEC9").opacity(0.5), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
                        .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityViewControllerRepresentable(items: shareItems)
        }
    }

    private func toggleCollapse(_ id: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if collapsedNodeIds.contains(id) {
                collapsedNodeIds.remove(id)
            } else {
                collapsedNodeIds.insert(id)
            }
        }
    }

    private func copyOutline() {
        let text = MindMapBuilder.toOutlineText(rootNode)
        UIPasteboard.general.string = text
        showToast("Đã sao chép Sơ Đồ Tư Duy vào bộ nhớ tạm!")
    }

    private func shareOutline() {
        let text = MindMapBuilder.toOutlineText(rootNode)
        shareItems = [text]
        showShareSheet = true
    }

    private func showToast(_ message: String) {
        withAnimation {
            copyToastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation {
                copyToastMessage = nil
            }
        }
    }
}

// MARK: - Control Bar

private struct MindMapControlBar: View {
    @Binding var viewMode: MindMapViewMode
    @Binding var zoomScale: CGFloat
    let onCopyOutline: () -> Void
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // View Mode Picker
            HStack(spacing: 4) {
                ForEach(MindMapViewMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewMode = mode
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.caption2)
                            Text(mode.rawValue)
                                .font(.caption2.bold())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .foregroundStyle(viewMode == mode ? .white : .white.opacity(0.6))
                        .background(
                            viewMode == mode ?
                            Color(hex: "6C5CE7") : Color.clear
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(3)
            .background(Color.white.opacity(0.06))
            .clipShape(Capsule())

            Spacer()

            if viewMode == .tree {
                // Zoom Controls
                HStack(spacing: 4) {
                    Button {
                        withAnimation {
                            zoomScale = max(0.6, zoomScale - 0.15)
                        }
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }

                    Button {
                        withAnimation {
                            zoomScale = 1.0
                        }
                    } label: {
                        Text("\(Int(zoomScale * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "00CEC9"))
                            .frame(minWidth: 32)
                    }

                    Button {
                        withAnimation {
                            zoomScale = min(1.8, zoomScale + 0.15)
                        }
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, 2)
            }

            // Copy Outline Button
            Button(action: onCopyOutline) {
                Image(systemName: "doc.on.doc.fill")
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "00CEC9"))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: "00CEC9").opacity(0.15))
                    .clipShape(Circle())
            }

            // Share Button
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Tree Canvas View

private struct MindMapTreeCanvasView: View {
    let rootNode: MindMapNode
    let branchColors: [Color]
    @Binding var zoomScale: CGFloat
    @Binding var collapsedNodeIds: Set<String>
    let onToggleCollapse: (String) -> Void

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            HStack(alignment: .center, spacing: 50) {
                // Central Root Node
                MindMapRootNodeView(title: rootNode.title)

                // Branches Column
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(Array(rootNode.children.enumerated()), id: \.element.id) { index, branch in
                        let color = branchColors[index % branchColors.count]
                        MindMapBranchRowView(
                            branch: branch,
                            accentColor: color,
                            isCollapsed: collapsedNodeIds.contains(branch.id),
                            onToggleCollapse: { onToggleCollapse(branch.id) }
                        )
                    }
                }
            }
            .padding(40)
            .scaleEffect(zoomScale, anchor: .topLeading)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: zoomScale)
        }
        .background(
            ZStack {
                Color(hex: "0D0B1C")
                // Subtle dot grid background pattern
                Canvas { context, size in
                    let dotSpacing: CGFloat = 24
                    for x in stride(from: 0, to: size.width, by: dotSpacing) {
                        for y in stride(from: 0, to: size.height, by: dotSpacing) {
                            let rect = CGRect(x: x, y: y, width: 1.5, height: 1.5)
                            context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.04)))
                        }
                    }
                }
            }
        )
    }
}

// MARK: - Root Node View

private struct MindMapRootNodeView: View {
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(.headline, design: .rounded).bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 160)

            Text("CHỦ ĐỀ TRUNG TÂM")
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .tracking(1.2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [Color(hex: "6C5CE7"), Color(hex: "FD79A8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: Color(hex: "6C5CE7").opacity(0.5), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Branch Row View (Level 1 + Level 2)

private struct MindMapBranchRowView: View {
    let branch: MindMapNode
    let accentColor: Color
    let isCollapsed: Bool
    let onToggleCollapse: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 32) {
            // Level 1: Branch Node Card
            Button(action: onToggleCollapse) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(branch.title)
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: 180, alignment: .leading)

                        if let details = branch.details, !details.isEmpty {
                            Text(details)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.65))
                                .lineLimit(2)
                                .frame(maxWidth: 180, alignment: .leading)
                        }
                    }

                    if !branch.children.isEmpty {
                        Image(systemName: isCollapsed ? "chevron.right.circle.fill" : "chevron.down.circle.fill")
                            .font(.caption)
                            .foregroundStyle(accentColor)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(hex: "1F1D36").opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentColor.opacity(0.7), lineWidth: 1.2)
                )
                .shadow(color: accentColor.opacity(0.2), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            // Level 2: Children Leaf Nodes (if not collapsed)
            if !isCollapsed && !branch.children.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(branch.children) { child in
                        MindMapLeafNodeView(node: child, accentColor: accentColor)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .leading)))
            }
        }
    }
}

// MARK: - Leaf Node View (Level 2)

private struct MindMapLeafNodeView: View {
    let node: MindMapNode
    let accentColor: Color

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor.opacity(0.8))
                .frame(width: 3, height: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(node.title)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .frame(maxWidth: 220, alignment: .leading)

                if let details = node.details, !details.isEmpty {
                    Text(details)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.8)
        )
    }
}

// MARK: - Outline List View (Card Mode)

private struct MindMapOutlineListView: View {
    let rootNode: MindMapNode
    let branchColors: [Color]
    @Binding var collapsedNodeIds: Set<String>
    let onToggleCollapse: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Topic Card
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "6C5CE7"), Color(hex: "FD79A8")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("CHỦ ĐỀ TRUNG TÂM")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: "00CEC9"))
                            .tracking(1)

                        Text(rootNode.title)
                            .font(.system(.headline, design: .rounded).bold())
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color(hex: "1F1D36").opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hex: "6C5CE7").opacity(0.5), lineWidth: 1)
                )

                // Branch Cards
                ForEach(Array(rootNode.children.enumerated()), id: \.element.id) { index, branch in
                    let color = branchColors[index % branchColors.count]
                    let isCollapsed = collapsedNodeIds.contains(branch.id)

                    VStack(alignment: .leading, spacing: 10) {
                        // Branch Header Button
                        Button {
                            onToggleCollapse(branch.id)
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 10, height: 10)

                                Text(branch.title)
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundStyle(.white)

                                Spacer()

                                if !branch.children.isEmpty {
                                    Text("\(branch.children.count) ý")
                                        .font(.caption2.bold())
                                        .foregroundStyle(color)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(color.opacity(0.15))
                                        .clipShape(Capsule())

                                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        if let details = branch.details, !details.isEmpty {
                            Text(details)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.leading, 20)
                        }

                        // Branch Children
                        if !isCollapsed && !branch.children.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(branch.children) { child in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .font(.caption.bold())
                                            .foregroundStyle(color)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(child.title)
                                                .font(.system(.caption, design: .rounded).weight(.medium))
                                                .foregroundStyle(.white.opacity(0.9))

                                            if let details = child.details, !details.isEmpty {
                                                Text(details)
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.white.opacity(0.55))
                                            }
                                        }
                                    }
                                    .padding(.leading, 12)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Activity View Controller (Share Sheet)

private struct ActivityViewControllerRepresentable: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
