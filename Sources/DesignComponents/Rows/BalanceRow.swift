//
//  BalanceRow.swift
//  DesignKit
//
//  A named balance in a list: icon, name, amount, an optional caption line with an amount in
//  it, and an optional mark on the trailing edge. Ported from Tenra's AccountRow; its account
//  model, the deposit interest copy, the tap and the swipe-to-delete stay in Tenra as an
//  adapter.
//  2.1.0: an `AmountRow` in the list style; this name is deprecated.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "🏦 Deposit / 2 000 000 ₸ / Posting: 30 Oct · 12 400 ₸ ……… 🔒".
///
/// At accessibility text sizes the detail's amount moves under its text, which then drops a
/// trailing "·" separator.
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
@available(*, deprecated, message: "Use AmountRow(title, leading: .icon(source), value: .amount(amount, color: AppColors.Text.secondary), currency:, style: .list, detail:, accessory: .systemImage(name)).")
public struct BalanceRow: View {
    /// A caption line under the amount: `AmountRow.Detail` since 2.1.0.
    public typealias Detail = AmountRow.Detail

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
        AmountRow(
            title,
            leading: .icon(iconSource),
            value: .amount(amount, color: AppColors.Text.secondary),
            currency: currency,
            style: .list,
            detail: detail,
            accessory: trailingSystemImage.map(AmountRow.Accessory.systemImage) ?? AmountRow.Accessory.none,
            transitionSourceID: transitionSourceID,
            transitionNamespace: transitionNamespace
        )
    }
}

// MARK: - Skeleton

/// Placeholder of a `BalanceRow`: `AmountRowSkeleton(style: .list, showsDetail:)`.
@available(*, deprecated, message: "Use AmountRowSkeleton(style: .list, showsDetail:).")
public struct BalanceRowSkeleton: View {
    let showsDetail: Bool

    public init(showsDetail: Bool = false) {
        self.showsDetail = showsDetail
    }

    public var body: some View {
        AmountRowSkeleton(style: .list, showsDetail: showsDetail)
    }
}
