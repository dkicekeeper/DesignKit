//
//  SettingsRowsScreen.swift
//  DesignKit Gallery
//
//  Rows of settings and forms: UniversalRow and its accessories (7.0.0: the one row of a form
//  card or a settings list), and the chevron.
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
        DisclosureChevronPage()
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
                "It replaced ToggleSettingsRow, ActionSettingsRow, ActionRowLabel, NavigationSettingsRow, CheckmarkRow, MenuPickerRow, NavigationPickerRow, DatePickerRow, StepperRow, SliderRow, ColorPickerRow and InfoRow, removed in 7.0.0 (docs/migration-7.0.md).",
                "The generic UniversalRow(config:leadingIcon:hint:content:trailing:) stays for a row none of these is.",
            ]
        ) {
            InRowHost(host: host) {
                if state == .loading {
                    skeleton
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

    @ViewBuilder
    private var skeleton: some View {
        switch kind {
        case .slider: UniversalRowSkeleton.slider(showsHint: showsHint, config: host.config)
        case .info, .amount: UniversalRowSkeleton.info(showsIcon: showsIcon)
        case .colors: UniversalRowSkeleton.colors()
        default:
            UniversalRowSkeleton(config: host.config,
                                 iconStyle: showsIcon ? .circle(size: AppIconSize.lg) : nil,
                                 trailing: skeletonTrailing)
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
