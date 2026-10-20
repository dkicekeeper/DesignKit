//
//  ToggleSettingsRow.swift
//  DesignKit
//
//  Settings row with a switch — the third settings row next to NavigationSettingsRow
//  and ActionSettingsRow, on the same UniversalRow `.settings` layout. (Material: Switch
//  list item; Fluent: Switch cell; HIG: toggle in a list.)
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Icon + title (+ optional hint) + switch. The icon is optional (3.0.0): a form row has none.
/// `config` is `.settings` (a `List` row, no side padding); in a `FormSection` card pass
/// `.standard`, which pads it like the rows around it (3.0.0).
///
/// ```swift
/// ToggleSettingsRow(icon: "bell", title: "Reminders", isOn: $remindersOn)
/// ToggleSettingsRow(title: "Released", isOn: $released)
/// ToggleSettingsRow(icon: "location", title: "Share location",
///                   hint: "Friends see your trip on the map", isOn: $shares)
/// ```
///
/// VoiceOver focuses the switch itself (labelled with the title, hinted with `hint`), so a
/// double tap toggles it; the visible title is not read twice.
@available(*, deprecated, message: "Use UniversalRow(_:icon:hint:config:accessory: .toggle(_:)) (6.2.0).")
public struct ToggleSettingsRow: View {
    let icon: String?
    let title: String
    let hint: String?
    let iconColor: Color
    let config: RowConfiguration
    @Binding var isOn: Bool

    public init(
        icon: String? = nil,
        title: String,
        hint: String? = nil,
        iconColor: Color = AppColors.accent,
        config: RowConfiguration = .settings,
        isOn: Binding<Bool>
    ) {
        self.icon = icon
        self.title = title
        self.hint = hint
        self.iconColor = iconColor
        self.config = config
        self._isOn = isOn
    }

    public var body: some View {
        UniversalRow(title, icon: icon, iconColor: iconColor, hint: hint, config: config, accessory: .toggle($isOn))
    }
}
