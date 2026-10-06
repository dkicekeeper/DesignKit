//
//  CheckmarkRow.swift
//  DesignKit
//
//  A row you pick from a list: an optional icon, the title, an optional value on the trailing
//  side, and the accent checkmark when it is the picked one. The rows of a filter or choice
//  sheet ("All accounts", each account, each category). Ported from Tenra's account,
//  category and time filters; the sheets themselves (lists of the app's models) stay there.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "Kaspi Gold ……… 120 000 ₸ ✓": a row of a choice list, built on `UniversalRow(.settings)`.
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
public struct CheckmarkRow: View {
    let title: String
    let icon: IconConfig?
    let value: String?
    let isSelected: Bool
    let action: () -> Void

    /// - Parameters:
    ///   - icon: The leading icon; none by default.
    ///   - value: Text on the trailing side, before the checkmark (a balance, a count).
    public init(
        _ title: String,
        icon: IconConfig? = nil,
        value: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.value = value
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        UniversalRow(config: .settings, leadingIcon: icon) {
            HStack(spacing: 0) {
                Text(title)
                    .font(AppTypography.h4)
                    .fontWeight(.medium)

                if let value {
                    Spacer()

                    Text(value)
                        .font(AppTypography.h4)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        } trailing: {
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(AppColors.accent)
            }
        }
        .selectableRow(isSelected: isSelected) {
            HapticManager.selection()
            action()
        }
    }
}
