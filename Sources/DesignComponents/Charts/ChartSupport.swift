//
//  ChartSupport.swift
//  DesignKit
//
//  Shared infrastructure of the ChartPoint charts (LineChart, BarChart, HeroSparkline),
//  ported from Tenra's PeriodChartHelpers / ChartAxisHelpers and reworked in 8.2.0:
//
//  - `ChartPointCache`: everything derived from a dataset (each series' values, label →
//    index, axis labels, Y envelope, the current period, the unfinished periods, VoiceOver
//    texts), keyed by a hash of the points and the series ids. Lives in `@State`, so it
//    survives body re-evaluations; rebuilt only when the data changes, so a tap or a scroll
//    never redoes O(N) work or calls a series' value closure. Before 8.2.0 the key was the
//    count and the first and last labels: new values under the same labels kept a stale
//    Y domain and clipped the new peak.
//  - `ChartWindow`: the visible window of a scrolling chart, centred on the selected period,
//    with empty categories after the last point so the latest period can sit in the middle.
//  - Axis builders, the selection banner and its VoiceOver announcement, the Audio Graph,
//    the entrance switches.
//

import SwiftUI
import UIKit
import Charts
import Accessibility
import DesignTokens
import DesignSupport

// MARK: - Cache

@MainActor
final class ChartPointCache {
    /// Hash of the points and the series ids the cache was built from.
    var key: Int?
    /// Hash of the labels alone: it changes when the categories change (month → week).
    var labelsKey: Int = 0
    /// `chartLabel` of each point, in order.
    var labels: [String] = []
    /// `chartTitle` of each point: the banner's title, what VoiceOver reads for a period.
    var titles: [String] = []
    /// Each series' values: `values[series][point]`.
    var values: [[Double]] = []
    /// What VoiceOver reads for each value: `spoken[series][point]`.
    var spoken: [[String]] = []
    /// `chartLabel` → index in the dataset. O(1) lookup for selection.
    var labelToIndex: [String: Int] = [:]
    /// `chartLabel` → `chartAxisLabel`, built once per dataset.
    var axisLabels: [String: String] = [:]
    /// First label whose `chartDate` is in the future ("today" marker). Nil if none.
    var todayLabel: String?
    /// The period that holds today: the last point that does not start after now, or the
    /// last point when the points have no dates.
    var currentIndex: Int = 0
    /// `chartIsPartial` of each point.
    var isPartial: [Bool] = []
    /// Start of the unfinished periods at the end of the series: where a line turns dashed.
    var partialStart: Int?
    /// Smallest / largest value across all series.
    var yMin: Double = 0
    var yMax: Double = 1
    /// The widest axis label and the text size it was measured at (0: not measured yet).
    var axisLabelWidth: CGFloat = 0
    var axisLabelFontSize: CGFloat = 0

    /// Width of the widest axis label at `fontSize`, measured once per dataset and text size.
    func widestAxisLabel(fontSize: CGFloat) -> CGFloat {
        if fontSize != axisLabelFontSize {
            axisLabelWidth = axisLabels.values.map { chartTextWidth($0, fontSize: fontSize) }.max() ?? 0
            axisLabelFontSize = fontSize
        }
        return axisLabelWidth
    }
}

/// Width of a line of `AppTypography.caption2` text at `fontSize` (Inter regular).
@MainActor
func chartTextWidth(_ text: String, fontSize: CGFloat) -> CGFloat {
    let descriptor = UIFontDescriptor(fontAttributes: [.family: AppInterFont.family])
    let font = UIFont(descriptor: descriptor, size: fontSize)
    return ceil((text as NSString).size(withAttributes: [.font: font]).width)
}

/// Hash of a dataset: its points (their `Hashable`, values included when synthesized) and
/// the series drawn from them.
func chartCacheKey<Point: ChartPoint>(_ points: [Point], seriesIDs: [String]) -> Int {
    var hasher = Hasher()
    hasher.combine(points)
    hasher.combine(seriesIDs)
    return hasher.finalize()
}

