//
//  NavigationPickerRow.swift
//  DesignKit
//
//  A form row that opens a list to choose from (3.0.0): the title, the chosen value and a
//  chevron; the list shows every option with a check by the chosen one, and a search field when
//  there are many. For long lists a menu would make too tall (Dalada's fish species, the packing
//  list to start from). A few options → `MenuPickerRow`.
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
public struct NavigationPickerRow<T: Hashable>: View {
    let icon: String?
    let title: String
    @Binding var selection: T
    let options: [(label: String, value: T)]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - icon: An SF Symbol before the title, in the accent; none by default.
    ///   - options: Shown in this order; more than `NavigationPickerMetrics.searchThreshold`
    ///     get a search field.
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

    private var selectedLabel: String? {
        options.first { $0.value == selection }?.label
    }

    private var leadingIcon: IconConfig? {
        icon.map { .sfSymbol($0, color: AppColors.accent, size: AppIconSize.lg) }
    }

    public var body: some View {
        NavigationLink {
            NavigationPickerList(title: title, selection: $selection, options: options)
        } label: {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    // Accessibility sizes: the chosen value under the title, as in iOS Settings.
                    UniversalRow(config: .standard, leadingIcon: leadingIcon) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(title)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.Text.primary)
                            if let selectedLabel {
                                valueText(selectedLabel)
                            }
                        }
                    } trailing: {
                        DisclosureChevron()
                    }
                } else {
                    UniversalRow(config: .standard, leadingIcon: leadingIcon, title: title) {
                        HStack(spacing: AppSpacing.sm) {
                            if let selectedLabel {
                                valueText(selectedLabel)
                            }
                            DisclosureChevron()
                        }
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(selectedLabel ?? ""))
        .accessibilityAddTraits(.isButton)
    }

    private func valueText(_ label: String) -> some View {
        Text(label)
            .font(AppTypography.body)
            .foregroundStyle(AppColors.Text.secondary)
            .lineLimit(1)
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
                CheckmarkRow(option.label, isSelected: option.value == selection) {
                    selection = option.value
                    HapticManager.selection()
                    dismiss()
                }
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
