//
//  ComponentIndex.swift
//  DesignKit Gallery
//
//  Which Gallery page shows a component, so a release note can link a name it mentions
//  (`RatingSummary(average:…)`) to the component's page. Built from the screens' own pages, like
//  the home screen's counts, so it never goes stale.
//

import SwiftUI

/// The Gallery screens that hold component pages.
enum GalleryScreen: String, CaseIterable, Identifiable, Sendable {
    case surfaces, motion, actions, textInput, selection, amounts, settingsRows, dataRows,
         moneyCards, progressCards, contentCards, charts, progress, feedback, navigation, media,
         content, sheets, effects

    var id: String { rawValue }

    @ViewBuilder var pages: some View {
        switch self {
        case .surfaces: SurfacesScreen.pages
        case .motion: MotionScreen.pages
        case .actions: ActionsScreen.pages
        case .textInput: TextInputScreen.pages
        case .selection: SelectionScreen.pages
        case .amounts: AmountsScreen.pages
        case .settingsRows: SettingsRowsScreen.pages
        case .dataRows: DataRowsScreen.pages
        case .moneyCards: MoneyCardsScreen.pages
        case .progressCards: ProgressCardsScreen.pages
        case .contentCards: ContentCardsScreen.pages
        case .charts: ChartsScreen.pages
        case .progress: ProgressScreen.pages
        case .feedback: FeedbackScreen.pages
        case .navigation: NavigationScreen.pages
        case .media: MediaScreen.pages
        case .content: ContentScreen.pages
        case .sheets: SheetsScreen.pages
        case .effects: EffectsScreen.pages
        }
    }

    /// The screen, opened on the page titled `page`.
    func destination(page: String) -> some View {
        Group {
            switch self {
            case .surfaces: SurfacesScreen()
            case .motion: MotionScreen()
            case .actions: ActionsScreen()
            case .textInput: TextInputScreen()
            case .selection: SelectionScreen()
            case .amounts: AmountsScreen()
            case .settingsRows: SettingsRowsScreen()
            case .dataRows: DataRowsScreen()
            case .moneyCards: MoneyCardsScreen()
            case .progressCards: ProgressCardsScreen()
            case .contentCards: ContentCardsScreen()
            case .charts: ChartsScreen()
            case .progress: ProgressScreen()
            case .feedback: FeedbackScreen()
            case .navigation: NavigationScreen()
            case .media: MediaScreen()
            case .content: ContentScreen()
            case .sheets: SheetsScreen()
            case .effects: EffectsScreen()
            }
        }
        .environment(\.showcaseInitialPage, page)
    }
}

/// A component page a release note can open.
struct ComponentLink: Hashable, Identifiable, Sendable {
    /// The page's title ("Rating · RatingPicker").
    let page: String
    let screen: GalleryScreen

    var id: String { page }
}

/// Component names → their pages.
struct ComponentIndex: Equatable, Sendable {
    private var links: [String: ComponentLink] = [:]

    var isEmpty: Bool { links.isEmpty }

    /// Files a page under each name its title gives: "Rating · RatingPicker" under both,
    /// "Mini/HeroBarPair" under `MiniBarPair` and `HeroBarPair`, ".cascadeIn(index:)" under
    /// `.cascadeIn`.
    mutating func register(page: String, on screen: GalleryScreen) {
        for part in page.components(separatedBy: " · ") {
            let name = Self.bareName(part)
            let names = name.hasPrefix("Mini/Hero")
                ? ["Mini" + name.dropFirst(9), "Hero" + name.dropFirst(9)]
                : [name]
            for name in names where links[name] == nil && !name.contains(" ") {
                links[name] = ComponentLink(page: page, screen: screen)
            }
        }
    }

    /// The page of the component a code span names, if the Gallery has one. A skeleton opens its
    /// component (Loading is its state); a 1.x name with `View` opens the component it became.
    func link(for codeSpan: String) -> ComponentLink? {
        let name = Self.bareName(codeSpan)
        var candidates = [name]
        if name.hasSuffix("Skeleton") { candidates.append(String(name.dropLast(8))) }
        if name.hasSuffix("View") { candidates.append(String(name.dropLast(4))) }
        if name.hasPrefix(".ds") { candidates.append(String(name.dropFirst(3))) }
        return candidates.lazy.compactMap { links[$0] }.first
    }

    /// The links for a release: the pages of the names it mentions, in order, each once.
    func links(for release: Changelog.Release) -> [ComponentLink] {
        var seen = Set<ComponentLink>()
        return release.codeSpans.compactMap(link(for:)).filter { seen.insert($0).inserted }
    }

    /// A name without its arguments: `RatingSummary(average:…)` → `RatingSummary`.
    private static func bareName(_ text: String) -> String {
        let name = text.split(separator: "(", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
        return name.trimmingCharacters(in: .whitespaces)
    }
}

extension EnvironmentValues {
    /// The Gallery's component pages, built once on the home screen (`ComponentIndexReader`).
    @Entry var componentIndex: ComponentIndex = ComponentIndex()
    /// The page a `ShowcasePage` opens on (its title), set by a link to a component.
    @Entry var showcaseInitialPage: String? = nil
}

/// Builds the index from every screen's pages, as `ShowcaseCount` counts them. Draws nothing.
struct ComponentIndexReader: View {
    @Binding var index: ComponentIndex

    var body: some View {
        ZStack {
            ForEach(GalleryScreen.allCases) { screen in
                Group(subviews: screen.pages) { subviews in
                    Color.clear.onAppear {
                        for subview in subviews where subview.containerValues.showcaseIsComponent {
                            index.register(page: subview.containerValues.showcaseTitle, on: screen)
                        }
                    }
                }
            }
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
