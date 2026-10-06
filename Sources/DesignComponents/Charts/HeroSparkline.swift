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
//  tool for scrolling.
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

    private var values: [Double] { dataPoints.map(series.value) }

    /// Last-point dot and projection tail: the solid colour, or the latest value's sign.
    private var tintColor: Color { series.color(for: values.last ?? 0) }

    /// Padded axis domain (~6 % headroom) including the projection endpoint.
    private var yDomain: ClosedRange<Double> {
        var domainValues = values
        if let projectedValue { domainValues.append(projectedValue) }
        let raw = series.yDomain(values: domainValues)
        let headroom = (raw.upperBound - raw.lowerBound) * 0.06
        let paddedMin = raw.lowerBound < 0 ? raw.lowerBound - headroom : raw.lowerBound
        return paddedMin...(raw.upperBound + headroom)
    }

    private var selectedPoint: Point? {
        guard let label = selectedValueLabel,
              let idx = cache.labelToIndex[label] else { return nil }
        return dataPoints[idx]
    }

    private func rebuildCacheIfNeeded() {
        rebuildChartCacheIfNeeded(cache, points: dataPoints) { p in
            [series.value(p)]
        }
    }

    // MARK: - Body

    public var body: some View {
        let _ = rebuildCacheIfNeeded()
        if dataPoints.count >= 2 {
            VStack(spacing: AppSpacing.lg) {
                bannerSlot
                chart
                    .padding(.leading, AppSpacing.lg)
                    .padding(.trailing, AppSpacing.lg)
                    .frame(height: chartHeight)
            }
            .chartAppear(delay: entranceDelay)
        }
    }

    private var bannerSlot: some View {
        ZStack {
            if let p = selectedPoint {
                ChartSelectionBanner(
                    title: p.chartTitle,
                    entries: chartBannerEntries(point: p, series: [series]),
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
        return chartAnnouncementText(title: p.chartTitle, point: p, series: [series], format: valueFormat)
    }

    // MARK: - Chart

    private var chart: some View {
        let domain = yDomain
        // Style gradients resolve against the marks' own bounds: UNPADDED envelope.
        let styleEnvelope = min(cache.yMin, 0)...max(cache.yMax, 1)
        let lineFill = series.lineStyle(yDomain: styleEnvelope)
        let areaFill = series.areaStyle(yDomain: styleEnvelope)
        var categoryDomain = dataPoints.map(\.chartLabel)
        if projectedValue != nil { categoryDomain.append(Self.projectionLabel) }
        let tint = tintColor
        let vals = values
        let axisLabels = cache.axisLabels

        return Chart {
            ForEach(dataPoints) { point in
                let v = series.value(point)
                AreaMark(
                    x: .value("Period", point.chartLabel),
                    y: .value("Value", v),
                    series: .value("Type", "fact"),
                    stacking: .unstacked
                )
                .foregroundStyle(areaFill)
                .interpolationMethod(.monotone)
                LineMark(
                    x: .value("Period", point.chartLabel),
                    y: .value("Value", v),
                    series: .value("Type", "fact")
                )
                .foregroundStyle(lineFill)
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }

            if series.showsZeroRule, domain.lowerBound < 0 {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(AppColors.textTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
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
                        .background(Circle().fill(AppColors.bgBase))
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
                .foregroundStyle(AppColors.success)
                PointMark(
                    x: .value("Period", dataPoints[minIdx].chartLabel),
                    y: .value("Value", vals[minIdx])
                )
                .symbolSize(90)
                .foregroundStyle(AppColors.destructive)
            }

            // "You are here" dot on the last point.
            if let last = dataPoints.last {
                PointMark(
                    x: .value("Period", last.chartLabel),
                    y: .value("Value", series.value(last))
                )
                .symbolSize(55)
                .foregroundStyle(tint)
            }

            // Selection emphasis — drawn LAST; the x-domain is locked by chartXScale.
            if let p = selectedPoint {
                let v = series.value(p)
                let pointColor = series.color(for: v)
                RuleMark(x: .value("Selected", p.chartLabel))
                    .foregroundStyle(pointColor.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                PointMark(x: .value("SelectedHalo", p.chartLabel), y: .value("SelectedV", v))
                    .symbolSize(180)
                    .foregroundStyle(pointColor.opacity(0.20))
                PointMark(x: .value("SelectedInner", p.chartLabel), y: .value("SelectedV", v))
                    .symbolSize(70)
                    .foregroundStyle(pointColor)
            }
        }
        .chartXScale(domain: categoryDomain)
        .chartYScale(domain: domain)
        .chartXLabelSelectionWithFeedback($selectedValueLabel)
        .chartCategoryXAxis(labelMap: axisLabels)
        .chartCompactYAxis()
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
            SkeletonView(height: ChartMetrics.heroPlotHeight)
                .padding(.horizontal, AppSpacing.lg)
        }
        .skeletonLoadingLabel()
    }
}
