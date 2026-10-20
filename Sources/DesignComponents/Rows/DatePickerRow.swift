//
//  DatePickerRow.swift
//  Tenra
//
//  Simplified date picker row - inline style only
//  For button-based selection, use DateButtons directly
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Date picker row with inline style
/// For button-based selection (Yesterday/Today/Calendar), use DateButtons directly
@available(*, deprecated, message: "Use UniversalRow(_:icon:accessory: .date(_:components:from:through:)) (6.2.0).")
public struct DatePickerRow: View {
    let icon: String?
    let title: String
    @Binding var selection: Date
    let displayedComponents: DatePickerComponents
    /// When set, the picker cannot select a date before this (3.0.0: a trip day from today on).
    let minDate: Date?
    /// When set, the picker cannot select a date after this (e.g. loan payments
    /// can't be future-dated — M-3).
    let maxDate: Date?

    public init(
        icon: String? = nil,
        title: String = String(localized: "common.startDate"),
        selection: Binding<Date>,
        displayedComponents: DatePickerComponents = .date,
        minDate: Date? = nil,
        maxDate: Date? = nil
    ) {
        self.icon = icon
        self.title = title
        self._selection = selection
        self.displayedComponents = displayedComponents
        self.minDate = minDate
        self.maxDate = maxDate
    }

    public var body: some View {
        UniversalRow(title, icon: icon,
                     accessory: .date($selection, components: displayedComponents, from: minDate, through: maxDate))
    }
}

// MARK: - Previews




