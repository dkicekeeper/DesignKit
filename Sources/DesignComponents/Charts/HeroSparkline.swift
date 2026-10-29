//
//  HeroSparkline.swift
//  DesignKit
//
//  Full-size interactive sibling of `Sparkline` for a detail screen's hero (Tenra's
//  insight detail): a real Swift Charts view with tap selection, haptic and banner,
//  plus what the plain charts cannot express:
//  - dashed projection tail to `projectedValue`, hollow endpoint (not yet real)
//  - min/max extreme markers (period records)
//  - "you are here" dot on the last point
//
//  Not scrollable: the hero shows the whole series at a glance; ChartSwitcher is the
//  tool for scrolling. Unlike LineChart it opens with nothing selected: the screen's header
//  already shows the latest value.
//
//  8.3.0: values come from the shared cache (read once per dataset, refreshed when they
//  change), the banner's slot grows with Dynamic Type, VoiceOver reads each period by its
//  title with the value in the chart's format.
//

import SwiftUI
import Charts
import DesignTokens
import DesignSupport

/// Hero trend chart of one series. Draws nothing with fewer than two points.
///
/// ```swift
/// HeroSparkline(dataPoints: months, series: spending, projectedValue: forecast,
///               valueFormat: .currency("KZT"), entranceDelay: 0.35)
/// ```
public struct HeroSparkline<Point: ChartPoint>: View {
    let dataPoints: [Point]
    let series: ChartSeries<Point>
    let projectedValue: Double?
    let markExtremes: Bool
    let valueFormat: ChartValueFormat
    let entranceDelay: Double

    @State private var selectedValueLabel: String?
    @State private var cache = ChartPointCache()
    /// The chart's width, for how many X axis labels fit.
    @State private var chartWidth: CGFloat = 0
    /// `AppTypography.caption2` at the person's text size.
    @ScaledMetric(relativeTo: .caption2) private var axisFontSize: CGFloat = 12
    /// Inside `.heroBackground(_:)` (4.5.0): a white line over a white fade, white points,
    /// translucent white axes.
    @Environment(\.heroTone) private var heroTone

    private var onColor: Bool { heroTone == .onColor }

    /// - Parameters:
    ///   - projectedValue: forecast endpoint drawn after the last point (dashed, hollow).
    ///   - markExtremes: success dot on the max, destructive dot on the min.
    ///   - valueFormat: banner / VoiceOver value format.
    ///   - entranceDelay: extra delay of the entrance animation — pass the navigation
    ///     transition's duration so the chart appears after the push settles.
    public init(
        dataPoints: [Point],
        series: ChartSeries<Point>,
        projectedValue: Double? = nil,
        markExtremes: Bool = false,
        valueFormat: ChartValueFormat = .compact,
        entranceDelay: Double = 0
    ) {
        self.dataPoints = dataPoints
        self.series = series
        self.projectedValue = projectedValue
        self.markExtremes = markExtremes
        self.valueFormat = valueFormat
        self.entranceDelay = entranceDelay
    }

    private var chartHeight: CGFloat { ChartMetrics.heroPlotHeight }
    /// Synthetic category carrying the projection endpoint. Not in `labelToIndex`, so
    /// tapping it never selects anything.
    private static var projectionLabel: String { "→" }

    /// The series' values, read once per dataset (8.3.0: on every render before).
    private var values: [Double] { cache.values.first ?? [] }

    /// Last-point dot and projection tail: the solid colour, or the latest value's sign.
    private var tintColor: Color { onColor ? ChartOnColor.mark : series.color(for: values.last ?? 0) }

    /// Padded axis domain (~6 % headroom) including the projection endpoint.
    private var yDomain: ClosedRange<Double> {
        var domainValues = values
        if let projectedValue { domainValues.append(projectedValue) }
        let raw = series.yDomain(values: domainValues)
        let headroom = (raw.upperBound - raw.lowerBound) * 0.06
        let paddedMin = raw.lowerBound < 0 ? raw.lowerBound - headroom : raw.lowerBound
        return paddedMin...(raw.upperBound + headroom)
    }

    private func rebuildCacheIfNeeded() {
        rebuildChartCacheIfNeeded(cache, points: dataPoints, series: [series], format: valueFormat)
    }

    // MARK: - Body

    public var body: some View {
        let _ = rebuildCacheIfNeeded()
        if dataPoints.count >= 2 {
            VStack(spacing: AppSpacing.lg) {
                bannerSlot
                chart
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { chartWidth = $0 }
                    .padding(.leading, AppSpacing.lg)
                    .padding(.trailing, AppSpacing.lg)
                    .frame(height: chartHeight)
                    // 2.3.0: the line is traced in from the left.
                    .chartDrawIn(delay: entranceDelay)
            }
            .chartAppear(delay: entranceDelay)
        }
    }

    private var bannerSlot: some View {
        ZStack {
            if let label = selectedValueLabel, let index = cache.labelToIndex[label] {
                ChartSelectionBanner(
                    title: cache.titles[index],
                    note: cache.isPartial[index] ? ChartText.partial : nil,
                    entries: chartBannerEntries(index: index, cache: cache, series: [series]),
                    format: valueFormat
                )
                .transition(.opacity)
            }
        }
        .chartBannerSlotStyle(animationKey: selectedValueLabel)
        .chartSelectionAnnouncement(announcementText)
    }

    private var announcementText: String? {
        guard let label = selectedValueLabel, let index = cache.labelToIndex[label] else { return nil }
        return chartAnnouncementText(title: cache.titles[index], index: index, cache: cache, series: [series])
    }

    // MARK: - Chart

