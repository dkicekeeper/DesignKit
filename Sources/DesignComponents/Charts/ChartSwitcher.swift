//
//  ChartSwitcher.swift
//  DesignKit
//
//  LineChart and BarChart behind a bar/line segmented picker and −/+ zoom controls
//  (Tenra's insight detail charts).
//
//  ┌──────────┐               ┌────┐ ┌────┐
//  │ Bar/Line │  …            │  − │ │  + │       ← controls row
//  └──────────┘               └────┘ └────┘
//  ┌──────────────────────────────────────────┐
//  │              chart content               │
//  └──────────────────────────────────────────┘
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Bar/line chart with a style picker and zoom. Selection resets when the style changes.
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

    @State private var style: ChartStyle
    @State private var zoomScale: CGFloat = 1.0

    /// Parameters as in `LineChart`; `initialStyle` picks the first chart shown.
    public init(
        dataPoints: [Point],
        series: [ChartSeries<Point>],
        valueFormat: ChartValueFormat = .compact,
        todayText: String = String(localized: "chart.today"),
        emptyTitle: String = String(localized: "chart.empty.title"),
        emptyMessage: String? = String(localized: "chart.empty.message"),
        initialStyle: ChartStyle = .line
    ) {
        self.dataPoints = dataPoints
        self.seriesList = series
        self.valueFormat = valueFormat
        self.todayText = todayText
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
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
        initialStyle: ChartStyle = .line
    ) {
        self.init(
            dataPoints: dataPoints,
            series: [series],
            valueFormat: valueFormat,
            todayText: todayText,
            emptyTitle: emptyTitle,
            emptyMessage: emptyMessage,
            initialStyle: initialStyle
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
                        zoomScale: $zoomScale
                    )
                case .bar:
                    BarChart(
                        dataPoints: dataPoints,
                        series: seriesList,
                        valueFormat: valueFormat,
                        todayText: todayText,
                        emptyTitle: emptyTitle,
                        emptyMessage: emptyMessage,
                        zoomScale: $zoomScale
                    )
                }
            }
            .id(style)        // fresh state (selection) on style change
            .transition(.opacity)
        }
        .animation(AppAnimation.gentleSpring, value: style)
    }

    // MARK: - Controls row

    private var controlsRow: some View {
        HStack(spacing: AppSpacing.md) {
            picker
            Spacer()
            ChartZoomControls(zoomScale: $zoomScale, range: 0.4...4.0)
        }
    }

    private var picker: some View {
        Picker("", selection: $style) {
            ForEach(ChartStyle.allCases) { s in
                Label(s.label, systemImage: s.systemImage)
                    .labelStyle(.iconOnly)
                    .tag(s)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .frame(maxWidth: 120)
        .accessibilityLabel(Text(verbatim: "Chart style"))
        .onChange(of: style) { _, _ in
            HapticManager.selection()
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `ChartSwitcher`: the style picker and zoom buttons, then the chart's
/// skeleton.
public struct ChartSwitcherSkeleton: View {
    let style: ChartStyle

    public init(style: ChartStyle = .line) {
        self.style = style
    }

    public var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                // The segmented picker (a capsule) and the two round zoom buttons.
                Skeleton.capsule(height: 32, width: 120)
                Spacer()
                HStack(spacing: 0) {
                    Skeleton.circle(44)
                    Skeleton.circle(44)
                }
            }
            .shimmer()
            .screenPadding()

            switch style {
            case .line: LineChartSkeleton()
            case .bar: BarChartSkeleton()
            }
        }
        .skeletonLoadingLabel()
    }
}
