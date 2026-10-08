//
//  FinanceRowsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Transaction rows, card pickers, streaming text and pager arrows (2.9.0, from Tenra). The date
//  range sheet has no snapshot (its calendars show the current month), nor the progress overlay
//  (its spinner turns on a clock, so no two frames match).
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Finance rows and pickers")
    struct FinanceRows {
        private let kaspi = TransactionRow.Account(name: "Kaspi Gold", icon: .sfSymbol("creditcard.fill"))
        private let deposit = TransactionRow.Account(name: "Halyk Deposit", icon: .sfSymbol("lock.fill"))

        @Test func transactionRows() async {
            await assertComponentSnapshot(
                VStack(spacing: 0) {
                    TransactionRow(
                        .entry(title: "Groceries", details: "Vegetables, Bread", account: kaspi),
                        note: "Magnum",
                        icon: .sfSymbol("cart.fill"), iconTint: .monochrome(.orange), iconBackground: AppColors.pale(.orange),
                        amounts: [
                            .init(18_500, currency: "KZT", prefix: "-", color: AppColors.Text.primary),
                            .init(36.5, currency: "USD", color: AppColors.Text.primary),
                        ],
                        accessibilityLabel: "Groceries"
                    )
                    Divider()
                    TransactionRow(
                        .entry(title: "Salary", account: .deleted("Old card")),
                        icon: .sfSymbol("banknote.fill"), iconTint: .monochrome(AppColors.income),
                        iconBackground: AppColors.pale(AppColors.income),
                        badgeSystemImage: "arrow.clockwise",
                        amounts: [.init(450_000, currency: "KZT", prefix: "+", color: AppColors.income)],
                        isPending: true,
                        accessibilityLabel: "Salary"
                    )
                    Divider()
                    TransactionRow(
                        .transfer(from: kaspi, to: deposit),
                        icon: .sfSymbol("arrow.left.arrow.right"), iconTint: .monochrome(AppColors.transfer),
                        iconBackground: AppColors.pale(AppColors.transfer),
                        amounts: [
                            .init(100_000, currency: "KZT", prefix: "-", color: AppColors.Text.primary),
                            .init(100_000, currency: "KZT", prefix: "+", color: AppColors.income),
                        ],
                        accessibilityLabel: "Transfer"
                    )
                }
                .cardContentPadding()
                .cardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func optionCards() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    OptionCard(title: "None", isSelected: false) { Rectangle().fill(AppColors.bgBase) }
                    OptionCard(title: "Gradient", isSelected: true) {
                        LinearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom)
                    }
                }
            )
        }

        @Test func snapCardPicker() async {
            await assertComponentSnapshot(
                SnapCardPicker(["Kaspi Gold", "Cash"], id: \.self, selection: .constant("Kaspi Gold")) { name, isSelected, select in
                    SelectableBalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: name, amount: 1_284_500,
                                          currency: "KZT", isSelected: isSelected, action: select)
                },
                appearances: [.light]
            )
        }

        @Test func streamingText() async {
            let text = "Coffee 2500 tenge"
            await assertComponentSnapshot(
                StreamingText(
                    text,
                    highlights: [.init(range: (text as NSString).range(of: "2500"), color: AppColors.success)]
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }

        @Test func flowLayoutCentered() async {
            await assertComponentSnapshot(
                FlowLayout(alignment: .center) {
                    ForEach(["Lake", "Free camping", "Fire allowed", "Pike", "Toilets"], id: \.self) {
                        Badge($0, color: AppColors.accent)
                    }
                },
                appearances: [.light]
            )
        }

        @Test func pagerArrows() async {
            await assertComponentSnapshot(
                PagerArrows(index: .constant(0), count: 3) {
                    Text("July")
                        .font(AppTypography.h3)
                        .frame(maxWidth: .infinity, minHeight: 80)
                },
                appearances: [.light]
            )
        }
    }
}
