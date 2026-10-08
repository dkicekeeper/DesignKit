//
//  BalancesSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Components ported from Tenra in 1.5.0: BalanceCard, SelectableBalanceCard, AmountRow (list:
//  BalanceRow and ProgressRingRow before 2.1), ProgressRingTile, MetricCard, PromptSheet.
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

        /// `AmountRow` in the list style with an amount (BalanceRow before 2.1, the same pixels).
        @Test func balanceRows() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    AmountRow("Kaspi Gold", leading: .icon(.sfSymbol("creditcard.fill")),
                              value: .amount(1_284_500, color: AppColors.Text.secondary),
                              currency: "KZT", style: .list)
                    AmountRow("Deposit", leading: .icon(.sfSymbol("banknote.fill")),
                              value: .amount(2_000_000, color: AppColors.Text.secondary),
                              currency: "KZT", style: .list,
                              detail: .init("Posting: 30 Oct  ·  ", amount: 12_400),
                              accessory: .systemImage("lock.square.stack.fill"))
                    AmountRow("Term deposit", leading: .icon(.sfSymbol("building.columns.fill")),
                              value: .amount(5_000_000, color: AppColors.Text.secondary),
                              currency: "KZT", style: .list,
                              detail: .init("Next posting: 1 Nov"),
                              accessory: .systemImage("lock.square.stack.fill"))
                }
                .cardContentPadding()
                .cardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// `AmountRow` limit rows (ProgressRingRow before 2.1). The row without a limit keeps the
        /// ring's room, so its icon and name line up with the others (2.1.0).
        @Test func progressRingRows() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    AmountRow("Food", leading: .tinted(.sfSymbol("fork.knife"), .orange),
                              value: .limit(LimitProgress(spent: 185_000, limit: 250_000)),
                              currency: "KZT", style: .list)
                    AmountRow("Shopping", leading: .tinted(.sfSymbol("bag.fill"), AppColors.accent),
                              value: .limit(LimitProgress(spent: 132_000, limit: 100_000)),
                              currency: "KZT", style: .list)
                    AmountRow("Transport", leading: .tinted(.sfSymbol("car.fill"), .blue),
                              value: .limit(nil, placeholder: "No budget set"),
                              currency: "KZT", style: .list)
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
                // 2.0.0: h2 title, body message and DSButtons, so the sheet is taller.
                .frame(height: 440)
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
