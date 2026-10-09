//
//  RootView.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens

/// Brand accents of the apps that consume DesignKit. The Gallery can preview either:
/// `DesignKitTheme.accent` is read at render time, so switching re-renders the tree.
enum GalleryTheme: String, CaseIterable, Identifiable {
    case tenra = "Tenra"
    case dalada = "Dalada"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .tenra: return .indigo
        // Dalada's AccentColor (light #2E8B57 / dark #3CB371).
        case .dalada: return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0x3C / 255, green: 0xB3 / 255, blue: 0x71 / 255, alpha: 1)
                : UIColor(red: 0x2E / 255, green: 0x8B / 255, blue: 0x57 / 255, alpha: 1)
        })
        }
    }
}

struct RootView: View {
    @State private var theme: GalleryTheme = .tenra

    var body: some View {
        NavigationStack {
            List {
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
            .navigationTitle("DesignKit")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Theme", selection: themeSelection) {
                        ForEach(GalleryTheme.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text(versionLine)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.bottom, AppSpacing.xs)
            }
        }
        .tint(AppColors.accent)
        // Tokens are static reads: a new identity re-renders every screen with the new accent.
        .id(theme)
    }

    /// Sets the accent BEFORE the state change, so the re-render already reads the new value.
    private var themeSelection: Binding<GalleryTheme> {
        Binding(
            get: { theme },
            set: { newTheme in
                DesignKitTheme.accent = newTheme.accent
                theme = newTheme
            }
        )
    }

    private var versionLine: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "DesignKit \(version) (\(build)) · \(theme.rawValue) theme"
    }

    private func row<Destination: View>(
        _ title: String,
        _ symbol: String,
        _ tint: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        row(title, symbol, tint, pages: EmptyView(), destination: destination)
    }

    /// A screen of components: its row counts the screen's component pages.
    private func row<Pages: View, Destination: View>(
        _ title: String,
        _ symbol: String,
        _ tint: Color,
        pages: Pages,
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
                }
            }
        }
    }
}

#Preview { RootView() }
