//
//  SummarySnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Summary cards and rows ported from Tenra. 1.1.0: TotalsCard, LimitProgressCard,
//  WeightBreakdownCard, CalculationCard, NetAmountRow, ScheduleRow. 1.2.0: ComparisonCard,
//  CashFlowCard (its loading skeleton shimmers, so it is not snapshot), RecurringPaymentCard
//  (without a base currency: the conversion is async), PayoffProgressCard, BreakdownRow.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Summary")
    struct Summary {
        @Test func totalsCard() async {
            await assertComponentSnapshot(
                TotalsCard([
                    .init(title: "Income", amount: 530_000, previous: 480_000, color: AppColors.success),
                    .init(title: "Expenses", amount: 320_000, previous: 350_000, color: AppColors.destructive,
                          increaseIsGood: false),
                    .init(title: "Net", amount: -60_000, previous: 130_000, color: AppColors.destructive),
                ], currency: "KZT", title: "May 2026"),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func limitProgressCards() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    LimitProgressCard(iconSource: .sfSymbol("fork.knife"), title: "Food", color: .orange,
                                      spent: 185_000, limit: 250_000, currency: "KZT", percentage: 74,
                                      caption: "9 days left")
                    LimitProgressCard(iconSource: .sfSymbol("bag.fill"), title: "Shopping", color: AppColors.accent,
                                      spent: 132_000, limit: 100_000, currency: "KZT", percentage: 132)
                }
            )
        }

        @Test func weightBreakdownCard() async {
            await assertComponentSnapshot(
                WeightBreakdownCard(
                    title: "How the score works",
                    message: "Each part counts by how much it matters for the whole.",
                    caption: "Based on the last 3 months",
                    segments: [
                        .init(title: "Savings", systemImage: "banknote.fill", color: AppColors.success, weight: 40),
                        .init(title: "Regular payments", systemImage: "repeat.circle", color: AppColors.accent, weight: 26.7),
                        .init(title: "Safety cushion", systemImage: "shield.lefthalf.filled", color: AppColors.income, weight: 20),
                        .init(title: "Cash flow", systemImage: "chart.line.uptrend.xyaxis", color: AppColors.destructive,
                              weight: 13.3),
                    ],
                    footnote: "No budgets set, so their weight is shared among the other parts."
                )
            )
        }

        @Test func calculationCard() async {
            await assertComponentSnapshot(
                CalculationCard(
                    systemImage: "banknote.fill",
                    color: AppColors.success,
                    title: "How it's calculated",
                    heroLabel: "Savings rate",
                    heroValue: "18.4%",
                    rows: [
                        .init(label: "Income", value: .amount(640_000, currency: "KZT")),
                        .init(label: "Expenses", value: .amount(522_240, currency: "KZT")),
                        .init(label: "Savings rate", value: .text("18.4%"), isEmphasised: true),
                    ],
                    explanation: "The share of income you did not spend this month.",
                    recommendation: "Aim for 20% or more: set aside the difference on payday."
                )
            )
        }

        @Test func netAmountRows() async {
            await assertComponentSnapshot(
                VStack(spacing: 0) {
                    NetAmountRow(label: "May 2026", inflow: 530_000, outflow: 320_000, net: 210_000, currency: "KZT")
                    Divider()
                    NetAmountRow(label: "April 2026", inflow: 280_000, outflow: 340_000, net: -60_000, currency: "KZT")
                    Divider()
                    NetAmountRow(label: "March 2026", inflow: 0, outflow: 0, net: 0, currency: "KZT",
                                 singleValue: 410_000, singleColor: AppColors.success)
                }
                .cardContentPadding()
                .cardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func scheduleRows() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.sm) {
                    ScheduleRow(title: "#3", subtitle: "12 Mar 2026", amount: 45_000, currency: "KZT",
                                detail: "int: 3 200 ₸", isDone: true)
                    ScheduleRow(title: "#4", subtitle: "12 Apr 2026", amount: 45_000, currency: "KZT",
                                detail: "int: 2 950 ₸", isDone: false)
                }
                .cardContentPadding()
                .cardStyle()
            )
        }

        @Test func comparisonCards() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    ComparisonCard(previousLabel: "Jan 2026", previousAmount: 95_000,
                                   currentLabel: "Feb 2026", currentAmount: 120_000,
                                   currency: "KZT", increaseIsGood: false)
                    ComparisonCard(previousLabel: "Jan 2026", previousAmount: 530_000,
                                   currentLabel: "Feb 2026", currentAmount: 620_000, currency: "KZT")
                    ComparisonCard(previousLabel: "Jan 2026", previousAmount: 100_000,
                                   currentLabel: "Feb 2026", currentAmount: 101_000, currency: "KZT")
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func cashFlowCards() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    CashFlowCard(
                        title: "History",
                        totals: .init(income: 50_000, expenses: 35_000,
                                      extra: .init(label: "Planned", amount: 5_000)),
                        currency: "KZT",
                        emptyMessage: "No transactions yet"
                    )
                    CashFlowCard(title: "History", totals: nil, currency: "KZT", isEmpty: true,
                                 emptyMessage: "No transactions yet")
                }
            )
        }

        @Test func recurringPaymentCards() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    RecurringPaymentCard(iconSource: .sfSymbol("play.tv.fill"), title: "Streaming",
                                         amount: 4_990, currency: "KZT",
                                         caption: "Next charge on 12 Oct", status: .active)
                    RecurringPaymentCard(iconSource: .sfSymbol("dumbbell.fill"), title: "Gym",
                                         amount: 15_000, currency: "KZT", status: .paused)
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func payoffProgressCards() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    PayoffProgressCard(
                        iconSource: .sfSymbol("car.fill"), title: "Car loan", subtitle: "Halyk Bank",
                        remaining: 1_200_000, total: 3_000_000, currency: "KZT", progress: 0.6,
                        phase: .inProgress(nextDate: "12 Nov 2026", remainingCaption: "18 left")
                    ) {
                        BadgeView("Credit", color: AppColors.expense)
                    }
                    PayoffProgressCard(
                        iconSource: .sfSymbol("iphone"), title: "Phone", subtitle: "Kaspi",
                        remaining: 0, total: 480_000, currency: "KZT", progress: 1,
                        phase: .done(caption: "Closed 15 Jun 2026")
                    )
                }
            )
        }

        @Test func breakdownRows() async {
            await assertComponentSnapshot(
                VStack(spacing: 0) {
                    BreakdownRow(iconSource: .sfSymbol("fork.knife"), color: AppColors.warning, title: "Food",
                                 subtitle: "Groceries, Cafés, Delivery", amount: 85_000, currency: "KZT",
                                 percentage: 42, showsChevron: true)
                    BreakdownRow(iconSource: .sfSymbol("car.fill"), color: AppColors.accent, title: "Transport",
                                 amount: 38_000, currency: "KZT", percentage: 19)
                }
                .cardContentPadding()
                .cardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }
    }
}
