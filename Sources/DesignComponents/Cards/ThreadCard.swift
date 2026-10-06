//
//  ThreadCard.swift
//  DesignKit
//
//  A discussion in a list: its title, the start of its text, and a footer with the number of
//  replies, who started it and when it was last active. Ported from Dalada's ThreadRow; the
//  thread model stays in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A discussion card.
///
/// ```swift
/// ThreadCard(title: thread.title, preview: thread.bodyPreview, repliesCount: thread.postsCount,
///            author: thread.author.label, lastActivity: thread.lastActivityAt)
/// ```
///
/// A card: pads itself and draws its own glass.
public struct ThreadCard: View {
    let title: String
    let preview: String?
    let repliesCount: Int
    let author: String
    let lastActivity: Date

    /// - Parameters:
    ///   - preview: Up to two lines under the title; none when empty.
    ///   - lastActivity: Shown as "5 minutes ago" on the right of the footer.
    public init(title: String, preview: String? = nil, repliesCount: Int, author: String, lastActivity: Date) {
        self.title = title
        self.preview = preview
        self.repliesCount = repliesCount
        self.author = author
        self.lastActivity = lastActivity
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(verbatim: title)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
            if let preview, !preview.isEmpty {
                Text(verbatim: preview)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }
            HStack(spacing: AppSpacing.sm) {
                Label {
                    Text(verbatim: "\(repliesCount)")
                } icon: {
                    Image(systemName: "bubble.left")
                }
                Text(verbatim: author)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(verbatim: lastActivity.formatted(.relative(presentation: .named)))
                    .lineLimit(1)
            }
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardContentPadding()
        .cardStyle()
        .contentShape(Rectangle())
    }
}

// MARK: - Skeleton

/// Placeholder of a `ThreadCard`: the same glass card with a title, two preview lines and a
/// footer line.
public struct ThreadCardSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SkeletonText(AppTypography.bodyEmphasis, width: 220)
            SkeletonText(AppTypography.caption, lines: 2)
            HStack(spacing: AppSpacing.sm) {
                SkeletonText(AppTypography.caption, width: 120)
                Spacer(minLength: 0)
                SkeletonText(AppTypography.caption, width: 60)
            }
        }
        .shimmer()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardContentPadding()
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
