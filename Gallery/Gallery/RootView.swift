//
//  RootView.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens

/// The apps that consume DesignKit, as presets of the Gallery (vNext: accent and surfaces
/// together, as each app sets them), and a custom accent to try one. `DesignKitTheme.accent` and
/// `.surface` are read at render time, so switching re-renders the tree.
enum GalleryTheme: String, CaseIterable, Identifiable {
    case tenra = "Tenra"
    case dalada = "Dalada"
    case platina = "Platina"
    case custom = "Custom"

    var id: String { rawValue }

    /// The app's accent; the custom one is the Gallery's own state.
    var accent: Color? {
        switch self {
        case .tenra: return .indigo
        // Dalada's AccentColor (light #2E8B57 / dark #3CB371).
        case .dalada: return Self.pair(light: (0x2E, 0x8B, 0x57), dark: (0x3C, 0xB3, 0x71))
        // Platina's Plasma (vNext; #3573BA before): light #D6006F / dark #FF4FA0.
        case .platina: return Self.pair(light: (0xD6, 0x00, 0x6F), dark: (0xFF, 0x4F, 0xA0))
        case .custom: return nil
        }
    }

    /// The app's surfaces: Tenra keeps Liquid Glass, Dalada and Platina draw grey cards.
    var surface: SurfaceStyle? {
        switch self {
        case .tenra: return .glass
        case .dalada, .platina: return .fill
        case .custom: return nil
        }
    }

    private static func pair(light: (Int, Int, Int), dark: (Int, Int, Int)) -> Color {
        Color(UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat(rgb.0) / 255, green: CGFloat(rgb.1) / 255, blue: CGFloat(rgb.2) / 255, alpha: 1)
        })
    }
}

struct RootView: View {
    @State private var theme: GalleryTheme = .tenra
    /// The surfaces of every page (8.12.0): the preset's, or the custom choice.
    @State private var surface: SurfaceStyle = .glass
    /// The custom preset (vNext): an accent to try and its surfaces.
    @State private var customAccent: Color = .orange
    @State private var showsCustom = false
    /// What the home screen's search looks for (vNext).
    @State private var query = ""
    /// Which page shows which component, for the links in the release notes.
    @State private var componentIndex = ComponentIndex()

