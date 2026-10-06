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
    var body: some View {
        ShowcasePage(title: "Charts") {
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
}

private struct ChartSwitcherPage: View {
    @State private var initial: ChartStyle = .line
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ChartSwitcher",
            summary: "A LineChart and a BarChart of the same data with a switch between them; zoom and tap a point.",
            since: "0.5.0",
            apps: [.tenra, .dalada],
            canvas: .bleed
        ) {
            switch state {
            case .loading:
                ChartSwitcherSkeleton(style: initial)
            case .empty:
                ChartSwitcher(dataPoints: [], series: [GallerySamples.income, GallerySamples.expenses],
                              valueFormat: .currency("KZT"), todayText: "Today", initialStyle: initial)
            default:
                ChartSwitcher(dataPoints: GallerySamples.months, series: [GallerySamples.income, GallerySamples.expenses],
                              valueFormat: .currency("KZT"), todayText: "Today", initialStyle: initial)
                    .id(initial)
            }
        } controls: {
            StateControl(state: $state, states: [.content, .loading, .empty])
            ChoiceControl("Starts as", selection: $initial, options: [("Line", .line), ("Bar", .bar)])
        }
    }
}

private struct LineChartPage: View {
    @State private var signed = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "LineChart",
            summary: "A trend over time; a signed series is green above zero and red below with a dashed zero rule.",
            since: "0.5.0",
            apps: [.tenra],
            canvas: .bleed
        ) {
            if state == .loading {
                LineChartSkeleton()
            } else if signed {
                LineChart(dataPoints: GallerySamples.months, series: GallerySamples.netFlow,
                          valueFormat: .currency("KZT"), todayText: "Today")
            } else {
                LineChart(dataPoints: GallerySamples.months, series: [GallerySamples.income, GallerySamples.expenses],
                          valueFormat: .currency("KZT"), todayText: "Today")
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Signed series (net)", isOn: $signed)
        }
    }
}

private struct BarChartPage: View {
    @State private var bars = 12.0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "BarChart",
            summary: "Bars per period, one or several series side by side.",
            since: "0.5.0",
            apps: [.tenra, .dalada],
            canvas: .bleed
        ) {
            if state == .loading {
                BarChartSkeleton(bars: Int(bars))
            } else {
                BarChart(dataPoints: Array(GallerySamples.months.suffix(Int(bars))),
                         series: GallerySamples.distance,
                         valueFormat: .custom({ "\($0.formatted(.number.precision(.fractionLength(0)))) km" }),
                         todayText: "Today")
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Bars", value: $bars, in: 4...16, step: 1)
        }
    }
}

private struct HeroSparklinePage: View {
    @State private var projects = true
    @State private var marksExtremes = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "HeroSparkline",
            summary: "A detail screen's hero trend: a dashed projection tail, min and max markers, tap for a value.",
            since: "0.5.0",
            apps: [.tenra],
            canvas: .bleed
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
                .id("\(projects)\(marksExtremes)")
            }
        } controls: {
            StateControl(state: $state)
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
            apps: [.tenra, .dalada],
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

    var body: some View {
        ComponentPage(
            name: "ChartSelectionBanner",
            summary: "What a tapped point holds: its title and one or more values with colour dots.",
            since: "0.5.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            if twoValues {
                ChartSelectionBanner(title: "January 2026", entries: [
                    .init(value: 480_000, color: AppColors.success),
                    .init(value: 275_000, color: AppColors.destructive),
                ], format: .currency("KZT"))
            } else {
                ChartSelectionBanner(title: "Week 12", entries: [
                    .init(value: 42.5, color: AppColors.accent, showsDot: false),
                ], format: .custom({ "\($0.formatted()) km" }))
            }
        } controls: {
            ToggleControl("Two values", isOn: $twoValues)
        }
    }
}

private struct ChartZoomControlsPage: View {
    @State private var zoom: CGFloat = 1

    var body: some View {
        ComponentPage(
            name: "ChartZoomControls",
            summary: "Glass − and + to zoom a chart's time axis within a range.",
            apps: [.tenra]
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
