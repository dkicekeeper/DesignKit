//
//  BalancesScreen.swift
//  DesignKit Gallery
//
//  Components of 1.5.0, ported from Tenra: balance cards and rows, progress-ring rows and
//  tiles, the metric card, the gradient orbs background and the prompt sheet.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct BalancesScreen: View {
    @State private var selectedWallet = "gold"
    @State private var selectedTile = "Food"
    @State private var showsPrompt = false

    private let slices: [DonutSlice] = [
        DonutSlice(id: "food", amount: 42_000, color: AppColors.accent, label: "Food", percentage: 42),
        DonutSlice(id: "rent", amount: 30_000, color: AppColors.success, label: "Rent", percentage: 30),
        DonutSlice(id: "fun", amount: 18_000, color: AppColors.warning, label: "Fun", percentage: 18),
        DonutSlice(id: "misc", amount: 10_000, color: AppColors.transfer, label: "Misc", percentage: 10),
    ]

    var body: some View {
        ShowcasePage(title: "Balances, Metrics & More") {
            balanceSection
            progressRingSection
            metricSection
            surfaceSection
        }
        .sheet(isPresented: $showsPrompt) {
            samplePrompt
        }
    }

    // MARK: Balances

    @ViewBuilder
    private var balanceSection: some View {
        ShowcaseSection(title: "BalanceCard", subtitle: "A named balance · sized for a carousel") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    BalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold",
                                amount: 1_284_500, currency: "KZT")
                    BalanceCard(iconSource: .sfSymbol("banknote.fill"), title: "Cash",
                                amount: 45_000, currency: "KZT")
                    BalanceCard(iconSource: .sfSymbol("dollarsign.circle.fill"), title: "Savings",
                                amount: 2_400, currency: "USD")
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }

        ShowcaseSection(title: "SelectableBalanceCard", subtitle: "Pick one · the selected card is outlined") {
            VStack(spacing: AppSpacing.md) {
                SelectableBalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold",
                                      amount: 1_284_500, currency: "KZT",
                                      isSelected: selectedWallet == "gold") { selectedWallet = "gold" }
                SelectableBalanceCard(iconSource: .sfSymbol("banknote.fill"), title: "Cash",
                                      amount: 45_000, currency: "KZT",
                                      isSelected: selectedWallet == "cash") { selectedWallet = "cash" }
            }
        }

        ShowcaseSection(title: "BalanceRow", subtitle: "A List row · caption with an amount · trailing mark") {
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
            .cardStyle()
        }
    }

    // MARK: Progress ring

    @ViewBuilder
    private var progressRingSection: some View {
        ShowcaseSection(title: "ProgressRingRow", subtitle: "A List row · within / over the limit · no limit") {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ProgressRingRow(iconSource: .sfSymbol("fork.knife"), color: .orange, title: "Food",
                                progress: LimitProgress(spent: 185_000, limit: 250_000), currency: "KZT")
                ProgressRingRow(iconSource: .sfSymbol("bag.fill"), color: AppColors.accent, title: "Shopping",
                                progress: LimitProgress(spent: 132_000, limit: 100_000), currency: "KZT")
                ProgressRingRow(iconSource: .sfSymbol("car.fill"), color: .blue, title: "Transport",
                                progress: nil, currency: "KZT", placeholder: "No budget set")
            }
            .cardContentPadding()
            .cardStyle()
        }

        ShowcaseSection(title: "ProgressRingTile", subtitle: "A picker grid tile · ring · selected · over") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppSpacing.lg) {
                tile("Food", "fork.knife", .orange, LimitProgress(spent: 185_000, limit: 250_000))
                tile("Shopping", "bag.fill", AppColors.accent, LimitProgress(spent: 132_000, limit: 100_000))
                tile("Transport", "car.fill", .blue, nil)
            }
        }

        ShowcaseSection(title: "ProgressRingTileGrid", subtitle: "Tiles with the amount and the limit under each") {
            ProgressRingTileGrid(items: gridItems, currency: "KZT") { item in
                selectedTile = item.title
            }
        }
    }

    private var gridItems: [ProgressRingTileGridItem] {
        [
            ProgressRingTileGridItem(id: "food", title: "Food", systemImage: "fork.knife", color: .orange,
                                     progress: LimitProgress(spent: 185_000, limit: 250_000),
                                     amount: 185_000, limit: 250_000),
            ProgressRingTileGridItem(id: "shopping", title: "Shopping", systemImage: "bag.fill", color: AppColors.accent,
                                     progress: LimitProgress(spent: 132_000, limit: 100_000),
                                     amount: 132_000, limit: 100_000),
            ProgressRingTileGridItem(id: "transport", title: "Transport", systemImage: "car.fill", color: .blue,
                                     amount: 24_500),
            ProgressRingTileGridItem(id: "home", title: "Home", systemImage: "house.fill", color: .green,
                                     amount: 210_000),
        ]
    }

    private func tile(_ title: String, _ symbol: String, _ color: Color, _ progress: LimitProgress?) -> some View {
        ProgressRingTile(title: title, systemImage: symbol, color: color, progress: progress,
                         isSelected: selectedTile == title) { selectedTile = title }
    }

    // MARK: Metric

    private var metricSection: some View {
        ShowcaseSection(title: "MetricCard", subtitle: "Mini chart on the trailing edge · none · full-width chart") {
            VStack(spacing: AppSpacing.md) {
                MetricCard(title: "Top category", subtitle: "Food took 42% of spending",
                           value: .amount(185_000, currency: "KZT"),
                           trend: .init(direction: .up, changePercent: 12.4, color: AppColors.destructive)) {
                    MiniDonut(slices: slices)
                }
                MetricCard(title: "Savings rate", subtitle: "You kept a fifth of your income",
                           value: .text("21"), unit: "%",
                           trend: .init(direction: .up, changePercent: 3.2))
                MetricCard(title: "Spending", subtitle: "Less than last month",
                           value: .amount(280_000, currency: "KZT"),
                           trend: .init(direction: .down, changePercent: -12.5, color: AppColors.success),
                           chartPlacement: .bottom) {
                    HeroBarPair(previous: 320_000, current: 280_000, color: AppColors.accent, currency: "KZT")
                }
            }
        }
    }

    // MARK: Surfaces

    @ViewBuilder
    private var surfaceSection: some View {
        ShowcaseSection(title: "GradientOrbsBackground", subtitle: "Weighted blurred orbs behind a glass card") {
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
        }

        ShowcaseSection(title: "PromptSheet", subtitle: "A short question in a 340 pt sheet") {
            Button("Show as a sheet") { showsPrompt = true }
                .buttonStyle(.bordered)
            samplePrompt
                .frame(height: 340)
                .clipShape(.rect(cornerRadius: AppRadius.xl))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.xl).stroke(AppColors.textTertiary.opacity(0.3)))
        }
    }

    private var samplePrompt: some View {
        PromptSheet(
            systemImage: "sparkles",
            title: "Enjoying the app?",
            message: "Your answer helps us decide what to improve next.",
            primaryTitle: "Love it!",
            secondaryTitle: "Not really",
            onPrimary: { showsPrompt = false },
            onSecondary: { showsPrompt = false }
        )
    }
}

#Preview { NavigationStack { BalancesScreen() } }
