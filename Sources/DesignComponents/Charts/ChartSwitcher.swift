//
//  ChartSwitcher.swift
//  DesignKit
//
//  LineChart and BarChart behind a bar/line segmented picker and −/+ zoom controls
//  (Tenra's insight detail charts). 8.3.0: the selected period outlives a switch (the other
//  chart opens centred on it), only the first chart plays its entrance, and under
//  `.chartDisplayOptions(_:)` a menu by the zoom turns the chart's extras on and off.
//
//  ┌──────────┐        ┌────┐ ┌────┐ ┌────┐
//  │ Bar/Line │  …     │ ≡  │ │  − │ │  + │       ← controls row (≡: the options menu)
//  └──────────┘        └────┘ └────┘ └────┘
//  ┌──────────────────────────────────────────┐
//  │              chart content               │
//  └──────────────────────────────────────────┘
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Bar/line chart with a style picker and zoom. The selected period stays when the style
/// changes.
///
/// ```swift
/// ChartSwitcher(dataPoints: months, series: [income, spending], valueFormat: .currency("KZT"))
/// ```
public struct ChartSwitcher<Point: ChartPoint>: View {
    let dataPoints: [Point]
    let seriesList: [ChartSeries<Point>]
    let valueFormat: ChartValueFormat
    let todayText: String
    let emptyTitle: String
    let emptyMessage: String?
    let options: TrendChartOptions

    @State private var style: ChartStyle
    @State private var zoomScale: CGFloat = 1.0
    /// The selected period's `chartLabel`; nil: the current period.
    @State private var selection: String?
    /// Once the style changed, the next chart is simply there: no second entrance.
    @State private var hasSwitched = false
    /// The person's chart options; the menu shows only under `.chartDisplayOptions(_:)`.
    @Environment(\.chartDisplayOptions) private var displayOptions

    /// Parameters as in `LineChart`; `initialStyle` picks the first chart shown, `barLayout`
    /// how the bars draw several series (8.3.0).
    public init(
        dataPoints: [Point],
        series: [ChartSeries<Point>],
        valueFormat: ChartValueFormat = .compact,
        todayText: String = String(localized: "chart.today"),
        emptyTitle: String = String(localized: "chart.empty.title"),
        emptyMessage: String? = String(localized: "chart.empty.message"),
        initialStyle: ChartStyle = .line,
        barLayout: BarChartLayout = .grouped,
        referenceLines: [ChartReferenceLine] = [],
        marksExtremes: Bool = false,
        followsScroll: Bool = false,
        comparisonLabel: String = String(localized: "chart.yearAgo", defaultValue: "A year ago")
    ) {
        self.dataPoints = dataPoints
        self.seriesList = series
        self.valueFormat = valueFormat
        self.todayText = todayText
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.options = TrendChartOptions(
            referenceLines: referenceLines,
            marksExtremes: marksExtremes,
            followsScroll: followsScroll,
            stacked: barLayout == .stacked,
            comparisonLabel: comparisonLabel
        )
        self._style = State(initialValue: initialStyle)
    }

