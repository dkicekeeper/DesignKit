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

    /// The screen's title: the section a search result names (vNext).
    var title: String {
        switch self {
        case .surfaces: SurfacesScreen.title
        case .motion: MotionScreen.title
        case .actions: ActionsScreen.title
        case .textInput: TextInputScreen.title
        case .selection: SelectionScreen.title
        case .amounts: AmountsScreen.title
        case .settingsRows: SettingsRowsScreen.title
        case .dataRows: DataRowsScreen.title
        case .moneyCards: MoneyCardsScreen.title
        case .progressCards: ProgressCardsScreen.title
        case .contentCards: ContentCardsScreen.title
        case .charts: ChartsScreen.title
        case .progress: ProgressScreen.title
        case .feedback: FeedbackScreen.title
        case .navigation: NavigationScreen.title
        case .media: MediaScreen.title
        case .content: ContentScreen.title
        case .sheets: SheetsScreen.title
        case .effects: EffectsScreen.title
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
    /// What the component is for (vNext): the search reads it.
    var summary: String = ""

    var id: String { page }
}

/// Component names → their pages.
struct ComponentIndex: Equatable, Sendable {
    private var links: [String: ComponentLink] = [:]
    /// Every page once, in the order the screens list them (vNext): the search's order.
    private var ordered: [ComponentLink] = []

    var isEmpty: Bool { links.isEmpty }

    /// Files a page under each name its title gives: "Rating · RatingPicker" under both,
    /// "Mini/HeroBarPair" under `MiniBarPair` and `HeroBarPair`, ".cascadeIn(index:)" under
    /// `.cascadeIn`.
    mutating func register(page: String, summary: String = "", on screen: GalleryScreen) {
        if !ordered.contains(where: { $0.page == page }) {
            ordered.append(ComponentLink(page: page, screen: screen, summary: summary))
        }
        for part in page.components(separatedBy: " · ") {
            let name = Self.bareName(part)
            let names = name.hasPrefix("Mini/Hero")
                ? ["Mini" + name.dropFirst(9), "Hero" + name.dropFirst(9)]
                : [name]
            for name in names where links[name] == nil && !name.contains(" ") {
                links[name] = ComponentLink(page: page, screen: screen, summary: summary)
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

    /// The pages a search finds (vNext): a name equal to the text first, then names that start
    /// with it, then names that contain it, then summaries that contain it; each page once, in
    /// the screens' order within a rank. Case and diacritics do not count; a skeleton, a 1.x
    /// name with `View` and a `.ds` modifier find their component, as in `link(for:)`.
    func search(_ text: String) -> [ComponentLink] {
        let query = Self.fold(text.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !query.isEmpty else { return [] }
        var variants = [query]
        if query.hasSuffix("skeleton") { variants.append(String(query.dropLast(8))) }
        if query.hasSuffix("view") { variants.append(String(query.dropLast(4))) }
        if query.hasPrefix(".ds") { variants.append(String(query.dropFirst(3))) }
        variants = variants.filter { !$0.isEmpty }

        var found: [(rank: Int, order: Int, link: ComponentLink)] = []
        for (order, link) in ordered.enumerated() {
            let names = link.page.components(separatedBy: " · ").map { Self.fold(Self.bareName($0)) }
            var rank: Int?
            for variant in variants {
                for name in names {
                    let match = name == variant ? 0 : name.hasPrefix(variant) ? 1 : name.contains(variant) ? 2 : nil
                    if let match { rank = min(rank ?? match, match) }
                }
            }
            if rank == nil, Self.fold(link.summary).contains(query) { rank = 3 }
            if let rank { found.append((rank, order, link)) }
        }
        return found.sorted { ($0.rank, $0.order) < ($1.rank, $1.order) }.map(\.link)
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
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
                            index.register(page: subview.containerValues.showcaseTitle,
                                           summary: subview.containerValues.showcaseSummary, on: screen)
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

/// The foundation screens of the home screen (vNext), which the search finds by title.
enum GalleryFoundation: String, CaseIterable, Identifiable, Sendable {
    case colors = "Colors"
    case typography = "Typography"
    case spacing = "Spacing & Radius"
    case iconSizes = "Icon Sizes"
    case surfaces = "Surfaces"
    case motion = "Motion"

    var id: String { rawValue }

    /// The foundations whose title contains `text`, case and diacritics aside.
    static func matching(_ text: String) -> [GalleryFoundation] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return allCases.filter {
            $0.rawValue.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    @ViewBuilder var destination: some View {
        switch self {
        case .colors: ColorsScreen()
        case .typography: TypographyScreen()
        case .spacing: SpacingScreen()
        case .iconSizes: IconSizesScreen()
        case .surfaces: SurfacesScreen()
        case .motion: MotionScreen()
        }
    }
}
