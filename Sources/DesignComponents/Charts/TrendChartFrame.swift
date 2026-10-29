//
//  TrendChartFrame.swift
//  DesignKit
//
//  What LineChart and BarChart share (8.2.0): the dataset cache, the selection, the window
//  centred on it, the banner above the plot, the axes, the reference lines, the Audio Graph
//  and the motion. Each chart draws only its marks.
//
//  - The selected period is the current one until the person taps another, and stays
//    selected (a tap that lifts does not clear it): the banner always shows a period, its
//    change from the one before, its forecast, a year ago, a record.
//  - A long press and a drag pick a stretch of periods: the banner sums it up until the next
//    tap.
//  - The window opens centred on the selected period; zoom re-centres it. Taps move the
//    selection, not the window; with `followsScroll` the selection is what sits under a
//    ruler in the middle, and the chart scrolls under it.
//  - New values under the same periods morph the marks; a zoom cross-fades to a new chart;
//    new periods (month → week) play the entrance again.
//

import SwiftUI
import Charts
import DesignTokens
import DesignSupport

/// A reference line with its value worked out (an average from the data).
struct ChartResolvedReference {
    let id: String
    let value: Double
    let label: String
    let color: Color
    let aboveColor: Color?
}

/// What a chart's marks need from the frame.
struct TrendChartContext {
    let cache: ChartPointCache
    /// The selected point: what was tapped, or the current period.
    let selectedIndex: Int
    /// The stretch picked with a long press and a drag; `nil` when none.
    let range: ClosedRange<Int>?
    /// Bars stand at their values (false before they rise in).
    let risen: Bool
    let references: [ChartResolvedReference]
    let marksExtremes: Bool
    /// Dark mode: lines and the selected bar glow softly.
    let glows: Bool
    /// The window's middle is the selection; the frame draws the ruler, the marks draw no
    /// selection (they do not change while the chart scrolls).
    let followsScroll: Bool
    /// Forecasts and comparisons drawn (`ChartDisplayOptions`).
    let showsForecast: Bool
    let showsComparison: Bool

    /// The selected period, or a period in the picked stretch: drawn in full colour. Following
    /// the scroll, every bar is.
    func isEmphasized(_ index: Int) -> Bool {
        if let range { return range.contains(index) }
        return followsScroll || index == selectedIndex
    }

    /// The colour of a bar that passes a limit with `aboveColor`, or `nil`.
    func aboveColor(for value: Double) -> Color? {
        references
            .filter { $0.aboveColor != nil && value > $0.value }
            .max { $0.value < $1.value }?
            .aboveColor
    }
}

/// Options LineChart and BarChart share.
struct TrendChartOptions {
    var referenceLines: [ChartReferenceLine] = []
    var marksExtremes = false
    var followsScroll = false
    /// Stacked bars: the Y axis spans the stacks, the banner leads with their total.
    var stacked = false
    /// Forecasts (`ChartSeries.projected`) and comparisons (`ChartSeries.comparison`) drawn and
    /// in the banner; a `ChartSwitcher` menu turns them off.
    var showsForecast = true
    var showsComparison = true
    /// The banner's line for `ChartSeries.comparison`.
    var comparisonLabel: String = ChartText.yearAgo

    /// With the person's choice (`.chartDisplayOptions`) over the chart's parameters: its
    /// average lines give way to one per series when `.average` is on.
    func applying<Point>(_ shown: ChartDisplayOptions?, series: [ChartSeries<Point>]) -> TrendChartOptions {
        guard let shown else { return self }
        var result = self
        result.referenceLines.removeAll(where: \.isAverage)
        if shown.contains(.average) {
            result.referenceLines += series.map { s in
                // Several series: each line in its series' colour.
                series.count == 1 ? .average(of: s.id) : .average(of: s.id, color: s.color(for: 0))
            }
        }
        result.marksExtremes = shown.contains(.records)
        result.showsForecast = shown.contains(.forecast)
        result.showsComparison = shown.contains(.comparison)
        result.followsScroll = shown.contains(.followsScroll)
        return result
    }
}

