//
//  ChartsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Progress bars and rings, amount text, sparklines, line and bar charts, the hero
//  sparkline, breakdown charts (orb, donut, proportion bars), gauges and bar pairs.
//  Entrance animations are off (`animatesOnAppear: false`) where a component offers it;
//  the others have finished by the time the renderer captures.
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
                        ProgressRing(progress: 0.45, size: AppIconSize.Tile.xxl, lineWidth: 5, animatesOnAppear: false, showsTrack: true)
                        ProgressRing(
                            progress: 1.15,
                            size: AppIconSize.Tile.xxl,
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

        @Test func heroSparkline() async {
            let income = ChartSeries<ChartValuePoint>.keyed("income", name: "Income", coloring: .solid(AppColors.success))

            await assertComponentSnapshot(
                HeroSparkline(
                    dataPoints: ChartSample.months,
                    series: income,
                    projectedValue: 590_000,
                    markExtremes: true,
                    valueFormat: .currency("KZT")
                )
            )
        }

        @Test func orbChart() async {
            await assertComponentSnapshot(
                OrbChart(slices: ChartSample.slices, size: 240, animatesOnAppear: false)
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
            )
        }

        @Test func proportions() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    HStack(spacing: AppSpacing.xl) {
                        MiniDonut(slices: ChartSample.slices)
                            .frame(width: 80, height: 80)
                        MiniProportionBar(segments: ChartSample.slices)
                            .frame(maxWidth: .infinity)
                    }
                    ProportionBar(ratio: 0.65, leftColor: AppColors.income, rightColor: AppColors.bgMuted, animatesOnAppear: false)
                    HeroProportionBar(segments: ChartSample.slices, currency: "KZT")
                }
            )
        }

        @Test func gauges() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    HeroHalfGauge(
                        value: 0.62,
                        norm: 0.5,
                        maxValue: 1,
                        zoneTicks: [0.3, 0.7],
                        color: AppColors.success,
                        diameter: 220,
                        animatesOnAppear: false
                    )
                    HeroMilestoneGauge(value: 4.2, target: 6, maxValue: 12, color: AppColors.accent, animatesOnAppear: false)
                    HStack(spacing: AppSpacing.lg) {
                        MiniHalfGauge(value: 0.62, norm: 0.5, maxValue: 1, color: AppColors.success)
                        MiniMilestoneGauge(value: 4.2, target: 6, maxValue: 12, color: AppColors.accent)
                    }
                }
                .frame(maxWidth: .infinity)
            )
        }

        @Test func barPairs() async {
            await assertComponentSnapshot(
                HStack(alignment: .bottom, spacing: AppSpacing.xl) {
                    HeroBarPair(previous: 320_000, current: 280_000, color: AppColors.accent, currency: "KZT", animatesOnAppear: false)
                    MiniBarPair(previous: 320_000, current: 280_000, color: AppColors.accent, isProjection: true)
                }
                .frame(maxWidth: .infinity)
            )
        }

        /// One banner per snapshot: each is a glass card.
        @Test func chartSelectionBanner() async {
            await assertComponentSnapshot(
                ChartSelectionBanner(title: "January 2026", entries: [
                    .init(value: 480_000, color: AppColors.success),
                    .init(value: 275_000, color: AppColors.destructive),
                ], format: .currency("KZT")),
                named: "twoValues",
                appearances: [.light, .dark, .largeText]
            )
            await assertComponentSnapshot(
                ChartSelectionBanner(title: "Week 12", entries: [
                    .init(value: 42.5, color: AppColors.accent, showsDot: false),
                ], format: .custom({ String(format: "%.1f km", $0) })),
                named: "oneValue"
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

    /// A spending breakdown for the orb, donut and proportion bars.
    static let slices: [DonutSlice] = [
        DonutSlice(id: "food", amount: 42_000, color: AppColors.accent, label: "Food", percentage: 42),
        DonutSlice(id: "rent", amount: 30_000, color: AppColors.success, label: "Rent", percentage: 30),
        DonutSlice(id: "fun", amount: 18_000, color: AppColors.warning, label: "Fun", percentage: 18),
        DonutSlice(id: "misc", amount: 10_000, color: AppColors.transfer, label: "Misc", percentage: 10),
    ]
}
