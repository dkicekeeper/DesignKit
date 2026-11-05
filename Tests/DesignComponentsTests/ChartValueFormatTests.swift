//
//  ChartValueFormatTests.swift
//
//  Pins `ChartValueFormat.compactString` (axis labels, chart VoiceOver): it follows the
//  configured separators only when `separatorsOverrideLocale` is on.
//

import Testing
import Foundation
import DesignSupport
@testable import DesignComponents

@Suite("ChartValueFormat.compactString")
struct ChartValueFormatTests {

    @Test func defaultConfigurationKeepsTheLocale() {
        let text = ChartValueFormat.compactString(
            1_200_000, locale: Locale(identifier: "en_US"), configuration: AmountDisplayConfiguration()
        )
        #expect(text == "1.2M")
    }

    @Test func followsTheConfiguredSeparatorWhenOverriding() {
        var configuration = AmountDisplayConfiguration()
        configuration.separatorsOverrideLocale = true
        configuration.decimalSeparator = ","
        let text = ChartValueFormat.compactString(
            1_200_000, locale: Locale(identifier: "en_US"), configuration: configuration
        )
        #expect(text.contains("1,2"))
    }
}
