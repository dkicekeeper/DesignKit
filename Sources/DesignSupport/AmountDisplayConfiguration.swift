//
//  AmountDisplayConfiguration.swift
//  Tenra
//
//  Created on 2026-02-11
//  Centralized configuration for amount display formatting
//

import Foundation

/// Where the currency symbol stands relative to the number.
public enum CurrencySymbolPosition: Sendable, Hashable {
    /// "1 234 ₸" (default).
    case after
    /// "₸1 234": the sign stays first ("-₸1 234").
    case before
}

/// When the fraction of an amount shows.
public enum AmountFractions: Sendable, Hashable {
    /// Only when the amount has one: "1 234 ₸", "1 234.50 ₸" (default).
    case whenPresent
    /// Always: "1 234.00 ₸".
    case always
    /// Never, the amount rounds half up: "1 235 ₸". Under one (0 < |x| < 1) the cents stay,
    /// else 0.40 would read "0".
    case never
}

/// Централизованная конфигурация для отображения денежных сумм
public struct AmountDisplayConfiguration: Equatable, Sendable {
    /// Where the currency symbol stands.
    public var symbolPosition: CurrencySymbolPosition = .after

    /// When the fraction shows.
    public var fractions: AmountFractions = .whenPresent

    /// Whether the configured separators are the whole number format, the locale's own left
    /// out. `true` (8.8.1): amounts group by 3 from 1 000 on in every locale (es_ES and it_IT
    /// would write "1234,56" below 10 000, en_IN "12,34,567" without `secondaryGroupingSize`),
    /// and the configured decimal and thousands separators also replace the locale's in
    /// abbreviated numbers ("1,2 млн", chart axis labels). `false` (default) leaves grouping and
    /// abbreviated numbers to the locale; an app that lets the person pick separators sets `true`.
    public var separatorsOverrideLocale: Bool = false

    /// Size of the groups after the first one ("12,34,567"); `nil` groups every 3 digits.
    public var secondaryGroupingSize: Int? = nil

    /// Показывать ли сотые, если они равны нулю. A view of `fractions`: reads
    /// `fractions == .always`; `true` writes `.always`, `false` writes `.whenPresent`.
    public var showDecimalsWhenZero: Bool {
        get { fractions == .always }
        set { fractions = newValue ? .always : .whenPresent }
    }

    /// Прозрачность дробной части (0.0...1.0)
    public var decimalOpacity: Double = 0.5

    /// Разделитель тысяч
    public var thousandsSeparator: String = " "

    /// Десятичный разделитель
    public var decimalSeparator: String = "."

    /// Минимальное количество знаков после запятой
    public var minimumFractionDigits: Int = 2

    /// Максимальное количество знаков после запятой
    public var maximumFractionDigits: Int = 2

    public init() {}

    // MARK: - Shared Instance

    /// Глобальный экземпляр конфигурации. Thread-safe (8.8.1): a read returns a copy, a write
    /// (the whole value or one property) replaces it under a lock and drops the cached
    /// formatters, so the app can change it on the main thread while amounts are formatted
    /// on any other.
    public nonisolated static var shared: AmountDisplayConfiguration {
        get { store.configuration }
        set { store.configuration = newValue }
    }

    /// `shared` and the formatters made for it.
    nonisolated static let store = Store(AmountDisplayConfiguration())

    // MARK: - Cached Formatter

    /// Кэшированный форматтер `shared` — пересоздаётся только при изменении `shared`.
    /// Используй в hot path (List, ForEach и т.п.). Shared between threads: read it, never
    /// change it (`makeNumberFormatter()` gives one of your own).
    public nonisolated static var formatter: NumberFormatter {
        store.formatter(for: nil, wholeNumbers: false)
    }

    // MARK: - Factory

    /// Создаёт новый `NumberFormatter` на основе текущих настроек.
    /// В hot path используй `AmountDisplayConfiguration.formatter` — он кэширован.
    public nonisolated func makeNumberFormatter() -> NumberFormatter {
        makeNumberFormatter(systemLocale: nil)
    }

