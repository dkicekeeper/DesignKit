//
//  AmountInputSeparatorsTests.swift
//
//  Pins the amount input field: the shown text follows the configured separators,
//  typed "," and "." both stay the decimal point, a paste drops the group mark.
//

import Testing
import Foundation
@testable import DesignSupport

@Suite("AmountInputFormatting separators")
struct AmountInputSeparatorsTests {

    private func config(thousands: String, decimal: String) -> AmountDisplayConfiguration {
        var c = AmountDisplayConfiguration()
        c.thousandsSeparator = thousands
        c.decimalSeparator = decimal
        return c
    }

    @Test func displayUsesConfiguredSeparators() {
        let commaDot = config(thousands: ",", decimal: ".")
        let dotComma = config(thousands: ".", decimal: ",")
        #expect(AmountInputFormatting.displayAmount(for: "1234.5", configuration: commaDot) == "1,234.5")
        #expect(AmountInputFormatting.displayAmount(for: "1234.5", configuration: dotComma) == "1.234,5")
        #expect(AmountInputFormatting.displayAmount(for: "1234.", configuration: dotComma) == "1.234,")
        #expect(AmountInputFormatting.displayAmount(for: "-1234567", configuration: commaDot) == "-1,234,567")
    }

    @Test func displaySecondaryGrouping() {
        var c = config(thousands: ",", decimal: ".")
        c.secondaryGroupingSize = 2
        #expect(AmountInputFormatting.displayAmount(for: "1234567", configuration: c) == "12,34,567")
    }

    @Test func displayDefaultUnchanged() {
        #expect(AmountInputFormatting.displayAmount(for: "1234.5", configuration: AmountDisplayConfiguration()) == "1 234.5")
        #expect(AmountInputFormatting.displayAmount(for: "", configuration: AmountDisplayConfiguration()) == "0")
        #expect(AmountInputFormatting.displayAmount(for: "0", configuration: AmountDisplayConfiguration()) == "0")
    }

    @Test func typedCommaStaysDecimal() {
        #expect(AmountInputFormatting.cleanAmountString("1,5") == "1.5")
    }

    @Test func pastedGroupedAmount() {
        let commaDot = config(thousands: ",", decimal: ".")
        let spaceComma = config(thousands: " ", decimal: ",")
        #expect(AmountInputFormatting.cleanPastedAmount("1,234.56", configuration: commaDot) == "1234.56")
        #expect(AmountInputFormatting.cleanPastedAmount("1 234,56", configuration: spaceComma) == "1234.56")
    }
}
