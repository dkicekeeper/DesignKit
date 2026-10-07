//
//  AmountPercentage.swift
//  DesignKit
//
//  An amount over its share in per cent: the trailing stack of a breakdown row. 2.0.0 moved it
//  out of BreakdownRow.swift and dropped "View" from its name.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Trailing "amount over percentage" stack of breakdown rows.
public struct AmountPercentage: View {
    let amount: Double
    let currency: String
    let percentage: Double

    /// - Parameter percentage: 0…100, shown with one decimal ("42.0%").
    public init(amount: Double, currency: String, percentage: Double) {
        self.amount = amount
        self.currency = currency
        self.percentage = percentage
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: AppSpacing.xs) {
            FormattedAmountText(amount: amount, currency: currency, color: AppColors.Text.primary)
            Text(String(format: "%.1f%%", percentage))
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary)
        }
    }
}

// MARK: - Names before 2.0

@available(*, deprecated, renamed: "AmountPercentage")
public typealias AmountPercentageView = AmountPercentage
