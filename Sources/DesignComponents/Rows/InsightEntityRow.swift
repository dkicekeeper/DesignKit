//
//  InsightEntityRow.swift
//  Tenra
//
//  Shared "icon + name + subtitle + trailing amount" row for Insights detail
//  lists. Replaces three near-identical ad-hoc builders in InsightDetailView
//  (recurring payments, wealth accounts, dormant accounts). Built on UniversalRow.
//  2.1.0: an `AmountRow` with an `.amount` value; this name is deprecated.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Generic entity row: leading icon, a title with an arbitrary subtitle view, and
/// a trailing amount with an optional caption (e.g. "в месяц").
///
/// Use the `subtitle: String` convenience for plain-text subtitles; use the
/// `@ViewBuilder` initializer for dynamic subtitles (e.g. a relative date).
@available(*, deprecated, message: "Use AmountRow(title, subtitle:, leading: .icon(source), value: .amount(amount, color:, caption:), currency:).")
public struct InsightEntityRow<Subtitle: View>: View {
    let iconSource: IconSource?
    let title: String
    let amount: Double
    let currency: String
    var amountColor: Color = AppColors.Text.primary
    var amountCaption: String? = nil
    @ViewBuilder let subtitle: () -> Subtitle

    public init(
        iconSource: IconSource?,
        title: String,
        amount: Double,
        currency: String,
        amountColor: Color = AppColors.Text.primary,
        amountCaption: String? = nil,
        @ViewBuilder subtitle: @escaping () -> Subtitle
    ) {
        self.iconSource = iconSource
        self.title = title
        self.amount = amount
        self.currency = currency
        self.amountColor = amountColor
        self.amountCaption = amountCaption
        self.subtitle = subtitle
    }

    public var body: some View {
        AmountRow(
            title,
            leading: iconSource.map(AmountRow.Leading.icon) ?? AmountRow.Leading.none,
            value: .amount(amount, color: amountColor, caption: amountCaption),
            currency: currency,
            subtitle: subtitle
        )
    }
}

// MARK: - Plain-text subtitle convenience

@available(*, deprecated)
public extension InsightEntityRow where Subtitle == Text {
    init(
        iconSource: IconSource?,
        title: String,
        subtitle: String,
        amount: Double,
        currency: String,
        amountColor: Color = AppColors.Text.primary,
        amountCaption: String? = nil
    ) {
        self.init(
            iconSource: iconSource,
            title: title,
            amount: amount,
            currency: currency,
            amountColor: amountColor,
            amountCaption: amountCaption
        ) {
            Text(subtitle)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary)
        }
    }
}

// MARK: - Skeleton

/// Placeholder of an `InsightEntityRow`: `AmountRowSkeleton(style: .info)`.
@available(*, deprecated, message: "Use AmountRowSkeleton(style: .info).")
public struct InsightEntityRowSkeleton: View {
    public init() {}

    public var body: some View {
        AmountRowSkeleton(style: .info)
    }
}
