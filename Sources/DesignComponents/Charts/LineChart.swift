//
//  LineChart.swift
//  DesignKit
//
//  Area/line chart for one or more series over category points, ported from Tenra's
//  insights LineChart. Native horizontal scrolling with a sticky leading Y axis; the
//  visible window follows `zoomScale` (ChartSwitcher's −/+). Pinch-to-zoom is not used:
//  it fights the navigation back-swipe.
//
//  8.2.0 (TrendChartFrame): opens on the current period, selected and in the middle of the
//  window; the banner always shows the selected period and names the series. A clean line
//  (no dot on every value), a fill only under a lone series, a dashed last stretch for a
//  period that is not over.
//
//  Performance rules (charts.md): static Y domain, values read from the cache, tap-only
//  selection, no animations on hot-path state.
//

import SwiftUI
import Charts
import DesignTokens
import DesignSupport

/// Scrollable area/line chart that opens on the current period, with tap selection, a banner
/// and a "Today" marker.
///
/// ```swift
/// LineChart(dataPoints: months, series: netFlow, valueFormat: .currency("KZT"))
/// LineChart(dataPoints: months, series: [income, spending])   // overlaid, the banner names both
/// ```
///
/// For a card-sized trend use `Sparkline` (Canvas, no Charts render tree).
public struct LineChart<Point: ChartPoint>: View {
    let dataPoints: [Point]
    let seriesList: [ChartSeries<Point>]
    let valueFormat: ChartValueFormat
    let todayText: String
    let emptyTitle: String
    let emptyMessage: String?
    let selection: Binding<String?>?

    /// External zoom (ChartSwitcher's toolbar); 1.0 when standalone.
    @Binding var zoomScale: CGFloat

    /// - Parameters:
    ///   - dataPoints: points in X order (oldest first).
    ///   - series: one or more series; several are overlaid and the banner lists each by name.
    ///   - valueFormat: banner / VoiceOver value format. The Y axis is always compact.
    ///   - todayText: label of the "Today" marker (key `chart.today`).
    ///   - emptyTitle / emptyMessage: empty state (keys `chart.empty.title` / `chart.empty.message`).
    ///   - zoomScale: visible-window scale; 1.0 shows 12 points.
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

