//
//  RowAccessory.swift
//  DesignKit
//
//  6.2.0 (the owner's review of the rows): one row for every form card and settings list.
//  `UniversalRow(_:icon:value:hint:role:config:accessory:)` takes what the row carries (a
//  switch, a menu, a list to pick from, a date, a stepper, a slider, a check, a screen to open,
//  an action, a value) and lays it out, pads it and draws its icon, so every row of a card
//  lines up. The twelve rows that each did one of these (`ToggleSettingsRow`, `MenuPickerRow`,
//  `InfoRow`, …) are this row now and deprecated.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// How a row reads: in the text's colours, or in red for an action that deletes or ends
/// something (6.2.0).
public enum RowRole: Hashable, Sendable {
    case standard
    case destructive
}

/// What a `UniversalRow` carries besides its title, and what a tap on it does (6.2.0).
///
/// ```swift
/// UniversalRow("Quiet hours", icon: "moon.fill", accessory: .toggle($quietHours))
/// UniversalRow("Language", icon: "globe", value: "English", accessory: .navigation { LanguageScreen() })
/// UniversalRow("Repeat", icon: "repeat", accessory: .menu($period, options: periods))
/// UniversalRow("Delete all data", icon: "trash", role: .destructive, accessory: .action { delete() })
/// ```
public struct RowAccessory {
    enum Kind {
        case none
        case info(String)
        case amount(InfoRowAmount)
        case toggle(Binding<Bool>)
        case navigation(@MainActor () -> AnyView)
        case action(() -> Void)
        case checkmark(isSelected: Bool, action: () -> Void)
        case menu(RowChoice)
        case picker(RowChoice)
        case date(Binding<Date>, components: DatePickerComponents, minDate: Date?, maxDate: Date?)
        case stepper(Binding<Int>, range: ClosedRange<Int>, step: Int, format: (Int) -> String)
        case slider(Binding<Double>, range: ClosedRange<Double>, step: Double?, valueText: String)
        case colors(Binding<String>, palette: [String])
    }

    let kind: Kind

    /// Nothing: the title, and `value` on the trailing edge if the row has one.
    public static var none: RowAccessory { RowAccessory(kind: .none) }

    /// A detail's value (`InfoRow` before 6.2.0): the title as the grey label, `value` in the
    /// emphasised type on the trailing edge; long values stack under the label at large text
    /// sizes. In a padded container pass `config: .info`.
    public static func info(_ value: String) -> RowAccessory {
        RowAccessory(kind: .info(value))
    }

    /// A detail's amount: as `info`, the amount in `FormattedAmountText`.
    public static func amount(_ amount: Double, currency: String, prefix: String = "") -> RowAccessory {
        RowAccessory(kind: .amount(InfoRowAmount(amount: amount, currency: currency, prefix: prefix)))
    }

    /// A switch on the trailing edge. VoiceOver focuses the switch, labelled with the title and
    /// hinted with the row's hint; the switch ticks when it flips.
    public static func toggle(_ isOn: Binding<Bool>) -> RowAccessory {
        RowAccessory(kind: .toggle(isOn))
    }

    /// A screen to open. In a card the row draws its chevron after `value`; in a `List`
    /// (`config: .settings`) the list draws it.
    @MainActor
    public static func navigation<Destination: View>(
        @ViewBuilder destination: @escaping () -> Destination
    ) -> RowAccessory {
        RowAccessory(kind: .navigation({ AnyView(destination()) }))
    }

    /// An action: the whole row is the button; `role: .destructive` turns it red.
    public static func action(_ action: @escaping () -> Void) -> RowAccessory {
        RowAccessory(kind: .action(action))
    }

    /// A choice in a list: the circle of every option, filled for the chosen one; a tap
    /// chooses (with a tick and a press).
    public static func checkmark(isSelected: Bool, action: @escaping () -> Void) -> RowAccessory {
        RowAccessory(kind: .checkmark(isSelected: isSelected, action: action))
    }

    /// A few options in a menu on the trailing edge, the chosen one shown; at large text sizes
    /// the menu moves under the title.
    public static func menu<Value: Hashable>(
        _ selection: Binding<Value>,
        options: [(label: String, value: Value)]
    ) -> RowAccessory {
        RowAccessory(kind: .menu(RowChoice(selection, options: options)))
    }

    /// Many options on a screen of their own: the chosen one before the chevron, a tap pushes
    /// the list (with a search field past `NavigationPickerMetrics.searchThreshold`). Needs a
    /// `NavigationStack` around it.
    public static func picker<Value: Hashable>(
        _ selection: Binding<Value>,
        options: [(label: String, value: Value)]
    ) -> RowAccessory {
        RowAccessory(kind: .picker(RowChoice(selection, options: options)))
    }

