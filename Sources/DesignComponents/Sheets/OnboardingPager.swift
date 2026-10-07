//
//  OnboardingPager.swift
//  DesignKit
//
//  First-launch introduction: swipeable pages with dots, a Skip button at the top and the
//  page's own buttons at the bottom. Moved from Dalada's IntroOnboardingView (0.7.0); the
//  pages, their order and what the buttons do stay in the app. For a data-collection flow
//  in a NavigationStack use OnboardingPageContainer + OnboardingStepIndicator instead.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Paged onboarding. The app owns `selection` and moves it from the buttons.
///
/// ```swift
/// enum Intro: Hashable, CaseIterable { case welcome, places, location }
/// @State private var page: Intro = .welcome
///
/// OnboardingPager(pages: Intro.allCases, selection: $page, onSkip: finish) { page in
///     switch page {
///     case .welcome: OnboardingPage(systemImage: "map", title: "...", message: "...")
///     ...
///     }
/// } actions: { page in
///     Button { next() } label: { Text("Next").frame(maxWidth: .infinity) }
///         .primaryButton()
/// }
/// ```
public struct OnboardingPager<Page: Hashable, Content: View, Actions: View>: View {
    let pages: [Page]
    @Binding var selection: Page
    let skipTitle: String
    let canSkip: (Page) -> Bool
    let onSkip: (() -> Void)?
    let content: (Page) -> Content
    let actions: (Page) -> Actions

    /// - Parameters:
    ///   - skipTitle: top-trailing button; key `onboarding.cta.skip` (default "Skip").
    ///   - canSkip: pages that show Skip (e.g. not the permission pages). All by default.
    ///   - onSkip: `nil` hides Skip everywhere.
    ///   - actions: buttons under the pages for the current page.
    public init(
        pages: [Page],
        selection: Binding<Page>,
        skipTitle: String = String(localized: "onboarding.cta.skip", defaultValue: "Skip"),
        canSkip: @escaping (Page) -> Bool = { _ in true },
        onSkip: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Page) -> Content,
        @ViewBuilder actions: @escaping (Page) -> Actions
    ) {
        self.pages = pages
        self._selection = selection
        self.skipTitle = skipTitle
        self.canSkip = canSkip
        self.onSkip = onSkip
        self.content = content
        self.actions = actions
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if let onSkip, canSkip(selection) {
                    Button(skipTitle, action: onSkip)
                        .font(AppTypography.bodySmall)
                }
            }
            .frame(height: 44)
            .screenPadding()

            TabView(selection: $selection) {
                ForEach(pages, id: \.self) { page in
                    content(page)
                        .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            actions(selection)
                .screenPadding()
                .padding(.vertical, AppSpacing.lg)
        }
    }
}

/// One onboarding page: `HeroSymbol`, title, text and optional content under them.
///
/// ```swift
/// OnboardingPage(systemImage: "arrow.down.circle", title: offlineTitle, message: offlineText) {
///     RegionCard(region)
/// }
/// ```
///
/// Scrolls when the text is long (large Dynamic Type).
public struct OnboardingPage<Accessory: View>: View {
    let systemImage: String
    let title: String
    let message: String
    let accessory: () -> Accessory

    public init(
        systemImage: String,
        title: String,
        message: String,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.accessory = accessory
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                HeroSymbol(systemImage: systemImage)
                    .padding(.top, AppSpacing.xl)
                VStack(spacing: AppSpacing.sm) {
                    Text(verbatim: title)
                        .font(AppTypography.h3)
                        .foregroundStyle(AppColors.Text.primary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: message)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.secondary)
                        .multilineTextAlignment(.center)
                }
                accessory()
            }
            .screenPadding()
            .padding(.bottom, AppSpacing.xxl)
        }
    }
}

public extension OnboardingPage where Accessory == EmptyView {
    init(systemImage: String, title: String, message: String) {
        self.init(systemImage: systemImage, title: title, message: message) { EmptyView() }
    }
}
