//
//  SkeletonsScreen.swift
//  DesignKit Gallery
//
//  The skeleton of every component that shows data (1.10.0): each keeps its component's
//  container and corner, grey shapes stand in for its text, amounts, icons and charts, and
//  a shape with no corner of its own takes the soft corner (AppRadius.soft).
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct SkeletonsScreen: View {
    @State private var shimmers = true

    var body: some View {
        ShowcasePage(title: "Skeletons") {
            shapesSection
            cardsSection
            progressCardsSection
            rowsSection
            chartsSection
            barsSection
            smallSection
            headersSection
            communitySection
        }
        .skeletonShimmer(shimmers)
    }

    /// The component's name over its skeleton.
    private func specimen<Content: View>(_ name: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            TokenLabel(name: name)
            content()
        }
    }

    // MARK: Shapes

    @ViewBuilder
    private var shapesSection: some View {
        ShowcaseSection(title: "Skeleton shapes", subtitle: "AppRadius.soft · circle · capsule · one shimmer") {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Toggle("Shimmer", isOn: $shimmers)
                    .font(AppTypography.body)
                specimen("SkeletonView · soft corner") {
                    SkeletonView(height: 64)
                }
                specimen("SkeletonText · h3, body × 3") {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SkeletonText(AppTypography.h3, width: 160)
                        SkeletonText(AppTypography.body, lines: 3)
                    }
                }
                specimen("SkeletonView.circle · .capsule") {
                    HStack(spacing: AppSpacing.md) {
                        SkeletonView.circle(AppIconSize.xxl)
                        SkeletonView.capsule(height: 32, width: 96)
                    }
                }
                specimen("IconViewSkeleton · circle, rounded square") {
                    HStack(spacing: AppSpacing.md) {
                        IconViewSkeleton(size: AppIconSize.xxl)
                        IconViewSkeleton(style: .roundedSquare(size: AppIconSize.xxl))
                    }
                }
                specimen("SkeletonRow") {
                    SkeletonRow()
                }
            }
        }
    }

    // MARK: Cards

    @ViewBuilder
    private var cardsSection: some View {
        ShowcaseSection(title: "Card skeletons", subtitle: "The card's glass and corner, grey content") {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                specimen("FinanceCardSkeleton") { FinanceCardSkeleton() }
                specimen("BalanceCardSkeleton") { BalanceCardSkeleton() }
                specimen("SelectableBalanceCardSkeleton") { SelectableBalanceCardSkeleton() }
                specimen("CashFlowCardSkeleton") { CashFlowCardSkeleton() }
                specimen("TotalsCardSkeleton") { TotalsCardSkeleton(count: 3, showsTitle: true) }
                specimen("ComparisonCardSkeleton") { ComparisonCardSkeleton() }
                specimen("InsightsStatCardSkeleton · StatTileSkeleton") {
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        InsightsStatCardSkeleton()
                        StatTileSkeleton()
                    }
                }
                specimen("RecurringPaymentCardSkeleton") { RecurringPaymentCardSkeleton() }
                specimen("RecommendationBoxSkeleton") { RecommendationBoxSkeleton() }
            }
        }
    }

    @ViewBuilder
    private var progressCardsSection: some View {
        ShowcaseSection(title: "Progress and score skeletons", subtitle: "Tracks keep their own corners") {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                specimen("LimitProgressCardSkeleton") { LimitProgressCardSkeleton() }
                specimen("TargetProgressCardSkeleton") { TargetProgressCardSkeleton() }
                specimen("PayoffProgressCardSkeleton") { PayoffProgressCardSkeleton() }
                specimen("ScoreCardSkeleton") { ScoreCardSkeleton() }
                specimen("ScoreGaugeCardSkeleton") { ScoreGaugeCardSkeleton() }
                specimen("MetricCardSkeleton · trailing, bottom") {
                    VStack(spacing: AppSpacing.md) {
                        MetricCardSkeleton()
                        MetricCardSkeleton(chartPlacement: .bottom)
                    }
                }
                specimen("WeightBreakdownCardSkeleton") { WeightBreakdownCardSkeleton() }
                specimen("CalculationCardSkeleton") { CalculationCardSkeleton() }
                specimen("ProgressRingTileGridSkeleton") { ProgressRingTileGridSkeleton(count: 4) }
                specimen("ProgressRingTileSkeleton") {
                    HStack(spacing: AppSpacing.lg) {
                        ProgressRingTileSkeleton()
                        ProgressRingTileSkeleton()
                        ProgressRingTileSkeleton()
                    }
                }
            }
        }
    }

    // MARK: Rows

    @ViewBuilder
    private var rowsSection: some View {
        ShowcaseSection(title: "Row skeletons", subtitle: "The row's padding, the icon's shape") {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                specimen("UniversalRowSkeleton · value, subtitle") {
                    UniversalRowSkeleton(showsSubtitle: true, trailing: .value)
                }
                specimen("navigationSettings · toggleSettings · actionSettings") {
                    VStack(spacing: 0) {
                        UniversalRowSkeleton.navigationSettings
                        UniversalRowSkeleton.toggleSettings
                        UniversalRowSkeleton.actionSettings
                    }
                }
                specimen("UniversalRowSkeleton.checkmark · CheckmarkRow") {
                    UniversalRowSkeleton.checkmark(iconStyle: .roundedSquare(size: AppIconSize.xl))
                }
                specimen("menuPicker · datePicker") {
                    VStack(spacing: 0) {
                        UniversalRowSkeleton.menuPicker
                        UniversalRowSkeleton.datePicker
                    }
                }
                specimen("BalanceRowSkeleton") { BalanceRowSkeleton(showsDetail: true) }
                specimen("ProgressRingRowSkeleton") { ProgressRingRowSkeleton() }
                specimen("BreakdownRowSkeleton") { BreakdownRowSkeleton() }
                specimen("InsightEntityRowSkeleton") { InsightEntityRowSkeleton() }
                specimen("NetAmountRowSkeleton") { NetAmountRowSkeleton() }
                specimen("ScheduleRowSkeleton") { ScheduleRowSkeleton() }
                specimen("InfoRowSkeleton") { InfoRowSkeleton(showsIcon: true) }
                specimen("ColorPickerRowSkeleton") { ColorPickerRowSkeleton() }
            }
        }
    }

    // MARK: Charts

    @ViewBuilder
    private var chartsSection: some View {
        ShowcaseSection(title: "Chart skeletons", subtitle: "Plot areas with the soft corner") {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                specimen("ChartSwitcherSkeleton") { ChartSwitcherSkeleton() }
                specimen("BarChartSkeleton") { BarChartSkeleton() }
                specimen("HeroSparklineSkeleton") { HeroSparklineSkeleton() }
                specimen("SparklineSkeleton") { SparklineSkeleton() }
                specimen("OrbChartSkeleton") { OrbChartSkeleton(size: 200) }
                specimen("LineChartSkeleton") { LineChartSkeleton() }
            }
        }
    }

    @ViewBuilder
    private var barsSection: some View {
        ShowcaseSection(title: "Gauge and bar skeletons", subtitle: "The track of each, its caps and corners") {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                specimen("LinearProgressBarSkeleton") { LinearProgressBarSkeleton() }
                specimen("ProportionBarSkeleton") { ProportionBarSkeleton(height: 12) }
                specimen("AmountComparisonBarSkeleton") { AmountComparisonBarSkeleton() }
                specimen("HeroProportionBarSkeleton") { HeroProportionBarSkeleton(segments: 3) }
                specimen("HeroHalfGaugeSkeleton") { HeroHalfGaugeSkeleton(diameter: 200, lineWidth: 16) }
                specimen("HeroMilestoneGaugeSkeleton") { HeroMilestoneGaugeSkeleton() }
                specimen("HeroBarPairSkeleton") {
                    HeroBarPairSkeleton(maxBarHeight: 120)
                        .frame(maxWidth: .infinity)
                }
                specimen("Mini charts: half gauge, milestones, bar pair, proportion, donut, ring") {
                    HStack(spacing: AppSpacing.md) {
                        MiniHalfGaugeSkeleton().frame(width: 100)
                        MiniMilestoneGaugeSkeleton().frame(width: 100)
                        MiniBarPairSkeleton().frame(width: 80)
                    }
                    HStack(spacing: AppSpacing.md) {
                        MiniProportionBarSkeleton().frame(width: 100)
                        MiniDonutSkeleton().frame(width: 60, height: 60)
                        ProgressRingSkeleton()
                    }
                }
            }
        }
    }

    // MARK: Small pieces

    @ViewBuilder
    private var smallSection: some View {
        ShowcaseSection(title: "Badge, icon and amount skeletons", subtitle: "Capsules stay capsules, circles stay circles") {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                specimen("BadgeViewSkeleton · TrendBadgeSkeleton · StatusIndicatorBadgeSkeleton") {
                    HStack(spacing: AppSpacing.md) {
                        BadgeViewSkeleton()
                        TrendBadgeSkeleton()
                        TrendBadgeSkeleton(style: .inline)
                        StatusIndicatorBadgeSkeleton(font: AppTypography.h4)
                    }
                }
                specimen("StatusBannerSkeleton · standard, compact") {
                    VStack(spacing: AppSpacing.sm) {
                        StatusBannerSkeleton()
                        StatusBannerSkeleton(style: .compact)
                    }
                }
                specimen("AvatarViewSkeleton · AvatarGroupSkeleton · HeroSymbolSkeleton") {
                    HStack(spacing: AppSpacing.lg) {
                        AvatarViewSkeleton()
                        AvatarGroupSkeleton()
                        HeroSymbolSkeleton(size: 64)
                    }
                }
                specimen("PackedCircleIconsViewSkeleton") { PackedCircleIconsViewSkeleton() }
                specimen("RatingViewSkeleton") { RatingViewSkeleton(size: 20) }
                specimen("ChipPickerSkeleton") { ChipPickerSkeleton() }
                specimen("FormattedAmountTextSkeleton · h1, body") {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        FormattedAmountTextSkeleton(font: AppTypography.h1, width: 200)
                        FormattedAmountTextSkeleton()
                    }
                }
                specimen("RedactableAmount · loading") {
                    RedactableAmount(amount: 0, currency: "KZT", isLoading: true)
                }
            }
        }
    }

    // MARK: Headers and display

    @ViewBuilder
    private var headersSection: some View {
        ShowcaseSection(title: "Header and display skeletons", subtitle: "Heroes, headers, timeline, calendar") {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                specimen("HeroSectionSkeleton") { HeroSectionSkeleton(showsProgress: true) }
                specimen("SectionHeaderViewSkeleton · default, compact, large") {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SectionHeaderViewSkeleton()
                        SectionHeaderViewSkeleton(style: .compact)
                        SectionHeaderViewSkeleton(style: .large)
                    }
                }
                specimen("DateSectionHeaderViewSkeleton") { DateSectionHeaderViewSkeleton() }
                specimen("ExpandableTextSkeleton") { ExpandableTextSkeleton() }
                specimen("ActivityTimelineSkeleton") { ActivityTimelineSkeleton() }
                specimen("MonthCalendarSkeleton") { MonthCalendarSkeleton() }
            }
        }
    }

    // MARK: Community & progress

    private var communitySection: some View {
        ShowcaseSection(title: "Community and progress skeletons", subtitle: "People, comments, reviews, achievements, checklists") {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                specimen("PersonRowSkeleton") { PersonRowSkeleton() }
                specimen("CommentRowSkeleton") { CommentRowSkeleton() }
                specimen("ThreadCardSkeleton") { ThreadCardSkeleton() }
                specimen("ReviewCardSkeleton") { ReviewCardSkeleton() }
                specimen("AchievementTileSkeleton · AchievementMedalSkeleton") {
                    HStack(spacing: AppSpacing.md) {
                        AchievementTileSkeleton(medalSize: 64)
                        AchievementTileSkeleton(medalSize: 64)
                        AchievementMedalSkeleton(size: 40)
                    }
                }
                specimen("AchievementProgressRowSkeleton") { AchievementProgressRowSkeleton() }
                specimen("ChecklistRowSkeleton") { ChecklistRowSkeleton() }
                specimen("ChecklistSummaryRowSkeleton") { ChecklistSummaryRowSkeleton() }
                specimen("StatsStripSkeleton") { StatsStripSkeleton() }
                specimen("StreakCardSkeleton") { StreakCardSkeleton() }
                specimen("ThumbnailCardSkeleton") { ThumbnailCardSkeleton() }
                specimen("ThumbnailRowSkeleton") { ThumbnailRowSkeleton() }
            }
        }
    }
}

#Preview { NavigationStack { SkeletonsScreen() } }
