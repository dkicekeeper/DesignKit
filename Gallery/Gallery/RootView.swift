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
                Section("Foundations") {
                    row("Colors", "paintpalette.fill", AppColors.accent) { ColorsScreen() }
                    row("Typography", "textformat", .pink) { TypographyScreen() }
                    row("Spacing & Radius", "ruler.fill", .orange) { SpacingScreen() }
                    row("Icon Sizes", "square.resize", .teal) { IconSizesScreen() }
                }
                Section("Elements") {
                    row("Icons", "star.circle.fill", .indigo) { IconsScreen() }
                    row("Buttons", "hand.tap.fill", .blue) { ButtonsScreen() }
                    row("Cards & Surfaces", "rectangle.on.rectangle", .green) { CardsScreen() }
                    row("Motion", "wand.and.rays", .purple) { MotionScreen() }
                }
                Section("Components") {
                    row("Components", "square.grid.2x2.fill", AppColors.accent) { ComponentsScreen() }
                    row("Balances, Metrics & More", "creditcard.fill", .green) { BalancesScreen() }
                    row("Badges, Stats & Rating", "star.leadinghalf.filled", .yellow) { DisplayScreen() }
                    row("Loading, Steps & More", "rectangle.dashed", .gray) { PatternsScreen() }
                    row("Onboarding, Calendar & More", "calendar", .orange) { FlowsScreen() }
                    row("Forms & Settings", "list.bullet.rectangle.fill", .mint) { FormsScreen() }
                    row("Inputs & Charts", "slider.horizontal.3", .pink) { InputsScreen() }
                    row("Trend Charts", "chart.xyaxis.line", .teal) { TrendChartsScreen() }
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
        NavigationLink {
            destination()
        } label: {
            Label {
                Text(title).font(AppTypography.bodyEmphasis)
            } icon: {
                Image(systemName: symbol)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(tint, in: RoundedRectangle(cornerRadius: 7))
            }
        }
    }
}

#Preview { RootView() }