/// How a chart enters.
enum TrendChartEntrance {
    /// The line is traced in from the left (`.chartDrawIn()`).
    case drawIn
    /// The bars rise from zero.
    case rise
}

struct TrendChartFrame<Point: ChartPoint, Plot: View>: View {
    let dataPoints: [Point]
    let seriesList: [ChartSeries<Point>]
    let valueFormat: ChartValueFormat
    @Binding var zoomScale: CGFloat
    /// ChartSwitcher's selection, kept across a style switch; nil: the frame keeps its own.
    let selection: Binding<String?>?
    let entrance: TrendChartEntrance
    /// The chart's parameters; `options` puts the person's choice over them.
    let baseOptions: TrendChartOptions
    let plot: (TrendChartContext) -> Plot

    @State private var cache = ChartPointCache()
    /// What Swift Charts reports; nil again when a touch ends.
    @State private var rawSelection: String?
    @State private var ownSelection: String?
    @State private var rawRange: ClosedRange<String>?
    /// The picked stretch, kept until the next tap.
    @State private var range: ClosedRange<Int>?
    /// The period the window was centred on when this chart (these periods, this zoom)
    /// appeared: taps move the selection, not the window.
    @State private var windowCenter: TrendChartCenter?
    /// The periods (`labelsKey`) the bars have risen for: new periods rise again.
    @State private var risenKey: Int?
    @State private var hasAppeared = false
    /// Where the scroll is and which point is under the ruler (a window that follows it).
    @State private var follow = ChartFollowState()
    /// Bumped to scroll a tapped period to the ruler: the scroll position is read again.
    @State private var scrollRequest = 0
    /// The chart's width, for how many X axis labels fit.
    @State private var chartWidth: CGFloat = 0
    /// `AppTypography.caption2` at the person's text size.
    @ScaledMetric(relativeTo: .caption2) private var axisFontSize: CGFloat = 12

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    @Environment(\.chartPlaysEntrance) private var playsEntrance
    @Environment(\.chartDisplayOptions) private var displayOptions
    @Environment(\.colorScheme) private var colorScheme

    init(
        dataPoints: [Point],
        series: [ChartSeries<Point>],
        valueFormat: ChartValueFormat,
        zoomScale: Binding<CGFloat>,
        selection: Binding<String?>?,
        entrance: TrendChartEntrance,
        options: TrendChartOptions,
        plot: @escaping (TrendChartContext) -> Plot
    ) {
        self.dataPoints = dataPoints
        self.seriesList = series
        self.valueFormat = valueFormat
        self._zoomScale = zoomScale
        self.selection = selection
        self.entrance = entrance
        self.baseOptions = options
        self.plot = plot
    }

    private var options: TrendChartOptions {
        baseOptions.applying(displayOptions?.wrappedValue, series: seriesList)
    }

    private var allowsMotion: Bool { !reduceMotion && designKitMotion }

    private var selectedLabel: String? { selection?.wrappedValue ?? ownSelection }

    private var selectedIndex: Int {
        if let label = selectedLabel, let index = cache.labelToIndex[label] { return index }
        return cache.currentIndex
    }

    /// The window's centre: where it was when this chart appeared; a new chart (new periods,
    /// a zoom) centres on the selected period, or on the one under the ruler.
    private func centerIndex(for identity: TrendChartIdentity) -> Int {
        if let center = windowCenter, center.identity == identity,
           let label = center.label, let index = cache.labelToIndex[label] {
            return index
        }
        if identity.followsScroll, let label = follow.followedLabel, let index = cache.labelToIndex[label] {
            return index
        }
        return selectedIndex
    }

