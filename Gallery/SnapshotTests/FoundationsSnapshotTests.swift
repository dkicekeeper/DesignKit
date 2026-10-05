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
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .largeText]
            )
        }

        @Test func buttons() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    Button {} label: { Text(verbatim: "Primary").frame(maxWidth: .infinity) }
                        .primaryButton()
                    Button {} label: { Text(verbatim: "Primary, disabled").frame(maxWidth: .infinity) }
                        .primaryButton(disabled: true)
                    Button {} label: { Text(verbatim: "Secondary").frame(maxWidth: .infinity) }
                        .secondaryButton()
                    // No LoadingButtonLabel(isLoading: true): its spinner turns on a clock, so no
                    // two captures match (docs/snapshots.md, "Not covered on purpose").
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func cardAndChips() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(verbatim: "Card title")
                            .font(AppTypography.h4)
                        Text(verbatim: "cardStyle() is a Liquid Glass surface")
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardContentPadding()
                    .cardStyle()

                    HStack(spacing: AppSpacing.sm) {
                        Text(verbatim: "Selected").filterChipStyle(isSelected: true)
                        Text(verbatim: "Chip").filterChipStyle()
                    }
                }
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
                        .primaryButton()
                    HStack(spacing: AppSpacing.md) {
                        BadgeView("Verified", systemImage: "checkmark.seal")
                        SelectionIndicator(isSelected: true)
                        AvatarView(name: "Ayan Seitkali", size: 32)
                        HeroSymbol(systemImage: "map", size: 48)
                    }
                    LinearProgressBar(value: 0.6, animatesOnAppear: false)
                },
                appearances: [.light, .dark]
            )
        }
    }
}
