//
//  DateRangePickerSheet.swift
//  DesignKit
//
//  A period of days picked on two calendars (2.9.0): "From" on the first, "To" on the second; the
//  start never passes the end. Cancel or Apply. For a custom period of a filter, a trip's dates.
//  Ported from Tenra's CustomPeriodPickerSheet; the filter it sets stays in Tenra.
//

import SwiftUI
import DesignTokens

/// Two graphical calendars for a range of days, in a sheet.
///
/// ```swift
/// .sheet(isPresented: $picking) {
///     DateRangePickerSheet(range: filter.range) { range in
///         filter.setCustomRange(range)
///         picking = false
///     }
/// }
/// ```
///
/// Apply hands the range to `onApply` (both ends are days, from the calendars); Cancel dismisses.
public struct DateRangePickerSheet: View {
    let title: String
    let fromTitle: String
    let toTitle: String
    let onApply: (ClosedRange<Date>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var range: ClosedRange<Date>

    /// - Parameters:
    ///   - range: The range the calendars start on.
    ///   - title, fromTitle, toTitle: The sheet's title and each calendar's label.
    public init(
        range: ClosedRange<Date>,
        title: String = String(localized: "timeFilter.customPeriod", defaultValue: "Custom period"),
        fromTitle: String = String(localized: "timeFilter.from", defaultValue: "From"),
        toTitle: String = String(localized: "timeFilter.to", defaultValue: "To"),
        onApply: @escaping (ClosedRange<Date>) -> Void
    ) {
        self.title = title
        self.fromTitle = fromTitle
        self.toTitle = toTitle
        self.onApply = onApply
        self._range = State(initialValue: range)
    }

    /// The start; moving it past the end moves the end along.
    private var start: Binding<Date> {
        Binding(
            get: { range.lowerBound },
            set: { newStart in range = newStart...max(newStart, range.upperBound) }
        )
    }

    /// The end; moving it before the start moves the start along.
    private var end: Binding<Date> {
        Binding(
            get: { range.upperBound },
            set: { newEnd in range = min(range.lowerBound, newEnd)...newEnd }
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    DatePicker(fromTitle, selection: start, in: ...range.upperBound, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding(.horizontal, AppSpacing.md)

                    Divider()

                    DatePicker(toTitle, selection: end, in: range.lowerBound..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding(.horizontal, AppSpacing.md)
                }
                .padding(.vertical, AppSpacing.md)
            }
            .navigationTitle(Text(verbatim: title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.apply", defaultValue: "Apply")) {
                        onApply(range)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
