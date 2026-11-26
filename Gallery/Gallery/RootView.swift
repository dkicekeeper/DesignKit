//
//  RootView.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens

/// A screen the home screen opens (8.22.3): on a phone it is pushed, on an iPad or a Mac it fills
/// the detail column beside the sidebar.
enum GalleryDestination: Hashable {
    case updates
    case foundation(GalleryFoundation)
    case screen(GalleryScreen)
    case patterns
    /// A component page the search found: its screen, opened on it.
    case page(ComponentLink)

    @ViewBuilder var view: some View {
        switch self {
        case .updates:
            UpdatesScreen()
                .galleryRefreshes()
        case .foundation(let foundation):
            foundation.destination
        case .screen(let screen):
            screen.destination()
        case .patterns:
            PatternsScreen()
                .galleryRefreshes()
        case .page(let link):
            link.screen.destination(page: link.page)
        }
    }
}

struct RootView: View {
    /// The custom preset's sheet (8.21.0).
    @State private var showsCustom = false
    /// What the home screen's search looks for (8.21.0).
    @State private var query = ""
    /// Which page shows which component, for the links in the release notes.
    @State private var componentIndex = ComponentIndex()
    /// The screen open beside the sidebar, or pushed on a phone (8.22.3).
    @State private var selection: GalleryDestination?

    private var settings: GallerySettings { .shared }

