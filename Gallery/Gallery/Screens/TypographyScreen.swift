//
//  TypographyScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens

struct TypographyScreen: View {
    private let styles: [(String, Font, String)] = [
        ("h1 · 34 bold", AppTypography.h1, "Net worth"),
        ("h2 · 28 semibold", AppTypography.h2, "Accounts"),
        ("h3 · 24 semibold", AppTypography.h3, "This month"),
        ("h4 · 20 semibold", AppTypography.h4, "Recent activity"),
        ("bodyEmphasis · 18 semibold", AppTypography.bodyEmphasis, "Groceries"),
        ("body · 18 regular", AppTypography.body, "The quick brown fox jumps over"),
        ("bodySmall · 16 regular", AppTypography.bodySmall, "The quick brown fox jumps over"),
        ("caption · 14 regular", AppTypography.caption, "Yesterday at 14:32"),
        ("caption2 · 12 regular", AppTypography.caption2, "Updated just now"),
    ]

    var body: some View {
        ShowcasePage(title: "Typography") {
            ShowcaseSection(title: "Inter", subtitle: "Variable font, bundled in DesignKit") {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ForEach(styles, id: \.0) { name, font, sample in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sample)
                                .font(font)
                                .foregroundStyle(AppColors.textPrimary)
                            Text(name)
                                .font(AppTypography.caption2)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

#Preview { NavigationStack { TypographyScreen() } }
