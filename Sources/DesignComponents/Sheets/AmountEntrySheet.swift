//
//  AmountEntrySheet.swift
//  DesignKit
//
//  Money put towards something (4.13.0): the hero of what it goes to, the amount on the
//  calculator keypad, a note, and the date buttons with Save. The amount may be typed in
//  another currency; on save it is converted to `currency` through
//  `DesignKitCurrencyConverter.convertSync`. Ported from Tenra's MoneyEntrySheet (money towards
//  a savings goal, a debt paid back); what the money is for and where it is saved stay in the
//  app, as does the sheet that edits the quick-access currencies (`onCustomizeCurrencies`).
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A sheet: "🚗 Car / 1 800 000 ₸ left", the amount over the keypad, a note, Today · Yesterday ·
/// a date · Save.
///
/// ```swift
/// .sheet(isPresented: $adding) {
///     AmountEntrySheet(
///         title: goal.name, icon: .sfSymbol("car.fill"), subtitle: "1 800 000 ₸ left",
///         currency: "KZT", baseCurrency: "KZT", currencies: ["KZT", "USD"]
///     ) { amount, date, note in
///         store.contribute(amount, on: date, note: note)
///     }
/// }
/// ```
public struct AmountEntrySheet: View {
    let title: String
    let icon: IconSource
    let subtitle: String?
    let currency: String
    let baseCurrency: String
    let currencies: [String]
    let suggestedAmount: Double?
    let notePlaceholder: String
    let onCustomizeCurrencies: (() -> Void)?
    let onSave: (_ amount: Double, _ date: Date, _ note: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var calc = CalculatorInputModel()
    @State private var selectedCurrency = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var validationError: String?
    @FocusState private var noteFocused: Bool

    /// - Parameters:
    ///   - currency: What the money is counted in: `onSave` receives the amount in it, and the
    ///     "≈" line shows it when another currency is typed.
    ///   - baseCurrency: The app's base currency, for `CurrencyAmountInput`.
    ///   - currencies: The currencies to offer in the amount's menu.
    ///   - suggestedAmount: Filled in to start with (what is left to pay back); none leaves the
    ///     amount empty.
    ///   - onCustomizeCurrencies: The menu's "Edit" row; the app presents its own sheet.
    ///   - onSave: The amount in `currency` (above zero), the date (today or earlier) and the
    ///     trimmed note, nil when empty. The sheet dismisses itself after it.
    public init(
        title: String,
        icon: IconSource,
        subtitle: String? = nil,
        currency: String,
        baseCurrency: String,
        currencies: [String],
        suggestedAmount: Double? = nil,
        notePlaceholder: String = String(localized: "moneyEntry.notePlaceholder", defaultValue: "Note"),
        onCustomizeCurrencies: (() -> Void)? = nil,
        onSave: @escaping (_ amount: Double, _ date: Date, _ note: String?) -> Void
    ) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.currency = currency
        self.baseCurrency = baseCurrency
        self.currencies = currencies
        self.suggestedAmount = suggestedAmount
        self.notePlaceholder = notePlaceholder
        self.onCustomizeCurrencies = onCustomizeCurrencies
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    HeroSection(icon: icon, title: title, subtitle: subtitle)

                    if let validationError {
                        InlineStatusText(message: validationError, type: .error)
                            .screenPadding()
                    }

                    CurrencyAmountInput(
                        amount: $amountText,
                        currency: $selectedCurrency,
                        baseCurrency: baseCurrency,
                        // "≈" in the sheet's own currency when typed in another.
                        equivalentCurrency: currency,
                        currencies: currencies,
                        errorMessage: nil,
                        calculatorModel: calc,
                        onCalculatorTap: { noteFocused = false },
                        onCustomizeCurrencies: onCustomizeCurrencies
                    )

                    FormTextField(
                        text: $note,
                        placeholder: notePlaceholder,
                        style: .multiline(min: 2, max: 6),
                        externalFocus: $noteFocused
                    )
                    .screenPadding()
                }
                .animation(AppAnimation.gentleSpring, value: validationError)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(String(localized: "button.close", defaultValue: "Close"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .dsButton()
                    .disabled(!isValid)
                    .accessibilityLabel(String(localized: "button.save", defaultValue: "Save"))
                }
            }
            .dateButtonsSafeArea(selectedDate: $date, isDisabled: !isValid, maxDate: Date()) { _ in
                save()
            }
            .safeAreaInset(edge: .bottom) {
                if !noteFocused {
                    CalculatorKeypad(model: calc)
                        .background(AppColors.bgBase)
                }
            }
            .onChange(of: calc.amountText) { _, newValue in
                amountText = newValue
            }
            .onAppear {
                selectedCurrency = currency
                if let suggestedAmount, suggestedAmount > 0 {
                    amountText = AmountInputFormatting.bindingString(for: suggestedAmount)
                    calc.seed(amountText)
                }
            }
        }
    }

    private var isValid: Bool {
        guard let amount = AmountFormatter.parse(amountText) else { return false }
        return amount > 0
    }

    private func save() {
        guard let parsed = AmountFormatter.parse(amountText), parsed > 0 else {
            withAnimation(AppAnimation.contentSpring) {
                validationError = String(localized: "moneyEntry.invalidAmount", defaultValue: "Enter an amount")
            }
            HapticManager.error()
            return
        }
        let typed = NSDecimalNumber(decimal: parsed).doubleValue
        guard let amount = converted(typed) else {
            withAnimation(AppAnimation.contentSpring) {
                validationError = String(localized: "currency.error.conversionFailed", defaultValue: "Currency conversion failed. Please check your internet connection.")
            }
            HapticManager.error()
            return
        }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(amount, date, trimmed.isEmpty ? nil : trimmed)
        HapticManager.success()
        dismiss()
    }

    /// The typed amount in `currency`: as it is in the same currency, through the host's
    /// converter otherwise (nil without a rate).
    private func converted(_ typed: Double) -> Double? {
        if selectedCurrency == currency { return typed }
        return DesignKitCurrencyConverter.convertSync?(typed, selectedCurrency, currency)
    }
}
