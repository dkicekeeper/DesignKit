//
//  Showcase.swift
//  DesignKit Gallery
//
//  Small layout helpers shared by the showcase screens.
//

import SwiftUI
import DesignTokens

/// A vertically scrolling showcase page with consistent padding.
struct ShowcasePage<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                content
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A labelled group of specimens.
struct ShowcaseSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.h4)
                    .foregroundStyle(AppColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            content
        }
    }
}

/// Caption used to annotate a token's name/value.
struct TokenLabel: View {
    let name: String
    var value: String? = nil
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(name)
                .font(AppTypography.caption.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
            if let value {
                Text(value)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}