    /// A date (and time) in the system's compact picker on the trailing edge, from `minDate`
    /// and through `maxDate` when given.
    public static func date(
        _ selection: Binding<Date>,
        components: DatePickerComponents = .date,
        from minDate: Date? = nil,
        through maxDate: Date? = nil
    ) -> RowAccessory {
        RowAccessory(kind: .date(selection, components: components, minDate: minDate, maxDate: maxDate))
    }

    /// A whole number with − / + within `range`; `format` is how the value reads ("3 pcs"),
    /// VoiceOver included.
    public static func stepper(
        _ value: Binding<Int>,
        in range: ClosedRange<Int>,
        step: Int = 1,
        format: @escaping (Int) -> String = { "\($0)" }
    ) -> RowAccessory {
        RowAccessory(kind: .stepper(value, range: range, step: step, format: format))
    }

    /// A value on a range: the formatted value on the title's line, the slider under it, the
    /// hint under the slider. A tick on every step, or at either end of a smooth slider.
    public static func slider(
        _ value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double? = nil,
        valueText: String
    ) -> RowAccessory {
        RowAccessory(kind: .slider(value, range: range, step: step, valueText: valueText))
    }

    /// A colour from `palette` (lowercase `#rrggbb`): the swatches in a row under the title; a
    /// stored colour outside the palette comes first, so it shows as chosen.
    public static func colors(
        _ selection: Binding<String>,
        palette: [String] = CategoryColors.pickerPalette
    ) -> RowAccessory {
        RowAccessory(kind: .colors(selection, palette: palette))
    }
}

/// A choice over any `Hashable` value, for a menu or a picker list.
struct RowChoice {
    let options: [(label: String, id: AnyHashable)]
    let selection: Binding<AnyHashable>

    init<Value: Hashable>(_ selection: Binding<Value>, options: [(label: String, value: Value)]) {
        self.options = options.map { (label: $0.label, id: AnyHashable($0.value)) }
        self.selection = Binding(
            get: { AnyHashable(selection.wrappedValue) },
            set: { newValue in
                if let value = newValue.base as? Value { selection.wrappedValue = value }
            }
        )
    }

    var selectedLabel: String? {
        options.first { $0.id == selection.wrappedValue }?.label
    }

    var listOptions: [(label: String, value: AnyHashable)] {
        options.map { (label: $0.label, value: $0.id) }
    }
}

/// A `UniversalRow` made of a title and an accessory.
struct RowControl {
    let title: String
    let icon: IconConfig?
    let value: String?
    let hint: String?
    let role: RowRole
    let titleColor: Color?
    let config: RowConfiguration
    let accessory: RowAccessory
}

