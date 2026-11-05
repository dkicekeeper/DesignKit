//
//  AmountDisplayConcurrencyTests.swift
//
//  `AmountDisplayConfiguration.shared` is written by the app on the main thread (a format
//  change) while amounts are formatted on any thread (an insights pass off the main actor).
//  Reads and writes go through one lock, and a formatter handed out is never changed again.
//
//  The writes to `.shared` here put back the value it already has, so suites running in
//  parallel keep reading the defaults; the store test swaps two configurations on a store of
//  its own. Run once with the Thread Sanitizer to see the race this guards against.
//

import Testing
import Foundation
@testable import DesignSupport

@Suite("Amount display concurrency")
struct AmountDisplayConcurrencyTests {

    private static let iterations = 1_000

    @Test func sharedReadsWhileItIsWritten() async {
        let expected = Formatting.formatCurrencySmart(1234.56, currency: "KZT")
        let unchanged = AmountDisplayConfiguration.shared
        let mismatches = await withTaskGroup(of: Int.self) { group in
            for _ in 0..<2 {
                group.addTask {
                    for _ in 0..<Self.iterations { AmountDisplayConfiguration.shared = unchanged }
                    return 0
                }
            }
            for _ in 0..<4 {
                group.addTask {
                    var wrong = 0
                    for index in 0..<Self.iterations {
                        if Formatting.formatCurrencySmart(1234.56, currency: "KZT") != expected { wrong += 1 }
                        // The whole-number path builds its own formatter variant.
                        if AmountDisplayConfiguration.shared.formattedNumber(Double(index)) == nil { wrong += 1 }
                        if AmountDisplayConfiguration.formatter.string(from: 1) == nil { wrong += 1 }
                    }
                    return wrong
                }
            }
            return await group.reduce(0, +)
        }
        #expect(mismatches == 0)
    }

    @Test func everyReadIsOneWholeConfiguration() async {
        var a = AmountDisplayConfiguration()
        a.thousandsSeparator = ","
        a.decimalSeparator = "."
        a.symbolPosition = .before
        var b = AmountDisplayConfiguration()
        b.thousandsSeparator = "\u{00A0}"
        b.decimalSeparator = ","
        b.secondaryGroupingSize = 2
        let store = AmountDisplayConfiguration.Store(a)
        let marks: Set<[String]> = [
            [a.thousandsSeparator, a.decimalSeparator],
            [b.thousandsSeparator, b.decimalSeparator],
        ]
        let (a2, b2) = (a, b)

        let torn = await withTaskGroup(of: Int.self) { group in
            group.addTask {
                for index in 0..<Self.iterations { store.configuration = index.isMultiple(of: 2) ? b2 : a2 }
                return 0
            }
            for _ in 0..<4 {
                group.addTask {
                    var wrong = 0
                    for index in 0..<Self.iterations {
                        let configuration = store.configuration
                        if configuration != a2 && configuration != b2 { wrong += 1 }
                        let formatter = store.formatter(for: nil, wholeNumbers: index.isMultiple(of: 3))
                        if !marks.contains([formatter.groupingSeparator, formatter.decimalSeparator]) { wrong += 1 }
                        if formatter.string(from: 1_234_567) == nil { wrong += 1 }
                    }
                    return wrong
                }
            }
            return await group.reduce(0, +)
        }
        #expect(torn == 0)
    }

    /// The whole-number variant is cached like the other one: the same instance comes back
    /// until the configuration changes.
    @Test func wholeNumberFormatterIsCached() {
        let store = AmountDisplayConfiguration.Store(AmountDisplayConfiguration())
        let whole = store.formatter(for: nil, wholeNumbers: true)
        #expect(store.formatter(for: nil, wholeNumbers: true) === whole)
        #expect(whole.maximumFractionDigits == 0)
        #expect(store.formatter(for: nil, wholeNumbers: false) !== whole)
        var other = AmountDisplayConfiguration()
        other.thousandsSeparator = ","
        store.configuration = other
        #expect(store.formatter(for: nil, wholeNumbers: true) !== whole)
        #expect(store.formatter(for: nil, wholeNumbers: true).groupingSeparator == ",")
    }
}
