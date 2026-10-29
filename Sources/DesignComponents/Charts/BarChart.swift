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
//  ran through the bar before); the bars rise from zero as the chart appears; the bar of a
//  period that is not over fades towards its top.
//
//  Performance rules (charts.md): static Y domain, values read from the cache, tap-only
//  selection, no animations on hot-path state.
//

import SwiftUI
import Charts
import DesignTokens
import DesignSupport

/// Scrollable bar chart that opens on the current period, with tap selection, a banner and a
/// "Today" marker.
///
/// ```swift
/// BarChart(dataPoints: months, series: spending, valueFormat: .currency("KZT"))
/// BarChart(dataPoints: months, series: [income, spending])   // grouped bars
/// ```
public struct BarChart<Point: ChartPoint>: View {
    let dataPoints: [Point]
    let seriesList: [ChartSeries<Point>]
    let valueFormat: ChartValueFormat
    let todayText: String
    let emptyTitle: String
    let emptyMessage: String?
    let selection: Binding<String?>?

    /// External zoom (ChartSwitcher's toolbar); 1.0 when standalone.
    @Binding var zoomScale: CGFloat

    /// Parameters as in `LineChart`.
    public init(
        dataPoints: [Point],
        series: [ChartSeries<Point>],
        valueFormat: ChartValueFormat = .compact,
        todayText: String = String(localized: "chart.today"),
        emptyTitle: String = String(localized: "chart.empty.title"),
        emptyMessage: String? = String(localized: "chart.empty.message"),
        zoomScale: Binding<CGFloat> = .constant(1.0)
    ) {
        self.init(
            dataPoints: dataPoints,
            series: series,
            valueFormat: valueFormat,
            todayText: todayText,
            emptyTitle: emptyTitle,
            emptyMessage: emptyMessage,
            zoomScale: zoomScale,
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
        zoomScale: Binding<CGFloat> = .constant(1.0)
    ) {
        self.init(
            dataPoints: dataPoints,
            series: [series],
            valueFormat: valueFormat,
            todayText: todayText,
            emptyTitle: emptyTitle,
            emptyMessage: emptyMessage,
            zoomScale: zoomScale,
            selection: nil
        )
    }

    /// ChartSwitcher's: the selection outlives a switch to the line.
    init(
        dataPoints: [Point],
        series: [ChartSeries<Point>],
        valueFormat: ChartValueFormat,
        todayText: String,
        emptyTitle: String,
        emptyMessage: String?,
        zoomScale: Binding<CGFloat>,
        selection: Binding<String?>?
    ) {
        self.dataPoints = dataPoints
        self.seriesList = series
        self.valueFormat = valueFormat
        self.todayText = todayText
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self._zoomScale = zoomScale
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
                entrance: .rise
            ) { context in
                plot(context)
            }
        }
    }

    // MARK: - Marks

    private func plot(_ context: TrendChartContext) -> some View {
        let cache = context.cache
        let showZeroRule = seriesList.contains(where: \.showsZeroRule)
        return Chart {
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

            ForEach(seriesList.indices, id: \.self) { s in
                seriesBars(s, context: context)
            }

            if showZeroRule {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(AppColors.Text.tertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .accessibilityHidden(true)
            }
        }
    }

    /// One series' bars. Per-value colour: signed series read green above zero, red below.
    @ChartContentBuilder
    private func seriesBars(_ s: Int, context: TrendChartContext) -> some ChartContent {
        let cache = context.cache
        let series = seriesList[s]
        let values = cache.values[s]
        let isGrouped = seriesList.count > 1
        let namePrefix = isGrouped ? "\(series.name), " : ""

        ForEach(cache.labels.indices, id: \.self) { i in
            let v = values[i]
            let style = Self.barStyle(
                series.color(for: v),
                isSelected: i == context.selectedIndex,
                isPartial: cache.isPartial[i],
                isNegative: v < 0
            )
            if isGrouped {
                BarMark(
                    x: .value("Period", cache.labels[i]),
                    y: .value("Value", context.risen ? v : 0)
                )
                .cornerRadius(AppRadius.xs)
                .foregroundStyle(style)
                .position(by: .value("Type", series.id))
                .accessibilityLabel(namePrefix + cache.titles[i])
                .accessibilityValue(cache.spoken[s][i])
            } else {
                BarMark(
                    x: .value("Period", cache.labels[i]),
                    y: .value("Value", context.risen ? v : 0),
                    width: .ratio(ChartMetrics.barWidthRatio)
                )
                .cornerRadius(AppRadius.xs)
                .foregroundStyle(style)
                .accessibilityLabel(cache.titles[i])
                .accessibilityValue(cache.spoken[s][i])
            }
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
