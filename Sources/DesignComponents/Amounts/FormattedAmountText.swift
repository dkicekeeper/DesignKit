//
//  FormattedAmountText.swift
//  Tenra
//
//  Created on 2026-02-11
//  Universal reusable component for displaying formatted amounts with smart decimal handling
//

import SwiftUI
import DesignTokens
import DesignSupport

/// How an amount behaves when its container is too narrow for the full number.
public enum AmountDisplayPolicy {
    /// Always the full number. Truncation/scaling is the caller's problem — use where
    /// the exact figure IS the content (amount editors, calculator display).
    case full
    /// Full number when it fits, abbreviated ("1,2 млн ₸") when it doesn't. Default:
    /// nothing changes visually anywhere the amount already fitted.
    case adaptive
    /// Always abbreviated (tight chrome: chart labels, badges).
    case compact
}

/// How the sign of an amount shows.
public enum AmountSign: Hashable, Sendable {
    /// As the number formats: a minus on negatives, nothing on positives. Default (1.x).
    case automatic
    /// "+" before a positive amount and "−" (U+2212) before a negative one: a change of money
    /// ("+5 000 ₸", "−1 200 ₸"). Zero has no sign.
    case always
    /// No sign: the absolute value.
    case never
}

/// What follows the number.
public enum AmountCurrencyDisplay: Hashable, Sendable {
    /// The currency's symbol: "1 200 ₸". Default.
    case symbol
    /// The ISO code: "1 200 USD", for foreign currencies or symbols shared by several ($).
    case code
    /// An SF Symbol instead of a currency: points, miles, bonuses ("1 200 ★").
    case systemImage(String)
    /// The number alone, when a header already names the currency.
    case numberOnly
}

/// Универсальный компонент для отображения денежных сумм с умной обработкой дробной части
///
/// Логика отображения:
/// - Если сотые = 0 и showDecimalsWhenZero = false → не показывает дробную часть (1000 ₸)
/// - Если сотые > 0 → показывает с прозрачностью decimalOpacity (1000.50 ₸)
/// - Если showDecimalsWhenZero = true → всегда показывает (1000.00 ₸)
///
/// Overflow: see `AmountDisplayPolicy`. VoiceOver always reads the FULL amount, whichever
/// variant is drawn — an abbreviation is a layout concession, not a change of value.
///
/// Under `.amountsHidden()` it draws "•••• ₸" (the unit stays, the number and sign
/// go) and VoiceOver reads "Hidden amount" (key `amount.hidden`).
public struct FormattedAmountText: View {
    let amount: Double
    let currency: String
    let prefix: String
    let fontSize: Font
    let fontWeight: Font.Weight
    let color: Color
    let showDecimalsWhenZero: Bool
    let decimalOpacity: Double
    let policy: AmountDisplayPolicy
    let sign: AmountSign
    let currencyDisplay: AmountCurrencyDisplay

    @Environment(\.amountsHidden) private var isHidden

    /// Инициализатор с полным набором параметров
    ///
    /// - Parameters:
    ///   - prefix: Text before the number. With `sign` other than `.automatic`, it follows
    ///     the sign.
    ///   - sign: `.always` for a change of money ("+5 000 ₸", "−1 200 ₸"), `.never` for the
    ///     absolute value.
    ///   - currencyDisplay: `.code` ("1 200 USD"), `.systemImage` (points), `.numberOnly`.
    public init(
        amount: Double,
        currency: String,
        prefix: String = "",
        fontSize: Font = AppTypography.body,
        fontWeight: Font.Weight = .semibold,
        color: Color = .primary,
        showDecimalsWhenZero: Bool = AmountDisplayConfiguration.shared.showDecimalsWhenZero,
        decimalOpacity: Double = AmountDisplayConfiguration.shared.decimalOpacity,
        policy: AmountDisplayPolicy = .adaptive,
        sign: AmountSign = .automatic,
        currencyDisplay: AmountCurrencyDisplay = .symbol
    ) {
        self.amount = amount
        self.currency = currency
        self.prefix = prefix
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.color = color
        self.showDecimalsWhenZero = showDecimalsWhenZero
        self.decimalOpacity = decimalOpacity
        self.policy = policy
        self.sign = sign
        self.currencyDisplay = currencyDisplay
    }

