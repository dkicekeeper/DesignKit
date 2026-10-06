//
//  ProgressRingTileGrid.swift
//  DesignKit
//
//  Tiles in a grid, each with its amount under it and its limit under that: Tenra's grid
//  of categories (a tile per category, the budget ring around it). Ported from Tenra's
//  CategoryGridView; the category model, the empty state and what a tap opens stay there.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// One tile of a `ProgressRingTileGrid`.
public struct ProgressRingTileGridItem: Identifiable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let color: Color
    /// The ring around the icon; none without a limit.
    public let progress: LimitProgress?
    /// Under the tile, in the primary colour.
    public let amount: Double
    /// Under the amount, in the secondary colour; none without a limit.
    public let limit: Double?
    /// Replaces the tile's own VoiceOver label (its title).
    public let accessibilityLabel: String?
    public let accessibilityHint: String?

    public init(
        id: String,
        title: String,
        systemImage: String,
        color: Color,
        progress: LimitProgress? = nil,
        amount: Double,
        limit: Double? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.progress = progress
        self.amount = amount
        self.limit = limit
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }
}

/// A grid of `ProgressRingTile`s with the amount (and the limit) under each.
///
/// ```swift
/// ProgressRingTileGrid(items: categories.map(\.tileItem), currency: "KZT") { item in
///     open(item.id)
/// }
/// ```
///
/// Columns: as many 108–180 pt columns as fit (four on an iPhone), or exactly `columns`.
/// The tile's id is its zoom-transition source in `transitionNamespace`.
public struct ProgressRingTileGrid: View {
    let items: [ProgressRingTileGridItem]
    let currency: String
    let columns: Int?
    let transitionNamespace: Namespace.ID?
    let onTap: (ProgressRingTileGridItem) -> Void

    public init(
        items: [ProgressRingTileGridItem],
        currency: String,
        columns: Int? = nil,
        transitionNamespace: Namespace.ID? = nil,
        onTap: @escaping (ProgressRingTileGridItem) -> Void
    ) {
        self.items = items
        self.currency = currency
        self.columns = columns
        self.transitionNamespace = transitionNamespace
        self.onTap = onTap
    }

    public var body: some View {
        LazyVGrid(columns: ProgressRingTileGridLayout.columns(columns), spacing: AppSpacing.xxxl) {
            ForEach(items) { item in
                cell(item)
            }
        }
    }

    private func cell(_ item: ProgressRingTileGridItem) -> some View {
        VStack(spacing: AppSpacing.xs) {
            tile(item)

            FormattedAmountText(
                amount: item.amount,
                currency: currency,
                fontSize: AppTypography.bodySmall,
                fontWeight: .regular,
                color: .primary
            )
            .lineLimit(1)

            if let limit = item.limit {
                FormattedAmountText(
                    amount: limit,
                    currency: currency,
                    fontSize: AppTypography.bodySmall,
                    fontWeight: .regular,
                    color: .secondary
                )
                .lineLimit(1)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func tile(_ item: ProgressRingTileGridItem) -> some View {
        let tile = ProgressRingTile(
            title: item.title,
            systemImage: item.systemImage,
            color: item.color,
            progress: item.progress,
            transitionSourceID: item.id,
            transitionNamespace: transitionNamespace,
            action: { onTap(item) }
        )
        if let label = item.accessibilityLabel {
            tile
                .accessibilityLabel(label)
                .accessibilityHint(item.accessibilityHint ?? "")
        } else {
            tile
        }
    }
}

/// The columns the grid and its skeleton share.
enum ProgressRingTileGridLayout {
    static func columns(_ count: Int?) -> [GridItem] {
        if let count {
            return Array(repeating: GridItem(.flexible(), spacing: AppSpacing.lg), count: count)
        }
        // Four columns on an iPhone; the adaptive minimum keeps iPad layouts sensible.
        return [GridItem(.adaptive(minimum: 108, maximum: 180), spacing: AppSpacing.lg)]
    }
}

// MARK: - Skeleton

/// Placeholder of a `ProgressRingTileGrid`: `count` tile skeletons in the same columns, each
/// with an amount line under it.
public struct ProgressRingTileGridSkeleton: View {
    let count: Int
    let columns: Int?

    public init(count: Int = 8, columns: Int? = nil) {
        self.count = max(1, count)
        self.columns = columns
    }

    public var body: some View {
        LazyVGrid(columns: ProgressRingTileGridLayout.columns(columns), spacing: AppSpacing.xxxl) {
            ForEach(0..<count, id: \.self) { _ in
                VStack(spacing: AppSpacing.xs) {
                    ProgressRingTileSkeleton()
                    SkeletonText(AppTypography.bodySmall, width: 64)
                }
            }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
