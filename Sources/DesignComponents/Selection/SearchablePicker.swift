//
//  SearchablePicker.swift
//  DesignKit
//
//  Picking from a list too long to scan (8.9.0, benchmark round 4: Astryx's MultiSelector with
//  `hasSearch` and `hasCreate`, Polaris' Combobox, Atlassian's Select): the system search field
//  narrows the options as the person types, one or several are picked with the row's circle, and
//  when nothing matches a "Create “…”" row adds the typed name. Tenra's categories and
//  subcategories, Dalada's gear and places; the apps built these lists from
//  `UniversalRow(accessory: .checkmark)` by hand. The list of options and what "create" stores
//  stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// One option of a `SearchablePicker`.
public struct SearchablePickerOption<Value: Hashable>: Identifiable {
    public let value: Value
    public let title: String
    public let subtitle: String?
    public let systemImage: String?
    public let iconColor: Color?

    public var id: Value { value }

    /// - Parameters:
    ///   - subtitle: A line under the title; the search looks in it too.
    ///   - systemImage: A symbol before the title (a category's icon), in `iconColor`.
    public init(_ title: String, value: Value, subtitle: String? = nil, systemImage: String? = nil, iconColor: Color? = nil) {
        self.value = value
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconColor = iconColor
    }
}

/// A list to pick one option or several from, with the system search and "Create “…”".
///
/// ```swift
/// // One: the category of a transaction, the sheet closes on a pick.
/// NavigationStack {
///     SearchablePicker(categoryOptions, selection: $categoryID, dismissesOnSelection: true) { name in
///         store.addCategory(named: name).id        // nil: nothing is created
///     }
///     .navigationTitle("Category")
/// }
///
/// // Several: the gear of a trip.
/// SearchablePicker(gearOptions, selection: $gearIDs)
/// ```
///
/// It is a screen's content: put it in a `NavigationStack` (a pushed screen or a sheet with its
/// own stack), where the search field lives. The options stand in a `FormSection` card in the
/// order given; the search keeps those whose title or subtitle contains what is typed (any case,
/// any accents). With `onCreate`, a typed name no option has offers "Create “name”" first; the
/// app adds the option and returns its value, which is picked. With nothing to show, "Nothing
/// found". Strings: `picker.search`, `picker.create`, `picker.noResults`.
public struct SearchablePicker<Value: Hashable>: View {
    public typealias Option = SearchablePickerOption<Value>

    private enum Mode {
        case single(Binding<Value?>)
        case multiple(Binding<Set<Value>>)
    }

    let options: [Option]
    private let mode: Mode
    let prompt: String?
    let dismissesOnSelection: Bool
    let onCreate: ((String) -> Value?)?

    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    /// One option. A tap picks it; with `dismissesOnSelection` the screen closes too.
    /// - Parameters:
    ///   - prompt: The search field's placeholder ("Search" by default).
    ///   - onCreate: Adds an option named by what was typed and returns its value (nil: none was
    ///     added). Without it there is no "Create" row.
    public init(
        _ options: [Option],
        selection: Binding<Value?>,
        prompt: String? = nil,
        dismissesOnSelection: Bool = false,
        onCreate: ((String) -> Value?)? = nil
    ) {
        self.options = options
        self.mode = .single(selection)
        self.prompt = prompt
        self.dismissesOnSelection = dismissesOnSelection
        self.onCreate = onCreate
    }

    /// Several options. A tap picks or unpicks one.
    public init(
        _ options: [Option],
        selection: Binding<Set<Value>>,
        prompt: String? = nil,
        onCreate: ((String) -> Value?)? = nil
    ) {
        self.options = options
        self.mode = .multiple(selection)
        self.prompt = prompt
        self.dismissesOnSelection = false
        self.onCreate = onCreate
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                if matches.isEmpty && createName == nil {
                    EmptyState(icon: "magnifyingglass",
                               title: String(localized: "picker.noResults", defaultValue: "Nothing found"),
                               style: .compact)
                        .padding(.top, AppSpacing.xxl)
                } else {
                    FormSection {
                        if let name = createName {
                            UniversalRow(
                                String(localized: "picker.create", defaultValue: "Create “\(name)”"),
                                icon: "plus.circle.fill",
                                titleColor: AppColors.accent,
                                accessory: .action { create(name) }
                            )
                        }
                        ForEach(matches) { option in
                            UniversalRow(
                                option.title,
                                icon: option.systemImage,
                                iconColor: option.iconColor,
                                hint: option.subtitle,
                                accessory: .checkmark(isSelected: isSelected(option.value)) { pick(option.value) }
                            )
                        }
                    }
                }
            }
            .screenPadding()
            .padding(.vertical, AppSpacing.lg)
        }
        .searchable(text: $query, prompt: Text(verbatim: prompt ?? String(localized: "picker.search", defaultValue: "Search")))
        .animation(AppAnimation.smooth, value: query)
    }

    // MARK: - Search

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The options whose title or subtitle contains the query, in their order.
    private var matches: [Option] {
        Self.matching(options, query: trimmedQuery)
    }

    /// What "Create" would add: the query, when there is a way to create and no option is
    /// called that already.
    private var createName: String? {
        let name = trimmedQuery
        guard onCreate != nil, !name.isEmpty else { return nil }
        let taken = options.contains { $0.title.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
        return taken ? nil : name
    }

    /// The options a query keeps: every one for an empty query, else those whose title or
    /// subtitle contains it, ignoring case and accents.
    static func matching(_ options: [Option], query: String) -> [Option] {
        guard !query.isEmpty else { return options }
        return options.filter { option in
            option.title.localizedStandardContains(query)
                || (option.subtitle?.localizedStandardContains(query) ?? false)
        }
    }

    // MARK: - Picking

    private func isSelected(_ value: Value) -> Bool {
        switch mode {
        case .single(let selection): selection.wrappedValue == value
        case .multiple(let selection): selection.wrappedValue.contains(value)
        }
    }

    private func pick(_ value: Value) {
        switch mode {
        case .single(let selection):
            selection.wrappedValue = value
            if dismissesOnSelection { dismiss() }
        case .multiple(let selection):
            if selection.wrappedValue.contains(value) {
                selection.wrappedValue.remove(value)
            } else {
                selection.wrappedValue.insert(value)
            }
        }
    }

    private func create(_ name: String) {
        guard let value = onCreate?(name) else { return }
        query = ""
        pick(value)
    }
}

// MARK: - Skeleton

/// Placeholder of a `SearchablePicker` while its options load: a card of `rows` option rows,
/// each a symbol, a title and the circle of a choice.
public struct SearchablePickerSkeleton: View {
    let rows: Int

    public init(rows: Int = 6) {
        self.rows = rows
    }

    public var body: some View {
        FormSection {
            ForEach(0..<max(rows, 1), id: \.self) { _ in
                UniversalRowSkeleton(iconStyle: .circle(size: AppIconSize.lg), trailing: .selection)
            }
        }
        .screenPadding()
        .padding(.vertical, AppSpacing.lg)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
