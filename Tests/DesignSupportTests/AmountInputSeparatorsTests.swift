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

    // MARK: - Live field (AmountDigitDisplay)

    @Test func liveDefaultKeepsKernGap() {
        let r = AmountInputFormatting.liveDisplay(for: "12345.5", configuration: AmountDisplayConfiguration())
        #expect(r.text == "12345.5")
        #expect(r.kernAfter == [1])
        let big = AmountInputFormatting.liveDisplay(for: "1234567", configuration: AmountDisplayConfiguration())
        #expect(big.text == "1234567")
        #expect(big.kernAfter == [0, 3])
    }

    @Test func liveCommaDotInsertsMarks() {
        let r = AmountInputFormatting.liveDisplay(for: "12345.5", configuration: config(thousands: ",", decimal: "."))
        #expect(r.text == "12,345.5")
        #expect(r.kernAfter.isEmpty)
    }

    @Test func liveDotCommaInsertsMarks() {
        let c = config(thousands: ".", decimal: ",")
        #expect(AmountInputFormatting.liveDisplay(for: "12345.5", configuration: c).text == "12.345,5")
        #expect(AmountInputFormatting.liveDisplay(for: "1234,", configuration: c).text == "1.234,")
    }

    @Test func liveSpaceCommaKeepsKernGap() {
        let r = AmountInputFormatting.liveDisplay(
            for: "12345.5", configuration: config(thousands: "\u{00A0}", decimal: ","))
        #expect(r.text == "12345,5")
        #expect(r.kernAfter == [1])
    }

    @Test func liveSecondaryGrouping() {
        var c = config(thousands: ",", decimal: ".")
        c.secondaryGroupingSize = 2
        #expect(AmountInputFormatting.liveDisplay(for: "1234567", configuration: c).text == "12,34,567")
        var k = AmountDisplayConfiguration()
        k.secondaryGroupingSize = 2
        let r = AmountInputFormatting.liveDisplay(for: "1234567", configuration: k)
        #expect(r.text == "1234567")
        #expect(r.kernAfter == [1, 3])
    }

    @Test func liveNegativeAndEmpty() {
        let c = config(thousands: ",", decimal: ".")
        #expect(AmountInputFormatting.liveDisplay(for: "-1234", configuration: c).text == "-1,234")
        let k = AmountInputFormatting.liveDisplay(for: "-1234", configuration: AmountDisplayConfiguration())
        #expect(k.text == "-1234")
        #expect(k.kernAfter == [1])
        #expect(AmountInputFormatting.liveDisplay(for: "", configuration: c).text == "0")
    }
}