    var body: some View {
        // The accent is a static read: reading the key draws the home screen and its tint again
        // when the preset changes, without closing the screen that is open (8.22.3).
        let _ = settings.renderKey
        NavigationSplitView {
            List(selection: $selection) {
                if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                    searchResults
                } else {
                    sections
                }
            }
            .searchable(text: $query, prompt: "Components")
            .navigationTitle("DesignKit")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("App", selection: Binding(get: { settings.theme }, set: { settings.select($0) })) {
                            ForEach(GalleryTheme.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Button("Custom accent…", systemImage: "paintpalette") { showsCustom = true }
                        if settings.changesCanvas {
                            Button("Reset the canvas", systemImage: "arrow.uturn.backward") { settings.resetCanvas() }
                        }
                    } label: {
                        Label(settings.theme.rawValue, systemImage: "paintbrush.pointed")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text(versionLine)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.Text.secondary)
                    .padding(.bottom, AppSpacing.xs)
            }
            .background { ComponentIndexReader(index: $componentIndex) }
        } detail: {
            NavigationStack {
                if let selection {
                    selection.view
                } else {
                    ContentUnavailableView(
                        "DesignKit",
                        systemImage: "square.grid.2x2",
                        description: Text("Pick a section, or search for a component.")
                    )
                }
            }
            // A new section starts its own stack.
            .id(selection)
        }
        .softScrollEdges()
        .environment(\.componentIndex, componentIndex)
        // The surfaces go down the environment, so every card follows the preset (8.22.3; the
        // static `DesignKitTheme.surface` stays the default for what reads no environment).
        .surfaceStyle(settings.surface)
        .tint(AppColors.accent)
        .sheet(isPresented: $showsCustom) { customSheet }
    }

    /// The home screen's sections, when nothing is searched.
    @ViewBuilder private var sections: some View {
        Section {
            row(UpdatesScreen.title, "sparkles.rectangle.stack", .orange,
                trailing: Changelog.bundled?.releases.first?.version, to: .updates)
        } footer: {
            Text("What each version added and changed, and how to move an app to it.")
        }
        Section {
            row("Colors", "paintpalette.fill", AppColors.accent, to: .foundation(.colors))
            row("Typography", "textformat", .pink, to: .foundation(.typography))
            row("Spacing & Radius", "ruler.fill", .orange, to: .foundation(.spacing))
            row("Icon Sizes", "square.resize", .teal, to: .foundation(.iconSizes))
            row("Surfaces", "rectangle.on.rectangle", .green, to: .foundation(.surfaces))
            row("Motion", "wand.and.rays", .purple, to: .foundation(.motion))
        } header: {
            Text("Foundations")
        }
        Section {
            row(ActionsScreen.title, "hand.tap.fill", .blue, pages: ActionsScreen.pages, to: .screen(.actions))
            row(TextInputScreen.title, "character.cursor.ibeam", .indigo, pages: TextInputScreen.pages, to: .screen(.textInput))
            row(SelectionScreen.title, "checklist", .mint, pages: SelectionScreen.pages, to: .screen(.selection))
            row(AmountsScreen.title, "banknote.fill", .green, pages: AmountsScreen.pages, to: .screen(.amounts))
        } header: {
            Text("Input & Actions")
        }
        Section {
            row(SettingsRowsScreen.title, "list.bullet.rectangle.fill", .gray, pages: SettingsRowsScreen.pages, to: .screen(.settingsRows))
            row(DataRowsScreen.title, "list.bullet", .cyan, pages: DataRowsScreen.pages, to: .screen(.dataRows))
            row(MoneyCardsScreen.title, "creditcard.fill", .green, pages: MoneyCardsScreen.pages, to: .screen(.moneyCards))
            row(ProgressCardsScreen.title, "chart.bar.doc.horizontal.fill", .orange, pages: ProgressCardsScreen.pages, to: .screen(.progressCards))
            row(ContentCardsScreen.title, "text.bubble.fill", .pink, pages: ContentCardsScreen.pages, to: .screen(.contentCards))
        } header: {
            Text("Containers")
        } footer: {
            Text("Rows and cards are split by what they show; each component has its own page with controls and states.")
        }
        Section {
            row(ChartsScreen.title, "chart.xyaxis.line", .teal, pages: ChartsScreen.pages, to: .screen(.charts))
            row(ProgressScreen.title, "gauge.with.dots.needle.67percent", .purple, pages: ProgressScreen.pages, to: .screen(.progress))
            row(FeedbackScreen.title, "exclamationmark.bubble.fill", .red, pages: FeedbackScreen.pages, to: .screen(.feedback))
        } header: {
            Text("Data & Status")
        }
        Section {
            row(NavigationScreen.title, "rectangle.topthird.inset.filled", .blue, pages: NavigationScreen.pages, to: .screen(.navigation))
            row(MediaScreen.title, "person.crop.circle.fill", .indigo, pages: MediaScreen.pages, to: .screen(.media))
            row(ContentScreen.title, "square.text.square.fill", .brown, pages: ContentScreen.pages, to: .screen(.content))
            row(SheetsScreen.title, "rectangle.portrait.bottomhalf.inset.filled", .mint, pages: SheetsScreen.pages, to: .screen(.sheets))
            row(EffectsScreen.title, "sparkles", .purple, pages: EffectsScreen.pages, to: .screen(.effects))
        } header: {
            Text("Structure & Effects")
        }
        Section {
            row(PatternsScreen.title, "rectangle.3.group.fill", .orange, to: .patterns)
        } footer: {
            Text("Whole screens made of the components: settings, a detail, a list, a dashboard, a conversation, an edit sheet, onboarding.")
        }
    }

    /// What the search finds: foundations by title, then component pages (8.21.0).
    @ViewBuilder private var searchResults: some View {
        let foundations = GalleryFoundation.matching(query)
        let pages = componentIndex.search(query)
        if foundations.isEmpty && pages.isEmpty {
            ContentUnavailableView.search(text: query)
        }
        if !foundations.isEmpty {
            Section("Foundations") {
                ForEach(foundations) { foundation in
                    NavigationLink(foundation.rawValue, value: GalleryDestination.foundation(foundation))
                }
            }
        }
        if !pages.isEmpty {
            Section("Components") {
                ForEach(pages) { link in
                    NavigationLink(value: GalleryDestination.page(link)) {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(verbatim: link.page)
                                .font(AppTypography.bodyEmphasis)
                            Text(verbatim: link.screen.title)
                                .font(AppTypography.caption.weight(.semibold))
                                .foregroundStyle(AppColors.Text.secondary)
                            Text(verbatim: link.summary)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.Text.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }

    /// The custom preset: an accent from the colour picker and its surfaces (8.21.0).
    private var customSheet: some View {
        NavigationStack {
            Form {
                ColorPicker("Accent", selection: Binding(get: { settings.customAccent },
                                                         set: { settings.setCustomAccent($0) }),
                            supportsOpacity: false)
                Picker("Surfaces", selection: Binding(get: { settings.surface },
                                                      set: { settings.setCustomSurface($0) })) {
                    Text("Glass").tag(SurfaceStyle.glass)
                    Text("Fill").tag(SurfaceStyle.fill)
                }
            }
            .navigationTitle("Custom accent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showsCustom = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var versionLine: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "DesignKit \(version) (\(build)) · \(settings.theme.rawValue) preset · \(settings.surface == .glass ? "glass" : "fill") surfaces"
    }

    private func row(
        _ title: String,
        _ symbol: String,
        _ tint: Color,
        trailing: String? = nil,
        to destination: GalleryDestination
    ) -> some View {
        row(title, symbol, tint, pages: EmptyView(), trailing: trailing, to: destination)
    }

    /// A screen of components: its row counts the screen's component pages.
    private func row<Pages: View>(
        _ title: String,
        _ symbol: String,
        _ tint: Color,
        pages: Pages,
        trailing: String? = nil,
        to destination: GalleryDestination
    ) -> some View {
        NavigationLink(value: destination) {
            HStack {
                Label {
                    Text(title).font(AppTypography.bodyEmphasis)
                } icon: {
                    Image(systemName: symbol)
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(tint, in: RoundedRectangle(cornerRadius: 7))
                }
                Spacer()
                if Pages.self != EmptyView.self {
                    ShowcaseCount { pages }
                } else if let trailing {
                    Text(verbatim: trailing)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                        .monospacedDigit()
                }
            }
        }
    }
}

#Preview { RootView() }