    private var risen: Bool {
        entrance != .rise || !allowsMotion || risenKey == cache.labelsKey
            || (!hasAppeared && !playsEntrance)
    }

    var body: some View {
        // Prime the per-dataset cache before anything reads it.
        let _ = rebuildChartCacheIfNeeded(cache, points: dataPoints, series: seriesList, format: valueFormat)
        let options = self.options
        let selected = selectedIndex
        let follows = options.followsScroll
        let identity = TrendChartIdentity(
            labels: cache.labelsKey,
            visibleCount: ChartWindow.visibleCount(count: cache.labels.count, zoomScale: zoomScale, followsScroll: follows),
            followsScroll: follows
        )
        let window = ChartWindow(
            labels: cache.labels,
            centerIndex: centerIndex(for: identity),
            zoomScale: zoomScale,
            followsScroll: follows
        )
        let references = resolvedReferences(options)
        let domain = yDomain(references: references, options: options)
        let openingCenter = centerIndex(for: identity)
        let context = TrendChartContext(
            cache: cache,
            selectedIndex: selected,
            range: range,
            risen: risen,
            references: references,
            marksExtremes: options.marksExtremes,
            glows: colorScheme == .dark,
            followsScroll: follows,
            showsForecast: options.showsForecast,
            showsComparison: options.showsComparison
        )
        let _ = scrollRequest
        let axisLabels = ChartAxisLabels(
            cache: cache,
            anchorIndex: cache.currentIndex,
            selectedIndex: follows && range == nil ? nil : (range?.lowerBound ?? selected),
            visibleCount: window.visibleCount,
            alignsTrailingEdge: window.categories.count == cache.labels.count,
            chartWidth: chartWidth,
            yDomain: domain,
            fontSize: axisFontSize
        )

        VStack(spacing: AppSpacing.lg) {
            if follows && range == nil {
                // Only the banner follows the point under the ruler: the chart is not redrawn
                // while it scrolls (a redraw set the scroll position again and the chart shook).
                ChartFollowedBanner(state: follow, fallback: openingCenter) { index in
                    banner(selected: index)
                }
            } else {
                banner(selected: selected)
            }
            entered(
                scrolled(
                    plot(context)
                        .chartXScale(domain: window.categories)
                        .chartYScale(domain: domain)
                        .chartXVisibleDomain(length: window.visibleCount),
                    window: window,
                    follows: follows
                )
                .chartXSelection(value: $rawSelection)
                .chartXSelection(range: $rawRange)
                .chartCategoryXAxis(labelMap: cache.axisLabels, labels: axisLabels)
                .chartCompactYAxis()
                .chartLegend(.hidden)
                .chartOverlay { proxy in
                    ChartPlotOverlay(proxy: proxy, references: references, showsCenterRuler: follows)
                }
                .accessibilityChartDescriptor(chartAudioGraph(
                    cache: cache,
                    series: seriesList,
                    domain: domain,
                    format: valueFormat,
                    isContinuous: entrance == .drawIn
                ))
                // New values under the same periods: the marks move to them.
                .animation(motion(AppAnimation.chartUpdateAnimation), value: cache.key)
                // New periods or a zoom: a new chart, centred again, fades in.
                .id(identity)
                .transition(.opacity)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { chartWidth = $0 }
                .padding(.leading, AppSpacing.lg)
                .frame(height: ChartMetrics.plotHeight)
            )
        }
        .animation(motion(AppAnimation.chartUpdateAnimation), value: identity)
        .chartFadeIn()
        .onChange(of: rawSelection) { _, new in
            guard let new, let index = cache.labelToIndex[new] else { return }
            let hadRange = range != nil
            range = nil
            if follows {
                // A tap brings its period to the ruler.
                guard index != (follow.centerIndex ?? openingCenter) || hadRange else { return }
                follow.leadingLabel = window.categories[index]
                follow.follow(index, label: new)
                withAnimation(motion(AppAnimation.smooth)) { scrollRequest &+= 1 }
                HapticManager.selection()
                return
            }
            guard index != selectedIndex || hadRange else { return }
            select(new)
            HapticManager.selection()
        }
        .onChange(of: rawRange) { _, new in
            guard let new,
                  let a = cache.labelToIndex[new.lowerBound],
                  let b = cache.labelToIndex[new.upperBound],
                  a != b else { return }
            let picked = min(a, b)...max(a, b)
            guard picked != range else { return }
            range = picked
            HapticManager.selection()
        }
        .onChange(of: identity, initial: true) { _, newIdentity in
            // Before `windowCenter` names the new chart, so it reads the centre it opened on.
            let center = centerIndex(for: newIdentity)
            windowCenter = TrendChartCenter(label: label(at: center), identity: newIdentity)
            follow.leadingLabel = nil
            follow.centerIndex = nil
            follow.window = window
        }
        .onChange(of: cache.labelsKey) { _, newKey in
            range = nil
            // New periods (a week to a month): the bars rise again.
            guard entrance == .rise, allowsMotion else { return }
            withAnimation(AppAnimation.chartAppearAnimation.delay(AppAnimation.chartAppearDelay)) {
                risenKey = newKey
            }
        }
        .onAppear(perform: appear)
    }