/// Rebuilds the cache in one O(N) pass when the data changed; no-op otherwise. The only place
/// the series' value closures run.
@MainActor
func rebuildChartCacheIfNeeded<Point: ChartPoint>(
    _ cache: ChartPointCache,
    points: [Point],
    series: [ChartSeries<Point>],
    format: ChartValueFormat
) {
    let key = chartCacheKey(points, seriesIDs: series.map(\.id))
    guard cache.key != key else { return }

    let now = Date()
    var labels = [String]()
    var titles = [String]()
    var indexMap = [String: Int]()
    var axisLabels = [String: String]()
    var isPartial = [Bool]()
    labels.reserveCapacity(points.count)
    titles.reserveCapacity(points.count)
    indexMap.reserveCapacity(points.count)
    axisLabels.reserveCapacity(points.count)
    isPartial.reserveCapacity(points.count)
    var todayLabel: String?
    var currentIndex = 0

    for (i, p) in points.enumerated() {
        let label = p.chartLabel
        labels.append(label)
        titles.append(p.chartTitle)
        indexMap[label] = i
        if axisLabels[label] == nil { axisLabels[label] = p.chartAxisLabel }
        isPartial.append(p.chartIsPartial)
        if let date = p.chartDate, date > now {
            if todayLabel == nil { todayLabel = label }
        } else {
            currentIndex = i
        }
    }

    var values = [[Double]]()
    var spoken = [[String]]()
    var minY = Double.infinity
    var maxY = -Double.infinity
    for s in series {
        let column = points.map(s.value)
        for v in column {
            if v < minY { minY = v }
            if v > maxY { maxY = v }
        }
        values.append(column)
        spoken.append(column.map(format.spokenText))
    }

    var partialStart: Int?
    var i = isPartial.count - 1
    while i >= 0, isPartial[i] {
        partialStart = i
        i -= 1
    }

    var labelsHasher = Hasher()
    labelsHasher.combine(labels)

    cache.labels = labels
    cache.titles = titles
    cache.labelsKey = labelsHasher.finalize()
    cache.values = values
    cache.spoken = spoken
    cache.labelToIndex = indexMap
    cache.axisLabels = axisLabels
    cache.todayLabel = todayLabel
    cache.currentIndex = currentIndex
    cache.isPartial = isPartial
    cache.partialStart = partialStart
    cache.yMin = minY.isFinite ? minY : 0
    cache.yMax = maxY.isFinite ? maxY : 1
    cache.axisLabelFontSize = 0
    cache.key = key
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

// MARK: - Window

/// The visible part of a scrolling chart (8.2.0): `visiblePoints` categories at zoom 1, the
/// selected period in the middle. When that period is near the end, empty categories follow
/// the last point, so the latest period does not sit against the screen's edge.
struct ChartWindow {
    /// Categories of the X axis: the points' labels, then the empty ones.
    let categories: [String]
    /// How many categories the plot shows at once.
    let visibleCount: Int
    /// The category at the window's leading edge when the chart appears.
    let leadingLabel: String

    /// Categories on screen at once: 12 at zoom 1, fewer zoomed in, at most the whole series.
    static func visibleCount(count: Int, zoomScale: CGFloat) -> Int {
        max(1, min(count, Int((ChartMetrics.visiblePoints / max(zoomScale, 0.1)).rounded())))
    }

    init(labels: [String], centerIndex: Int, zoomScale: CGFloat) {
        let count = labels.count
        let window = Self.visibleCount(count: count, zoomScale: zoomScale)
        // The whole series fits: nothing scrolls, nothing to centre.
        guard count > window else {
            categories = labels
            visibleCount = window
            leadingLabel = labels.first ?? ""
            return
        }
        let center = min(max(centerIndex, 0), count - 1)
        let leading = max(0, center - window / 2)
        let padding = max(0, leading + window - count)
        categories = labels + (0..<padding).map(Self.paddingLabel)
        visibleCount = window
        leadingLabel = labels[leading]
    }

    /// An empty category after the last point. The invisible separator keeps it apart from any
    /// real label.
    static func paddingLabel(_ index: Int) -> String {
        "\u{2063}chart-padding-\(index)"
    }

    static func isPadding(_ label: String) -> Bool {
        label.hasPrefix("\u{2063}chart-padding-")
    }
}

// MARK: - Axis builders

extension View {
    /// Category X axis: the labels `labels` chose (8.2.0: Swift Charts' greedy collision
    /// resolution before), display strings from `labelMap`. The selected period's label is
    /// semibold in the primary colour. On colour (`tone: .onColor`, 4.5.0) the labels are
    /// white, the others translucent.
    func chartCategoryXAxis(labelMap: [String: String], labels: ChartAxisLabels, tone: HeroTone = .onSurface) -> some View {
        chartXAxis {
            AxisMarks(values: labels.values) { value in
                let label = value.as(String.self) ?? ""
                let isSelected = label == labels.emphasized
                AxisValueLabel(
                    anchor: label == labels.trailingEdge ? .topTrailing : nil,
                    collisionResolution: .disabled
                ) {
                    Text(labelMap[label] ?? label)
                        .font(AppTypography.caption2)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(ChartAxisLabels.color(isSelected: isSelected, tone: tone))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
        }
    }

    /// Leading Y axis: about four values in the person's language ("75K", "1,5 млн") over a
    /// thin dashed grid (8.2.0; a solid grid at the system's tick count before). On colour
    /// (`tone: .onColor`, 4.5.0) the grid and the labels are translucent white.
    @ViewBuilder
    func chartCompactYAxis(tone: HeroTone = .onSurface) -> some View {
        if tone == .onColor {
            chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: ChartMetrics.yTickCount)) { value in
                    AxisGridLine(stroke: ChartMetrics.gridStroke)
                        .foregroundStyle(ChartOnColor.grid)
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(ChartValueFormat.compactString(amount))
                                .font(AppTypography.caption2)
                                .foregroundStyle(ChartOnColor.label)
                        }
                    }
                }
            }
        } else {
            chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: ChartMetrics.yTickCount)) { value in
                    AxisGridLine(stroke: ChartMetrics.gridStroke)
                        .foregroundStyle(AppColors.Border.normal)
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
}

