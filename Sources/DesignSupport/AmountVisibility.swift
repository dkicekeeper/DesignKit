//
//  AmountVisibility.swift
//  DesignKit
//
//  Hiding amounts on screen: with it on, FormattedAmountText, and every card, row and badge
//  built on it, shows "•••• ₸" instead of the number (for showing the app to someone, or a
//  screen recording). The host app keeps the switch (a setting, an eye button) and sets it
//  once near the root; DesignKit only draws it.
//

import SwiftUI

public extension EnvironmentValues {
    /// Hides amounts under this view: `FormattedAmountText` (and the cards, rows and badges
    /// built on it) draws "•••• ₸" and VoiceOver reads "Hidden amount". Amount inputs and chart
    /// axes are not hidden. Default `false`.
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
