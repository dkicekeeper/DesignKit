//
//  SurfacesScreen.swift
//  DesignKit Gallery
//
//  Surfaces: glass or a grey fill (8.12.0), the card, the form card, the filter chip, and the
//  padding a card owns.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct SurfacesScreen: View {
    static let title = "Surfaces"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per surface; the Updates screen links to them (ComponentIndex).
    @ViewBuilder static var pages: some View {
        SurfaceStylePage()
        CardStylePage()
        FormCardStylePage()
        FilterChipStylePage()
    }
}

private struct SurfaceStylePage: View {
    @State private var surface: SurfaceStyle = .fill
    @State private var reminder = true
    @State private var chip = 0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "SurfaceStyle",
            summary: "How the surfaces draw: Liquid Glass (Tenra, Dalada) or a grey fill on the white page with no glass. Set DesignKitTheme.surface once in App.init(); .surfaceStyle(_:) changes a subtree. The toolbar's Surfaces menu shows every page either way.",
            since: "8.12.0",
            apps: [],
            canvas: .fill,
            notes: [
                "It reaches cardStyle() and everything on it (FormSection, CardList, the cards), filter chips, ProgressRingTile, an Icon's glass plate, OnboardingStepIndicator and MessageBanner.",
                "Buttons (DSButton, .buttonStyle(.glass)), floating chrome (MessageComposer, GlassActionMenu, the system's bars) and glass drawn on a coloured hero stay Liquid Glass.",
                "Under .fill the greys inside a card (an icon's plate, tracks, chips, skeletons) turn translucent, a step darker than the card: .surfaceNeutral1 and .surfaceNeutral2 for an app's own.",
            ],
            styles: [".glass", ".fill"],
            dos: [
                "Choose it once for the app, next to DesignKitTheme.accent.",
                "Fill an app's own neutral shape inside a card with .surfaceNeutral1 or .surfaceNeutral2.",
            ],
            donts: [
                "Don't use .fill on a grey page (systemGroupedBackground): the cards melt into it.",
                "Don't put AppColors.Background.neutral1 inside a grey card: it is the card's own colour.",
            ]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if state == .loading {
                    FormSection(header: "Trip") {
                        UniversalRowSkeleton()
                        UniversalRowSkeleton()
                    }
                } else {
                    FormSection(header: "Trip") {
                        UniversalRow("Reminder", icon: "clock", accessory: .toggle($reminder))
                        UniversalRow("Route", icon: "map", accessory: .info("Big Almaty Lake"))
                    }
                }
                HStack(spacing: AppSpacing.md) {
                    Icon(source: .sfSymbol("cart.fill"), size: AppIconSize.Tile.sm)
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Groceries").font(AppTypography.h4)
                        LinearProgressBar(value: 0.6, animatesOnAppear: false)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardContentPadding()
                .cardStyle()
                HStack(spacing: AppSpacing.sm) {
                    ForEach(Array(["All", "Hikes", "Lakes"].enumerated()), id: \.offset) { index, title in
                        Text(title)
                            .filterChipStyle(isSelected: chip == index)
                            .onTapGesture { chip = index }
                    }
                }
            }
            // The page the surfaces lie on, whatever the Gallery's own canvas.
            .padding(AppSpacing.lg)
            .background(AppColors.Background.base, in: .rect(cornerRadius: AppRadius.lg))
            .surfaceStyle(surface)
        } controls: {
            ChoiceControl("Surface", selection: $surface, options: [("Glass", .glass), ("Fill", .fill)])
            StateControl(state: $state)
        }
    }
}

private struct CardStylePage: View {
    @State private var radius = Double(AppRadius.xl)
    @State private var padded = true

    var body: some View {
        ComponentPage(
            name: ".cardStyle()",
            summary: "The display card: Liquid Glass, or a grey fill under SurfaceStyle.fill (8.12.0). It adds no padding: the content pads itself (.cardContentPadding(), 16 pt).",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "A card pads itself; a row pads only vertically; a primitive not at all (design-system §10).",
                "A card with native menus inside uses .formCardStyle(): glass would morph into the menu.",
            ]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Total balance").font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text("₸ 1 284 500").font(AppTypography.h2)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(padded ? AppSpacing.lg : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(radius: radius)
        } controls: {
            SliderControl("Corner radius", value: $radius, in: 0...32, step: 2) { "\(Int($0)) pt" }
            ToggleControl("Content padding", isOn: $padded)
        }
    }
}

private struct FormCardStylePage: View {
    var body: some View {
        ComponentPage(
            name: ".formCardStyle()",
            summary: "A material card, for a host that wants one. Up to 7.x the form cards were material for fear of menus in glass; since 8.0.0 FormSection is glass (cardStyle), and menus open from their row there too.",
            apps: [],
            canvas: .fill
        ) {
            VStack(spacing: 0) {
                ForEach(["Currency", "Category", "Account"], id: \.self) { label in
                    HStack {
                        Text(label).font(AppTypography.body)
                        Spacer()
                        Text("Choose").font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .padding(AppSpacing.lg)
                    if label != "Account" { Divider().padding(.leading, AppSpacing.lg) }
                }
            }
            .formCardStyle()
        }
    }
}

private struct FilterChipStylePage: View {
    @State private var selected = 0

    var body: some View {
        ComponentPage(
            name: ".filterChipStyle()",
            summary: "An interactive chip on Liquid Glass; the selected one gets an accent tint.",
            apps: [.tenra, .dalada]
        ) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(Array(["All", "Income", "Expense"].enumerated()), id: \.offset) { index, title in
                    Text(title)
                        .filterChipStyle(isSelected: selected == index)
                        .onTapGesture { selected = index }
                }
            }
        }
    }
}

#Preview { NavigationStack { SurfacesScreen() } }
