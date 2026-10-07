//
//  SelectableBalanceCard.swift
//  DesignKit
//
//  A named balance to pick from: icon, name and amount in a full-width card, outlined in the
//  accent colour when selected. Ported from Tenra's AccountRadioButton; reading the balance
//  from its account store stays in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// One option of a "pick where the money comes from" list; the caller keeps the selection.
///
/// ```swift
/// ForEach(wallets) { wallet in
///     SelectableBalanceCard(iconSource: wallet.icon, title: wallet.name,
///                           amount: wallet.balance, currency: wallet.currency,
///                           isSelected: selectedID == wallet.id) {
///         selectedID = wallet.id
///     }
/// }
/// ```
public struct SelectableBalanceCard: View {
    let iconSource: IconSource?
    let title: String
    let amount: Double
    let currency: String
    let isSelected: Bool
    let action: () -> Void

    /// - Parameter isSelected: Outlines the card in `AppColors.accent` (2 pt), animated.
    public init(
        iconSource: IconSource?,
        title: String,
        amount: Double,
        currency: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.iconSource = iconSource
        self.title = title
        self.amount = amount
        self.currency = currency
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Icon(source: iconSource, size: AppIconSize.Tile.sm)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)

                    FormattedAmountText(
                        amount: amount,
                        currency: currency,
                        fontSize: AppTypography.body,
                        fontWeight: .semibold,
                        color: .primary
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.lg)
            .cardStyle()
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .stroke(AppColors.accent, lineWidth: 2)
                    .opacity(isSelected ? 1 : 0)
                    .animation(AppAnimation.gentleSpring, value: isSelected)
            }
        }
        .buttonStyle(.bounce)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Skeleton

/// Placeholder of a `SelectableBalanceCard`: the same card, a round icon, the title and the
/// amount, unselected.
public struct SelectableBalanceCardSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            IconSkeleton(size: AppIconSize.Tile.sm)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.body, width: 100)
                SkeletonText(AppTypography.body, width: 120)
            }
        }
        .shimmer()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
