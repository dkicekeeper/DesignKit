//
//  ChipPicker.swift
//  DesignKit
//
//  A horizontal row of chips with an optional caption above: one-or-none selection
//  (Dalada's check-in conditions) or several at once (filters, 0.6.0 — Material filter
//  chips, Carbon / Atlassian tag groups). Tapping a selected chip clears it.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Horizontally scrolling chips.
///
/// ```swift
/// // One or none
/// ChipPicker("Weather", options: Weather.allCases, selection: $weather) { $0.title }
/// // Several, with icons
/// ChipPicker(options: PlaceType.allCases, selection: $types,
///            systemImage: { $0.systemImage }) { $0.title }
/// ```
///
/// Chips use `filterChipStyle(isSelected:)` and carry the `.isSelected` trait. A fixed
/// 2–4 way switch → `SegmentedPickerView`; a filter that opens a menu → `UniversalFilterButton`.
public struct ChipPicker<Option: Hashable>: View {
    private enum Selection {
        case single(Binding<Option?>)
        case multiple(Binding<Set<Option>>)
    }

    let title: String?
    let options: [Option]
    private let selection: Selection
    let systemImage: ((Option) -> String?)?
    let label: (Option) -> String

    /// One or none: `selection` is `nil` when nothing is picked.
    public init(
        _ title: String? = nil,
        options: [Option],
        selection: Binding<Option?>,
        systemImage: ((Option) -> String?)? = nil,
        label: @escaping (Option) -> String
    ) {
        self.title = title
        self.options = options
        self.selection = .single(selection)
        self.systemImage = systemImage
        self.label = label
    }

    /// Several at once: each tap adds or removes the option.
    public init(
        _ title: String? = nil,
        options: [Option],
        selection: Binding<Set<Option>>,
        systemImage: ((Option) -> String?)? = nil,
        label: @escaping (Option) -> String
    ) {
        self.title = title
        self.options = options
        self.selection = .multiple(selection)
        self.systemImage = systemImage
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let title {
                Text(verbatim: title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(options, id: \.self) { option in
                        let selected = isSelected(option)
                        Button {
                            toggle(option)
                            HapticManager.selection()
                        } label: {
                            chipLabel(option)
                        }
                        .buttonStyle(.plain)
                        .filterChipStyle(isSelected: selected)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .padding(.vertical, AppSpacing.xxs)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    @ViewBuilder
    private func chipLabel(_ option: Option) -> some View {
        if let symbol = systemImage?(option) {
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: symbol)
                Text(verbatim: label(option))
            }
        } else {
            Text(verbatim: label(option))
        }
    }

    private func isSelected(_ option: Option) -> Bool {
        switch selection {
        case .single(let binding): return binding.wrappedValue == option
        case .multiple(let binding): return binding.wrappedValue.contains(option)
        }
    }

    private func toggle(_ option: Option) {
        switch selection {
        case .single(let binding):
            binding.wrappedValue = binding.wrappedValue == option ? nil : option
        case .multiple(let binding):
            if binding.wrappedValue.contains(option) {
                binding.wrappedValue.remove(option)
            } else {
                binding.wrappedValue.insert(option)
            }
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `ChipPicker`: the title and a row of chips with the chips' corner.
public struct ChipPickerSkeleton: View {
    let count: Int
    let showsTitle: Bool

    public init(count: Int = 4, showsTitle: Bool = true) {
        self.count = max(1, count)
        self.showsTitle = showsTitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if showsTitle {
                SkeletonText(AppTypography.caption, width: 80)
            }
            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<count, id: \.self) { index in
                    // A chip's own layout (filterChipStyle), invisible, in its corner.
                    Text(verbatim: "Ag")
                        .font(AppTypography.bodySmall.weight(.medium))
                        .hidden()
                        .frame(width: index.isMultiple(of: 2) ? 56 : 72)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(SkeletonView.fill, in: RoundedRectangle(cornerRadius: AppRadius.xl))
                }
            }
            .padding(.vertical, AppSpacing.xxs)
        }
        .padding(.vertical, AppSpacing.xs)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
