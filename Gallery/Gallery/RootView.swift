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
                    row("Actions", "hand.tap.fill", .blue, count: 8) { ActionsScreen() }
                    row("Text Input", "character.cursor.ibeam", .indigo, count: 4) { TextInputScreen() }
                    row("Selection", "checklist", .mint, count: 6) { SelectionScreen() }
                    row("Amounts & Currency", "banknote.fill", .green, count: 12) { AmountsScreen() }
                } header: {
                    Text("Input & Actions")
                }
                Section {
                    row("Rows: Settings & Forms", "list.bullet.rectangle.fill", .gray, count: 11) { SettingsRowsScreen() }
                    row("Rows: Data", "list.bullet", .cyan, count: 11) { DataRowsScreen() }
                    row("Cards: Money", "creditcard.fill", .green, count: 9) { MoneyCardsScreen() }
                    row("Cards: Progress & Stats", "chart.bar.doc.horizontal.fill", .orange, count: 12) { ProgressCardsScreen() }
                    row("Cards: Content", "text.bubble.fill", .pink, count: 5) { ContentCardsScreen() }
                } header: {
                    Text("Containers")
                } footer: {
                    Text("Rows and cards are split by what they show; each component has its own page with controls and states.")
                }
                Section {
                    row("Charts", "chart.xyaxis.line", .teal, count: 8) { ChartsScreen() }
                    row("Progress & Gauges", "gauge.with.dots.needle.67percent", .purple, count: 9) { ProgressScreen() }
                    row("Status & Feedback", "exclamationmark.bubble.fill", .red, count: 10) { FeedbackScreen() }
                } header: {
                    Text("Data & Status")
                }
                Section {
                    row("Headers & Navigation", "rectangle.topthird.inset.filled", .blue, count: 7) { NavigationScreen() }
                    row("Media & Identity", "person.crop.circle.fill", .indigo, count: 9) { MediaScreen() }
                    row("Content & Layout", "square.text.square.fill", .brown, count: 7) { ContentScreen() }
                    row("Sheets & Flows", "rectangle.portrait.bottomhalf.inset.filled", .mint, count: 7) { SheetsScreen() }
                    row("Effects", "sparkles", .purple, count: 5) { EffectsScreen() }
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
        count: Int? = nil,
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
                if let count {
                    Text("\(count)")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                        .monospacedDigit()
                }
            }
        }
    }
}

#Preview { RootView() }
