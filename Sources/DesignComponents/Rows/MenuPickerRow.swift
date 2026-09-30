//
//  MenuPickerRow.swift
//  Tenra
//
//  Reusable menu picker row with icon, title, and compact menu selection
//  Universal component for all single-select scenarios
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Universal menu picker row for forms.
/// Shows `icon + title` on the left and a native `Menu` trigger (selected
/// label + chevron) on the right. Tapping the trigger opens an iOS menu with
/// the selectable options; iOS handles the open transition, checkmark on the
/// current selection, and dismissal.
///
/// The menu uses a `Picker` inside `Menu` — Apple's canonical pattern for a
/// single-select dropdown bound to a `Hashable` value. iOS renders the
/// options as native menu items with a built-in checkmark on the selected
/// row, so we don't draw the checkmark ourselves.
public struct MenuPickerRow<T: Hashable>: View {
    let icon: String?
    let title: String
    @Binding var selection: T
    let options: [(label: String, value: T)]

    public init(
        icon: String? = nil,
        title: String,
        selection: Binding<T>,
        options: [(label: String, value: T)]
    ) {
        self.icon = icon
        self.title = title
        self._selection = selection
        self.options = options
    }

    public var body: some View {
        UniversalRow(
            config: .standard,
            leadingIcon: icon.map { .sfSymbol($0, color: AppColors.accent, size: AppIconSize.lg) }
        ) {
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
        } trailing: {
            Menu {
                Picker(title, selection: $selection) {
                    ForEach(options, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
            } label: {
                if let selectedOption = options.first(where: { $0.value == selection }) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(selectedOption.label)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - Convenience Initializers


// Domain convenience inits (RecurringFrequency, RecurringOption, LoanType, ReminderOption)
// stay in the host app as `extension MenuPickerRow where T == ...`.
