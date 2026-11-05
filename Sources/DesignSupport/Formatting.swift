//
//  Formatting.swift
//  Tenra
//
//  Created on 2024
//  REFACTORED 2026-02-11: Added smart decimal handling with AmountDisplayConfiguration
//

import Foundation

public nonisolated struct Formatting {
    public static let currencySymbols: [String: String] = [
        "KZT": "₸",
        "USD": "$",
        "EUR": "€",
        "RUB": "₽",
        "GBP": "£",
        "CNY": "¥",
        "JPY": "¥"
    ]

    /// Получает символ валюты по коду
    /// - Parameter currency: Код валюты (например, "USD", "KZT")
    /// - Returns: Символ валюты (например, "$", "₸") или код валюты, если символ не найден
    public static func currencySymbol(for currency: String) -> String {
        if let symbol = currencySymbols[currency.uppercased()] {
            return symbol
        }
        // Fallback: full ISO CurrencyInfo lookup (covers all currencies).
        if let info = CurrencyInfo.find(currency.uppercased()) {
            return info.symbol
        }
        return currency
    }

    /// Форматирует сумму с символом валюты (старая версия, всегда показывает .00)
    /// - Parameters:
    ///   - amount: Сумма
    ///   - currency: Код валюты
    /// - Returns: Отформатированная строка с символом валюты (например, "1,234.56 $")
    /// - Note: Для обратной совместимости. Используйте formatCurrencySmart() для умной обработки дробной части
    public static func formatCurrency(_ amount: Double, currency: String) -> String {
        return formatCurrencySmart(amount, currency: currency, showDecimalsWhenZero: true)
    }

    /// Puts `symbol` on `number` ("1 234" → "1 234 ₸" or "₸1 234"). `number` carries its own
    /// minus when `isNegative`; before the number the minus stays first ("-₸1 234").
    public static func attachSymbol(
        _ number: String,
        symbol: String,
        isNegative: Bool,
        position: CurrencySymbolPosition
    ) -> String {
        switch position {
        case .after:
            return "\(number) \(symbol)"
        case .before:
            guard isNegative, let first = number.first, first == "-" || first == "\u{2212}" else {
                return symbol + number
            }
            return "-" + symbol + number.dropFirst()
        }
    }

    /// Форматирует сумму с символом валюты с умной обработкой дробной части
    /// - Parameters:
    ///   - amount: Сумма
    ///   - currency: Код валюты
    ///   - showDecimalsWhenZero: Показывать ли .00 для целых чисел (по умолчанию из конфигурации)
    ///   - configuration: symbol position, fractions, separators (default: the shared one)
    /// - Returns: Отформатированная строка (например, "1 234" или "1 234.56 ₸")
    public static func formatCurrencySmart(
        _ amount: Double,
        currency: String,
        showDecimalsWhenZero: Bool? = nil,
        configuration: AmountDisplayConfiguration = .shared
    ) -> String {
        let symbol = currencySymbol(for: currency)
        // An explicit `true` forces the fraction; `false` leaves it to `fractions`, which
        // `.always` would otherwise override (the 1.x parameter only ever hid a zero fraction).
        var configuration = configuration
        if showDecimalsWhenZero == false, configuration.fractions == .always {
            configuration.fractions = .whenPresent
        }
        guard let formattedAmount = configuration.formattedNumber(amount, alwaysShowFraction: showDecimalsWhenZero == true) else {
            return String(format: "%.2f %@", amount, symbol)
        }
        return attachSymbol(formattedAmount, symbol: symbol, isNegative: amount < 0, position: configuration.symbolPosition)
    }

    // MARK: - Compact (abbreviated) amounts

    /// Abbreviated amount with currency symbol — "1.2M ₸", "1,2 млн ₸", "120万 ₸".
    ///
    /// Used ONLY as a fallback by `FormattedAmountText` when the full amount does not fit
    /// its container (see `AmountDisplayPolicy.adaptive`). Never call it to pre-shorten an
    /// amount by hand: a value that fits must always render in full.
    ///
    /// The unit names come from the system compact notation, so they follow the reader's
    /// locale — including languages that group by 10 000 rather than 1 000 (ja 万, ko 억).
    /// A hand-rolled K/M table produces wrong magnitudes there, which is exactly the case
    /// this is meant to serve (currencies counted in hundreds of millions).
    ///
    /// - Parameter maxFractionDigits: `1` → "1.2M", `0` → "1M".
    /// - Parameter locale: injectable for tests; defaults to the reader's locale.
    public static func formatCurrencyCompact(
        _ amount: Double,
        currency: String,
        maxFractionDigits: Int = 1,
        locale: Locale = .current,
        configuration: AmountDisplayConfiguration = .shared
    ) -> String {
        attachSymbol(
            formatCompactNumber(amount, maxFractionDigits: maxFractionDigits, locale: locale, configuration: configuration),
            symbol: currencySymbol(for: currency),
            isNegative: amount < 0,
            position: configuration.symbolPosition
        )
    }

    /// The number of `formatCurrencyCompact` without a currency ("1.2M", "1,2 млн"), for a
    /// caller that puts its own unit after it. With `configuration.separatorsOverrideLocale`
    /// the configured separators replace the locale's ("1,2M"); otherwise the locale's stay.
    public static func formatCompactNumber(
        _ amount: Double,
        maxFractionDigits: Int = 1,
        locale: Locale = .current,
        configuration: AmountDisplayConfiguration = .shared
    ) -> String {
        let style = FloatingPointFormatStyle<Double>
            .number
            .notation(.compactName)
            .precision(.fractionLength(0...max(0, maxFractionDigits)))
            .locale(locale)
        return applyConfiguredSeparators(amount.formatted(style), locale: locale, configuration: configuration)
    }

    /// `text`, a number formatted in `locale`, with the locale's decimal and grouping
    /// separators swapped for the configured ones when `separatorsOverrideLocale` is on.
    public static func applyConfiguredSeparators(
        _ text: String,
        locale: Locale,
        configuration: AmountDisplayConfiguration = .shared
    ) -> String {
        guard configuration.separatorsOverrideLocale else { return text }
        let decimal = locale.decimalSeparator ?? "."
        let grouping = locale.groupingSeparator ?? ","
        // One pass, so "," -> "." and "." -> "," do not undo each other. A separator is swapped
        // only between two digits: the locale's grouping space can also stand between the
        // number and its unit word ("1,2 млн"), and that one is not a thousands separator.
        let pairs = [(decimal, configuration.decimalSeparator), (grouping, configuration.thousandsSeparator)]
        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            let previousIsDigit = index > text.startIndex && text[text.index(before: index)].isNumber
            var swapped = false
            if previousIsDigit {
                for (localeSeparator, configured) in pairs where text[index...].hasPrefix(localeSeparator) {
                    let next = text.index(index, offsetBy: localeSeparator.count)
                    guard next < text.endIndex, text[next].isNumber else { continue }
                    result += configured
                    index = next
                    swapped = true
                    break
                }
            }
            if !swapped {
                result.append(text[index])
                index = text.index(after: index)
            }
        }
        return result
    }
}
