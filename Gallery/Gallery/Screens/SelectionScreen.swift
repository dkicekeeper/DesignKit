//
//  SelectionScreen.swift
//  DesignKit Gallery
//
//  Selection: segments, chips, rating, the check circle, quick dates, the icon picker.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

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
    }
}

private struct SegmentedPickerPage: View {
    @State private var selection = 0
    @State private var count = 3

    var body: some View {
        ComponentPage(
            name: "SegmentedPicker",
            summary: "Two to four exclusive modes on Liquid Glass.",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "A selection haptic as the segment moves (2.3.0, HapticCue.select).",
            ]
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
            apps: [.dalada],
            canvas: .fill,
            notes: [
                "allTitle (2.8.0): an \"All\" chip in front, selected while nothing is picked; a tap clears the selection.",
                "inset (3.1.0): in a FormSection card pass the card's padding, AppSpacing.lg. The caption and the first chip start there; the chips still scroll to the card's edge.",
            ]
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
                               tint: [AppColors.accent, AppColors.success, AppColors.textTertiary][tint])
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
                    .foregroundStyle(AppColors.textSecondary)
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
                "centered(width:): the neighbours a little smaller and paler, the selection following the centre as the row scrolls. PickerCarousel and OptionCardPicker(style: .carousel) are built on it.",
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
    @State private var style: OptionCardPickerStyle = .carousel
    @State private var hasSettings = true
    @State private var moves = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "OptionCardPicker · OptionCard",
            summary: "Options as pictures, the chosen one outlined in the accent with a check. carousel (5.2.0): the chosen option large on top, the options in a row under it, its settings under the row; list: cards one under another.",
            since: "2.9.0",
            apps: [.tenra],
            canvas: style == .carousel ? .bleed : .fill,
            notes: [
                "carousel: as Ten's wardrobe. The centred card is the choice, a swipe or a tap changes it; the preview on top is the option's artwork in a phone's shape.",
                "settings: what the app sets for the chosen option (Choose a photo for a photo); under the row, or under the cards in list.",
                "OptionCard alone for a list that mixes plain options with one that opens a picker (wrap that card in a PhotosPicker).",
            ],
            styles: ["list", "carousel"]
        ) {
            if state == .loading {
                if style == .carousel { OptionCardCarouselSkeleton() } else { OptionCardSkeleton() }
            } else if hasSettings {
                OptionCardPicker(Background.allCases, selection: $selection, style: style, title: { $0.rawValue }) { background in
                    artwork(background)
                } settings: { background in
                    settings(background)
                }
            } else {
                OptionCardPicker(Background.allCases, selection: $selection, style: style, title: { $0.rawValue }) { background in
                    artwork(background)
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Style", selection: $style, options: [("List", .list), ("Carousel", .carousel)])
            ToggleControl("Settings", isOn: $hasSettings)
        }
    }

    @ViewBuilder
    private func artwork(_ background: Background) -> some View {
        switch background {
        case .none: Rectangle().fill(AppColors.bgBase)
        case .gradient: AuroraBackground(motion: moves ? .drift : .still)
        case .photo: GalleryPhotoView(photo: GalleryPhoto.samples[0])
        }
    }

    /// What each background sets, as an app would put it.
    @ViewBuilder
    private func settings(_ background: Background) -> some View {
        switch background {
        case .none:
            Text("The plain background of the screen.")
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary)
        case .gradient:
            FormSection {
                ToggleSettingsRow(title: "Moves slowly", config: .standard, isOn: $moves)
            }
            .screenPadding()
        case .photo:
            DSButton("Choose a photo", systemImage: "photo.on.rectangle", appearance: .secondary) {}
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
