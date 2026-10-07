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
    var body: some View {
        ShowcasePage(title: "Rows: Settings & Forms") {
            UniversalRowPage()
            InfoRowPage()
            NavigationSettingsRowPage()
            ToggleSettingsRowPage()
            ActionSettingsRowPage()
            MenuPickerRowPage()
            SliderRowPage()
            DatePickerRowPage()
            ColorPickerRowPage()
            CheckmarkRowPage()
            DisclosureChevronPage()
        }
    }
}

/// Rows live in a form card in the apps; the preview puts them in one too.
private struct InFormCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        FormSection { content }
    }
}

private struct UniversalRowPage: View {
    @State private var config = 0
    @State private var showsIcon = true
    @State private var showsHint = false
    @State private var trailing = 1
    @State private var state: SpecimenState = .content

    private var rowConfig: RowConfiguration {
        [RowConfiguration.standard, .settings, .info, .selectable, .sheetList][config]
    }

    private var skeletonTrailing: UniversalRowSkeleton.Trailing {
        [.empty, .value, .chevron][trailing]
    }

    var body: some View {
        ComponentPage(
            name: "UniversalRow",
            summary: "The row every list row is built on: a leading icon, content, a trailing slot, a hint; padding from its RowConfiguration preset.",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: ["Presets: .standard, .settings, .info, .selectable, .sheetList (design-system §10 for their padding)."]
        ) {
            InFormCard {
                if state == .loading {
                    UniversalRowSkeleton(config: rowConfig,
                                         iconStyle: showsIcon ? .circle(size: AppIconSize.md) : nil,
                                         trailing: skeletonTrailing)
                } else {
                    UniversalRow(
                        config: rowConfig,
                        leadingIcon: showsIcon ? .sfSymbol("bell.fill", color: AppColors.accent) : nil,
                        hint: showsHint ? "Reminders the evening before" : nil
                    ) {
                        Text("Notifications").font(AppTypography.body)
                    } trailing: {
                        switch trailing {
                        case 1: Text("On").font(AppTypography.body).foregroundStyle(AppColors.textSecondary)
                        case 2: DisclosureChevron()
                        default: EmptyView()
                        }
                    }
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Preset", selection: $config, options: [
                (".standard", 0), (".settings", 1), (".info", 2), (".selectable", 3), (".sheetList", 4),
            ])
            ToggleControl("Leading icon", isOn: $showsIcon)
            ToggleControl("Hint", isOn: $showsHint)
            ChoiceControl("Trailing", selection: $trailing, options: [("None", 0), ("Value", 1), ("Chevron", 2)])
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
            summary: "A label and its value (text or an amount) on a detail screen; stacks at large text sizes.",
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
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "NavigationSettingsRow",
            summary: "A settings row that opens a screen: a small icon, the title, a chevron.",
            apps: [.tenra, .dalada],
            canvas: .fill
        ) {
            InFormCard {
                if state == .loading {
                    UniversalRowSkeleton.navigationSettings
                } else {
                    NavigationSettingsRow(icon: "globe", title: "Language") {
                        Text("Language settings").navigationTitle("Language")
                    }
                }
            }
        } controls: {
            StateControl(state: $state)
        }
    }
}

private struct ToggleSettingsRowPage: View {
    @State private var isOn = true
    @State private var showsHint = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ToggleSettingsRow",
            summary: "A settings row with a switch and an optional hint under the title.",
            since: "0.6.0",
            apps: [.tenra, .dalada],
            canvas: .fill
        ) {
            InFormCard {
                if state == .loading {
                    UniversalRowSkeleton.toggleSettings
                } else {
                    ToggleSettingsRow(icon: "moon.fill", title: "Quiet hours",
                                      hint: showsHint ? "No notifications from 22:00 to 8:00" : nil,
                                      isOn: $isOn)
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("On", isOn: $isOn)
            ToggleControl("Hint", isOn: $showsHint)
        }
    }
}

private struct ActionSettingsRowPage: View {
    @State private var destructive = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ActionSettingsRow",
            summary: "A settings row that runs an action: export, sign out, delete the account.",
            apps: [.tenra, .dalada],
            canvas: .fill
        ) {
            InFormCard {
                if state == .loading {
                    UniversalRowSkeleton.actionSettings
                } else {
                    ActionSettingsRow(icon: destructive ? "trash" : "square.and.arrow.up",
                                      title: destructive ? "Delete all data" : "Export",
                                      isDestructive: destructive) {}
                }
            }
        } controls: {
            StateControl(state: $state)
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
            summary: "A form row whose value opens a menu of a few options.",
            apps: [.tenra],
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

private struct SliderRowPage: View {
    @State private var value = 0.6
    @State private var showsIcon = true
    @State private var showsHint = false
    @State private var stepped = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "SliderRow",
            summary: "A setting set with a slider: the title, the current value on the right, the slider, an optional hint.",
            since: "1.15.0",
            apps: [.tenra],
            canvas: .fill,
            notes: ["The app formats the value (per cent, metres, minutes) and passes it as valueText."]
        ) {
            InFormCard {
                if state == .loading {
                    SliderRowSkeleton(showsHint: showsHint)
                } else {
                    SliderRow(
                        "Colour intensity",
                        systemImage: showsIcon ? "circle.lefthalf.filled" : nil,
                        value: $value,
                        in: 0.05...1,
                        step: stepped ? 0.05 : nil,
                        valueText: "\(Int((value * 100).rounded()))%",
                        hint: showsHint ? "How strongly the home background shows through the cards." : nil
                    )
                }
            }
        } controls: {
            StateControl(state: $state)
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
            summary: "A form row with a date (and time) in a compact picker.",
            apps: [.tenra],
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
            summary: "A row of colour swatches to pick a category's or an account's colour.",
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
    @State private var state: SpecimenState = .content

    private let accounts = [("kaspi", "Kaspi Gold", "1 250 000 ₸"), ("halyk", "Halyk", "320 000 ₸"), ("cash", "Cash", "45 000 ₸")]

    var body: some View {
        ComponentPage(
            name: "CheckmarkRow",
            summary: "A row of a choice list (a filter or picker sheet): the picked one gets the accent checkmark.",
            since: "1.10.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            InFormCard {
                ForEach(accounts, id: \.0) { account in
                    if state == .loading {
                        UniversalRowSkeleton.checkmark(iconStyle: showsIcons ? .circle(size: AppIconSize.lg) : nil)
                    } else {
                        CheckmarkRow(account.1,
                                     icon: showsIcons ? .sfSymbol("creditcard.fill", color: AppColors.accent) : nil,
                                     value: showsValues ? account.2 : nil,
                                     isSelected: selection == account.0) { selection = account.0 }
                    }
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Icons", isOn: $showsIcons)
            ToggleControl("Values", isOn: $showsValues)
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
