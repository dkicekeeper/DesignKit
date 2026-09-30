//
//  DesignKitCurrencyConverter.swift
//  DesignKit
//
//  Currency conversion is an app concern (rate providers, caching, network).
//  DesignKit ships no FX — host apps inject a converter. When none is set,
//  `ConvertedAmountView` renders nothing (the same as a failed conversion).
//

import Foundation

public enum DesignKitCurrencyConverter {
    /// App-provided async conversion: `(amount, fromCurrency, toCurrency) -> converted`.
    /// Return `nil` when the rate is unavailable. Tenra wires this to its
    /// `CurrencyConverter.convert(amount:from:to:)`.
    public static var convert: (@Sendable (_ amount: Double, _ from: String, _ to: String) async -> Double?)?
}
