//
//  AmountInputFormatting.swift
//  Tenra
//
//  Shared static utilities for amount input components.
//  Single source of truth for string cleaning and display formatting
//  used by AmountDigitDisplay (via AmountInputView and AnimatedAmountInput).
//

import SwiftUI

// MARK: - AmountInputFormatting

/// Static formatting utilities shared between amount input components.
///
/// Centralises formatter instances, string cleaning, and display formatting
/// so all amount input components use identical mechanics.
public enum AmountInputFormatting {

    // MARK: - Formatter

    /// Primary formatter: groups digits with spaces, up to 2 decimal places.
    /// Used by currency conversion display and other formatted amount contexts.
    public static let displayFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.groupingSeparator = " "
        f.usesGroupingSeparator = true
        f.decimalSeparator = "."
        return f
    }()

    // MARK: - String Cleaning

    /// Normalises the decimal separator and strips all non-numeric characters.
    /// Single source of truth — used for both keyboard input and clipboard paste.
    /// Preserves a leading minus sign for negative balances.
    public static func cleanAmountString(_ text: String) -> String {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        let hasLeadingMinus = normalized.first == "-"
        let digits = normalized.filter { $0.isNumber || $0 == "." }
        return hasLeadingMinus ? "-" + digits : digits
    }

    // MARK: - Binding Initialization

    /// Produces a clean amount string suitable for initializing an AmountInput
    /// `String` binding from a stored numeric value. Mirrors the design-system rule
    /// (`displayFormatter.minimumFractionDigits = 0`) so a Double of 3500 becomes
    /// "3500" instead of `String(format: "%.2f", …)`'s "3500.00", and 3500.5 becomes
    /// "3500.5". Avoids the delete-key UX issue where the visible display shows no
    /// trailing zeros but the binding holds them, making the first deletes invisible.
    public static func bindingString(for value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// Decimal overload of `bindingString(for:)`.
    public static func bindingString(for value: Decimal) -> String {
        bindingString(for: NSDecimalNumber(decimal: value).doubleValue)
    }

    // MARK: - Display Formatting

    /// Converts a raw amount string into a user-facing display string with grouping.
    ///
    /// The group mark, the decimal mark and the secondary group size come from
    /// `configuration` (the defaults give "1 234.5"). The fraction stays as typed, so an
    /// unfinished "1234." shows "1 234." and "0.0" is not collapsed while typing "0.05".
    ///
    /// Rules:
    /// - Empty, "-" or a plain zero → `"0"`
    /// - Non-parseable input → cleaned raw string (preserves typing in progress)
    public static func displayAmount(
        for text: String,
        configuration: AmountDisplayConfiguration = .shared
    ) -> String {
        let cleaned = cleanAmountString(text)

        if cleaned.isEmpty || cleaned == "-" { return "0" }

        guard let decimal = Decimal(string: cleaned) else { return cleaned }
        if decimal == 0 && !cleaned.contains(".") { return "0" }

        let isNegative = cleaned.hasPrefix("-")
        let unsigned = isNegative ? String(cleaned.dropFirst()) : cleaned
        let parts = unsigned.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integer = groupDigits(
            String(parts[0]),
            separator: configuration.thousandsSeparator,
            secondaryGroupingSize: configuration.secondaryGroupingSize
        )
        var result = (isNegative ? "-" : "") + (integer.isEmpty ? "0" : integer)
        if parts.count > 1 { result += configuration.decimalSeparator + parts[1] }
        return result
    }

    /// Cleans text pasted from the clipboard. When it holds the configured decimal mark,
    /// the configured group mark is a grouping and goes first ("1,234.56" → "1234.56");
    /// otherwise the text is cleaned as typed (a lone "," or "." is the decimal point).
    public static func cleanPastedAmount(
        _ text: String,
        configuration: AmountDisplayConfiguration = .shared
    ) -> String {
        var source = text
        let group = configuration.thousandsSeparator
        let decimal = configuration.decimalSeparator
        if !group.isEmpty, group != decimal, source.contains(decimal) {
            source = source.replacingOccurrences(of: group, with: "")
        }
        if decimal != "." { source = source.replacingOccurrences(of: decimal, with: ".") }
        return cleanAmountString(source)
    }

    /// Formats a Decimal that `displayFormatter` could not handle,
    /// grouping the integer part with spaces.
    public static func formatLargeNumber(_ decimal: Decimal) -> String {
        if let s = displayFormatter.string(from: NSDecimalNumber(decimal: decimal)) { return s }
        let string = String(describing: decimal)
        guard string.contains(".") else { return groupDigits(string) }
        let parts = string.components(separatedBy: ".")
        return "\(groupDigits(parts[0])).\(parts[1].prefix(2))"
    }

    /// Groups digits in an integer string with `separator` every 3 digits, or every
    /// `secondaryGroupingSize` digits after the first group of 3 when it is set.
    public static func groupDigits(
        _ s: String,
        separator: String = " ",
        secondaryGroupingSize: Int? = nil
    ) -> String {
        var result = ""
        var sinceBreak = 0
        var groupSize = 3
        for char in s.reversed() {
            if sinceBreak == groupSize {
                result = separator + result
                sinceBreak = 0
                if let secondaryGroupingSize, secondaryGroupingSize > 0 { groupSize = secondaryGroupingSize }
            }
            result = String(char) + result
            sinceBreak += 1
        }
        return result
    }
}
