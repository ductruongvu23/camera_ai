//
//  MindMapTabView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//  Redesigned following Apple Human Interface Guidelines (Apple Design System)
//

import SwiftUI

enum MindMapViewMode: String, CaseIterable {
    case tree = "Sơ Đồ Cây"
    case outline = "Danh Sách Thẻ"

    var icon: String {
        switch self {
        case .tree: return "point.3.connected.trianglepath.dotted"
        case .outline: return "list.bullet.indent"
        }
    }
}

/// Interactive Mind Map view designed with Apple Freeform aesthetics
struct MindMapTabView: View {
    let rootNode: MindMapNode

    @State private var viewMode: MindMapViewMode = .tree
    @State private var zoomScale: CGFloat = 1.0
    @State private var collapsedNodeIds: Set<String> = []
    @State private var copyToastMessage: String?
    @State private var showShareSheet: Bool = false
    @State private var shareItems: [Any] = []

    // Apple HIG refined palette for branches
    private let branchColors: [Color] = [
        AppleTheme.blue,
        AppleTheme.indigo,
        AppleTheme.teal,
        AppleTheme.orange,
        AppleTheme.green,
        AppleTheme.purple
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Apple Native Control Bar
            AppleMindMapControlBar(
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
                    AppleMindMapCanvasView(
                        rootNode: rootNode,
                        branchColors: branchColors,
                        zoomScale: $zoomScale,
                        collapsedNodeIds: $collapsedNodeIds,
                        onToggleCollapse: toggleCollapse
                    )
                } else {
                    AppleMindMapOutlineView(
                        rootNode: rootNode,
                        branchColors: branchColors,
                        collapsedNodeIds: $collapsedNodeIds,
                        onToggleCollapse: toggleCollapse
                    )
                }

                // Apple-style Toast Notification
                if let toast = copyToastMessage {
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
        showToast("Đã sao chép sơ đồ tư duy vào bộ nhớ tạm!")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                copyToastMessage = nil
            }
        }
    }
}

// MARK: - Apple Control Bar

private struct AppleMindMapControlBar: View {
    @Binding var viewMode: MindMapViewMode
    @Binding var zoomScale: CGFloat
    let onCopyOutline: () -> Void
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Native Apple Segmented Picker
            Picker("Chế độ xem", selection: $viewMode) {
                ForEach(MindMapViewMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 220)

            Spacer()

            if viewMode == .tree {
                // Apple Zoom Controls
                HStack(spacing: 2) {
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            zoomScale = max(0.6, zoomScale - 0.15)
                        }
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(AppleTheme.primaryText)
                            .frame(width: 28, height: 28)
                    }

                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            zoomScale = 1.0
                        }
                    } label: {
                        Text("\(Int(zoomScale * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppleTheme.blue)
                            .frame(minWidth: 32)
                    }

                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            zoomScale = min(1.8, zoomScale + 0.15)
                        }
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(AppleTheme.primaryText)
                            .frame(width: 28, height: 28)
                    }
                }
                .padding(.horizontal, 4)
                .background(AppleTheme.secondaryBackground)
                .clipShape(Capsule())
            }

            // Copy Button
            Button(action: onCopyOutline) {
                Image(systemName: "doc.on.doc")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppleTheme.blue)
                    .frame(width: 30, height: 30)
                    .background(AppleTheme.secondaryBackground)
                    .clipShape(Circle())
            }

            // Share Button
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppleTheme.blue)
                    .frame(width: 30, height: 30)
                    .background(AppleTheme.secondaryBackground)
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Tree Canvas View

private struct AppleMindMapCanvasView: View {
    let rootNode: MindMapNode
    let branchColors: [Color]
    @Binding var zoomScale: CGFloat
    @Binding var collapsedNodeIds: Set<String>
    let onToggleCollapse: (String) -> Void

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            HStack(alignment: .center, spacing: 44) {
                // Root Node Card
                VStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppleTheme.blue)

                    Text(rootNode.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppleTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 160)

