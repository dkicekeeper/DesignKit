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
        OrbChartPage()
        ChartSelectionBannerPage()
        ChartZoomControlsPage()
    }
}

private struct ChartSwitcherPage: View {
    @State private var initial: ChartStyle = .line
    @State private var inProgress = true
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
            ]
        ) {
            switch state {
            case .loading:
                ChartSwitcherSkeleton(style: initial, series: 2)
            case .empty:
                ChartSwitcher(dataPoints: [], series: [GallerySamples.income, GallerySamples.expenses],
                              valueFormat: .currency("KZT"), todayText: "Today", initialStyle: initial)
            default:
                ChartSwitcher(dataPoints: GallerySamples.months(24, inProgress: inProgress),
                              series: [GallerySamples.income, GallerySamples.expenses],
                              valueFormat: .currency("KZT"), todayText: "Today", initialStyle: initial)
                    .id("\(initial)\(inProgress)")
            }
        } controls: {
            StateControl(state: $state, states: [.content, .loading, .empty])
            ChoiceControl("Starts as", selection: $initial, options: [("Line", .line), ("Bar", .bar)])
            ToggleControl("This month in progress", isOn: $inProgress)
        }
    }
}

private struct LineChartPage: View {
    @State private var signed = true
    @State private var inProgress = true
    @State private var count = 24.0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "LineChart",
            summary: "A trend over time; a signed series is green above zero and red below with a dashed zero rule.",
            since: "0.5.0",
            apps: [.tenra],
            canvas: .bleed,
            notes: [
                "Opens on the current period, selected and in the middle of the window; the banner always shows the selected period (8.2.0).",
                "A period that is not over (ChartPoint.chartIsPartial) ends the line in dashes and reads “so far”.",
                "Two series: no fill under the lines, and the banner names each.",
            ]
        ) {
            if state == .loading {
                LineChartSkeleton(series: signed ? 1 : 2)
            } else if state == .empty {
                LineChart(dataPoints: [], series: GallerySamples.netFlow, todayText: "Today")
            } else {
                LineChart(dataPoints: GallerySamples.months(Int(count), inProgress: inProgress),
                          series: signed ? [GallerySamples.netFlow] : [GallerySamples.income, GallerySamples.expenses],
                          valueFormat: .currency("KZT"), todayText: "Today")
                    .id("\(signed)\(inProgress)")
            }
        } controls: {
            StateControl(state: $state, states: [.content, .loading, .empty])
            ToggleControl("Signed series (net)", isOn: $signed)
            ToggleControl("This month in progress", isOn: $inProgress)
            SliderControl("Months", value: $count, in: 4...120, step: 1)
        }
    }
}

private struct BarChartPage: View {
    @State private var count = 24.0
    @State private var twoSeries = false
    @State private var inProgress = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "BarChart",
            summary: "Bars per period, one or several series side by side.",
            since: "0.5.0",
            apps: [.tenra],
            canvas: .bleed,
            notes: [
                "Opens on the current period, selected and in the middle of the window; its bars are in full colour, the others step back (8.2.0).",
                "The bars rise from zero as the chart appears; a period that is not over fades towards the top.",
            ]
        ) {
            if state == .loading {
                BarChartSkeleton(bars: min(Int(count), 12), series: twoSeries ? 2 : 1)
            } else if state == .empty {
                BarChart(dataPoints: [], series: GallerySamples.distance, todayText: "Today")
            } else if twoSeries {
                BarChart(dataPoints: GallerySamples.months(Int(count), inProgress: inProgress),
                         series: [GallerySamples.income, GallerySamples.expenses],
                         valueFormat: .currency("KZT"), todayText: "Today")
                    .id("two\(inProgress)")
            } else {
                BarChart(dataPoints: GallerySamples.months(Int(count), inProgress: inProgress),
                         series: GallerySamples.distance,
                         valueFormat: .custom({ "\($0.formatted(.number.precision(.fractionLength(0)))) km" }),
                         todayText: "Today")
                    .id("one\(inProgress)")
            }
        } controls: {
            StateControl(state: $state, states: [.content, .loading, .empty])
            ToggleControl("Two series", isOn: $twoSeries)
            ToggleControl("This month in progress", isOn: $inProgress)
            SliderControl("Months", value: $count, in: 4...120, step: 1)
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
