//
//  ScoreCard.swift
//  DesignKit
//
//  A score as a feed card: title, grade and "72 / 100" on the left, a mini half-gauge on the
//  trailing edge. Ported from Tenra's HealthScoreCardView; the health score model and its
//  grade colour stay in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "Health score / Good / 72 / 100" with a 120 pt half-gauge on the right.
///
/// ```swift
/// ScoreCard(title: "Health score", grade: "Good", score: 72, color: AppColors.success)
/// ```
public struct ScoreCard: View {
    let title: String
    let grade: String
    let score: Int
    let maxScore: Int
    let color: Color

    // Mini-chart footprint, the same as the insight feed cards'.
    static var miniChartWidth: CGFloat { 120 }
    static var miniChartHeight: CGFloat { 120 }

    /// - Parameters:
    ///   - color: Tints the score and the gauge arc.
    public init(title: String, grade: String, score: Int, maxScore: Int = 100, color: Color) {
        self.title = title
        self.grade = grade
        self.score = score
        self.maxScore = maxScore
        self.color = color
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)

            Text(grade)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)

            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                Text(verbatim: "\(score)")
                    .font(AppTypography.h2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)

                Text(verbatim: "/ \(maxScore)")
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, Self.miniChartWidth + AppSpacing.sm)
        .padding(AppSpacing.lg)
        .cardStyle()
        .overlay(alignment: .trailing) {
            MiniHalfGauge(
                value: Double(score),
                maxValue: Double(maxScore),
                color: color
            )
            .frame(width: Self.miniChartWidth, height: Self.miniChartHeight)
            .padding(.trailing, AppSpacing.lg)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `ScoreCard`: the same card, its three lines and the mini gauge's track.
public struct ScoreCardSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SkeletonText(AppTypography.body, width: 110)
            SkeletonText(AppTypography.bodyEmphasis, width: 140)
            SkeletonText(AppTypography.h2, width: 90)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, ScoreCard.miniChartWidth + AppSpacing.sm)
        .shimmer()
        .padding(AppSpacing.lg)
        .cardStyle()
        .overlay(alignment: .trailing) {
            MiniHalfGaugeSkeleton()
                .frame(width: ScoreCard.miniChartWidth, height: ScoreCard.miniChartHeight)
                .padding(.trailing, AppSpacing.lg)
        }
        .skeletonLoadingLabel()
    }
}
