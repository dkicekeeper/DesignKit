//
//  SelectionScreen.swift
//  DesignKit Gallery
//
//  Selection: segments, chips, rating, the check circle, quick dates, the icon picker, a long
//  list with search.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents
import PhotosUI

struct SelectionScreen: View {
    static let title = "Selection"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        SegmentedPickerPage()
        ChipPickerPage()
        RatingPage()
        SelectionIndicatorPage()
        DateButtonsPage()
        IconPickerPage()
        SnapCardPickerPage()
        OptionCardPickerPage()
        PickerCarouselPage()
        SearchablePickerPage()
    }
}

private struct SearchablePickerPage: View {
    @State private var state: SpecimenState = .content
    @State private var multiple = false
    @State private var creates = true
    @State private var isPresented = false
    @State private var single: String? = "Cafés"
    @State private var several: Set<String> = ["Tent", "Headlamp"]
    @State private var categories: [(String, String, String?)] = [
        ("Cafés", "cup.and.saucer.fill", "Coffee, lunch out"), ("Groceries", "cart.fill", nil),
        ("Taxi", "car.fill", "Rides and parking"), ("Rent", "house.fill", nil),
        ("Health", "cross.case.fill", "Pharmacy, doctors"), ("Gifts", "gift.fill", nil),
        ("Subscriptions", "repeat", "Music, video, cloud"), ("Travel", "airplane", nil),
    ]
    @State private var gear = ["Tent", "Sleeping bag", "Headlamp", "Stove", "Water filter", "Trekking poles", "Rain jacket"]

    var body: some View {
        ComponentPage(
            name: "SearchablePicker",
            summary: "A list too long to scan: the system search narrows it, one option or several are picked with the row's circle, and a name nothing has offers “Create”.",
            since: "8.9.0",
            apps: [.tenra, .dalada, .platina],
            notes: [
                "A screen's content: put it in a NavigationStack (a pushed screen, or a sheet with its own stack), where the search field lives.",
                "selection: Binding<Value?> picks one (dismissesOnSelection: true closes the screen on a pick); Binding<Set<Value>> picks several.",
                "The search keeps the options whose title or subtitle contains the text, any case, any accents. onCreate adds the typed name and returns its value, which is picked.",
                "Loading: SearchablePickerSkeleton. Strings: picker.search, picker.create, picker.noResults.",
            ],
            dos: [
                "Use it when the list is too long to scan (about 10 options and more).",
                "Pass onCreate when a person can add the missing option (a category, a tag).",
            ],
            donts: [
                "Use it for a few options: a menu row or ChipPicker shows them at once.",
                "Put it outside a NavigationStack: the search field lives in the navigation bar.",
            ],
            code: pickerCode,
            cases: pickerCases
        ) {
            if state == .loading {
                SearchablePickerSkeleton(rows: 4)
            } else {
                VStack(spacing: AppSpacing.md) {
                    Text(summary)
                        .font(AppTypography.bodyEmphasis)
                        .multilineTextAlignment(.center)
                    DSButton(multiple ? "Pick the gear" : "Pick a category", systemImage: "magnifyingglass",
                             appearance: .secondary, fullWidth: true) { isPresented = true }
                }
                .sheet(isPresented: $isPresented) {
                    NavigationStack {
                        picker
                            .navigationTitle(multiple ? "Gear" : "Category")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") { isPresented = false }
                                }
                            }
                    }
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Selection", selection: $multiple, options: [("One", false), ("Several", true)])
            ToggleControl("Create a missing name", isOn: $creates)
        }
    }

    @ViewBuilder
    private var picker: some View {
        if multiple {
            SearchablePicker(gear.map { SearchablePickerOption($0, value: $0) }, selection: $several,
                             onCreate: creates ? { name in gear.append(name); return name } : nil)
        } else {
            SearchablePicker(categories.map { SearchablePickerOption($0.0, value: $0.0, subtitle: $0.2, systemImage: $0.1) },
                             selection: $single, dismissesOnSelection: true,
                             onCreate: creates ? { name in categories.append((name, "tag.fill", nil)); return name } : nil)
        }
    }

