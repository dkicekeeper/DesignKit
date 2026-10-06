//
//  SurfacesScreen.swift
//  DesignKit Gallery
//
//  Surfaces: the glass card, the form card, the filter chip, and the padding a card owns.
//

import SwiftUI
import DesignTokens
import DesignComponents

struct SurfacesScreen: View {
    var body: some View {
        ShowcasePage(title: "Surfaces") {
            CardStylePage()
            FormCardStylePage()
            FilterChipStylePage()
        }
    }
}

private struct CardStylePage: View {
    @State private var radius = Double(AppRadius.xl)
    @State private var padded = true

    var body: some View {
        ComponentPage(
            name: ".cardStyle()",
            summary: "The Liquid Glass display card. It adds no padding: the content pads itself (.cardContentPadding(), 16 pt).",
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
            summary: "The material card for interactive rows (menus, pickers): no glass, so native menus open from their own row.",
            apps: [.tenra],
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
