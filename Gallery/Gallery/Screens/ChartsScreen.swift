//
//  ChartsScreen.swift
//  DesignKit Gallery
//
//  Charts: trends over time (line, bar, switcher, sparklines), the breakdown orb, the
//  selection banner and zoom.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct ChartsScreen: View {
    static let title = "Charts"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        ChartSwitcherPage()
        LineChartPage()
        BarChartPage()
        HeroSparklinePage()
        SparklinePage()
        CalendarHeatmapPage()
        OrbChartPage()
        ChartSelectionBannerPage()
        ChartZoomControlsPage()
    }
}

/// The extras a trend chart page can switch on (8.2.0).
private struct TrendExtras {
    var forecast = true
    var lastYear = false
    var average = false
    var limit = false
    var records = false
    var followsScroll = false

    var expenses: ChartSeries<ChartValuePoint> {
        .keyed("expenses", name: "Expenses", coloring: .solid(AppColors.destructive), better: .lower,
               projectedKey: forecast ? "expensesForecast" : nil, comparisonKey: lastYear ? "expensesLastYear" : nil)
    }

    var income: ChartSeries<ChartValuePoint> {
        .keyed("income", name: "Income", coloring: .solid(AppColors.success), better: .higher,
               projectedKey: forecast ? "incomeForecast" : nil, comparisonKey: lastYear ? "incomeLastYear" : nil)
    }

    var distance: ChartSeries<ChartValuePoint> {
        .keyed("km", name: "Distance", coloring: .solid(AppColors.accent), better: .higher,
               projectedKey: forecast ? "kmForecast" : nil, comparisonKey: lastYear ? "kmLastYear" : nil)
    }

    func referenceLines(limit value: Double) -> [ChartReferenceLine] {
        var lines: [ChartReferenceLine] = []
        if average { lines.append(.average(label: "Average")) }
        if limit { lines.append(.value(value, label: "Limit", aboveColor: AppColors.warning)) }
        return lines
    }

    var key: String { "\(forecast)\(lastYear)\(average)\(limit)\(records)\(followsScroll)" }
}

/// The switches for `TrendExtras`.
private struct TrendExtrasControls: View {
    @Binding var extras: TrendExtras
    var limitLabel = "Limit line (bars past it orange)"

    var body: some View {
        ToggleControl("Forecast for this month", isOn: $extras.forecast)
        ToggleControl("A year ago", isOn: $extras.lastYear)
        ToggleControl("Average line", isOn: $extras.average)
        ToggleControl(limitLabel, isOn: $extras.limit)
        ToggleControl("Records (highest, lowest)", isOn: $extras.records)
        ToggleControl("Selection follows the scroll", isOn: $extras.followsScroll)
    }
}

