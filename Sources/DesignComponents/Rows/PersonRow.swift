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
public struct PersonRow<Avatar: View, Trailing: View>: View {
    let name: String
    let subtitle: String?
    let avatar: Avatar
    let trailing: Trailing

    /// - Parameters:
    ///   - subtitle: Under the name, in the secondary colour (the @username).
    ///   - avatar: The person's picture, `AppIconSize.Tile.xs` (40) across.
    public init(
        name: String,
        subtitle: String? = nil,
        avatar: Avatar,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.name = name
        self.subtitle = subtitle
        self.avatar = avatar
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            avatar
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(verbatim: name)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(1)
                if let subtitle {
                    Text(verbatim: subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Text.secondary)
                }
            }
            Spacer(minLength: 0)
            trailing
        }
        .contentShape(Rectangle())
    }
}

public extension PersonRow where Avatar == AvatarView {
    /// With the name's initials for the avatar.
    init(
        name: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.init(name: name, subtitle: subtitle, avatar: AvatarView(name: name), trailing: trailing)
    }
}

// MARK: - Skeleton

/// Placeholder of a `PersonRow`: the avatar circle, a name line and a shorter line under it.
public struct PersonRowSkeleton: View {
    let showsSubtitle: Bool

    public init(showsSubtitle: Bool = true) {
        self.showsSubtitle = showsSubtitle
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            SkeletonView.circle(AppIconSize.Tile.xs)
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
    }
}