    /// `systemLocale` stands in for the device's locale, which a formatter follows without
    /// `separatorsOverrideLocale` (tests); `nil` leaves it to the system.
    nonisolated func makeNumberFormatter(systemLocale: Locale?) -> NumberFormatter {
        let f = NumberFormatter()
        // The locale first: setting it resets what it decides (separators, grouping sizes).
        if separatorsOverrideLocale {
            // The configured separators are the whole format: no locale's grouping rule (the
            // minimum grouping of es_ES, the lakh of en_IN) and plain digits and minus.
            f.locale = Locale(identifier: "en_US_POSIX")
        } else if let systemLocale {
            f.locale = systemLocale
        }
        f.numberStyle = .decimal
        f.groupingSeparator = thousandsSeparator
        f.decimalSeparator = decimalSeparator
        f.minimumFractionDigits = minimumFractionDigits
        f.maximumFractionDigits = maximumFractionDigits
        f.usesGroupingSeparator = true
        if separatorsOverrideLocale {
            f.groupingSize = 3
            f.secondaryGroupingSize = secondaryGroupingSize ?? 0
        } else if let secondaryGroupingSize {
            f.secondaryGroupingSize = secondaryGroupingSize
        }
        return f
    }

    /// Whether `amount` shows its fraction. `alwaysShow` is a caller's explicit
    /// "show decimals when zero".
    public nonisolated func showsFraction(for amount: Double, alwaysShow: Bool = false) -> Bool {
        if alwaysShow { return true }
        switch fractions {
        case .always: return true
        case .never: return amount != 0 && abs(amount) < 1
        case .whenPresent: return amount.truncatingRemainder(dividingBy: 1) != 0
        }
    }

    /// The number of `amount` as a string, with the sign and without a unit. Its formatter is
    /// cached by configuration (hot path), the whole-number one too.
    public nonisolated func formattedNumber(_ amount: Double, alwaysShowFraction: Bool = false) -> String? {
        let wholeNumbers = !showsFraction(for: amount, alwaysShow: alwaysShowFraction)
        return Self.store.formatter(for: self, wholeNumbers: wholeNumbers).string(from: NSNumber(value: amount))
    }

    // MARK: - Store

    /// A configuration and the formatters made from it, behind one lock: `shared` is written
    /// on the main thread while amounts are formatted on any thread. A formatter handed out is
    /// never changed afterwards.
    nonisolated final class Store: @unchecked Sendable {
        private let lock = NSLock()
        private var current: AmountDisplayConfiguration
        private var formatters: [FormatterKey: NumberFormatter] = [:]

        /// Different configurations kept at once before the cache starts over (the shared
        /// one and a few samples, such as a settings screen's previews).
        private static let capacity = 16

        init(_ configuration: AmountDisplayConfiguration) {
            current = configuration
        }

        /// The configuration; a write drops the cached formatters.
        var configuration: AmountDisplayConfiguration {
            get { lock.withLock { current } }
            set {
                lock.withLock {
                    current = newValue
                    formatters.removeAll()
                }
            }
        }

        /// The cached formatter of `configuration` (the store's own when `nil`): with its
        /// fraction digits, or with none for `wholeNumbers`, rounding half up.
        func formatter(for configuration: AmountDisplayConfiguration?, wholeNumbers: Bool) -> NumberFormatter {
            lock.withLock {
                let configuration = configuration ?? current
                let key = FormatterKey(configuration, wholeNumbers: wholeNumbers)
                if let cached = formatters[key] { return cached }
                if formatters.count >= Self.capacity { formatters.removeAll() }
                let made = configuration.makeNumberFormatter()
                if wholeNumbers {
                    made.minimumFractionDigits = 0
                    made.maximumFractionDigits = 0
                    made.roundingMode = .halfUp
                }
                formatters[key] = made
                return made
            }
        }
    }

    /// What a formatter is made from. Without `separatorsOverrideLocale` it follows the
    /// device's locale, so the locale is part of the key.
    struct FormatterKey: Hashable {
        let thousandsSeparator: String
        let decimalSeparator: String
        let minimumFractionDigits: Int
        let maximumFractionDigits: Int
        let secondaryGroupingSize: Int?
        let overridesLocale: Bool
        let systemLocale: String?
        let wholeNumbers: Bool

        init(_ configuration: AmountDisplayConfiguration, wholeNumbers: Bool) {
            thousandsSeparator = configuration.thousandsSeparator
            decimalSeparator = configuration.decimalSeparator
            minimumFractionDigits = configuration.minimumFractionDigits
            maximumFractionDigits = configuration.maximumFractionDigits
            secondaryGroupingSize = configuration.secondaryGroupingSize
            overridesLocale = configuration.separatorsOverrideLocale
            systemLocale = overridesLocale ? nil : Locale.current.identifier
            self.wholeNumbers = wholeNumbers
        }
    }
}
