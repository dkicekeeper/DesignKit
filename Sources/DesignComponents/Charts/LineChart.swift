//
//  LineChart.swift
//  DesignKit
//
//  Area/line chart for one or more series over category points, ported from Tenra's
//  insights LineChart. Native horizontal scrolling with a sticky leading Y axis; the
//  visible window follows `zoomScale` (ChartSwitcher's −/+). Pinch-to-zoom is not used:
//  it fights the navigation back-swipe.
//
//  Performance rules (charts.md): static Y domain, tap-only selection, cached
//  label → index lookups, no animations on hot-path state.
//

import SwiftUI
import Charts
import DesignTokens
import DesignSupport

/// Scrollable area/line chart with tap selection, a selection banner and a "Today" marker.
///
/// ```swift
/// LineChart(dataPoints: months, series: netFlow, valueFormat: .currency("KZT"))
/// LineChart(dataPoints: months, series: [income, spending])   // overlaid, dual banner
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

    /// External zoom (ChartSwitcher's toolbar); 1.0 when standalone.
    @Binding var zoomScale: CGFloat

    @State private var selectedValueLabel: String?
    @State private var cache = ChartPointCache()

    /// - Parameters:
    ///   - dataPoints: points in X order (oldest first).
    ///   - series: one or more series; several are overlaid and the banner lists each.
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
        self.dataPoints = dataPoints
        self.seriesList = series
        self.valueFormat = valueFormat
        self.todayText = todayText
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self._zoomScale = zoomScale
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
            zoomScale: zoomScale
        )
    }

    private let chartHeight: CGFloat = 200

    /// Static Y domain over the whole dataset (all series), from the cached envelope.
    private var fullYDomain: ClosedRange<Double> {
        paddedChartDomain(
            yMin: cache.yMin,
            yMax: cache.yMax,
            allowsNegative: seriesList.contains { $0.baseline == .signed }
        )
    }

    private var selectedPoint: Point? {
        guard let label = selectedValueLabel,
              let idx = cache.labelToIndex[label] else { return nil }
        return dataPoints[idx]
    }

    /// Points in the visible window: 12 by default; zoom-in halves, zoom-out doubles.
    /// Width-independent: `chartXVisibleDomain(length:)` on a category axis counts categories.
    private var visibleCount: Int {
        let base = 12.0
        let raw = Int((base / max(zoomScale, 0.1)).rounded())
        return max(1, min(dataPoints.count, raw))
    }

    private func rebuildCacheIfNeeded() {
        rebuildChartCacheIfNeeded(cache, points: dataPoints) { p in
            seriesList.map { $0.value(p) }
        }
    }

    // MARK: Body

    public var body: some View {
        // Prime the per-dataset cache before any cache-reading getter fires.
        let _ = rebuildCacheIfNeeded()
        if dataPoints.isEmpty || seriesList.isEmpty {
            emptyState.frame(height: chartHeight)
        } else {
            VStack(spacing: AppSpacing.lg) {
                bannerSlot
                fullChart
                    .padding(.leading, AppSpacing.lg)
                    .frame(height: chartHeight)
            }
            .chartAppear()
        }
    }

    private var bannerSlot: some View {
        ZStack {
            if let p = selectedPoint {
                ChartSelectionBanner(
                    title: p.chartTitle,
                    entries: chartBannerEntries(point: p, series: seriesList),
                    format: valueFormat
                )
                .transition(.opacity)
            }
        }
        .chartBannerSlotStyle(animationKey: selectedPoint?.chartLabel)
        .chartSelectionAnnouncement(announcementText)
    }

    private var announcementText: String? {
        guard let p = selectedPoint else { return nil }
        return chartAnnouncementText(title: p.chartTitle, point: p, series: seriesList, format: valueFormat)
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: emptyTitle,
            description: emptyMessage,
            style: .compact
        )
    }

    // MARK: - Interactive full chart

    private var fullChart: some View {
        let domain = fullYDomain
        // Gradients resolve against the marks' own bounds: use the UNPADDED envelope, not
        // the padded axis domain, or the colour switch drifts above the zero line.
        let styleEnvelope = min(cache.yMin, 0)...max(cache.yMax, 1)
        let lineFills = seriesList.map { $0.lineStyle(yDomain: styleEnvelope) }
        let areaFills = seriesList.map { $0.areaStyle(yDomain: styleEnvelope) }
        let categoryDomain = dataPoints.map(\.chartLabel)
        let leftIdx = max(0, dataPoints.count - visibleCount)
        let trailingAnchorLabel = dataPoints[leftIdx].chartLabel
        let showZeroRule = seriesList.contains(where: \.showsZeroRule)
        let axisLabels = cache.axisLabels
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
            }

            // `series:` + `stacking: .unstacked` keep several series as distinct overlaid
            // lines/areas with a y = 0 baseline. Harmless for one series.
            ForEach(seriesList.indices, id: \.self) { i in
                let s = seriesList[i]
                ForEach(dataPoints) { point in
                    let v = s.value(point)
                    AreaMark(
                        x: .value("Period", point.chartLabel),
                        y: .value("Value", v),
                        series: .value("Type", s.id),
                        stacking: .unstacked
                    )
                    .foregroundStyle(areaFills[i])
                    .interpolationMethod(.monotone)
                    LineMark(
                        x: .value("Period", point.chartLabel),
                        y: .value("Value", v),
                        series: .value("Type", s.id)
                    )
                    .foregroundStyle(lineFills[i])
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: s.lineWidth))
                    PointMark(x: .value("Period", point.chartLabel), y: .value("Value", v))
                        .foregroundStyle(s.color(for: v))
                        .symbolSize(30)
                }
            }

            if showZeroRule {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(AppColors.textTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
            }

            // Selection emphasis — drawn LAST so it is on top: ruler → halo → point.
            // Several series: every series' point at the selected x; zero values are
            // skipped (a halo on the baseline reads as noise).
            if let label = selectedValueLabel,
               let idx = cache.labelToIndex[label] {
                let selected = dataPoints[idx]
                let rulerColor = seriesList.count == 1
                    ? seriesList[0].color(for: seriesList[0].value(selected))
                    : AppColors.accent

                RuleMark(x: .value("Selected", label))
                    .foregroundStyle(rulerColor.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))

                ForEach(seriesList.indices, id: \.self) { i in
                    let s = seriesList[i]
                    let v = s.value(selected)
                    if seriesList.count == 1 || v > 0 {
                        let pointColor = s.color(for: v)
                        PointMark(
                            x: .value("SelectedHalo", selected.chartLabel),
                            y: .value("SelectedV", v)
                        )
                        .symbolSize(180)
                        .foregroundStyle(pointColor.opacity(0.20))

                        PointMark(
                            x: .value("SelectedInner", selected.chartLabel),
                            y: .value("SelectedV", v)
                        )
                        .symbolSize(70)
                        .foregroundStyle(pointColor)
                    }
                }
            }
        }
        // Lock the category order to the data: otherwise Charts derives the x-domain from
        // the first occurrence across marks and the selection ruler reorders the axis.
        .chartXScale(domain: categoryDomain)
        .chartYScale(domain: domain)
        .chartXVisibleDomain(length: visibleCount)
        .chartScrollableAxes(.horizontal)
        .chartScrollPosition(initialX: trailingAnchorLabel)
        .chartXLabelSelectionWithFeedback($selectedValueLabel)
        .chartCategoryXAxis(labelMap: axisLabels)
        .chartCompactYAxis()
        .chartLegend(.hidden)
    }
}
