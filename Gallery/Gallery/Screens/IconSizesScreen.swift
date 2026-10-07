//
//  IconSizesScreen.swift
//  DesignKit Gallery
//
//  The two icon size scales (1.13.0), named like AppSpacing: glyphs (AppIconSize.xs…xl) and
//  tiles, icons with their own backing (AppIconSize.Tile.xs…xxxl).
//

import SwiftUI
import DesignTokens
import DesignSupport

struct IconSizesScreen: View {
    private let glyphs: [(String, CGFloat, String)] = [
        ("xs", AppIconSize.xs, "a glyph at caption size"),
        ("sm", AppIconSize.sm, "inline, in text"),
        ("md", AppIconSize.md, "toolbar, settings rows"),
        ("lg", AppIconSize.lg, "emphasized, form rows"),
        ("xl", AppIconSize.xl, "large glyphs, logos in rows"),
    ]

    private let tiles: [(String, CGFloat, String)] = [
        ("xs", AppIconSize.Tile.xs, "avatar, small tile"),
        ("sm", AppIconSize.Tile.sm, "a content row's icon (IconView default)"),
        ("md", AppIconSize.Tile.md, "empty-state icon"),
        ("lg", AppIconSize.Tile.lg, "category coin in rows"),
        ("xl", AppIconSize.Tile.xl, "coin in grids, profile avatar"),
        ("xxl", AppIconSize.Tile.xxl, "ring around an xl tile"),
        ("xxxl", AppIconSize.Tile.xxxl, "hero icon"),
    ]

    var body: some View {
        ShowcasePage(title: "Icon Sizes") {
            ShowcaseSection(title: "Glyphs", subtitle: "AppIconSize.xs … xl · a symbol on its own") {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ForEach(glyphs, id: \.0) { name, value, use in
                        sizeRow(name: "AppIconSize.\(name)", value: value, use: use) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: value))
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                }
            }
            ShowcaseSection(title: "Tiles", subtitle: "AppIconSize.Tile.xs … xxxl · an icon with its own backing") {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ForEach(tiles, id: \.0) { name, value, use in
                        sizeRow(name: "Tile.\(name)", value: value, use: use) {
                            IconView(source: .sfSymbol("creditcard.fill"),
                                     style: .circle(size: value, tint: .monochrome(AppColors.accent),
                                                    backgroundColor: AppColors.pale(AppColors.accent)))
                        }
                    }
                }
            }
            ShowcaseSection(title: "Renamed in 1.13.0", subtitle: "Same values; Xcode's fix-it renames them") {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach([("avatar", "Tile.xs"), ("xxl", "Tile.sm"), ("xxxl", "Tile.md"), ("categoryIcon", "Tile.lg"),
                             ("mega", "Tile.xl"), ("budgetRing", "Tile.xxl"), ("ultra", "Tile.xxxl")], id: \.0) { old, new in
                        HStack {
                            Text("AppIconSize.\(old)")
                                .strikethrough()
                                .foregroundStyle(AppColors.textSecondary)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(AppColors.textTertiary)
                            Text("AppIconSize.\(new)")
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        .font(AppTypography.bodySmall.monospaced())
                    }
                }
            }
        }
    }

    /// The icon in a fixed-width column, then the token, its points and what it is for.
    private func sizeRow<Icon: View>(name: String, value: CGFloat, use: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: AppSpacing.lg) {
            icon()
                .frame(width: AppIconSize.Tile.xxxl, height: max(value, AppIconSize.lg))
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.sm) {
                    Text(name)
                        .font(AppTypography.bodySmall.weight(.semibold).monospaced())
                        .foregroundStyle(AppColors.textPrimary)
                    Text("\(Int(value)) pt")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Text(use)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

#Preview { NavigationStack { IconSizesScreen() } }
