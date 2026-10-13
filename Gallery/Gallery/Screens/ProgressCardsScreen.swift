//
//  ProgressCardsScreen.swift
//  DesignKit Gallery
//
//  Cards about progress and numbers: limits, targets, payoffs, scores, metrics, stats, streaks,
//  ring tiles.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct ProgressCardsScreen: View {
    static let title = "Cards: Progress & Stats"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        LimitProgressCardPage()
        TargetProgressCardPage()
        PayoffProgressCardPage()
        ScoreCardPage()
        ScoreGaugeCardPage()
        MetricCardPage()
        InsightsStatCardPage()
        StatTilePage()
        StatsStripPage()
        StreakCardPage()
        ProgressRingTilePage()
        ProgressRingTileGridPage()
    }
}

private struct LimitProgressCardPage: View {
    @State private var spent = 185_000.0
    @State private var showsCaption = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "LimitProgressCard",
            summary: "Progress towards a limit: icon, name, spent of limit, a bar that turns red once over.",
            since: "1.1.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                LimitProgressCardSkeleton()
            } else {
                LimitProgressCard(iconSource: .sfSymbol("fork.knife"), title: "Food", color: .orange,
                                  spent: spent, limit: 250_000, currency: "KZT",
                                  percentage: spent / 250_000 * 100,
                                  caption: showsCaption ? "9 days left" : nil)
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Spent of 250 000", value: $spent, in: 0...400_000, step: 1_000)
            ToggleControl("Caption", isOn: $showsCaption)
        }
    }
}

private struct TargetProgressCardPage: View {
    @State private var progress = 0.5
    @State private var isMuted = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "TargetProgressCard",
            summary: "A metric against its target: current and target values, progress, an explanation and advice; muted when it does not count.",
            since: "1.2.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                TargetProgressCardSkeleton()
            } else {
                TargetProgressCard(
                    systemImage: "banknote.fill",
                    color: AppColors.success,
                    title: "Savings rate",
                    badge: "Weight 30%",
                    summary: "Score \(Int(progress * 100)) of 100",
                    currentLabel: "Current", currentValue: "\((progress * 20).formatted(.number.precision(.fractionLength(1))))%",
                    targetLabel: "Target", targetValue: "20% or more",
                    progress: progress,
                    explanation: "The share of income left after expenses.",
                    recommendation: "Cut expenses by about 60 000 ₸ a month to reach 20%.",
                    isMuted: isMuted
                )
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Progress", value: $progress, in: 0...1, step: 0.05) { "\(Int($0 * 100))%" }
            ToggleControl("Muted", isOn: $isMuted)
        }
    }
}

private struct PayoffProgressCardPage: View {
    @State private var progress = 0.6
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "PayoffProgressCard",
            summary: "A loan or instalment being paid off: remaining of total, the bar, the next date; “repaid” at the end.",
            since: "1.2.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                PayoffProgressCardSkeleton()
            } else {
                PayoffProgressCard(
                    iconSource: .sfSymbol("car.fill"), title: "Car loan", subtitle: "Halyk Bank",
                    remaining: 3_000_000 * (1 - progress), total: 3_000_000, currency: "KZT", progress: progress,
                    phase: progress >= 1
                        ? .done(caption: "Closed 15 Jun 2026")
                        : .inProgress(nextDate: "12 Nov 2026", remainingCaption: "18 left")
                ) {
                    Badge(progress >= 1 ? "Paid off" : "Credit",
                              color: progress >= 1 ? AppColors.income : AppColors.expense)
                }
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Paid", value: $progress, in: 0...1, step: 0.05) { "\(Int($0 * 100))%" }
        }
    }
}

private struct ScoreCardPage: View {
    @State private var score = 72.0
    @State private var decodes = false
    @State private var state: SpecimenState = .content

    private var grade: (String, Color) {
        score >= 70 ? ("Good", AppColors.success) : score >= 40 ? ("Fair", AppColors.warning) : ("Needs attention", AppColors.destructive)
    }

