//
//  NavigationScreen.swift
//  DesignKit Gallery
//
//  Headers and navigation: section headers, a detail screen's hero, the carousel, onboarding
//  steps, the tab bar's plus.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct NavigationScreen: View {
    static let title = "Headers & Navigation"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        SectionHeaderPage()
        HeroSectionPage()
        UniversalCarouselPage()
        OnboardingStepIndicatorPage()
        PlusTabLabelPage()
        CreatureTabLabelPage()
        LiveSessionBarPage()
        PagerArrowsPage()
    }
}

private struct SectionHeaderPage: View {
    @State private var style: SectionHeader.Style = .default
    @State private var showsIcon = true
    @State private var trailingSymbol = ""
    @State private var tinted = false
    @State private var trailing = 1
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "SectionHeader",
            summary: "The title over a section in three styles: default (a form, a card, a List section, a screen's with the screen padding), large (a screen's own sections) and card (a day in a transaction list), with symbols around the title and an optional action at the end of the line.",
            apps: [.tenra, .dalada, .platina],
            canvas: .fill,
            notes: [
                "Both symbols show in every style (3.2.0), in the title's font: the one before the title in the accent, the one right after it in the tertiary grey. Tint colours both.",
                "The symbol after the title says what the header does: chevron.forward for one that leads somewhere (wrap it in a NavigationLink), info.circle for one that explains.",
                "The action (1.15.0) is any view: a NavigationLink “All”, a button, a spinner, a day's total. It takes bodySmall and sits inside the style's padding.",
                "8.0.0: one look for a section's title, bold and in sentence case, in a List's header too. compact, the small grey uppercase label, is removed (docs/migration-8.0.md); default has no padding of its own, so on a screen add .screenPadding().",
                "2.0.0: SectionHeaderView before; DateSectionHeaderView is the card style with the day's total as the action.",
            ],
            styles: ["default", "large", "card"],
            code: headerCode,
            cases: headerCases
        ) {
            if state == .loading {
                SectionHeaderSkeleton(style: style, showsTrailing: trailing != 0, showsIcon: showsIcon)
            } else {
                switch trailing {
                case 1:
                    header(leading: "map") {
                        NavigationLink("All") { Text("All trips").navigationTitle("Trips") }
                    }
                case 2:
                    header(leading: "icloud.and.arrow.up") {
                        ProgressView()
                    }
                case 3:
                    header(leading: "calendar") {
                        FormattedAmountText(amount: 45_000, currency: "KZT", prefix: "-",
                                            fontSize: AppTypography.bodySmall, fontWeight: .semibold,
                                            color: AppColors.Text.tertiary)
                    }
                default:
                    SectionHeader(title, systemImage: showsIcon ? "map" : nil,
                                  trailingSystemImage: trailingSymbol.isEmpty ? nil : trailingSymbol,
                                  tint: tinted ? AppColors.Status.positive : nil, style: style)
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Style", selection: $style, options: [
                ("Default", .default), ("Large", .large), ("Card", .card),
            ])
            ChoiceControl("Action", selection: $trailing, options: [("None", 0), ("All", 1), ("Spinner", 2), ("Total", 3)])
            ToggleControl("Icon before the title", isOn: $showsIcon)
            ChoiceControl("Icon after the title (3.2.0)", selection: $trailingSymbol, options: [
                ("None", ""), ("Chevron", "chevron.forward"), ("Info", "info.circle"),
            ])
            ToggleControl("Tint (green)", isOn: $tinted)
        }
    }

    private func header<Trailing: View>(leading: String, @ViewBuilder trailing: () -> Trailing) -> SectionHeader {
        SectionHeader(title, systemImage: showsIcon ? leading : nil,
                      trailingSystemImage: trailingSymbol.isEmpty ? nil : trailingSymbol,
                      tint: tinted ? AppColors.Status.positive : nil, style: style, trailing: trailing)
    }

    private var title: String {
        switch style {
        case .card: "Yesterday"
        default: "Recent trips"
        }
    }

    /// The symbol before the title, as the preview picks it for the action.
    private var leadingSymbol: String {
        switch trailing {
        case 2: "icloud.and.arrow.up"
        case 3: "calendar"
        default: "map"
        }
    }

    /// The action at the end of the line, as the call writes it; nil without one.
    private var actionCode: String? {
        switch trailing {
        case 1:
            return SwiftCode.call("NavigationLink", [.text("All")], trailing: "TripsView()")
        case 2:
            return "ProgressView()"
        case 3:
            return SwiftCode.call("FormattedAmountText", [
                .labeled("amount", "45_000"),
                .text("currency", "KZT"),
                .text("prefix", "-"),
                .labeled("fontSize", "AppTypography.bodySmall"),
                .labeled("color", "AppColors.Text.tertiary"),
            ])
        default:
            return nil
        }
    }

    /// The call as the controls set it, the defaults left out.
    private var headerCode: String {
        if state == .loading {
            return SwiftCode.call("SectionHeaderSkeleton", [
                .option("style", ".\(style)", default: ".default"),
                .flag("showsTrailing", trailing != 0),
                .flag("showsIcon", showsIcon),
            ])
        }
        return SwiftCode.call("SectionHeader", [
            .text(title),
            showsIcon ? .text("systemImage", leadingSymbol) : nil,
            trailingSymbol.isEmpty ? nil : .text("trailingSystemImage", trailingSymbol),
            tinted ? .labeled("tint", "AppColors.Status.positive") : nil,
            .option("style", ".\(style)", default: ".default"),
        ], trailing: actionCode)
    }

    /// Headers as the apps' screens use them.
    private var headerCases: [SpecimenCase] {
        [
            SpecimenCase("Recent trips") {
                style = .default; showsIcon = true; trailingSymbol = ""; tinted = false; trailing = 1
                state = .content
            },
            SpecimenCase("Day total") {
                style = .card; showsIcon = false; trailingSymbol = ""; tinted = false; trailing = 3
                state = .content
            },
            SpecimenCase("Syncing") {
                style = .large; showsIcon = true; trailingSymbol = ""; tinted = false; trailing = 2
                state = .content
            },
            SpecimenCase("With info") {
                style = .default; showsIcon = false; trailingSymbol = "info.circle"; tinted = false; trailing = 0
                state = .content
            },
            SpecimenCase("Leads on") {
                style = .large; showsIcon = true; trailingSymbol = "chevron.forward"; tinted = true; trailing = 0
                state = .content
            },
        ]
    }
}

