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
//  window; the banner always shows the selected period, names the series and gives the
//  change from the period before. A clean line (no dot on every value), a fill only under a
//  lone series, a dashed last stretch for a period that is not over and a dotted rise to its
//  forecast, a pale dashed line a year back, reference lines, records, a picked stretch, a
//  soft glow in dark mode.
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
/// LineChart(dataPoints: months, series: spending, referenceLines: [.average()], marksExtremes: true)
/// ```
///
/// A long press and a drag pick a stretch of periods: the banner sums it up.
///
/// For a card-sized trend use `Sparkline` (Canvas, no Charts render tree).
public struct LineChart<Point: ChartPoint>: View {
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

    /// - Parameters:
    ///   - dataPoints: points in X order (oldest first).
    ///   - series: one or more series; several are overlaid and the banner lists each by name.
    ///   - valueFormat: banner / VoiceOver value format. The Y axis is always compact.
    ///   - todayText: label of the "Today" marker (key `chart.today`).
    ///   - emptyTitle / emptyMessage: empty state (keys `chart.empty.title` / `chart.empty.message`).
    ///   - zoomScale: visible-window scale; 1.0 shows 12 points.
    ///   - referenceLines: an average, a limit, a goal across the plot (8.2.0).
    ///   - marksExtremes: dots on each series' highest and lowest finished period (8.2.0).
    ///   - followsScroll: a ruler in the window's middle; the chart scrolls under it and the
    ///     period at the ruler is the selection, with a tick (8.2.0).
    ///   - comparisonLabel: the banner's line for `ChartSeries.comparison` (key `chart.yearAgo`).
    public init(
        dataPoints: [Point],
        series: [ChartSeries<Point>],
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

    /// ChartSwitcher's: the options, and the selection that outlives a switch to the bars.
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
                entrance: .drawIn,
                options: options
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
            // The picked stretch, behind everything.
            ChartRangeBands(range: context.range, labels: cache.labels)

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

            if context.showsComparison {
                ForEach(seriesList.indices, id: \.self) { s in
                    comparisonMarks(s, cache: cache)
                }
            }

            ForEach(seriesList.indices, id: \.self) { s in
                seriesMarks(s, context: context, lineFill: lineFills[s], areaFill: areaFills[s])
            }

            if context.showsForecast {
                ForEach(seriesList.indices, id: \.self) { s in
                    forecastMarks(s, cache: cache)
                }
            }

            if showZeroRule {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(AppColors.Text.tertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .accessibilityHidden(true)
            }

            ChartReferenceRules(references: context.references)

            if context.marksExtremes {
                ForEach(seriesList.indices, id: \.self) { s in
                    extremeMarks(s, cache: cache)
                }
            }

            // Selection emphasis — drawn LAST so it is on top: ruler → halo → dot. Following the
            // scroll, the frame's ruler in the middle is the selection: the marks stay as they
            // are while the chart scrolls under it.
            if let range = context.range {
                selectionMarks(index: range.lowerBound, context: context)
                selectionMarks(index: range.upperBound, context: context)
            } else if !context.followsScroll {
                selectionMarks(index: context.selectedIndex, context: context)
            }
        }
    }

