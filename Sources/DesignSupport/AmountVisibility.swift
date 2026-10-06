//
//  AmountVisibility.swift
//  DesignKit
//
//  Hiding amounts on screen: with it on, FormattedAmountText, and every card, row and badge
//  built on it, shows "•••• ₸" instead of the number (for showing the app to someone, or a
//  screen recording). The host app keeps the switch (a setting, an eye button) and sets it
//  once near the root; DesignKit only draws it. An amount the app formats into its own text
//  reads the same environment value and shows `Formatting.hiddenAmount(currency:)`.
//

import SwiftUI

public extension EnvironmentValues {
    /// Hides amounts under this view: `FormattedAmountText` (and the cards, rows and badges
    /// built on it) and the amounts in chart legends and tap pills draw "•••• ₸", and VoiceOver
    /// reads "Hidden amount". Amount inputs and chart axes are not hidden. Default `false`.
    ///
    /// An amount in the app's own text reads it too:
    ///
    /// ```swift
    /// @Environment(\.amountsHidden) private var amountsHidden
    ///
    /// Text(amountsHidden
    ///      ? Formatting.hiddenAmount(currency: code)
    ///      : Formatting.formatCurrencySmart(total, currency: code))
    /// ```
    @Entry var amountsHidden: Bool = false
}

public extension View {
    /// Hides the amounts in this view and its children, or shows them again.
    ///
    /// ```swift
    /// @AppStorage("hidesAmounts") private var hidesAmounts = false
    ///
    /// ContentView()
    ///     .amountsHidden(hidesAmounts)
    /// ```
    func amountsHidden(_ hidden: Bool = true) -> some View {
        environment(\.amountsHidden, hidden)
    }
}

public extension Formatting {
    /// What a hidden amount shows: "••••", then the currency's symbol when one is given
    /// ("•••• ₸"). For an amount the app writes into its own text under `.amountsHidden()`;
    /// `FormattedAmountText` hides itself.
    static func hiddenAmount(currency: String? = nil) -> String {
        let mark = "••••"
        guard let currency, !currency.isEmpty else { return mark }
        return mark + " " + currencySymbol(for: currency)
    }
}