    var body: some View {
        NavigationStack {
            List {
                if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                    searchResults
                } else {
                    sections
                }
                Section {
                    row(PatternsScreen.title, "rectangle.3.group.fill", .orange) { PatternsScreen() }
                } footer: {
                    Text("Whole screens made of the components: settings, a detail, a list, a dashboard, a conversation, an edit sheet, onboarding.")
                }
            }
            .searchable(text: $query, prompt: "Components")
            .navigationTitle("DesignKit")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("App", selection: themeSelection) {
                            ForEach(GalleryTheme.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Button("Custom accent…", systemImage: "paintpalette") { showsCustom = true }
                    } label: {
                        Label(theme.rawValue, systemImage: "paintbrush.pointed")
                    }
                }
            }
            .sheet(isPresented: $showsCustom) { customSheet }
            .safeAreaInset(edge: .bottom) {
                Text(versionLine)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.Text.secondary)
                    .padding(.bottom, AppSpacing.xs)
            }
            .background { ComponentIndexReader(index: $componentIndex) }
        }
        .softScrollEdges()
        .environment(\.componentIndex, componentIndex)
        .tint(AppColors.accent)
        // Tokens are static reads: a new identity re-renders every screen with the new accent
        // and surfaces.
        .id("\(theme.rawValue)-\(surface)-\(customAccent.description)")
    }

    /// The home screen's sections, when nothing is searched.
    @ViewBuilder private var sections: some View {
        Section {
            row(UpdatesScreen.title, "sparkles.rectangle.stack", .orange,
                trailing: Changelog.bundled?.releases.first?.version) { UpdatesScreen() }
        } footer: {
            Text("What each version added and changed, and how to move an app to it.")
        }
        Section {
            row("Colors", "paintpalette.fill", AppColors.accent) { ColorsScreen() }
            row("Typography", "textformat", .pink) { TypographyScreen() }
            row("Spacing & Radius", "ruler.fill", .orange) { SpacingScreen() }
            row("Icon Sizes", "square.resize", .teal) { IconSizesScreen() }
            row("Surfaces", "rectangle.on.rectangle", .green) { SurfacesScreen() }
            row("Motion", "wand.and.rays", .purple) { MotionScreen() }
        } header: {
            Text("Foundations")
        }
        Section {
            row(ActionsScreen.title, "hand.tap.fill", .blue, pages: ActionsScreen.pages) { ActionsScreen() }
            row(TextInputScreen.title, "character.cursor.ibeam", .indigo, pages: TextInputScreen.pages) { TextInputScreen() }
            row(SelectionScreen.title, "checklist", .mint, pages: SelectionScreen.pages) { SelectionScreen() }
            row(AmountsScreen.title, "banknote.fill", .green, pages: AmountsScreen.pages) { AmountsScreen() }
        } header: {
            Text("Input & Actions")
        }
        Section {
            row(SettingsRowsScreen.title, "list.bullet.rectangle.fill", .gray, pages: SettingsRowsScreen.pages) { SettingsRowsScreen() }
            row(DataRowsScreen.title, "list.bullet", .cyan, pages: DataRowsScreen.pages) { DataRowsScreen() }
            row(MoneyCardsScreen.title, "creditcard.fill", .green, pages: MoneyCardsScreen.pages) { MoneyCardsScreen() }
            row(ProgressCardsScreen.title, "chart.bar.doc.horizontal.fill", .orange, pages: ProgressCardsScreen.pages) { ProgressCardsScreen() }
            row(ContentCardsScreen.title, "text.bubble.fill", .pink, pages: ContentCardsScreen.pages) { ContentCardsScreen() }
        } header: {
            Text("Containers")
        } footer: {
            Text("Rows and cards are split by what they show; each component has its own page with controls and states.")
        }
        Section {
            row(ChartsScreen.title, "chart.xyaxis.line", .teal, pages: ChartsScreen.pages) { ChartsScreen() }
            row(ProgressScreen.title, "gauge.with.dots.needle.67percent", .purple, pages: ProgressScreen.pages) { ProgressScreen() }
            row(FeedbackScreen.title, "exclamationmark.bubble.fill", .red, pages: FeedbackScreen.pages) { FeedbackScreen() }
        } header: {
            Text("Data & Status")
        }
        Section {
            row(NavigationScreen.title, "rectangle.topthird.inset.filled", .blue, pages: NavigationScreen.pages) { NavigationScreen() }
            row(MediaScreen.title, "person.crop.circle.fill", .indigo, pages: MediaScreen.pages) { MediaScreen() }
            row(ContentScreen.title, "square.text.square.fill", .brown, pages: ContentScreen.pages) { ContentScreen() }
            row(SheetsScreen.title, "rectangle.portrait.bottomhalf.inset.filled", .mint, pages: SheetsScreen.pages) { SheetsScreen() }
            row(EffectsScreen.title, "sparkles", .purple, pages: EffectsScreen.pages) { EffectsScreen() }
        } header: {
            Text("Structure & Effects")
        }
    }

    /// What the search finds: foundations by title, then component pages (vNext).
    @ViewBuilder private var searchResults: some View {
        let foundations = GalleryFoundation.matching(query)
        let pages = componentIndex.search(query)
        if foundations.isEmpty && pages.isEmpty {
            ContentUnavailableView.search(text: query)
        }
        if !foundations.isEmpty {
            Section("Foundations") {
                ForEach(foundations) { foundation in
                    NavigationLink(foundation.rawValue) { foundation.destination }
                }
            }
        }
        if !pages.isEmpty {
            Section("Components") {
                ForEach(pages) { link in
                    NavigationLink {
                        link.screen.destination(page: link.page)
                    } label: {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(verbatim: link.page)
                                .font(AppTypography.bodyEmphasis)
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

    /// The custom preset: an accent from the colour picker and its surfaces (vNext).
    private var customSheet: some View {
        NavigationStack {
            Form {
                ColorPicker("Accent", selection: customSelection, supportsOpacity: false)
                Picker("Surfaces", selection: customSurfaceSelection) {
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

    /// Picks the custom colour and switches to the custom preset, BEFORE the state change.
    private var customSelection: Binding<Color> {
        Binding(
            get: { customAccent },
            set: { color in
                DesignKitTheme.accent = color
                theme = .custom
                customAccent = color
            }
        )
    }

    private var customSurfaceSelection: Binding<SurfaceStyle> {
        Binding(
            get: { surface },
            set: { newSurface in
                DesignKitTheme.surface = newSurface
                theme = .custom
                surface = newSurface
            }
        )
    }

    /// Sets the accent BEFORE the state change, so the re-render already reads the new value.
    private var themeSelection: Binding<GalleryTheme> {
        Binding(
            get: { theme },
            set: { newTheme in
                // A preset sets the app's accent and surfaces together (vNext).
                let accent = newTheme.accent ?? customAccent
                let newSurface = newTheme.surface ?? surface
                DesignKitTheme.accent = accent
                DesignKitTheme.surface = newSurface
                surface = newSurface
                theme = newTheme
            }
        )
    }

    private var versionLine: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "DesignKit \(version) (\(build)) · \(theme.rawValue) preset · \(surface == .glass ? "glass" : "fill") surfaces"
    }

    private func row<Destination: View>(
        _ title: String,
        _ symbol: String,
        _ tint: Color,
        trailing: String? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        row(title, symbol, tint, pages: EmptyView(), trailing: trailing, destination: destination)
    }

    /// A screen of components: its row counts the screen's component pages.
    private func row<Pages: View, Destination: View>(
        _ title: String,
        _ symbol: String,
        _ tint: Color,
        pages: Pages,
        trailing: String? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
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
