//
//  SearchSuggestions.swift
//  DesignKit
//
//  Suggestions under the system search field (3.5.0): the recent queries while the field is
//  empty, the app's suggestions that match what is typed, the typed part in bold. They live in
//  the system's own suggestion list (`.searchSuggestions`), so the search stays the system's:
//  `.searchable` places the field, DesignKit draws the lines. What to suggest, and where the
//  recent queries are kept, stays in the app.
//  5.2.0: a symbol sits in a circle tile, as in DesignKit's other rows (a suggestion's in a pale
//  tint of its colour, a recent query's clock in grey), and "Clear" is in the accent.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// One suggestion the app offers under the search field: a place, a category, a person.
public struct SearchSuggestion: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String?
    /// A symbol (drawn in `tint` on a pale tile of it) or a brand logo before the title; none
    /// by default.
    public let icon: IconSource?
    public let tint: Color?
    /// What a tap puts in the search field; the title by default.
    public let completion: String

    /// - Parameters:
    ///   - subtitle: What the suggestion is ("Category", "Lake · 12 km"); it is matched too.
    ///   - tint: The symbol's colour, its tile a pale tint of it; the accent by default (5.2.0,
    ///     the secondary grey without a tile before).
    ///   - completion: What a tap puts in the search field; `title` by default.
    ///   - id: Tells equal titles apart; `completion` by default.
    public init(
        _ title: String,
        subtitle: String? = nil,
        icon: IconSource? = nil,
        tint: Color? = nil,
        completion: String? = nil,
        id: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.completion = completion ?? title
        self.id = id ?? completion ?? title
    }
}

// MARK: - Modifier

public extension View {
    /// DesignKit's suggestions under the system search field. Apply it after `.searchable`:
    ///
    /// ```swift
    /// @AppStorage("places.recentSearches") private var recent = RecentSearches()
    ///
    /// List { … }
    ///     .searchable(text: $query)
    ///     .dsSearchSuggestions(text: $query, recent: $recent, suggestions: placeSuggestions)
    /// ```
    ///
    /// - While the field is empty: the recent queries, newest first, with "Clear" and swipe to
    ///   remove one.
    /// - While the person types: up to three recent queries and `limit` of the `suggestions`
    ///   whose title, subtitle or completion contain the text (ignoring case and diacritics), the
    ///   typed part in bold. `isLoading` with nothing to show yet draws skeleton lines.
    /// - A tap on a line puts its text in the field, records it as a recent query and hides the
    ///   suggestions until the text changes, so the results show. The ↖ button puts the text in
    ///   the field to keep typing. A query submitted from the keyboard is recorded too.
    ///
    /// The suggestions cover the screen's content while they show (the system's behaviour);
    /// with nothing to show, the content stays in view.
    ///
    /// - Parameters:
    ///   - recent: The recent queries; `nil` for a field that keeps none.
    ///   - suggestions: The candidates; DesignKit picks those that match the text.
    ///   - onSearch: A query was chosen or submitted: it is in the field and recorded already.
    ///   - onSelect: One of `suggestions` was tapped (open a place, apply a filter), after
    ///     `onSearch`.
    func dsSearchSuggestions(
        text: Binding<String>,
        recent: Binding<RecentSearches>? = nil,
        suggestions: [SearchSuggestion] = [],
        isLoading: Bool = false,
        limit: Int = 5,
        onSearch: ((String) -> Void)? = nil,
        onSelect: ((SearchSuggestion) -> Void)? = nil
    ) -> some View {
        modifier(SearchSuggestionsModifier(
            text: text,
            recent: recent,
            suggestions: suggestions,
            isLoading: isLoading,
            limit: limit,
            onSearch: onSearch,
            onSelect: onSelect
        ))
    }
}

private struct SearchSuggestionsModifier: ViewModifier {
    @Binding var text: String
    let recent: Binding<RecentSearches>?
    let suggestions: [SearchSuggestion]
    let isLoading: Bool
    let limit: Int
    let onSearch: ((String) -> Void)?
    let onSelect: ((SearchSuggestion) -> Void)?

    /// The query just chosen or submitted: no suggestions until the text changes, so the
    /// results under them show.
    @State private var settled: String?

    private var isSettled: Bool {
        settled.map { SearchMatch.isSame($0, text) } ?? false
    }

    func body(content: Content) -> some View {
        content
            .searchSuggestions {
                if !isSettled {
                    SearchSuggestionsContent(
                        text: $text,
                        recent: recent,
                        suggestions: suggestions,
                        isLoading: isLoading,
                        limit: limit,
                        onSearch: { query in
                            settled = query
                            onSearch?(query)
                        },
                        onSelect: onSelect
                    )
                }
            }
            .onSubmit(of: .search) {
                let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else { return }
                recent?.wrappedValue.record(query)
                settled = query
                onSearch?(query)
            }
            .onChange(of: text) { _, newValue in
                if let settled, !SearchMatch.isSame(settled, newValue) {
                    self.settled = nil
                }
            }
    }
}

