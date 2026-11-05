//
//  AmountGroupingTests.swift
//
//  Pins how `AmountDisplayConfiguration` groups digits. With `separatorsOverrideLocale` the
//  formatter is locale-independent: groups of 3 from 1 000 on (es_ES and it_IT write "1234,56"
//  under 10 000 by their own rule) and no lakh grouping unless asked (en_IN). Without it the
//  device's locale decides, as before 8.8.1. `makeNumberFormatter(systemLocale:)` stands in for
//  the device's locale. Every test builds its own configuration and never touches `.shared`.
//

import Testing
import Foundation
@testable import DesignSupport

@Suite("Amount grouping")
struct AmountGroupingTests {

    private func configuration(
        thousands: String,
        decimal: String,
        overridesLocale: Bool = true,
        secondary: Int? = nil
    ) -> AmountDisplayConfiguration {
        var configuration = AmountDisplayConfiguration()
        configuration.thousandsSeparator = thousands
        configuration.decimalSeparator = decimal
        configuration.separatorsOverrideLocale = overridesLocale
        configuration.secondaryGroupingSize = secondary
        return configuration
    }

    private func format(_ amount: Double, _ configuration: AmountDisplayConfiguration, on locale: String) -> String? {
        configuration.makeNumberFormatter(systemLocale: Locale(identifier: locale))
            .string(from: NSNumber(value: amount))
    }

    @Test(arguments: ["es_ES", "it_IT", "pt_PT", "pl_PL"])
    func groupsFromAThousandWhatEverTheLocale(_ locale: String) {
        #expect(format(1234.56, configuration(thousands: "\u{00A0}", decimal: ","), on: locale) == "1\u{00A0}234,56")
        #expect(format(1234.56, configuration(thousands: ".", decimal: ","), on: locale) == "1.234,56")
        #expect(format(-1234.56, configuration(thousands: ".", decimal: ","), on: locale) == "-1.234,56")
    }

    @Test func noLakhGroupingUnlessAsked() {
        #expect(format(1_234_567.8, configuration(thousands: ",", decimal: "."), on: "en_IN") == "1,234,567.80")
        #expect(format(1_234_567.8, configuration(thousands: ",", decimal: ".", secondary: 2), on: "en_IN") == "12,34,567.80")
    }

    @Test func overrideMakesTheFormatterLocaleIndependent() {
        let formatter = configuration(thousands: " ", decimal: ".").makeNumberFormatter()
        #expect(formatter.locale.identifier == "en_US_POSIX")
        #expect(formatter.groupingSize == 3)
        #expect(formatter.secondaryGroupingSize == 0)
        #expect(configuration(thousands: " ", decimal: ".", secondary: 2).makeNumberFormatter().secondaryGroupingSize == 2)
    }

    /// Dalada's case: without the override the locale's own grouping rule stays.
    @Test func withoutTheOverrideTheLocaleDecides() {
        let plain = configuration(thousands: ".", decimal: ",", overridesLocale: false)
        #expect(format(1234.56, plain, on: "es_ES") == "1234,56")
        #expect(format(1_234_567.8, configuration(thousands: ",", decimal: ".", overridesLocale: false), on: "en_IN") == "12,34,567.80")
        #expect(plain.makeNumberFormatter().locale.identifier == Locale.current.identifier)
    }

    /// The cached formatters (`formattedNumber`, `.formatter`) are built the same way.
    @Test func formattedNumberIsLocaleIndependentToo() {
        let marks = configuration(thousands: ".", decimal: ",")
        #expect(marks.formattedNumber(1234.56) == "1.234,56")
        #expect(marks.formattedNumber(1234) == "1.234")
        #expect(configuration(thousands: ",", decimal: ".").formattedNumber(1_234_567.8) == "1,234,567.80")
    }
}
