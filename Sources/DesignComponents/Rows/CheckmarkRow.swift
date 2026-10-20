//
//  CheckmarkRow.swift
//  DesignKit
//
//  A row you pick from a list: an optional icon, the title, an optional value on the trailing
//  side, and a `SelectionIndicator` (5.2.0): the accent filled check on the picked one, an
//  empty circle on the others (a bare checkmark on the picked one before). The rows of a filter
//  or choice sheet ("All accounts", each account, each category). Ported from Tenra's account,
//  category and time filters; the sheets themselves (lists of the app's models) stay there.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "Kaspi Gold ……… 120 000 ₸ ◉": a row of a choice list, built on `UniversalRow(.settings)`.
///
/// ```swift
/// CheckmarkRow("All accounts", isSelected: selection == nil) { selection = nil }
/// CheckmarkRow(account.name,
///              icon: .custom(source: account.icon, style: .roundedSquare(size: AppIconSize.xl)),
///              value: balanceText,
///              isSelected: selection == account.id) { selection = account.id }
/// ```
///
/// A tap plays the selection haptic, then runs `action`. VoiceOver hears the row as a button
/// and "Selected" on the picked one.
@available(*, deprecated, message: "Use UniversalRow(_:leadingIcon:value:config:accessory: .checkmark(isSelected:action:)) (6.2.0).")
public struct CheckmarkRow: View {
    let title: String
    let icon: IconConfig?
    let value: String?
    let isSelected: Bool
    let config: RowConfiguration
    let action: () -> Void

    /// - Parameters:
    ///   - icon: The leading icon; none by default.
    ///   - value: Text on the trailing side, before the indicator (a balance, a count).
    ///   - config: `.settings` (default) for a `List` row, which pads it; `.standard` in a
    ///     `FormSection` card (3.0.0).
    public init(
        _ title: String,
        icon: IconConfig? = nil,
        value: String? = nil,
        isSelected: Bool,
        config: RowConfiguration = .settings,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.value = value
        self.isSelected = isSelected
        self.config = config
        self.action = action
    }

    public var body: some View {
        UniversalRow(title, leadingIcon: icon, value: value, config: config,
                     accessory: .checkmark(isSelected: isSelected, action: action))
    }
}