    var body: some View {
        ComponentPage(
            name: "ScoreCard",
            summary: "A score in a feed: grade and value with a mini gauge.",
            since: "1.2.0",
            apps: [.tenra],
            canvas: .fill,
            notes: ["decodesScore (2.7.0): the score decodes itself as it appears and when it changes. Leave it off in a lazy feed."]
        ) {
            if state == .loading {
                ScoreCardSkeleton()
            } else {
                ScoreCard(title: "Health score", grade: grade.0, score: Int(score), color: grade.1, decodesScore: decodes)
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Score", value: $score, in: 0...100, step: 1)
            ToggleControl("Decodes score", isOn: $decodes)
        }
    }
}

private struct ScoreGaugeCardPage: View {
    @State private var score = 72.0
    @State private var hasData = true
    @State private var decodes = false
    @State private var style: ScoreGaugeCard.Style = .card
    @State private var tone: HeroHalfGauge.Tone = .onColor
    @State private var showsMaximum = false
    @State private var showsTrend = false
    @State private var valueKind: ScoreValueKind = .score
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ScoreGaugeCard",
            summary: "A score as a hero half-gauge with zones; “not enough data” without a score. .hero is the top of a screen, edge to edge.",
            since: "1.2.0",
            apps: [.tenra],
            canvas: style == .hero ? .bleed : .fill,
            notes: [
                "decodesScore (2.7.0): the score decodes itself as it appears and when it changes.",
                ".hero (4.2.0): no card and no .screenPadding(); on colour its gradient starts at the screen's top edge, deep with white text in dark mode, pale with black text in light mode (4.5.1). A long score shrinks to stay inside the arc (4.5.1). “Open as a screen” shows it there.",
                "value:fractionDigits:unit: (4.3.0) shows a rate, “12.4%”, on a scale of maxScore; Trend(direction:change:caption:) a change in the score's own units, “+5”.",
                "amount:currency:maxValue:norm: (4.5.0) shows an amount in the app's format, hidden with the app's amounts, with a reference (an average, a budget) notched on the arc.",
            ],
            styles: ["card", "hero"]
        ) {
            if state == .loading {
                ScoreGaugeCardSkeleton(style: style)
            } else {
                switch valueKind {
                case .score:
                    ScoreGaugeSample(score: score, hasData: hasData, decodes: decodes, style: style, tone: tone,
                                     showsMaximum: showsMaximum, showsTrend: showsTrend)
                case .rate:
                    SavingsRateSample(rate: score * 0.4, hasData: hasData, decodes: decodes, style: style, tone: tone,
                                      showsTrend: showsTrend)
                case .amount:
                    // Up to 2 000 000 ₸: a long amount shrinks inside the arc (4.5.1).
                    LargeExpenseSample(amount: score * 20_000, hasData: hasData, style: style, tone: tone)
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Style", selection: $style, options: [("Card", .card), ("Hero", .hero)])
            if style == .hero {
                ChoiceControl("Tone", selection: $tone, options: [("On colour", .onColor), ("On surface", .onSurface)])
            }
            ChoiceControl("Value", selection: $valueKind, options: [("Score", .score), ("Rate", .rate), ("Amount", .amount)])
            SliderControl("Score", value: $score, in: 0...100, step: 1)
            ToggleControl("Has data", isOn: $hasData)
            ToggleControl("Shows /100", isOn: $showsMaximum)
            ToggleControl("Trend", isOn: $showsTrend)
            ToggleControl("Decodes score", isOn: $decodes)
            NavigationLink {
                ScoreHeroScreen(score: score, tone: tone)
            } label: {
                Label("Open as a screen", systemImage: "iphone")
                    .font(AppTypography.bodySmall.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tint(AppColors.accent)
        }
    }
}

/// The score card with the Gallery's grades: Good from 70, Fair from 40, Low below.
private struct ScoreGaugeSample: View {
    let score: Double
    var hasData = true
    var decodes = false
    var style: ScoreGaugeCard.Style = .card
    var tone: HeroHalfGauge.Tone = .onColor
    var showsMaximum = false
    var showsTrend = false

    var body: some View {
        ScoreGaugeCard(score: hasData ? Int(score) : nil, zoneTicks: [40, 70],
                       grade: hasData ? (score >= 70 ? "Good" : score >= 40 ? "Fair" : "Low") : "Not enough data",
                       color: hasData ? (score >= 70 ? AppColors.success : score >= 40 ? AppColors.warning : AppColors.destructive)
                           : AppColors.textSecondary,
                       subtitle: hasData ? "You're on track" : "Add a month of income to see your score",
                       decodesScore: decodes,
                       style: style,
                       tone: tone,
                       showsMaximum: showsMaximum,
                       trend: showsTrend ? .init(direction: .up, change: "+5", caption: "since last month") : nil)
    }
}

/// A rate on the score card (4.3.0): "12.4%" on a 0–40% scale with the 10% and 20% marks.
private struct SavingsRateSample: View {
    let rate: Double
    var hasData = true
    var decodes = false
    var style: ScoreGaugeCard.Style = .card
    var tone: HeroHalfGauge.Tone = .onColor
    var showsTrend = false

    var body: some View {
        ScoreGaugeCard(value: hasData ? rate : nil, fractionDigits: 1, unit: "%", maxScore: 40, zoneTicks: [10, 20],
                       grade: hasData ? (rate >= 20 ? "On target" : rate >= 10 ? "Below target" : "Low") : "Not enough data",
                       color: hasData ? (rate >= 20 ? AppColors.success : rate >= 10 ? AppColors.warning : AppColors.destructive)
                           : AppColors.textSecondary,
                       subtitle: "Target: 20% of income",
                       decodesScore: decodes,
                       style: style,
                       tone: tone,
                       trend: showsTrend ? .init(direction: .down, change: "−1.6 pp", caption: "since last month") : nil)
    }
}

/// What the Value control shows.
private enum ScoreValueKind: Hashable {
    case score, rate, amount
}

/// An amount on the card (4.5.0): a large expense against the usual one, notched on the arc.
private struct LargeExpenseSample: View {
    let amount: Double
    var hasData = true
    var style: ScoreGaugeCard.Style = .card
    var tone: HeroHalfGauge.Tone = .onColor

    private let usual = 30_700.0

    var body: some View {
        ScoreGaugeCard(amount: hasData ? amount : nil, currency: "KZT", maxValue: max(amount, usual) * 1.15, norm: usual,
                       grade: hasData ? "\((amount / usual).formatted(.number.precision(.fractionLength(1))))× the usual" : "Not enough data",
                       color: hasData ? (amount / usual >= 8 ? AppColors.destructive : AppColors.warning) : AppColors.textSecondary,
                       subtitle: "Furniture, 3 Oct",
                       style: style,
                       tone: tone)
    }
}

/// `ScoreGaugeCard(style: .hero)` where it lives: the top of a screen under an inline navigation
/// bar, edge to edge, and glass cards that rise over the bottom of its gradient.
private struct ScoreHeroScreen: View {
    let score: Double
    let tone: HeroHalfGauge.Tone

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                ScoreGaugeSample(score: score, style: .hero, tone: tone, showsMaximum: true, showsTrend: true)
                VStack(spacing: AppSpacing.lg) {
                    TargetProgressSampleCard(title: "Savings rate", current: 0.18, target: 0.2)
                    TargetProgressSampleCard(title: "Emergency fund", current: 2.4, target: 3)
                }
                .screenPadding()
                // The cards rise over the fading end of the gradient.
                .padding(.top, -AppSpacing.xxl)
            }
            .padding(.bottom, AppSpacing.lg)
        }
        // The colour reaches the top of the screen under the bar (4.5.0).
        .heroScrollEdge()
        .navigationTitle("Financial health")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A plain glass card with a title and a bar, for the hero screen sample.
private struct TargetProgressSampleCard: View {
    let title: String
    let current: Double
    let target: Double

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(AppColors.textPrimary)
            LinearProgressBar(value: min(current / target, 1), color: AppColors.success)
            Text(verbatim: "\(current.formatted(.number.precision(.fractionLength(0...2)))) of \(target.formatted(.number.precision(.fractionLength(0...2))))")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardContentPadding()
        .cardStyle()
    }
}

private struct MetricCardPage: View {
    @State private var placement: MetricCardChartPlacement? = .trailing
    @State private var showsTrend = true
    @State private var state: SpecimenState = .content

