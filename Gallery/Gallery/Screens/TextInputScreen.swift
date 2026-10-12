//
//  TextInputScreen.swift
//  DesignKit Gallery
//
//  Text input: fields, the hero title, the message field, tags, search suggestions.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct TextInputScreen: View {
    static let title = "Text Input"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        FormTextFieldPage()
        AnimatedTitleInputPage()
        MessageComposerPage()
        TagInputPage()
        SearchSuggestionsPage()
    }
}

private struct FormTextFieldPage: View {
    @State private var text = "Big Almaty Lake"
    @State private var style = 0
    @State private var showsError = false
    @State private var showsHelp = true
    @State private var disabled = false
    @State private var limited = false

    private var fieldStyle: FormTextField.Style {
        switch style {
        case 1: return .multiline(min: 2, max: 5)
        case 2: return .inline
        case 3: return .row
        case 4: return .rowMultiline(min: 2, max: 5)
        default: return .standard
        }
    }

    var body: some View {
        ComponentPage(
            name: "FormTextField",
            summary: "A form field with focus, error, help and disabled states; inline styles sit in a row's trailing slot, row styles fill a FormSection row (3.0.0).",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "Inline styles show no error or help text: put validation at the form level (InlineStatusText).",
                "limit: (3.8.0) counts characters under the field from 80% of it, red over it; the field doesn't cut the text.",
            ],
            styles: ["standard", "multiline", "inline", "inlineMultiline", "row", "rowMultiline"]
        ) {
            if style >= 3 {
                // Row styles fill a row of a FormSection on their own: the card is their chrome.
                FormSection(header: "Place") {
                    FormTextField(
                        text: $text,
                        placeholder: "Place name",
                        style: fieldStyle,
                        errorMessage: showsError ? "The name is too short" : nil,
                        helpText: showsHelp ? "Shown on the map" : nil,
                        limit: limited ? 20 : nil,
                        isDisabled: disabled
                    )
                }
            } else if style == 2 {
                UniversalRow(config: .standard) {
                    Text("Name").font(AppTypography.body)
                } trailing: {
                    FormTextField(text: $text, placeholder: "Place name", style: fieldStyle, isDisabled: disabled)
                }
            } else {
                FormTextField(
                    text: $text,
                    placeholder: "Place name",
                    style: fieldStyle,
                    errorMessage: showsError ? "The name is too short" : nil,
                    helpText: showsHelp ? "Shown on the map" : nil,
                    limit: limited ? 20 : nil,
                    isDisabled: disabled
                )
            }
        } controls: {
            ChoiceControl("Style", selection: $style, options: [("Standard", 0), ("Multiline", 1), ("Inline", 2), ("Row", 3), ("Row, multiline", 4)])
            ToggleControl("Error", isOn: $showsError)
            ToggleControl("Help text", isOn: $showsHelp)
            ToggleControl("Limit 20", isOn: $limited)
            ToggleControl("Disabled", isOn: $disabled)
            TextControl("Text", text: $text)
        }
    }
}

private struct AnimatedTitleInputPage: View {
    @State private var title = ""
    @State private var alignment = 0

    var body: some View {
        ComponentPage(
            name: "AnimatedTitleInput",
            summary: "A large title typed in place, each letter animating in: the name in an edit sheet's hero.",
            apps: [.tenra]
        ) {
            AnimatedTitleInput(text: $title, placeholder: "Untitled",
                               alignment: alignment == 0 ? .center : .leading)
        } controls: {
            ChoiceControl("Alignment", selection: $alignment, options: [("Center", 0), ("Leading", 1)])
            TextControl("Text", text: $title)
        }
    }
}

private struct MessageComposerPage: View {
    @State private var text = ""
    @State private var showsQuote = true
    @State private var showsError = false
    @State private var isSending = false
    @State private var disabled = false
    @State private var limited = false

    var body: some View {
        ComponentPage(
            name: "MessageComposer",
            summary: "The field at the bottom of a conversation: glass that grows to five lines, the send button inside, the quoted message, the send error.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill,
            notes: [
                "Put it in safeAreaBar(edge: .bottom) so the list scrolls under the glass; give it the screen margins.",
                "Signed out: .disabled(true) with a placeholder that says why.",
                "limit: (3.8.0) shows the count over the field from 80% of it; over it the count is red and sending is off.",
            ]
        ) {
            MessageComposer(
                text: $text,
                placeholder: disabled ? "Sign in to comment" : "Add a comment…",
                quote: showsQuote ? MessageQuote(title: "Replying to Aida", text: "Was anyone on the lake this weekend?") : nil,
                isSending: isSending,
                errorMessage: showsError ? "No connection. Try again." : nil,
                limit: limited ? 40 : nil,
                onCancelQuote: { showsQuote = false }
            ) {
                isSending = true
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    text = ""
                    isSending = false
                }
            }
            .disabled(disabled)
        } controls: {
            ToggleControl("Quote", isOn: $showsQuote)
            ToggleControl("Error", isOn: $showsError)
            ToggleControl("Sending", isOn: $isSending)
            ToggleControl("Limit 40", isOn: $limited)
            ToggleControl("Disabled", isOn: $disabled)
            TextControl("Text", text: $text)
        }
    }
}