// MARK: - X axis labels

/// Which category labels the X axis draws (8.2.0). Swift Charts' greedy collision resolution
/// dropped every label that did not fit, unevenly and at the edges, so a period could have no
/// date under it. Now the labels go at a regular step that fits the widest one, counted from
/// the current period (which always has its label); the selected period's label is always
/// drawn, in bold, and a neighbour too close to it gives way. On a chart that does not scroll,
/// the last label ends at its tick instead of being cut by the chart's edge.
struct ChartAxisLabels {
    /// The labels to draw, in order.
    let values: [String]
    /// The selected period's label.
    let emphasized: String?
    /// The label aligned by its trailing edge.
    let trailingEdge: String?

    /// - Parameters:
    ///   - anchorIndex: the period the step counts from (the current one).
    ///   - selectedIndex: the period whose label is always drawn, in bold.
    ///   - visibleCount: categories on screen at once.
    ///   - alignsTrailingEdge: the last point sits at the chart's trailing edge (a chart that
    ///     does not scroll and has nothing after its last point).
    ///   - chartWidth: the chart's width, Y axis included (0 before it is known).
    ///   - yDomain: the Y axis' domain, for the width of its labels.
    ///   - fontSize: `caption2` at the person's text size.
    @MainActor
    init(
        cache: ChartPointCache,
        anchorIndex: Int,
        selectedIndex: Int?,
        visibleCount: Int,
        alignsTrailingEdge: Bool,
        chartWidth: CGFloat,
        yDomain: ClosedRange<Double>,
        fontSize: CGFloat
    ) {
        let labels = cache.labels
        guard !labels.isEmpty else {
            values = []
            emphasized = nil
            trailingEdge = nil
            return
        }
        let yAxisWidth = max(
            chartTextWidth(ChartValueFormat.compactString(yDomain.upperBound), fontSize: fontSize),
            chartTextWidth(ChartValueFormat.compactString(yDomain.lowerBound), fontSize: fontSize)
        ) + ChartMetrics.axisLabelGap
        let plotWidth = max((chartWidth > 0 ? chartWidth : ChartMetrics.fallbackWidth) - yAxisWidth, 1)
        let band = plotWidth / CGFloat(max(visibleCount, 1))
        let labelWidth = cache.widestAxisLabel(fontSize: fontSize)
        let step = max(1, Int(((labelWidth + ChartMetrics.axisLabelGap) / band).rounded(.up)))

        let anchor = min(max(anchorIndex, 0), labels.count - 1)
        var shown = Set(labels.indices.filter { (($0 - anchor) % step + step) % step == 0 })
        if let selected = selectedIndex, labels.indices.contains(selected), !shown.contains(selected) {
            shown = shown.filter { abs($0 - selected) >= step }
            shown.insert(selected)
        }
        values = shown.sorted().map { labels[$0] }
        emphasized = selectedIndex.flatMap { labels.indices.contains($0) ? labels[$0] : nil }
        let last = labels.count - 1
        trailingEdge = alignsTrailingEdge && labelWidth > band && shown.contains(last) ? labels[last] : nil
    }