    // MARK: - Banner

    private func banner(selected: Int) -> some View {
        let options = self.options
        let content = range.map { rangeBanner($0, options: options) } ?? periodBanner(selected, options: options)
        return ChartSelectionBanner(
            title: content.title,
            note: content.note,
            entries: content.entries,
            format: valueFormat
        )
        .screenPadding()
        .animation(AppAnimation.chartBannerFade, value: content.title)
        .chartSelectionAnnouncement(announcement(content))
    }

    private struct BannerContent {
        let title: String
        let note: String?
        let entries: [ChartSelectionBanner.Entry]
    }

    /// One period: each series' value, its change from the period before (from its forecast
    /// while the period is not over), its forecast, a year ago, a record.
    private func periodBanner(_ i: Int, options: TrendChartOptions) -> BannerContent {
        let several = seriesList.count > 1
        var entries = seriesList.indices.map { s -> ChartSelectionBanner.Entry in
            let series = seriesList[s]
            let v = cache.values[s][i]
            let forecast = options.showsForecast ? cache.projected[s][i] : nil
            let before = options.showsComparison ? cache.comparison[s][i] : nil
            var details: [ChartSelectionBanner.Detail] = []
            if let forecast { details.append(.init(ChartText.forecast, value: forecast)) }
            if let before { details.append(.init(options.comparisonLabel, value: before)) }
            let reached = cache.isPartial[i] ? forecast : v
            let change = i > 0 ? reached.flatMap { chartChangePercent(from: cache.values[s][i - 1], to: $0) } : nil
            return .init(
                value: v,
                color: series.color(for: v),
                showsDot: several,
                label: several ? series.name : nil,
                changePercent: change,
                better: series.better,
                details: details,
                isRecord: cache.recordIndex[s] == i
            )
        }
        if options.stacked && several {
            let total = cache.values.map { $0[i] }.reduce(0, +)
            entries.insert(.init(value: total, color: AppColors.Text.primary, showsDot: false, label: ChartText.total), at: 0)
        }
        return BannerContent(title: cache.titles[i], note: cache.isPartial[i] ? ChartText.partial : nil, entries: entries)
    }

