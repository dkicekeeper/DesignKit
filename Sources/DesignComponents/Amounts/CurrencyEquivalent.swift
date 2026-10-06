//
//  CurrencyEquivalent.swift
//  DesignKit
//
//  The logic behind the "≈" line of CurrencyAmountInput, kept out of the view so it is
//  unit-tested (Tests/DesignComponentsTests/CurrencyEquivalentTests.swift): which currency
//  the line shows, which conversion result it may show, and what it shows while a
//  conversion runs or after one finds no rate. Plain values, no SwiftUI.
//

import Foundation

/// One conversion the "≈" line asks for: `amount` from `from` into `to`.
struct CurrencyEquivalentRequest: Hashable, Sendable {
    let amount: Double
    let from: String
    let to: String

    init(amount: Double, from: String, to: String) {
        self.amount = amount
        self.from = from
        self.to = to
    }

    /// The conversion for an amount typed in `currency`, or `nil` when there is no line:
    /// no amount above zero, or nothing to convert into.
    init?(amount: Double?, currency: String, equivalentCurrency: String?, baseCurrency: String) {
        guard let amount, amount > 0,
              let target = Self.targetCurrency(
                  for: currency,
                  equivalentCurrency: equivalentCurrency,
                  baseCurrency: baseCurrency
              )
        else { return nil }
        self.init(amount: amount, from: currency, to: target)
    }

    /// The currency of the line for an amount in `currency`: `equivalentCurrency`
    /// (`baseCurrency` when nil), or `baseCurrency` when the amount is already in
    /// `equivalentCurrency`; nil (no line) when the amount is in both. So with the account's
    /// currency as `equivalentCurrency`, an amount in another currency shows its value in the
    /// account's, and an amount in the account's own foreign currency its base-currency value.
    static func targetCurrency(for currency: String, equivalentCurrency: String?, baseCurrency: String) -> String? {
        let preferred = equivalentCurrency ?? baseCurrency
        if currency != preferred { return preferred }
        if currency != baseCurrency { return baseCurrency }
        return nil
    }

    /// The same pair of currencies, whatever the amounts.
    func hasSameCurrencies(as other: CurrencyEquivalentRequest) -> Bool {
        from == other.from && to == other.to
    }
}

/// What the "≈" line shows.
enum CurrencyEquivalentDisplay: Equatable, Sendable {
    /// No line.
    case hidden
    /// "≈" and a spinner, until a rate comes.
    case loading
    /// "≈ 1 234 ₸".
    case converted(amount: Double, currency: String)

    var isVisible: Bool { self != .hidden }

    /// The amount and currency to show, nil while loading or hidden.
    var convertedValue: (amount: Double, currency: String)? {
        if case let .converted(amount, currency) = self { return (amount, currency) }
        return nil
    }
}

/// The conversions of one "≈" line: the latest one asked for and the latest result.
///
/// The latest input wins. Each `begin` hands out a ticket, and `finish` keeps a result only
/// when its ticket is still the latest, so a slow, older conversion that comes back after a
/// newer one started is dropped instead of overwriting it.
struct CurrencyEquivalentState: Sendable {
    /// One started conversion.
    struct Ticket: Equatable, Sendable {
        let request: CurrencyEquivalentRequest
        /// Only the amount changed since the previous conversion: the user is typing, so the
        /// conversion waits for a pause. A new line or new currencies convert at once.
        let waitsForTyping: Bool
        fileprivate let generation: Int
    }

    /// The result of a finished conversion: `value` is nil when there was no rate.
    struct Outcome: Equatable, Sendable {
        let request: CurrencyEquivalentRequest
        let value: Double?
    }

    /// The conversion asked for last; nil when there is no line.
    private(set) var request: CurrencyEquivalentRequest?
    /// The result of the latest conversion that finished while it was still the latest.
    private(set) var outcome: Outcome?
    private var generation = 0

    init() {}

    /// Starts a conversion for `request`, making any running one stale. `nil` (no line)
    /// clears the result and returns no ticket: there is nothing to convert.
    mutating func begin(_ request: CurrencyEquivalentRequest?) -> Ticket? {
        generation += 1
        let previous = self.request
        self.request = request
        guard let request else {
            outcome = nil
            return nil
        }
        let typing = previous.map { $0.hasSameCurrencies(as: request) && $0.amount != request.amount } ?? false
        return Ticket(request: request, waitsForTyping: typing, generation: generation)
    }

    /// Records what `ticket`'s conversion gave (nil: no rate). Ignored when a newer
    /// conversion began after it.
    mutating func finish(_ ticket: Ticket, value: Double?) {
        guard ticket.generation == generation else { return }
        outcome = Outcome(request: ticket.request, value: value)
    }

    /// What the line shows for the current input (`request`, from the view's inputs as they
    /// are now).
    ///
    /// - A result for the same currencies is shown while the amount's own conversion runs, so
    ///   typing changes the number in place (the old amount's value until the new one comes).
    /// - No rate for the latest result: no line, rather than an older, wrong number.
    /// - A result for other currencies is never shown. Until one comes for these, `instant`
    ///   (cached rates, `DesignKitCurrencyConverter.convertSync`) gives the value at once, and
    ///   without it the spinner shows.
    func display(
        for request: CurrencyEquivalentRequest?,
        instant: (CurrencyEquivalentRequest) -> Double? = { _ in nil }
    ) -> CurrencyEquivalentDisplay {
        guard let request else { return .hidden }
        if let outcome, outcome.request.hasSameCurrencies(as: request) {
            guard let value = outcome.value else { return .hidden }
            return .converted(amount: value, currency: request.to)
        }
        if let value = instant(request) {
            return .converted(amount: value, currency: request.to)
        }
        return .loading
    }
}
