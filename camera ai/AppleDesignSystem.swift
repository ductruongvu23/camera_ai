//
//  AppleDesignSystem.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//  Reference: Apple Human Interface Guidelines & Apple Design System Catalog
//

import SwiftUI

/// Official Apple HIG Design Tokens & Helpers
enum AppleTheme {
    // MARK: - Semantic Colors (Adaptive Light & Dark Mode)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let secondaryBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let tertiaryBackground = Color(uiColor: .tertiarySystemGroupedBackground)

    static let primaryText = Color(uiColor: .label)
    static let secondaryText = Color(uiColor: .secondaryLabel)
    static let tertiaryText = Color(uiColor: .tertiaryLabel)
    static let separator = Color(uiColor: .separator)

    // MARK: - Apple System Palette
    static let blue = Color(uiColor: .systemBlue)
    static let indigo = Color(uiColor: .systemIndigo)
    static let purple = Color(uiColor: .systemPurple)
    static let teal = Color(uiColor: .systemTeal)
    static let mint = Color(uiColor: .systemMint)
    static let green = Color(uiColor: .systemGreen)
    static let orange = Color(uiColor: .systemOrange)
    static let red = Color(uiColor: .systemRed)

    // MARK: - Corner Radii
    static let cardRadius: CGFloat = 16
    static let smallRadius: CGFloat = 10
    static let buttonRadius: CGFloat = 14

    // MARK: - Apple Inset Grouped Card Modifier
    struct InsetCardModifier: ViewModifier {
        var padding: CGFloat = 16

        func body(content: Content) -> some View {
            content
                .padding(padding)
                .background(AppleTheme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppleTheme.cardRadius, style: .continuous)
                        .stroke(AppleTheme.separator.opacity(0.18), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }
}

extension View {
    /// Applies Apple HIG Inset Grouped card styling
    func appleCardStyle(padding: CGFloat = 16) -> some View {
        modifier(AppleTheme.InsetCardModifier(padding: padding))
    }
}
