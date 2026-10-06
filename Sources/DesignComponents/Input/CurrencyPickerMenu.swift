//
//  CurrencyPickerMenu.swift
//  DesignKit
//
//  The currency of an amount as a chip that opens a menu: "₸ ⌄". The menu lists the given
//  currencies by name, the chosen one checked, and an optional "Customize…" action that
//  edits the list. Ported from Tenra's CurrencySelectorView; which currencies to offer
//  (account currencies + the user's quick picks) and the customize sheet stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "₸ ⌄": picks the currency of an amount.
///
/// ```swift
/// CurrencyPickerMenu(selection: $currency, currencies: ["KZT", "USD", "EUR"]) {
///     showsQuickPicks = true      // optional: the "Customize…" item
/// }
/// ```
public struct CurrencyPickerMenu: View {
    @Binding var selection: String
    let currencies: [String]
    let onCustomize: (() -> Void)?

    /// - Parameters:
    ///   - currencies: ISO codes; shown once each, sorted by the currency's name. Codes
    ///     `CurrencyInfo` does not know are left out.
    ///   - onCustomize: Adds "Customize…" (key `currency.customizeAction`) under a divider.
    public init(selection: Binding<String>, currencies: [String], onCustomize: (() -> Void)? = nil) {
        self._selection = selection
        self.currencies = currencies
        self.onCustomize = onCustomize
    }

    private var menuCurrencies: [CurrencyInfo] {
        Set(currencies)
            .compactMap { CurrencyInfo.find($0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public var body: some View {
        Menu {
            ForEach(menuCurrencies) { currency in
                Button {
                    selection = currency.code
                    HapticManager.selection()
                } label: {
                    HStack {
                        Text(verbatim: "\(currency.code) \(currency.symbol)")
                        Spacer()
                        if selection == currency.code {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            if let onCustomize {
                Divider()

                Button(action: onCustomize) {
                    Label(
                        String(localized: "currency.customizeAction", defaultValue: "Customize…"),
                        systemImage: "slider.horizontal.3"
                    )
                }
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Text(verbatim: Formatting.currencySymbol(for: selection))
                Image(systemName: "chevron.down")
                    .font(.system(size: AppIconSize.sm))
            }
            .filterChipStyle(isSelected: false)
        }
    }
}
