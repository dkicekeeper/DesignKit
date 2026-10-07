//
//  SheetsScreen.swift
//  DesignKit Gallery
//
//  Sheets and flows: a prompt, permission primers, onboarding and its pieces.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct SheetsScreen: View {
    var body: some View {
        ShowcasePage(title: "Sheets & Flows") {
            PromptSheetPage()
            PermissionPrimerViewPage()
            NotificationPermissionViewPage()
            OnboardingPagerPage()
            OnboardingPagePage()
            OnboardingPageContainerPage()
            LoopOnboardingHeroPage()
        }
    }
}

/// A button that presents a sheet: the preview of a component that lives in one.
private struct PresentButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "rectangle.portrait.bottomhalf.inset.filled")
                .frame(maxWidth: .infinity)
        }
        .appButton(.secondary)
    }
}

private struct PromptSheetPage: View {
    @State private var isPresented = false

    var body: some View {
        ComponentPage(
            name: "PromptSheet",
            summary: "A short question in a small sheet: a symbol, a title, a message, two answers.",
            since: "1.5.0",
            apps: [.tenra]
        ) {
            PresentButton(title: "Show the prompt") { isPresented = true }
                .sheet(isPresented: $isPresented) {
                    PromptSheet(
                        systemImage: "sparkles",
                        title: "Enjoying the app?",
                        message: "Your answer helps us decide what to improve next.",
                        primaryTitle: "Love it!",
                        secondaryTitle: "Not really",
                        onPrimary: { isPresented = false },
                        onSecondary: { isPresented = false }
                    )
                }
        }
    }
}

private struct PermissionPrimerViewPage: View {
    @State private var isPresented = false

    var body: some View {
        ComponentPage(
            name: "PermissionPrimerView",
            summary: "Why the app needs a permission, before the system alert: a hero symbol, the reason, Allow and Later.",
            since: "0.7.0",
            apps: [.tenra, .dalada],
            notes: ["Show it in a .medium sheet; Allow runs the system request."]
        ) {
            PresentButton(title: "Show the primer") { isPresented = true }
                .sheet(isPresented: $isPresented) {
                    PermissionPrimerView(
                        systemImage: "bell.badge",
                        title: "Don't miss replies",
                        message: "We'll tell you when a friend answers or a place you saved gets new rules.",
                        allowTitle: "Turn on",
                        laterTitle: "Not now",
                        onAllow: {
                            try? await Task.sleep(for: .seconds(1))
                            isPresented = false
                        },
                        onLater: { isPresented = false }
                    )
                    .presentationDetents([.medium])
                }
        }
    }
}

private struct NotificationPermissionViewPage: View {
    @State private var isPresented = false

    var body: some View {
        ComponentPage(
            name: "NotificationPermissionView",
            summary: "Tenra's notification primer: the same primer with the notification wording built in.",
            apps: [.tenra]
        ) {
            PresentButton(title: "Show it") { isPresented = true }
                .sheet(isPresented: $isPresented) {
                    NotificationPermissionView(
                        onAllow: { isPresented = false },
                        onSkip: { isPresented = false }
                    )
                }
        }
    }
}

private struct OnboardingPagerPage: View {
    @State private var isPresented = false

    var body: some View {
        ComponentPage(
            name: "OnboardingPager",
            summary: "Onboarding pages with dots, Skip where allowed and each page's own buttons.",
            since: "0.7.0",
            apps: [.dalada]
        ) {
            PresentButton(title: "Show onboarding") { isPresented = true }
                .fullScreenCover(isPresented: $isPresented) {
                    SampleOnboarding { isPresented = false }
                }
        }
    }
}

private struct OnboardingPagePage: View {
    @State private var showsAccessory = true

