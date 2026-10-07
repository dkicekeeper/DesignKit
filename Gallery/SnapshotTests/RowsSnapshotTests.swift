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
                    SectionHeader("Accounts", systemImage: "creditcard")
                    SectionHeader("Compact header", style: .compact)
                    SectionHeader("Large header", style: .large)
                    HStack(spacing: AppSpacing.lg) {
                        SelectionIndicator(isSelected: true)
                        SelectionIndicator(isSelected: false)
                        SelectionIndicator(isSelected: true, tint: AppColors.success)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }

        @Test func colorPickerRow() async {
            await assertComponentSnapshot(
                ColorPickerRow(selectedColorHex: .constant(CategoryColors.pickerPalette[2]), title: "Color")
                    .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// One header per snapshot: each is a glass card. The label is the app's own (Tenra passes
        /// "Today", "Yesterday" or the formatted date). `SectionHeader(style: .card)` since 2.0.0
        /// (DateSectionHeaderView before, the same pixels).
        @Test func dateSectionHeaders() async {
            await assertComponentSnapshot(
                SectionHeader("Yesterday", style: .card) {
                    FormattedAmountText(amount: 45_000, currency: "KZT", prefix: "-",
                                        fontSize: AppTypography.bodySmall, fontWeight: .semibold,
                                        color: AppColors.Text.tertiary)
                },
                named: "withTotal",
                appearances: [.light, .dark, .largeText]
            )
            await assertComponentSnapshot(
                SectionHeader("30 September", style: .card),
                named: "labelOnly"
            )
        }

        /// The action at the end of the line (1.15.0), in each style.
        @Test func sectionHeaderTrailing() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader("Recent trips", systemImage: "map") {
                        Button("All") {}
                    }
                    SectionHeader("Waiting to send", style: .compact) {
                        Button("Send now") {}
                    }
                    SectionHeader("Insights", systemImage: "sparkles", style: .large) {
                        Button("All") {}
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func sliderRow() async {
            await assertComponentSnapshot(
                VStack(spacing: 0) {
                    SliderRow("Colour intensity", systemImage: "circle.lefthalf.filled",
                              value: .constant(0.6), in: 0.05...1, valueText: "60%")
                    Divider()
                    SliderRow("Radius", value: .constant(500), in: 100...2_000, step: 100, valueText: "500 m",
                              hint: "Trips hide their track inside this circle")
                }
                .padding(.horizontal, AppSpacing.lg)
                .formCardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }
    }
}
