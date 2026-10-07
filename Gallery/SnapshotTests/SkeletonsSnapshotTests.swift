//
//  SkeletonsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  The skeleton of every component that shows data (1.10.0). The renderer stops the shimmer
//  (`.skeletonShimmer(false)`), so a skeleton is a still picture. Every card skeleton has
//  its own snapshot: glass reflects a card next to it.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Skeletons")
    struct Skeletons {
        @Test func shapes() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Skeleton(height: 48)
                    SkeletonText(AppTypography.h3, width: 160)
                    SkeletonText(AppTypography.body, lines: 2)
                    HStack(spacing: AppSpacing.md) {
                        Skeleton.circle(AppIconSize.Tile.sm)
                        IconSkeleton(style: .roundedSquare(size: AppIconSize.Tile.sm))
                        Skeleton.capsule(height: 32, width: 96)
                    }
                    SkeletonRow()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }

        @Test func cardSkeletons() async {
            let cards: [(String, AnyView)] = [
                ("finance", AnyView(FinanceCardSkeleton())),
                ("balance", AnyView(BalanceCardSkeleton())),
                ("selectableBalance", AnyView(SelectableBalanceCardSkeleton())),
                ("cashFlow", AnyView(CashFlowCardSkeleton())),
                ("insightsStat", AnyView(InsightsStatCardSkeleton())),
                ("recurringPayment", AnyView(RecurringPaymentCardSkeleton())),
                ("limitProgress", AnyView(LimitProgressCardSkeleton())),
                ("targetProgress", AnyView(TargetProgressCardSkeleton())),
                ("payoffProgress", AnyView(PayoffProgressCardSkeleton())),
                ("score", AnyView(ScoreCardSkeleton())),
                ("scoreGauge", AnyView(ScoreGaugeCardSkeleton())),
                ("metricTrailing", AnyView(MetricCardSkeleton())),
                ("metricBottom", AnyView(MetricCardSkeleton(chartPlacement: .bottom))),
                ("weightBreakdown", AnyView(WeightBreakdownCardSkeleton())),
                ("calculation", AnyView(CalculationCardSkeleton())),
                ("dateSectionHeader", AnyView(SectionHeaderSkeleton(style: .card, showsTrailing: true))),
                ("monthCalendar", AnyView(MonthCalendarSkeleton())),
            ]
            for (name, card) in cards {
                await assertComponentSnapshot(card, named: name, appearances: [.light])
            }
        }

        /// The community and progress components (1.12.0): each card on its own, the rows together.
        @Test func communityCardSkeletons() async {
            let cards: [(String, AnyView)] = [
                ("thread", AnyView(ThreadCardSkeleton())),
                ("review", AnyView(ReviewCardSkeleton())),
                ("statsStrip", AnyView(StatsStripSkeleton())),
                ("streak", AnyView(StreakCardSkeleton())),
            ]
            for (name, card) in cards {
                await assertComponentSnapshot(card, named: name, appearances: [.light])
            }
        }

        @Test func communityRowSkeletons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    PersonRowSkeleton()
                    CommentRowSkeleton()
                    AchievementProgressRowSkeleton()
                    ChecklistRowSkeleton()
                    ChecklistSummaryRowSkeleton()
                    ThumbnailRowSkeleton()
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        ThumbnailCardSkeleton(width: 160)
                        AchievementTileSkeleton(medalSize: 64)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark]
            )
        }

        /// Cards that stack at accessibility text sizes, like their components.
        @Test func stackingCardSkeletons() async {
            await assertComponentSnapshot(
                TotalsCardSkeleton(count: 2, showsTitle: true),
                named: "totals",
                appearances: [.light, .dark, .largeText]
            )
            await assertComponentSnapshot(
                ComparisonCardSkeleton(),
                named: "comparison",
                appearances: [.light, .largeText]
            )
        }

        // Rows and gauges come in two snapshots each: one would be taller than the screen.
        @Test func settingsRowSkeletons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    UniversalRowSkeleton(showsSubtitle: true, trailing: .value)
                    UniversalRowSkeleton.navigationSettings
                    UniversalRowSkeleton.toggleSettings
                    UniversalRowSkeleton.datePicker
                    UniversalRowSkeleton.checkmark(iconStyle: .roundedSquare(size: AppIconSize.xl))
                    ColorPickerRowSkeleton(swatches: 5)
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func dataRowSkeletons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    AmountRowSkeleton(style: .list, showsDetail: true)
                    AmountRowSkeleton(style: .list, showsRing: true)
                    AmountRowSkeleton(style: .info)
                    AmountRowSkeleton(style: .info)
                    NetAmountRowSkeleton()
                    ScheduleRowSkeleton()
                    InfoRowSkeleton(showsIcon: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func chartSkeletons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ChartSwitcherSkeleton(style: .bar)
                    SparklineSkeleton()
                    OrbChartSkeleton(size: 160)
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light]
            )
        }

        @Test func barSkeletons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    LinearProgressBarSkeleton()
                    ProportionBarSkeleton(height: 12)
                    AmountComparisonBarSkeleton()
                    HeroProportionBarSkeleton(segments: 2)
                    HeroMilestoneGaugeSkeleton()
                    HeroBarPairSkeleton(maxBarHeight: 100)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark]
            )
        }

        @Test func gaugeSkeletons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    HeroHalfGaugeSkeleton(diameter: 200, lineWidth: 16)
                    HStack(spacing: AppSpacing.md) {
                        MiniHalfGaugeSkeleton().frame(width: 100)
                        MiniMilestoneGaugeSkeleton().frame(width: 100)
                        MiniBarPairSkeleton().frame(width: 80)
                    }
                    HStack(spacing: AppSpacing.md) {
                        MiniProportionBarSkeleton().frame(width: 100)
                        MiniDonutSkeleton().frame(width: 60, height: 60)
                        ProgressRingSkeleton()
                        ProgressRingTileSkeleton()
                    }
                    ProgressRingTileGridSkeleton(count: 3)
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark]
            )
        }

        @Test func smallSkeletons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.md) {
                        BadgeSkeleton()
                        TrendBadgeSkeleton()
                        TrendBadgeSkeleton(style: .inline)
                        StatusIndicatorBadgeSkeleton(font: AppTypography.h4)
                    }
                    StatusBannerSkeleton()
                    StatusBannerSkeleton(style: .compact)
                    RecommendationBoxSkeleton()
                    HStack(spacing: AppSpacing.lg) {
                        AvatarSkeleton()
                        AvatarGroupSkeleton()
                        HeroSymbolSkeleton(size: 64)
                        StatTileSkeleton()
                    }
                    HStack(spacing: AppSpacing.lg) {
                        PackedCircleIconsSkeleton()
                        RatingSkeleton(size: 20)
                    }
                    ChipPickerSkeleton(count: 3)
                    FormattedAmountTextSkeleton(font: AppTypography.h1, width: 200)
                    RedactableAmount(amount: 0, currency: "KZT", isLoading: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func headerSkeletons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    HeroSectionSkeleton(showsProgress: true)
                    SectionHeaderSkeleton()
                    SectionHeaderSkeleton(style: .large)
                    ExpandableTextSkeleton()
                    ActivityTimelineSkeleton()
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light]
            )
        }

        @Test func trendChartSkeletons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    LineChartSkeleton()
                    HeroSparklineSkeleton()
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark]
            )
        }

        @Test func headerAndSliderSkeletons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    SectionHeaderSkeleton(showsTrailing: true)
                    SectionHeaderSkeleton(style: .large, showsTrailing: true)
                    SliderRowSkeleton(showsHint: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark]
            )
        }
    }
}