    var body: some View {
        ComponentPage(
            name: "OnboardingPage",
            summary: "One onboarding page: a hero symbol, a title, a message and an accessory.",
            since: "0.7.0",
            apps: [.dalada],
            canvas: .tall(minHeight: 420)
        ) {
            if showsAccessory {
                OnboardingPage(systemImage: "mappin.and.ellipse", title: "Places",
                               message: "Lakes, rivers and camps with reviews from people who were there.") {
                    FlowLayout {
                        ForEach(["Lake", "River", "Camp"], id: \.self) { BadgeView($0) }
                    }
                }
            } else {
                OnboardingPage(systemImage: "mappin.and.ellipse", title: "Places",
                               message: "Lakes, rivers and camps with reviews from people who were there.")
            }
        } controls: {
            ToggleControl("Accessory", isOn: $showsAccessory)
        }
    }
}

private struct OnboardingPageContainerPage: View {
    @State private var isPresented = false

    var body: some View {
        ComponentPage(
            name: "OnboardingPageContainer",
            summary: "Tenra's onboarding step: the step indicator, a title, content, Continue and Skip.",
            apps: [.tenra]
        ) {
            PresentButton(title: "Show a step") { isPresented = true }
                .fullScreenCover(isPresented: $isPresented) {
                    OnboardingPageContainer(
                        progressStep: 1,
                        title: "Main currency",
                        subtitle: "Totals and charts are shown in it. You can change it later.",
                        primaryButtonTitle: "Continue",
                        onPrimaryTap: { isPresented = false },
                        onSkip: { isPresented = false }
                    ) {
                        FlowLayout {
                            ForEach(["KZT", "USD", "EUR", "RUB"], id: \.self) {
                                BadgeView($0, color: AppColors.accent)
                            }
                        }
                    }
                }
        }
    }
}

private struct LoopOnboardingHeroPage: View {
    @State private var phase = 0

    private let symbols = ["sparkles", "chart.pie.fill", "bell.badge.fill"]

    var body: some View {
        ComponentPage(
            name: "LoopOnboardingHero",
            summary: "An onboarding hero symbol with a pulsing ring; .blurSlideHero reveals the text under it.",
            apps: [.tenra],
            canvas: .tall(minHeight: 280)
        ) {
            LoopOnboardingHero(symbol: symbols[phase])
                .id(phase)
        } controls: {
            ChoiceControl("Symbol", selection: $phase, options: [("Sparkles", 0), ("Chart", 1), ("Bell", 2)])
        }
    }
}

// MARK: - Sample onboarding

private struct SampleOnboarding: View {
    enum Page: Hashable, CaseIterable { case welcome, places, location, done }

    let onFinish: () -> Void
    @State private var page: Page = .welcome

    var body: some View {
        OnboardingPager(
            pages: Page.allCases,
            selection: $page,
            canSkip: { $0 != .location && $0 != .done },
            onSkip: onFinish
        ) { page in
            switch page {
            case .welcome:
                OnboardingPage(systemImage: "figure.fishing", title: "Welcome",
                               message: "Places, rules and trips for anglers and hikers.")
            case .places:
                OnboardingPage(systemImage: "mappin.and.ellipse", title: "Places",
                               message: "Lakes, rivers and camps with reviews from people who were there.") {
                    FlowLayout {
                        ForEach(["Lake", "River", "Camp"], id: \.self) { BadgeView($0) }
                    }
                }
            case .location:
                OnboardingPage(systemImage: "location.circle", title: "Your location",
                               message: "To show what is near you. Only while you use the app.")
            case .done:
                OnboardingPage(systemImage: "checkmark.seal", title: "All set", message: "Have a good trip.")
            }
        } actions: { page in
            VStack(spacing: AppSpacing.sm) {
                Button {
                    next()
                } label: {
                    Text(page == .location ? "Allow" : page == .done ? "Start" : "Next")
                        .frame(maxWidth: .infinity)
                }
                .appButton()
                if page == .location {
                    Button { next() } label: { Text("Later").frame(maxWidth: .infinity) }
                        .appButton(.secondary)
                }
            }
        }
        .background(AppColors.bgCard.ignoresSafeArea())
    }

    private func next() {
        let all = Page.allCases
        guard let index = all.firstIndex(of: page), index + 1 < all.count else { return onFinish() }
        withAnimation { page = all[index + 1] }
    }
}

#Preview { NavigationStack { SheetsScreen() } }
