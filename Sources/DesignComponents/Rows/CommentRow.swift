//
//  CommentRow.swift
//  DesignKit
//
//  A comment or a reply in a thread: small avatar, author, how long ago, a menu slot, the
//  quoted message, the text, and a row of actions (reactions, "Reply", "edited"). Ported from
//  Dalada's PostRow and CommentRow (one layout for both); the avatar loading, the moderation
//  menu and what the actions do stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A comment.
///
/// ```swift
/// CommentRow(author: "Aida", date: post.createdAt, text: AttributedString(post.body),
///            quote: post.quote.map { MessageQuote(title: $0.author, text: $0.body) },
///            avatar: AppAvatar(path: post.author.avatarPath, size: 32)) {
///     ModerationMenu(…)
/// } actions: {
///     ReactionButton(…)
///     Button("Reply") { reply(to: post) }
/// }
/// ```
///
/// The text is selectable; pass an `AttributedString` to keep links and mentions. Padding:
/// none, like a row that lives in a `List` (design-system §10).
public struct CommentRow<AvatarContent: View, Trailing: View, Actions: View>: View {
    let author: String
    let date: Date
    let text: AttributedString
    let quote: MessageQuote?
    let avatar: AvatarContent
    let menu: Trailing
    let actions: Actions

    /// - Parameters:
    ///   - author: The author's name ("You" for one's own).
    ///   - quote: The message this one answers, over the text.
    ///   - avatar: `CommentRowMetrics.avatarSize` (32) across.
    ///   - menu: After the time (report, block).
    ///   - actions: Under the text, `AppSpacing.lg` apart, in the caption font.
    public init(
        author: String,
        date: Date,
        text: AttributedString,
        quote: MessageQuote? = nil,
        avatar: AvatarContent,
        @ViewBuilder menu: () -> Trailing = { EmptyView() },
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) {
        self.author = author
        self.date = date
        self.text = text
        self.quote = quote
        self.avatar = avatar
        self.menu = menu()
        self.actions = actions()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            avatar
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    Text(verbatim: author)
                        .font(AppTypography.bodyEmphasis)
                        .foregroundStyle(AppColors.Text.primary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(verbatim: date.formatted(.relative(presentation: .named)))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Text.tertiary)
                        .lineLimit(1)
                    menu
                }

                if let quote {
                    QuoteBlock(quote: quote)
                }

                Text(text)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.primary)
                    .textSelection(.enabled)

                if Actions.self != EmptyView.self {
                    HStack(spacing: AppSpacing.lg) {
                        actions
                        Spacer(minLength: 0)
                    }
                    .font(AppTypography.caption)
                }
            }
        }
    }
}

public extension CommentRow where AvatarContent == Avatar {
    /// With the author's initials for the avatar.
    init(
        author: String,
        date: Date,
        text: AttributedString,
        quote: MessageQuote? = nil,
        @ViewBuilder menu: () -> Trailing = { EmptyView() },
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) {
        self.init(
            author: author, date: date, text: text, quote: quote,
            avatar: Avatar(name: author, size: CommentRowMetrics.avatarSize),
            menu: menu, actions: actions
        )
    }
}

/// The quoted message inside a comment: a grey bar, who, and up to three lines of what.
struct QuoteBlock: View {
    let quote: MessageQuote

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Rectangle()
                .fill(AppColors.Text.tertiary)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(verbatim: quote.title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
                Text(verbatim: quote.text)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
                    .lineLimit(3)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// The comment's avatar size, shared with its skeleton.
public enum CommentRowMetrics {
    public static let avatarSize: CGFloat = AppIconSize.xl
}

// MARK: - Skeleton

/// Placeholder of a `CommentRow`: the small avatar, the author and time lines, two lines of text.
public struct CommentRowSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Skeleton.circle(CommentRowMetrics.avatarSize)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    SkeletonText(AppTypography.bodyEmphasis, width: 100)
                    Spacer(minLength: 0)
                    SkeletonText(AppTypography.caption, width: 48)
                }
                SkeletonText(AppTypography.bodySmall, lines: 2)
            }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
