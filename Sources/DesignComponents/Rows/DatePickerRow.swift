//
//  DatePickerRow.swift
//  Tenra
//
//  Simplified date picker row - inline style only
//  For button-based selection, use DateButtonsView directly
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Date picker row with inline style
/// For button-based selection (Yesterday/Today/Calendar), use DateButtonsView directly
public struct DatePickerRow: View {
    let icon: String?
    let title: String
    @Binding var selection: Date
    let displayedComponents: DatePickerComponents
    /// When set, the picker cannot select a date after this (e.g. loan payments
    /// can't be future-dated — M-3).
    let maxDate: Date?

    public init(
        icon: String? = nil,
        title: String = String(localized: "common.startDate"),
        selection: Binding<Date>,
        displayedComponents: DatePickerComponents = .date,
        maxDate: Date? = nil
    ) {
        self.icon = icon
        self.title = title
        self._selection = selection
        self.displayedComponents = displayedComponents
        self.maxDate = maxDate
    }

    public var body: some View {
        UniversalRow(
            config: .standard,
            leadingIcon: icon.map { .sfSymbol($0, color: AppColors.accent, size: AppIconSize.lg) }
        ) {
            if let maxDate {
                DatePicker(
                    title,
                    selection: $selection,
                    in: ...maxDate,
                    displayedComponents: displayedComponents
                )
            } else {
                DatePicker(
                    title,
                    selection: $selection,
                    displayedComponents: displayedComponents
                )
            }
        } trailing: {
            EmptyView()
        }
    }
}

// MARK: - Previews




