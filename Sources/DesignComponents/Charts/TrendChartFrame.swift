//
//  TrendChartFrame.swift
//  DesignKit
//
//  What LineChart and BarChart share (8.2.0): the dataset cache, the selection, the window
//  centred on it, the banner above the plot, the axes, the Audio Graph and the motion. Each
//  chart draws only its marks.
//
//  - The selected period is the current one until the person taps another, and stays
//    selected (a tap that lifts does not clear it): the banner always shows a period.
//  - The window opens centred on the selected period; zoom re-centres it. Taps move the
//    selection, not the window.
//  - New values under the same periods morph the marks; new periods (month → week) and a
//    zoom cross-fade to a new chart.
//

import SwiftUI
import Charts
import DesignTokens
import DesignSupport

/// What a chart's marks need from the frame.
struct TrendChartContext {
    let cache: ChartPointCache
    /// The selected point: what was tapped, or the current period.
    let selectedIndex: Int
    /// Bars stand at their values (false before they rise in).
    let risen: Bool
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
    let plot: (TrendChartContext) -> Plot

    @State private var cache = ChartPointCache()
    /// What Swift Charts reports; nil again when a touch ends.
    @State private var rawSelection: String?
    @State private var ownSelection: String?
    /// The period the window was centred on when this chart (these periods, this zoom)
    /// appeared: taps move the selection, not the window.
    @State private var windowCenter: TrendChartCenter?
    @State private var hasRisen = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    @Environment(\.chartPlaysEntrance) private var playsEntrance

    init(
        dataPoints: [Point],
        series: [ChartSeries<Point>],
        valueFormat: ChartValueFormat,
        zoomScale: Binding<CGFloat>,
        selection: Binding<String?>?,
        entrance: TrendChartEntrance,
        plot: @escaping (TrendChartContext) -> Plot
    ) {
        self.dataPoints = dataPoints
        self.seriesList = series
        self.valueFormat = valueFormat
        self._zoomScale = zoomScale
        self.selection = selection
        self.entrance = entrance
        self.plot = plot
    }

    private var allowsMotion: Bool { !reduceMotion && designKitMotion }

    private var selectedLabel: String? { selection?.wrappedValue ?? ownSelection }

    private var selectedIndex: Int {
        if let label = selectedLabel, let index = cache.labelToIndex[label] { return index }
        return cache.currentIndex
    }

    /// The window's centre: where it was when this chart appeared; a new chart (new periods,
    /// a zoom) centres on the selected period.
    private func centerIndex(for identity: TrendChartIdentity) -> Int {
        if let center = windowCenter, center.identity == identity,
           let label = center.label, let index = cache.labelToIndex[label] {
            return index
        }
        return selectedIndex
    }

    private var risen: Bool {
        hasRisen || entrance != .rise || !allowsMotion || !playsEntrance
    }

    var body: some View {
        // Prime the per-dataset cache before anything reads it.
        let _ = rebuildChartCacheIfNeeded(cache, points: dataPoints, series: seriesList, format: valueFormat)
        let selected = selectedIndex
        let identity = TrendChartIdentity(
            labels: cache.labelsKey,
            visibleCount: ChartWindow.visibleCount(count: cache.labels.count, zoomScale: zoomScale)
        )
        let window = ChartWindow(labels: cache.labels, centerIndex: centerIndex(for: identity), zoomScale: zoomScale)
        let domain = paddedChartDomain(
            yMin: cache.yMin,
            yMax: cache.yMax,
            allowsNegative: seriesList.contains { $0.baseline == .signed }
        )
        let context = TrendChartContext(cache: cache, selectedIndex: selected, risen: risen)

        VStack(spacing: AppSpacing.lg) {
            banner(index: selected)
            entered(
                plot(context)
                    .chartXScale(domain: window.categories)
                    .chartYScale(domain: domain)
                    .chartXVisibleDomain(length: window.visibleCount)
                    .chartScrollableAxes(.horizontal)
                    .chartScrollPosition(initialX: window.leadingLabel)
                    .chartXSelection(value: $rawSelection)
                    .chartCategoryXAxis(labelMap: cache.axisLabels)
                    .chartCompactYAxis()
                    .chartLegend(.hidden)
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
                    .padding(.leading, AppSpacing.lg)
                    .frame(height: ChartMetrics.plotHeight)
            )
        }
        .animation(motion(AppAnimation.chartUpdateAnimation), value: identity)
        .chartFadeIn()
        .onChange(of: rawSelection) { _, new in
            guard let new, let index = cache.labelToIndex[new], index != selectedIndex else { return }
            if let selection {
                selection.wrappedValue = new
            } else {
                ownSelection = new
            }
            HapticManager.selection()
        }
        .onChange(of: identity, initial: true) { _, newIdentity in
            windowCenter = TrendChartCenter(label: label(at: selectedIndex), identity: newIdentity)
        }
        .onAppear(perform: rise)
    }

    // MARK: - Pieces

    private func banner(index: Int) -> some View {
        let title = cache.titles[index]
        return ChartSelectionBanner(
            title: title,
            note: cache.isPartial[index] ? ChartText.partial : nil,
            entries: chartBannerEntries(index: index, cache: cache, series: seriesList),
            format: valueFormat
        )
        .screenPadding()
        .animation(AppAnimation.chartBannerFade, value: index)
        .chartSelectionAnnouncement(chartAnnouncementText(title: title, index: index, cache: cache, series: seriesList))
    }

    @ViewBuilder
    private func entered<Content: View>(_ content: Content) -> some View {
        switch entrance {
        case .drawIn: content.chartDrawIn()
        case .rise: content
        }
    }

    private func label(at index: Int) -> String? {
        cache.labels.indices.contains(index) ? cache.labels[index] : nil
    }

    private func motion(_ animation: Animation) -> Animation? {
        AppAnimation.motion(animation, reduceMotion: reduceMotion, isEnabled: designKitMotion)
    }

    /// The bars rise from zero once, as the chart first appears.
    private func rise() {
        guard entrance == .rise, !hasRisen else { return }
        guard allowsMotion, playsEntrance else {
            hasRisen = true
            return
        }
        withAnimation(AppAnimation.chartAppearAnimation.delay(AppAnimation.chartAppearDelay)) {
            hasRisen = true
        }
    }
}

/// What makes a new chart: other periods or another window size.
struct TrendChartIdentity: Hashable {
    let labels: Int
    let visibleCount: Int
}

/// Where a chart's window was centred.
struct TrendChartCenter: Equatable {
    let label: String?
    let identity: TrendChartIdentity
}

/// The selected point of a line: a soft halo under a dot in a ring of the background, so it
/// stands out from the line it sits on (8.2.0).
struct ChartSelectedDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .padding(ChartMetrics.selectedRing)
            .background(Circle().fill(AppColors.Background.base))
            .frame(width: ChartMetrics.selectedDot, height: ChartMetrics.selectedDot)
    }
}
