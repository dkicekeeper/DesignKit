//
//  SettingsRowsScreen.swift
//  DesignKit Gallery
//
//  Rows of settings and forms: the universal row and its presets, info rows, pickers in rows.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct SettingsRowsScreen: View {
    static let title = "Rows: Settings & Forms"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        UniversalRowPage()
        InfoRowPage()
        NavigationSettingsRowPage()
        ToggleSettingsRowPage()
        ActionSettingsRowPage()
        ActionRowLabelPage()
        MenuPickerRowPage()
        NavigationPickerRowPage()
        StepperRowPage()
        SliderRowPage()
        DatePickerRowPage()
        ColorPickerRowPage()
        CheckmarkRowPage()
        DisclosureChevronPage()
    }
}

/// Rows live in a form card in the apps; the preview puts them in one too.
private struct InFormCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        FormSection { content }
    }
}

/// Where a settings row sits (6.1.0): in a `FormSection` card with `.standard`, which pads the
/// row like the rows around it, or in a `List` with `.settings`, which leaves the padding to the
/// list. A `.settings` row in a card has no side padding.
private enum RowHost: Hashable {
    case card, list

    var config: RowConfiguration { self == .card ? .standard : .settings }

    static let options: [(String, RowHost)] = [("Card: .standard", .card), ("List: .settings", .list)]
}

private struct InRowHost<Content: View>: View {
    let host: RowHost
    @ViewBuilder var content: Content

    var body: some View {
        switch host {
        case .card:
            FormSection { content }
        case .list:
            NavigationStack {
                List { content }
                    .scrollDisabled(true)
                    .toolbar(.hidden, for: .navigationBar)
            }
            .frame(height: 200)
        }
    }
}

private struct UniversalRowPage: View {
    /// What the row carries (6.2.0): one page for every kind of row.
    enum Kind: String, CaseIterable {
        case none = "None", info = "Info", amount = "Amount", toggle = "Toggle", navigation = "Navigation"
        case action = "Action", checkmark = "Checkmark", menu = "Menu", picker = "Picker", date = "Date"
        case stepper = "Stepper", slider = "Slider", colors = "Colors"
    }

    @State private var kind: Kind = .toggle
    @State private var host: RowHost = .card
    @State private var showsIcon = true
    @State private var showsHint = false
    @State private var showsValue = true
    @State private var destructive = false
    @State private var state: SpecimenState = .content

    @State private var isOn = true
    @State private var period = "month"
    @State private var species = "pike"
    @State private var date = Date()
    @State private var count = 3
    @State private var level = 0.35
    @State private var colorHex = CategoryColors.pickerPalette[3]
    @State private var picked = false

    private let periods: [(label: String, value: String)] = [
        (label: "Weekly", value: "week"), (label: "Monthly", value: "month"), (label: "Yearly", value: "year"),
    ]
    private let fish: [(label: String, value: String)] = ["Pike", "Perch", "Carp", "Asp", "Bream", "Catfish", "Chub",
        "Grayling", "Ide", "Roach", "Rudd", "Tench", "Trout", "Zander"].map { (label: $0, value: $0.lowercased()) }

