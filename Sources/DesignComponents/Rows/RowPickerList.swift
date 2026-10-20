//
//  RowPickerList.swift
//  DesignKit
//
//  The list `UniversalRow(accessory: .picker)` pushes (3.0.0's NavigationPickerRow, a row
//  of `UniversalRow` since 7.0.0): a checkmark row per option, a search field past
//  `NavigationPickerMetrics.searchThreshold`.
//

import SwiftUI
import DesignTokens
import DesignSupport

public enum NavigationPickerMetrics {
    /// More options than this get a search field.
    public static let searchThreshold = 12
}

/// The list a picker row (`accessory: .picker`) pushes: a checkmark row per option; a tap chooses it and
/// goes back.
struct NavigationPickerList<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [(label: String, value: T)]

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var shown: [(label: String, value: T)] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return options }
        return options.filter { $0.label.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        List {
            ForEach(shown, id: \.value) { option in
                // The row ticks as it chooses.
                UniversalRow(option.label, config: .settings,
                             accessory: .checkmark(isSelected: option.value == selection) {
                                 selection = option.value
                                 dismiss()
                             })
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .modifier(NavigationPickerSearch(isEnabled: options.count > NavigationPickerMetrics.searchThreshold, query: $query))
    }
}

private struct NavigationPickerSearch: ViewModifier {
    let isEnabled: Bool
    @Binding var query: String

    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(text: $query)
        } else {
            content
        }
    }
}
