//
//  BarChart.swift
//  DesignKit
//
//  Bar counterpart of LineChart for one or more series over category points, ported
//  from Tenra's insights BarChart. Several series are grouped side by side via
//  `position(by:)`. Paired with LineChart by ChartSwitcher.
//
//  8.2.0 (TrendChartFrame): opens on the current period, selected and in the middle of the
//  window; the selected period's bars are in full colour and the others step back (a ruler
//  ran through the bar before); the bars rise from zero as the chart appears, and again on
//  new periods; the bar of a period that is not over fades towards its top, under a pale bar
//  up to its forecast; a pale wider bar a year back; reference lines (bars past a limit take
//  its colour); records; a picked stretch; stacks (`layout: .stacked`); a glow in dark mode.
//
//  Performance rules (charts.md): static Y domain, values read from the cache, tap-only
//  selection, no animations on hot-path state.
//

import SwiftUI
import Charts
import DesignTokens
import DesignSupport

/// How a `BarChart` draws several series (8.2.0).
public enum BarChartLayout: Hashable, Sendable {
    /// Side by side in each period: income next to spending.
    case grouped
    /// On top of each other: the parts of a period's total (spending by category). The banner
    /// leads with the total; forecasts and comparisons are not drawn.
    case stacked
}

/// Scrollable bar chart that opens on the current period, with tap selection, a banner and a
/// "Today" marker.
///
/// ```swift
/// BarChart(dataPoints: months, series: spending, valueFormat: .currency("KZT"))
/// BarChart(dataPoints: months, series: [income, spending])                 // grouped bars
/// BarChart(dataPoints: months, series: categories, layout: .stacked)       // stacks
/// BarChart(dataPoints: months, series: spending,
///          referenceLines: [.value(500_000, label: "Limit", aboveColor: AppColors.warning)])
/// ```
///
/// A long press and a drag pick a stretch of periods: the banner sums it up.
public struct BarChart<Point: ChartPoint>: View {
    let dataPoints: [Point]
    let seriesList: [ChartSeries<Point>]
    let valueFormat: ChartValueFormat
    let todayText: String
    let emptyTitle: String
    let emptyMessage: String?
    let options: TrendChartOptions
    let selection: Binding<String?>?

    /// External zoom (ChartSwitcher's toolbar); 1.0 when standalone.
    @Binding var zoomScale: CGFloat

    /// Parameters as in `LineChart`; `layout` stacks several series (8.2.0).
    public init(
        dataPoints: [Point],
        series: [ChartSeries<Point>],
        valueFormat: ChartValueFormat = .compact,
        todayText: String = String(localized: "chart.today"),
        emptyTitle: String = String(localized: "chart.empty.title"),
        emptyMessage: String? = String(localized: "chart.empty.message"),
        zoomScale: Binding<CGFloat> = .constant(1.0),
        layout: BarChartLayout = .grouped,
        referenceLines: [ChartReferenceLine] = [],
        marksExtremes: Bool = false,
        followsScroll: Bool = false,
        comparisonLabel: String = String(localized: "chart.yearAgo", defaultValue: "A year ago")
    ) {
        self.init(
            dataPoints: dataPoints,
            series: series,
            valueFormat: valueFormat,
            todayText: todayText,
            emptyTitle: emptyTitle,
            emptyMessage: emptyMessage,
            zoomScale: zoomScale,
            options: TrendChartOptions(
                referenceLines: referenceLines,
                marksExtremes: marksExtremes,
                followsScroll: followsScroll,
                stacked: layout == .stacked,
                comparisonLabel: comparisonLabel
            ),
            selection: nil
        )
    }

    /// Single-series convenience.
    public init(
        dataPoints: [Point],
        series: ChartSeries<Point>,
        valueFormat: ChartValueFormat = .compact,
        todayText: String = String(localized: "chart.today"),
        emptyTitle: String = String(localized: "chart.empty.title"),
        emptyMessage: String? = String(localized: "chart.empty.message"),
        zoomScale: Binding<CGFloat> = .constant(1.0),
        referenceLines: [ChartReferenceLine] = [],
        marksExtremes: Bool = false,
        followsScroll: Bool = false,
        comparisonLabel: String = String(localized: "chart.yearAgo", defaultValue: "A year ago")
    ) {
        self.init(
            dataPoints: dataPoints,
            series: [series],
            valueFormat: valueFormat,
            todayText: todayText,
            emptyTitle: emptyTitle,
            emptyMessage: emptyMessage,
            zoomScale: zoomScale,
            referenceLines: referenceLines,
            marksExtremes: marksExtremes,
            followsScroll: followsScroll,
            comparisonLabel: comparisonLabel
        )
    }

    /// ChartSwitcher's: the options, and the selection that outlives a switch to the line.
    init(
        dataPoints: [Point],
        series: [ChartSeries<Point>],
        valueFormat: ChartValueFormat,
        todayText: String,
        emptyTitle: String,
        emptyMessage: String?,
        zoomScale: Binding<CGFloat>,
        options: TrendChartOptions,
        selection: Binding<String?>?
    ) {
        self.dataPoints = dataPoints
        self.seriesList = series
        self.valueFormat = valueFormat
        self.todayText = todayText
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self._zoomScale = zoomScale
        self.options = options
        self.selection = selection
    }

