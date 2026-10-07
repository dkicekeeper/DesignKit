//
//  FormattedAmountView.swift
//  Tenra
//
//  Created on 2026-01-30
//  Formatted amount display with separate opacity for decimal part
//  REFACTORED 2026-02-11: Now delegates to FormattedAmountText for unified logic
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Обертка для обратной совместимости - делегирует в FormattedAmountText
public struct FormattedAmountView: View {
    let amount: Double
    let currency: String
    let prefix: String
    let color: Color

    public init(amount: Double, currency: String, prefix: String = "", color: Color = AppColors.textPrimary) {
        self.amount = amount
        self.currency = currency
        self.prefix = prefix
        self.color = color
    }

    public var body: some View {
        FormattedAmountText(
            amount: amount,
            currency: currency,
            prefix: prefix,
            fontSize: AppTypography.body,
            fontWeight: .semibold,
            color: color
        )
    }
}

