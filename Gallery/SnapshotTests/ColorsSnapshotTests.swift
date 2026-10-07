//
//  ColorsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Semantic colours v2 (1.6.0): a swatch per token, light and dark, so a changed value shows
//  in the PNG diff. Split in three to fit the screen.
//

import SwiftUI
import Testing
import DesignTokens

extension ComponentSnapshots {
    @MainActor
    @Suite("Colors")
    struct Colors {
        @Test func semanticColors() async {
            await assertComponentSnapshot(
                SwatchGrid(items: [
                    ("primary", AppColors.Text.primary),
                    ("secondary", AppColors.Text.secondary),
                    ("tertiary", AppColors.Text.tertiary),
                    ("action", AppColors.Text.action),
                    ("positive", AppColors.Text.positive),
                    ("negative", AppColors.Text.negative),
                    ("warning", AppColors.Text.warning),
                    ("onAccent", AppColors.Text.onAccent),
                    ("primaryOnDark", AppColors.Text.primaryOnDark),
                    ("secondaryOnDark", AppColors.Text.secondaryOnDark),
                    ("tertiaryOnDark", AppColors.Text.tertiaryOnDark),
                    ("primaryOnLight", AppColors.Text.primaryOnLight),
                    ("secondaryOnLight", AppColors.Text.secondaryOnLight),
                    ("tertiaryOnLight", AppColors.Text.tertiaryOnLight),
                ]),
                named: "text"
            )
            await assertComponentSnapshot(
                SwatchGrid(items: [
                    ("base", AppColors.Background.base),
                    ("baseAlt", AppColors.Background.baseAlt),
                    ("elevation1", AppColors.Background.elevation1),
                    ("elevation2", AppColors.Background.elevation2),
                    ("elevation3", AppColors.Background.elevation3),
                    ("neutral1", AppColors.Background.neutral1),
                    ("neutral2", AppColors.Background.neutral2),
                    ("fill", AppColors.Background.fill),
                    ("fillOnDark", AppColors.Background.fillOnDark),
                    ("fillOnLight", AppColors.Background.fillOnLight),
                    ("overlayOnImage", AppColors.Background.overlayOnImage),
                    ("border.normal", AppColors.Border.normal),
                    ("border.opaque", AppColors.Border.opaque),
                    ("border.selected", AppColors.Border.selected),
                    ("border.darkOnly", AppColors.Border.darkModeOnly),
                    ("border.onDark", AppColors.Border.onDark),
                    ("border.onLight", AppColors.Border.onLight),
                ]),
                named: "surfaces"
            )
            await assertComponentSnapshot(
                SwatchGrid(items: [
                    ("info", AppColors.Status.info),
                    ("positive", AppColors.Status.positive),
                    ("negative", AppColors.Status.negative),
                    ("warning", AppColors.Status.warning),
                    ("neutral", AppColors.Status.neutral),
                    ("infoPale", AppColors.Status.infoPale),
                    ("positivePale", AppColors.Status.positivePale),
                    ("negativePale", AppColors.Status.negativePale),
                    ("warningPale", AppColors.Status.warningPale),
                    ("neutralPale", AppColors.Status.neutralPale),
                    ("pale(accent)", AppColors.pale(AppColors.accent)),
                    ("pale(category)", AppColors.pale(CategoryColors.color(for: "Food"))),
                ]),
                named: "status"
            )
        }
    }
}

/// Swatches four to a row, each with its token name. Not lazy, so all of it draws at once.
private struct SwatchGrid: View {
    let items: [(String, Color)]

    var body: some View {
        let rows = stride(from: 0, to: items.count, by: 4).map { Array(items[$0..<min($0 + 4, items.count)]) }
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: AppSpacing.sm) {
                    ForEach(rows[row], id: \.0) { name, color in
                        VStack(spacing: AppSpacing.xxs) {
                            RoundedRectangle(cornerRadius: AppRadius.xs)
                                .fill(color)
                                .frame(height: 36)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.xs)
                                        .strokeBorder(AppColors.Text.tertiary.opacity(0.4))
                                )
                            Text(verbatim: name)
                                .font(AppTypography.caption2)
                                .foregroundStyle(AppColors.Text.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    ForEach(0..<(4 - rows[row].count), id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    }
                }
            }
        }
    }
}