private struct ChartSwitcherPage: View {
    @State private var initial: ChartStyle = .line
    @State private var inProgress = true
    @State private var extras = TrendExtras()
    /// The options menu: the person's choice, kept in `@AppStorage` by an app.
    @State private var usesMenu = true
    @State private var shown = ChartDisplayOptions.standard
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ChartSwitcher",
            summary: "A LineChart and a BarChart of the same data with a switch between them; zoom and tap a point.",
            since: "0.5.0",
            apps: [.tenra],
            canvas: .bleed,
            notes: [
                "Opens on the current period, selected and in the middle of the window (8.2.0).",
                "The selected period stays when you switch; zoom re-centres on it.",
                "Press and drag across periods: the banner sums them up.",
                "Under .chartDisplayOptions($options) a menu by the zoom turns the average, records, forecast, a year ago and the ruler on and off for every chart of the app (8.2.0).",
            ]
        ) {
            Group {
                switch state {
                case .loading:
                    ChartSwitcherSkeleton(style: initial, series: 2)
                case .empty:
                    ChartSwitcher(dataPoints: [], series: [GallerySamples.income, GallerySamples.expenses],
                                  valueFormat: .currency("KZT"), todayText: "Today", initialStyle: initial)
                default:
                    if usesMenu {
                        // The menu decides: the series offer their forecast and a year ago.
                        let offered = TrendExtras(forecast: true, lastYear: true, limit: extras.limit)
                        ChartSwitcher(dataPoints: GallerySamples.monthSeries(24, inProgress: inProgress),
                                      series: [offered.income, offered.expenses],
                                      valueFormat: .currency("KZT"), todayText: "Today", initialStyle: initial,
                                      referenceLines: offered.referenceLines(limit: 560_000))
                            .id("\(initial)\(inProgress)\(extras.limit)")
                    } else {
                        ChartSwitcher(dataPoints: GallerySamples.monthSeries(24, inProgress: inProgress),
                                      series: [extras.income, extras.expenses],
                                      valueFormat: .currency("KZT"), todayText: "Today", initialStyle: initial,
                                      referenceLines: extras.referenceLines(limit: 560_000),
                                      marksExtremes: extras.records, followsScroll: extras.followsScroll)
                            .id("\(initial)\(inProgress)\(extras.key)")
                    }
                }
            }
            .modifier(GalleryChartOptions(options: usesMenu ? $shown : nil))
        } controls: {
            StateControl(state: $state, states: [.content, .loading, .empty])
            ChoiceControl("Starts as", selection: $initial, options: [("Line", .line), ("Bar", .bar)])
            ToggleControl("This month in progress", isOn: $inProgress)
            ToggleControl("Options menu (.chartDisplayOptions)", isOn: $usesMenu)
            if usesMenu {
                ToggleControl("Limit line (bars past it orange)", isOn: $extras.limit)
            } else {
                TrendExtrasControls(extras: $extras)
            }
        }
    }
}

/// `.chartDisplayOptions(_:)` when the page shows the menu.
private struct GalleryChartOptions: ViewModifier {
    let options: Binding<ChartDisplayOptions>?

    func body(content: Content) -> some View {
        if let options {
            content.chartDisplayOptions(options)
        } else {
            content
        }
    }
}

private struct LineChartPage: View {
    @State private var signed = false
    @State private var inProgress = true
    @State private var count = 24.0
    @State private var extras = TrendExtras(average: true, records: true)
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "LineChart",
            summary: "A trend over time; a signed series is green above zero and red below with a dashed zero rule.",
            since: "0.5.0",
            apps: [.tenra],
            canvas: .bleed,
            notes: [
                "Opens on the current period, selected and in the middle of the window; the banner always shows the selected period and its change from the one before (8.2.0).",
                "A period that is not over (ChartPoint.chartIsPartial) ends the line in dashes and reads “so far”; with a forecast (ChartSeries.projected) a dotted rise goes to it.",
                "Press and drag across periods: the banner sums them up. In dark mode the line glows.",
            ]
        ) {
            if state == .loading {
                LineChartSkeleton(series: signed ? 1 : 2)
            } else if state == .empty {
                LineChart(dataPoints: [], series: GallerySamples.netFlow, todayText: "Today")
            } else {
                LineChart(dataPoints: GallerySamples.monthSeries(Int(count), inProgress: inProgress),
                          series: signed ? [GallerySamples.netFlow] : [extras.income, extras.expenses],
                          valueFormat: .currency("KZT"), todayText: "Today",
                          referenceLines: extras.referenceLines(limit: 600_000),
                          marksExtremes: extras.records, followsScroll: extras.followsScroll)
                    .id("\(signed)\(inProgress)\(extras.key)")
            }
        } controls: {
            StateControl(state: $state, states: [.content, .loading, .empty])
            ToggleControl("Signed series (net)", isOn: $signed)
            ToggleControl("This month in progress", isOn: $inProgress)
            SliderControl("Months", value: $count, in: 4...120, step: 1)
            TrendExtrasControls(extras: $extras, limitLabel: "Limit line")
        }
    }
}

private struct BarChartPage: View {
    private enum Data: Hashable { case distance, incomeAndSpending, categories }

