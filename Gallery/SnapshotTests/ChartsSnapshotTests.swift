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

        /// 8.2.0: a forecast for the unfinished month (a pale bar, a dotted rise to a ring) and a
        /// year ago (a pale wider bar, a pale dashed line); the banner's change, forecast and year
        /// ago lines.
        @Test func forecastAndYearAgo() async {
            await assertComponentSnapshot(
                BarChart(dataPoints: ChartSample.monthsInProgress, series: ChartSample.incomeWithExtras,
                         valueFormat: .currency("KZT"), todayText: "Today"),
                named: "bar",
                appearances: [.light, .dark, .largeText]
            )
            await assertComponentSnapshot(
                LineChart(dataPoints: ChartSample.monthsInProgress, series: ChartSample.incomeWithExtras,
                          valueFormat: .currency("KZT"), todayText: "Today"),
                named: "line"
            )
        }

        /// 8.2.0: an average and a limit across the plot (bars past it orange), records.
        @Test func referenceLinesAndRecords() async {
            await assertComponentSnapshot(
                BarChart(dataPoints: ChartSample.months, series: ChartSample.expenses, todayText: "Today",
                         referenceLines: [.average(), .value(470_000, label: "Limit", aboveColor: AppColors.warning)],
                         marksExtremes: true),
                named: "bar"
            )
            await assertComponentSnapshot(
                LineChart(dataPoints: ChartSample.months, series: ChartSample.income, todayText: "Today",
                          referenceLines: [.average()], marksExtremes: true),
                named: "line"
            )
        }

        /// 8.2.0: spending by category in stacks; the banner leads with the total.
        @Test func stackedBars() async {
            await assertComponentSnapshot(
                BarChart(dataPoints: ChartSample.categoryMonths, series: ChartSample.categories,
                         valueFormat: .currency("KZT"), todayText: "Today", layout: .stacked),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// 8.2.0: sixteen weeks of days up to a fixed day, Monday first.
        @Test func calendarHeatmap() async {
            await assertComponentSnapshot(
                CalendarHeatmap(values: ChartSample.days, weeks: 16, color: AppColors.destructive,
                                valueFormat: .currency("KZT"), today: ChartSample.today, calendar: ChartSample.calendar),
                appearances: [.light, .dark, .largeText]
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

        /// 8.2.0: spending by weekday in a card's slot, Saturday in colour, with the initials.
        @Test func miniBars() async {
            await assertComponentSnapshot(
                HStack(alignment: .bottom, spacing: AppSpacing.xl) {
                    MiniBars(values: ChartSample.weekdays, color: AppColors.accent,
                             labels: ["M", "T", "W", "T", "F", "S", "S"])
                        .frame(width: 120)
                    MiniBars(values: ChartSample.weekdays, highlighted: 2, color: AppColors.destructive)
                        .frame(width: 120)
                }
                .frame(maxWidth: .infinity),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// 8.2.0: the person's options (`.chartDisplayOptions`) over a chart's parameters: an
        /// average line per series in its colour, records, the forecast and a year ago.
        @Test func displayOptions() async {
            await assertComponentSnapshot(
                LineChart(dataPoints: ChartSample.monthsInProgress, series: [ChartSample.incomeWithExtras, ChartSample.expenses],
                          valueFormat: .currency("KZT"), todayText: "Today")
                    .chartDisplayOptions(.constant([.average, .records, .forecast, .comparison])),
                named: "line"
            )
            await assertComponentSnapshot(
                BarChart(dataPoints: ChartSample.monthsInProgress, series: ChartSample.incomeWithExtras,
                         valueFormat: .currency("KZT"), todayText: "Today",
                         referenceLines: [.average()], marksExtremes: true)
                    .chartDisplayOptions(.constant([])),
                named: "barNothing"
            )
        }

        /// 8.2.0: a window that follows the scroll: an odd window, the ruler on the middle bar,
        /// every bar in full colour, the banner on the period under the ruler.
        @Test func followsScroll() async {
            await assertComponentSnapshot(
                BarChart(dataPoints: ChartSample.year, series: ChartSample.expenses, todayText: "Today", followsScroll: true)
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
            // 8.2.0: the change from the period before, lines under the value, a record.
            await assertComponentSnapshot(
                ChartSelectionBanner(title: "March 2026", entries: [
                    .init(value: 560_000, color: AppColors.success, label: "Income", changePercent: 12.4, better: .higher,
                          details: [.init("A year ago", value: 498_000)], isRecord: true),
                    .init(value: 470_000, color: AppColors.destructive, label: "Expenses", changePercent: 6.1, better: .lower,
                          details: [.init("Forecast", value: 520_000)]),
                ], format: .currency("KZT")),
                named: "details",
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

    /// The same six months, June not over yet (a third of it in, heading for 590K); each month
    /// with income a year before.
    static let monthsInProgress: [ChartValuePoint] = rows.map { row in
        let inProgress = row.0 == "Jun"
        let share = inProgress ? 0.35 : 1
        var values = ["income": row.1 * 1_000 * share, "expenses": row.2 * 1_000 * share,
                      "incomeLastYear": row.1 * 1_000 * 0.88]
        if inProgress { values["incomeForecast"] = 590_000 }
        return ChartValuePoint(label: row.0, isPartial: inProgress, values: values)
    }

    /// Eighteen months, more than a chart's window of twelve.
    static let year: [ChartValuePoint] = (0..<18).map { index in
        let row = rows[index % rows.count]
        return ChartValuePoint(label: "\(row.0) \(index / rows.count + 1)", axisLabel: row.0,
                               values: ["income": row.1 * 1_000, "expenses": row.2 * 1_000])
    }

    /// Income with its forecast for June and a year ago for every month.
    static let incomeWithExtras = ChartSeries<ChartValuePoint>.keyed(
        "income", name: "Income", coloring: .solid(AppColors.success), better: .higher,
        projectedKey: "incomeForecast", comparisonKey: "incomeLastYear")

    /// Six months of spending by category, no dates.
    static let categoryMonths: [ChartValuePoint] = rows.enumerated().map { index, row in
        let spending = row.2 * 1_000
        let food = (spending * (0.36 + 0.02 * Double(index % 3))).rounded()
        let home = (spending * 0.32).rounded()
        return ChartValuePoint(label: row.0, values: [
            "food": food,
            "home": home,
            "transport": spending - food - home,
        ])
    }

    static let categories: [ChartSeries<ChartValuePoint>] = [
        .keyed("food", name: "Food", coloring: .solid(AppColors.Palette.orange.color)),
        .keyed("home", name: "Home", coloring: .solid(AppColors.Palette.blue.color)),
        .keyed("transport", name: "Transport", coloring: .solid(AppColors.Palette.teal.color)),
    ]

    /// A fixed calendar and day for the heatmap: Monday first, UTC, Wednesday 28 October 2026.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()
    static let today = calendar.date(from: DateComponents(year: 2026, month: 10, day: 28)) ?? .distantPast

    /// 112 days of spending up to `today`, from a fixed formula: busier at weekends, nothing on
    /// every seventh day.
    static let days: [Date: Double] = {
        var result = [Date: Double]()
        for back in 0..<112 {
            guard let day = calendar.date(byAdding: .day, value: -back, to: today) else { continue }
            guard back % 7 != 3 else { continue }
            let weekday = calendar.component(.weekday, from: day)
            let weekend = weekday == 1 || weekday == 7 ? 1.9 : 1
            result[day] = (5_000 + 1_500 * Double((back * 37) % 11)) * weekend
        }
        return result
    }()

    /// Spending by weekday, Monday first: Saturday the most.
    static let weekdays: [Double] = [18_000, 12_500, 15_000, 14_000, 22_000, 31_000, 9_500]

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