    // MARK: Body

    public var body: some View {
        if dataPoints.isEmpty || seriesList.isEmpty {
            EmptyState(
                icon: "chart.bar",
                title: emptyTitle,
                description: emptyMessage,
                style: .compact
            )
            .frame(height: ChartMetrics.plotHeight)
        } else {
            TrendChartFrame(
                dataPoints: dataPoints,
                series: seriesList,
                valueFormat: valueFormat,
                zoomScale: $zoomScale,
                selection: selection,
                entrance: .rise,
                options: options
            ) { context in
                plot(context)
            }
        }
    }

    // MARK: - Marks

    private func plot(_ context: TrendChartContext) -> some View {
        let cache = context.cache
        let showZeroRule = seriesList.contains(where: \.showsZeroRule)
        let stacked = options.stacked
        return Chart {
            ChartRangeBands(range: context.range, labels: cache.labels)

            // Today marker — drawn first; today is one of the categories.
            if let today = cache.todayLabel {
                RuleMark(x: .value("Today", today))
                    .foregroundStyle(AppColors.accent.opacity(0.45))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top, alignment: .center, spacing: 2) {
                        Text(todayText)
                            .font(AppTypography.caption2)
                            .foregroundStyle(AppColors.accent)
                    }
                    .accessibilityHidden(true)
            }

            if !stacked {
                ForEach(seriesList.indices, id: \.self) { s in
                    ghostBars(s, context: context)
                }
            }

            ForEach(seriesList.indices, id: \.self) { s in
                seriesBars(s, context: context)
            }

            if showZeroRule {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(AppColors.Text.tertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .accessibilityHidden(true)
            }

            ChartReferenceRules(references: context.references)

            if context.marksExtremes && !stacked {
                ForEach(seriesList.indices, id: \.self) { s in
                    extremeMarks(s, cache: cache)
                }
            }
        }
    }

    /// Behind a series' bars: a pale wider bar a year back (`ChartSeries.comparison`) and a pale
    /// bar up to a forecast (an unfinished period with `ChartSeries.projected`).
    @ChartContentBuilder
    private func ghostBars(_ s: Int, context: TrendChartContext) -> some ChartContent {
        let cache = context.cache
        let series = seriesList[s]
        let isGrouped = seriesList.count > 1

        ForEach(cache.labels.indices, id: \.self) { i in
            if let before = cache.comparison[s][i] {
                ghostBar(
                    label: cache.labels[i], value: context.risen ? before : 0, seriesID: series.id,
                    isGrouped: isGrouped, width: ChartMetrics.comparisonWidthRatio,
                    style: AppColors.Text.primary.opacity(ChartMetrics.comparisonOpacity)
                )
            }
            if let forecast = cache.projected[s][i] {
                ghostBar(
                    label: cache.labels[i], value: context.risen ? forecast : 0, seriesID: series.id,
                    isGrouped: isGrouped, width: ChartMetrics.barWidthRatio,
                    style: series.color(for: forecast).opacity(ChartMetrics.forecastOpacity)
                )
            }
        }
    }

    @ChartContentBuilder
    private func ghostBar(
        label: String,
        value: Double,
        seriesID: String,
        isGrouped: Bool,
        width: Double,
        style: Color
    ) -> some ChartContent {
        if isGrouped {
            BarMark(x: .value("Period", label), y: .value("Value", value), stacking: .unstacked)
                .cornerRadius(AppRadius.xs)
                .foregroundStyle(style)
                .position(by: .value("Type", seriesID))
                .accessibilityHidden(true)
        } else {
            BarMark(x: .value("Period", label), y: .value("Value", value), width: .ratio(width), stacking: .unstacked)
                .cornerRadius(AppRadius.xs)
                .foregroundStyle(style)
                .accessibilityHidden(true)
        }
    }