    @State private var count = 24.0
    @State private var data: Data = .distance
    @State private var inProgress = true
    @State private var extras = TrendExtras(lastYear: true, limit: true)
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "BarChart",
            summary: "Bars per period, one or several series side by side or stacked.",
            since: "0.5.0",
            apps: [.tenra],
            canvas: .bleed,
            notes: [
                "Opens on the current period, selected and in the middle of the window; its bars are in full colour, the others step back (8.2.0).",
                "The bars rise from zero as the chart appears; a period that is not over fades towards the top, under a pale bar up to its forecast; a pale wider bar shows a year ago.",
                "layout: .stacked puts the series on top of each other; the banner leads with the total.",
            ],
            styles: ["grouped", "stacked"]
        ) {
            if state == .loading {
                BarChartSkeleton(bars: min(Int(count), 12), series: data == .distance ? 1 : 2)
            } else if state == .empty {
                BarChart(dataPoints: [], series: GallerySamples.distance, todayText: "Today")
            } else {
                switch data {
                case .distance:
                    BarChart(dataPoints: GallerySamples.monthSeries(Int(count), inProgress: inProgress),
                             series: extras.distance,
                             valueFormat: .custom({ "\($0.formatted(.number.precision(.fractionLength(0)))) km" }),
                             todayText: "Today",
                             referenceLines: extras.referenceLines(limit: 55),
                             marksExtremes: extras.records, followsScroll: extras.followsScroll)
                        .id("one\(inProgress)\(extras.key)")
                case .incomeAndSpending:
                    BarChart(dataPoints: GallerySamples.monthSeries(Int(count), inProgress: inProgress),
                             series: [extras.income, extras.expenses],
                             valueFormat: .currency("KZT"), todayText: "Today",
                             referenceLines: extras.referenceLines(limit: 560_000),
                             marksExtremes: extras.records, followsScroll: extras.followsScroll)
                        .id("two\(inProgress)\(extras.key)")
                case .categories:
                    BarChart(dataPoints: GallerySamples.monthSeries(Int(count), inProgress: inProgress),
                             series: GallerySamples.categories,
                             valueFormat: .currency("KZT"), todayText: "Today",
                             layout: .stacked,
                             referenceLines: extras.referenceLines(limit: 560_000),
                             followsScroll: extras.followsScroll)
                        .id("stacked\(inProgress)\(extras.key)")
                }
            }
        } controls: {
            StateControl(state: $state, states: [.content, .loading, .empty])
            ChoiceControl("Data", selection: $data, options: [
                ("Distance", .distance), ("Income and spending", .incomeAndSpending), ("Spending by category (stacked)", .categories),
            ])
            ToggleControl("This month in progress", isOn: $inProgress)
            SliderControl("Months", value: $count, in: 4...120, step: 1)
            TrendExtrasControls(extras: $extras)
        }
    }
}

private struct CalendarHeatmapPage: View {
    private enum Tint: Hashable { case spending, distance }

    @State private var weeks = 26.0
    @State private var tint: Tint = .spending
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "CalendarHeatmap",
            summary: "Days as small squares, a week per column, tinted by their value; tap a day for its amount.",
            since: "8.2.0",
            canvas: .fill,
            notes: [
                "Five steps from an empty grey square to the full colour, by the quartiles of the days with a value.",
                "Opens on today at the trailing end; days after today are not drawn.",
            ]
        ) {
            switch state {
            case .loading:
                CalendarHeatmapSkeleton(weeks: Int(weeks))
            case .empty:
                CalendarHeatmap(values: [:])
            default:
                CalendarHeatmap(
                    values: GallerySamples.spendingByDay(),
                    weeks: Int(weeks),
                    color: tint == .spending ? AppColors.destructive : AppColors.accent,
                    valueFormat: .currency("KZT")
                )
            }
        } controls: {
            StateControl(state: $state, states: [.content, .loading, .empty])
            SliderControl("Weeks", value: $weeks, in: 4...53, step: 1)
            ChoiceControl("Colour", selection: $tint, options: [("Spending", .spending), ("Accent", .distance)])
        }
    }
}