    /// A picked stretch: per series its total and average (or, for a level, its last value and
    /// where it started), and the change from the first period to the last.
    private func rangeBanner(_ r: ClosedRange<Int>, options: TrendChartOptions) -> BannerContent {
        let several = seriesList.count > 1
        var entries = seriesList.indices.map { s -> ChartSelectionBanner.Entry in
            let series = seriesList[s]
            let slice = r.map { cache.values[s][$0] }
            let first = cache.values[s][r.lowerBound]
            let last = cache.values[s][r.upperBound]
            let change = chartChangePercent(from: first, to: last)
            switch series.rangeSummary {
            case .total:
                let sum = slice.reduce(0, +)
                return .init(
                    value: sum, color: series.color(for: sum), showsDot: several,
                    label: several ? series.name : nil, changePercent: change, better: series.better,
                    details: [.init(ChartText.average, value: sum / Double(slice.count))]
                )
            case .change:
                return .init(
                    value: last, color: series.color(for: last), showsDot: several,
                    label: several ? series.name : nil, changePercent: change, better: series.better,
                    details: [.init(ChartText.from, value: first)]
                )
            }
        }
        if options.stacked && several {
            let total = r.flatMap { i in cache.values.map { $0[i] } }.reduce(0, +)
            entries.insert(.init(value: total, color: AppColors.Text.primary, showsDot: false, label: ChartText.total), at: 0)
        }
        let title = "\(cache.titles[r.lowerBound]) – \(cache.titles[r.upperBound])"
        return BannerContent(title: title, note: nil, entries: entries)
    }

    /// "January 2025. Income: 480 000 KZT. Expenses: 275 000 KZT."
    private func announcement(_ content: BannerContent) -> String {
        let parts = content.entries.map { entry in
            (entry.label.map { "\($0): " } ?? "") + valueFormat.spokenText(entry.value) + "."
        }
        return "\(content.title). " + parts.joined(separator: " ")
    }

    // MARK: - Pieces

    /// The scroll position: where the window starts when the chart appears, or (following the
    /// scroll) a binding that turns each new middle period into the banner's, with the scroll
    /// coming to rest on whole periods.
    @ViewBuilder
    private func scrolled<Content: View>(_ content: Content, window: ChartWindow, follows: Bool) -> some View {
        if follows {
            content
                .chartScrollableAxes(.horizontal)
                .chartScrollTargetBehavior(ChartPeriodSnap(visibleCount: window.visibleCount))
                .chartScrollPosition(x: Binding(
                    get: { follow.leadingLabel ?? window.leadingLabel },
                    set: { leading in followScroll(to: leading) }
                ))
        } else {
            content
                .chartScrollableAxes(.horizontal)
                .chartScrollPosition(initialX: window.leadingLabel)
        }
    }

    /// The window moved: the period in its middle goes to the banner, with a tick. Nothing
    /// the chart reads changes, so the chart is not redrawn under the finger.
    private func followScroll(to leading: String) {
        guard leading != follow.leadingLabel else { return }
        follow.leadingLabel = leading
        guard range == nil, rawRange == nil,
              let window = follow.window,
              let index = window.centerIndex(leadingLabel: leading, labelToIndex: cache.labelToIndex),
              index != follow.centerIndex else { return }
        follow.follow(index, label: cache.labels[index])
        HapticManager.selection()
    }

    private func select(_ label: String) {
        if let selection {
            selection.wrappedValue = label
        } else {
            ownSelection = label
        }
    }

    @ViewBuilder
    private func entered<Content: View>(_ content: Content) -> some View {
        switch entrance {
        case .drawIn: content.modifier(ChartDrawInModifier(delay: 0, replayKey: cache.labelsKey))
        case .rise: content
        }
    }

    private func appear() {
        defer { hasAppeared = true }
        guard entrance == .rise, risenKey == nil else { return }
        guard allowsMotion, playsEntrance else {
            risenKey = cache.labelsKey
            return
        }
        // The bars rise from zero once, as the chart first appears.
        withAnimation(AppAnimation.chartAppearAnimation.delay(AppAnimation.chartAppearDelay)) {
            risenKey = cache.labelsKey
        }
    }

