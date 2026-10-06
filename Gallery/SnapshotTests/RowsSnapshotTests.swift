//
//  RowsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  UniversalRow, settings rows, info rows, section headers, selection.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Rows")
    struct Rows {
        @Test func universalRows() async {
            await assertComponentSnapshot(
                VStack(spacing: 0) {
                    UniversalRow(config: .standard, leadingIcon: .sfSymbol("creditcard", color: AppColors.accent)) {
                        Text(verbatim: "Kaspi Gold")
                            .font(AppTypography.body)
                    } trailing: {
                        FormattedAmountText(amount: 152_340.5, currency: "KZT")
                    }
                    Divider()
                    UniversalRow(
                        config: .settings,
                        leadingIcon: .sfSymbol("bell", color: AppColors.accent),
                        hint: "A day before the payment"
                    ) {
                        Text(verbatim: "Reminders")
                            .font(AppTypography.body)
                    } trailing: {
                        DisclosureChevron()
                    }
                }
                .cardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func settingsRows() async {
            await assertComponentSnapshot(
                VStack(spacing: 0) {
                    ActionSettingsRow(icon: "square.and.arrow.up", title: "Export data") {}
                    Divider()
                    ToggleSettingsRow(icon: "faceid", title: "Face ID", isOn: .constant(true))
                    Divider()
                    ToggleSettingsRow(
                        icon: "location",
                        title: "Share location",
                        hint: "Friends see your trip on the map",
                        isOn: .constant(false)
                    )
                    Divider()
                    ActionSettingsRow(icon: "trash", title: "Delete all data", isDestructive: true) {}
                }
                .cardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func checkmarkRows() async {
            await assertComponentSnapshot(
                VStack(spacing: 0) {
                    CheckmarkRow("All accounts", isSelected: false) {}
                    CheckmarkRow("Kaspi Gold",
                                 icon: .custom(source: .sfSymbol("creditcard.fill"),
                                               style: .roundedSquare(size: AppIconSize.xl, tint: .accentMonochrome)),
                                 value: "120 000 ₸",
                                 isSelected: true) {}
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func infoRows() async {
            await assertComponentSnapshot(
                VStack(spacing: 0) {
                    InfoRow(icon: "calendar", label: "Next payment", value: "12 October")
                    InfoRow(icon: "banknote", label: "Amount", amount: 4_990, currency: "KZT")
                    InfoRow(label: "A long label that truncates before the value", value: "1 234 567 ₸")
                }
                .cardContentPadding()
                .cardStyle(),
                appearances: [.light, .largeText]
            )
        }

        @Test func headersAndSelection() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView("Accounts", systemImage: "creditcard")
                    SectionHeaderView("Compact header", style: .compact)
                    SectionHeaderView("Large header", style: .large)
                    HStack(spacing: AppSpacing.lg) {
                        SelectionIndicator(isSelected: true)
                        SelectionIndicator(isSelected: false)
                        SelectionIndicator(isSelected: true, tint: AppColors.success)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }
    }
}