    private var summary: String {
        if multiple {
            return several.isEmpty ? "No gear" : several.sorted().joined(separator: ", ")
        }
        return single ?? "No category"
    }

    /// The picker as the controls set it, the defaults left out.
    private var pickerCode: String {
        if state == .loading {
            return SwiftCode.call("SearchablePickerSkeleton", [.number("rows", 4, default: 6)])
        }
        if multiple {
            return SwiftCode.call("SearchablePicker", [
                .positional("gear.map { SearchablePickerOption($0.name, value: $0.id) }"),
                .labeled("selection", "$packed"),
                creates ? .labeled("onCreate", "{ name in addGear(named: name) }") : nil,
            ])
        }
        return SwiftCode.call("SearchablePicker", [
            .positional("categories.map { SearchablePickerOption($0.name, value: $0.id, subtitle: $0.note, systemImage: $0.symbol) }"),
            .labeled("selection", "$category"),
            .flag("dismissesOnSelection", true),
            creates ? .labeled("onCreate", "{ name in addCategory(named: name) }") : nil,
        ])
    }

    /// Picks as the apps hold them.
    private var pickerCases: [SpecimenCase] {
        [
            SpecimenCase("One category") {
                state = .content; multiple = false; creates = true; isPresented = false; single = "Groceries"
            },
            SpecimenCase("Nothing picked") {
                state = .content; multiple = false; creates = false; isPresented = false; single = nil
            },
            SpecimenCase("Long name") {
                let name = "Children's clubs and summer camps"
                if !categories.contains(where: { $0.0 == name }) {
                    categories.append((name, "graduationcap.fill", "Sports, music, school trips"))
                }
                state = .content; multiple = false; creates = true; isPresented = false; single = name
            },
            SpecimenCase("Hike gear") {
                state = .content; multiple = true; creates = true; isPresented = false
                several = ["Tent", "Sleeping bag", "Headlamp", "Stove", "Water filter", "Trekking poles", "Rain jacket"]
            },
            SpecimenCase("Nothing packed") {
                state = .content; multiple = true; creates = false; isPresented = false; several = []
            },
        ]
    }
}

private struct SegmentedPickerPage: View {
    @State private var selection = 0
    @State private var count = 3

    var body: some View {
        ComponentPage(
            name: "SegmentedPicker",
            summary: "Two to four exclusive modes on Liquid Glass.",
            apps: [.tenra, .dalada, .platina],
            canvas: .fill,
            notes: [
                "A selection haptic as the segment moves (2.3.0, HapticCue.select).",
            ],
            code: segmentsCode,
            cases: segmentsCases
        ) {
            SegmentedPicker(
                title: "Type",
                selection: $selection,
                options: Array([("Expense", 0), ("Income", 1), ("Transfer", 2), ("Debt", 3)].prefix(count))
                    .map { (label: $0.0, value: $0.1) }
            )
        } controls: {
            StepperControl("Options", value: $count, in: 2...4)
        }
    }

    /// The picker as the controls set it: its options over the app's own type.
    private var segmentsCode: String {
        let options = [("Expense", ".expense"), ("Income", ".income"), ("Transfer", ".transfer"), ("Debt", ".debt")]
            .prefix(count)
            .map { "(\(SwiftCode.string($0.0)), \($0.1))" }
        return SwiftCode.call("SegmentedPicker", [
            .text("title", "Type"),
            .labeled("selection", "$type"),
            .labeled("options", SwiftCode.array(Array(options))),
        ])
    }

    /// Switches as the apps show them.
    private var segmentsCases: [SpecimenCase] {
        [
            SpecimenCase("Two modes") { count = 2; selection = 1 },
            SpecimenCase("Expense") { count = 3; selection = 0 },
            SpecimenCase("Four modes") { count = 4; selection = 3 },
        ]
    }
}