    /// The caller's style through `AppTypography.numbers`, the one place amounts' figures
    /// are styled (proportional since 3.3.0).
    private var numberFont: Font { AppTypography.numbers(fontSize) }

    // MARK: - Sign and unit

    /// The number drawn: the absolute value when the sign is drawn separately (or not at all).
    private var displayAmount: Double {
        sign == .automatic ? amount : abs(amount)
    }

    /// The sign, then the caller's prefix.
    private var leadingText: String {
        switch sign {
        case .automatic, .never:
            return prefix
        case .always:
            if amount > 0 { return "+" + prefix }
            if amount < 0 { return "\u{2212}" + prefix }
            return prefix
        }
    }

    /// The unit as plain text (symbol, code), for lengths and VoiceOver; `nil` for an image or
    /// no unit.
    private var unitString: String? {
        switch currencyDisplay {
        case .symbol: return Formatting.currencySymbol(for: currency)
        case .code: return currency.uppercased()
        case .systemImage, .numberOnly: return nil
        }
    }

    /// " ₸", " USD", " ★" or nothing, styled like the number.
    private var unitRun: Text? {
        let unit: Text
        switch currencyDisplay {
        case .symbol, .code:
            guard let unitString else { return nil }
            unit = Text(" " + unitString)
        case .systemImage(let name):
            unit = Text(" \(Image(systemName: name))")
        case .numberOnly:
            return nil
        }
        return unit.font(numberFont).fontWeight(fontWeight).foregroundStyle(color)
    }

    /// `run` followed by the unit, as one `Text`.
    private func withUnit(_ run: Text) -> Text {
        guard let unitRun else { return run }
        return Text("\(run)\(unitRun)")
    }

    private var formattedParts: (integer: String, decimal: String, symbol: String) {
        let symbol = Formatting.currencySymbol(for: currency)
        let numberFormatter = AmountDisplayConfiguration.formatter

        let formatted = numberFormatter.string(from: NSNumber(value: displayAmount)) ?? String(format: "%.2f", displayAmount)

        // Разделяем на целую и дробную части
        let components = formatted.split(separator: Character(AmountDisplayConfiguration.shared.decimalSeparator))
        let integerPart = String(components.first ?? "0")
        let decimalPart = components.count > 1 ? String(components[1]) : "00"

        return (integerPart, decimalPart, symbol)
    }

    private var shouldShowDecimal: Bool {
        // Если showDecimalsWhenZero = true, всегда показываем
        if showDecimalsWhenZero {
            return true
        }
        // Иначе показываем только если есть дробная часть
        return amount.truncatingRemainder(dividingBy: 1) != 0
    }

    /// Single concatenated `Text` (one layout unit) so `.minimumScaleFactor` / line
    /// limits scale the whole amount uniformly — rendering the integer, decimal and
    /// symbol as separate `Text`s let each run scale independently (only the integer
    /// shrank while the decimal & symbol stayed full size). The reduced decimal opacity
    /// is preserved by colouring that run separately.
    private var composedText: Text {
        let parts = formattedParts

        // Built by interpolating styled `Text` runs into one `Text`. `Text.+` does the same
        // thing but was deprecated in iOS 26; interpolating a `Text` value preserves that
        // run's own font/weight/foregroundStyle, so the decimal run keeps its reduced
        // opacity exactly as before. Still ONE Text — that is what makes
        // `.minimumScaleFactor` scale the whole amount uniformly (see comment above).
        let integerRun = Text(leadingText + parts.integer)
            .font(numberFont).fontWeight(fontWeight).foregroundStyle(color)
        let decimalRun = Text(AmountDisplayConfiguration.shared.decimalSeparator + parts.decimal)
            .font(numberFont).fontWeight(fontWeight).foregroundStyle(color.opacity(decimalOpacity))

        // Runs side by side in one interpolation, as in 1.x (no nested Text).
        switch (shouldShowDecimal, unitRun) {
        case (true, let unit?): return Text("\(integerRun)\(decimalRun)\(unit)")
        case (true, nil): return Text("\(integerRun)\(decimalRun)")
        case (false, let unit?): return Text("\(integerRun)\(unit)")
        case (false, nil): return integerRun
        }
    }