    private func resolvedReferences(_ options: TrendChartOptions) -> [ChartResolvedReference] {
        options.referenceLines.compactMap { line in
            let value: Double?
            switch line.value {
            case .fixed(let v):
                value = v
            case .average(let seriesID):
                let s = seriesID.flatMap { id in seriesList.firstIndex { $0.id == id } } ?? 0
                value = cache.finishedAverage.indices.contains(s) ? cache.finishedAverage[s] : nil
            }
            return value.map { ChartResolvedReference(id: line.id, value: $0, label: line.label,
                                                      color: line.color, aboveColor: line.aboveColor) }
        }
    }

    /// The padded Y domain over the values, the forecasts and comparisons drawn, the stacks and
    /// the reference lines.
    private func yDomain(references: [ChartResolvedReference], options: TrendChartOptions) -> ClosedRange<Double> {
        var low = cache.yMin
        var high = cache.yMax
        if options.stacked {
            low = min(low, cache.stackedMin)
            high = max(high, cache.stackedMax)
        }
        for span in [options.showsForecast ? cache.forecastRange : nil, options.showsComparison ? cache.comparisonRange : nil] {
            guard let span else { continue }
            low = min(low, span.lowerBound)
            high = max(high, span.upperBound)
        }
        for reference in references {
            low = min(low, reference.value)
            high = max(high, reference.value)
        }
        return paddedChartDomain(
            yMin: low,
            yMax: high,
            allowsNegative: seriesList.contains { $0.baseline == .signed } || low < 0
        )
    }

    private func label(at index: Int) -> String? {
        cache.labels.indices.contains(index) ? cache.labels[index] : nil
    }

    private func motion(_ animation: Animation) -> Animation? {
        AppAnimation.motion(animation, reduceMotion: reduceMotion, isEnabled: designKitMotion)
    }
}

/// A window that follows the scroll (8.2.0): the point under the ruler, observed by the banner
/// alone, and the scroll position, which Swift Charts writes as the chart scrolls and which
/// must not redraw anything.
@Observable
@MainActor
final class ChartFollowState {
    /// The point under the ruler; `nil`: the one the window opened on.
    var centerIndex: Int?
    /// Its label, kept across a zoom (the new window opens on it); the frame reads it without
    /// being redrawn as it changes.
    @ObservationIgnored var followedLabel: String?
    /// The category at the window's leading edge; `nil`: where the window opened.
    @ObservationIgnored var leadingLabel: String?
    /// The window the position belongs to.
    @ObservationIgnored var window: ChartWindow?

    func follow(_ index: Int, label: String) {
        centerIndex = index
        followedLabel = label
    }
}

/// The banner of a chart that follows the scroll: it alone reads the point under the ruler,
/// so only it is redrawn as the chart scrolls.
struct ChartFollowedBanner<Content: View>: View {
    let state: ChartFollowState
    let fallback: Int
    let content: (Int) -> Content

    var body: some View {
        content(state.centerIndex ?? fallback)
    }
}

/// Change in percent from `a` to `b`; `nil` when `a` is not above zero (a change from nothing
/// or from a loss reads as nothing useful).
func chartChangePercent(from a: Double, to b: Double) -> Double? {
    guard a > 0 else { return nil }
    return (b - a) / a * 100
}

/// What makes a new chart: other periods, another window size, a window that follows the
/// scroll or not.
struct TrendChartIdentity: Hashable {
    let labels: Int
    let visibleCount: Int
    let followsScroll: Bool
}

/// Following the scroll, the chart comes to rest with a period in the middle of the window,
/// under the ruler: the scroll stops on whole periods (8.2.0). The window shows `visibleCount`
/// periods across the plot, so a period is the plot's width over that.
struct ChartPeriodSnap: ChartScrollTargetBehavior {
    let visibleCount: Int

    func updateTarget(_ target: inout ScrollTarget, context: ChartScrollTargetBehaviorContext) {
        let period = context.containerSize.width / CGFloat(max(visibleCount, 1))
        guard period > 0 else { return }
        let end = max(context.contentSize.width - context.containerSize.width, 0)
        target.rect.origin.x = min(max((target.rect.minX / period).rounded() * period, 0), end)
    }
}

