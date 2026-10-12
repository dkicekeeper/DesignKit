//
//  RatingSummary.swift
//  DesignKit
//
//  How an item is rated, at a glance (4.1.0, benchmark round 3): the average in large digits,
//  its stars and how many reviews, and a bar per star from the top down, in a glass card
//  (the App Store's and Google Play's ratings block). Dalada's place reviews drew it as
//  `ReviewSummaryView`; loading the reviews stays in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// The average rating, its stars, the review count and how the reviews spread over the stars.
///
/// ```swift
/// RatingSummary(average: summary.ratingAverage, count: summary.reviewsCount,
///               distribution: summary.stars,
///               countLabel: String(localized: "reviews.count \(summary.reviewsCount)"))
/// ```
///
/// Each bar is the share of the reviews that gave that many stars, in the warning colour of
/// `Rating`. VoiceOver reads each bar as `rating.bar` ("Rating 5: 12 reviews").
public struct RatingSummary: View {
    let average: Double?
    let count: Int
    let distribution: [Int]
    let countLabel: String
    let animatesOnAppear: Bool

    /// - Parameters:
    ///   - average: The mean rating; nil (no reviews yet) shows 0.0 and empty stars.
    ///   - count: How many reviews; each bar is its star's count over this.
    ///   - distribution: How many reviews gave 1, 2, … stars (one star first). Its length is
    ///     the scale (5 by default).
    ///   - countLabel: The line under the stars ("12 reviews"), so the app keeps its plurals.
    ///   - animatesOnAppear: The bars fill when the card appears.
    public init(average: Double?, count: Int, distribution: [Int], countLabel: String, animatesOnAppear: Bool = true) {
        self.average = average
        self.count = count
        self.distribution = distribution.isEmpty ? Array(repeating: 0, count: 5) : distribution
        self.countLabel = countLabel
        self.animatesOnAppear = animatesOnAppear
    }

    private var maximum: Int { distribution.count }

    private func share(of star: Int) -> Double {
        guard count > 0 else { return 0 }
        return Double(distribution[star - 1]) / Double(count)
    }

    public var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.xxs) {
                Text(verbatim: (average ?? 0).formatted(.number.precision(.fractionLength(1))))
                    .font(AppTypography.h2)
                    .monospacedDigit()
                Rating(rating: average ?? 0, maximum: maximum, size: 12)
                Text(verbatim: countLabel)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
            VStack(spacing: AppSpacing.xxs) {
                ForEach((1...maximum).reversed(), id: \.self) { star in
                    HStack(spacing: AppSpacing.xs) {
                        Text(verbatim: "\(star)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.Text.secondary)
                            .frame(width: AppIconSize.xs)
                        LinearProgressBar(value: share(of: star), color: AppColors.warning, height: 6,
                                          animatesOnAppear: animatesOnAppear)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(String(localized: "rating.bar",
                                                     defaultValue: "Rating \(star): \(distribution[star - 1]) reviews")))
                }
            }
        }
        .cardContentPadding()
        .cardStyle()
    }
}

// MARK: - Skeleton

/// Placeholder of a `RatingSummary`: the average, the stars and the count line on the left,
/// a grey bar per star on the right, in the same glass card.
public struct RatingSummarySkeleton: View {
    let maximum: Int

    public init(maximum: Int = 5) {
        self.maximum = max(1, maximum)
    }

    public var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.xxs) {
                SkeletonText(AppTypography.h2, width: 52)
                HStack(spacing: 2) {
                    ForEach(0..<maximum, id: \.self) { _ in
                        Skeleton(height: 12, width: 12)
                    }
                }
                SkeletonText(AppTypography.caption, width: 64)
            }
            VStack(spacing: AppSpacing.xxs) {
                ForEach(0..<maximum, id: \.self) { _ in
                    HStack(spacing: AppSpacing.xs) {
                        SkeletonText(AppTypography.caption, width: AppIconSize.xs)
                        Skeleton(height: 6)
                    }
                }
            }
        }
        .shimmer()
        .cardContentPadding()
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