    /// ChartSwitcher's: the selection outlives a switch to the bars.
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
                icon: "chart.line.uptrend.xyaxis",
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
                entrance: .drawIn
            ) { context in
                plot(context)
            }
        }
    }

    // MARK: - Marks

    private func plot(_ context: TrendChartContext) -> some View {
        let cache = context.cache
        // Gradients resolve against the marks' own bounds: use the UNPADDED envelope, not
        // the padded axis domain, or the colour switch drifts above the zero line.
        let styleEnvelope = min(cache.yMin, 0)...max(cache.yMax, 1)
        let lineFills = seriesList.map { $0.lineStyle(yDomain: styleEnvelope) }
        let areaFills = seriesList.map { $0.areaStyle(yDomain: styleEnvelope) }
        let showZeroRule = seriesList.contains(where: \.showsZeroRule)
        return Chart {
            // Today / future boundary — drawn first; today is one of the categories.
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
                seriesMarks(s, cache: cache, lineFill: lineFills[s], areaFill: areaFills[s])
            }

            if showZeroRule {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(AppColors.Text.tertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .accessibilityHidden(true)
            }

            // Selection emphasis — drawn LAST so it is on top: ruler → halo → dot.
            selectionMarks(index: context.selectedIndex, cache: cache)
        }
    }

    /// One series: the fill (a lone series only: two fills over each other turn muddy), the
    /// line, and a dashed stretch into the periods that are not over. The fill stops where the
    /// stretch starts, as under a forecast: it is a curve and the stretch a straight dash, so a
    /// fill under the stretch would bulge past it.
    @ChartContentBuilder
    private func seriesMarks(
        _ s: Int,
        cache: ChartPointCache,
        lineFill: AnyShapeStyle,
        areaFill: AnyShapeStyle
    ) -> some ChartContent {
        let series = seriesList[s]
        let values = cache.values[s]
        let hasFill = seriesList.count == 1
        let hasPartial = cache.partialStart != nil
        let partialStart = cache.partialStart ?? cache.labels.count
        let solid = StrokeStyle(lineWidth: series.lineWidth, lineCap: .round, lineJoin: .round)
        let dashed = StrokeStyle(lineWidth: series.lineWidth, lineCap: .round, lineJoin: .round, dash: ChartMetrics.partialDash)
        let namePrefix = seriesList.count > 1 ? "\(series.name), " : ""

        ForEach(cache.labels.indices, id: \.self) { i in
            if hasFill && i < partialStart {
                // `series:` + `stacking: .unstacked` keep the area on its own y = 0 baseline.
                AreaMark(
                    x: .value("Period", cache.labels[i]),
                    y: .value("Value", values[i]),
                    series: .value("Type", series.id),
                    stacking: .unstacked
                )
                .foregroundStyle(areaFill)
                .interpolationMethod(.monotone)
                .accessibilityHidden(true)
            }
            if i < partialStart {
                LineMark(
                    x: .value("Period", cache.labels[i]),
                    y: .value("Value", values[i]),
                    series: .value("Type", series.id)
                )
                .foregroundStyle(lineFill)
                .interpolationMethod(.monotone)
                .lineStyle(solid)
                .accessibilityLabel(namePrefix + cache.titles[i])
                .accessibilityValue(cache.spoken[s][i])
            }
            if hasPartial && i >= max(partialStart - 1, 0) {
                LineMark(
                    x: .value("Period", cache.labels[i]),
                    y: .value("Value", values[i]),
                    series: .value("Type", series.id + ChartPartialSeries.suffix)
                )
                .foregroundStyle(lineFill)
                .interpolationMethod(.monotone)
                .lineStyle(dashed)
                .accessibilityLabel(namePrefix + cache.titles[i])
                .accessibilityValue(cache.spoken[s][i])
                // The stretch starts on the last finished period, already read above.
                .accessibilityHidden(i < partialStart)
            }
        }
    }

    /// A ruler through the selected period, a halo and a ringed dot on each series' value
    /// there. Several series: zero values are skipped (a halo on the baseline reads as noise).
    @ChartContentBuilder
    private func selectionMarks(index: Int, cache: ChartPointCache) -> some ChartContent {
        let label = cache.labels[index]
        let rulerColor = seriesList.count == 1
            ? seriesList[0].color(for: cache.values[0][index])
            : AppColors.accent

        RuleMark(x: .value("Selected", label))
            .foregroundStyle(rulerColor.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .accessibilityHidden(true)

        ForEach(seriesList.indices, id: \.self) { s in
            let v = cache.values[s][index]
            if seriesList.count == 1 || v != 0 {
                let color = seriesList[s].color(for: v)
                PointMark(x: .value("SelectedHalo", label), y: .value("SelectedV", v))
                    .symbolSize(ChartMetrics.haloSize)
                    .foregroundStyle(color.opacity(0.20))
                    .accessibilityHidden(true)
                PointMark(x: .value("SelectedDot", label), y: .value("SelectedV", v))
                    .symbol { ChartSelectedDot(color: color) }
                    .accessibilityHidden(true)
            }
        }
    }
}

/// The dashed stretch of a line is a series of its own.
enum ChartPartialSeries {
    static let suffix = "\u{2063}partial"
}

// MARK: - Skeleton

/// Placeholder of a `LineChart`: the banner's card, then the plot area with a soft corner.
/// `series: 2` for a chart of two series, whose banner names each.
public struct LineChartSkeleton: View {
    let series: Int

    public init(series: Int = 1) {
        self.series = series
    }

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ChartSelectionBannerSkeleton(values: series)
                .screenPadding()
            Skeleton(height: ChartMetrics.plotHeight)
                .padding(.leading, AppSpacing.lg)
        }
        .skeletonLoadingLabel()
    }
}
