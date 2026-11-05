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
public struct AmountDisplayConfiguration: Equatable {
    /// Where the currency symbol stands.
    public var symbolPosition: CurrencySymbolPosition = .after

    /// When the fraction shows.
    public var fractions: AmountFractions = .whenPresent

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

    /// Глобальный экземпляр конфигурации.
    /// Замена всего экземпляра или изменение любого свойства
    /// автоматически инвалидирует кэшированный форматтер.
    public nonisolated(unsafe) static var shared = AmountDisplayConfiguration() {
        didSet { _cachedFormatter = nil }
    }

    // MARK: - Cached Formatter

    /// Кэшированный форматтер — пересоздаётся только при изменении `shared`.
    /// Используй в hot path (List, ForEach и т.п.).
    private nonisolated(unsafe) static var _cachedFormatter: NumberFormatter?

    public nonisolated static var formatter: NumberFormatter {
        if let cached = _cachedFormatter { return cached }
        let f = shared.makeNumberFormatter()
        _cachedFormatter = f
        return f
    }

    // MARK: - Factory

    /// Создаёт новый `NumberFormatter` на основе текущих настроек.
    /// В hot path используй `AmountDisplayConfiguration.formatter` — он кэширован.
    public nonisolated func makeNumberFormatter() -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = thousandsSeparator
        f.decimalSeparator = decimalSeparator
        f.minimumFractionDigits = minimumFractionDigits
        f.maximumFractionDigits = maximumFractionDigits
        f.usesGroupingSeparator = true
        if let secondaryGroupingSize { f.secondaryGroupingSize = secondaryGroupingSize }
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

    /// The number of `amount` as a string, with the sign and without a unit. The cached
    /// formatter serves `shared` (hot path); another configuration builds its own.
    public nonisolated func formattedNumber(_ amount: Double, alwaysShowFraction: Bool = false) -> String? {
        let formatter: NumberFormatter
        if showsFraction(for: amount, alwaysShow: alwaysShowFraction) {
            formatter = self == Self.shared ? Self.formatter : makeNumberFormatter()
        } else {
            formatter = makeNumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            formatter.roundingMode = .halfUp
        }
        return formatter.string(from: NSNumber(value: amount))
    }
}