private struct HeroSparklinePage: View {
    @State private var projects = true
    @State private var marksExtremes = true
    @State private var onColor = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "HeroSparkline",
            summary: "A detail screen's hero trend: a dashed projection tail, min and max markers, tap for a value.",
            since: "0.5.0",
            apps: [.tenra],
            canvas: .bleed,
            notes: ["Inside .heroBackground (4.5.0): a white line over a white fade, white points, translucent white axes."]
        ) {
            if state == .loading {
                HeroSparklineSkeleton()
            } else {
                HeroSparkline(
                    dataPoints: Array(GallerySamples.months.suffix(8)),
                    series: GallerySamples.distance,
                    projectedValue: projects ? 64 : nil,
                    markExtremes: marksExtremes,
                    valueFormat: .custom({ "\($0.formatted(.number.precision(.fractionLength(0...1)))) km" })
                )
                .id("\(projects)\(marksExtremes)\(onColor)")
                .galleryHeroBackground(onColor, color: AppColors.accent)
            }
        } controls: {
            StateControl(state: $state)
            HeroBackgroundControl(onColor: $onColor)
            ToggleControl("Projection", isOn: $projects)
            ToggleControl("Min and max", isOn: $marksExtremes)
        }
    }
}

private struct SparklinePage: View {
    @State private var signed = false
    @State private var projects = false
    @State private var height = 60.0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "Sparkline",
            summary: "A tiny trend for cards and feeds, drawn on a Canvas.",
            since: "0.5.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                SparklineSkeleton(height: height)
            } else if projects {
                Sparkline(values: [12, 18, 15, 22, 27], coloring: .solid(AppColors.warning),
                          height: height, projectedValue: 34)
            } else {
                Sparkline(dataPoints: GallerySamples.months,
                          series: signed ? GallerySamples.netFlow : GallerySamples.distance)
                    .frame(height: height)
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Signed series", isOn: $signed)
            ToggleControl("Forecast", isOn: $projects)
            SliderControl("Height", value: $height, in: 32...120, step: 4)
        }
    }
}

private struct OrbChartPage: View {
    @State private var size = 240.0
    @State private var labels = true
    @State private var byName = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "OrbChart",
            summary: "A breakdown as a glass orb with thin perimeter arcs and centred labels.",
            apps: [.tenra],
            notes: ["DonutSlice.foldingSlivers merges shares under 5% into “Other”."]
        ) {
            if state == .loading {
                OrbChartSkeleton(size: size)
            } else {
                OrbChart(slices: GallerySamples.slices, size: size, showLabels: labels,
                         labelStyle: byName ? .name : .percent)
                    .frame(height: size + 40)
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Size", value: $size, in: 160...300, step: 10)
            ToggleControl("Labels", isOn: $labels)
            ToggleControl("Names instead of %", isOn: $byName)
        }
    }
}

private struct ChartSelectionBannerPage: View {
    @State private var twoValues = true
    @State private var inProgress = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ChartSelectionBanner",
            summary: "The selected period: its title and one or more values; with several series it names each.",
            since: "0.5.0",
            canvas: .fill,
            notes: ["A note after the title in the secondary colour, “so far” for a period that is not over (8.2.0)."]
        ) {
            if state == .loading {
                ChartSelectionBannerSkeleton(values: twoValues ? 2 : 1)
            } else if twoValues {
                ChartSelectionBanner(title: "January 2026", note: inProgress ? "so far" : nil, entries: [
                    .init(value: 480_000, color: AppColors.success, label: "Income"),
                    .init(value: 275_000, color: AppColors.destructive, label: "Expenses"),
                ], format: .currency("KZT"))
            } else {
                ChartSelectionBanner(title: "Week 12", note: inProgress ? "so far" : nil, entries: [
                    .init(value: 42.5, color: AppColors.accent, showsDot: false),
                ], format: .custom({ "\($0.formatted()) km" }))
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Two values", isOn: $twoValues)
            ToggleControl("In progress", isOn: $inProgress)
        }
    }
}

private struct ChartZoomControlsPage: View {
    @State private var zoom: CGFloat = 1

    var body: some View {
        ComponentPage(
            name: "ChartZoomControls",
            summary: "Glass − and + to zoom a chart's time axis within a range."
        ) {
            VStack(spacing: AppSpacing.sm) {
                ChartZoomControls(zoomScale: $zoom, range: 1...4)
                Text("zoom \(zoom, specifier: "%.1f")×")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

#Preview { NavigationStack { ChartsScreen() } }
