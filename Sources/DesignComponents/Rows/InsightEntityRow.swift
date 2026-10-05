//
//  InsightEntityRow.swift
//  Tenra
//
//  Shared "icon + name + subtitle + trailing amount" row for Insights detail
//  lists. Replaces three near-identical ad-hoc builders in InsightDetailView
//  (recurring payments, wealth accounts, dormant accounts). Built on UniversalRow.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Generic entity row: leading icon, a title with an arbitrary subtitle view, and
/// a trailing amount with an optional caption (e.g. "в месяц").
///
/// Use the `subtitle: String` convenience for plain-text subtitles; use the
/// `@ViewBuilder` initializer for dynamic subtitles (e.g. a relative date).
public struct InsightEntityRow<Subtitle: View>: View {
    let iconSource: IconSource?
    let title: String
    let amount: Double
    let currency: String
    var amountColor: Color = AppColors.textPrimary
    var amountCaption: String? = nil
    @ViewBuilder let subtitle: () -> Subtitle

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        iconSource: IconSource?,
        title: String,
        amount: Double,
        currency: String,
        amountColor: Color = AppColors.textPrimary,
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
        if dynamicTypeSize.isAccessibilitySize {
            // Accessibility text sizes: the amount moves under the title, which then has the
            // row's full width and does not break mid-word.
            UniversalRow(
                config: .info,
                leadingIcon: iconSource.map { .auto(source: $0, size: AppIconSize.xxl) }
            ) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                    subtitle()
                    amountStack(alignment: .leading)
                }
            } trailing: {
                EmptyView()
            }
        } else {
            UniversalRow(
                config: .info,
                leadingIcon: iconSource.map { .auto(source: $0, size: AppIconSize.xxl) }
            ) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                    subtitle()
                }
            } trailing: {
                amountStack(alignment: .trailing)
            }
        }
    }

    private func amountStack(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: AppSpacing.xs) {
            FormattedAmountText(
                amount: amount,
                currency: currency,
                fontSize: AppTypography.body,
                fontWeight: .semibold,
                color: amountColor
            )
            if let amountCaption {
                Text(amountCaption)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Plain-text subtitle convenience

public extension InsightEntityRow where Subtitle == Text {
    init(
        iconSource: IconSource?,
        title: String,
        subtitle: String,
        amount: Double,
        currency: String,
        amountColor: Color = AppColors.textPrimary,
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
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

// MARK: - Previews
