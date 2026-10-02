//
//  ChartsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Progress bars and rings, amount text, sparklines, line and bar charts.
//  Entrance animations are off (`animatesOnAppear: false`) so the final state is drawn.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Charts")
    struct Charts {
        @Test func progress() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    LinearProgressBar(value: 0.35, animatesOnAppear: false)
                    LinearProgressBar(percentage: 112, isOverBudget: true, color: AppColors.warning, animatesOnAppear: false)
                    HStack(spacing: AppSpacing.lg) {
                        ProgressRing(progress: 0.45, size: AppIconSize.budgetRing, lineWidth: 5, animatesOnAppear: false, showsTrack: true)
                        ProgressRing(
                            progress: 1.15,
                            size: AppIconSize.budgetRing,
                            lineWidth: 5,
                            isOverBudget: true,
                            animatesOnAppear: false,
                            showsTrack: true
                        )
                    }
                    AmountComparisonBar(expenseAmount: 921_300, incomeAmount: 640_000, currency: "KZT", animatesOnAppear: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }

        @Test func amounts() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    FormattedAmountText(amount: 1_234_567.89, currency: "KZT", fontSize: AppTypography.h2)
                    FormattedAmountText(amount: 4_990, currency: "USD")
                    FormattedAmountText(amount: -350.5, currency: "EUR", color: AppColors.destructive)
                    FormattedAmountText(amount: 12_000, currency: "KZT", prefix: "+", color: AppColors.income)
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .largeText]
            )
        }

        @Test func sparklines() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    Sparkline(values: [3, 5, 4, 8, 6, 9, 7, 11], height: 48)
                    Sparkline(
                        values: [4, -2, 3, -5, 1, 6, -1],
                        coloring: .signed(positive: AppColors.success, negative: AppColors.destructive),
                        baseline: .signed,
                        height: 48,
                        markExtremes: true
                    )
                }
            )
        }

        @Test func lineAndBarCharts() async {
            let income = ChartSeries<ChartValuePoint>.keyed("income", name: "Income", coloring: .solid(AppColors.success))
            let expenses = ChartSeries<ChartValuePoint>.keyed("expenses", name: "Expenses", coloring: .solid(AppColors.destructive))

            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.xl) {
                    LineChart(dataPoints: ChartSample.months, series: [income, expenses], todayText: "Today")
                    BarChart(dataPoints: ChartSample.months, series: [income, expenses], todayText: "Today")
                }
            )
        }
    }
}

/// Six months without dates: no "today" marker, so the picture does not depend on the day.
private enum ChartSample {
    /// (label, income, expenses), thousands.
    private static let rows: [(String, Double, Double)] = [
        ("Jan", 420, 380), ("Feb", 450, 410), ("Mar", 390, 460),
        ("Apr", 520, 430), ("May", 480, 500), ("Jun", 560, 470),
    ]

    static let months: [ChartValuePoint] = rows.map { row in
        ChartValuePoint(label: row.0, values: ["income": row.1 * 1_000, "expenses": row.2 * 1_000])
    }
}
