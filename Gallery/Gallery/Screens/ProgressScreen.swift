//
//  ProgressScreen.swift
//  DesignKit Gallery
//
//  Progress and gauges: bars, rings, proportions, half-gauges, milestones, bar pairs — mini for
//  cards and hero for detail screens.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct ProgressScreen: View {
    static let title = "Progress & Gauges"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        LinearProgressBarPage()
        ProgressRingPage()
        ProportionBarPage()
        AmountComparisonBarPage()
        MiniDonutPage()
        ProportionBarsPage()
        HalfGaugePage()
        MilestoneGaugePage()
        BarPairPage()
    }
}

private struct LinearProgressBarPage: View {
    @State private var value = 0.72
    @State private var height = 8.0
    @State private var projected = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "LinearProgressBar",
            summary: "A bar of progress; over 100% it turns red. A projection shows where the period will end.",
            apps: [.tenra, .dalada],
            canvas: .fill
        ) {
            if state == .loading {
                LinearProgressBarSkeleton(height: height)
            } else {
                LinearProgressBar(percentage: value * 100, isOverBudget: value > 1, color: AppColors.accent,
                                  height: height, projectedPercentage: projected ? min(value * 130, 150) : nil)
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Progress", value: $value, in: 0...1.5, step: 0.01) { "\(Int($0 * 100))%" }
            SliderControl("Height", value: $height, in: 4...16, step: 1)
            ToggleControl("Projection", isOn: $projected)
        }
    }
}

private struct ProgressRingPage: View {
    @State private var progress = 0.45
    @State private var lineWidth = 5.0
    @State private var showsTrack = true
    @State private var celebrates = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ProgressRing",
            summary: "A ring of progress around something (a category coin); red once over.",
            apps: [.tenra],
            notes: [
                "celebratesCompletion (2.3.0): a goal ring, green at any fill (2.3.1). Reaching 100 % draws a checkmark in, the ring glows once and the success haptic plays. Off for budgets.",
            ]
        ) {
            if state == .loading {
                ProgressRingSkeleton(size: AppIconSize.Tile.xxl, lineWidth: lineWidth)
            } else {
                ProgressRing(progress: progress, size: AppIconSize.Tile.xxl, lineWidth: lineWidth,
                             isOverBudget: !celebrates && progress > 1, showsTrack: showsTrack,
                             celebratesCompletion: celebrates)
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Progress", value: $progress, in: 0...1.5, step: 0.01) { "\(Int($0 * 100))%" }
            SliderControl("Line width", value: $lineWidth, in: 2...10, step: 1)
            ToggleControl("Track", isOn: $showsTrack)
            ToggleControl("Celebrates completion (goal)", isOn: $celebrates)
        }
    }
}

private struct ProportionBarPage: View {
    @State private var ratio = 0.65
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ProportionBar",
            summary: "One bar split in two: a share and the rest.",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                ProportionBarSkeleton()
            } else {
                ProportionBar(ratio: ratio, leftColor: AppColors.income, rightColor: AppColors.bgMuted)
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Share", value: $ratio, in: 0...1, step: 0.01) { "\(Int($0 * 100))%" }
        }
    }
}

private struct AmountComparisonBarPage: View {
    @State private var expenses = 921_300.0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "AmountComparisonBar",
            summary: "Expenses against income as two bars with their amounts.",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                AmountComparisonBarSkeleton()
            } else {
                AmountComparisonBar(expenseAmount: expenses, incomeAmount: 640_000, currency: "KZT")
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Expenses (income 640 000)", value: $expenses, in: 0...1_200_000, step: 1_000)
        }
    }
}

private struct MiniDonutPage: View {
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "MiniDonut",
            summary: "A compact breakdown ring for a card's trailing edge.",
            apps: [.tenra]
        ) {
            if state == .loading {
                MiniDonutSkeleton()
            } else {
                MiniDonut(slices: GallerySamples.slices)
                    .frame(width: 80, height: 80)
            }
        } controls: {
            StateControl(state: $state)
        }
    }
}

private struct ProportionBarsPage: View {
    @State private var hero = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "Mini/HeroProportionBar",
            summary: "A breakdown as a stacked bar: mini for cards, hero with a tappable legend for detail screens.",
            apps: [.tenra],
            canvas: .fill
        ) {
            if hero {
                if state == .loading {
                    HeroProportionBarSkeleton(segments: 4)
                } else {
                    HeroProportionBar(segments: GallerySamples.slices, currency: "KZT")
                }
            } else if state == .loading {
                MiniProportionBarSkeleton()
            } else {
                MiniProportionBar(segments: GallerySamples.slices)
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Size", selection: $hero, options: [("Hero", true), ("Mini", false)])
        }
    }
}

private struct HalfGaugePage: View {
    @State private var value = 0.62
    @State private var norm = true
    @State private var hero = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "Mini/HeroHalfGauge",
            summary: "A value on a half-circle with an optional norm marker and zone ticks.",
            apps: [.tenra]
        ) {
            if hero {
                if state == .loading {
                    HeroHalfGaugeSkeleton(diameter: 220)
                } else {
                    HeroHalfGauge(value: value, norm: norm ? 0.5 : nil, maxValue: 1, zoneTicks: [0.3, 0.7],
                                  color: AppColors.success, diameter: 220)
                        .id("\(value)\(norm)")
                }
            } else if state == .loading {
                MiniHalfGaugeSkeleton()
            } else {
                MiniHalfGauge(value: value, norm: norm ? 0.5 : nil, maxValue: 1, color: AppColors.success)
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Size", selection: $hero, options: [("Hero", true), ("Mini", false)])
            SliderControl("Value", value: $value, in: 0...1, step: 0.01)
            ToggleControl("Norm marker", isOn: $norm)
        }
    }
}

private struct MilestoneGaugePage: View {
    @State private var value = 4.2
    @State private var hero = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "Mini/HeroMilestoneGauge",
            summary: "Progress towards a target on a segmented scale.",
            apps: [.tenra],
            canvas: .fill
        ) {
            if hero {
                if state == .loading {
                    HeroMilestoneGaugeSkeleton()
                } else {
                    HeroMilestoneGauge(value: value, target: 6, maxValue: 12, color: AppColors.accent)
                        .id(value)
                }
            } else if state == .loading {
                MiniMilestoneGaugeSkeleton()
            } else {
                MiniMilestoneGauge(value: value, target: 6, maxValue: 12, color: AppColors.accent)
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Size", selection: $hero, options: [("Hero", true), ("Mini", false)])
            SliderControl("Value (target 6 of 12)", value: $value, in: 0...12, step: 0.1)
        }
    }
}

private struct BarPairPage: View {
    @State private var current = 280_000.0
    @State private var projection = false
    @State private var hero = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "Mini/HeroBarPair",
            summary: "The previous period against the current one; a projection is dashed.",
            apps: [.tenra]
        ) {
            if hero {
                if state == .loading {
                    HeroBarPairSkeleton()
                } else {
                    HeroBarPair(previous: 320_000, current: current, color: AppColors.accent,
                                isProjection: projection, currency: "KZT")
                        .id("\(current)\(projection)")
                }
            } else if state == .loading {
                MiniBarPairSkeleton()
            } else {
                MiniBarPair(previous: 320_000, current: current, color: AppColors.accent, isProjection: projection)
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Size", selection: $hero, options: [("Hero", true), ("Mini", false)])
            SliderControl("Current (previous 320 000)", value: $current, in: 0...500_000, step: 1_000)
            ToggleControl("Projection", isOn: $projection)
        }
    }
}

#Preview { NavigationStack { ProgressScreen() } }
