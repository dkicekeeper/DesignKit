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

/// Icon + title (+ optional hint) + switch.
///
/// ```swift
/// ToggleSettingsRow(icon: "bell", title: "Reminders", isOn: $remindersOn)
/// ToggleSettingsRow(icon: "location", title: "Share location",
///                   hint: "Friends see your trip on the map", isOn: $shares)
/// ```
///
/// VoiceOver focuses the switch itself (labelled with the title, hinted with `hint`), so a
/// double tap toggles it; the visible title is not read twice.
public struct ToggleSettingsRow: View {
    let icon: String
    let title: String
    let hint: String?
    let iconColor: Color
    @Binding var isOn: Bool

    public init(
        icon: String,
        title: String,
        hint: String? = nil,
        iconColor: Color = AppColors.accent,
        isOn: Binding<Bool>
    ) {
        self.icon = icon
        self.title = title
        self.hint = hint
        self.iconColor = iconColor
        self._isOn = isOn
    }

    public var body: some View {
        UniversalRow(
            config: .settings,
            leadingIcon: .sfSymbol(icon, color: iconColor, size: AppIconSize.md),
            hint: hint
        ) {
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.Text.primary)
                .accessibilityHidden(true)
        } trailing: {
            Toggle(isOn: $isOn) {
                Text(title)
            }
            .labelsHidden()
            .tint(AppColors.accent)
            .accessibilityHint(hint.map { Text($0) } ?? Text(verbatim: ""))
            .onChange(of: isOn) { _, _ in HapticManager.selection() }
        }
    }
}
