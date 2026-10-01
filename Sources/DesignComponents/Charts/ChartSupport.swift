//
//  ChartSupport.swift
//  DesignKit
//
//  Shared infrastructure of the ChartPoint charts (LineChart, BarChart, HeroSparkline),
//  ported from Tenra's PeriodChartHelpers / ChartAxisHelpers:
//
//  - `ChartPointCache`: per-instance derived values (label → index, axis labels, Y
//    envelope, "today" label) keyed by a dataset fingerprint. Lives in `@State` so it
//    survives body re-evaluations; rebuilt only when the dataset shape changes, so
//    scrolling and selection never redo O(N) work.
//  - Axis builders, tap selection with a haptic, the fixed-height banner slot and the
//    VoiceOver announcement of the selected point.
//

import SwiftUI
import Charts
import DesignTokens
import DesignSupport

// MARK: - Cache

@MainActor
final class ChartPointCache {
    /// `chartLabel` → index in the dataset. O(1) lookup for tap selection.
    var labelToIndex: [String: Int] = [:]
    /// `chartLabel` → `chartAxisLabel`, built once per dataset.
    var axisLabels: [String: String] = [:]
    /// First label whose `chartDate` is in the future ("today" marker). Nil if none.
    var todayLabel: String?
    /// Smallest / largest value across all series.
    var yMin: Double = 0
    var yMax: Double = 1
    /// Fingerprint of the last dataset processed.
    var identity: String = ""
}

/// Cheap dataset fingerprint: count + first/last label.
func chartCacheIdentity<Point: ChartPoint>(_ points: [Point]) -> String {
    guard let first = points.first, let last = points.last else { return "" }
    return "\(points.count)|\(first.chartLabel)|\(last.chartLabel)"
}

/// Rebuilds the cache in one O(N) pass when the dataset fingerprint changed; no-op otherwise.
/// `values` returns the per-point values folded into the Y envelope (one per series).
@MainActor
func rebuildChartCacheIfNeeded<Point: ChartPoint>(
    _ cache: ChartPointCache,
    points: [Point],
    values: (Point) -> [Double]
) {
    let identity = chartCacheIdentity(points)
    guard cache.identity != identity else { return }

    var indexMap = [String: Int]()
    var axisLabels = [String: String]()
    indexMap.reserveCapacity(points.count)
    axisLabels.reserveCapacity(points.count)
    var minY = Double.infinity
    var maxY = -Double.infinity
    let now = Date()
    var todayLabel: String?

    for (i, p) in points.enumerated() {
        let label = p.chartLabel
        indexMap[label] = i
        if axisLabels[label] == nil { axisLabels[label] = p.chartAxisLabel }
        if todayLabel == nil, let date = p.chartDate, date > now { todayLabel = label }
        for v in values(p) {
            if v < minY { minY = v }
            if v > maxY { maxY = v }
        }
    }

    cache.labelToIndex = indexMap
    cache.axisLabels = axisLabels
    cache.todayLabel = todayLabel
    cache.yMin = minY.isFinite ? minY : 0
    cache.yMax = maxY.isFinite ? maxY : 1
    cache.identity = identity
}

/// Padded axis domain over a dataset: ~6 % headroom so the peak point (and its selection
/// ring) is not clipped; zero-based series keep their 0 floor.
func paddedChartDomain(yMin: Double, yMax: Double, allowsNegative: Bool) -> ClosedRange<Double> {
    let rawMin = allowsNegative ? min(yMin, 0) : 0
    let rawMax = max(yMax, 1)
    let headroom = (rawMax - rawMin) * 0.06
    let paddedMin = rawMin < 0 ? rawMin - headroom : rawMin
    return paddedMin...(rawMax + headroom)
}

// MARK: - Axis builders

extension View {
    /// Category X axis: greedy collision resolution, display strings from `labelMap`.
    func chartCategoryXAxis(labelMap: [String: String]) -> some View {
        chartXAxis {
            AxisMarks { value in
                AxisValueLabel(collisionResolution: .greedy(minimumSpacing: 6)) {
                    if let label = value.as(String.self) {
                        Text(labelMap[label] ?? label)
                            .font(AppTypography.caption2)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    /// Leading Y axis with grid lines and compact values ("75K").
    func chartCompactYAxis() -> some View {
        chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(ChartValueFormat.compactString(amount))
                            .font(AppTypography.caption2)
                    }
                }
            }
        }
    }
}

// MARK: - Selection + banner

extension View {
    /// `chartXSelection(value:)` plus a selection haptic on change.
    func chartXLabelSelectionWithFeedback(_ binding: Binding<String?>) -> some View {
        chartXSelection(value: binding)
            .onChange(of: binding.wrappedValue) { _, new in
                guard new != nil else { return }
                HapticManager.selection()
            }
    }

    /// Fixed-height slot for the selection banner so the chart does not jump.
    func chartBannerSlotStyle(animationKey: AnyHashable?) -> some View {
        frame(height: 56)
            .screenPadding()
            .animation(AppAnimation.chartBannerFade, value: animationKey)
    }

    /// Announces the selected point to VoiceOver whenever `text` changes.
    func chartSelectionAnnouncement(_ text: String?) -> some View {
        onChange(of: text) { _, new in
            guard let new, !new.isEmpty else { return }
            AccessibilityNotification.Announcement(new).post()
        }
    }
}

/// "January 2025. 205 000 KZT." for one series; "January 2025. Income: 480 000 KZT.
/// Expenses: 275 000 KZT." for several.
func chartAnnouncementText<Point>(
    title: String,
    point: Point,
    series: [ChartSeries<Point>],
    format: ChartValueFormat
) -> String {
    if series.count == 1 {
        return "\(title). \(format.spokenText(series[0].value(point)))."
    }
    let parts = series.map { "\($0.name): \(format.spokenText($0.value(point)))." }
    return "\(title). " + parts.joined(separator: " ")
}

/// Banner entries for a selected point: one undotted value for a single series,
/// a dot + value per series for several.
func chartBannerEntries<Point>(point: Point, series: [ChartSeries<Point>]) -> [ChartSelectionBanner.Entry] {
    if series.count == 1 {
        let v = series[0].value(point)
        return [.init(value: v, color: series[0].color(for: v), showsDot: false)]
    }
    return series.map { s in
        let v = s.value(point)
        return .init(value: v, color: s.color(for: v), showsDot: true)
    }
}