private struct HeroSectionPage: View {
    @State private var showsProgress = true
    @State private var showsIcon = true
    @State private var spent = 185_000.0
    @State private var onColor = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "HeroSection",
            summary: "The top of a detail screen: the icon, the name, the main amount, a subtitle and progress.",
            apps: [.tenra],
            canvas: onColor ? .bleed : .tall(minHeight: 300),
            notes: ["Inside .heroBackground (4.5.0) its text is white and the subtitle semibold."]
        ) {
            if state == .loading {
                HeroSectionSkeleton(showsIcon: showsIcon, showsProgress: showsProgress)
            } else {
                HeroSection(
                    icon: .sfSymbol("fork.knife"),
                    title: "Food",
                    iconTint: .monochrome(.orange),
                    showsIcon: showsIcon,
                    primaryAmount: spent,
                    primaryCurrency: "KZT",
                    subtitle: "This month",
                    progress: showsProgress ? ProgressConfig(current: spent, total: 250_000, label: "Budget", color: .orange) : nil
                )
                .galleryHeroBackground(onColor, color: AppColors.Status.warning)
            }
        } controls: {
            StateControl(state: $state)
            HeroBackgroundControl(onColor: $onColor)
            ToggleControl("Icon", isOn: $showsIcon)
            ToggleControl("Progress", isOn: $showsProgress)
            SliderControl("Spent of 250 000", value: $spent, in: 0...400_000, step: 1_000)
        }
    }
}

private struct UniversalCarouselPage: View {
    @State private var cards = true
    @State private var dims = true
    @State private var filter = "month"

    var body: some View {
        ComponentPage(
            name: "UniversalCarousel",
            summary: "The only horizontal scroller: filter chips or cards; .carouselItemTransition() dims cards as they scroll off.",
            apps: [.tenra],
            canvas: .bleed,
            notes: ["Presets: .standard, .filter, .cards (spacing, padding, snapping)."]
        ) {
            if cards {
                UniversalCarousel(config: .cards) {
                    ForEach(["Kaspi Gold", "Halyk", "Freedom", "Jusan"], id: \.self) { name in
                        BalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: name,
                                    amount: 120_000, currency: "KZT")
                            .carouselItemTransition(isEnabled: dims)
                    }
                }
            } else {
                UniversalCarousel(config: .filter) {
                    ForEach(["week", "month", "year", "all"], id: \.self) { key in
                        UniversalFilterButton(title: key.capitalized, isSelected: filter == key, onTap: { filter = key })
                    }
                }
            }
        } controls: {
            ChoiceControl("Content", selection: $cards, options: [("Cards", true), ("Filters", false)])
            ToggleControl("Dim cards off-screen", isOn: $dims)
        }
    }
}