private struct ChipPickerPage: View {
    @State private var single: String? = "Cloudy"
    @State private var several: Set<String> = ["Lake", "Camp"]
    @State private var multiple = false
    @State private var showsIcons = true
    @State private var showsTitle = true
    @State private var showsAll = false
    @State private var inCard = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ChipPicker",
            summary: "Chips to pick one option, or several (a filter); with icons, a title and an \"All\" chip.",
            since: "0.4.0",
            apps: [.tenra, .dalada, .platina],
            canvas: .fill,
            notes: [
                "allTitle (2.8.0): an \"All\" chip in front, selected while nothing is picked; a tap clears the selection.",
                "inset (3.1.0): in a FormSection card pass the card's padding, AppSpacing.lg. The caption and the first chip start there; the chips still scroll to the card's edge.",
            ],
            code: chipsCode,
            cases: chipsCases
        ) {
            if state == .loading {
                ChipPickerSkeleton(count: 4, showsTitle: showsTitle)
            } else if inCard {
                FormSection { picker.padding(.vertical, AppSpacing.sm) }
            } else {
                picker
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Several", isOn: $multiple)
            ToggleControl("Icons", isOn: $showsIcons)
            ToggleControl("Title", isOn: $showsTitle)
            ToggleControl("\"All\" chip", isOn: $showsAll)
            ToggleControl("In a card (inset, 3.1.0)", isOn: $inCard)
        }
    }

    @ViewBuilder
    private var picker: some View {
        let inset = inCard ? AppSpacing.lg : 0
        if multiple {
            ChipPicker(showsTitle ? "Place" : nil, options: ["Lake", "River", "Camp", "Forest"],
                       selection: $several, allTitle: showsAll ? "All" : nil, systemImage: placeIcon,
                       inset: inset) { $0 }
        } else {
            ChipPicker(showsTitle ? "Weather" : nil, options: ["Sunny", "Cloudy", "Rain", "Snow"],
                       selection: $single, allTitle: showsAll ? "Any" : nil, systemImage: weatherIcon,
                       inset: inset) { $0 }
        }
    }

    private var weatherIcon: ((String) -> String?)? {
        guard showsIcons else { return nil }
        return { ["Sunny": "sun.max", "Cloudy": "cloud", "Rain": "cloud.rain", "Snow": "snowflake"][$0] }
    }

    private var placeIcon: ((String) -> String?)? {
        guard showsIcons else { return nil }
        return { _ in "mappin" }
    }

    /// The chips as the controls set them, the defaults left out; in a card with its padding.
    private var chipsCode: String {
        if state == .loading {
            return SwiftCode.call("ChipPickerSkeleton", [.flag("showsTitle", showsTitle, default: true)])
        }
        let options = multiple ? ["Lake", "River", "Camp", "Forest"] : ["Sunny", "Cloudy", "Rain", "Snow"]
        let caption = multiple ? "Place" : "Weather"
        let selection = multiple ? "$places" : "$weather"
        let allTitle = multiple ? "All" : "Any"
        let icon = multiple ? #"{ _ in "mappin" }"# : "{ weatherSymbols[$0] }"
        let chips = SwiftCode.call("ChipPicker", [
            showsTitle ? .positional(SwiftCode.string(caption)) : nil,
            .labeled("options", SwiftCode.array(options.map { SwiftCode.string($0) })),
            .labeled("selection", selection),
            showsAll ? .text("allTitle", allTitle) : nil,
            showsIcons ? .labeled("systemImage", icon) : nil,
            inCard ? .labeled("inset", "AppSpacing.lg") : nil,
        ], trailing: "$0")
        guard inCard else { return chips }
        let padded = SwiftCode.modifier(chips, "padding", [.positional(".vertical"), .positional("AppSpacing.sm")])
        return SwiftCode.call("FormSection", [], trailing: padded)
    }

    /// Chips as the apps fill them.
    private var chipsCases: [SpecimenCase] {
        [
            SpecimenCase("Rain") {
                state = .content; multiple = false; single = "Rain"; showsIcons = true; showsTitle = true
                showsAll = false; inCard = false
            },
            SpecimenCase("Nothing picked") {
                state = .content; multiple = false; single = nil; showsIcons = true; showsTitle = true
                showsAll = true; inCard = false
            },
            SpecimenCase("Filter") {
                state = .content; multiple = true; several = ["Lake", "River", "Forest"]; showsIcons = true
                showsTitle = false; showsAll = true; inCard = false
            },
            SpecimenCase("In a form") {
                state = .content; multiple = false; single = "Sunny"; showsIcons = true; showsTitle = true
                showsAll = false; inCard = true
            },
            SpecimenCase("Text only") {
                state = .content; multiple = true; several = []; showsIcons = false; showsTitle = true
                showsAll = false; inCard = false
            },
        ]
    }
}

