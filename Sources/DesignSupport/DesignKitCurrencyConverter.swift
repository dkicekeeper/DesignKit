//
//  DesignKitCurrencyConverter.swift
//  DesignKit
//
//  Currency conversion is an app concern (rate providers, caching, network).
//  DesignKit ships no FX — host apps inject a converter. When none is set,
//  `ConvertedAmount` renders nothing (the same as a failed conversion).
//

import Foundation

public enum DesignKitCurrencyConverter {
    /// App-provided async conversion: `(amount, fromCurrency, toCurrency) -> converted`.
    /// Return `nil` when the rate is unavailable. Tenra wires this to its
    /// `CurrencyConverter.convert(amount:from:to:)`.
    public static var convert: (@Sendable (_ amount: Double, _ from: String, _ to: String) async -> Double?)?

    /// App-provided instant conversion from cached rates: `(amount, from, to) -> converted`, or
    /// `nil` when no rate is cached (then `convert` is asked). Lets an amount field show the
    /// converted value without waiting while the user types. Optional; Tenra wires it to
    /// `CurrencyConverter.convertSync(amount:from:to:)`.
    public static var convertSync: (@Sendable (_ amount: Double, _ from: String, _ to: String) -> Double?)?

    /// `convertSync` first, then `convert`; `nil` when neither gives a rate (or none is set).
    public static func converted(_ amount: Double, from: String, to: String) async -> Double? {
        if let instant = convertSync?(amount, from, to) { return instant }
        return await convert?(amount, from, to)
    }
}
