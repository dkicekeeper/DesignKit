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
                        .screenPadding()
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
                    .screenPadding()
                    SectionHeader("Insights", systemImage: "sparkles", style: .large) {
                        Button("All") {}
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// Symbols around the title in every style (3.2.0): the one before it in the accent (the
        /// label's grey in compact), the one after it in the tertiary grey; a tint colours both.
        /// The card is its own snapshot: one glass card per snapshot.
        @Test func sectionHeaderSymbols() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader("Recent trips", systemImage: "map", trailingSystemImage: "chevron.forward") {
                        Button("All") {}
                    }
                    SectionHeader("Waiting to send", systemImage: "icloud.and.arrow.up",
                                  trailingSystemImage: "info.circle", style: .compact)
                        .screenPadding()
                    SectionHeader("Insights", systemImage: "sparkles", trailingSystemImage: "chevron.forward",
                                  style: .large)
                    SectionHeader("Goals", systemImage: "target", trailingSystemImage: "chevron.forward",
                                  tint: AppColors.success)
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                named: "styles",
                appearances: [.light, .dark, .largeText]
            )
            await assertComponentSnapshot(
                SectionHeader("Yesterday", systemImage: "calendar", trailingSystemImage: "info.circle",
                              style: .card) {
                    FormattedAmountText(amount: 45_000, currency: "KZT", prefix: "-",
                                        fontSize: AppTypography.bodySmall, fontWeight: .semibold,
                                        color: AppColors.Text.tertiary)
                },
                named: "card"
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

        /// UniversalRow's accessories (6.2.0) in a card: every row's icon 24 pt, so the titles
        /// line up; a value, a switch, a menu, a stepper, a date, a destructive action.
        @Test func universalRowAccessories() async {
            await assertComponentSnapshot(
                NavigationStack {
                    FormSection {
                        UniversalRow("Next payment", icon: "calendar", accessory: .info("12 October"))
                        Divider().padding(.leading, AppSpacing.lg)
                        UniversalRow("Quiet hours", icon: "moon.fill", hint: "No notifications at night",
                                     accessory: .toggle(.constant(true)))
                        Divider().padding(.leading, AppSpacing.lg)
                        UniversalRow("Language", icon: "globe", value: "English", accessory: .navigation { EmptyView() })
                        Divider().padding(.leading, AppSpacing.lg)
                        UniversalRow("Repeat", icon: "repeat", accessory: .menu(.constant("month"), options: [
                            (label: "Weekly", value: "week"), (label: "Monthly", value: "month"),
                        ]))
                        Divider().padding(.leading, AppSpacing.lg)
                        UniversalRow("Fish caught", icon: "number", accessory: .stepper(.constant(3), in: 0...99) { "\($0) pcs" })
                        Divider().padding(.leading, AppSpacing.lg)
                        UniversalRow("Delete all data", icon: "trash", role: .destructive, accessory: .action {})
                    }
                    .toolbar(.hidden, for: .navigationBar)
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        /// The same rows in a List (`config: .settings`): the list pads them and draws the
        /// navigation chevron.
        @Test func universalRowList() async {
            await assertComponentSnapshot(
                NavigationStack {
                    List {
                        UniversalRow("Quiet hours", icon: "moon.fill", config: .settings, accessory: .toggle(.constant(false)))
                        UniversalRow("Language", icon: "globe", value: "English", config: .settings,
                                     accessory: .navigation { EmptyView() })
                        UniversalRow("Kaspi Gold", icon: "creditcard.fill", value: "1 250 000 ₸", config: .settings,
                                     accessory: .checkmark(isSelected: true) {})
                    }
                    .scrollDisabled(true)
                    .frame(height: 260)
                    .toolbar(.hidden, for: .navigationBar)
                },
                appearances: [.light, .dark]
            )
        }

        /// A settings card of form rows (6.1.0): each with `.standard`, so all pad alike, the
        /// slider included; inset dividers between them. A home background's photo settings.
        @Test func settingsCard() async {
            await assertComponentSnapshot(
                FormSection {
                    ActionRowLabel("Change photo", systemImage: "photo.on.rectangle")
                    Divider().padding(.leading, AppSpacing.lg)
                    ToggleSettingsRow(icon: "camera.filters", title: "Blur", config: .standard, isOn: .constant(true))
                    Divider().padding(.leading, AppSpacing.lg)
                    SliderRow("Intensity", systemImage: "circle.lefthalf.filled", value: .constant(0.35),
                              in: 0.05...1, valueText: "35%", config: .standard)
                    Divider().padding(.leading, AppSpacing.lg)
                    ActionSettingsRow(icon: "trash", title: "Remove photo", isDestructive: true, config: .standard) {}
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        /// ItemRow (3.6.0) in both styles, with a pale-circle symbol, a top glyph next to a
        /// description, a badge, two meta lines and the accessories; one card per style.
        @Test func itemRows() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ItemRow(
                        "Morning on Kapchagay",
                        meta: [
                            MetaLine([.text("12 Oct"), .text("14.2 km"), .text("3 h 10 min")]),
                            MetaLine([.label("with @aida", systemImage: "person.2")], tint: AppColors.Text.tertiary),
                        ],
                        leading: .symbol("figure.fishing"),
                        titleLineLimit: 1
                    ) {
                        DisclosureChevron()
                    }
                    ItemRow(
                        "Camp by the river",
                        meta: [MetaLine([
                            .label("Friends", systemImage: "person.2"),
                            .label("Pending", systemImage: "hourglass", tint: AppColors.warning),
                        ], separator: .space)],
                        leading: .symbol("tent")
                    ) {
                        DisclosureChevron()
                    }
                    ItemRow(
                        "Three knots for every angler",
                        detail: "The clinch, the palomar and the loop: when each holds and how to tie it.",
                        meta: [MetaLine([.text("Knots"), .text("4 min"), .symbol("bookmark.fill", accessibilityLabel: "Saved")],
                                        tint: AppColors.Text.tertiary)],
                        leading: .glyph("book")
                    )
                    ItemRow("Spinning rod", meta: [MetaLine([.text("Shimano"), .text("×2"), .text("620 g")])],
                            titleFont: AppTypography.body) {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundStyle(AppColors.warning)
                    }
                }
                .cardContentPadding()
                .cardStyle(),
                named: "standard",
                appearances: [.light, .dark, .largeText]
            )
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ItemRow("12 Oct 2026, 09:40", badge: "Auto",
                            meta: [MetaLine([.text("1 204 transactions"), .text("3.1 MB")])], style: .large) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.accent)
                    }
                    ItemRow("Coffee", meta: [MetaLine([.text("Used 14 times"), .text("Oct 9, 2026")])],
                            style: .large, titleFont: AppTypography.h4)
                }
                .cardContentPadding()
                .cardStyle(),
                named: "large",
                appearances: [.light, .dark, .largeText]
            )
        }
    }
}
