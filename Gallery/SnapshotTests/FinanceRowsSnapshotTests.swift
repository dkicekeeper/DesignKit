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

        /// OptionCardPicker(style: .carousel) (5.2.0): the chosen option large on top, the row
        /// under it with the chosen card in the middle, the chosen option's settings under it.
        @Test func optionCardCarousel() async {
            await assertComponentSnapshot(
                OptionCardPicker(["None", "Gradient", "Photo"], selection: .constant("Gradient"), style: .carousel,
                                 title: { $0 }) { option in
                    switch option {
                    case "Gradient": LinearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom)
                    case "Photo": LinearGradient(colors: [.teal, .blue], startPoint: .top, endPoint: .bottom)
                    default: Rectangle().fill(AppColors.bgBase)
                    }
                } settings: { _ in
                    DSButton("Animate", systemImage: "sparkles", appearance: .secondary) {}
                },
                appearances: [.light, .dark]
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

        /// 5.1.1: every character of the text, punctuation included, with a gap only where the text
        /// has a space; Japanese without gaps, wrapping between its words.
        @Test func streamingTextScripts() async {
            let samples: [(name: String, text: String, amount: String)] = [
                ("en", "\"Coffee,\" 2500 tenge. And a taxi?", "2500"),
                ("ru", "Сколько я потратил на «кофе»? 2500 тенге.", "2500"),
                ("ja", "コンビニで500円使って、タクシーに1,800円払った。", "500円"),
                ("ko", "점심 12,000원, 택시 8,000원 썼어?", "12,000원"),
            ]
            for sample in samples {
                await assertComponentSnapshot(
                    StreamingText(
                        sample.text,
                        highlights: [.init(range: (sample.text as NSString).range(of: sample.amount), color: AppColors.success)]
                    )
                    .frame(maxWidth: .infinity, alignment: .leading),
                    named: sample.name,
                    appearances: [.light]
                )
            }
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