    init(values: [String], emphasized: String?, trailingEdge: String?) {
        self.values = values
        self.emphasized = emphasized
        self.trailingEdge = trailingEdge
    }

    /// The same labels and one more at the end (HeroSparkline's projection arrow).
    func appending(_ label: String) -> ChartAxisLabels {
        ChartAxisLabels(values: values + [label], emphasized: emphasized, trailingEdge: trailingEdge)
    }

    static func color(isSelected: Bool, tone: HeroTone) -> Color {
        switch (tone, isSelected) {
        case (.onColor, true): return ChartOnColor.mark
        case (.onColor, false): return ChartOnColor.label
        case (_, true): return AppColors.Text.primary
        case (_, false): return AppColors.Text.secondary
        }
    }
}

/// A chart's marks on colour (`.heroBackground`, 4.5.0): white, the grid and labels translucent.
enum ChartOnColor {
    static let mark = AppColors.staticWhite
    static let label = AppColors.staticWhite.opacity(0.78)
    static let grid = AppColors.staticWhite.opacity(0.22)
    /// The area under a line: white fading out downwards.
    static var area: AnyShapeStyle {
        AnyShapeStyle(LinearGradient(colors: [AppColors.staticWhite.opacity(0.32), AppColors.staticWhite.opacity(0)],
                                     startPoint: .top, endPoint: .bottom))
    }
}

// MARK: - Selection + banner

extension View {
    /// `chartXSelection(value:)` plus a selection haptic on change (HeroSparkline).
    func chartXLabelSelectionWithFeedback(_ binding: Binding<String?>) -> some View {
        chartXSelection(value: binding)
            .onChange(of: binding.wrappedValue) { _, new in
                guard new != nil else { return }
                HapticManager.selection()
            }
    }

    /// Slot for a banner that comes and goes (HeroSparkline), so the chart does not jump. Its
    /// height follows Dynamic Type (8.2.0: a fixed 56 pt before, less than the banner itself).
    func chartBannerSlotStyle(animationKey: AnyHashable?) -> some View {
        modifier(ChartBannerSlot(animationKey: animationKey))
    }

    /// Announces the selected point to VoiceOver whenever `text` changes.
    func chartSelectionAnnouncement(_ text: String?) -> some View {
        onChange(of: text) { _, new in
            guard let new, !new.isEmpty else { return }
            AccessibilityNotification.Announcement(new).post()
        }
    }
}

private struct ChartBannerSlot: ViewModifier {
    let animationKey: AnyHashable?
    @ScaledMetric(relativeTo: .body) private var height = ChartMetrics.bannerHeight

    func body(content: Content) -> some View {
        content
            .frame(height: height)
            .screenPadding()
            .animation(AppAnimation.chartBannerFade, value: animationKey)
    }
}

/// "January 2025. 205 000 KZT." for one series; "January 2025. Income: 480 000 KZT.
/// Expenses: 275 000 KZT." for several.
@MainActor
func chartAnnouncementText<Point>(
    title: String,
    index: Int,
    cache: ChartPointCache,
    series: [ChartSeries<Point>]
) -> String {
    if series.count == 1 {
        return "\(title). \(cache.spoken[0][index])."
    }
    let parts = series.indices.map { "\(series[$0].name): \(cache.spoken[$0][index])." }
    return "\(title). " + parts.joined(separator: " ")
}

/// Banner entries for a point: one undotted value for a single series; for several a dot,
/// the series' name and its value each, so the banner is the chart's legend (8.2.0).
@MainActor
func chartBannerEntries<Point>(
    index: Int,
    cache: ChartPointCache,
    series: [ChartSeries<Point>]
) -> [ChartSelectionBanner.Entry] {
    if series.count == 1 {
        let v = cache.values[0][index]
        return [.init(value: v, color: series[0].color(for: v), showsDot: false)]
    }
    return series.indices.map { s in
        let v = cache.values[s][index]
        return .init(value: v, color: series[s].color(for: v), showsDot: true, label: series[s].name)
    }
}

/// Texts the charts read themselves.
enum ChartText {
    /// After the banner's title for a period that is not over yet.
    static var partial: String { String(localized: "chart.partial", defaultValue: "so far") }
}

