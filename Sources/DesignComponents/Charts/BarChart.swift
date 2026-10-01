//
//  BarChart.swift
//  DesignKit
//
//  Bar counterpart of LineChart for one or more series over category points, ported
//  from Tenra's insights BarChart. Several series are grouped side by side via
//  `position(by:)`. Paired with LineChart by ChartSwitcher.
//
//  Performance rules (charts.md): static Y domain, tap-only selection, cached
//  label → index lookups, no animations on hot-path state.
//

import SwiftUI
import Charts
import DesignTokens
import DesignSupport

/// Scrollable bar chart with tap selection, a selection banner and a "Today" marker.
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

    /// External zoom (ChartSwitcher's toolbar); 1.0 when standalone.
    @Binding var zoomScale: CGFloat

    @State private var selectedValueLabel: String?
    @State private var cache = ChartPointCache()

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

    /// Static Y domain over the whole dataset with ~6 % headroom (bars touching the plot
    /// edge read as clipped).
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

    /// Width-independent visible window; see LineChart.
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
            icon: "chart.bar",
            title: emptyTitle,
            description: emptyMessage,
            style: .compact
        )
    }

    // MARK: - Interactive full chart

    private var fullChart: some View {
        let domain = fullYDomain
        let categoryDomain = dataPoints.map(\.chartLabel)
        let leftIdx = max(0, dataPoints.count - visibleCount)
        let trailingAnchorLabel = dataPoints[leftIdx].chartLabel
        let isGrouped = seriesList.count > 1
        let showZeroRule = seriesList.contains(where: \.showsZeroRule)
        let axisLabels = cache.axisLabels
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
            }

            ForEach(seriesList.indices, id: \.self) { i in
                let s = seriesList[i]
                ForEach(dataPoints) { point in
                    let v = s.value(point)
                    // Per-value colour: signed series read green above zero, red below.
                    if isGrouped {
                        BarMark(
                            x: .value("Period", point.chartLabel),
                            y: .value("Value", v)
                        )
                        .cornerRadius(AppRadius.xs)
                        .foregroundStyle(s.color(for: v).opacity(0.85))
                        .position(by: .value("Type", s.id))
                    } else {
                        BarMark(
                            x: .value("Period", point.chartLabel),
                            y: .value("Value", v)
                        )
                        .cornerRadius(AppRadius.xs)
                        .foregroundStyle(s.color(for: v).opacity(0.85))
                    }
                }
            }

            if showZeroRule {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(AppColors.textTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
            }

            // Selection emphasis last: translucent column band + a ruler through its centre.
            if let label = selectedValueLabel {
                RectangleMark(x: .value("SelBand", label))
                    .foregroundStyle(AppColors.accent.opacity(0.10))

                RuleMark(x: .value("Selected", label))
                    .foregroundStyle(AppColors.accent.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
        }
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