/// Lays out a `RowControl`: the leading icon, the title, the accessory and the hint, on
/// `UniversalRow`'s layout.
struct RowControlView: View {
    let row: RowControl

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.isEnabled) private var isEnabled

    @ViewBuilder
    var body: some View {
        switch row.accessory.kind {
        case .none:
            layout { titleText } trailing: { trailingValue }
        case .info(let value):
            infoRow {
                Text(value)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                    .multilineTextAlignment(.trailing)
            }
        case .amount(let display):
            infoRow {
                FormattedAmountText(
                    amount: display.amount,
                    currency: display.currency,
                    prefix: display.prefix,
                    fontSize: AppTypography.bodyEmphasis,
                    fontWeight: .semibold,
                    color: AppColors.Text.primary
                )
            }
        case .toggle(let isOn):
            toggleRow(isOn)
        case .navigation(let destination):
            navigationRow(value: row.value, destination: destination)
        case .action(let action):
            layout { titleText } trailing: { trailingValue }
                .actionRow(role: row.role == .destructive ? .destructive : nil, action: action)
        case .checkmark(let isSelected, let action):
            checkmarkRow(isSelected: isSelected, action: action)
        case .menu(let choice):
            menuRow(choice)
        case .picker(let choice):
            pickerRow(choice)
        case .date(let selection, let components, let minDate, let maxDate):
            layout { titleText.accessibilityHidden(true) } trailing: {
                datePicker(selection, components: components, minDate: minDate, maxDate: maxDate)
            }
        case .stepper(let value, let range, let step, let format):
            stepperRow(value, range: range, step: step, format: format)
        case .slider(let value, let range, let step, let valueText):
            sliderRow(value, range: range, step: step, valueText: valueText)
        case .colors(let selection, let palette):
            colorsRow(selection, palette: palette)
        }
    }

    // MARK: - Pieces

    /// A row with no side padding of its own (`.settings`) lives in a `List`, which pads it and
    /// draws a navigation chevron.
    private var isInList: Bool { row.config.horizontalPadding == 0 }

    private var titleColor: Color {
        if !isEnabled { return AppColors.Text.tertiary }
        return row.titleColor ?? (row.role == .destructive ? AppColors.destructive : AppColors.Text.primary)
    }

    /// The leading icon, grey while the row is disabled.
    private var leadingIcon: IconConfig? {
        guard let icon = row.icon else { return nil }
        guard !isEnabled else { return icon }
        var style = icon.style
        style.tint = .monochrome(AppColors.Text.tertiary)
        return IconConfig(source: icon.source, style: style)
    }

    private var titleText: some View {
        Text(row.title)
            .font(AppTypography.body)
            .foregroundStyle(titleColor)
    }

    @ViewBuilder
    private var trailingValue: some View {
        if let value = row.value {
            valueText(value)
        }
    }

    private func valueText(_ value: String, font: Font = AppTypography.body) -> some View {
        Text(value)
            .font(font)
            .foregroundStyle(AppColors.Text.secondary)
            .lineLimit(1)
    }

    private func layout<Content: View, Trailing: View>(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) -> some View {
        UniversalRow(config: row.config, leadingIcon: leadingIcon, hint: row.hint, content: content, trailing: trailing)
    }

    // MARK: - Accessories

    private func infoRow<Value: View>(@ViewBuilder value: @escaping () -> Value) -> some View {
        layout {
            InfoRowLayout(label: row.title, value: value)
        } trailing: {
            EmptyView()
        }
    }

    private func toggleRow(_ isOn: Binding<Bool>) -> some View {
        layout {
            titleText.accessibilityHidden(true)
        } trailing: {
            Toggle(isOn: isOn) {
                Text(row.title)
            }
            .labelsHidden()
            .tint(AppColors.accent)
            .accessibilityHint(row.hint.map { Text($0) } ?? Text(verbatim: ""))
            .onChange(of: isOn.wrappedValue) { _, _ in HapticManager.selection() }
        }
    }

    @ViewBuilder
    private func navigationRow(value: String?, destination: @escaping @MainActor () -> AnyView) -> some View {
        if isInList {
            // The list adds the chevron after the row.
            NavigationLink {
                destination()
            } label: {
                layout { titleText } trailing: {
                    if let value {
                        valueText(value, font: AppTypography.bodySmall)
                    }
                }
            }
        } else {
            NavigationLink {
                destination()
            } label: {
                Group {
                    if let value, dynamicTypeSize.isAccessibilitySize {
                        // Accessibility sizes: the value under the title, as in iOS Settings.
                        layout {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                titleText
                                valueText(value)
                            }
                        } trailing: {
                            DisclosureChevron()
                        }
                    } else {
                        layout { titleText } trailing: {
                            HStack(spacing: AppSpacing.sm) {
                                if let value {
                                    valueText(value)
                                }
                                DisclosureChevron()
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func pickerRow(_ choice: RowChoice) -> some View {
        navigationRow(value: choice.selectedLabel) {
            AnyView(NavigationPickerList(title: row.title, selection: choice.selection, options: choice.listOptions))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(row.title))
        .accessibilityValue(Text(choice.selectedLabel ?? ""))
        .accessibilityAddTraits(.isButton)
    }

    private func checkmarkRow(isSelected: Bool, action: @escaping () -> Void) -> some View {
        layout {
            HStack(spacing: 0) {
                Text(row.title)
                    .font(AppTypography.h4)
                    .fontWeight(.medium)
                    .foregroundStyle(titleColor)
                if let value = row.value {
                    Spacer()
                    Text(value)
                        .font(AppTypography.h4)
                        .foregroundStyle(AppColors.Text.secondary)
                }
            }
        } trailing: {
            // Every row shows its circle, so the list reads as a choice before anything is picked.
            SelectionIndicator(isSelected: isSelected)
        }
        .selectableRow(isSelected: isSelected) {
            HapticManager.selection()
            action()
        }
    }

    @ViewBuilder
    private func menuRow(_ choice: RowChoice) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            // Accessibility text sizes: the chosen value under the title, as in iOS Settings, so
            // neither is truncated.
            layout {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    titleText
                    menu(choice)
                }
            } trailing: {
                EmptyView()
            }
        } else {
            layout { titleText } trailing: { menu(choice) }
        }
    }

    private func menu(_ choice: RowChoice) -> some View {
        Menu {
            Picker(row.title, selection: choice.selection) {
                ForEach(choice.options, id: \.id) { option in
                    Text(option.label).tag(option.id)
                }
            }
        } label: {
            if let label = choice.selectedLabel {
                HStack(spacing: AppSpacing.xs) {
                    Text(label)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.primary)
                        .lineLimit(1)
                    Icon("chevron.up.chevron.down", size: AppIconSize.xs, tint: .monochrome(AppColors.Text.primary))
                        .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func datePicker(
        _ selection: Binding<Date>,
        components: DatePickerComponents,
        minDate: Date?,
        maxDate: Date?
    ) -> some View {
        Group {
            if let minDate, let maxDate {
                DatePicker(row.title, selection: selection, in: minDate...max(minDate, maxDate), displayedComponents: components)
            } else if let minDate {
                DatePicker(row.title, selection: selection, in: minDate..., displayedComponents: components)
            } else if let maxDate {
                DatePicker(row.title, selection: selection, in: ...maxDate, displayedComponents: components)
            } else {
                DatePicker(row.title, selection: selection, displayedComponents: components)
            }
        }
        .labelsHidden()
        .tint(AppColors.accent)
    }

    @ViewBuilder
    private func stepperRow(_ value: Binding<Int>, range: ClosedRange<Int>, step: Int, format: @escaping (Int) -> String) -> some View {
        let number = Text(verbatim: format(value.wrappedValue))
            .font(AppTypography.body)
            .monospacedDigit()
            .foregroundStyle(AppColors.Text.secondary)
            .contentTransition(.numericText(value: Double(value.wrappedValue)))
            .animation(AppAnimation.contentSpring, value: value.wrappedValue)
            .accessibilityHidden(true)
        let stepper = Stepper(value: value, in: range, step: step) {
            Text(row.title)
        }
        .labelsHidden()
        .accessibilityValue(Text(verbatim: format(value.wrappedValue)))
        .onChange(of: value.wrappedValue) { _, _ in HapticManager.selection() }

        if dynamicTypeSize.isAccessibilitySize {
            layout {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    titleText.accessibilityHidden(true)
                    HStack(spacing: AppSpacing.md) {
                        number
                        Spacer(minLength: 0)
                        stepper
                    }
                }
            } trailing: {
                EmptyView()
            }
        } else {
            layout { titleText.accessibilityHidden(true) } trailing: {
                HStack(spacing: AppSpacing.md) {
                    // The value keeps its width: "12 pcs" stays on one line, the title gives way.
                    number.fixedSize()
                    stepper
                }
            }
        }
    }

    private func sliderRow(_ value: Binding<Double>, range: ClosedRange<Double>, step: Double?, valueText: String) -> some View {
        let isAtEnd = value.wrappedValue <= range.lowerBound || value.wrappedValue >= range.upperBound
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: row.config.spacing) {
                if let icon = leadingIcon {
                    Icon(source: icon.source, style: icon.style)
                }
                titleText
                Spacer()
                Text(valueText)
                    .font(AppTypography.bodySmall.monospacedDigit())
                    .foregroundStyle(AppColors.Text.secondary)
            }

            Group {
                if let step {
                    Slider(value: value, in: range, step: step)
                } else {
                    Slider(value: value, in: range)
                }
            }
            .tint(AppColors.accent)
            // 2.3.0: a tick on every step of a stepped slider, and at either end of a smooth one.
            .hapticCue(.tick, trigger: value.wrappedValue) { _, _ in step != nil }
            .hapticCue(.tick, trigger: isAtEnd) { _, atEnd in step == nil && atEnd }
            .accessibilityLabel(Text(row.title))
            .accessibilityValue(Text(valueText))

            if let hint = row.hint {
                Text(hint)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, row.config.verticalPadding)
        .padding(.horizontal, row.config.horizontalPadding)
    }

    private func colorsRow(_ selection: Binding<String>, palette: [String]) -> some View {
        let selected = selection.wrappedValue.lowercased()
        // A stored colour outside the palette (a custom one, another case) comes first, so it
        // shows as chosen instead of nothing.
        let shown = palette.contains { $0.lowercased() == selected } ? palette : [selection.wrappedValue] + palette
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if !row.title.isEmpty {
                HStack(spacing: row.config.spacing) {
                    if let icon = leadingIcon {
                        Icon(source: icon.source, style: icon.style)
                    }
                    titleText
                }
                .padding(.horizontal, row.config.horizontalPadding)
            }
            UniversalCarousel(config: .compact) {
                ForEach(shown, id: \.self) { hex in
                    ColorSwatch(colorHex: hex, isSelected: selected == hex.lowercased()) {
                        HapticManager.selection()
                        selection.wrappedValue = hex
                    }
                }
            }
        }
        .padding(.vertical, row.config.verticalPadding)
    }
}
