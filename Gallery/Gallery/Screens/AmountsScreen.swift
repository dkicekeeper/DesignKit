//
//  AmountsScreen.swift
//  DesignKit Gallery
//
//  Amounts & currency: entering an amount, the calculator, currencies, and every way an
//  amount is shown.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct AmountsScreen: View {
    var body: some View {
        ShowcasePage(title: "Amounts & Currency") {
            FormattedAmountTextPage()
            AmountInputPage()
            AmountDigitDisplayPage()
            CalculatorPage()
            CurrencyAmountInputPage()
            CurrencyPickerMenuPage()
            CurrencyListPage()
            ConvertedAmountPage()
            SpentBudgetTextPage()
            AmountPercentagePage()
            RedactableAmountPage()
        }
    }
}

private struct FormattedAmountTextPage: View {
    @State private var amount = 1_234_567.89
    @State private var policy: AmountDisplayPolicy = .adaptive
    @State private var sign: AmountSign = .automatic
    @State private var unit = 0
    @State private var hidden = false
    @State private var negative = false
    @State private var state: SpecimenState = .content

    private var currencyDisplay: AmountCurrencyDisplay {
        switch unit {
        case 1: return .code
        case 2: return .numberOnly
        default: return .symbol
        }
    }

    var body: some View {
        ComponentPage(
            name: "FormattedAmountText",
            summary: "An amount with its currency: grouped tabular digits, decimals hidden when zero, the sign and the unit as you choose. Every amount in DesignKit is one.",
            apps: [.tenra, .dalada],
            notes: [
                "Hidden amounts: .amountsHidden() above it turns it into •••• ₸.",
                "Loading: FormattedAmountTextSkeleton(font:width:).",
            ]
        ) {
            if state == .loading {
                FormattedAmountTextSkeleton(font: AppTypography.h1, width: 220)
            } else {
                FormattedAmountText(
                    amount: negative ? -amount : amount,
                    currency: "KZT",
                    fontSize: AppTypography.h1,
                    fontWeight: .bold,
                    color: AppColors.textPrimary,
                    policy: policy,
                    sign: sign,
                    currencyDisplay: currencyDisplay
                )
                .amountsHidden(hidden)
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Amount", value: $amount, in: 0...5_000_000, step: 0.01) {
                $0.formatted(.number.precision(.fractionLength(2)))
            }
            ToggleControl("Negative", isOn: $negative)
            ChoiceControl("Policy", selection: $policy, options: [("Full", .full), ("Adaptive", .adaptive), ("Compact", .compact)])
            ChoiceControl("Sign", selection: $sign, options: [("Auto", .automatic), ("Always", .always), ("Never", .never)])
            ChoiceControl("Unit", selection: $unit, options: [("Symbol", 0), ("Code", 1), ("Number", 2)])
            ToggleControl("Hidden", isOn: $hidden)
        }
    }
}

private struct AmountInputPage: View {
    @State private var amount = "1250"
    @State private var size = 48.0

    var body: some View {
        ComponentPage(
            name: "AmountInput",
            summary: "An amount typed in large digits that animate as they change; the size shrinks to fit.",
            apps: [.tenra]
        ) {
            AmountInput(amount: $amount, baseFontSize: size)
        } controls: {
            SliderControl("Font size", value: $size, in: 32...64, step: 2)
            TextControl("Amount", text: $amount)
        }
    }
}

private struct AmountDigitDisplayPage: View {
    @State private var raw = "1250.5"
    @State private var isFocused = true

    var body: some View {
        ComponentPage(
            name: "AmountDigitDisplay",
            summary: "The digits of an amount being typed, grouped, with a BlinkingCursor while focused: what AmountInput and the calculator draw.",
            apps: [.tenra]
        ) {
            AmountDigitDisplay(rawAmount: raw, baseFontSize: 48, isFocused: isFocused)
        } controls: {
            ToggleControl("Focused (cursor)", isOn: $isFocused)
            TextControl("Digits", text: $raw)
        }
    }
}

private struct CalculatorPage: View {
    @State private var model = CalculatorInputModel(seed: "1250")

    var body: some View {
        ComponentPage(
            name: "CalculatorKeypad",
            summary: "A keypad with + − × ÷ that drives a CalculatorAmountDisplay above it; hold ⌫ to clear.",
            apps: [.tenra],
            canvas: .fill
        ) {
            VStack(spacing: AppSpacing.md) {
                CalculatorAmountDisplay(model: model, baseFontSize: 44)
                    .frame(maxWidth: .infinity)
                CalculatorKeypad(model: model)
            }
        } controls: {
            ActionControl("Reset to 1 250", systemImage: "arrow.counterclockwise") { model.seed("1250") }
            ActionControl("Clear", systemImage: "xmark.circle") { model.clear() }
        }
    }
}