// MARK: - Content

/// The lines `.dsSearchSuggestions` puts under the search field: the "Recent" section and the
/// "Suggestions" section. Public for a container of the app's own (and the Gallery); a screen
/// uses the modifier.
public struct SearchSuggestionsContent: View {
    @Binding var text: String
    let recent: Binding<RecentSearches>?
    let suggestions: [SearchSuggestion]
    let isLoading: Bool
    let limit: Int
    let onSearch: ((String) -> Void)?
    let onSelect: ((SearchSuggestion) -> Void)?

    /// Recent queries shown while the person types.
    static let recentWhileTyping = 3

    public init(
        text: Binding<String>,
        recent: Binding<RecentSearches>? = nil,
        suggestions: [SearchSuggestion] = [],
        isLoading: Bool = false,
        limit: Int = 5,
        onSearch: ((String) -> Void)? = nil,
        onSelect: ((SearchSuggestion) -> Void)? = nil
    ) {
        self._text = text
        self.recent = recent
        self.suggestions = suggestions
        self.isLoading = isLoading
        self.limit = limit
        self.onSearch = onSearch
        self.onSelect = onSelect
    }

    private var query: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// All of them while the field is empty; while typing, a few that contain the text and are
    /// not the text itself.
    private var shownRecents: [String] {
        let queries = recent?.wrappedValue.queries ?? []
        guard !query.isEmpty else { return queries }
        return Array(queries
            .filter { SearchMatch.range(of: query, in: $0) != nil && !SearchMatch.isSame($0, query) }
            .prefix(Self.recentWhileTyping))
    }

    /// Only while typing: those that match the text and would change it.
    private var shownSuggestions: [SearchSuggestion] {
        guard !query.isEmpty else { return [] }
        return Array(suggestions
            .filter { SearchMatch.matches(query, $0.title, $0.subtitle, $0.completion) && !SearchMatch.isSame($0.completion, query) }
            .prefix(max(limit, 0)))
    }

    public var body: some View {
        let recents = shownRecents
        let matches = shownSuggestions
        if !recents.isEmpty {
            Section {
                ForEach(recents, id: \.self) { recentQuery in
                    Button {
                        search(recentQuery)
                    } label: {
                        SearchSuggestionRow.recent(recentQuery, highlighting: query) { text = recentQuery }
                    }
                    .accessibilityAction(named: SearchSuggestionRow.fillTitle) { text = recentQuery }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            recent?.wrappedValue.remove(recentQuery)
                        } label: {
                            Label(String(localized: "search.recent.remove", defaultValue: "Remove"), systemImage: "trash")
                        }
                    }
                }
            } header: {
                SectionHeader(String(localized: "search.recent", defaultValue: "Recent")) {
                    Button(String(localized: "search.recent.clear", defaultValue: "Clear")) {
                        recent?.wrappedValue.removeAll()
                    }
                    // The accent, not the list's own blue (5.2.0): a header's button takes its
                    // colour from the tint, not the foreground style.
                    .buttonStyle(.borderless)
                    .tint(AppColors.accent)
                }
            }
        }
        if !query.isEmpty && (!matches.isEmpty || isLoading) {
            Section {
                if matches.isEmpty {
                    ForEach(0..<SearchSuggestionsMetrics.skeletonLines, id: \.self) { _ in
                        SearchSuggestionRowSkeleton()
                    }
                } else {
                    ForEach(matches) { suggestion in
                        Button {
                            search(suggestion.completion)
                            onSelect?(suggestion)
                        } label: {
                            SearchSuggestionRow(
                                suggestion.title,
                                subtitle: suggestion.subtitle,
                                icon: suggestion.icon,
                                tint: suggestion.tint,
                                highlighting: query
                            ) { text = suggestion.completion }
                        }
                        .accessibilityAction(named: SearchSuggestionRow.fillTitle) { text = suggestion.completion }
                    }
                }
            } header: {
                SectionHeader(String(localized: "search.suggestions", defaultValue: "Suggestions"))
            }
        }
    }

    private func search(_ query: String) {
        text = query
        recent?.wrappedValue.record(query)
        onSearch?(query)
    }
}

enum SearchSuggestionsMetrics {
    /// Skeleton lines while the suggestions load.
    static let skeletonLines = 3
    /// A line's icon tile (5.2.0), at the default text size.
    static let iconSide: CGFloat = AppIconSize.xl
}

