//
//  ChipPicker.swift
//  DesignKit
//
//  Single choice from a horizontal row of chips, with an optional caption above.
//  Tapping the selected chip clears the choice. From Dalada's ChipRow (check-in form:
//  weather, water level, bite).
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Horizontally scrolling chips; one or none selected.
///
/// ```swift
/// @State private var weather: Weather?
/// ChipPicker("Weather", options: Weather.allCases, selection: $weather) { $0.title }
/// ```
///
/// Chips use `filterChipStyle(isSelected:)`. For a fixed 2–4 way switch use
/// `SegmentedPickerView`; for a filter that opens a menu use `UniversalFilterButton`.
public struct ChipPicker<Option: Hashable>: View {
    let title: String?
    let options: [Option]
    @Binding var selection: Option?
    let label: (Option) -> String

    public init(
        _ title: String? = nil,
        options: [Option],
        selection: Binding<Option?>,
        label: @escaping (Option) -> String
    ) {
        self.title = title
        self.options = options
        self._selection = selection
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let title {
                Text(verbatim: title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selection = selection == option ? nil : option
                            HapticManager.selection()
                        } label: {
                            Text(verbatim: label(option))
                        }
                        .buttonStyle(.plain)
                        .filterChipStyle(isSelected: selection == option)
                        .accessibilityAddTraits(selection == option ? .isSelected : [])
                    }
                }
                .padding(.vertical, AppSpacing.xxs)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
