//
//  AmountDisplayOptionsTests.swift
//
//  Pins the display options of `AmountDisplayConfiguration`: where the symbol stands, when
//  the fraction shows, secondary grouping. Every test builds its own configuration and never
//  touches `AmountDisplayConfiguration.shared`.
//

import Testing
import Foundation
@testable import DesignSupport

@Suite("Amount display options")
struct AmountDisplayOptionsTests {

    private func smart(
        _ amount: Double,
        _ currency: String = "KZT",
        _ edit: (inout AmountDisplayConfiguration) -> Void = { _ in }
    ) -> String {
        var configuration = AmountDisplayConfiguration()
        edit(&configuration)
        return Formatting.formatCurrencySmart(amount, currency: currency, configuration: configuration)
    }

    @Test func symbolAfterIsTheDefault() {
        #expect(smart(1234) == "1 234 ₸")
    }

    @Test func symbolBeforeKeepsTheSignFirst() {
        #expect(smart(1234) { $0.symbolPosition = .before } == "₸1 234")
        #expect(smart(-1234) { $0.symbolPosition = .before } == "-₸1 234")
    }

    @Test func attachSymbolBeforeGluesASignSymbol() {
        #expect(Formatting.attachSymbol("1 234", symbol: "₸", isNegative: false, position: .before) == "₸1 234")
        #expect(Formatting.attachSymbol("-1 234", symbol: "₸", isNegative: true, position: .before) == "-₸1 234")
        #expect(Formatting.attachSymbol("\u{2212}1,234", symbol: "$", isNegative: true, position: .before) == "-$1,234")
        #expect(Formatting.attachSymbol("1.234,56", symbol: "€", isNegative: false, position: .before) == "€1.234,56")
        #expect(Formatting.attachSymbol("1,234", symbol: "₹", isNegative: false, position: .before) == "₹1,234")
        #expect(Formatting.attachSymbol("1,234", symbol: "£", isNegative: false, position: .before) == "£1,234")
        #expect(Formatting.attachSymbol("1,234", symbol: "¥", isNegative: false, position: .before) == "¥1,234")
    }

    /// A symbol with a letter anywhere in it keeps the space too, as each region writes it:
    /// "R$ 1.234,56" (Brazil), "US$ 1,234", "лв. 1 234", "S/ 1 234" (Peru).
    @Test func attachSymbolBeforeSpacesASymbolWithALetter() {
        #expect(Formatting.attachSymbol("1.234,56", symbol: "R$", isNegative: false, position: .before) == "R$\u{00A0}1.234,56")
        #expect(Formatting.attachSymbol("-1.234,56", symbol: "R$", isNegative: true, position: .before) == "-R$\u{00A0}1.234,56")
        #expect(Formatting.attachSymbol("1,234", symbol: "US$", isNegative: false, position: .before) == "US$\u{00A0}1,234")
        #expect(Formatting.attachSymbol("1 234", symbol: "лв.", isNegative: false, position: .before) == "лв.\u{00A0}1 234")
        #expect(Formatting.attachSymbol("1 234", symbol: "S/", isNegative: false, position: .before) == "S/\u{00A0}1 234")
    }

    /// A symbol of letters keeps a no-break space before the number: "CHF 1’234.50", not
    /// "CHF1’234.50".
    @Test func attachSymbolBeforeSpacesALetterSymbol() {
        #expect(Formatting.attachSymbol("1’234.50", symbol: "CHF", isNegative: false, position: .before) == "CHF\u{00A0}1’234.50")
        #expect(Formatting.attachSymbol("-1’234.50", symbol: "CHF", isNegative: true, position: .before) == "-CHF\u{00A0}1’234.50")
        #expect(Formatting.attachSymbol("1 234", symbol: "zł", isNegative: false, position: .before) == "zł\u{00A0}1 234")
        #expect(Formatting.attachSymbol("1 234", symbol: "сом", isNegative: false, position: .before) == "сом\u{00A0}1 234")
    }

    @Test func attachSymbolAfterIsUnchanged() {
        #expect(Formatting.attachSymbol("1 234", symbol: "₸", isNegative: false, position: .after) == "1 234 ₸")
        #expect(Formatting.attachSymbol("-1’234.50", symbol: "CHF", isNegative: true, position: .after) == "-1’234.50 CHF")
    }

