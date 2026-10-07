//
//  ThumbnailCard.swift
//  DesignKit
//
//  Something with a picture in a carousel or a list: the picture (a photo, or a symbol on a
//  pale tint when there is none), the title with a "verified" seal, a "saved" bookmark, and
//  caption lines under it. Ported from Dalada's PlaceItemCard and PlaceItemRow; the photo
//  loading (signed URLs, cache) and the meta lines stay in the app, in the slots.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A card with a picture on top, for a horizontal carousel.
///
/// ```swift
/// ThumbnailCard(title: place.name, isVerified: place.isEditorial, isSaved: place.isSaved) {
///     if let photo { AppPhoto(photo) } else { ThumbnailPlaceholder(systemImage: "tent") }
/// } details: {
///     Text("Lake · 12 km · ★ 4.6")
/// }
/// ```
///
/// No glass and no padding: the picture is the card (200 × 110, `AppRadius.md`), the text
/// sits under it. The details slot gets the caption font in the secondary colour.
public struct ThumbnailCard<Picture: View, Details: View>: View {
    let title: String
    let isVerified: Bool
    let isSaved: Bool
    let verifiedLabel: String?
    let savedLabel: String?
    let width: CGFloat
    let picture: Picture
    let details: Details

    /// - Parameters:
    ///   - isVerified: An accent seal after the title (curated, official).
    ///   - isSaved: An accent bookmark disc on the picture's corner.
    ///   - verifiedLabel: The seal's VoiceOver label; key `thumbnail.verified` by default.
    ///   - savedLabel: The bookmark's VoiceOver label; key `thumbnail.saved` by default.
    ///   - width: The card's width; the picture is `ThumbnailMetrics.cardImageHeight` (110) tall.
    public init(
        title: String,
        isVerified: Bool = false,
        isSaved: Bool = false,
        verifiedLabel: String? = nil,
        savedLabel: String? = nil,
        width: CGFloat = ThumbnailMetrics.cardWidth,
        @ViewBuilder picture: () -> Picture,
        @ViewBuilder details: () -> Details = { EmptyView() }
    ) {
        self.title = title
        self.isVerified = isVerified
        self.isSaved = isSaved
        self.verifiedLabel = verifiedLabel
        self.savedLabel = savedLabel
        self.width = width
        self.picture = picture()
        self.details = details()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ZStack(alignment: .topTrailing) {
                picture
                    .frame(width: width, height: ThumbnailMetrics.cardImageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                if isSaved {
                    Image(systemName: "bookmark.fill")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.staticWhite)
                        .padding(AppSpacing.xs)
                        .background(AppColors.accent, in: Circle())
                        .padding(AppSpacing.xs)
                        .accessibilityLabel(Text(verbatim: savedLabel ?? ThumbnailText.saved))
                }
            }
            HStack(spacing: AppSpacing.xxs) {
                Text(verbatim: title)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(1)
                if isVerified {
                    VerifiedSeal(label: verifiedLabel)
                }
            }
            details
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.Text.secondary)
        }
        .frame(width: width, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// The same thing as a list row: a 64 pt picture on the left, the title (two lines) with the
/// seal and the bookmark, the details under it.
///
/// ```swift
/// ThumbnailRow(title: place.name, isVerified: true, isSaved: true) {
///     ThumbnailPlaceholder(systemImage: "tent")
/// } details: {
///     Text("Lake · 12 km")
/// }
/// ```
///
/// Padding: none, like a row that lives in a `List` (design-system §10).
public struct ThumbnailRow<Picture: View, Details: View>: View {
    let title: String
    let isVerified: Bool
    let isSaved: Bool
    let verifiedLabel: String?
    let savedLabel: String?
    let picture: Picture
    let details: Details

    public init(
        title: String,
        isVerified: Bool = false,
        isSaved: Bool = false,
        verifiedLabel: String? = nil,
        savedLabel: String? = nil,
        @ViewBuilder picture: () -> Picture,
        @ViewBuilder details: () -> Details = { EmptyView() }
    ) {
        self.title = title
        self.isVerified = isVerified
        self.isSaved = isSaved
        self.verifiedLabel = verifiedLabel
        self.savedLabel = savedLabel
        self.picture = picture()
        self.details = details()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            picture
                .frame(width: ThumbnailMetrics.rowImageSize, height: ThumbnailMetrics.rowImageSize)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.xxs) {
                    Text(verbatim: title)
                        .font(AppTypography.bodyEmphasis)
                        .foregroundStyle(AppColors.Text.primary)
                        .lineLimit(2)
                    if isVerified {
                        VerifiedSeal(label: verifiedLabel)
                    }
                    if isSaved {
                        Image(systemName: "bookmark.fill")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.accent)
                            .accessibilityLabel(Text(verbatim: savedLabel ?? ThumbnailText.saved))
                    }
                }
                details
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}

/// The picture when there is no photo: a symbol on a pale tint, filling the frame.
///
/// ```swift
/// ThumbnailPlaceholder(systemImage: "tent", tint: AppColors.accent)
/// ```
public struct ThumbnailPlaceholder: View {
    let systemImage: String
    let tint: Color

    public init(systemImage: String, tint: Color = AppColors.accent) {
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            AppColors.pale(tint)
            Image(systemName: systemImage)
                .font(.system(size: AppIconSize.md * 1.5))
                .foregroundStyle(tint)
        }
        .accessibilityHidden(true)
    }
}

/// The accent seal after a title.
private struct VerifiedSeal: View {
    let label: String?

    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.accent)
            .accessibilityLabel(Text(verbatim: label ?? ThumbnailText.verified))
    }
}

private enum ThumbnailText {
    static var verified: String { String(localized: "thumbnail.verified", defaultValue: "Verified") }
    static var saved: String { String(localized: "thumbnail.saved", defaultValue: "Saved") }
}

/// The sizes of the thumbnail card and row, shared with their skeletons.
public enum ThumbnailMetrics {
    public static let cardWidth: CGFloat = 200
    public static let cardImageHeight: CGFloat = 110
    public static let rowImageSize: CGFloat = AppIconSize.Tile.xl
}

// MARK: - Skeletons

/// Placeholder of a `ThumbnailCard`: the picture's rounded rectangle, a title line and two
/// caption lines.
public struct ThumbnailCardSkeleton: View {
    let width: CGFloat

    public init(width: CGFloat = ThumbnailMetrics.cardWidth) {
        self.width = width
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SkeletonView(height: ThumbnailMetrics.cardImageHeight, width: width, cornerRadius: AppRadius.md)
            SkeletonText(AppTypography.bodyEmphasis, width: width * 0.7)
            SkeletonText(AppTypography.caption, width: width, lines: 2)
        }
        .frame(width: width, alignment: .leading)
        .shimmer()
        .skeletonLoadingLabel()
    }
}

/// Placeholder of a `ThumbnailRow`: the 64 pt picture, a title line and two caption lines.
public struct ThumbnailRowSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            SkeletonView(
                height: ThumbnailMetrics.rowImageSize,
                width: ThumbnailMetrics.rowImageSize,
                cornerRadius: AppRadius.md
            )
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                SkeletonText(AppTypography.bodyEmphasis, width: 180)
                SkeletonText(AppTypography.caption, lines: 2)
            }
            Spacer(minLength: 0)
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
