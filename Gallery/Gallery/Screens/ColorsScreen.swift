//
//  ColorsScreen.swift
//  DesignKit Gallery
//
//  Semantic colours v2 (1.6.0): one page per group, each token with its swatch and what it is
//  for; then the flat 1.x names, the financial tokens and the category palette.
//

import SwiftUI
import DesignTokens

struct ColorsScreen: View {
    private struct Token: Identifiable {
        let name: String
        let color: Color
        let use: String
        var id: String { name }
    }

    private let text: [Token] = [
        .init(name: "Text.primary", color: AppColors.Text.primary, use: "Main text and icons"),
        .init(name: "Text.secondary", color: AppColors.Text.secondary, use: "Subtitles, metadata"),
        .init(name: "Text.tertiary", color: AppColors.Text.tertiary, use: "Hints, disclaimers, disabled"),
        .init(name: "Text.action", color: AppColors.Text.action, use: "Links, text buttons (accent)"),
        .init(name: "Text.positive", color: AppColors.Text.positive, use: "A rise, money in, done"),
        .init(name: "Text.negative", color: AppColors.Text.negative, use: "A fall, an error"),
        .init(name: "Text.warning", color: AppColors.Text.warning, use: "A warning"),
        .init(name: "Text.onAccent", color: AppColors.Text.onAccent, use: "On an accent fill"),
    ]

    private let background: [Token] = [
        .init(name: "Background.base", color: AppColors.Background.base, use: "The screen"),
        .init(name: "Background.baseAlt", color: AppColors.Background.baseAlt, use: "Grouped-list screen"),
        .init(name: "Background.elevation1", color: AppColors.Background.elevation1, use: "Sheets, cards on base"),
        .init(name: "Background.elevation2", color: AppColors.Background.elevation2, use: "Cards on elevation 1"),
        .init(name: "Background.elevation3", color: AppColors.Background.elevation3, use: "Above everything"),
        .init(name: "Background.neutral1", color: AppColors.Background.neutral1, use: "Fields, grouped blocks"),
        .init(name: "Background.neutral2", color: AppColors.Background.neutral2, use: "Tracks, sunken controls"),
        .init(name: "Background.fill", color: AppColors.Background.fill, use: "Translucent, any surface"),
    ]

    private let status: [Token] = [
        .init(name: "Status.info", color: AppColors.Status.info, use: "Information"),
        .init(name: "Status.positive", color: AppColors.Status.positive, use: "Success, a rise"),
        .init(name: "Status.negative", color: AppColors.Status.negative, use: "An error, a fall"),
        .init(name: "Status.warning", color: AppColors.Status.warning, use: "A warning"),
        .init(name: "Status.neutral", color: AppColors.Status.neutral, use: "Archived, paused"),
    ]

    private let border: [Token] = [
        .init(name: "Border.normal", color: AppColors.Border.normal, use: "Separators, outlines"),
        .init(name: "Border.opaque", color: AppColors.Border.opaque, use: "Overlapping outlines"),
        .init(name: "Border.selected", color: AppColors.Border.selected, use: "A selected element"),
        .init(name: "Border.darkModeOnly", color: AppColors.Border.darkModeOnly, use: "Shows in dark only"),
    ]

    private let legacy: [Token] = [
        .init(name: "bgBase", color: AppColors.bgBase, use: "= Background.base"),
        .init(name: "bgCard", color: AppColors.bgCard, use: "= Background.neutral1"),
        .init(name: "bgMuted", color: AppColors.bgMuted, use: "= Background.neutral2"),
        .init(name: "textPrimary", color: AppColors.textPrimary, use: "= Text.primary"),
        .init(name: "textSecondary", color: AppColors.textSecondary, use: "= Text.secondary"),
        .init(name: "textTertiary", color: AppColors.textTertiary, use: "= Text.tertiary"),
        .init(name: "accent", color: AppColors.accent, use: "DesignKitTheme.accent"),
        .init(name: "destructive", color: AppColors.destructive, use: "= Status.negative"),
        .init(name: "success", color: AppColors.success, use: "= Status.positive"),
        .init(name: "warning", color: AppColors.warning, use: "= Status.warning"),
        .init(name: "staticWhite", color: AppColors.staticWhite, use: "= Text.primaryOnDark"),
    ]

    private let financial: [Token] = [
        .init(name: "income", color: AppColors.income, use: "Money in"),
        .init(name: "expense", color: AppColors.expense, use: "Money out (not red)"),
        .init(name: "transfer", color: AppColors.transfer, use: "Between own accounts"),
        .init(name: "planned", color: AppColors.planned, use: "= Status.info"),
    ]

    var body: some View {
        ShowcasePage(title: "Colors") {
            ShowcaseSection(title: "Text", subtitle: "AppColors.Text · follows the theme") {
                tokenList(text)
            }
            ShowcaseSection(title: "On dark / on light", subtitle: "Text on photos and headers · the same in both themes") {
                onDarkOnLight
            }
            ShowcaseSection(title: "Background", subtitle: "AppColors.Background · levels and containers") {
                elevationDemo
                tokenList(background)
            }
            ShowcaseSection(title: "Status", subtitle: "AppColors.Status · solid and pale") {
                statusDemo
                tokenList(status)
            }
            ShowcaseSection(title: "Border", subtitle: "AppColors.Border") {
                tokenList(border)
                darkModeOnlyDemo
            }
            ShowcaseSection(title: "Flat names (1.x)", subtitle: "Aliases of the groups · keep working") {
                tokenList(legacy)
            }
            ShowcaseSection(title: "Financial", subtitle: "Transaction-type tokens") {
                tokenList(financial)
            }
            ShowcaseSection(title: "Category palette", subtitle: "Deterministic hash → color · AppColors.pale(_:)") {
                paletteDemo
            }
        }
    }