// MARK: - Audio Graph

/// What VoiceOver's Audio Graph reads (8.2.0): the periods by their titles, the values in the
/// chart's format.
struct ChartAudioGraph: AXChartDescriptorRepresentable {
    let categories: [String]
    let series: [(name: String, values: [Double])]
    let range: ClosedRange<Double>
    let isContinuous: Bool
    let format: ChartValueFormat

    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXCategoricalDataAxisDescriptor(title: "", categoryOrder: categories)
        let yAxis = AXNumericDataAxisDescriptor(
            title: "",
            range: range,
            gridlinePositions: [],
            valueDescriptionProvider: { [format] in format.spokenText($0) }
        )
        let seriesDescriptors = series.map { s in
            AXDataSeriesDescriptor(
                name: s.name,
                isContinuous: isContinuous,
                dataPoints: zip(categories, s.values).map { AXDataPoint(x: $0, y: $1) }
            )
        }
        return AXChartDescriptor(
            title: nil,
            summary: nil,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: seriesDescriptors
        )
    }
}

/// The Audio Graph of a chart over a cached dataset.
@MainActor
func chartAudioGraph<Point: ChartPoint>(
    cache: ChartPointCache,
    series: [ChartSeries<Point>],
    domain: ClosedRange<Double>,
    format: ChartValueFormat,
    isContinuous: Bool
) -> ChartAudioGraph {
    ChartAudioGraph(
        categories: cache.titles,
        series: series.indices.map { (name: series[$0].name, values: cache.values[$0]) },
        range: domain,
        isContinuous: isContinuous,
        format: format
    )
}

// MARK: - Entrance

extension EnvironmentValues {
    /// Whether a chart plays its entrance when it appears. `ChartSwitcher` turns it off once
    /// the person switches style, so the other chart is simply there (8.2.0).
    @Entry var chartPlaysEntrance: Bool = true
}

extension View {
    /// A chart fades in once as it first appears (8.2.0: without the scale of `.chartAppear()`;
    /// the marks bring their own motion). Instant under Reduce Motion, with
    /// `.designKitMotion(false)` and after a `ChartSwitcher` switch.
    func chartFadeIn() -> some View {
        modifier(ChartFadeInModifier())
    }
}

private struct ChartFadeInModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    @Environment(\.chartPlaysEntrance) private var playsEntrance
    @State private var appeared = false

    private var fades: Bool { !reduceMotion && designKitMotion && playsEntrance }

    func body(content: Content) -> some View {
        content
            // Without motion the chart is there from the first frame (snapshots, a switch).
            .opacity(appeared || !fades ? 1 : 0)
            .onAppear {
                guard !appeared else { return }
                guard fades else {
                    appeared = true
                    return
                }
                withAnimation(.easeOut(duration: MotionBudget.entrance).delay(AppAnimation.chartAppearDelay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Metrics

/// Sizes the charts and their skeletons share.
enum ChartMetrics {
    /// Plot area of `LineChart` and `BarChart`.
    static let plotHeight: CGFloat = 200
    /// Plot area of `HeroSparkline`.
    static let heroPlotHeight: CGFloat = 220
    /// The banner above a plot at the default text size (it grows with Dynamic Type).
    static let bannerHeight: CGFloat = 64
    /// Points a scrolling chart shows at zoom 1.
    static let visiblePoints: Double = 12
    /// Values on the Y axis.
    static let yTickCount = 4
    /// The Y grid: thin and dashed, under the data.
    static let gridStroke = StrokeStyle(lineWidth: 0.5, dash: [2, 3])
    /// Bars other than the selected period's.
    static let dimmedOpacity: Double = 0.4
    /// Where a bar of an unfinished period fades to, as a share of its colour's opacity.
    static let partialFade: Double = 0.25
    /// A bar's width as a share of its category, one series.
    static let barWidthRatio: Double = 0.6
    /// The dash of a line's unfinished stretch.
    static let partialDash: [CGFloat] = [4, 4]
    /// The selected point: a soft halo, then the dot in a ring of the background.
    static let haloSize: CGFloat = 320
    static let selectedDot: CGFloat = 16
    static let selectedRing: CGFloat = 3
    /// Space between two X axis labels, and between the Y axis labels and the plot.
    static let axisLabelGap: CGFloat = 8
    /// The chart's width until its layout is known.
    static let fallbackWidth: CGFloat = 360
}