    var body: some View {
        ComponentPage(
            name: "UniversalRow",
            summary: "The one row of a form card or a settings list (6.2.0): an icon, the title, what the row carries (accessory: a switch, a menu, a list, a date, a stepper, a slider, a check, a screen, an action, a value) and a hint.",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "UniversalRow(_:icon:value:hint:role:config:accessory:). config: .standard in a FormSection card (the default), .settings in a List, .info inside a padded container.",
                "The icon is a glyph in the accent, 24 pt in every row (6.2.0), so the titles of a card line up. role: .destructive turns the title and the icon red.",
                "It replaces ToggleSettingsRow, ActionSettingsRow, ActionRowLabel, NavigationSettingsRow, CheckmarkRow, MenuPickerRow, NavigationPickerRow, DatePickerRow, StepperRow, SliderRow, ColorPickerRow and InfoRow, deprecated in 6.2.0.",
                "The generic UniversalRow(config:leadingIcon:hint:content:trailing:) stays for a row none of these is.",
            ]
        ) {
            InRowHost(host: host) {
                if state == .loading {
                    UniversalRowSkeleton(config: host.config,
                                         iconStyle: showsIcon ? .circle(size: AppIconSize.lg) : nil,
                                         trailing: skeletonTrailing)
                } else {
                    row.disabled(state == .disabled)
                }
            }
        } controls: {
            StateControl(state: $state, states: [.content, .loading, .disabled])
            ChoiceControl("Accessory", selection: $kind, options: Kind.allCases.map { ($0.rawValue, $0) })
            ChoiceControl("In", selection: $host, options: RowHost.options)
            ToggleControl("Icon", isOn: $showsIcon)
            ToggleControl("Value", isOn: $showsValue)
            ToggleControl("Hint", isOn: $showsHint)
            ToggleControl("Destructive", isOn: $destructive)
        }
    }

    private var row: some View {
        UniversalRow(
            title,
            icon: showsIcon ? symbol : nil,
            value: showsValue ? value : nil,
            hint: showsHint ? "Shown under the title" : nil,
            role: destructive ? .destructive : .standard,
            config: host.config,
            accessory: accessory
        )
    }

    private var title: String {
        switch kind {
        case .none: "Version"
        case .info: "Next payment"
        case .amount: "Monthly payment"
        case .toggle: "Quiet hours"
        case .navigation: "Language"
        case .action: destructive ? "Delete all data" : "Export"
        case .checkmark: "Kaspi Gold"
        case .menu: "Repeat"
        case .picker: "Species"
        case .date: "Start date"
        case .stepper: "Fish caught"
        case .slider: "Colour intensity"
        case .colors: "Colour"
        }
    }

    private var symbol: String {
        switch kind {
        case .none: "info.circle"
        case .info, .date: "calendar"
        case .amount: "banknote"
        case .toggle: "moon.fill"
        case .navigation: "globe"
        case .action: destructive ? "trash" : "square.and.arrow.up"
        case .checkmark: "creditcard.fill"
        case .menu: "repeat"
        case .picker: "fish"
        case .stepper: "number"
        case .slider: "circle.lefthalf.filled"
        case .colors: "paintpalette"
        }
    }

    private var value: String? {
        switch kind {
        case .none: "6.2.0"
        case .navigation: "English"
        case .checkmark: "1 250 000 ₸"
        default: nil
        }
    }

    private var accessory: RowAccessory {
        switch kind {
        case .none: .none
        case .info: .info("12 October")
        case .amount: .amount(85_000, currency: "KZT")
        case .toggle: .toggle($isOn)
        case .navigation: .navigation { Text("Language settings").navigationTitle("Language") }
        case .action: .action {}
        case .checkmark: .checkmark(isSelected: picked) { picked.toggle() }
        case .menu: .menu($period, options: periods)
        case .picker: .picker($species, options: fish)
        case .date: .date($date)
        case .stepper: .stepper($count, in: 0...99) { "\($0) pcs" }
        case .slider: .slider($level, in: 0.05...1, valueText: "\(Int((level * 100).rounded()))%")
        case .colors: .colors($colorHex)
        }
    }

    private var skeletonTrailing: UniversalRowSkeleton.Trailing {
        switch kind {
        case .toggle: .toggle
        case .navigation, .picker: .chevron
        case .checkmark: .selection
        case .menu, .date: .capsule
        case .none, .info, .amount, .stepper: .value
        case .action, .slider, .colors: .empty
        }
    }
}

private struct InfoRowPage: View {
    @State private var showsIcon = true
    @State private var isAmount = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "InfoRow",
            summary: "Deprecated in 6.2.0: UniversalRow(config: .info, accessory: .info / .amount). A label and its value (text or an amount) on a detail screen; stacks at large text sizes.",
            apps: [.tenra],
            canvas: .fill,
            notes: ["Any value view: InfoRowLayout(label:) { … } is the layout InfoRow is built on."]
        ) {
            InFormCard {
                if state == .loading {
                    InfoRowSkeleton(showsIcon: showsIcon)
                } else if isAmount {
                    InfoRow(icon: showsIcon ? "banknote" : nil, label: "Monthly payment", amount: 85_000, currency: "KZT")
                } else {
                    InfoRow(icon: showsIcon ? "calendar" : nil, label: "Next payment", value: "12 October")
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Icon", isOn: $showsIcon)
            ToggleControl("Amount value", isOn: $isAmount)
        }
    }
}