private struct RatingPage: View {
    @State private var rating = 3
    @State private var shown = 3.5
    @State private var size = 32.0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "Rating · RatingPicker",
            summary: "Stars: Rating shows a rating with half stars, RatingPicker is the tap-to-rate input.",
            since: "0.4.0",
            apps: [.dalada]
        ) {
            VStack(spacing: AppSpacing.lg) {
                if state == .loading {
                    RatingSkeleton(size: 14)
                } else {
                    Rating(rating: shown, size: 14)
                }
                RatingPicker(rating: $rating, size: size)
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Shown rating", value: $shown, in: 0...5, step: 0.25)
            SliderControl("Picker size", value: $size, in: 20...44, step: 2)
        }
    }
}

private struct SelectionIndicatorPage: View {
    @State private var isSelected = true
    @State private var tint = 0

    var body: some View {
        ComponentPage(
            name: "SelectionIndicator",
            summary: "The check circle of a selectable row: empty, or filled in its tint.",
            apps: [.tenra, .dalada]
        ) {
            SelectionIndicator(isSelected: isSelected,
                               tint: [AppColors.accent, AppColors.Status.positive, AppColors.Text.tertiary][tint])
                .onTapGesture { isSelected.toggle() }
        } controls: {
            ToggleControl("Selected", isOn: $isSelected)
            ChoiceControl("Tint", selection: $tint, options: [("Accent", 0), ("Success", 1), ("Muted", 2)])
        }
    }
}

private struct DateButtonsPage: View {
    @State private var date = Date()
    @State private var disabled = false

    var body: some View {
        ComponentPage(
            name: "DateButtons",
            summary: "Yesterday · Today · a past date: the date of a new transaction, above the keyboard.",
            apps: [.tenra],
            canvas: .fill,
            notes: ["No future dates. .dateButtonsSafeArea() pins it above the keyboard."]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                DateButtons(selectedDate: $date, isDisabled: disabled) { _ in }
                Text(date, format: .dateTime.day().month().year())
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        } controls: {
            ToggleControl("Disabled", isOn: $disabled)
        }
    }
}

private struct IconPickerPage: View {
    @State private var icon: IconSource? = .sfSymbol("cart.fill")
    @State private var showsPicker = false
    @State private var allowsLogos = true

    var body: some View {
        ComponentPage(
            name: "IconPicker",
            summary: "A sheet to pick an SF Symbol (grouped, searchable in 11 languages) or a brand logo from the app's catalog.",
            since: "1.10.0",
            apps: [.tenra],
            notes: ["The logos tab shows when the app sets DesignKitLogoCatalog and allowsLogos is on."]
        ) {
            Button { showsPicker = true } label: {
                Icon(source: icon, style: .glassHero(size: AppIconSize.Tile.xl))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showsPicker) {
                IconPicker(selection: $icon, allowsLogos: allowsLogos)
            }
        } controls: {
            ToggleControl("Logos tab", isOn: $allowsLogos)
            ActionControl("Open the picker", systemImage: "square.grid.3x3") { showsPicker = true }
        }
    }
}

