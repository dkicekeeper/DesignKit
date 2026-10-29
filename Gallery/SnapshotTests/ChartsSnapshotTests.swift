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

        /// One chart per snapshot: each opens on its last period with the banner, a glass card.
        @Test func lineAndBarCharts() async {
            await assertComponentSnapshot(
                LineChart(dataPoints: ChartSample.months, series: [ChartSample.income, ChartSample.expenses], todayText: "Today"),
                named: "line",
                appearances: [.light, .dark, .largeText]
            )
            await assertComponentSnapshot(
                BarChart(dataPoints: ChartSample.months, series: [ChartSample.income, ChartSample.expenses], todayText: "Today"),
                named: "bar"
            )
        }

        /// 8.2.0: the last period is not over: a dashed end of the line, a bar fading upwards,
        /// "so far" in the banner.
        @Test func unfinishedPeriod() async {
            await assertComponentSnapshot(
                LineChart(dataPoints: ChartSample.monthsInProgress, series: ChartSample.income,
                          valueFormat: .currency("KZT"), todayText: "Today"),
                named: "line"
            )
            await assertComponentSnapshot(
                BarChart(dataPoints: ChartSample.monthsInProgress, series: ChartSample.income,
                         valueFormat: .currency("KZT"), todayText: "Today"),
                named: "bar"
            )
        }

        /// 8.2.0: more periods than the window holds: the last one in the middle, empty periods
        /// after it.
        @Test func centredWindow() async {
            await assertComponentSnapshot(
                BarChart(dataPoints: ChartSample.year, series: ChartSample.expenses, todayText: "Today")
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

        /// The bleed half gauge (4.2.0): the arc runs out past both edges, a knob on the value,
        /// the zones as notches; on the page and on colour. At the default 360 pt, the widest a
        /// snapshot can be (its window adds 2 × 40 pt and must fit the 440 pt screen).
        @Test func bleedGauges() async {
            await assertComponentSnapshot(
                HeroHalfGauge(value: 0.62, maxValue: 1, zoneTicks: [0.4, 0.7], color: AppColors.success,
                              style: .bleed, lineWidth: 28, animatesOnAppear: false),
                named: "onSurface"
            )
            await assertComponentSnapshot(
                HeroHalfGauge(value: 0.84, maxValue: 1, zoneTicks: [0.4, 0.7], color: AppColors.destructive,
                              style: .bleed, tone: .onColor, lineWidth: 28, animatesOnAppear: false)
                    .padding(.vertical, AppSpacing.lg)
                    .background(AppColors.destructive),
                named: "onColor"
            )
            await assertComponentSnapshot(
                HeroHalfGauge(value: 0, maxValue: 1, color: AppColors.accent, style: .bleed, lineWidth: 28,
                              animatesOnAppear: false),
                named: "empty",
                appearances: [.light]
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
            // 8.2.0: the series' names (the legend) and a note after the title.
            await assertComponentSnapshot(
                ChartSelectionBanner(title: "January 2026", note: "so far", entries: [
                    .init(value: 480_000, color: AppColors.success, label: "Income"),
                    .init(value: 275_000, color: AppColors.destructive, label: "Expenses"),
                ], format: .currency("KZT")),
                named: "legend",
                appearances: [.light, .dark, .largeText]
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

    /// The same six months, June not over yet (a third of it in).
    static let monthsInProgress: [ChartValuePoint] = rows.map { row in
        let inProgress = row.0 == "Jun"
        let share = inProgress ? 0.35 : 1
        return ChartValuePoint(label: row.0, isPartial: inProgress,
                               values: ["income": row.1 * 1_000 * share, "expenses": row.2 * 1_000 * share])
    }

    /// Eighteen months, more than a chart's window of twelve.
    static let year: [ChartValuePoint] = (0..<18).map { index in
        let row = rows[index % rows.count]
        return ChartValuePoint(label: "\(row.0) \(index / rows.count + 1)", axisLabel: row.0,
                               values: ["income": row.1 * 1_000, "expenses": row.2 * 1_000])
    }

    static let income = ChartSeries<ChartValuePoint>.keyed("income", name: "Income", coloring: .solid(AppColors.success))
    static let expenses = ChartSeries<ChartValuePoint>.keyed("expenses", name: "Expenses", coloring: .solid(AppColors.destructive))

    /// A spending breakdown for the orb, donut and proportion bars.
    static let slices: [DonutSlice] = [
        DonutSlice(id: "food", amount: 42_000, color: AppColors.accent, label: "Food", percentage: 42),
        DonutSlice(id: "rent", amount: 30_000, color: AppColors.success, label: "Rent", percentage: 30),
        DonutSlice(id: "fun", amount: 18_000, color: AppColors.warning, label: "Fun", percentage: 18),
        DonutSlice(id: "misc", amount: 10_000, color: AppColors.transfer, label: "Misc", percentage: 10),
    ]
}