    private let slices: [DonutSlice] = GallerySamples.slices

    var body: some View {
        ComponentPage(
            name: "MetricCard",
            summary: "A figure with its trend badge and a chart: on the trailing edge, full width under it, or none.",
            since: "1.5.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                MetricCardSkeleton(chartPlacement: placement)
            } else {
                switch placement {
                case .bottom:
                    MetricCard(title: "Spending", subtitle: "Less than last month",
                               value: .amount(280_000, currency: "KZT"),
                               trend: showsTrend ? .init(direction: .down, changePercent: -12.5, color: AppColors.success) : nil,
                               chartPlacement: .bottom) {
                        HeroBarPair(previous: 320_000, current: 280_000, color: AppColors.accent, currency: "KZT")
                    }
                case .trailing:
                    MetricCard(title: "Top category", subtitle: "Food took 42% of spending",
                               value: .amount(185_000, currency: "KZT"),
                               trend: showsTrend ? .init(direction: .up, changePercent: 12.4, color: AppColors.destructive) : nil) {
                        MiniDonut(slices: slices)
                    }
                case nil:
                    MetricCard(title: "Savings rate", subtitle: "You kept a fifth of your income",
                               value: .text("21"), unit: "%",
                               trend: showsTrend ? .init(direction: .up, changePercent: 3.2) : nil)
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Chart", selection: $placement, options: [("Trailing", .trailing), ("Bottom", .bottom), ("None", nil)])
            ToggleControl("Trend badge", isOn: $showsTrend)
        }
    }
}

private struct InsightsStatCardPage: View {
    @State private var showsChange = true
    @State private var showsFooter = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "InsightsStatCard",
            summary: "A total in the insights grid with a change badge and a footer slot.",
            apps: [.tenra],
            canvas: .fill
        ) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                if state == .loading {
                    InsightsStatCardSkeleton()
                    InsightsStatCardSkeleton()
                } else {
                    InsightsStatCard(title: "Income", amount: 640_000, currency: "KZT",
                                     color: AppColors.income, previous: showsChange ? 580_000 : nil, upIsGood: true)
                    InsightsStatCard(title: "Expenses", amount: 921_300, currency: "KZT",
                                     color: AppColors.expense, previous: showsChange ? 870_000 : nil, upIsGood: false) {
                        if showsFooter {
                            ProportionBar(ratio: 0.7, leftColor: AppColors.destructive, rightColor: AppColors.bgMuted, height: 6)
                                .padding(.top, AppSpacing.xxs)
                        }
                    }
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Change badge", isOn: $showsChange)
            ToggleControl("Footer", isOn: $showsFooter)
        }
    }
}

