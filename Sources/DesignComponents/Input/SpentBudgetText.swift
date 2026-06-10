//
//  SpentBudgetText.swift
//  Tenra
//
//  "spent / budget" amount pair shared by CategoryRow and BudgetProgressRow.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Renders `spent / budget` as two `FormattedAmountText` values around a slash.
/// Font, weight and colors are configurable so both the management-list style
/// (bodySmall, over-budget tinting) and the insights card style (caption,
/// tertiary separator) route through one implementation.
public struct SpentBudgetText: View {
    let spent: Double
    let budget: Double
    let currency: String
    var font: Font = AppTypography.bodySmall
    var fontWeight: Font.Weight = .regular
    var amountColor: Color = AppColors.textSecondary
    var separatorColor: Color = AppColors.textSecondary

    public init(spent: Double, budget: Double, currency: String, font: Font = AppTypography.bodySmall, fontWeight: Font.Weight = .regular, amountColor: Color = AppColors.textSecondary, separatorColor: Color = AppColors.textSecondary) {
        self.spent = spent
        self.budget = budget
        self.currency = currency
        self.font = font
        self.fontWeight = fontWeight
        self.amountColor = amountColor
        self.separatorColor = separatorColor
    }

    public var body: some View {
        HStack(spacing: 0) {
            FormattedAmountText(
                amount: spent,
                currency: currency,
                fontSize: font,
                fontWeight: fontWeight,
                color: amountColor
            )
            Text(" / ")
                .font(font)
                .foregroundStyle(separatorColor)
            FormattedAmountText(
                amount: budget,
                currency: currency,
                fontSize: font,
                fontWeight: fontWeight,
                color: amountColor
            )
        }
    }
}