    // MARK: Lists

    private func tokenList(_ tokens: [Token]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(tokens) { token in
                HStack(spacing: AppSpacing.md) {
                    RoundedRectangle(cornerRadius: AppRadius.xs)
                        .fill(token.color)
                        .frame(width: 44, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.xs)
                                .strokeBorder(AppColors.Border.normal)
                        )
                    VStack(alignment: .leading, spacing: 0) {
                        Text(token.name)
                            .font(AppTypography.caption.weight(.medium))
                            .foregroundStyle(AppColors.Text.primary)
                        Text(token.use)
                            .font(AppTypography.caption2)
                            .foregroundStyle(AppColors.Text.secondary)
                    }
                }
            }
        }
    }

    // MARK: Demos

    private var onDarkOnLight: some View {
        VStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Primary on dark").font(AppTypography.h4).foregroundStyle(AppColors.Text.primaryOnDark)
                Text("Secondary on dark").font(AppTypography.body).foregroundStyle(AppColors.Text.secondaryOnDark)
                Text("Tertiary on dark").font(AppTypography.bodySmall).foregroundStyle(AppColors.Text.tertiaryOnDark)
                Text("fillOnDark")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.primaryOnDark)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(AppColors.Background.fillOnDark, in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.lg)
            .background(
                LinearGradient(colors: [.indigo, .black], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: AppRadius.lg)
            )

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Primary on light").font(AppTypography.h4).foregroundStyle(AppColors.Text.primaryOnLight)
                Text("Secondary on light").font(AppTypography.body).foregroundStyle(AppColors.Text.secondaryOnLight)
                Text("Tertiary on light").font(AppTypography.bodySmall).foregroundStyle(AppColors.Text.tertiaryOnLight)
                Text("fillOnLight")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.primaryOnLight)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(AppColors.Background.fillOnLight, in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.lg)
            .background(
                LinearGradient(colors: [.yellow.opacity(0.5), .orange.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: AppRadius.lg)
            )

            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [.teal, .green], startPoint: .top, endPoint: .bottom)
                AppColors.Background.overlayOnImage
                Text("overlayOnImage under text")
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primaryOnDark)
                    .padding(AppSpacing.lg)
            }
            .frame(height: 96)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        }
    }

    private var elevationDemo: some View {
        ZStack(alignment: .topLeading) {
            level("base", AppColors.Background.base, offset: 0)
            level("elevation1", AppColors.Background.elevation1, offset: 1)
            level("elevation2", AppColors.Background.elevation2, offset: 2)
            level("elevation3", AppColors.Background.elevation3, offset: 3)
        }
        .frame(height: 200, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.Background.baseAlt, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private func level(_ name: String, _ color: Color, offset: Int) -> some View {
        Text(name)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.Text.secondary)
            .padding(AppSpacing.sm)
            .frame(width: 150, height: 96, alignment: .topLeading)
            .background(color, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            .offset(x: CGFloat(offset) * 36, y: CGFloat(offset) * 28)
    }

    private var statusDemo: some View {
        VStack(spacing: AppSpacing.sm) {
            statusRow("info.circle.fill", "Statement is ready", AppColors.Status.info, AppColors.Status.infoPale)
            statusRow("checkmark.circle.fill", "Payment sent", AppColors.Status.positive, AppColors.Status.positivePale)
            statusRow("exclamationmark.triangle.fill", "Card expires soon", AppColors.Status.warning, AppColors.Status.warningPale)
            statusRow("xmark.octagon.fill", "Transfer failed", AppColors.Status.negative, AppColors.Status.negativePale)
            statusRow("pause.circle.fill", "Subscription paused", AppColors.Status.neutral, AppColors.Status.neutralPale)
        }
    }

    private func statusRow(_ symbol: String, _ text: String, _ solid: Color, _ pale: Color) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: symbol).foregroundStyle(solid)
            Text(text).font(AppTypography.bodySmall).foregroundStyle(AppColors.Text.primary)
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(pale, in: RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private var darkModeOnlyDemo: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach([Color.black, .indigo, .red], id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(AppColors.Border.darkModeOnly, lineWidth: 1))
            }
            Text("Border.darkModeOnly: switch the Gallery to dark")
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.Text.secondary)
        }
    }

    private var paletteDemo: some View {
        let names = ["Food", "Travel", "Bills", "Health", "Shopping", "Salary", "Gifts", "Home"]
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: AppSpacing.sm)], spacing: AppSpacing.sm) {
            ForEach(names, id: \.self) { name in
                let color = CategoryColors.hexColor(for: name)
                Text(name)
                    .font(AppTypography.caption.weight(.medium))
                    .foregroundStyle(color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.pale(color), in: RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
    }
}

#Preview { NavigationStack { ColorsScreen() } }