    /// One series' bars. Per-value colour: signed series read green above zero, red below; a
    /// bar past a limit takes the limit's colour. In dark mode the selected bars glow.
    @ChartContentBuilder
    private func seriesBars(_ s: Int, context: TrendChartContext) -> some ChartContent {
        let cache = context.cache
        let series = seriesList[s]
        let values = cache.values[s]
        let isGrouped = seriesList.count > 1 && !options.stacked
        let stacked = options.stacked
        let namePrefix = seriesList.count > 1 ? "\(series.name), " : ""

        ForEach(cache.labels.indices, id: \.self) { i in
            let v = values[i]
            let color = context.aboveColor(for: v) ?? series.color(for: v)
            let emphasized = context.isEmphasized(i)
            let style = Self.barStyle(color, isSelected: emphasized, isPartial: cache.isPartial[i], isNegative: v < 0)
            let glow = context.glows && emphasized ? color.opacity(0.6) : Color.clear
            let glowRadius: CGFloat = context.glows && emphasized ? 8 : 0
            if stacked {
                BarMark(x: .value("Period", cache.labels[i]), y: .value("Value", context.risen ? v : 0))
                    .foregroundStyle(style)
                    .shadow(color: glow, radius: glowRadius)
                    .accessibilityLabel(namePrefix + cache.titles[i])
                    .accessibilityValue(cache.spoken[s][i])
            } else if isGrouped {
                BarMark(x: .value("Period", cache.labels[i]), y: .value("Value", context.risen ? v : 0), stacking: .unstacked)
                    .cornerRadius(AppRadius.xs)
                    .foregroundStyle(style)
                    .position(by: .value("Type", series.id))
                    .shadow(color: glow, radius: glowRadius)
                    .accessibilityLabel(namePrefix + cache.titles[i])
                    .accessibilityValue(cache.spoken[s][i])
            } else {
                BarMark(
                    x: .value("Period", cache.labels[i]),
                    y: .value("Value", context.risen ? v : 0),
                    width: .ratio(ChartMetrics.barWidthRatio),
                    stacking: .unstacked
                )
                .cornerRadius(AppRadius.xs)
                .foregroundStyle(style)
                .shadow(color: glow, radius: glowRadius)
                .accessibilityLabel(cache.titles[i])
                .accessibilityValue(cache.spoken[s][i])
            }
        }
    }

    /// A dot above a series' highest (success) and lowest (destructive) finished bar; for a
    /// series that is better lower, the other way round.
    @ChartContentBuilder
    private func extremeMarks(_ s: Int, cache: ChartPointCache) -> some ChartContent {
        let series = seriesList[s]
        let lowerIsBetter = series.better == .lower
        let isGrouped = seriesList.count > 1
        if let high = cache.maxIndex[s] {
            extremeDot(label: cache.labels[high], value: cache.values[s][high], seriesID: series.id, isGrouped: isGrouped,
                       color: lowerIsBetter ? AppColors.destructive : AppColors.success)
        }
        if let low = cache.minIndex[s] {
            extremeDot(label: cache.labels[low], value: cache.values[s][low], seriesID: series.id, isGrouped: isGrouped,
                       color: lowerIsBetter ? AppColors.success : AppColors.destructive)
        }
    }

    @ChartContentBuilder
    private func extremeDot(label: String, value: Double, seriesID: String, isGrouped: Bool, color: Color) -> some ChartContent {
        if isGrouped {
            PointMark(x: .value("Period", label), y: .value("Value", value))
                .symbolSize(40)
                .foregroundStyle(color)
                .position(by: .value("Type", seriesID))
                .offset(y: value < 0 ? ChartMetrics.extremeDotOffset : -ChartMetrics.extremeDotOffset)
                .accessibilityHidden(true)
        } else {
            PointMark(x: .value("Period", label), y: .value("Value", value))
                .symbolSize(40)
                .foregroundStyle(color)
                .offset(y: value < 0 ? ChartMetrics.extremeDotOffset : -ChartMetrics.extremeDotOffset)
                .accessibilityHidden(true)
        }
    }

    /// The selected period in full colour, the others a step back; a period that is not over
    /// fades towards the bar's end, as a forecast does.
    static func barStyle(_ color: Color, isSelected: Bool, isPartial: Bool, isNegative: Bool) -> AnyShapeStyle {
        let opacity = isSelected ? 1 : ChartMetrics.dimmedOpacity
        guard isPartial else { return AnyShapeStyle(color.opacity(opacity)) }
        return AnyShapeStyle(LinearGradient(
            colors: [color.opacity(opacity), color.opacity(opacity * ChartMetrics.partialFade)],
            startPoint: isNegative ? .top : .bottom,
            endPoint: isNegative ? .bottom : .top
        ))
    }
}

// MARK: - Skeleton

/// Placeholder of a `BarChart`: the banner's card, then a row of bars with the chart's corner.
/// `series: 2` for a chart of two series, whose banner names each.
public struct BarChartSkeleton: View {
    let bars: Int
    let series: Int

    public init(bars: Int = 12, series: Int = 1) {
        self.bars = max(1, bars)
        self.series = series
    }

    /// Heights of the bars, as shares of the plot: varied, so the row reads as a bar chart.
    private static let shares: [CGFloat] = [0.55, 0.75, 0.45, 0.85, 0.65, 0.95, 0.6, 0.8, 0.5, 0.7, 0.9, 0.65]

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ChartSelectionBannerSkeleton(values: series)
                .screenPadding()
            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                ForEach(0..<bars, id: \.self) { index in
                    Skeleton(
                        height: ChartMetrics.plotHeight * Self.shares[index % Self.shares.count],
                        cornerRadius: AppRadius.xs
                    )
                }
            }
            .frame(height: ChartMetrics.plotHeight, alignment: .bottom)
            .padding(.leading, AppSpacing.lg)
            .shimmer()
        }
        .skeletonLoadingLabel()
    }
}
