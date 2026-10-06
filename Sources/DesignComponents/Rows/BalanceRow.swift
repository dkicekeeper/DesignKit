//
//  BalanceRow.swift
//  DesignKit
//
//  A named balance in a list: icon, name, amount, an optional caption line with an amount in
//  it, and an optional mark on the trailing edge. Ported from Tenra's AccountRow; its account
//  model, the deposit interest copy, the tap and the swipe-to-delete stay in Tenra as an
//  adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "🏦 Deposit / 2 000 000 ₸ / Posting: 30 Oct · 12 400 ₸ ……… 🔒".
///
/// A `List` row: it has no padding of its own, the list's row insets place it. Make it
/// tappable with a `Button` (`.buttonStyle(.plain)`, `.contentShape(Rectangle())`) and add
/// `.swipeActions` at the call site.
///
/// ```swift
/// BalanceRow(iconSource: .sfSymbol("banknote.fill"), title: "Deposit",
///            amount: 2_000_000, currency: "KZT",
///            detail: .init("Interest today: ", amount: 1_250),
///            trailingSystemImage: "lock.square.stack.fill")
/// ```
public struct BalanceRow: View {
    /// A caption line under the amount: text, then an optional amount in `amountColor`.
    public struct Detail {
        public let text: String
        public let amount: Double?
        public let amountColor: Color

        /// - Parameters:
        ///   - text: Caption text, in secondary. Include the separator before the amount
        ///     ("Posting: 30 Oct  ·  ").
        ///   - amount: Follows the text on the same line, in the row's currency.
        ///   - amountColor: `AppColors.planned` by default.
        public init(_ text: String, amount: Double? = nil, amountColor: Color = AppColors.planned) {
            self.text = text
            self.amount = amount
            self.amountColor = amountColor
        }
    }

    let iconSource: IconSource?
    let title: String
    let amount: Double
    let currency: String
    let detail: Detail?
    let trailingSystemImage: String?
    let transitionSourceID: String?
    let transitionNamespace: Namespace.ID?

    /// - Parameters:
    ///   - detail: A caption line under the amount; `nil` hides it.
    ///   - trailingSystemImage: A secondary mark on the trailing edge (a lock for a locked
    ///     balance, for example).
    ///   - transitionSourceID: With `transitionNamespace`, makes the icon the source of a
    ///     `.navigationTransition(.zoom(sourceID:in:))`.
    public init(
        iconSource: IconSource?,
        title: String,
        amount: Double,
        currency: String,
        detail: Detail? = nil,
        trailingSystemImage: String? = nil,
        transitionSourceID: String? = nil,
        transitionNamespace: Namespace.ID? = nil
    ) {
        self.iconSource = iconSource
        self.title = title
        self.amount = amount
        self.currency = currency
        self.detail = detail
        self.trailingSystemImage = trailingSystemImage
        self.transitionSourceID = transitionSourceID
        self.transitionNamespace = transitionNamespace
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            IconView(source: iconSource, size: AppIconSize.xxl)
                .matchedTransitionSourceIfPresent(
                    id: transitionSourceID,
                    namespace: transitionNamespace
                )

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.h4)

                FormattedAmountText(
                    amount: amount,
                    currency: currency,
                    fontSize: AppTypography.bodySmall,
                    color: .secondary
                )

                if let detail {
                    HStack(spacing: 0) {
                        Text(detail.text)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)

                        if let detailAmount = detail.amount {
                            FormattedAmountText(
                                amount: detailAmount,
                                currency: currency,
                                fontSize: AppTypography.caption,
                                color: detail.amountColor
                            )
                        }
                    }
                }
            }

            Spacer()

            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .foregroundStyle(.secondary)
                    .font(.system(size: AppIconSize.sm))
            }
        }
    }
}