private struct OnboardingStepIndicatorPage: View {
    @State private var step = 1

    var body: some View {
        ComponentPage(
            name: "OnboardingStepIndicator",
            summary: "Where onboarding is: a symbol per step, the current one in the accent.",
            apps: [.tenra, .dalada]
        ) {
            OnboardingStepIndicator(currentStep: step, symbols: ["map", "tent.fill", "person.2.fill", "checkmark.seal.fill"])
        } controls: {
            StepperControl("Step", value: $step, in: 0...3)
        }
    }
}

private struct PlusTabLabelPage: View {
    @State private var isExpanded = false

    var body: some View {
        ComponentPage(
            name: "PlusTabLabel",
            summary: "The tab bar's “+” that turns into × while its menu is open.",
            apps: [.tenra]
        ) {
            PlusTabLabel(isExpanded: isExpanded)
                .font(AppTypography.bodyEmphasis)
                .onTapGesture { withAnimation(AppAnimation.contentSpring) { isExpanded.toggle() } }
        } controls: {
            ToggleControl("Expanded", isOn: $isExpanded)
        }
    }
}

private struct CreatureTabLabelPage: View {
    @State private var title = "Assistant"

    var body: some View {
        ComponentPage(
            name: "CreatureTabLabel",
            summary: "An assistant's tab: ParticleCreature's still glyph (twelve dots and two eyes) over a title, tinted by the bar.",
            since: "4.8.0",
            apps: [.tenra, .platina],
            notes: [
                "A tab item takes only an image and a text, so the live creature waits inside the screen the tab opens.",
                "The glyph is CreatureGlyph.templateImage(): a template image, so the bar tints it like a symbol.",
            ]
        ) {
            CreatureTabLabel(title: title)
                .foregroundStyle(AppColors.accent)
        } controls: {
            TextControl("Title", text: $title)
        }
    }
}

private struct LiveSessionBarPage: View {
    @State private var isPaused = false
    @State private var showsDetail = true
    @State private var startedAt = Date.now.addingTimeInterval(-754)
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "LiveSessionBar",
            summary: "Something going on above the tabs: a pulsing recording dot (a pause sign when paused), the running time, a detail; a tap opens it.",
            since: "2.8.0",
            apps: [.dalada, .platina],
            canvas: .fill,
            notes: [
                ".liveSessionAccessory(isEnabled:) puts it in the tab bar's bottom accessory (iOS 26.1). On iOS 26.0 nothing is shown: offer another way back (LiveSessionAccessory.isAvailable).",
            ]
        ) {
            if state == .loading {
                LiveSessionBarSkeleton()
                    .padding(.vertical, AppSpacing.md)
            } else {
                LiveSessionBar(startedAt: startedAt, isPaused: isPaused, detail: showsDetail ? "3.2 km" : nil,
                               accessibilityLabel: "Trip recording in progress") {}
                    .padding(.vertical, AppSpacing.md)
                    .glassEffect(.regular, in: Capsule())
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Paused", isOn: $isPaused)
            ToggleControl("Detail", isOn: $showsDetail)
            ActionControl("Restart the clock") { startedAt = .now }
        }
    }
}

private struct PagerArrowsPage: View {
    @State private var index = 2
    @State private var showsArrows = true

    private let months = ["July", "August", "September", "October"]

    var body: some View {
        ComponentPage(
            name: "PagerArrows",
            summary: "Step through pages with arrows as well as a swipe: a chevron on each side of the content, greyed at either end.",
            since: "2.9.0",
            apps: [.tenra],
            canvas: .fill,
            notes: ["Put it over a paged TabView's content: the swipe animates itself, an arrow animates the page change."]
        ) {
            PagerArrows(index: $index, count: months.count, showsArrows: showsArrows) {
                TabView(selection: $index) {
                    ForEach(months.indices, id: \.self) { page in
                        Text(months[page])
                            .font(AppTypography.h3)
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 140)
            }
        } controls: {
            ToggleControl("Arrows", isOn: $showsArrows)
            StepperControl("Page", value: $index, in: 0...3)
        }
    }
}

#Preview { NavigationStack { NavigationScreen() } }
