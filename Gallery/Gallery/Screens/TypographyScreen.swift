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
            ShowcaseSection(title: "Numbers", subtitle: "AppTypography.numbers(_:) · proportional; .monospacedDigit() for counters") {
                HStack(alignment: .top, spacing: AppSpacing.xl) {
                    numberColumn("Amounts", font: AppTypography.numbers(AppTypography.h4))
                    numberColumn("Counters", font: AppTypography.h4.monospacedDigit())
                }
            }
            ShowcaseSection(title: ".fadeTruncation()", subtitle: "One line that fades out instead of \"…\"") {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Halyk Bank savings account for the summer trip")
                        .font(AppTypography.h4)
                        .fadeTruncation()
                    Text("Halyk Bank savings account for the summer trip")
                        .font(AppTypography.h4)
                        .lineLimit(1)
                    Text("Fits as it is")
                        .font(AppTypography.h4)
                        .fadeTruncation()
                }
                .frame(width: 240, alignment: .leading)
                .foregroundStyle(AppColors.Text.primary)
            }
        }
    }

    /// The same amounts in one style, aligned on the right.
    private func numberColumn(_ title: String, font: Font) -> some View {
        VStack(alignment: .trailing, spacing: AppSpacing.xs) {
            ForEach(["1 111 111", "8 888 888", "407 150"], id: \.self) { amount in
                Text(verbatim: amount).font(font)
            }
            Text(title)
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.textSecondary)
        }
        .foregroundStyle(AppColors.textPrimary)
    }
}

#Preview { NavigationStack { TypographyScreen() } }