private struct SnapCardPickerPage: View {
    private struct Wallet: Identifiable {
        let id: String
        let name: String
        let symbol: String
        let balance: Double
    }

    @State private var selection: String? = "gold"
    @State private var centered = false
    @State private var state: SpecimenState = .content

    private let wallets = [
        Wallet(id: "gold", name: "Kaspi Gold", symbol: "creditcard.fill", balance: 1_284_500),
        Wallet(id: "cash", name: "Cash", symbol: "banknote.fill", balance: 42_000),
        Wallet(id: "deposit", name: "Deposit", symbol: "lock.fill", balance: 2_500_000),
    ]

    var body: some View {
        ComponentPage(
            name: "SnapCardPicker",
            summary: "Pick one by swiping cards: full-width cards that snap, the neighbours peeking in (fill), or cards of one width with the centred one full size (centered, 5.0.0); the centred card is the selection, a tap selects too.",
            since: "2.9.0",
            apps: [.tenra],
            canvas: .bleed,
            notes: [
                "The card is the app's (SelectableBalanceCard, a category card); the picker passes it isSelected and the action that selects it.",
                "It aligns only once its container is measured, so a selection that arrives after it appears still scrolls into place.",
                "centered(width:): the neighbours a little smaller and paler, the selection following the centre as the row scrolls. PickerCarousel and OptionCardPicker are built on it.",
                "5.2.0: fill's selection follows the centre during a drag too (it waited for the row to stop), and centered no longer clips its cards' outline at the top and bottom.",
            ],
            styles: ["fill", "centered"]
        ) {
            if state == .loading {
                SnapCardPickerSkeleton { SelectableBalanceCardSkeleton() }
            } else if centered {
                SnapCardPicker(wallets, selection: $selection, style: .centered(width: 220)) { wallet, isSelected, select in
                    SelectableBalanceCard(iconSource: .sfSymbol(wallet.symbol), title: wallet.name,
                                          amount: wallet.balance, currency: "KZT",
                                          isSelected: isSelected, action: select)
                }
            } else {
                SnapCardPicker(wallets, selection: $selection) { wallet, isSelected, select in
                    SelectableBalanceCard(iconSource: .sfSymbol(wallet.symbol), title: wallet.name,
                                          amount: wallet.balance, currency: "KZT",
                                          isSelected: isSelected, action: select)
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Style", selection: $centered, options: [("Fill", false), ("Centered", true)])
            ChoiceControl("Selection", selection: $selection, options: wallets.map { ($0.name, Optional($0.id)) })
        }
    }
}

private struct OptionCardPickerPage: View {
    private enum Background: String, CaseIterable, Hashable {
        case none = "None"
        case gradient = "Gradient"
        case photo = "Photo"
    }

    @State private var selection: Background = .gradient
    @State private var hasSettings = true
    @State private var moves = true
    @State private var intensity = 0.6
    @State private var hasPhoto = true
    @State private var blursPhoto = false
    @State private var photoItem: PhotosPickerItem?
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "OptionCardPicker",
            summary: "Options as large previews in a carousel: the centred one is the choice, outlined in the accent, the neighbours peek at the sides; under it, the chosen option's settings.",
            since: "2.9.0",
            apps: [.tenra],
            canvas: .bleed,
            notes: [
                "6.0.0: the only look. A swipe or a tap on a neighbour changes the choice, with the selection haptic; only the centred preview moves.",
                "settings: what the app sets for the chosen option, in DesignKit's rows: a FormSection of UniversalRows (a PhotosPicker's label, .toggle, .slider, a destructive .action), inset dividers between them.",
                "artwork fills the frame it is given: a phone's shape, 180 × 270.",
            ]
        ) {
            if state == .loading {
                OptionCardPickerSkeleton()
            } else if hasSettings {
                OptionCardPicker(Background.allCases, selection: $selection, title: { $0.rawValue }) { background in
                    artwork(background)
                } settings: { background in
                    settings(background)
                }
            } else {
                OptionCardPicker(Background.allCases, selection: $selection, title: { $0.rawValue }) { background in
                    artwork(background)
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Settings", isOn: $hasSettings)
        }
    }

    @ViewBuilder
    private func artwork(_ background: Background) -> some View {
        switch background {
        case .none: Rectangle().fill(AppColors.Background.page)
        case .gradient: AuroraBackground(motion: moves ? .drift : .still).opacity(intensity)
        case .photo: GalleryPhotoView(photo: GalleryPhoto.samples[0]).blur(radius: blursPhoto ? 8 : 0, opaque: true)
        }
    }

    /// What each background sets, as an app would put it: DesignKit's form rows in a card.
    @ViewBuilder
    private func settings(_ background: Background) -> some View {
        switch background {
        case .none:
            EmptyView()
        case .gradient:
            FormSection(header: "Colours") {
                UniversalRow("Moves slowly", icon: "wind", accessory: .toggle($moves))
                UniversalRow("Intensity", icon: "circle.lefthalf.filled",
                             accessory: .slider($intensity, in: 0.1...1, valueText: "\(Int((intensity * 100).rounded()))%"))
            }
            .screenPadding()
        case .photo:
            FormSection {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    UniversalRow(hasPhoto ? "Change photo" : "Choose a photo", icon: "photo.on.rectangle",
                                 titleColor: AppColors.accent)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // The picker's label does not pass the row's divider inset out: its icon and space.
                .rowDividerInset(AppIconSize.lg + AppSpacing.md)
                if hasPhoto {
                    UniversalRow("Blur", icon: "camera.filters", accessory: .toggle($blursPhoto))
                    UniversalRow("Remove photo", icon: "trash", role: .destructive, accessory: .action {
                        hasPhoto = false
                    })
                }
            }
            .screenPadding()
            .onChange(of: photoItem) { _, item in
                if item != nil { hasPhoto = true; photoItem = nil }
            }
        }
    }
}

private struct PickerCarouselPage: View {
    private struct Hat: Identifiable {
        let id: String
        let accessory: CreatureAccessory?
        let name: String
        let condition: String?
    }

    private let hats: [Hat] = [
        Hat(id: "none", accessory: nil, name: "Nothing", condition: nil),
        Hat(id: "glasses", accessory: .glasses, name: "Glasses", condition: nil),
        Hat(id: "headphones", accessory: .headphones, name: "Headphones", condition: nil),
        Hat(id: "sunglasses", accessory: .sunglasses, name: "Sunglasses", condition: "Open the app 7 days in a row"),
        Hat(id: "crown", accessory: .crown, name: "Crown", condition: "Reach a savings goal"),
        Hat(id: "partyHat", accessory: .partyHat, name: "Party hat", condition: "Create your first goal"),
    ]

    @State private var focused: String? = "glasses"
    @State private var chosen: String? = "glasses"
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "PickerCarousel",
            summary: "Options to try on, side by side: the middle card is the focused one; closed ones are dim with a lock, and what opens the focused one shows above.",
            since: "4.14.0",
            apps: [.tenra],
            canvas: .fill,
            notes: [
                "Scrolling and a tap on a card change focused; the app decides what that does (Ten tries the accessory on, an open one is put on at once).",
                "Pictures are drawn still; draw the focused option large above the carousel.",
                "Strings: common.locked (VoiceOver), unless lockedLabel is given.",
            ]
        ) {
            if state == .loading {
                PickerCarouselSkeleton()
            } else {
                PickerCarousel(
                    items: hats,
                    focused: $focused,
                    chosen: chosen,
                    title: { $0.name },
                    condition: { $0.condition }
                ) { hat in
                    ParticleCreature(mood: .idle, accessory: hat.accessory)
                }
                .onChange(of: focused) { _, id in
                    if let hat = hats.first(where: { $0.id == id }), hat.condition == nil { chosen = id }
                }
            }
        } controls: {
            StateControl(state: $state)
        }
    }
}

#Preview { NavigationStack { SelectionScreen() } }
