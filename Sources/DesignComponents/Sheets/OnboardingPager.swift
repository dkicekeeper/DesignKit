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
///         .dsButton()
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

    /// The pager's frame, for the pages' parallax (2.3.0).
    @State private var pagerFrame: CGRect?

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
            // Global, not a named space: the pages are hosted by the system's paging view.
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { pagerFrame = $0 }
            .environment(\.onboardingPagerFrame, pagerFrame)

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
                    // 2.3.0: in an OnboardingPager the symbol lags behind the page as it swipes.
                    .modifier(OnboardingParallaxModifier())
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

// MARK: - Parallax (2.3.0)

extension EnvironmentValues {
    /// The global frame of the `OnboardingPager` around a page; `nil` outside one.
    @Entry var onboardingPagerFrame: CGRect? = nil
}

enum OnboardingParallaxMetrics {
    /// The symbol moves at 60 % of the page's speed.
    static let lag: CGFloat = 0.4
    /// A page swiped its full width away: the symbol shrinks by this and fades by `fade`.
    static let shrink: CGFloat = 0.2
    static let fade: Double = 0.5
}

/// Moves the view slower than its page while the pager swipes, shrinking and fading it a
/// little, so the picture and the text part at different speeds. One `visualEffect`; nothing
/// re-renders. Off under Reduce Motion and `.designKitMotion(false)`, and outside a pager.
struct OnboardingParallaxModifier: ViewModifier {
    @Environment(\.onboardingPagerFrame) private var pagerFrame
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion

    func body(content: Content) -> some View {
        let pager = !reduceMotion && designKitMotion ? pagerFrame : nil
        content
            .visualEffect { view, proxy in
                // How far the page has moved from the centre of the pager.
                let shift = pager.map { proxy.frame(in: .global).midX - $0.midX } ?? 0
                let progress = min(abs(shift) / max(pager?.width ?? 1, 1), 1)
                return view
                    .offset(x: -shift * OnboardingParallaxMetrics.lag)
                    .scaleEffect(1 - progress * OnboardingParallaxMetrics.shrink)
                    .opacity(1 - Double(progress) * OnboardingParallaxMetrics.fade)
            }
    }
}
