//
//  SelectionIndicator.swift
//  Tenra
//
//  Leading circle that shows whether a row is picked in a bulk-selection list.
//
//  Why this exists instead of `List(selection:)`: every management row in this app is
//  rooted in a `Button` (AccountRow, CategoryRow, SubcategoryRow), and a Button row
//  consumes the tap before the List's selection machinery sees it. The symptom was a
//  selection mode where nothing highlighted and nothing toggled, while "select all"
//  silently filled the set. Selection is therefore driven by the row's own action, and
//  shown by this indicator.
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct SelectionIndicator: View {

    let isSelected: Bool
    let tint: Color

    /// - Parameter tint: colour of the filled check (default accent; e.g. `AppColors.success`
    ///   for a done checklist item, `AppColors.Text.tertiary` for a disabled, already-owned one).
    public init(
        isSelected: Bool,
        tint: Color = AppColors.accent
    ) {
        self.isSelected = isSelected
        self.tint = tint
    }

    public var body: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title3)
            .foregroundStyle(isSelected ? tint : AppColors.Text.secondary)
            .symbolEffect(.bounce, value: isSelected)
            // The row itself carries the label and the `.isSelected` trait.
            .accessibilityHidden(true)
    }
}
