//
//  BalanceCard.swift
//  DesignKit
//
//  A named balance in a compact card: icon, name and amount. Ported from Tenra's AccountCard;
//  its account model, the navigation link and the zoom transition stay in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "🏦 Kaspi Gold / 1 284 500 ₸" in a card, sized to its content (for a carousel).
///
/// `isLive: true` (2.7.0) shows the amount as a `LiveAmountText`: it rolls up from zero when the
/// card first appears and flashes green or red when the balance changes.
///
/// Navigation is left to the caller: wrap the card in a `NavigationLink` with
/// `.buttonStyle(.bounce)`; a `glassEffectID` or `matchedTransitionSource` goes on the card.
///
/// ```swift
/// NavigationLink(value: wallet) {
///     BalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold",
///                 amount: 1_284_500, currency: "KZT")
/// }
/// .buttonStyle(.bounce)
/// ```
public struct BalanceCard: View {
    let iconSource: IconSource?
    let title: String
    let amount: Double
    let currency: String
    let isLive: Bool

    /// - Parameter isLive: The amount rolls up on the card's first appearance and flashes the
    ///   direction of a change (`LiveAmountText`).
    public init(iconSource: IconSource?, title: String, amount: Double, currency: String, isLive: Bool = false) {
        self.iconSource = iconSource
        self.title = title
        self.amount = amount
        self.currency = currency
        self.isLive = isLive
    }

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Icon(source: iconSource, size: AppIconSize.Tile.sm)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.h4)
                    .foregroundStyle(.primary)

                if isLive {
                    LiveAmountText(
                        amount: amount,
                        currency: currency,
                        fontSize: AppTypography.bodySmall,
                        fontWeight: .semibold,
                        color: .primary
                    )
                } else {
                    FormattedAmountText(
                        amount: amount,
                        currency: currency,
                        fontSize: AppTypography.bodySmall,
                        fontWeight: .semibold,
                        color: .primary
                    )
                }
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }
}

// MARK: - Skeleton

/// Placeholder of a `BalanceCard`: the same card, a round icon, the title and the amount.
public struct BalanceCardSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            IconSkeleton(size: AppIconSize.Tile.sm)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.h4, width: 120)
                SkeletonText(AppTypography.bodySmall, width: 90)
            }
        }
        .shimmer()
        .padding(AppSpacing.lg)
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
