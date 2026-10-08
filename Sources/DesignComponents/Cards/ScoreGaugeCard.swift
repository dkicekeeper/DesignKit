//
//  ScoreGaugeCard.swift
//  DesignKit
//
//  A score on a fixed scale as a hero: a half-circle gauge with zone ticks, the score and a
//  grade capsule inside it, a line of text below. Ported from Tenra's HealthScoreHeroCard; the
//  health score model, its grade colour and the grade-band copy stay in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "72" and "Good" inside a 0–100 gauge, "You're on track" under it. `score == nil` shows "—"
/// over an empty gauge (not enough data yet).
///
/// ```swift
/// ScoreGaugeCard(score: 72, zoneTicks: [40, 70], grade: "Good",
///                color: AppColors.success, subtitle: "You're on track")
/// ```
public struct ScoreGaugeCard: View {
    let score: Int?
    let maxScore: Double
    let zoneTicks: [Double]
    let grade: String
    let color: Color
    let subtitle: String
    let decodesScore: Bool

    /// - Parameters:
    ///   - score: `nil` when it cannot be computed: the gauge stays empty and the number reads "—".
    ///   - maxScore: The end of the scale.
    ///   - zoneTicks: Zone boundaries marked on the arc (e.g. `[40, 70]`).
    ///   - color: Tints the arc, the number and the grade capsule.
    ///   - decodesScore: The number decodes itself as it appears and when it changes
    ///     (`ScrambleText`, 2.7.0).
    public init(
        score: Int?,
        maxScore: Double = 100,
        zoneTicks: [Double] = [],
        grade: String,
        color: Color,
        subtitle: String,
        decodesScore: Bool = false
    ) {
        self.score = score
        self.maxScore = maxScore
        self.zoneTicks = zoneTicks
        self.grade = grade
        self.color = color
        self.subtitle = subtitle
        self.decodesScore = decodesScore
    }

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack(alignment: .bottom) {
                HeroHalfGauge(
                    value: score.map(Double.init) ?? 0,
                    maxValue: maxScore,
                    zoneTicks: zoneTicks,
                    color: color,
                    diameter: 220,
                    lineWidth: 16
                )

                // Score + grade sit inside the semicircle's interior.
                VStack(spacing: AppSpacing.xs) {
                    scoreText
                        .font(AppTypography.h1.bold())
                        .foregroundStyle(score != nil ? color : AppColors.Text.tertiary)
                        .materialize(delay: 0.35)

                    Text(grade)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(color)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.pale(color))
                        .clipShape(Capsule())
                        .materialize(delay: 0.45)
                }
            }

            Text(subtitle)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(AppColors.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    @ViewBuilder
    private var scoreText: some View {
        if decodesScore, let score {
            ScrambleText("\(score)")
        } else {
            Text(verbatim: score.map { "\($0)" } ?? "—")
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `ScoreGaugeCard`: the same card, the gauge's track, the score, the grade
/// capsule and the subtitle.
public struct ScoreGaugeCardSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack(alignment: .bottom) {
                HeroHalfGaugeSkeleton(diameter: 220, lineWidth: 16)
                VStack(spacing: AppSpacing.xs) {
                    SkeletonText(AppTypography.h1, width: 72)
                    // The grade's capsule: a line of its text with its padding.
                    Text(verbatim: "Grade")
                        .font(AppTypography.bodySmall)
                        .hidden()
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Skeleton.fill, in: Capsule())
                }
            }
            SkeletonText(AppTypography.bodyEmphasis, width: 180)
        }
        .frame(maxWidth: .infinity)
        .shimmer()
        .padding(AppSpacing.lg)
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
