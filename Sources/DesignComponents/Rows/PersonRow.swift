//
//  PersonRow.swift
//  DesignKit
//
//  A person in a list: avatar, name, a line under it (the @username, a status), and a trailing
//  slot (a chevron, friend-request buttons, a relationship mark). Ported from Dalada's
//  PersonRow; the photo loading (signed URLs, cache) stays in the app, which passes its
//  avatar view.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A row for a person.
///
/// ```swift
/// PersonRow(name: "Aida Nurlanovna", subtitle: "@aida")          // initials avatar
/// PersonRow(name: "Aida", subtitle: "@aida",
///           avatar: AppAvatar(path: profile.avatarPath)) {         // the app's photo
///     DisclosureChevron()
/// }
/// ```
///
/// Padding: none, like a row that lives in a `List` (design-system §10).
///
/// `style: .card` (2.8.0) is the person at the top of their profile: a 64 pt avatar, the name in
/// `h4`, the @username and a third line (the city), in a padded card:
///
/// ```swift
/// PersonRow(name: "Aida", subtitle: "@aida", detail: "Almaty",
///           avatar: AppAvatar(path: profile.avatarPath, size: AppIconSize.Tile.xl),
///           style: .card) {
///     DisclosureChevron()
/// }
/// ```
public struct PersonRow<AvatarContent: View, Trailing: View>: View {
    public typealias Style = PersonRowStyle

    let name: String
    let subtitle: String?
    let detail: String?
    let avatar: AvatarContent
    let style: Style
    let trailing: Trailing

    /// - Parameters:
    ///   - subtitle: Under the name, in the secondary colour (the @username).
    ///   - detail: A third line, in the tertiary colour (the city).
    ///   - avatar: The person's picture: `AppIconSize.xxl` (40) across in a list,
    ///     `AppIconSize.Tile.xl` (64) in a card.
    public init(
        name: String,
        subtitle: String? = nil,
        detail: String? = nil,
        avatar: AvatarContent,
        style: Style = .list,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.name = name
        self.subtitle = subtitle
        self.detail = detail
        self.avatar = avatar
        self.style = style
        self.trailing = trailing()
    }

    public var body: some View {
        switch style {
        case .list:
            row
                .contentShape(Rectangle())
        case .card:
            row
                .cardContentPadding()
                .cardStyle()
        }
    }

    private var row: some View {
        HStack(spacing: style == .card ? AppSpacing.lg : AppSpacing.md) {
            avatar
            VStack(alignment: .leading, spacing: style == .card ? AppSpacing.xs : AppSpacing.xxs) {
                Text(verbatim: name)
                    .font(style == .card ? AppTypography.h4 : AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(style == .card ? nil : 1)
                if let subtitle {
                    Text(verbatim: subtitle)
                        .font(style == .card ? AppTypography.bodySmall : AppTypography.caption)
                        .foregroundStyle(AppColors.Text.secondary)
                }
                if let detail {
                    Text(verbatim: detail)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Text.tertiary)
                }
            }
            Spacer(minLength: 0)
            trailing
        }
    }
}

/// How a `PersonRow` is laid out.
public enum PersonRowStyle: Hashable, Sendable {
    /// A row of a list: the name in `bodyEmphasis`, no padding.
    case list
    /// A profile's header: the name in `h4`, roomier, in a card that pads itself.
    case card
}

public extension PersonRow where AvatarContent == Avatar {
    /// With the name's initials for the avatar, sized for the style.
    init(
        name: String,
        subtitle: String? = nil,
        detail: String? = nil,
        style: Style = .list,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.init(
            name: name,
            subtitle: subtitle,
            detail: detail,
            avatar: Avatar(name: name, size: style == .card ? AppIconSize.Tile.xl : AppIconSize.xxl),
            style: style,
            trailing: trailing
        )
    }
}

// MARK: - Skeleton

/// Placeholder of a `PersonRow`: the avatar circle, a name line and a shorter line under it; in
/// the card style, the card with a 64 pt avatar and three lines.
public struct PersonRowSkeleton: View {
    let showsSubtitle: Bool
    let style: PersonRowStyle

    public init(showsSubtitle: Bool = true, style: PersonRowStyle = .list) {
        self.showsSubtitle = showsSubtitle
        self.style = style
    }

    public var body: some View {
        switch style {
        case .list:
            HStack(spacing: AppSpacing.md) {
                Skeleton.circle(AppIconSize.xxl)
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    SkeletonText(AppTypography.bodyEmphasis, width: 140)
                    if showsSubtitle {
                        SkeletonText(AppTypography.caption, width: 80)
                    }
                }
                Spacer(minLength: 0)
            }
            .shimmer()
            .skeletonLoadingLabel()
        case .card:
            HStack(spacing: AppSpacing.lg) {
                Skeleton.circle(AppIconSize.Tile.xl)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    SkeletonText(AppTypography.h4, width: 140)
                    if showsSubtitle {
                        SkeletonText(AppTypography.bodySmall, width: 90)
                        SkeletonText(AppTypography.caption, width: 70)
                    }
                }
                Spacer(minLength: 0)
            }
            .shimmer()
            .cardContentPadding()
            .cardStyle()
            .skeletonLoadingLabel()
        }
    }
}
