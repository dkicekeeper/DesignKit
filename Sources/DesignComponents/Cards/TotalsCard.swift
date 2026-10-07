//
//  TotalsCard.swift
//  DesignKit
//
//  A card of labelled totals side by side, each with an optional change badge against a
//  previous value. Ported from Tenra's InsightsTotalsCard (income / expenses / net flow);
//  the three items, their titles and colours stay in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Labelled totals in one row ("Income", "Expenses", "Net"), with an optional title above
/// and a small "↑ 12%" badge under each value when a previous value is given.
///
/// ```swift
/// TotalsCard([
///     .init(title: "Income", amount: 530_000, previous: 480_000, color: AppColors.success),
///     .init(title: "Expenses", amount: 320_000, previous: 350_000, color: AppColors.destructive,
///           increaseIsGood: false),
/// ], currency: "KZT", title: "May 2026")
/// ```
public struct TotalsCard: View {
    public struct Item: Identifiable {
        public let id: String
        public let title: String
        public let amount: Double
        /// The value to compare with; `nil` hides the change badge.
        public let previous: Double?
        public let color: Color
        /// Colours the change badge: a rise is green when `true`, red when `false`.
        public let increaseIsGood: Bool

        public init(
            id: String? = nil,
            title: String,
            amount: Double,
            previous: Double? = nil,
            color: Color = AppColors.Text.primary,
            increaseIsGood: Bool = true
        ) {
            self.id = id ?? title
            self.title = title
            self.amount = amount
            self.previous = previous
            self.color = color
            self.increaseIsGood = increaseIsGood
        }
    }

    let items: [Item]
    let currency: String
    let title: String?
    let amountFont: Font

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - items: The totals, left to right, spread across the card's width (one per line
    ///     at accessibility text sizes).
    ///   - title: A line above the totals (the period shown, for example); `nil` hides it.
    ///   - amountFont: Font of the amounts.
    public init(
        _ items: [Item],
        currency: String,
        title: String? = nil,
        amountFont: Font = AppTypography.body
    ) {
        self.items = items
        self.currency = currency
        self.title = title
        self.amountFont = amountFont
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if let title {
                Text(title)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
            }

            if dynamicTypeSize.isAccessibilitySize {
                // Accessibility text sizes: one item per line, so no title breaks mid-word.
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(items) { item in
                        stackedItem(item)
                    }
                }
            } else {
                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Spacer()
                        }
                        totalItem(item)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    /// "Expenses ……… 320 000 ₸ / ↓ 9%": the title on the left, the value on the right.
    private func stackedItem(_ item: Item) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            Text(item.title)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary)
                .layoutPriority(1)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                FormattedAmountText(
                    amount: item.amount,
                    currency: currency,
                    fontSize: amountFont,
                    fontWeight: .semibold,
                    color: item.color
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)

                if let previous = item.previous {
                    Self.changeBadge(current: item.amount, previous: previous, increaseIsGood: item.increaseIsGood)
                }
            }
        }
    }

    private func totalItem(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(item.title)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary)

            // The full amount with its currency symbol, never a compact "1.2M".
            FormattedAmountText(
                amount: item.amount,
                currency: currency,
                fontSize: amountFont,
                fontWeight: .semibold,
                color: item.color
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            if let previous = item.previous {
                Self.changeBadge(current: item.amount, previous: previous, increaseIsGood: item.increaseIsGood)
            }
        }
    }

    /// "↑ 12%" / "↓ 4%", coloured by whether the change is good. Nothing when the previous
    /// value is zero (no defined change) or the change rounds to 0%.
    @ViewBuilder
    private static func changeBadge(current: Double, previous: Double, increaseIsGood: Bool) -> some View {
        if abs(previous) > 0.01 {
            let delta = ((current - previous) / abs(previous)) * 100
            if abs(delta) >= 0.5 {
                let isUp = delta > 0
                let color: Color = (isUp == increaseIsGood) ? AppColors.success : AppColors.destructive
                HStack(spacing: 2) {
                    Image(systemName: isUp ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                    Text(String(format: "%.0f%%", abs(delta)))
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `TotalsCard`: the same card, the title and `count` totals side by side;
/// one per line at accessibility text sizes, like the card.
public struct TotalsCardSkeleton: View {
    let count: Int
    let showsTitle: Bool
    let amountFont: Font

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(count: Int = 2, showsTitle: Bool = false, amountFont: Font = AppTypography.body) {
        self.count = max(1, count)
        self.showsTitle = showsTitle
        self.amountFont = amountFont
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if showsTitle {
                SkeletonText(AppTypography.bodyEmphasis, width: 120)
            }
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(0..<count, id: \.self) { _ in
                        HStack(spacing: AppSpacing.sm) {
                            SkeletonText(AppTypography.bodySmall, width: 70)
                            Spacer(minLength: 0)
                            SkeletonText(amountFont, width: 110)
                        }
                    }
                }
            } else {
                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    ForEach(0..<count, id: \.self) { index in
                        if index > 0 {
                            Spacer()
                        }
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            SkeletonText(AppTypography.bodySmall, width: 70)
                            SkeletonText(amountFont, width: 100)
                        }
                    }
                }
            }
        }
        .shimmer()
        .padding(AppSpacing.lg)
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