    /// "•••• ₸": the number and sign hidden, the unit kept.
    private var hiddenText: Text {
        withUnit(Text(verbatim: Formatting.hiddenAmount()).font(numberFont).fontWeight(fontWeight).foregroundStyle(color))
    }

    // MARK: - Compact variants

    /// Abbreviated string for `digits` fraction digits, as one styled `Text`.
    /// No dimmed decimal run here: in "1,2 млн" the digit after the separator is a
    /// significant figure, not a cents tail.
    private func compactText(digits: Int) -> Text {
        if currencyDisplay == .symbol {
            // One run, as in 1.x.
            return Text(leadingText + Formatting.formatCurrencyCompact(displayAmount, currency: currency, maxFractionDigits: digits))
                .font(numberFont).fontWeight(fontWeight).foregroundStyle(color)
        }
        return withUnit(
            Text(leadingText + Formatting.formatCompactNumber(displayAmount, maxFractionDigits: digits))
                .font(numberFont).fontWeight(fontWeight).foregroundStyle(color)
        )
    }

    /// Fallback candidate for `ViewThatFits`, or the full text when abbreviating wouldn't
    /// actually help.
    ///
    /// Compact unit names are localized words, so "10 тыс. ₸" is LONGER than "10 000 ₸";
    /// swapping in a longer string would overflow harder, not less. Falling back to the
    /// full text keeps every `ViewThatFits` slot filled — an `if` here would leave an
    /// `EmptyView` candidate, which always "fits" and would render nothing at all.
    private func candidate(digits: Int) -> Text {
        let parts = formattedParts
        // As in 1.x: the full length counts the unit without its space, the compact one with it.
        let unit = unitString ?? ""
        let fullLength = (leadingText + parts.integer + unit).count
        let compactLength = (leadingText + Formatting.formatCompactNumber(displayAmount, maxFractionDigits: digits)).count
            + (unit.isEmpty ? 0 : unit.count + 1)
        guard compactLength < fullLength else { return composedText }
        return compactText(digits: digits)
    }

    /// Full amount, always — VoiceOver must not lose precision to a layout decision.
    private var accessibilityText: String {
        if isHidden {
            return String(localized: "amount.hidden", defaultValue: "Hidden amount")
        }
        switch currencyDisplay {
        case .symbol:
            return leadingText + Formatting.formatCurrencySmart(displayAmount, currency: currency, showDecimalsWhenZero: showDecimalsWhenZero)
        case .code, .systemImage, .numberOnly:
            let number = AmountDisplayConfiguration.formatter.string(from: NSNumber(value: displayAmount))
                ?? String(format: "%.2f", displayAmount)
            return leadingText + number + (unitString.map { " " + $0 } ?? "")
        }
    }

    public var body: some View {
        Group {
            if isHidden {
                hiddenText.lineLimit(1)
            } else {
                amountText
            }
        }
        .contentTransition(.numericText())
        .animation(AppAnimation.gentleSpring, value: amount)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var amountText: some View {
        Group {
            switch policy {
            case .full:
                composedText
            case .compact:
                compactText(digits: 1)
            case .adaptive:
                // First candidate that fits wins, so an amount with room to spare renders
                // exactly as it did before this policy existed.
                ViewThatFits(in: .horizontal) {
                    composedText.lineLimit(1)
                    candidate(digits: 1).lineLimit(1)
                    candidate(digits: 0).lineLimit(1)
                }
            }
        }
    }
}

// MARK: - Skeleton

/// Placeholder of an amount: `FormattedAmountText`, and the views that draw one
/// (`FormattedAmountView`, `ConvertedAmount`, `SpentBudgetText`, `RedactableAmount`).
/// A line of the amount's style, as tall as its text.
public struct FormattedAmountTextSkeleton: View {
    let font: Font
    let width: CGFloat

    public init(font: Font = AppTypography.body, width: CGFloat = 100) {
        self.font = font
        self.width = width
    }

    public var body: some View {
        SkeletonText(font, width: width)
            .skeletonLoadingLabel()
    }
}
