//
//  ReviewCard.swift
//  DesignKit
//
//  A review: author, stars, how long ago, a menu slot, a line under it (when they were
//  there), the text folded to four lines, the photos, and a row of actions ("Helpful",
//  comments, "edited"). Ported from Dalada's ReviewRow; the photo loading, the moderation menu
//  and the reactions stay in the app, in the slots.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A review card.
///
/// ```swift
/// ReviewCard(author: "Aida", rating: 4, date: review.createdAt,
///            subtitle: "Visited in May 2026", text: review.body) {
///     ModerationMenu(…)
/// } media: {
///     PhotoStrip(review.media)
/// } actions: {
///     ReactionButton(…)
/// }
/// ```
///
/// A card: pads itself and draws its own glass.
public struct ReviewCard<Trailing: View, Media: View, Actions: View>: View {
    let author: String
    let rating: Double
    let date: Date
    let subtitle: String?
    let text: String?
    let menu: Trailing
    let media: Media
    let actions: Actions

    /// - Parameters:
    ///   - author: The author's name ("You" for one's own).
    ///   - rating: Stars out of five.
    ///   - subtitle: A caption line under the author (when the place was visited).
    ///   - text: Folded to four lines with "More" (`ExpandableText`).
    ///   - menu: After the time (report, block).
    ///   - media: Under the text (photos).
    ///   - actions: The last row, `AppSpacing.md` apart.
    public init(
        author: String,
        rating: Double,
        date: Date,
        subtitle: String? = nil,
        text: String? = nil,
        @ViewBuilder menu: () -> Trailing = { EmptyView() },
        @ViewBuilder media: () -> Media = { EmptyView() },
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) {
        self.author = author
        self.rating = rating
        self.date = date
        self.subtitle = subtitle
        self.text = text
        self.menu = menu()
        self.media = media()
        self.actions = actions()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Text(verbatim: author)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(1)
                RatingView(rating: rating, size: ReviewCardMetrics.starSize)
                Spacer(minLength: 0)
                Text(verbatim: date.formatted(.relative(presentation: .named)))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.tertiary)
                    .lineLimit(1)
                menu
            }
            if let subtitle {
                Text(verbatim: subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
            if let text, !text.isEmpty {
                ExpandableText(text, lineLimit: 4, font: AppTypography.bodySmall)
            }
            media
            if Actions.self != EmptyView.self {
                HStack(spacing: AppSpacing.md) {
                    actions
                    Spacer(minLength: 0)
                }
            }
        }
        .cardContentPadding()
        .cardStyle()
    }
}

/// The review's star size, shared with its skeleton.
enum ReviewCardMetrics {
    static let starSize: CGFloat = 12
}

// MARK: - Skeleton

/// Placeholder of a `ReviewCard`: the same glass card with the author, the stars, the time and
/// three lines of text.
public struct ReviewCardSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                SkeletonText(AppTypography.bodyEmphasis, width: 90)
                RatingViewSkeleton(size: ReviewCardMetrics.starSize)
                Spacer(minLength: 0)
                SkeletonText(AppTypography.caption, width: 48)
            }
            SkeletonText(AppTypography.bodySmall, lines: 3)
        }
        .shimmer()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardContentPadding()
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
