//
//  HoldingCard.swift
//  DesignKit
//
//  Something a person holds and what it is worth (a home, a car, a share position): icon,
//  name and a subtitle (when it was valued) with an accessory on the right; the value large,
//  its change as a trend pill with a caption; and the values over time as a sparkline on the
//  trailing edge. Made for Tenra's assets (8.2.0); the asset model, its valuation maths and the
//  wording stay in the app as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// How a `HoldingCard`'s value changed (`HoldingCard.Change`): a `TrendBadge` pill and a
/// caption after it.
///
/// Top-level, not nested in the generic card, so the app can build it without naming the
/// card's accessory.
public struct HoldingChange: Equatable, Sendable {
    public let direction: TrendBadge.Direction
    public let percent: Double?
    public let caption: String?

    /// - Parameters:
    ///   - direction: The pill's arrow and colour; it also tints the sparkline.
    ///   - percent: Signed percent in the pill (`192` → "+192.0%"); `nil` shows the arrow only.
    ///   - caption: After the pill, secondary ("+46M ₸ since purchase"), formatted by the app.
    public init(direction: TrendBadge.Direction, percent: Double?, caption: String? = nil) {
        self.direction = direction
        self.percent = percent
        self.caption = caption
    }
}

/// "🏠 Apartment / Valued 16 Oct", "70 000 000 ₸", "↗ +191.7%  +46M ₸ since purchase" with the
/// values over time on the right.
///
/// ```swift
/// HoldingCard(
///     iconSource: .sfSymbol("house.fill"), title: "Apartment", subtitle: "Valued 16 Oct",
///     amount: 70_000_000, currency: "KZT",
///     change: .init(direction: .up, percent: 191.7, caption: "+46M ₸ since purchase"),
///     history: [24_000_000, 41_000_000, 58_000_000, 70_000_000]
/// )
/// ```
///
/// - Fewer than two values in `history` draw no sparkline: the text takes the full width.
/// - `isLive: true` shows the value as a `LiveAmountText`: it rolls up when the card first
///   appears and flashes the direction of a change.
/// - At accessibility text sizes the sparkline goes under the value, the full width.
/// - Navigation is left to the caller: a `NavigationLink` around the card with
///   `.buttonStyle(.plain)` or `.bounce`.
public struct HoldingCard<Accessory: View>: View {
    public typealias Change = HoldingChange

    let iconSource: IconSource?
    let title: String
    let subtitle: String?
    let amount: Double
    let currency: String
    let change: Change?
    let history: [Double]
    let isLive: Bool
    let accessory: Accessory

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The sparkline's footprint beside the value.
    static var sparklineWidth: CGFloat { 96 }
    static var sparklineHeight: CGFloat { 44 }

    /// - Parameters:
    ///   - subtitle: Under the name, secondary: when the value was set, a place, a count.
    ///   - amount: The value, large.
    ///   - change: The pill and caption under the value; `nil` leaves the line out (no
    ///     purchase price to compare with).
    ///   - history: The values over time, oldest first, the last one the current value.
    ///   - isLive: The value rolls up on the card's first appearance (`LiveAmountText`).
    ///   - accessory: A view on the trailing edge of the header (a status badge).
    public init(
        iconSource: IconSource?,
        title: String,
        subtitle: String? = nil,
        amount: Double,
        currency: String,
        change: Change? = nil,
        history: [Double] = [],
        isLive: Bool = false,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.iconSource = iconSource
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.currency = currency
        self.change = change
        self.history = history
        self.isLive = isLive
        self.accessory = accessory()
    }

    private var hasSparkline: Bool { history.count >= 2 }

    /// The line follows the change: green up, red down, the accent without one.
    private var sparklineColor: Color {
        change?.direction.color ?? AppColors.accent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header: icon + name + subtitle + accessory, as PayoffProgressCard.
            HStack(alignment: .top) {
                Icon(source: iconSource, size: AppIconSize.Tile.sm)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.h4)
                        .foregroundStyle(AppColors.Text.primary)
                        .lineLimit(2)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.Text.secondary)
                    }
                }

                Spacer(minLength: AppSpacing.sm)

                accessory
            }

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    valueColumn
                    if hasSparkline {
                        sparkline
                    }
                }
            } else {
                HStack(alignment: .bottom, spacing: AppSpacing.md) {
                    valueColumn
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if hasSparkline {
                        sparkline
                            .frame(width: Self.sparklineWidth)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Value

    private var valueColumn: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Group {
                if isLive {
                    LiveAmountText(
                        amount: amount,
                        currency: currency,
                        fontSize: AppTypography.h2,
                        fontWeight: .bold,
                        color: AppColors.Text.primary
                    )
                } else {
                    FormattedAmountText(
                        amount: amount,
                        currency: currency,
                        fontSize: AppTypography.h2,
                        fontWeight: .bold,
                        color: AppColors.Text.primary
                    )
                }
            }
            .lineLimit(1)

            if let change {
                // The caption drops under the pill when both do not fit.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.sm) {
                        changeBadge(change)
                        changeCaption(change)
                    }
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        changeBadge(change)
                        changeCaption(change)
                    }
                }
            }
        }
    }

    private func changeBadge(_ change: Change) -> some View {
        TrendBadge(direction: change.direction, changePercent: change.percent, style: .pill)
    }

    @ViewBuilder
    private func changeCaption(_ change: Change) -> some View {
        if let caption = change.caption {
            Text(caption)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary)
                .lineLimit(1)
        }
    }

    private var sparkline: some View {
        Sparkline(
            values: history,
            coloring: .solid(sparklineColor),
            lineWidth: 2,
            height: Self.sparklineHeight,
            endDotRadius: 3
        )
        .accessibilityHidden(true)
    }
}

public extension HoldingCard where Accessory == EmptyView {
    /// A card with nothing on the trailing edge of the header.
    init(
        iconSource: IconSource?,
        title: String,
        subtitle: String? = nil,
        amount: Double,
        currency: String,
        change: Change? = nil,
        history: [Double] = [],
        isLive: Bool = false
    ) {
        self.init(
            iconSource: iconSource, title: title, subtitle: subtitle,
            amount: amount, currency: currency, change: change,
            history: history, isLive: isLive
        ) { EmptyView() }
    }
}

// MARK: - Skeleton

/// Placeholder of a `HoldingCard`: the same card, the header, the value, the change pill and
/// the sparkline's slot.
public struct HoldingCardSkeleton: View {
    /// The card shows a sparkline; `false` for one without history.
    let showsSparkline: Bool

    public init(showsSparkline: Bool = true) {
        self.showsSparkline = showsSparkline
    }

    private var sparklineWidth: CGFloat { HoldingCard<EmptyView>.sparklineWidth }
    private var sparklineHeight: CGFloat { HoldingCard<EmptyView>.sparklineHeight }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top) {
                IconSkeleton(size: AppIconSize.Tile.sm)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    SkeletonText(AppTypography.h4, width: 140)
                    SkeletonText(AppTypography.bodySmall, width: 100)
                }
                Spacer()
            }
            HStack(alignment: .bottom, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    SkeletonText(AppTypography.h2, width: 150)
                    Skeleton.capsule(height: 26, width: 84)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if showsSparkline {
                    Skeleton(height: sparklineHeight, width: sparklineWidth)
                }
            }
        }
        .shimmer()
        .padding(AppSpacing.lg)
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
