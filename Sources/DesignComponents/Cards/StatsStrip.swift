//
//  StatsStrip.swift
//  DesignKit
//
//  A card of counters side by side: a number in the h4 style and its caption under it,
//  centred, equal widths ("42 days · 17 trips · 384 km · 9 catches"). Ported from Dalada's
//  ProfileStatsCard; loading and caching the numbers stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A card of counters.
///
/// ```swift
/// StatsStrip(items: [
///     .init(value: "42", title: "days outdoors"),
///     .init(value: "17", title: "trips"),
///     .init(value: "384", title: "km"),
/// ])
/// ```
///
/// Two to five items read well on an iPhone; numbers shrink to fit (down to 60%), captions
/// wrap to two lines. A card: pads itself and draws its own glass. For one figure with a
/// trend, `StatTile`.
public struct StatsStrip: View {
    /// One counter.
    public struct Item: Identifiable, Sendable {
        public let value: String
        public let title: String
        public var id: String { title }

        public init(value: String, title: String) {
            self.value = value
            self.title = title
        }
    }

    let items: [Item]

    public init(items: [Item]) {
        self.items = items
    }

    public var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            ForEach(items) { item in
                VStack(spacing: AppSpacing.xxs) {
                    Text(verbatim: item.value)
                        .font(AppTypography.h4)
                        .foregroundStyle(AppColors.textPrimary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(verbatim: item.title)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
        .cardContentPadding()
        .cardStyle()
    }
}

// MARK: - Skeleton

/// Placeholder of a `StatsStrip`: the same glass card with `count` columns of a number line
/// and a caption line.
public struct StatsStripSkeleton: View {
    let count: Int

    public init(count: Int = 4) {
        self.count = max(1, count)
    }

    public var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            ForEach(0..<count, id: \.self) { _ in
                VStack(spacing: AppSpacing.xxs) {
                    SkeletonText(AppTypography.h4, width: 40)
                    SkeletonText(AppTypography.caption, width: 56)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .shimmer()
        .cardContentPadding()
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
