//
//  BalancesSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Components ported from Tenra in 1.5.0: BalanceCard, SelectableBalanceCard, BalanceRow,
//  ProgressRingRow, ProgressRingTile, MetricCard, GradientOrbsBackground, PromptSheet.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Balances")
    struct Balances {
        @Test func balanceCard() async {
            await assertComponentSnapshot(
                BalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold",
                            amount: 1_284_500, currency: "KZT"),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func selectableBalanceCards() async {
            await assertComponentSnapshot(
                SelectableBalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold",
                                      amount: 1_284_500, currency: "KZT", isSelected: true) {},
                named: "selected"
            )
            await assertComponentSnapshot(
                SelectableBalanceCard(iconSource: .sfSymbol("banknote.fill"), title: "Cash",
                                      amount: 45_000, currency: "KZT", isSelected: false) {},
                named: "unselected"
            )
        }

        @Test func balanceRows() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    BalanceRow(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold",
                               amount: 1_284_500, currency: "KZT")
                    BalanceRow(iconSource: .sfSymbol("banknote.fill"), title: "Deposit",
                               amount: 2_000_000, currency: "KZT",
                               detail: .init("Posting: 30 Oct  ·  ", amount: 12_400),
                               trailingSystemImage: "lock.square.stack.fill")
                    BalanceRow(iconSource: .sfSymbol("building.columns.fill"), title: "Term deposit",
                               amount: 5_000_000, currency: "KZT",
                               detail: .init("Next posting: 1 Nov"),
                               trailingSystemImage: "lock.square.stack.fill")
                }
                .cardContentPadding()
                .cardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func progressRingRows() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ProgressRingRow(iconSource: .sfSymbol("fork.knife"), color: .orange, title: "Food",
                                    progress: LimitProgress(spent: 185_000, limit: 250_000), currency: "KZT")
                    ProgressRingRow(iconSource: .sfSymbol("bag.fill"), color: AppColors.accent, title: "Shopping",
                                    progress: LimitProgress(spent: 132_000, limit: 100_000), currency: "KZT")
                    ProgressRingRow(iconSource: .sfSymbol("car.fill"), color: .blue, title: "Transport",
                                    progress: nil, currency: "KZT", placeholder: "No budget set")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardContentPadding()
                .cardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func progressRingTiles() async {
            // One tile per snapshot: each has its own glass circle.
            await assertComponentSnapshot(
                ProgressRingTile(title: "Food", systemImage: "fork.knife", color: .orange,
                                 progress: LimitProgress(spent: 185_000, limit: 250_000)) {},
                named: "ring",
                width: 120
            )
            await assertComponentSnapshot(
                ProgressRingTile(title: "Shopping", systemImage: "bag.fill", color: AppColors.accent,
                                 progress: LimitProgress(spent: 132_000, limit: 100_000),
                                 isSelected: true) {},
                named: "selectedOver",
                width: 120
            )
            await assertComponentSnapshot(
                ProgressRingTile(title: "Transport", systemImage: "car.fill", color: .blue) {},
                named: "noRing",
                width: 120
            )
        }

        @Test func progressRingTileGrid() async {
            // Two tiles: each has its own glass circle, and glass reflects its neighbour.
            await assertComponentSnapshot(
                ProgressRingTileGrid(items: [
                    ProgressRingTileGridItem(id: "food", title: "Food", systemImage: "fork.knife", color: .orange,
                                             progress: LimitProgress(spent: 185_000, limit: 250_000),
                                             amount: 185_000, limit: 250_000),
                    ProgressRingTileGridItem(id: "home", title: "Home", systemImage: "house.fill", color: .green,
                                             amount: 210_000),
                ], currency: "KZT", columns: 2) { _ in },
                width: 260,
                appearances: [.light]
            )
        }

        @Test func metricCards() async {
            await assertComponentSnapshot(
                MetricCard(title: "Top category", subtitle: "Food took 42% of spending",
                           value: .amount(185_000, currency: "KZT"),
                           trend: .init(direction: .up, changePercent: 12.4, color: AppColors.destructive)) {
                    MiniDonut(slices: BalancesSample.slices)
                },
                named: "miniChart",
                appearances: [.light, .dark, .largeText]
            )
            await assertComponentSnapshot(
                MetricCard(title: "Savings rate", subtitle: "You kept a fifth of your income",
                           value: .text("21"), unit: "%",
                           trend: .init(direction: .up, changePercent: 3.2)),
                named: "noChart"
            )
            await assertComponentSnapshot(
                MetricCard(title: "Spending", subtitle: "Less than last month",
                           value: .amount(280_000, currency: "KZT"),
                           trend: .init(direction: .down, changePercent: -12.5, color: AppColors.success),
                           chartPlacement: .bottom) {
                    HeroBarPair(previous: 320_000, current: 280_000, color: AppColors.accent,
                                currency: "KZT", animatesOnAppear: false)
                },
                named: "bottomChart"
            )
        }

        @Test func gradientOrbsBackground() async {
            await assertComponentSnapshot(
                ZStack {
                    GradientOrbsBackground([
                        .init(color: .orange, weight: 1.0),
                        .init(color: AppColors.accent, weight: 0.6),
                        .init(color: .pink, weight: 0.4),
                    ])
                    .clipShape(.rect(cornerRadius: AppRadius.xl))

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("This month").font(AppTypography.bodySmall).foregroundStyle(AppColors.textSecondary)
                        FormattedAmountText(amount: 921_300, currency: "KZT",
                                            fontSize: AppTypography.h2, fontWeight: .bold,
                                            color: AppColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.lg)
                    .cardStyle()
                }
                .frame(height: 200)
            )
        }

        @Test func promptSheet() async {
            await assertComponentSnapshot(
                PromptSheet(
                    systemImage: "sparkles",
                    title: "Enjoying the app?",
                    message: "Your answer helps us decide what to improve next.",
                    primaryTitle: "Love it!",
                    secondaryTitle: "Not really",
                    onPrimary: {},
                    onSecondary: {}
                )
                .frame(height: 340)
            )
        }
    }
}

private enum BalancesSample {
    static let slices: [DonutSlice] = [
        DonutSlice(id: "food", amount: 42_000, color: AppColors.accent, label: "Food", percentage: 42),
        DonutSlice(id: "rent", amount: 30_000, color: AppColors.success, label: "Rent", percentage: 30),
        DonutSlice(id: "fun", amount: 18_000, color: AppColors.warning, label: "Fun", percentage: 18),
        DonutSlice(id: "misc", amount: 10_000, color: AppColors.transfer, label: "Misc", percentage: 10),
    ]
}
