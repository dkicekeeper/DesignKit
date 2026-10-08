//
//  IconsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Icon styles, the brand-logo fallback (the Gallery sets no logo loader) and the
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
                        Icon(
                            source: .sfSymbol("fork.knife"),
                            style: .categoryIcon(size: AppIconSize.Tile.sm, backgroundColor: AppColors.accent.opacity(0.15))
                        )
                        Icon(
                            source: .sfSymbol("heart.fill"),
                            style: .circle(
                                size: AppIconSize.Tile.sm,
                                tint: .monochrome(AppColors.destructive),
                                backgroundColor: AppColors.destructive.opacity(0.15)
                            )
                        )
                        Icon(
                            source: .sfSymbol("bolt.fill"),
                            style: .roundedSquare(
                                size: AppIconSize.Tile.sm,
                                tint: .monochrome(AppColors.warning),
                                backgroundColor: AppColors.warning.opacity(0.15)
                            )
                        )
                        Icon(source: nil, style: .placeholder(size: AppIconSize.Tile.sm))
                    }
                    HStack(spacing: AppSpacing.lg) {
                        Icon(
                            source: .sfSymbol("creditcard.fill"),
                            style: .glassHero(size: AppIconSize.Tile.sm, tint: .monochrome(AppColors.accent))
                        )
                        Icon(source: .sfSymbol("cart.fill"), size: AppIconSize.xl)
                        Icon(source: .brandService("netflix"), style: .serviceLogo())
                        Icon(source: .brandService("Kaspi"), style: .roundedSquare(size: AppIconSize.xl))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }

        @Test func packedCircles() async {
            await assertComponentSnapshot(
                PackedCircleIcons(items: [
                    PackedCircleItem(id: "1", iconSource: .sfSymbol("creditcard.fill"), amount: 1_250_000, tint: AppColors.accent),
                    PackedCircleItem(id: "2", iconSource: .sfSymbol("banknote.fill"), amount: 480_000, tint: AppColors.success),
                    PackedCircleItem(id: "3", iconSource: .sfSymbol("wallet.bifold.fill"), amount: 220_000, tint: AppColors.warning),
                    PackedCircleItem(id: "4", iconSource: .sfSymbol("bitcoinsign.circle.fill"), amount: 90_000, tint: AppColors.transfer),
                ])
                .frame(maxWidth: .infinity)
            )
        }

        /// The look before 2.9.0, kept as `.flat`: the same picture as `packedCircles` was.
        @Test func packedCirclesFlat() async {
            await assertComponentSnapshot(
                PackedCircleIcons(items: [
                    PackedCircleItem(id: "1", iconSource: .sfSymbol("creditcard.fill"), amount: 1_250_000, tint: AppColors.accent),
                    PackedCircleItem(id: "2", iconSource: .sfSymbol("banknote.fill"), amount: 480_000, tint: AppColors.success),
                    PackedCircleItem(id: "3", iconSource: .sfSymbol("wallet.bifold.fill"), amount: 220_000, tint: AppColors.warning),
                    PackedCircleItem(id: "4", iconSource: .sfSymbol("bitcoinsign.circle.fill"), amount: 90_000, tint: AppColors.transfer),
                ], style: .flat)
                .frame(maxWidth: .infinity)
            )
        }

        /// Logos as the marbles' skin (invented brands from GalleryLogos; one on white), with an
        /// overflow marble, in a FinanceCard on Liquid Glass as on Tenra's home.
        @Test func packedCircleLogos() async {
            await assertComponentSnapshot(
                FinanceCard(title: "Subscriptions", isEmpty: false, emptyTitle: "", subtitle: "6 active") {
                    Text(verbatim: "18 470 ₸")
                } trailing: {
                    PackedCircleIcons(items: [
                        PackedCircleItem(id: "1", iconSource: .brandService("Reelio"), amount: 4_990),
                        PackedCircleItem(id: "2", iconSource: .brandService("Leafnote"), amount: 2_490),
                        PackedCircleItem(id: "3", iconSource: .brandService("Tunewave"), amount: 1_990),
                        PackedCircleItem(id: "4", iconSource: .brandService("Cloudy"), amount: 990),
                        PackedCircleItem(id: "5", iconSource: .brandService("Reelio"), amount: 490),
                        PackedCircleItem(id: "6", iconSource: .brandService("Cloudy"), amount: 290),
                    ], maxVisible: 4)
                }
            )
        }
    }
}