    /// One series: the fill (a lone series only: two fills over each other turn muddy), the
    /// line, and a dashed stretch into the periods that are not over. The fill stops where the
    /// stretch starts, as under a forecast: it is a curve and the stretch a straight dash, so a
    /// fill under the stretch would bulge past it. In dark mode the line glows.
    @ChartContentBuilder
    private func seriesMarks(
        _ s: Int,
        context: TrendChartContext,
        lineFill: AnyShapeStyle,
        areaFill: AnyShapeStyle
    ) -> some ChartContent {
        let cache = context.cache
        let series = seriesList[s]
        let values = cache.values[s]
        let hasFill = seriesList.count == 1
        let hasPartial = cache.partialStart != nil
        let partialStart = cache.partialStart ?? cache.labels.count
        let solid = StrokeStyle(lineWidth: series.lineWidth, lineCap: .round, lineJoin: .round)
        let dashed = StrokeStyle(lineWidth: series.lineWidth, lineCap: .round, lineJoin: .round, dash: ChartMetrics.partialDash)
        let namePrefix = seriesList.count > 1 ? "\(series.name), " : ""
        let glow = context.glows ? series.color(for: values.last ?? 0).opacity(0.6) : Color.clear
        let glowRadius: CGFloat = context.glows ? 6 : 0

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
                .shadow(color: glow, radius: glowRadius)
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
                .shadow(color: glow, radius: glowRadius)
                .accessibilityLabel(namePrefix + cache.titles[i])
                .accessibilityValue(cache.spoken[s][i])
                // The stretch starts on the last finished period, already read above.
                .accessibilityHidden(i < partialStart)
            }
        }
    }

    /// The same periods a cycle before (`ChartSeries.comparison`): a thin pale dashed line.
    @ChartContentBuilder
    private func comparisonMarks(_ s: Int, cache: ChartPointCache) -> some ChartContent {
        let series = seriesList[s]
        let before = cache.comparison[s]
        let color = series.color(for: cache.values[s].last ?? 0).opacity(0.45)

        ForEach(cache.labels.indices, id: \.self) { i in
            if let v = before[i] {
                LineMark(
                    x: .value("Period", cache.labels[i]),
                    y: .value("Value", v),
                    series: .value("Type", series.id + ChartComparisonSeries.suffix)
                )
                .foregroundStyle(color)
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [2, 3]))
                .accessibilityHidden(true)
            }
        }
    }

    /// A period not over with a forecast: a dotted rise from its value so far to the forecast,
    /// ending in a hollow ring (dashed and hollow: not yet real).
    @ChartContentBuilder
    private func forecastMarks(_ s: Int, cache: ChartPointCache) -> some ChartContent {
        let series = seriesList[s]
        let forecasts = cache.projected[s]

        ForEach(cache.labels.indices, id: \.self) { i in
            if let forecast = forecasts[i] {
                let color = series.color(for: forecast)
                RuleMark(
                    x: .value("Period", cache.labels[i]),
                    yStart: .value("Value", cache.values[s][i]),
                    yEnd: .value("Value", forecast)
                )
                .foregroundStyle(color.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 4]))
                .accessibilityHidden(true)
                PointMark(x: .value("Period", cache.labels[i]), y: .value("Value", forecast))
                    .symbol { ChartForecastRing(color: color) }
                    .accessibilityHidden(true)
            }
        }
    }

    /// Dots on a series' highest (success) and lowest (destructive) finished period; for a
    /// series that is better lower, the other way round.
    @ChartContentBuilder
    private func extremeMarks(_ s: Int, cache: ChartPointCache) -> some ChartContent {
        let lowerIsBetter = seriesList[s].better == .lower
        if let high = cache.maxIndex[s] {
            PointMark(x: .value("Period", cache.labels[high]), y: .value("Value", cache.values[s][high]))
                .symbolSize(70)
                .foregroundStyle(lowerIsBetter ? AppColors.destructive : AppColors.success)
                .accessibilityHidden(true)
        }
        if let low = cache.minIndex[s] {
            PointMark(x: .value("Period", cache.labels[low]), y: .value("Value", cache.values[s][low]))
                .symbolSize(70)
                .foregroundStyle(lowerIsBetter ? AppColors.success : AppColors.destructive)
                .accessibilityHidden(true)
        }
    }

    /// A ruler through a period (none at the ends of a stretch picked while following the
    /// scroll: the frame draws its ruler), a halo and a ringed dot on each series' value there.
    /// Several series: zero values are skipped (a halo on the baseline reads as noise).
    @ChartContentBuilder
    private func selectionMarks(index: Int, context: TrendChartContext) -> some ChartContent {
        let cache = context.cache
        let label = cache.labels[index]
        let rulerColor = seriesList.count == 1
            ? seriesList[0].color(for: cache.values[0][index])
            : AppColors.accent

        if !context.followsScroll {
            RuleMark(x: .value("Selected", label))
                .foregroundStyle(rulerColor.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .accessibilityHidden(true)
        }

        ForEach(seriesList.indices, id: \.self) { s in
            let v = cache.values[s][index]
            if seriesList.count == 1 || v != 0 {
                let color = seriesList[s].color(for: v)
                PointMark(x: .value("SelectedHalo", label), y: .value("SelectedV", v))
                    .symbolSize(ChartMetrics.haloSize)
                    .foregroundStyle(color.opacity(0.20))
                    .accessibilityHidden(true)
                PointMark(x: .value("SelectedDot", label), y: .value("SelectedV", v))
                    .symbol { ChartSelectedDot(color: color, glows: context.glows) }
                    .accessibilityHidden(true)
            }
        }
    }
}

/// The dashed stretch of a line is a series of its own.
enum ChartPartialSeries {
    static let suffix = "\u{2063}partial"
}

/// So is the pale line of a comparison.
enum ChartComparisonSeries {
    static let suffix = "\u{2063}comparison"
}

/// A forecast's end: a hollow ring (8.2.0).
struct ChartForecastRing: View {
    let color: Color

    var body: some View {
        Circle()
            .strokeBorder(color, lineWidth: 2)
            .background(Circle().fill(AppColors.Background.base))
            .frame(width: 11, height: 11)
    }
}

/// The picked stretch: a pale band over its periods (8.2.0).
struct ChartRangeBands: ChartContent {
    let range: ClosedRange<Int>?
    let labels: [String]

    var body: some ChartContent {
        if let range {
            ForEach(Array(range), id: \.self) { i in
                RectangleMark(x: .value("Range", labels[i]))
                    .foregroundStyle(AppColors.accent.opacity(0.08))
                    .accessibilityHidden(true)
            }
        }
    }
}

/// The reference lines: dashed rules across the plot; their labels are the frame's overlay
/// (8.2.0).
struct ChartReferenceRules: ChartContent {
    let references: [ChartResolvedReference]

    var body: some ChartContent {
        ForEach(references, id: \.id) { reference in
            RuleMark(y: .value("Reference", reference.value))
                .foregroundStyle(reference.color.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                .accessibilityLabel(reference.label)
                .accessibilityValue(ChartValueFormat.compactString(reference.value))
        }
    }
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
