//
//  CurrencyEquivalentTests.swift
//  DesignKit
//
//  The "≈" line of CurrencyAmountInput (1.12.0): the latest input wins over a slower, older
//  conversion, and no rate clears the line instead of leaving the previous number on it.
//

import Testing
@testable import DesignComponents

@Suite("CurrencyEquivalent")
struct CurrencyEquivalentTests {

    private func request(_ amount: Double, _ from: String, _ to: String) -> CurrencyEquivalentRequest {
        CurrencyEquivalentRequest(amount: amount, from: from, to: to)
    }

    /// `state.begin(request)`, which hands out a ticket for any request. Called outside
    /// `#require`: the macro would call the mutating `begin` on a copy of `state`.
    private func begin(
        _ request: CurrencyEquivalentRequest,
        in state: inout CurrencyEquivalentState
    ) throws -> CurrencyEquivalentState.Ticket {
        let ticket = state.begin(request)
        return try #require(ticket)
    }

    // MARK: - When there is a line

    @Test("A line only for an amount above zero in another currency than the base")
    func amountAboveZero() {
        #expect(CurrencyEquivalentRequest(amount: nil, currency: "USD", baseCurrency: "KZT") == nil)
        #expect(CurrencyEquivalentRequest(amount: 0, currency: "USD", baseCurrency: "KZT") == nil)
        #expect(CurrencyEquivalentRequest(amount: -5, currency: "USD", baseCurrency: "KZT") == nil)
        // The base currency itself: no line (the snapshot of CurrencyAmountInput).
        #expect(CurrencyEquivalentRequest(amount: 1_250, currency: "KZT", baseCurrency: "KZT") == nil)
        #expect(CurrencyEquivalentRequest(amount: 10, currency: "USD", baseCurrency: "KZT") == request(10, "USD", "KZT"))
    }

    // MARK: - When to convert

    @Test("A new line and new currencies convert at once; typing waits for a pause")
    func typingWaits() throws {
        var state = CurrencyEquivalentState()

        let first = try begin(request(1, "USD", "KZT"), in: &state)
        #expect(first.waitsForTyping == false)

        let typed = try begin(request(12, "USD", "KZT"), in: &state)
        #expect(typed.waitsForTyping)

        let otherCurrency = try begin(request(12, "EUR", "KZT"), in: &state)
        #expect(otherCurrency.waitsForTyping == false)

        let otherTarget = try begin(request(12, "EUR", "USD"), in: &state)
        #expect(otherTarget.waitsForTyping == false)

        // The same input again (the view came back): at once.
        let again = try begin(request(12, "EUR", "USD"), in: &state)
        #expect(again.waitsForTyping == false)

        // After the line was gone (the amount cleared), the first digit converts at once.
        let cleared = state.begin(nil)
        #expect(cleared == nil)
        let restarted = try begin(request(5, "EUR", "USD"), in: &state)
        #expect(restarted.waitsForTyping == false)
    }

    // MARK: - The latest input wins

    @Test("A slow, older conversion that comes back last never overwrites a newer one")
    func olderResultLast() throws {
        var state = CurrencyEquivalentState()
        let dollars = request(100, "USD", "KZT")
        let euros = request(100, "EUR", "KZT")
        let older = try begin(dollars, in: &state)
        let newer = try begin(euros, in: &state)

        state.finish(newer, value: 52_000)
        state.finish(older, value: 48_000)

        #expect(state.outcome == CurrencyEquivalentState.Outcome(request: euros, value: 52_000))
        #expect(state.display(for: euros) == .converted(amount: 52_000, currency: "KZT"))
    }

    @Test("An older conversion that comes back first is dropped too")
    func olderResultFirst() throws {
        var state = CurrencyEquivalentState()
        let older = try begin(request(1, "USD", "KZT"), in: &state)
        let current = request(12, "USD", "KZT")
        let newer = try begin(current, in: &state)

        state.finish(older, value: 480)
        #expect(state.outcome == nil)
        #expect(state.display(for: current) == .loading)

        state.finish(newer, value: 5_760)
        #expect(state.display(for: current) == .converted(amount: 5_760, currency: "KZT"))
    }

    // MARK: - What the line shows

    @Test("Typing keeps the previous value until its own conversion comes")
    func typingKeepsValue() throws {
        var state = CurrencyEquivalentState()
        let hundred = request(100, "USD", "KZT")
        let first = try begin(hundred, in: &state)
        state.finish(first, value: 48_000)

        let thousand = request(1_000, "USD", "KZT")
        let typed = try begin(thousand, in: &state)
        // The number changes in place once the pause is over, not through the spinner.
        let cachedRate: (CurrencyEquivalentRequest) -> Double? = { $0.amount * 480 }
        #expect(state.display(for: thousand) == .converted(amount: 48_000, currency: "KZT"))
        #expect(state.display(for: thousand, instant: cachedRate) == .converted(amount: 48_000, currency: "KZT"))

        state.finish(typed, value: 480_000)
        #expect(state.display(for: thousand) == .converted(amount: 480_000, currency: "KZT"))
    }

    @Test("No rate hides the line instead of keeping the previous number")
    func noRateHides() throws {
        var state = CurrencyEquivalentState()
        let hundred = request(100, "USD", "KZT")
        let first = try begin(hundred, in: &state)
        state.finish(first, value: 48_000)

        let thousand = request(1_000, "USD", "KZT")
        let typed = try begin(thousand, in: &state)
        state.finish(typed, value: nil)
        #expect(state.display(for: thousand) == .hidden)

        // Typing on: no line until a rate comes, then the value.
        let more = request(1_500, "USD", "KZT")
        let next = try begin(more, in: &state)
        #expect(state.display(for: more) == .hidden)
        state.finish(next, value: 720_000)
        #expect(state.display(for: more) == .converted(amount: 720_000, currency: "KZT"))
    }

    @Test("A value for other currencies is never shown: the cached rate's value, or the spinner")
    func otherCurrencies() throws {
        var state = CurrencyEquivalentState()
        let dollars = request(100, "USD", "KZT")
        let first = try begin(dollars, in: &state)
        state.finish(first, value: 48_000)

        // Another currency typed: not the dollars' value.
        let euros = request(100, "EUR", "KZT")
        #expect(state.display(for: euros) == .loading)
        let cachedRate: (CurrencyEquivalentRequest) -> Double? = { $0.amount * 520 }
        #expect(state.display(for: euros, instant: cachedRate) == .converted(amount: 52_000, currency: "KZT"))

        // Another currency for the line: the same.
        let dollarsInEuros = request(100, "USD", "EUR")
        #expect(state.display(for: dollarsInEuros) == .loading)
    }

    @Test("No amount: no line, and the last result is cleared")
    func clearing() throws {
        var state = CurrencyEquivalentState()
        let hundred = request(100, "USD", "KZT")
        let first = try begin(hundred, in: &state)
        state.finish(first, value: 48_000)

        #expect(state.display(for: nil) == .hidden)
        let cleared = state.begin(nil)
        #expect(cleared == nil)
        #expect(state.outcome == nil)
        #expect(state.display(for: hundred) == .loading)
    }
}
