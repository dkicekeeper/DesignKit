//
//  CardsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Home-screen cards, stat cards, entity rows, the filter carousel.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Cards")
    struct Cards {
        @Test func financeCards() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    FinanceCard(title: "Accounts", isEmpty: false, emptyTitle: "No accounts", subtitle: "3 accounts") {
                        RedactableAmount(amount: 1_884_500, currency: "KZT", isLoading: false)
                    } trailing: {
                        HStack(spacing: -AppSpacing.sm) {
                            ForEach(CardsSample.accountIcons) { icon in
                                IconView(
                                    source: .sfSymbol(icon.symbol),
                                    style: .circle(size: AppIconSize.avatar, tint: .monochrome(.white), backgroundColor: icon.color)
                                )
                                .overlay(Circle().strokeBorder(AppColors.bgBase, lineWidth: 2))
                            }
                        }
                    }
                    EmptyCardView(sectionTitle: "Loans", emptyTitle: "No active loans")
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func statCards() async {
            await assertComponentSnapshot(
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    InsightsStatCard(
                        title: "Income",
                        amount: 640_000,
                        currency: "KZT",
                        color: AppColors.income,
                        previous: 580_000,
                        upIsGood: true
                    )
                    InsightsStatCard(
                        title: "Expenses",
                        amount: 921_300,
                        currency: "KZT",
                        color: AppColors.expense,
                        previous: 870_000,
                        upIsGood: false
                    ) {
                        ProportionBar(
                            ratio: 0.7,
                            leftColor: AppColors.destructive,
                            rightColor: AppColors.bgMuted,
                            height: 6,
                            animatesOnAppear: false
                        )
                        .padding(.top, AppSpacing.xxs)
                    }
                }
            )
        }

        @Test func entityRowsAndFilters() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    InsightEntityRow(
                        iconSource: .sfSymbol("tv.fill"),
                        title: "Streaming",
                        subtitle: "3 services",
                        amount: 12_900,
                        currency: "KZT",
                        amountCaption: "per month"
                    )
                    .cardContentPadding()
                    .cardStyle()
                    UniversalCarousel(config: .filter) {
                        UniversalFilterButton(title: "Week", onTap: {})
                        UniversalFilterButton(title: "Month", isSelected: true, onTap: {})
                        UniversalFilterButton(title: "Year", showChevron: false, onTap: {})
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }
    }
}

private enum CardsSample {
    struct AccountIcon: Identifiable {
        let symbol: String
        let color: Color
        var id: String { symbol }
    }

    static let accountIcons = [
        AccountIcon(symbol: "creditcard.fill", color: AppColors.accent),
        AccountIcon(symbol: "banknote.fill", color: AppColors.success),
        AccountIcon(symbol: "wallet.bifold.fill", color: AppColors.warning),
    ]
}
