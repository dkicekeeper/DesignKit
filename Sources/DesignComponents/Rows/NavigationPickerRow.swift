//
//  NavigationPickerRow.swift
//  DesignKit
//
//  A form row that opens a list to choose from (3.0.0): the title, the chosen value and a
//  chevron; the list shows every option with a check by the chosen one, and a search field when
//  there are many. For long lists a menu would make too tall (Dalada's fish species, the packing
//  list to start from). A few options → `MenuPickerRow`. `style: .list` (4.14.0) is the same
//  choice as a row of a `List`, as iOS Settings draws it (Tenra's voice language).
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A choice from a long list: the row shows the title and the chosen value; a tap pushes the
/// list. Needs a `NavigationStack` around it (an `EditSheetContainer` has one).
///
/// ```swift
/// NavigationPickerRow(icon: "fish", title: "Species", selection: $speciesID,
///                     options: species.map { (label: $0.name, value: $0.id) })
/// ```
///
/// Its skeleton is `UniversalRowSkeleton.menuPicker`: the same shape, a title and a value.
@available(*, deprecated, message: "Use UniversalRow(_:icon:config:accessory: .picker(_:options:)) (6.2.0).")
public struct NavigationPickerRow<T: Hashable>: View {
    /// Where the row lives.
    public enum Style: Sendable {
        /// A row of a form card (`FormSection`, `EditSheetContainer`): its own padding, a large
        /// icon, the value and a chevron of its own.
        case form
        /// A row of a `List` (4.14.0): the settings row (`RowConfiguration.settings`), a
        /// medium icon and the value in the small type; the list draws the chevron.
        case list
    }

    let icon: String?
    let title: String
    @Binding var selection: T
    let options: [(label: String, value: T)]
    let style: Style

    /// - Parameters:
    ///   - icon: An SF Symbol before the title, in the accent; none by default.
    ///   - options: Shown in this order; more than `NavigationPickerMetrics.searchThreshold`
    ///     get a search field.
    ///   - style: `.form` in a form card (the default), `.list` in a `List`.
    public init(
        icon: String? = nil,
        title: String,
        selection: Binding<T>,
        options: [(label: String, value: T)],
        style: Style = .form
    ) {
        self.icon = icon
        self.title = title
        self._selection = selection
        self.options = options
        self.style = style
    }


    public var body: some View {
        UniversalRow(title, icon: icon, config: style == .list ? .settings : .standard,
                     accessory: .picker($selection, options: options))
    }
}

public enum NavigationPickerMetrics {
    /// More options than this get a search field.
    public static let searchThreshold = 12
}

/// The list a `NavigationPickerRow` pushes: a checkmark row per option; a tap chooses it and
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