    /// Single-series convenience.
    public init(
        dataPoints: [Point],
        series: ChartSeries<Point>,
        valueFormat: ChartValueFormat = .compact,
        todayText: String = String(localized: "chart.today"),
        emptyTitle: String = String(localized: "chart.empty.title"),
        emptyMessage: String? = String(localized: "chart.empty.message"),
        initialStyle: ChartStyle = .line,
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
            initialStyle: initialStyle,
            referenceLines: referenceLines,
            marksExtremes: marksExtremes,
            followsScroll: followsScroll,
            comparisonLabel: comparisonLabel
        )
    }

    public var body: some View {
        VStack(spacing: AppSpacing.sm) {
            controlsRow.screenPadding()

            Group {
                switch style {
                case .line:
                    LineChart(
                        dataPoints: dataPoints,
                        series: seriesList,
                        valueFormat: valueFormat,
                        todayText: todayText,
                        emptyTitle: emptyTitle,
                        emptyMessage: emptyMessage,
                        zoomScale: $zoomScale,
                        options: lineOptions,
                        selection: $selection
                    )
                case .bar:
                    BarChart(
                        dataPoints: dataPoints,
                        series: seriesList,
                        valueFormat: valueFormat,
                        todayText: todayText,
                        emptyTitle: emptyTitle,
                        emptyMessage: emptyMessage,
                        zoomScale: $zoomScale,
                        options: options,
                        selection: $selection
                    )
                }
            }
            .id(style)
            .transition(.opacity)
            .environment(\.chartPlaysEntrance, !hasSwitched)
        }
        .animation(AppAnimation.gentleSpring, value: style)
    }

    /// The line has no stacks: its options without them.
    private var lineOptions: TrendChartOptions {
        var line = options
        line.stacked = false
        return line
    }

    /// The picker's selection: a switch also turns the next chart's entrance off, in the same
    /// update, so the new chart never starts one.
    private var styleSelection: Binding<ChartStyle> {
        Binding(
            get: { style },
            set: { newStyle in
                hasSwitched = true
                style = newStyle
            }
        )
    }

    // MARK: - Controls row

    private var controlsRow: some View {
        HStack(spacing: AppSpacing.md) {
            picker
            Spacer()
            if let displayOptions {
                ChartOptionsMenu(
                    options: displayOptions,
                    offersForecast: seriesList.contains { $0.projected != nil },
                    offersComparison: seriesList.contains { $0.comparison != nil },
                    comparisonLabel: options.comparisonLabel
                )
            }
            ChartZoomControls(zoomScale: $zoomScale, range: 0.4...4.0)
        }
    }

    private var picker: some View {
        Picker("", selection: styleSelection) {
            ForEach(ChartStyle.allCases) { s in
                // A system segmented picker's item: iOS draws its symbol (7.0.0, outside the Icon rule).
                Label(s.label, systemImage: s.systemImage)
                    .labelStyle(.iconOnly)
                    .tag(s)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .frame(maxWidth: 120)
        .accessibilityLabel(Text(String(localized: "chart.style", defaultValue: "Chart style")))
        .onChange(of: style) { _, _ in
            HapticManager.selection()
        }
    }
}

// MARK: - Options menu

/// The person's chart options in a menu (8.3.0): a glass button by the zoom. A forecast and a
/// comparison are offered only when a series has them. The menu stays open while the person
/// turns several on or off; its items are iOS's (outside the Icon rule).
struct ChartOptionsMenu: View {
    @Binding var options: ChartDisplayOptions
    let offersForecast: Bool
    let offersComparison: Bool
    let comparisonLabel: String

    init(options: Binding<ChartDisplayOptions>, offersForecast: Bool, offersComparison: Bool, comparisonLabel: String) {
        self._options = options
        self.offersForecast = offersForecast
        self.offersComparison = offersComparison
        self.comparisonLabel = comparisonLabel
    }

    var body: some View {
        Menu {
            toggle(.average, String(localized: "chart.option.average", defaultValue: "Average line"),
                   systemImage: "chart.line.flattrend.xyaxis")
            toggle(.records, String(localized: "chart.option.records", defaultValue: "Highs and lows"),
                   systemImage: "arrow.up.arrow.down")
            if offersForecast {
                toggle(.forecast, ChartText.forecast, systemImage: "chart.line.uptrend.xyaxis")
            }
            if offersComparison {
                toggle(.comparison, comparisonLabel, systemImage: "clock.arrow.circlepath")
            }
            Divider()
            toggle(.followsScroll, String(localized: "chart.option.followsScroll", defaultValue: "Scroll under a ruler"),
                   systemImage: "arrow.left.and.right")
        } label: {
            Icon("slider.horizontal.3", size: AppIconSize.md)
                .fontWeight(.medium)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .menuActionDismissBehavior(.disabled)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(Text(String(localized: "chart.options", defaultValue: "Chart options")))
    }

    private func toggle(_ option: ChartDisplayOptions, _ title: String, systemImage: String) -> some View {
        Toggle(isOn: Binding(
            get: { options.contains(option) },
            set: { isOn in
                HapticManager.selection()
                if isOn { options.insert(option) } else { options.remove(option) }
            }
        )) {
            Label(title, systemImage: systemImage)
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `ChartSwitcher`: the style picker and zoom buttons, then the chart's
/// skeleton. `series: 2` for a chart of two series, whose banner names each.
public struct ChartSwitcherSkeleton: View {
    let style: ChartStyle
    let series: Int

    @Environment(\.chartDisplayOptions) private var displayOptions

    public init(style: ChartStyle = .line, series: Int = 1) {
        self.style = style
        self.series = series
    }

    public var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                // The segmented picker (a capsule), the options menu's button under
                // `.chartDisplayOptions(_:)`, and the two round zoom buttons.
                Skeleton.capsule(height: 32, width: 120)
                Spacer()
                if displayOptions != nil {
                    Skeleton.circle(44)
                }
                HStack(spacing: 0) {
                    Skeleton.circle(44)
                    Skeleton.circle(44)
                }
            }
            .shimmer()
            .screenPadding()

            switch style {
            case .line: LineChartSkeleton(series: series)
            case .bar: BarChartSkeleton(series: series)
            }
        }
        .skeletonLoadingLabel()
    }
}
