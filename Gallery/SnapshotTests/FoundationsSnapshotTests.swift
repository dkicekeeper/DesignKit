//
//  FoundationsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Typography, buttons, cards, chips and the accent theme.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Foundations")
    struct Foundations {
        @Test func typography() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(verbatim: "Heading 1").font(AppTypography.h1)
                    Text(verbatim: "Heading 2").font(AppTypography.h2)
                    Text(verbatim: "Heading 3").font(AppTypography.h3)
                    Text(verbatim: "Heading 4").font(AppTypography.h4)
                    Text(verbatim: "Body emphasis").font(AppTypography.bodyEmphasis)
                    Text(verbatim: "Body text of a paragraph").font(AppTypography.body)
                    Text(verbatim: "Body small").font(AppTypography.bodySmall)
                    Text(verbatim: "Caption").font(AppTypography.caption)
                    Text(verbatim: "Caption 2").font(AppTypography.caption2)
                }
                .foregroundStyle(AppColors.Text.primary)
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .largeText]
            )
        }

        @Test func buttons() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    Button {} label: { Text(verbatim: "Primary").frame(maxWidth: .infinity) }
                        .dsButton()
                    Button {} label: { Text(verbatim: "Primary, disabled").frame(maxWidth: .infinity) }
                        .dsButton(disabled: true)
                    Button {} label: { Text(verbatim: "Secondary").frame(maxWidth: .infinity) }
                        .dsButton(.secondary)
                    // No DSButton(isLoading: true): its spinner turns on a clock, so no two
                    // captures match (docs/snapshots.md, "Not covered on purpose").
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func buttonMatrix() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach([DSButtonRole.normal, .destructive, .neutral], id: \.self) { role in
                        HStack(spacing: AppSpacing.sm) {
                            Button {} label: { Text(verbatim: "Primary") }.dsButton(.primary, role: role, size: .medium)
                            Button {} label: { Text(verbatim: "Secondary") }.dsButton(.secondary, role: role, size: .medium)
                            Button {} label: { Text(verbatim: "Flat") }.dsButton(.flat, role: role, size: .medium)
                        }
                    }
                    HStack(spacing: AppSpacing.sm) {
                        Button {} label: { Text(verbatim: "Small") }.dsButton(size: .small)
                        Button {} label: { Text(verbatim: "Disabled") }.dsButton(size: .medium, disabled: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark]
            )
        }

        @Test func numbers() async {
            await assertComponentSnapshot(
                HStack(alignment: .top, spacing: AppSpacing.xl) {
                    // `AppTypography.numbers` (proportional since 3.4.0), then tabular figures.
                    ForEach([false, true], id: \.self) { tabular in
                        VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                            ForEach(["1 111 111", "8 888 888", "407 150"], id: \.self) { amount in
                                Text(verbatim: amount)
                                    .font(tabular ? AppTypography.h4.monospacedDigit() : AppTypography.numbers(AppTypography.h4))
                            }
                        }
                    }
                }
                .foregroundStyle(AppColors.Text.primary)
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light]
            )
        }

        @Test func fadeTruncation() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(verbatim: "Halyk Bank savings account for the summer trip")
                        .font(AppTypography.h4)
                        .fadeTruncation()
                    Text(verbatim: "Fits as it is")
                        .font(AppTypography.h4)
                        .fadeTruncation()
                }
                .foregroundStyle(AppColors.Text.primary)
                .frame(width: 240, alignment: .leading),
                width: 240,
                appearances: [.light]
            )
        }

        @Test func cardAndChips() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(verbatim: "Card title")
                        .font(AppTypography.h4)
                    Text(verbatim: "cardStyle() is a Liquid Glass surface")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardContentPadding()
                .cardStyle(),
                named: "card"
            )
            await assertComponentSnapshot(
                HStack(spacing: AppSpacing.sm) {
                    Text(verbatim: "Selected").filterChipStyle(isSelected: true)
                    Text(verbatim: "Chip").filterChipStyle()
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                named: "chips"
            )
        }

        /// `SurfaceStyle` (8.12.0): the same section and card on Liquid Glass and as the grey
        /// fill on the white page; under `.fill` the greys inside a card (a tile's plate, chips, a
        /// track, a skeleton) stay a step darker than it. The glass twins look as before 8.12.0.
        @Test func surfaceStyles() async {
            let styles: [(SurfaceStyle, String)] = [(.glass, "glass"), (.fill, "fill")]
            for (surface, name) in styles {
                await assertComponentSnapshot(
                    FormSection(header: "Trip") {
                        UniversalRow("Reminder", icon: "clock", accessory: .toggle(.constant(true)))
                        ChipPicker("Bite", options: ["None", "Weak", "Good"], selection: .constant("Good"),
                                   inset: AppSpacing.lg) { $0 }
                            .padding(.vertical, AppSpacing.sm)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .surfaceStyle(surface),
                    named: "section-\(name)"
                )
                await assertComponentSnapshot(
                    HStack(spacing: AppSpacing.md) {
                        Icon(source: .sfSymbol("cart.fill"), size: AppIconSize.Tile.sm)
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(verbatim: "Groceries").font(AppTypography.h4)
                            LinearProgressBar(value: 0.6, animatesOnAppear: false)
                            SkeletonText(AppTypography.bodySmall, width: 120)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardContentPadding()
                    .cardStyle()
                    .surfaceStyle(surface),
                    named: "card-\(name)"
                )
            }
        }

        /// `.readableWidth()` and `AppLayout.cardColumns()` (8.13.0), drawn small: the window
        /// must fit the phone's screen, so a 240 pt column stands for the 720 pt one in a 360 pt
        /// "screen" (the whole width at a large text size, where the column grows), and 150 pt
        /// cards two in a row for the 320 pt ones on an iPad. Grey surfaces: glass cards side by
        /// side reflect each other.
        @Test func readableWidth() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    FormSection(header: "Trip") {
                        UniversalRow("Reminder", icon: "clock", accessory: .toggle(.constant(true)))
                    }
                    Text(verbatim: "The lake lies at 2,500 m, an hour's drive above the city.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardContentPadding()
                        .cardStyle()
                }
                .readableWidth(240)
                .background(AppColors.accent.opacity(0.08))
                .surfaceStyle(.fill),
                named: "column",
                appearances: [.light, .largeText]
            )
            await assertComponentSnapshot(
                LazyVGrid(columns: AppLayout.cardColumns(minimum: 150), spacing: AppSpacing.lg) {
                    ForEach(["Big Almaty Lake", "Charyn Canyon", "Kolsai Lakes"], id: \.self) { title in
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Icon(source: .sfSymbol("mountain.2.fill"), size: AppIconSize.lg)
                            Text(verbatim: title).font(AppTypography.h4)
                                .foregroundStyle(AppColors.Text.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardContentPadding()
                        .cardStyle()
                    }
                }
                .surfaceStyle(.fill),
                named: "cardGrid"
            )
        }

        /// `AdaptiveColumns` (8.15.0), drawn small like the column above: a 130 pt side beside a
        /// main column of at least 150 pt fits in 320 pt, and in 240 pt the side folds under the
        /// main column. At a large text size both widths grow, so 320 pt folds it too.
        @Test func adaptiveColumns() async {
            await assertComponentSnapshot(
                AdaptiveColumnsSpecimen().frame(width: 320).surfaceStyle(.fill),
                named: "sideBySide",
                appearances: [.light, .largeText]
            )
            await assertComponentSnapshot(
                AdaptiveColumnsSpecimen().frame(width: 240).surfaceStyle(.fill),
                named: "folded",
                appearances: [.light]
            )
        }

        /// Dalada's green accent through `DesignKitTheme.accent`: everything tinted follows it.
        @Test func daladaAccent() async {
            let saved = DesignKitTheme.accent
            DesignKitTheme.accent = Color(red: 0x2E / 255, green: 0x8B / 255, blue: 0x57 / 255)
            defer { DesignKitTheme.accent = saved }

            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Button {} label: { Text(verbatim: "Start trip").frame(maxWidth: .infinity) }
                        .dsButton()
                    HStack(spacing: AppSpacing.md) {
                        Badge("Verified", systemImage: "checkmark.seal")
                        SelectionIndicator(isSelected: true)
                        Avatar(name: "Ayan Seitkali", size: 32)
                        HeroSymbol(systemImage: "map", size: 48)
                    }
                    LinearProgressBar(value: 0.6, animatesOnAppear: false)
                },
                appearances: [.light, .dark]
            )
        }

        /// `AppColors.Palette` (3.7.0): each hue as a marker with a white symbol, the same in
        /// both themes.
        @Test func palette() async {
            await assertComponentSnapshot(
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 5), spacing: AppSpacing.sm) {
                    ForEach(AppColors.Palette.allCases, id: \.self) { hue in
                        VStack(spacing: AppSpacing.xxs) {
                            Circle()
                                .fill(hue.color)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                            Text(verbatim: hue.rawValue)
                                .font(AppTypography.caption)
                        }
                    }
                },
                appearances: [.light, .dark]
            )
        }
    }
}

/// A trip's route with its weather and group beside it, at the small widths of the snapshot.
private struct AdaptiveColumnsSpecimen: View {
    var body: some View {
        AdaptiveColumns(sideWidth: 130, mainMinWidth: 150, spacing: AppSpacing.md) {
            card("Route", symbol: "map.fill", detail: "Almaty, Big Almaty Lake, the observatory")
        } side: {
            card("Weather", symbol: "sun.max.fill", detail: "+18°, clear")
            card("Group", symbol: "person.2.fill", detail: "4 people")
        }
    }

    private func card(_ title: String, symbol: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Icon(source: .sfSymbol(symbol), size: AppIconSize.lg)
            Text(verbatim: title).font(AppTypography.h4)
                .foregroundStyle(AppColors.Text.primary)
            Text(verbatim: detail).font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardContentPadding()
        .cardStyle()
    }
}