private struct NavigationSettingsRowPage: View {
    @State private var showsValue = true
    @State private var showsIcon = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "NavigationSettingsRow",
            summary: "Deprecated in 6.2.0: UniversalRow(config: .settings, accessory: .navigation). A settings row that opens a screen: a small icon, the title, what is set, a chevron.",
            apps: [.tenra],
            canvas: .fill,
            notes: [
                "value: what is set, before the chevron, as iOS Settings shows it (5.0.0). NavigationPickerRow(style: .list) is this row with the chosen option.",
                "A List row: the list pads it and draws the chevron. In a FormSection card use NavigationPickerRow.",
            ]
        ) {
            InRowHost(host: .list) {
                if state == .loading {
                    UniversalRowSkeleton.navigationSettings
                } else {
                    NavigationSettingsRow(icon: showsIcon ? "globe" : nil, title: "Language", value: showsValue ? "English" : nil) {
                        Text("Language settings").navigationTitle("Language")
                    }
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Value", isOn: $showsValue)
            ToggleControl("Icon", isOn: $showsIcon)
        }
    }
}

private struct ToggleSettingsRowPage: View {
    @State private var isOn = true
    @State private var showsHint = true
    @State private var showsIcon = true
    @State private var host: RowHost = .card
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ToggleSettingsRow",
            summary: "Deprecated in 6.2.0: UniversalRow(accessory: .toggle). A settings row with a switch and an optional hint under the title.",
            since: "0.6.0",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "config: .standard in a FormSection card, .settings (the default) in a List (3.0.0).",
            ]
        ) {
            InRowHost(host: host) {
                if state == .loading {
                    UniversalRowSkeleton(config: host.config, iconStyle: .circle(size: AppIconSize.md), trailing: .toggle)
                } else {
                    ToggleSettingsRow(icon: showsIcon ? "moon.fill" : nil, title: "Quiet hours",
                                      hint: showsHint ? "No notifications from 22:00 to 8:00" : nil,
                                      config: host.config, isOn: $isOn)
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("In", selection: $host, options: RowHost.options)
            ToggleControl("On", isOn: $isOn)
            ToggleControl("Hint", isOn: $showsHint)
            ToggleControl("Icon (optional since 3.0.0)", isOn: $showsIcon)
        }
    }
}

private struct ActionSettingsRowPage: View {
    @State private var destructive = false
    @State private var host: RowHost = .card
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ActionSettingsRow",
            summary: "Deprecated in 6.2.0: UniversalRow(accessory: .action). A settings row that runs an action: export, sign out, delete the account.",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "config: .standard in a FormSection card, .settings (the default) in a List. A PhotosPicker or a ShareLink takes ActionRowLabel as its label.",
            ]
        ) {
            InRowHost(host: host) {
                if state == .loading {
                    UniversalRowSkeleton(config: host.config, iconStyle: .circle(size: AppIconSize.md))
                } else {
                    ActionSettingsRow(icon: destructive ? "trash" : "square.and.arrow.up",
                                      title: destructive ? "Delete all data" : "Export",
                                      isDestructive: destructive, config: host.config) {}
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("In", selection: $host, options: RowHost.options)
            ToggleControl("Destructive", isOn: $destructive)
        }
    }
}

private struct MenuPickerRowPage: View {
    @State private var period = "month"
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "MenuPickerRow",
            summary: "Deprecated in 6.2.0: UniversalRow(accessory: .menu). A form row whose value opens a menu of a few options.",
            apps: [.tenra, .dalada],
            canvas: .fill
        ) {
            InFormCard {
                if state == .loading {
                    UniversalRowSkeleton.menuPicker
                } else {
                    MenuPickerRow(icon: "repeat", title: "Repeat", selection: $period, options: [
                        (label: "Weekly", value: "week"), (label: "Monthly", value: "month"), (label: "Yearly", value: "year"),
                    ])
                }
            }
        } controls: {
            StateControl(state: $state)
        }
    }
}

private struct NavigationPickerRowPage: View {
    @State private var species = "pike"
    @State private var showsIcon = true
    @State private var many = true
    @State private var style: NavigationPickerRow<String>.Style = .form
    @State private var state: SpecimenState = .content

    private let fewOptions: [(label: String, value: String)] = [
        (label: "Pike", value: "pike"), (label: "Perch", value: "perch"), (label: "Carp", value: "carp"),
    ]
    private var manyOptions: [(label: String, value: String)] {
        fewOptions + ["Asp", "Bream", "Catfish", "Chub", "Grayling", "Ide", "Roach", "Rudd", "Tench", "Trout", "Zander"]
            .map { (label: $0, value: $0.lowercased()) }
    }

