//
//  SpacingScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens

struct SpacingScreen: View {
    private let spacings: [(String, CGFloat)] = [
        ("xxs", AppSpacing.xxs), ("xs", AppSpacing.xs), ("sm", AppSpacing.sm),
        ("md", AppSpacing.md), ("lg", AppSpacing.lg), ("xl", AppSpacing.xl),
        ("xxl", AppSpacing.xxl), ("xxxl", AppSpacing.xxxl),
    ]
    private let radii: [(String, CGFloat)] = [
        ("xs", AppRadius.xs), ("md", AppRadius.md), ("lg", AppRadius.lg), ("xl", AppRadius.xl),
    ]

    var body: some View {
        ShowcasePage(title: "Spacing & Radius") {
            ShowcaseSection(title: "Spacing", subtitle: "4pt grid") {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(spacings, id: \.0) { name, value in
                        HStack(spacing: AppSpacing.md) {
                            Text(name)
                                .font(AppTypography.caption.weight(.medium))
                                .frame(width: 44, alignment: .leading)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppColors.accent)
                                .frame(width: value, height: 16)
                            Text("\(Int(value))pt")
                                .font(AppTypography.caption2)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
            ShowcaseSection(title: "Corner radius") {
                HStack(spacing: AppSpacing.md) {
                    ForEach(radii, id: \.0) { name, value in
                        VStack(spacing: AppSpacing.xs) {
                            RoundedRectangle(cornerRadius: value)
                                .fill(AppColors.accent.opacity(0.18))
                                .overlay(RoundedRectangle(cornerRadius: value).strokeBorder(AppColors.accent))
                                .frame(width: 64, height: 64)
                            TokenLabel(name: name, value: "\(Int(value))")
                        }
                    }
                }
            }
        }
    }
}

#Preview { NavigationStack { SpacingScreen() } }