private struct CurrencyAmountInputPage: View {
    @State private var amount = "1250"
    @State private var currency = "USD"
    @State private var showsError = false
    /// The "≈" line's currency: the base currency (KZT, the same as leaving it out) or a
    /// euro card's.
    @State private var equivalentCurrency = "KZT"

    var body: some View {
        ComponentPage(
            name: "CurrencyAmountInput",
            summary: "An amount with its currency chip and, in another currency, ≈ the amount in the base currency or in an account's (equivalentCurrency).",
            since: "1.10.0",
            apps: [.tenra],
            notes: [
                "The ≈ line needs the app's DesignKitCurrencyConverter.",
                "With a EUR card, USD shows ≈ €; EUR, the card's own currency, shows ≈ ₸."
            ]
        ) {
            CurrencyAmountInput(
                amount: $amount,
                currency: $currency,
                baseCurrency: "KZT",
                equivalentCurrency: equivalentCurrency,
                currencies: ["KZT", "USD", "EUR", "RUB"],
                errorMessage: showsError ? "Not enough on the account" : nil
            )
        } controls: {
            ChoiceControl("Currency", selection: $currency, options: [("KZT", "KZT"), ("USD", "USD"), ("EUR", "EUR")])
            ChoiceControl("≈ in", selection: $equivalentCurrency, options: [("Base currency", "KZT"), ("EUR card", "EUR")])
            ToggleControl("Error", isOn: $showsError)
        }
    }
}

private struct CurrencyPickerMenuPage: View {
    @State private var currency = "KZT"
    @State private var customizes = true

    var body: some View {
        ComponentPage(
            name: "CurrencyPickerMenu",
            summary: "The currency chip: a menu of the app's currencies, with “Customize…” at the end.",
            since: "1.10.0",
            apps: [.tenra]
        ) {
            CurrencyPickerMenu(selection: $currency, currencies: ["KZT", "USD", "EUR", "RUB"],
                               onCustomize: customizes ? {} : nil)
        } controls: {
            ToggleControl("Customize…", isOn: $customizes)
        }
    }
}

private struct CurrencyListPage: View {
    @State private var currency = "KZT"

    var body: some View {
        ComponentPage(
            name: "CurrencyList",
            summary: "Every currency, popular ones first, with search; pushed from a currency chip.",
            since: "1.10.0",
            apps: [.tenra]
        ) {
            NavigationLink {
                CurrencyList(selection: currency) { currency = $0 }
                    .navigationTitle("Currency")
            } label: {
                Text("Currency: \(currency)").filterChipStyle()
            }
            .buttonStyle(.plain)
        }
    }
}

private struct ConvertedAmountPage: View {
    @State private var from = "USD"

    var body: some View {
        ComponentPage(
            name: "ConvertedAmount",
            summary: "≈ an amount in another currency, converted by the app's DesignKitCurrencyConverter.",
            apps: [.tenra],
            notes: ["The Gallery sets a sample converter; without one the view shows nothing."]
        ) {
            ConvertedAmount(amount: 100, fromCurrency: from, toCurrency: "KZT",
                                fontSize: AppTypography.bodySmall, color: AppColors.textSecondary)
        } controls: {
            ChoiceControl("From", selection: $from, options: [("USD", "USD"), ("EUR", "EUR"), ("RUB", "RUB")])
        }
    }
}

private struct SpentBudgetTextPage: View {
    @State private var spent = 185_000.0
    @State private var budget = 250_000.0

    var body: some View {
        ComponentPage(
            name: "SpentBudgetText",
            summary: "“Spent / budget” on one line.",
            apps: [.tenra]
        ) {
            SpentBudgetText(spent: spent, budget: budget, currency: "KZT")
        } controls: {
            SliderControl("Spent", value: $spent, in: 0...400_000, step: 1_000)
            SliderControl("Budget", value: $budget, in: 50_000...400_000, step: 1_000)
        }
    }
}

private struct AmountPercentagePage: View {
    @State private var percentage = 42.0

    var body: some View {
        ComponentPage(
            name: "AmountPercentage",
            summary: "An amount with its share under it: the trailing side of a breakdown row.",
            apps: [.tenra]
        ) {
            AmountPercentage(amount: 42_000, currency: "KZT", percentage: percentage)
        } controls: {
            SliderControl("Share", value: $percentage, in: 0...100, step: 1) { "\(Int($0))%" }
        }
    }
}

private struct RedactableAmountPage: View {
    @State private var isLoading = false
    @State private var hidden = false

    var body: some View {
        ComponentPage(
            name: "RedactableAmount",
            summary: "A card's total that shows a skeleton line of its own width while it loads.",
            since: "1.7.0",
            apps: [.tenra]
        ) {
            RedactableAmount(amount: 2_450_000, currency: "KZT", isLoading: isLoading)
                .amountsHidden(hidden)
        } controls: {
            ToggleControl("Loading", isOn: $isLoading)
            ToggleControl("Hidden", isOn: $hidden)
        }
    }
}

#Preview { NavigationStack { AmountsScreen() } }