/// Where a chart's window was centred.
struct TrendChartCenter: Equatable {
    let label: String?
    let identity: TrendChartIdentity
}

/// Over the plot, fixed while it scrolls: the reference lines' labels in pills at its leading
/// edge (over the older periods, not the current one), and the ruler in its middle when the
/// selection follows the scroll. Pills of lines close together stack instead of overlapping.
struct ChartPlotOverlay: View {
    let proxy: ChartProxy
    let references: [ChartResolvedReference]
    let showsCenterRuler: Bool

    /// A pill's height and the gap to the next, at the person's text size.
    @ScaledMetric(relativeTo: .caption2) private var pillStep: CGFloat = 22

    init(proxy: ChartProxy, references: [ChartResolvedReference], showsCenterRuler: Bool) {
        self.proxy = proxy
        self.references = references
        self.showsCenterRuler = showsCenterRuler
    }

    var body: some View {
        GeometryReader { geometry in
            // The visible part of the plot: in a chart that scrolls, `plotFrame` is the whole
            // scrolled plot, whose middle and leading edge are off screen.
            if let anchor = proxy.plotContainerFrame ?? proxy.plotFrame {
                let plot = geometry[anchor]
                ZStack(alignment: .topLeading) {
                    if showsCenterRuler {
                        Capsule()
                            .fill(AppColors.accent.opacity(0.7))
                            .frame(width: 2, height: plot.height)
                            .position(x: plot.midX, y: plot.midY)
                    }
                    ForEach(placedPills(), id: \.reference.id) { pill in
                        ChartReferencePill(reference: pill.reference)
                            .position(x: plot.minX + ChartMetrics.referencePillInset, y: plot.minY + pill.y)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private struct PlacedPill {
        let reference: ChartResolvedReference
        let y: CGFloat
    }

    /// Each pill just above its line; going down the plot, a pill closer than a step to the one
    /// above moves down below it.
    private func placedPills() -> [PlacedPill] {
        let placed = references
            .compactMap { reference in
                proxy.position(forY: reference.value).map { PlacedPill(reference: reference, y: $0 - ChartMetrics.referencePillLift) }
            }
            .sorted { $0.y < $1.y }
        var result: [PlacedPill] = []
        for pill in placed {
            let y = result.last.map { max(pill.y, $0.y + pillStep) } ?? pill.y
            result.append(PlacedPill(reference: pill.reference, y: y))
        }
        return result
    }
}

/// "Average 480K" in a pill of the line's colour (8.2.0).
struct ChartReferencePill: View {
    let reference: ChartResolvedReference

    var body: some View {
        Text(verbatim: "\(reference.label) \(ChartValueFormat.compactString(reference.value))")
            .font(AppTypography.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(reference.color)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 2)
            .background(.regularMaterial, in: Capsule())
            .fixedSize()
            // `position` centres the pill: shift it right by half its width so it starts there.
            .modifier(ChartLeadingAligned())
    }
}

/// Shifts a view right by half its width: placed with `position(x:)` at an edge, it starts there.
private struct ChartLeadingAligned: ViewModifier {
    @State private var width: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .offset(x: width / 2)
    }
}

/// The selected point of a line: a soft halo under a dot in a ring of the background, so it
/// stands out from the line it sits on (8.2.0). In dark mode it glows.
struct ChartSelectedDot: View {
    let color: Color
    var glows = false

    var body: some View {
        Circle()
            .fill(color)
            .padding(ChartMetrics.selectedRing)
            .background(Circle().fill(AppColors.Background.base))
            .frame(width: ChartMetrics.selectedDot, height: ChartMetrics.selectedDot)
            .shadow(color: glows ? color.opacity(0.8) : .clear, radius: glows ? 6 : 0)
    }
}
