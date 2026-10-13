//
//  HeroBackgroundSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  The hero pieces on colour (`.heroBackground`, 4.5.0): `HeroSection` with its trend,
//  `HeroBarPair`, `HeroSparkline`, `HeroMilestoneGauge` and `HeroProportionBar`, in white on the
//  deep gradient in dark mode and as on the page, in black, on the pale one in light mode
//  (4.5.1), each clipped to its own box (the gradient runs up and down past a hero on a
//  screen), and `ScoreGaugeCard(amount:)` as a hero, as on a screen, a long amount shrunk to
//  stay inside the arc (4.5.1).
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Hero background")
    struct HeroBackground {
        /// The header of an insight on its colour: title, amount, trend and subtitle in white.
        @Test func heroSectionOnColor() async {
            await assertComponentSnapshot(
                HeroSection(icon: nil, title: "Spending", showsIcon: false, primaryAmount: 284_000,
                            primaryCurrency: "KZT", subtitle: "September against August") {
                    TrendBadge(direction: .up, changePercent: 12.4)
                }
                .onHeroColor(AppColors.warning)
            )
        }

        /// The hero charts on colour, one per snapshot.
        @Test func heroChartsOnColor() async {
            await assertComponentSnapshot(
                HeroBarPair(previous: 252_000, current: 284_000, color: AppColors.warning, currency: "KZT",
                            animatesOnAppear: false)
                    .onHeroColor(AppColors.warning),
                named: "barPair"
            )
            await assertComponentSnapshot(
                HeroSparkline(dataPoints: HeroSamples.months, series: HeroSamples.series, projectedValue: 64,
                              markExtremes: true)
                    .onHeroColor(AppColors.accent),
                named: "sparkline"
            )
            await assertComponentSnapshot(
                HeroMilestoneGauge(value: 4.2, target: 6, maxValue: 12, color: AppColors.accent,
                                   animatesOnAppear: false)
                    .onHeroColor(AppColors.accent),
                named: "milestone"
            )
            await assertComponentSnapshot(
                HeroProportionBar(segments: HeroSamples.slices, currency: "KZT")
                    .onHeroColor(AppColors.success),
                named: "proportion"
            )
        }

        /// An amount on the hero (4.5.0): a large expense against the usual one, notched on the arc.
        @Test func scoreGaugeHeroAmount() async {
            await assertComponentSnapshot(
                ScoreGaugeCard(amount: 84_900, currency: "KZT", maxValue: 84_900 * 1.15, norm: 6_100,
                               grade: "13.9× the usual", color: AppColors.destructive,
                               subtitle: "Furniture, 3 Oct", style: .hero)
            )
        }

        /// A long amount on the hero (4.5.1): it shrinks to the room inside the arc instead of
        /// running onto it.
        @Test func scoreGaugeHeroLongAmount() async {
            await assertComponentSnapshot(
                ScoreGaugeCard(amount: 1_200_000, currency: "KZT", maxValue: 1_200_000 * 1.15, norm: 30_700,
                               grade: "39.1× the usual", color: AppColors.warning,
                               subtitle: "Furniture, 29 Sep", style: .hero)
            )
        }
    }
}

private extension View {
    /// On a hero's colour, clipped to the piece's own box.
    func onHeroColor(_ color: Color) -> some View {
        frame(maxWidth: .infinity)
            .padding(AppSpacing.lg)
            .heroBackground(color)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    }
}

/// Fixed data for the hero charts.
private enum HeroSamples {
    private static let km: [Double] = [32, 41, 38, 52, 47, 58, 44, 55]

    static let months: [ChartValuePoint] = ["Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep"]
        .enumerated()
        .map { index, label in ChartValuePoint(label: label, values: ["km": km[index]]) }

    static let series = ChartSeries<ChartValuePoint>.keyed("km", name: "Distance", coloring: .solid(AppColors.accent))

    static let slices: [DonutSlice] = [
        DonutSlice(id: "salary", amount: 620_000, color: AppColors.success, label: "Salary", percentage: 75),
        DonutSlice(id: "freelance", amount: 180_000, color: AppColors.accent, label: "Freelance", percentage: 22),
        DonutSlice(id: "cashback", amount: 24_000, color: AppColors.warning, label: "Cashback", percentage: 3),
    ]
}
