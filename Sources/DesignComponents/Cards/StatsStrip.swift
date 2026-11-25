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
/// wrap to two lines; at accessibility text sizes the counters take two columns. A card: pads
/// itself and draws its own glass. For one figure with a trend, `StatTile`.
///
/// A counter that needs explaining (how it is counted, where it comes from) takes `info:`
/// (vNext): an `InfoTip` after its caption, on the caption's first line.
///
/// ```swift
/// .init(value: "1.8%", title: "of players",
///       info: "The percentage of the game's players who have earned the trophy.",
///       infoTitle: "Share of players")
/// ```
public struct StatsStrip: View {
    /// One counter.
    public struct Item: Identifiable, Sendable {
        public let value: String
        public let title: String
        /// What the counter means, in an `InfoTip` after its caption (vNext): a sentence or two.
        public let info: String?
        /// The tip's heading, the counter's name (the caption is often only its unit); `nil`
        /// shows the text alone, and VoiceOver names the tip "More information".
        public let infoTitle: String?
        public var id: String { title }

        /// - Parameters:
        ///   - info: What the counter means and how it is counted, in an `InfoTip` after the
        ///     caption (vNext).
        ///   - infoTitle: The tip's heading, the counter's full name.
        public init(value: String, title: String, info: String? = nil, infoTitle: String? = nil) {
            self.value = value
            self.title = title
            self.info = info
            self.infoTitle = infoTitle
        }
    }

    let items: [Item]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(items: [Item]) {
        self.items = items
    }

    public var body: some View {
        StatsStripLayout(isStacked: dynamicTypeSize.isAccessibilitySize) {
            ForEach(items) { item in
                counter(item)
            }
        }
        .cardContentPadding()
        .cardStyle()
    }

    @ViewBuilder
    private func counter(_ item: Item) -> some View {
        if let info = item.info {
            // The counter reads as one element and its tip as another, so the tip's button keeps
            // its own action under VoiceOver.
            VStack(spacing: AppSpacing.xxs) {
                value(item)
                    .accessibilityHidden(true)
                caption(item)
                    .accessibilityLabel(Text(verbatim: "\(item.value), \(item.title)"))
                    .infoTip(info, title: item.infoTitle)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
        } else {
            VStack(spacing: AppSpacing.xxs) {
                value(item)
                caption(item)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    private func value(_ item: Item) -> some View {
        Text(verbatim: item.value)
            .font(AppTypography.h4)
            .foregroundStyle(AppColors.Text.primary)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    private func caption(_ item: Item) -> some View {
        Text(verbatim: item.title)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.Text.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }
}

/// The counters in one row, or at accessibility text sizes in two columns, so a caption is
/// not broken mid-word.
struct StatsStripLayout<Content: View>: View {
    let isStacked: Bool
    @ViewBuilder let content: Content

    var body: some View {
        if isStacked {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 2),
                alignment: .center,
                spacing: AppSpacing.md
            ) {
                content
            }
        } else {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                content
            }
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `StatsStrip`: the same glass card with `count` columns of a number line
/// and a caption line.
public struct StatsStripSkeleton: View {
    let count: Int

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(count: Int = 4) {
        self.count = max(1, count)
    }

    public var body: some View {
        StatsStripLayout(isStacked: dynamicTypeSize.isAccessibilitySize) {
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
