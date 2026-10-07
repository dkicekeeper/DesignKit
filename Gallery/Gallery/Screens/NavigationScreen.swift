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
    var body: some View {
        ShowcasePage(title: "Headers & Navigation") {
            SectionHeaderViewPage()
            SettingsSectionHeaderViewPage()
            DateSectionHeaderViewPage()
            HeroSectionPage()
            UniversalCarouselPage()
            OnboardingStepIndicatorPage()
            PlusTabLabelPage()
        }
    }
}

private struct SectionHeaderViewPage: View {
    @State private var style: SectionHeaderView.Style = .default
    @State private var showsIcon = true
    @State private var trailing = 1
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "SectionHeaderView",
            summary: "The title over a section: default, compact (settings) or large (a screen's sections), with an optional action at the end of the line.",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "The icon shows in the large style only.",
                "The action (1.15.0) is any view: a NavigationLink “All”, a button, a spinner. It takes bodySmall and sits inside the style's padding.",
            ]
        ) {
            if state == .loading {
                SectionHeaderViewSkeleton(style: style, showsTrailing: trailing != 0)
            } else {
                switch trailing {
                case 1:
                    SectionHeaderView("Recent trips", systemImage: showsIcon ? "map" : nil, style: style) {
                        NavigationLink("All") { Text("All trips").navigationTitle("Trips") }
                    }
                case 2:
                    SectionHeaderView("Waiting to send", systemImage: showsIcon ? "icloud.and.arrow.up" : nil, style: style) {
                        ProgressView()
                    }
                default:
                    SectionHeaderView("Recent trips", systemImage: showsIcon ? "map" : nil, style: style)
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Style", selection: $style, options: [("Default", .default), ("Compact", .compact), ("Large", .large)])
            ChoiceControl("Action", selection: $trailing, options: [("None", 0), ("All", 1), ("Spinner", 2)])
            ToggleControl("Icon", isOn: $showsIcon)
        }
    }
}

private struct SettingsSectionHeaderViewPage: View {
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "SettingsSectionHeaderView",
            summary: "The small caption over a group of settings rows.",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                SectionHeaderViewSkeleton(style: .compact)
            } else {
                SettingsSectionHeaderView(title: "Notifications")
            }
        } controls: {
            StateControl(state: $state)
        }
    }
}

private struct DateSectionHeaderViewPage: View {
    @State private var showsAmount = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "DateSectionHeaderView",
            summary: "A day's header in a transaction list: the label the app gives (Today, Yesterday, the date) and the day's expenses.",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                DateSectionHeaderViewSkeleton()
            } else {
                DateSectionHeaderView(dateKey: "Yesterday", amount: showsAmount ? 45_000 : nil,
                                      currency: showsAmount ? "KZT" : nil)
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Day total", isOn: $showsAmount)
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

#Preview { NavigationStack { NavigationScreen() } }