private struct TagInputPage: View {
    @State private var tags = ["Pike", "Early morning"]
    @State private var limited = false

    var body: some View {
        ComponentPage(
            name: "TagInput",
            summary: "Free-form tags as removable chips, a field for the next one and matching suggestions.",
            since: "0.7.0",
            apps: [.dalada],
            canvas: .fill,
            notes: ["Return or a comma adds a tag; duplicates and blanks are dropped. A fixed set of options → ChipPicker."]
        ) {
            TagInput("Add a tag", tags: $tags, suggestions: ["Perch", "Night", "Kids", "4x4 only"],
                     maxTags: limited ? 3 : nil)
        } controls: {
            ToggleControl("At most 3", isOn: $limited)
            ActionControl("Clear", systemImage: "xmark.circle") { tags = [] }
        }
    }
}

/// Places and categories to suggest, the kind both apps offer.
private let sampleSuggestions: [SearchSuggestion] = [
    SearchSuggestion("Kapchagay Reservoir", subtitle: "Reservoir · 70 km", icon: .sfSymbol("water.waves"), tint: AppColors.accent),
    SearchSuggestion("Kaindy Lake", subtitle: "Lake · 280 km", icon: .sfSymbol("drop.fill"), tint: AppColors.accent),
    SearchSuggestion("Big Almaty Lake", subtitle: "Lake · 28 km", icon: .sfSymbol("drop.fill"), tint: AppColors.accent),
    SearchSuggestion("Kolsai Lakes", subtitle: "Lakes · 300 km", icon: .sfSymbol("drop.fill"), tint: AppColors.accent),
    SearchSuggestion("Coffee", subtitle: "Category", icon: .sfSymbol("cup.and.saucer.fill"), tint: AppColors.warning),
    SearchSuggestion("Car", subtitle: "Category", icon: .sfSymbol("car.fill"), tint: AppColors.warning),
]

private let sampleRecent = RecentSearches(["Kapchagay", "pike", "coffee"])

private struct SearchSuggestionsPage: View {
    @State private var state: SpecimenState = .content
    @State private var typed = "ka"
    @State private var recent = sampleRecent
    @State private var showsRecent = true
    @State private var showsSubtitles = true
    @State private var isTrying = false

    private var suggestions: [SearchSuggestion] {
        guard state == .content else { return [] }
        return sampleSuggestions.map { suggestion in
            SearchSuggestion(suggestion.title, subtitle: showsSubtitles ? suggestion.subtitle : nil,
                             icon: suggestion.icon, tint: suggestion.tint)
        }
    }

    private var recentBinding: Binding<RecentSearches>? {
        showsRecent && state != .empty ? $recent : nil
    }

    var body: some View {
        ComponentPage(
            name: "SearchSuggestions",
            summary: "Lines under the system search field: the recent queries while it is empty, the app's suggestions that match what is typed, the typed part in bold. .dsSearchSuggestions after .searchable; RecentSearches keeps the queries.",
            since: "3.5.0",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "The search stays the system's: .searchable places the field, the lines go in its own suggestion list, which covers the screen while it shows.",
                "A tap puts the text in the field, records it and hides the suggestions until the text changes; ↖ puts it in the field to keep typing; swipe removes a recent query.",
                "Keep RecentSearches with @AppStorage under the screen's own key. Suggestions whose title, subtitle or completion contain the text show, up to limit (5).",
            ]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                List {
                    SearchSuggestionsContent(
                        text: $typed,
                        recent: recentBinding,
                        suggestions: suggestions,
                        isLoading: state == .loading
                    )
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: 360)
                if state == .empty || (recentBinding == nil && typed.isEmpty) {
                    Text("Nothing to suggest: the screen's content stays in view.")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                }
            }
            .sheet(isPresented: $isTrying) {
                SearchSuggestionsDemo()
            }
        } controls: {
            StateControl(state: $state, states: [.content, .loading, .empty])
            TextControl("Typed text", text: $typed)
            ToggleControl("Recent queries", isOn: $showsRecent)
            ToggleControl("Subtitles", isOn: $showsSubtitles)
            ActionControl("Reset recent queries", systemImage: "arrow.counterclockwise") { recent = sampleRecent }
            ActionControl("Try it in a search field", systemImage: "magnifyingglass") { isTrying = true }
        }
    }
}

/// A real search: places filtered as you type, with DesignKit's suggestions under the field.
private struct SearchSuggestionsDemo: View {
    @State private var query = ""
    @State private var recent = sampleRecent
    @State private var opened: String?
    @Environment(\.dismiss) private var dismiss

    private var results: [SearchSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return sampleSuggestions }
        return sampleSuggestions.filter { SearchMatch.matches(trimmed, $0.title, $0.subtitle) }
    }

    var body: some View {
        NavigationStack {
            List {
                if let opened {
                    Text("Opened \(opened)")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                }
                ForEach(results) { place in
                    SearchSuggestionRow(place.title, subtitle: place.subtitle, icon: place.icon, tint: place.tint)
                }
            }
            .navigationTitle("Places")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Places and categories")
            .dsSearchSuggestions(text: $query, recent: $recent, suggestions: sampleSuggestions,
                                 onSelect: { suggestion in opened = suggestion.title })
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview { NavigationStack { TextInputScreen() } }