    private var chart: some View {
        let domain = yDomain
        // Style gradients resolve against the marks' own bounds: UNPADDED envelope.
        let styleEnvelope = min(cache.yMin, 0)...max(cache.yMax, 1)
        let lineFill = onColor ? AnyShapeStyle(ChartOnColor.mark) : series.lineStyle(yDomain: styleEnvelope)
        let areaFill = onColor ? ChartOnColor.area : series.areaStyle(yDomain: styleEnvelope)
        let onColor = self.onColor
        var categoryDomain = cache.labels
        if projectedValue != nil { categoryDomain.append(Self.projectionLabel) }
        let tint = tintColor
        let vals = values
        let axisLabels = cache.axisLabels

        let labels = cache.labels
        let titles = cache.titles
        let spoken = cache.spoken.first ?? []
        let selectedIndex = selectedValueLabel.flatMap { cache.labelToIndex[$0] }
        let fitted = ChartAxisLabels(
            cache: cache,
            anchorIndex: labels.count - 1,
            selectedIndex: selectedIndex,
            visibleCount: categoryDomain.count,
            alignsTrailingEdge: projectedValue == nil,
            chartWidth: chartWidth,
            yDomain: domain,
            fontSize: axisFontSize
        )
        let axisLabelPlan = projectedValue != nil ? fitted.appending(Self.projectionLabel) : fitted

        return Chart {
            ForEach(labels.indices, id: \.self) { i in
                AreaMark(
                    x: .value("Period", labels[i]),
                    y: .value("Value", vals[i]),
                    series: .value("Type", "fact"),
                    stacking: .unstacked
                )
                .foregroundStyle(areaFill)
                .interpolationMethod(.monotone)
                .accessibilityHidden(true)
                LineMark(
                    x: .value("Period", labels[i]),
                    y: .value("Value", vals[i]),
                    series: .value("Type", "fact")
                )
                .foregroundStyle(lineFill)
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .accessibilityLabel(titles[i])
                .accessibilityValue(spoken[i])
            }

            if series.showsZeroRule, domain.lowerBound < 0 {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(onColor ? ChartOnColor.label : AppColors.Text.tertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .accessibilityHidden(true)
            }

            // Dashed projection tail: last point → forecast endpoint, hollow dot.
            if let projectedValue, let last = dataPoints.last {
                LineMark(
                    x: .value("Period", last.chartLabel),
                    y: .value("Value", series.value(last)),
                    series: .value("Type", "projection")
                )
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                LineMark(
                    x: .value("Period", Self.projectionLabel),
                    y: .value("Value", projectedValue),
                    series: .value("Type", "projection")
                )
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                PointMark(
                    x: .value("Period", Self.projectionLabel),
                    y: .value("Value", projectedValue)
                )
                .symbol {
                    Circle()
                        .strokeBorder(tint, lineWidth: 2)
                        .frame(width: 11, height: 11)
                        .background(Circle().fill(onColor ? Color.clear : AppColors.Background.base))
                }
            }

            // Extremes: max (success) and min (destructive).
            if markExtremes,
               let maxIdx = vals.indices.max(by: { vals[$0] < vals[$1] }),
               let minIdx = vals.indices.min(by: { vals[$0] < vals[$1] }),
               maxIdx != minIdx {
                PointMark(
                    x: .value("Period", dataPoints[maxIdx].chartLabel),
                    y: .value("Value", vals[maxIdx])
                )
                .symbolSize(90)
                .foregroundStyle(onColor ? ChartOnColor.mark : AppColors.success)
                .accessibilityHidden(true)
                PointMark(
                    x: .value("Period", dataPoints[minIdx].chartLabel),
                    y: .value("Value", vals[minIdx])
                )
                .symbolSize(90)
                .foregroundStyle(onColor ? ChartOnColor.label : AppColors.destructive)
                .accessibilityHidden(true)
            }

            // "You are here" dot on the last point.
            if let last = dataPoints.last {
                PointMark(
                    x: .value("Period", last.chartLabel),
                    y: .value("Value", series.value(last))
                )
                .symbolSize(55)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            }

            // Selection emphasis — drawn LAST; the x-domain is locked by chartXScale.
            if let i = selectedIndex {
                let v = vals[i]
                let pointColor = onColor ? ChartOnColor.mark : series.color(for: v)
                RuleMark(x: .value("Selected", labels[i]))
                    .foregroundStyle(pointColor.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .accessibilityHidden(true)
                PointMark(x: .value("SelectedHalo", labels[i]), y: .value("SelectedV", v))
                    .symbolSize(180)
                    .foregroundStyle(pointColor.opacity(0.20))
                    .accessibilityHidden(true)
                PointMark(x: .value("SelectedInner", labels[i]), y: .value("SelectedV", v))
                    .symbolSize(70)
                    .foregroundStyle(pointColor)
                    .accessibilityHidden(true)
            }
        }
        .chartXScale(domain: categoryDomain)
        .chartYScale(domain: domain)
        .chartXLabelSelectionWithFeedback($selectedValueLabel)
        .chartCategoryXAxis(labelMap: axisLabels, labels: axisLabelPlan, tone: heroTone)
        .chartCompactYAxis(tone: heroTone)
        .chartLegend(.hidden)
    }
}

// MARK: - Skeleton

/// Placeholder of a `HeroSparkline`: the banner slot, then the plot area with a soft corner.
public struct HeroSparklineSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Color.clear.frame(height: ChartMetrics.bannerHeight)
            Skeleton(height: ChartMetrics.heroPlotHeight)
                .padding(.horizontal, AppSpacing.lg)
        }
        .skeletonLoadingLabel()
    }
}