// MARK: - Row

/// One line of search suggestions: a symbol in a circle tile or a logo, the title with the typed
/// part in bold, a subtitle, and a ↖ button that puts the text in the field to keep typing. No
/// padding of its own: it lives in a list, whose insets give it.
public struct SearchSuggestionRow: View {
    let title: String
    let subtitle: String?
    let icon: IconSource?
    let tint: Color?
    /// The symbol's tile; a pale tint of the symbol's colour when `nil`.
    let tileFill: Color?
    let query: String
    let onFill: (() -> Void)?

    /// The icon's tile grows with the text, so a large symbol never runs into the title and
    /// the titles of all lines stay aligned (5.2.0: a 32 pt tile, a bare 24 pt symbol before).
    @ScaledMetric(relativeTo: .body) private var iconSide: CGFloat = SearchSuggestionsMetrics.iconSide

    static var fillTitle: String {
        String(localized: "search.fill", defaultValue: "Edit in search field")
    }

    /// - Parameters:
    ///   - icon: A symbol (in `tint`, on a pale tile of it) or a brand logo.
    ///   - tint: The symbol's colour; the accent by default (5.2.0).
    ///   - query: The typed text, drawn in bold where the title contains it.
    ///   - onFill: The ↖ button; none without it.
    public init(
        _ title: String,
        subtitle: String? = nil,
        icon: IconSource? = nil,
        tint: Color? = nil,
        highlighting query: String = "",
        onFill: (() -> Void)? = nil
    ) {
        self.init(title, subtitle: subtitle, icon: icon, tint: tint, tileFill: nil, highlighting: query, onFill: onFill)
    }

    init(
        _ title: String,
        subtitle: String?,
        icon: IconSource?,
        tint: Color?,
        tileFill: Color?,
        highlighting query: String,
        onFill: (() -> Void)?
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.tileFill = tileFill
        self.query = query
        self.onFill = onFill
    }

    /// A recent query: the clock symbol on a grey tile (5.2.0; a bare tertiary clock before).
    public static func recent(
        _ query: String,
        highlighting typed: String = "",
        onFill: (() -> Void)? = nil
    ) -> SearchSuggestionRow {
        SearchSuggestionRow(
            query,
            subtitle: nil,
            icon: .sfSymbol("clock.arrow.circlepath"),
            tint: AppColors.Text.secondary,
            tileFill: AppColors.Background.neutral1,
            highlighting: typed,
            onFill: onFill
        )
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            leadingIcon
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(highlightedTitle)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(2)
                if let subtitle {
                    // Two lines, so a large text size wraps "Reservoir · 70 km" instead of
                    // cutting the distance off (3.5.1).
                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: AppSpacing.sm)
            if let onFill {
                Button(action: onFill) {
                    Icon("arrow.up.left", size: AppIconSize.md)
                        .foregroundStyle(AppColors.Text.tertiary)
                        .frame(minWidth: AppIconSize.lg, minHeight: AppIconSize.lg)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Self.fillTitle)
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var leadingIcon: some View {
        switch icon {
        case .sfSymbol:
            let color = tint ?? AppColors.accent
            Icon(source: icon, style: .circle(
                size: iconSide,
                tint: .monochrome(color),
                backgroundColor: tileFill ?? AppColors.pale(color)
            ))
        case .brandService:
            Icon(source: icon, size: iconSide)
        case nil:
            EmptyView()
        }
    }

    /// The title with the first occurrence of the typed text in bold.
    private var highlightedTitle: AttributedString {
        var attributed = AttributedString(title)
        if let range = SearchMatch.range(of: query, in: title),
           let attributedRange = Range<AttributedString.Index>(range, in: attributed) {
            // The SwiftUI key by name: `.font` alone could also mean UIKit's.
            attributed[attributedRange][AttributeScopes.SwiftUIAttributes.FontAttribute.self] = AppTypography.bodyEmphasis
        }
        return attributed
    }
}

// MARK: - Skeleton

/// Placeholder of a `SearchSuggestionRow` while the suggestions load: a grey circle for the
/// symbol and a line for the title (`showsSubtitle` adds a shorter one).
public struct SearchSuggestionRowSkeleton: View {
    let showsSubtitle: Bool

    public init(showsSubtitle: Bool = false) {
        self.showsSubtitle = showsSubtitle
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            Skeleton.circle(SearchSuggestionsMetrics.iconSide)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                SkeletonText(AppTypography.body, width: 150)
                if showsSubtitle {
                    SkeletonText(AppTypography.bodySmall, width: 90)
                }
            }
            Spacer(minLength: 0)
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
