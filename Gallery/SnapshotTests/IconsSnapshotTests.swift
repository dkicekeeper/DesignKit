//
//  IconsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  IconView styles, the brand-logo fallback (the Gallery sets no logo loader) and the
//  packed circles of account icons.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Icons")
    struct Icons {
        @Test func iconStyles() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    HStack(spacing: AppSpacing.lg) {
                        IconView(
                            source: .sfSymbol("fork.knife"),
                            style: .categoryIcon(size: AppIconSize.xxl, backgroundColor: AppColors.accent.opacity(0.15))
                        )
                        IconView(
                            source: .sfSymbol("heart.fill"),
                            style: .circle(
                                size: AppIconSize.xxl,
                                tint: .monochrome(AppColors.destructive),
                                backgroundColor: AppColors.destructive.opacity(0.15)
                            )
                        )
                        IconView(
                            source: .sfSymbol("bolt.fill"),
                            style: .roundedSquare(
                                size: AppIconSize.xxl,
                                tint: .monochrome(AppColors.warning),
                                backgroundColor: AppColors.warning.opacity(0.15)
                            )
                        )
                        IconView(source: nil, style: .placeholder(size: AppIconSize.xxl))
                    }
                    HStack(spacing: AppSpacing.lg) {
                        IconView(
                            source: .sfSymbol("creditcard.fill"),
                            style: .glassHero(size: AppIconSize.xxl, tint: .monochrome(AppColors.accent))
                        )
                        IconView(source: .sfSymbol("cart.fill"), size: AppIconSize.xl)
                        IconView(source: .brandService("netflix"), style: .serviceLogo())
                        BrandLogoView(brandName: "Kaspi", size: AppIconSize.xl)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }

        @Test func packedCircles() async {
            await assertComponentSnapshot(
                PackedCircleIconsView(items: [
                    PackedCircleItem(id: "1", iconSource: .sfSymbol("creditcard.fill"), amount: 1_250_000, tint: AppColors.accent),
                    PackedCircleItem(id: "2", iconSource: .sfSymbol("banknote.fill"), amount: 480_000, tint: AppColors.success),
                    PackedCircleItem(id: "3", iconSource: .sfSymbol("wallet.bifold.fill"), amount: 220_000, tint: AppColors.warning),
                    PackedCircleItem(id: "4", iconSource: .sfSymbol("bitcoinsign.circle.fill"), amount: 90_000, tint: AppColors.transfer),
                ])
                .frame(maxWidth: .infinity)
            )
        }
    }
}
