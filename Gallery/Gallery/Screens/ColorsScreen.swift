//
//  ColorsScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens

struct ColorsScreen: View {
    private let semantic: [(String, Color)] = [
        ("bgBase", AppColors.bgBase),
        ("bgCard", AppColors.bgCard),
        ("bgMuted", AppColors.bgMuted),
        ("textPrimary", AppColors.textPrimary),
        ("textSecondary", AppColors.textSecondary),
        ("textTertiary", AppColors.textTertiary),
        ("accent", AppColors.accent),
        ("destructive", AppColors.destructive),
        ("success", AppColors.success),
        ("warning", AppColors.warning),
    ]

    private let financial: [(String, Color)] = [
        ("income", AppColors.income),
        ("expense", AppColors.expense),
        ("transfer", AppColors.transfer),
        ("planned", AppColors.planned),
    ]

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: AppSpacing.md)]

    var body: some View {
        ShowcasePage(title: "Colors") {
            ShowcaseSection(title: "Semantic", subtitle: "Adaptive to light / dark") {
                grid(semantic)
            }
            ShowcaseSection(title: "Financial", subtitle: "Transaction-type tokens") {
                grid(financial)
            }
            ShowcaseSection(title: "Category palette", subtitle: "Deterministic hash → color") {
                grid(paletteSamples)
            }
        }
    }

    private var paletteSamples: [(String, Color)] {
        let names = ["Food", "Travel", "Bills", "Health", "Shopping", "Salary", "Gifts", "Home"]
        return names.map { ($0, CategoryColors.hexColor(for: $0)) }
    }

    private func grid(_ items: [(String, Color)]) -> some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
            ForEach(items, id: \.0) { name, color in
                VStack(spacing: AppSpacing.xs) {
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(color)
                        .frame(height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .strokeBorder(AppColors.textTertiary.opacity(0.2))
                        )
                    Text(name)
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

#Preview { NavigationStack { ColorsScreen() } }
