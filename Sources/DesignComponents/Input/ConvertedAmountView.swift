//
//  ConvertedAmountView.swift
//  Tenra
//
//  Displays a converted amount in a target currency, loading asynchronously.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Shows a currency-converted amount using the host app's `DesignKitCurrencyConverter`.
/// Renders nothing while loading or if conversion fails.
public struct ConvertedAmountView: View {
    let amount: Double
    let fromCurrency: String
    let toCurrency: String
    let fontSize: Font
    let color: Color

    @State private var convertedAmount: Double?

    public init(
        amount: Double,
        fromCurrency: String,
        toCurrency: String,
        fontSize: Font,
        color: Color
    ) {
        self.amount = amount
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.fontSize = fontSize
        self.color = color
    }

    public var body: some View {
        Group {
            if let converted = convertedAmount, converted > 0 {
                FormattedAmountText(
                    amount: converted,
                    currency: toCurrency,
                    fontSize: fontSize,
                    color: color
                )
            }
        }
        .task(id: "\(amount)-\(fromCurrency)-\(toCurrency)") {
            convertedAmount = await DesignKitCurrencyConverter.convert?(amount, fromCurrency, toCurrency)
        }
    }
}