    var body: some View {
        ComponentPage(
            name: "NavigationPickerRow",
            summary: "Deprecated in 6.2.0: UniversalRow(accessory: .picker). A choice from a long list: the row shows the chosen value; a tap pushes the list, with a search field past 12 options.",
            since: "3.0.0",
            apps: [.dalada, .tenra],
            canvas: .fill,
            notes: [
                "Needs a NavigationStack around it (an EditSheetContainer has one). A few options: MenuPickerRow.",
                "style: .list (4.14.0) is the row of a List, as iOS Settings draws it: the list adds the chevron.",
            ],
            styles: ["form", "list"]
        ) {
            NavigationStack {
                Group {
                    if style == .list {
                        List {
                            if state == .loading {
                                UniversalRowSkeleton.menuPicker
                            } else {
                                NavigationPickerRow(icon: showsIcon ? "waveform" : nil, title: "Voice language",
                                                    selection: $species, options: many ? manyOptions : fewOptions,
                                                    style: .list)
                            }
                        }
                    } else {
                        InFormCard {
                            if state == .loading {
                                UniversalRowSkeleton.menuPicker
                            } else {
                                NavigationPickerRow(icon: showsIcon ? "fish" : nil, title: "Species",
                                                    selection: $species, options: many ? manyOptions : fewOptions)
                            }
                        }
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
            .frame(height: 220)
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Style", selection: $style, options: [("Form", .form), ("List", .list)])
            ToggleControl("Icon", isOn: $showsIcon)
            ToggleControl("Many options (search)", isOn: $many)
        }
    }
}

private struct StepperRowPage: View {
    @State private var count = 3
    @State private var showsIcon = true
    @State private var showsUnit = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "StepperRow",
            summary: "Deprecated in 6.2.0: UniversalRow(accessory: .stepper). A whole number in a form: the title, the value and − / + to change it, within a range.",
            since: "3.0.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            InFormCard {
                if state == .loading {
                    UniversalRowSkeleton.menuPicker
                } else {
                    StepperRow(icon: showsIcon ? "fish" : nil, title: "Fish caught", value: $count, in: 0...99) {
                        showsUnit ? "\($0) pcs" : "\($0)"
                    }
                }
            }
        } controls: {
            StateControl(state: $state)
            StepperControl("Value", value: $count, in: 0...99)
            ToggleControl("Icon", isOn: $showsIcon)
            ToggleControl("Unit", isOn: $showsUnit)
        }
    }
}

private struct SliderRowPage: View {
    @State private var value = 0.6
    @State private var showsIcon = true
    @State private var showsHint = false
    @State private var stepped = false
    @State private var host: RowHost = .card
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "SliderRow",
            summary: "Deprecated in 6.2.0: UniversalRow(accessory: .slider). A setting set with a slider: the title, the current value on the right, the slider, an optional hint.",
            since: "1.15.0",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "The app formats the value (per cent, metres, minutes) and passes it as valueText.",
                "Haptics (2.3.0): a tick on every step of a stepped slider; a smooth one ticks at either end.",
                "config (6.1.0): .standard in a FormSection card, .settings (the default) in a List.",
            ]
        ) {
            InRowHost(host: host) {
                if state == .loading {
                    SliderRowSkeleton(showsHint: showsHint, config: host.config)
                } else {
                    SliderRow(
                        "Colour intensity",
                        systemImage: showsIcon ? "circle.lefthalf.filled" : nil,
                        value: $value,
                        in: 0.05...1,
                        step: stepped ? 0.05 : nil,
                        valueText: "\(Int((value * 100).rounded()))%",
                        hint: showsHint ? "How strongly the home background shows through the cards." : nil,
                        config: host.config
                    )
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("In", selection: $host, options: RowHost.options)
            ToggleControl("Icon", isOn: $showsIcon)
            ToggleControl("Hint", isOn: $showsHint)
            ToggleControl("Steps of 5%", isOn: $stepped)
        }
    }
}

