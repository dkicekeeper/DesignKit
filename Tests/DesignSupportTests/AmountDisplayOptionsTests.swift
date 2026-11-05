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
        configuration.decimalSeparator = ","
        configuration.symbolPosition = .before
        let result = Formatting.formatCurrencyCompact(
            1_200_000, currency: "USD", locale: Locale(identifier: "en_US"), configuration: configuration
        )
        #expect(result == "$1,2M")
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