private struct StatTilePage: View {
    @State private var showsIcon = true
    @State private var accent = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "StatTile",
            summary: "One figure with its caption and an optional symbol: a trip's distance, a profile's count.",
            since: "0.4.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            HStack(spacing: AppSpacing.md) {
                if state == .loading {
                    StatTileSkeleton()
                    StatTileSkeleton()
                } else {
                    StatTile(title: "Distance", value: "12.4 km", systemImage: showsIcon ? "point.topleft.down.to.point.bottomright.curvepath" : nil,
                             valueColor: accent ? AppColors.accent : AppColors.textPrimary)
                    StatTile(title: "Catches", value: "7", systemImage: showsIcon ? "fish" : nil,
                             valueColor: accent ? AppColors.accent : AppColors.textPrimary)
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Icon", isOn: $showsIcon)
            ToggleControl("Accent value", isOn: $accent)
        }
    }
}

private struct StatsStripPage: View {
    @State private var count = 4
    @State private var state: SpecimenState = .content

    private let all: [StatsStrip.Item] = [
        .init(value: "42", title: "days outdoors"), .init(value: "17", title: "trips"),
        .init(value: "384", title: "km"), .init(value: "9", title: "catches"), .init(value: "5", title: "places"),
    ]

    var body: some View {
        ComponentPage(
            name: "StatsStrip",
            summary: "Counters side by side in a card; two columns at accessibility text sizes.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            if state == .loading {
                StatsStripSkeleton(count: count)
            } else {
                StatsStrip(items: Array(all.prefix(count)))
            }
        } controls: {
            StateControl(state: $state)
            StepperControl("Counters", value: $count, in: 2...5)
        }
    }
}

private struct StreakCardPage: View {
    @State private var isActive = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "StreakCard",
            summary: "A streak: a flame while it runs (grey once it stopped), what to do next, the best result.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            if state == .loading {
                StreakCardSkeleton()
            } else {
                StreakCard(systemImage: "flame.fill", isActive: isActive,
                           title: isActive ? "3 weeks in a row" : "No streak",
                           subtitle: isActive ? "Head out by Sunday to keep it" : "One trip this week starts it",
                           value: "5", valueCaption: "best")
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Running", isOn: $isActive)
        }
    }
}

private struct ProgressRingTilePage: View {
    @State private var spent = 185_000.0
    @State private var hasLimit = true
    @State private var isSelected = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ProgressRingTile",
            summary: "A category coin inside its budget ring, with the title under it.",
            since: "1.5.0",
            apps: [.tenra]
        ) {
            if state == .loading {
                ProgressRingTileSkeleton()
            } else {
                ProgressRingTile(title: "Food", systemImage: "fork.knife", color: .orange,
                                 progress: hasLimit ? LimitProgress(spent: spent, limit: 250_000) : nil,
                                 isSelected: isSelected) { isSelected.toggle() }
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Spent of 250 000", value: $spent, in: 0...400_000, step: 1_000)
            ToggleControl("Has a limit", isOn: $hasLimit)
            ToggleControl("Selected", isOn: $isSelected)
        }
    }
}

private struct ProgressRingTileGridPage: View {
    @State private var columns = 0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ProgressRingTileGrid",
            summary: "Ring tiles in a grid with each amount (and limit) under it: Tenra's categories.",
            since: "1.10.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                ProgressRingTileGridSkeleton(count: 4, columns: columns == 0 ? nil : columns)
            } else {
                ProgressRingTileGrid(items: GallerySamples.tileItems, currency: "KZT",
                                     columns: columns == 0 ? nil : columns) { _ in }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Columns", selection: $columns, options: [("Adaptive", 0), ("3", 3), ("4", 4)])
        }
    }
}

#Preview { NavigationStack { ProgressCardsScreen() } }