private struct DatePickerRowPage: View {
    @State private var date = Date()
    @State private var withTime = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "DatePickerRow",
            summary: "Deprecated in 6.2.0: UniversalRow(accessory: .date). A form row with a date (and time) in a compact picker.",
            apps: [.tenra, .dalada],
            canvas: .fill
        ) {
            InFormCard {
                if state == .loading {
                    UniversalRowSkeleton.datePicker
                } else {
                    DatePickerRow(icon: "calendar", title: "Start date", selection: $date,
                                  displayedComponents: withTime ? [.date, .hourAndMinute] : .date)
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Time", isOn: $withTime)
        }
    }
}

private struct ColorPickerRowPage: View {
    @State private var hex = "#6366f1"
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ColorPickerRow",
            summary: "Deprecated in 6.2.0: UniversalRow(accessory: .colors). A row of colour swatches to pick a category's or an account's colour.",
            apps: [.tenra],
            canvas: .fill,
            notes: ["The default palette is CategoryColors.pickerPalette (1.11.0): the 14 colours a name hashes to, then 16 deeper and neutral shades."]
        ) {
            InFormCard {
                if state == .loading {
                    ColorPickerRowSkeleton()
                } else {
                    ColorPickerRow(selectedColorHex: $hex, title: "Color")
                }
            }
        } controls: {
            StateControl(state: $state)
            HStack {
                Text("Selected").font(AppTypography.bodySmall)
                Spacer()
                Text(hex).font(AppTypography.bodySmall).foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

private struct CheckmarkRowPage: View {
    @State private var selection = "kaspi"
    @State private var showsIcons = true
    @State private var showsValues = true
    @State private var host: RowHost = .card
    @State private var state: SpecimenState = .content

    private let accounts = [("kaspi", "Kaspi Gold", "1 250 000 ₸"), ("halyk", "Halyk", "320 000 ₸"), ("cash", "Cash", "45 000 ₸")]

    var body: some View {
        ComponentPage(
            name: "CheckmarkRow",
            summary: "Deprecated in 6.2.0: UniversalRow(accessory: .checkmark). A row of a choice list (a filter or picker sheet): a SelectionIndicator on every row, the accent filled check on the picked one.",
            since: "1.10.0",
            apps: [.tenra, .dalada],
            canvas: .fill
        ) {
            InRowHost(host: host) {
                ForEach(accounts, id: \.0) { account in
                    if state == .loading {
                        UniversalRowSkeleton(config: host.config, iconStyle: showsIcons ? .circle(size: AppIconSize.lg) : nil,
                                             titleFont: AppTypography.h4, trailing: .selection)
                    } else {
                        CheckmarkRow(account.1,
                                     icon: showsIcons ? .sfSymbol("creditcard.fill", color: AppColors.accent) : nil,
                                     value: showsValues ? account.2 : nil,
                                     isSelected: selection == account.0,
                                     config: host.config) { selection = account.0 }
                    }
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Icons", isOn: $showsIcons)
            ToggleControl("Values", isOn: $showsValues)
            ChoiceControl("In (.standard since 3.0.0)", selection: $host, options: RowHost.options)
        }
    }
}

private struct ActionRowLabelPage: View {
    @State private var showsSymbol = true
    @State private var quiet = false

    var body: some View {
        ComponentPage(
            name: "ActionRowLabel",
            summary: "Deprecated in 6.2.0: UniversalRow(_:icon:iconColor:titleColor:) as the label. The look of an action row for a control that is not a Button: the label of a PhotosPicker, a ShareLink, a Link.",
            since: "3.1.0",
            apps: [.dalada],
            canvas: .fill,
            notes: [
                "ActionSettingsRow is the same row with its own button; this one is only the label.",
                "Its init is nonisolated: PhotosPicker builds its label off the main actor.",
                "No skeleton: it shows no data.",
            ]
        ) {
            InFormCard {
                ActionRowLabel(
                    "Add photos",
                    systemImage: showsSymbol ? "photo.on.rectangle.angled" : nil,
                    titleColor: quiet ? AppColors.Text.primary : nil
                )
            }
        } controls: {
            ToggleControl("Symbol", isOn: $showsSymbol)
            ToggleControl("Quiet title", isOn: $quiet)
        }
    }
}

private struct DisclosureChevronPage: View {
    var body: some View {
        ComponentPage(
            name: "DisclosureChevron",
            summary: "The chevron at the end of a row that opens a screen; tertiary, sized to the text.",
            apps: [.tenra, .dalada]
        ) {
            DisclosureChevron()
        }
    }
}

#Preview { NavigationStack { SettingsRowsScreen() } }
