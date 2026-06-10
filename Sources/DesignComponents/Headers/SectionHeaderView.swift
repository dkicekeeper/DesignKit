//
//  SectionHeaderView.swift
//  Tenra
//
//  Unified section header component with consistent styling across the app
//  Replaces: SettingsSectionHeaderView, inline headers, category headers
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Unified section header component with 3 style variants
/// - `.default`: Standard section header (bodyEmphasis, primary color). Used in forms, date groups, cards.
/// - `.compact`: Small uppercase label (bodySmall, secondary color, with horizontal padding). Used in filters, pickers.
/// - `.large`: Page-level section title (h3, primary color, optional icon, with horizontal padding). Used in insights.
public struct SectionHeaderView: View {
    let title: String
    /// Optional SF Symbol name shown to the left of the title (accent color).
    /// Currently used only with `.large` style.
    var systemImage: String? = nil
    let style: Style

    public enum Style {
        /// Standard section header (bodyEmphasis, primary color)
        case `default`

        /// Small uppercase label with horizontal padding (bodySmall, secondary color)
        case compact

        /// Page-level section title with horizontal padding (h3, primary color, optional icon)
        case large
    }

    public init(_ title: String, systemImage: String? = nil, style: Style = .default) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
    }

    public var body: some View {
        switch style {
        case .default:
            defaultStyle
        case .compact:
            compactStyle
        case .large:
            largeStyle
        }
    }

    // MARK: - Style Variants

    private var defaultStyle: some View {
        Text(title)
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.textPrimary)
    }

    private var compactStyle: some View {
        Text(title)
            .font(AppTypography.bodySmall)
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .screenPadding()
    }

    private var largeStyle: some View {
        HStack(spacing: AppSpacing.md) {
            if let icon = systemImage {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.accent)
            }
            Text(title)
                .font(AppTypography.h3)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .screenPadding()
    }
}

// MARK: - Previews




