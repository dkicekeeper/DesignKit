//
//  BreakdownRow.swift
//  DesignKit
//
//  One part of a breakdown: a tinted icon, a name with an optional detail line, and the part's
//  amount over its share. Ported from Tenra's CategoryBreakdownRow (its trailing stack is
//  Amounts/AmountPercentage.swift);
//  the mapping from Tenra's breakdown item and its category names stays in Tenra as an adapter.
//
//  2.1.0: an `AmountRow` with a `.share` value; this name is deprecated.
//
//  Navigation is left to the caller: wrap the row in a `NavigationLink` and pass
//  `showsChevron: true` so it shows the disclosure chevron.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "🍴 Food / Groceries, Cafés ……… 85 000 ₸ / 42.0%".
///
/// ```swift
/// BreakdownRow(iconSource: .sfSymbol("fork.knife"), color: AppColors.warning, title: "Food",
///              subtitle: "Groceries, Cafés", amount: 85_000, currency: "KZT", percentage: 42)
/// ```
@available(*, deprecated, message: "Use AmountRow(title, subtitle:, subtitleLineLimit: 1, leading: .tinted(source, color), value: .share(amount, percentage:), currency:, accessory: .chevron).")
public struct BreakdownRow: View {
    let iconSource: IconSource?
    let color: Color
    let title: String
    let subtitle: String?
    let amount: Double
    let currency: String
    let percentage: Double
    let showsChevron: Bool

    /// - Parameters:
    ///   - color: Tints the icon and its circle.
    ///   - subtitle: One line under the title (the part's own parts, for example).
    ///   - percentage: The part's share, 0…100.
    ///   - showsChevron: Pass `true` when the row is wrapped in a `NavigationLink`.
    public init(
        iconSource: IconSource?,
        color: Color,
        title: String,
        subtitle: String? = nil,
        amount: Double,
        currency: String,
        percentage: Double,
        showsChevron: Bool = false
    ) {
        self.iconSource = iconSource
        self.color = color
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.currency = currency
        self.percentage = percentage
        self.showsChevron = showsChevron
    }

    public var body: some View {
        AmountRow(
            title,
            subtitle: subtitle,
            subtitleLineLimit: 1,
            leading: .tinted(iconSource, color),
            value: .share(amount, percentage: percentage),
            currency: currency,
            accessory: showsChevron ? .chevron : .none
        )
    }
}

// MARK: - Skeleton

/// Placeholder of a `BreakdownRow`: `AmountRowSkeleton(style: .info)`.
@available(*, deprecated, message: "Use AmountRowSkeleton(style: .info).")
public struct BreakdownRowSkeleton: View {
    public init() {}

    public var body: some View {
        AmountRowSkeleton(style: .info)
    }
}