                    Text("CHỦ ĐỀ TRUNG TÂM")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(AppleTheme.secondaryText)
                        .tracking(1)
                }
                .appleCardStyle(padding: 18)
                .shadow(color: AppleTheme.blue.opacity(0.15), radius: 10, y: 4)

                // Branches Column
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(Array(rootNode.children.enumerated()), id: \.element.id) { index, branch in
                        let color = branchColors[index % branchColors.count]
                        let isCollapsed = collapsedNodeIds.contains(branch.id)

                        HStack(alignment: .center, spacing: 28) {
                            // Branch Node Card
                            Button {
                                onToggleCollapse(branch.id)
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 9, height: 9)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(branch.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppleTheme.primaryText)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: 180, alignment: .leading)

                                        if let details = branch.details, !details.isEmpty {
                                            Text(details)
                                                .font(.caption2)
                                                .foregroundStyle(AppleTheme.secondaryText)
                                                .lineLimit(2)
                                                .frame(maxWidth: 180, alignment: .leading)
                                        }
                                    }

                                    if !branch.children.isEmpty {
                                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                                            .font(.caption2.bold())
                                            .foregroundStyle(color)
                                    }
                                }
                                .appleCardStyle(padding: 12)
                            }
                            .buttonStyle(.plain)

                            // Leaf Nodes
                            if !isCollapsed && !branch.children.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(branch.children) { child in
                                        HStack(spacing: 8) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(color)
                                                .frame(width: 3, height: 14)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(child.title)
                                                    .font(.caption.weight(.medium))
                                                    .foregroundStyle(AppleTheme.primaryText)
                                                    .lineLimit(3)
                                                    .frame(maxWidth: 200, alignment: .leading)

                                                if let details = child.details, !details.isEmpty {
                                                    Text(details)
                                                        .font(.system(size: 10))
                                                        .foregroundStyle(AppleTheme.secondaryText)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(AppleTheme.secondaryBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(AppleTheme.separator.opacity(0.2), lineWidth: 0.5)
                                        )
                                    }
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .leading)))
                            }
                        }
                    }
                }
            }
            .padding(36)
            .scaleEffect(zoomScale, anchor: .topLeading)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: zoomScale)
        }
        .background(
            ZStack {
                AppleTheme.background
                // Subtle dot grid background pattern
                Canvas { context, size in
                    let dotSpacing: CGFloat = 24
                    for x in stride(from: 0, to: size.width, by: dotSpacing) {
                        for y in stride(from: 0, to: size.height, by: dotSpacing) {
                            let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                            context.fill(Path(ellipseIn: rect), with: .color(AppleTheme.separator.opacity(0.25)))
                        }
                    }
                }
            }
        )
    }
}

// MARK: - Outline View

private struct AppleMindMapOutlineView: View {
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
                            .fill(AppleTheme.blue.opacity(0.12))
                            .frame(width: 40, height: 40)

                        Image(systemName: "brain.head.profile")
                            .font(.body.weight(.bold))
                            .foregroundStyle(AppleTheme.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("CHỦ ĐỀ TRUNG TÂM")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(AppleTheme.blue)
                            .tracking(1)

                        Text(rootNode.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppleTheme.primaryText)
                    }
                    Spacer()
                }
                .appleCardStyle(padding: 14)

                // Branch Cards
                ForEach(Array(rootNode.children.enumerated()), id: \.element.id) { index, branch in
                    let color = branchColors[index % branchColors.count]
                    let isCollapsed = collapsedNodeIds.contains(branch.id)

                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            onToggleCollapse(branch.id)
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 10, height: 10)

                                Text(branch.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppleTheme.primaryText)

                                Spacer()

                                if !branch.children.isEmpty {
                                    Text("\(branch.children.count) ý")
                                        .font(.caption2.bold())
                                        .foregroundStyle(color)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(color.opacity(0.12))
                                        .clipShape(Capsule())

                                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                                        .font(.caption2.bold())
                                        .foregroundStyle(AppleTheme.secondaryText)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        if let details = branch.details, !details.isEmpty {
                            Text(details)
                                .font(.caption)
                                .foregroundStyle(AppleTheme.secondaryText)
                                .padding(.leading, 20)
                        }

                        if !isCollapsed && !branch.children.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(branch.children) { child in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .font(.caption.bold())
                                            .foregroundStyle(color)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(child.title)
                                                .font(.caption)
                                                .foregroundStyle(AppleTheme.primaryText)

                                            if let details = child.details, !details.isEmpty {
                                                Text(details)
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(AppleTheme.secondaryText)
                                            }
                                        }
                                    }
                                    .padding(.leading, 12)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .appleCardStyle(padding: 14)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
    }
}

// Activity View Controller
private struct ActivityViewControllerRepresentable: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