    @Test func letterSymbolBeforeInFormattedAmounts() {
        let swiss: (inout AmountDisplayConfiguration) -> Void = {
            $0.symbolPosition = .before
            $0.thousandsSeparator = "’"
        }
        #expect(smart(1234.5, "CHF", swiss) == "CHF\u{00A0}1’234.50")
        #expect(smart(-1234.5, "CHF", swiss) == "-CHF\u{00A0}1’234.50")
        var configuration = AmountDisplayConfiguration()
        configuration.symbolPosition = .before
        #expect(Formatting.formatCurrencyCompact(
            1_200_000, currency: "CHF", locale: Locale(identifier: "en_US"), configuration: configuration
        ) == "CHF\u{00A0}1.2M")
    }

    /// Brazil's region puts the symbol first with "." and ",": "R$ 1.234,56", not "R$1.234,56".
    @Test func brazilianRealBeforeTheNumber() {
        let brazil: (inout AmountDisplayConfiguration) -> Void = {
            $0.symbolPosition = .before
            $0.thousandsSeparator = "."
            $0.decimalSeparator = ","
            $0.separatorsOverrideLocale = true
        }
        let symbol = Formatting.currencySymbol(for: "BRL")
        #expect(symbol == "R$")
        #expect(smart(1234.56, "BRL", brazil) == "R$\u{00A0}1.234,56")
        #expect(smart(-1234.56, "BRL", brazil) == "-R$\u{00A0}1.234,56")
        var configuration = AmountDisplayConfiguration()
        configuration.symbolPosition = .before
        #expect(Formatting.formatCurrencyCompact(
            1_200_000, currency: "BRL", locale: Locale(identifier: "en_US"), configuration: configuration
        ) == "R$\u{00A0}1.2M")
        #expect(Formatting.hiddenAmount(currency: "BRL", configuration: configuration) == "R$\u{00A0}••••")
    }

    @Test func hiddenAmountFollowsTheSymbol() {
        var before = AmountDisplayConfiguration()
        before.symbolPosition = .before
        #expect(Formatting.hiddenAmount(currency: "KZT", configuration: before) == "₸ ••••")
        #expect(Formatting.hiddenAmount(currency: "CHF", configuration: before) == "CHF\u{00A0}••••")
        #expect(Formatting.hiddenAmount(currency: nil, configuration: before) == "••••")
        let after = AmountDisplayConfiguration()
        #expect(Formatting.hiddenAmount(currency: "KZT", configuration: after) == "•••• ₸")
        #expect(Formatting.hiddenAmount(currency: "CHF", configuration: after) == "•••• CHF")
    }

    /// A locale with no grouping mark (or no decimal mark) has nothing to swap: the text comes
    /// back as it is instead of looping on an empty prefix.
    @Test func emptyLocaleSeparatorIsSkipped() {
        var configuration = AmountDisplayConfiguration()
        configuration.separatorsOverrideLocale = true
        configuration.decimalSeparator = ","
        configuration.thousandsSeparator = ""
        #expect(Formatting.applyConfiguredSeparators("1234.5M", decimal: ".", grouping: "", configuration: configuration) == "1234,5M")
        #expect(Formatting.applyConfiguredSeparators("1234M", decimal: "", grouping: "", configuration: configuration) == "1234M")
    }

    @Test func fractionsAlways() {
        #expect(smart(1234) { $0.fractions = .always } == "1 234.00 ₸")
    }

    @Test func fractionsNeverRounds() {
        #expect(smart(1234.5) { $0.fractions = .never } == "1 235 ₸")
    }

    @Test func fractionsNeverKeepsCentsUnderOne() {
        #expect(smart(0.4) { $0.fractions = .never } == "0.40 ₸")
        #expect(smart(-0.4) { $0.fractions = .never } == "-0.40 ₸")
    }

    @Test func secondaryGrouping() {
        let result = smart(1234567.8) {
            $0.thousandsSeparator = ","
            $0.secondaryGroupingSize = 2
        }
        #expect(result == "12,34,567.80 ₸")
    }

    @Test func compactFollowsSeparatorAndSymbol() {
        var configuration = AmountDisplayConfiguration()
        configuration.separatorsOverrideLocale = true
        configuration.decimalSeparator = ","
        configuration.symbolPosition = .before
        let result = Formatting.formatCurrencyCompact(
            1_200_000, currency: "USD", locale: Locale(identifier: "en_US"), configuration: configuration
        )
        #expect(result == "$1,2M")
    }

    @Test func compactKeepsTheConfiguredPointInACommaLocale() {
        let russian = Locale(identifier: "ru_RU")
        var configuration = AmountDisplayConfiguration()
        #expect(Formatting.formatCurrencyCompact(1_200_000, currency: "KZT", locale: russian, configuration: configuration)
                == "1,2\u{00A0}млн ₸")
        configuration.separatorsOverrideLocale = true
        configuration.decimalSeparator = "."
        configuration.thousandsSeparator = ","
        // The locale's no-break space before the unit word is not a thousands separator.
        #expect(Formatting.formatCurrencyCompact(1_200_000, currency: "KZT", locale: russian, configuration: configuration)
                == "1.2\u{00A0}млн ₸")
    }

    @Test func configuredSeparatorsSwapOnlyInsideTheNumber() {
        // The system writes no grouping in compact output ("1234T"), so the grouping branch
        // is pinned on a hand-made string.
        var configuration = AmountDisplayConfiguration()
        configuration.separatorsOverrideLocale = true
        configuration.decimalSeparator = ","
        configuration.thousandsSeparator = "."
        let text = Formatting.applyConfiguredSeparators(
            "1,234.5 T, x", locale: Locale(identifier: "en_US"), configuration: configuration
        )
        #expect(text == "1.234,5 T, x")
    }

    @Test func showDecimalsWhenZeroMapsToFractions() {
        var configuration = AmountDisplayConfiguration()
        #expect(configuration.showDecimalsWhenZero == false)
        configuration.showDecimalsWhenZero = true
        #expect(configuration.fractions == .always)
        configuration.showDecimalsWhenZero = false
        #expect(configuration.fractions == .whenPresent)
    }
}
