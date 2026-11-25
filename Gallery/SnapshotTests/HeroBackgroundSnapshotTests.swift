//
//  HeroBackgroundSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  The hero pieces on colour (`.heroBackground`, 4.5.0): `HeroSection` with its trend,
//  `HeroBarPair`, `HeroSparkline`, `HeroMilestoneGauge` and `HeroProportionBar`, in white on the
//  deep gradient in dark mode and as on the page, in black, on the pale one in light mode
//  (4.5.1), each clipped to its own box (the gradient runs up and down past a hero on a
//  screen), and `ScoreGaugeCard(amount:)` as a hero, as on a screen, a long amount shrunk to
//  stay inside the arc (4.5.1); a hero on a photo (8.14.0, `.heroBackground(picture:)`), and on a
//  backdrop with a figure in front of it (8.17.0, `.heroBackground(picture:subject:)`).
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
                .onHeroColor(AppColors.Status.warning)
            )
        }

        /// A trip's hero on its photo (8.14.0, `.heroBackground(picture:)`), as a film's page in
        /// the TV app: sharp at the top, its own colours blurred and darkened under the centred
        /// text and buttons, which are white in light mode too. The photo comes from the
        /// Gallery's loader.
        @Test func heroOnPicture() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    Text(verbatim: "Camp at night")
                        .font(AppTypography.h1)
                        .foregroundStyle(AppColors.Text.primary)
                        .frame(maxWidth: .infinity, minHeight: AppSpacing.xxxl * 4, alignment: .bottom)
                    Text(verbatim: "Hike \u{00B7} 2 days")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                    DSButton("Start trip", systemImage: "play.fill", fullWidth: true) {}
                    LinearProgressBar(value: 0.68, animatesOnAppear: false)
                }
                .padding(AppSpacing.lg)
                .heroBackground(clearHeight: AppSpacing.xxxl * 3) {
                    RemotePhoto(key: "gallery-photo-3", url: URL(string: "https://gallery.invalid/photo/3.jpg"))
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            )
        }

        /// A hero on a backdrop with a cut-out figure in front of it (8.17.0,
        /// `.heroBackground(picture:subject:)`): the figure as wide as the hero, sharp at the top,
        /// blurred and darkened with the backdrop under the text.
        @Test func heroOnPictureWithSubject() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    Text(verbatim: "Camp at night")
                        .font(AppTypography.h1)
                        .foregroundStyle(AppColors.Text.primary)
                        .frame(maxWidth: .infinity, minHeight: AppSpacing.xxxl * 4, alignment: .bottom)
                    Text(verbatim: "Hike \u{00B7} 2 days")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                    DSButton("Start trip", systemImage: "play.fill", fullWidth: true) {}
                    LinearProgressBar(value: 0.68, animatesOnAppear: false)
                }
                .padding(AppSpacing.lg)
                .heroBackground(clearHeight: AppSpacing.xxxl * 3) {
                    RemotePhoto(key: "gallery-backdrop-3", url: URL(string: "https://gallery.invalid/photo/3.jpg"))
                } subject: {
                    RemotePhoto(key: "gallery-figure", url: URL(string: "https://gallery.invalid/figure.png"))
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            )
        }

        /// The hero charts on colour, one per snapshot.
        @Test func heroChartsOnColor() async {
            await assertComponentSnapshot(
                HeroBarPair(previous: 252_000, current: 284_000, color: AppColors.Status.warning, currency: "KZT",
                            animatesOnAppear: false)
                    .onHeroColor(AppColors.Status.warning),
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
                    .onHeroColor(AppColors.Status.positive),
                named: "proportion"
            )
        }

        /// An amount on the hero (4.5.0): a large expense against the usual one, notched on the arc.
        @Test func scoreGaugeHeroAmount() async {
            await assertComponentSnapshot(
                ScoreGaugeCard(amount: 84_900, currency: "KZT", maxValue: 84_900 * 1.15, norm: 6_100,
                               grade: "13.9× the usual", color: AppColors.Status.negative,
                               subtitle: "Furniture, 3 Oct", style: .hero)
            )
        }

        /// A long amount on the hero (4.5.1): it shrinks to the room inside the arc instead of
        /// running onto it.
        @Test func scoreGaugeHeroLongAmount() async {
            await assertComponentSnapshot(
                ScoreGaugeCard(amount: 1_200_000, currency: "KZT", maxValue: 1_200_000 * 1.15, norm: 30_700,
                               grade: "39.1× the usual", color: AppColors.Status.warning,
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
        DonutSlice(id: "salary", amount: 620_000, color: AppColors.Status.positive, label: "Salary", percentage: 75),
        DonutSlice(id: "freelance", amount: 180_000, color: AppColors.accent, label: "Freelance", percentage: 22),
        DonutSlice(id: "cashback", amount: 24_000, color: AppColors.Status.warning, label: "Cashback", percentage: 3),
    ]
}
