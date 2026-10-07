//
//  IconSizesScreen.swift
//  DesignKit Gallery
//
//  The two icon size scales (1.13.0), named like AppSpacing: glyphs (AppIconSize.xs…xxl) and
//  tiles, icons with their own backing (AppIconSize.Tile.sm…xxxl). 2.0.0 moved 40 pt from the
//  tiles to the glyphs: too small for a tile's padding.
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
        ("xxl", AppIconSize.xxl, "avatar, a logo in a row (Tile.xs before 2.0)"),
    ]

    private let tiles: [(String, CGFloat, String)] = [
        ("sm", AppIconSize.Tile.sm, "the smallest tile: a content row's icon (Icon default)"),
        ("md", AppIconSize.Tile.md, "empty-state icon"),
        ("lg", AppIconSize.Tile.lg, "category coin in rows"),
        ("xl", AppIconSize.Tile.xl, "coin in grids, profile avatar"),
        ("xxl", AppIconSize.Tile.xxl, "ring around an xl tile"),
        ("xxxl", AppIconSize.Tile.xxxl, "hero icon"),
    ]

    var body: some View {
        ShowcasePage(title: "Icon Sizes") {
            ShowcaseSection(title: "Glyphs", subtitle: "AppIconSize.xs … xxl · a symbol on its own") {
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
            ShowcaseSection(title: "Tiles", subtitle: "AppIconSize.Tile.sm … xxxl · an icon with its own backing, from 44 pt") {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ForEach(tiles, id: \.0) { name, value, use in
                        sizeRow(name: "Tile.\(name)", value: value, use: use) {
                            Icon(source: .sfSymbol("creditcard.fill"),
                                     style: .circle(size: value, tint: .monochrome(AppColors.accent),
                                                    backgroundColor: AppColors.pale(AppColors.accent)))
                        }
                    }
                }
            }
            ShowcaseSection(title: "Changed in 2.0.0", subtitle: "Removed names and their values") {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach([("Tile.xs", "xxl", "40"), ("avatar", "xxl", "40"), ("categoryIcon", "Tile.lg", "52"),
                             ("mega", "Tile.xl", "64"), ("budgetRing", "Tile.xxl", "72"), ("ultra", "Tile.xxxl", "80")], id: \.0) { old, new, points in
                        HStack {
                            Text("AppIconSize.\(old)")
                                .strikethrough()
                                .foregroundStyle(AppColors.Text.secondary)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(AppColors.Text.tertiary)
                            Text("AppIconSize.\(new)")
                                .foregroundStyle(AppColors.Text.primary)
                            Text("\(points) pt")
                                .foregroundStyle(AppColors.Text.tertiary)
                        }
                        .font(AppTypography.bodySmall.monospaced())
                    }
                    Text("The 1.x xxl (44) and xxxl (48) are now Tile.sm and Tile.md; xxl is 40 pt since 2.0.0.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// The icon in a fixed-width column, then the token, its points and what it is for.
    private func sizeRow<IconContent: View>(name: String, value: CGFloat, use: String, @ViewBuilder icon: () -> IconContent) -> some View {
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
