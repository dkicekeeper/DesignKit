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
            summary: "The title over a section in four styles: default, compact (a List or Form section, or a screen's with the screen padding), large (a screen's sections) and card (a day in a transaction list), with symbols around the title and an optional action at the end of the line.",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "Both symbols show in every style (3.2.0), in the title's font: the one before the title in the accent (the label's grey in compact), the one right after it in the tertiary grey. Tint colours both.",
                "The symbol after the title says what the header does: chevron.forward for one that leads somewhere (wrap it in a NavigationLink), info.circle for one that explains.",
                "The action (1.15.0) is any view: a NavigationLink “All”, a button, a spinner, a day's total. It takes bodySmall and sits inside the style's padding.",
                "3.2.0: compact has no padding of its own, as list had, and list is deprecated (it is compact). On a screen, add .screenPadding().",
                "2.0.0: SectionHeaderView before; SettingsSectionHeaderView is the compact style in a List, DateSectionHeaderView the card style with the day's total as the action.",
            ],
            styles: ["default", "compact", "large", "card"]
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
                                  tint: tinted ? AppColors.success : nil, style: style)
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Style", selection: $style, options: [
                ("Default", .default), ("Compact", .compact), ("Large", .large), ("Card", .card),
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
                      tint: tinted ? AppColors.success : nil, style: style, trailing: trailing)
    }

    private var title: String {
        switch style {
        case .compact: "Notifications"
        case .card: "Yesterday"
        default: "Recent trips"
        }
    }
}

private struct HeroSectionPage: View {
    @State private var showsProgress = true
    @State private var showsIcon = true
    @State private var spent = 185_000.0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "HeroSection",
            summary: "The top of a detail screen: the icon, the name, the main amount, a subtitle and progress.",
            apps: [.tenra],
            canvas: .tall(minHeight: 300)
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
            }
        } controls: {
            StateControl(state: $state)
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
            apps: [.dalada]
        ) {
            PlusTabLabel(isExpanded: isExpanded)
                .font(AppTypography.bodyEmphasis)
                .onTapGesture { withAnimation(AppAnimation.contentSpring) { isExpanded.toggle() } }
        } controls: {
            ToggleControl("Expanded", isOn: $isExpanded)
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
            apps: [.dalada],
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
