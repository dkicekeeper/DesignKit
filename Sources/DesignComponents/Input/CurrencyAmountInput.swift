//
//  CurrencyAmountInput.swift
//  DesignKit
//
//  The amount at the top of an add or edit sheet: the large animated amount (typed, or the
//  calculator's display), "≈ 1 234 ₸" in the base currency when another currency is chosen,
//  the currency chip, and the validation error. Ported from Tenra's AmountInputView: the
//  conversion goes through DesignKitCurrencyConverter (convertSync, then convert), and the
//  currencies to offer and the customize action are parameters.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A large amount with its currency.
///
/// ```swift
/// CurrencyAmountInput(
///     amount: $amountText,
///     currency: $currency,
///     baseCurrency: "KZT",
///     currencies: ["KZT", "USD", "EUR"],
///     errorMessage: error
/// )
/// ```
///
/// The converted line appears when the chosen currency is not `baseCurrency` and the amount is
/// above zero; it needs the host's converter (`DesignKitCurrencyConverter`) and shows a small
/// spinner until a rate comes. Typing waits 0.3 s before converting; a currency change converts
/// at once.
public struct CurrencyAmountInput: View {
    @Binding var amount: String
    @Binding var currency: String
    let baseCurrency: String
    let currencies: [String]
    let errorMessage: String?
    let calculatorModel: CalculatorInputModel?
    let onCalculatorTap: (() -> Void)?
    let onAmountChange: ((String) -> Void)?
    let onCustomizeCurrencies: (() -> Void)?

    @State private var convertedAmount: Double?

    /// - Parameters:
    ///   - currencies: What the currency chip offers (`CurrencyPickerMenu`).
    ///   - calculatorModel: When set, the amount is entered with the in-app calculator keypad:
    ///     the large display reads the model (the host owns it, places the keypad and mirrors
    ///     `model.amountText` into `amount`). Otherwise the system keyboard, focused on appear.
    ///   - onCalculatorTap: The calculator display was tapped (re-show the keypad).
    ///   - onCustomizeCurrencies: Adds "Customize…" to the currency menu.
    public init(
        amount: Binding<String>,
        currency: Binding<String>,
        baseCurrency: String,
        currencies: [String],
        errorMessage: String? = nil,
        calculatorModel: CalculatorInputModel? = nil,
        onCalculatorTap: (() -> Void)? = nil,
        onAmountChange: ((String) -> Void)? = nil,
        onCustomizeCurrencies: (() -> Void)? = nil
    ) {
        self._amount = amount
        self._currency = currency
        self.baseCurrency = baseCurrency
        self.currencies = currencies
        self.errorMessage = errorMessage
        self.calculatorModel = calculatorModel
        self.onCalculatorTap = onCalculatorTap
        self.onAmountChange = onAmountChange
        self.onCustomizeCurrencies = onCustomizeCurrencies
    }

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            if let calculatorModel {
                CalculatorAmountDisplay(model: calculatorModel, onTap: onCalculatorTap)
            } else {
                AmountInput(
                    amount: $amount,
                    baseFontSize: 56,
                    color: errorMessage != nil ? AppColors.destructive : AppColors.textPrimary,
                    autoFocus: true,
                    showContextMenu: true,
                    onAmountChange: onAmountChange
                )
            }

            // Converted amount in the base currency
            convertedAmountView
                .animation(AppAnimation.gentleSpring, value: shouldShowConversion)

            // Currency chip (centred)
            CurrencyPickerMenu(selection: $currency, currencies: currencies, onCustomize: onCustomizeCurrencies)

            // Validation error
            if let errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.destructive)
                    .multilineTextAlignment(.center)
            }
        }
        // Typing: convert once it pauses.
        .task(id: amount) {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await updateConvertedAmount()
        }
        // A new currency: convert at once.
        .onChange(of: currency) { _, _ in
            Task { await updateConvertedAmount() }
        }
    }

    // MARK: - Converted amount

    @ViewBuilder
    private var convertedAmountView: some View {
        if shouldShowConversion {
            HStack(spacing: AppSpacing.xs) {
                Text(String(localized: "currency.conversion.approximate", defaultValue: "≈"))
                    .font(AppTypography.h4)
                    .foregroundStyle(AppColors.textSecondary)

                if let convertedAmount {
                    Text(Self.groupedDigits(convertedAmount))
                        .font(AppTypography.h4)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.textSecondary)
                        .contentTransition(.numericText())
                        .animation(AppAnimation.gentleSpring, value: convertedAmount)

                    Text(verbatim: Formatting.currencySymbol(for: baseCurrency))
                        .font(AppTypography.h4)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.textSecondary)
                        .contentTransition(.numericText())
                } else {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    private var shouldShowConversion: Bool {
        guard currency != baseCurrency else { return false }
        guard let value = Self.parse(amount), value > 0 else { return false }
        return true
    }

    private static func parse(_ text: String) -> Double? {
        Double(AmountInputFormatting.cleanAmountString(text))
    }

    /// The digits with kern at the group boundaries instead of spaces, so `.numericText()`
    /// animates only the digits that change (as `AmountDigitDisplay` does).
    private static func groupedDigits(_ value: Double) -> AttributedString {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."

        let raw = formatter.string(from: NSNumber(value: value)) ?? "0"
        var result = AttributedString(raw)

        let integerEnd = raw.firstIndex(of: ".") ?? raw.endIndex
        let integerCount = raw.distance(from: raw.startIndex, to: integerEnd)
        guard integerCount > 3 else { return result }

        let groupKern: CGFloat = 3.0
        var attrIndex = result.startIndex
        for charIndex in 0..<integerCount {
            let nextIndex = result.index(afterCharacter: attrIndex)
            if charIndex < integerCount - 1 && (integerCount - charIndex - 1) % 3 == 0 {
                result[attrIndex..<nextIndex].kern = groupKern
            }
            attrIndex = nextIndex
        }
        return result
    }

    @MainActor
    private func updateConvertedAmount() async {
        guard currency != baseCurrency, let value = Self.parse(amount), value > 0 else {
            convertedAmount = nil
            return
        }
        if let converted = await DesignKitCurrencyConverter.converted(value, from: currency, to: baseCurrency) {
            convertedAmount = converted
        }
    }
}
