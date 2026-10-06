//
//  RecurringPaymentCard.swift
//  DesignKit
//
//  A recurring payment (a subscription, a membership, a bill): icon, name, amount, the amount
//  in a base currency when it differs, a caption and a status mark. Ported from Tenra's
//  SubscriptionCard; the mapping from Tenra's recurring series (and its next-charge copy)
//  stays in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "Netflix / $9.99 / ≈ 4 990 ₸ / Next charge on 12 Oct" with a status mark on the right.
///
/// ```swift
/// RecurringPaymentCard(iconSource: .brandService("Netflix"), title: "Netflix",
///                      amount: 9.99, currency: "USD", baseCurrency: "KZT",
///                      caption: "Next charge on 12 Oct", status: .active)
/// ```
public struct RecurringPaymentCard: View {
    let iconSource: IconSource?
    let title: String
    let amount: Double
    let currency: String
    let baseCurrency: String?
    let caption: String?
    let status: EntityStatus?

    /// - Parameters:
    ///   - baseCurrency: Adds the amount converted to this currency (`ConvertedAmountView`,
    ///     through `DesignKitCurrencyConverter`) when it differs from `currency`.
    ///   - caption: A line at the bottom ("Next charge on 12 Oct").
    ///   - status: A mark on the trailing edge; `nil` hides it.
    public init(
        iconSource: IconSource?,
        title: String,
        amount: Double,
        currency: String,
        baseCurrency: String? = nil,
        caption: String? = nil,
        status: EntityStatus? = nil
    ) {
        self.iconSource = iconSource
        self.title = title
        self.amount = amount
        self.currency = currency
        self.baseCurrency = baseCurrency
        self.caption = caption
        self.status = status
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            IconView(
                source: iconSource,
                size: AppIconSize.xxl
            )

            // Info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.bodyEmphasis)

                FormattedAmountText(
                    amount: amount,
                    currency: currency,
                    fontSize: AppTypography.body,
                    color: .secondary
                )

                if let baseCurrency, !baseCurrency.isEmpty, currency != baseCurrency {
                    ConvertedAmountView(
                        amount: amount,
                        fromCurrency: currency,
                        toCurrency: baseCurrency,
                        fontSize: AppTypography.caption,
                        color: .secondary.opacity(0.7)
                    )
                }

                if let caption {
                    Text(caption)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Status indicator
            if let status {
                StatusIndicatorBadge(status: status, font: AppTypography.h4)
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Skeleton

/// Placeholder of a `RecurringPaymentCard`: the same card, the round icon, the title and the
/// amount.
public struct RecurringPaymentCardSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            IconViewSkeleton(size: AppIconSize.xxl)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.bodyEmphasis, width: 120)
                SkeletonText(AppTypography.body, width: 90)
            }
            Spacer()
        }
        .shimmer()
        .padding(AppSpacing.lg)
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
