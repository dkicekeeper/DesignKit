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
        /// Rows in a FormSection (8.0.0): the card pads them at the sides and draws the divider
        /// under the upper row's text.
        @Test func universalRows() async {
            await assertComponentSnapshot(
                FormSection {
                    UniversalRow(config: .standard, leadingIcon: .sfSymbol("creditcard", color: AppColors.accent)) {
                        Text(verbatim: "Kaspi Gold")
                            .font(AppTypography.body)
                    } trailing: {
                        FormattedAmountText(amount: 152_340.5, currency: "KZT")
                    }
                    UniversalRow(
                        config: .standard,
                        leadingIcon: .sfSymbol("bell", color: AppColors.accent),
                        hint: "A day before the payment"
                    ) {
                        Text(verbatim: "Reminders")
                            .font(AppTypography.body)
                    } trailing: {
                        DisclosureChevron()
                    }
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        /// A settings section (8.0.0: a glass card as every form, no longer a List's rows).
        @Test func settingsRows() async {
            await assertComponentSnapshot(
                FormSection(header: "Privacy") {
                    UniversalRow("Export data", icon: "square.and.arrow.up", accessory: .action {})
                    UniversalRow("Face ID", icon: "faceid", accessory: .toggle(.constant(true)))
                    UniversalRow("Share location", icon: "location", hint: "Friends see your trip on the map",
                                 accessory: .toggle(.constant(false)))
                    UniversalRow("Delete all data", icon: "trash", role: .destructive, accessory: .action {})
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func checkmarkRows() async {
            await assertComponentSnapshot(
                VStack(spacing: 0) {
                    UniversalRow("All accounts", config: .settings, accessory: .checkmark(isSelected: false) {})
                    UniversalRow("Kaspi Gold",
                                 leadingIcon: .custom(source: .sfSymbol("creditcard.fill"),
                                                      style: .roundedSquare(size: AppIconSize.xl, tint: .accentMonochrome)),
                                 value: "120 000 ₸",
                                 config: .settings,
                                 accessory: .checkmark(isSelected: true) {})
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func infoRows() async {
            await assertComponentSnapshot(
                VStack(spacing: 0) {
                    UniversalRow("Next payment", icon: "calendar", config: .info, accessory: .info("12 October"))
                    UniversalRow("Amount", icon: "banknote", config: .info, accessory: .amount(4_990, currency: "KZT"))
                    UniversalRow("A long label that truncates before the value", config: .info, accessory: .info("1 234 567 ₸"))
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
                UniversalRow("Color", config: .settings, accessory: .colors(.constant(CategoryColors.pickerPalette[2])))
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
                    SectionHeader("Waiting to send") {
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
                FormSection {
                    UniversalRow("Colour intensity", icon: "circle.lefthalf.filled",
                                 accessory: .slider(.constant(0.6), in: 0.05...1, valueText: "60%"))
                    UniversalRow("Radius", hint: "Trips hide their track inside this circle",
                                 accessory: .slider(.constant(500), in: 100...2_000, step: 100, valueText: "500 m"))
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        /// UniversalRow's accessories (7.0.0) in a card: every row's icon 24 pt, so the titles
        /// line up; a value, a switch, a menu, a stepper, a date, a destructive action.
        @Test func universalRowAccessories() async {
            // A NavigationStack has no size of its own: a fixed height, taller at large text,
            // where the menu, the stepper and the navigation value move under the title (within
            // the 956 pt screen with the margins: SnapshotSupport checks it).
            await assertComponentSnapshot(accessoryRows(height: 360), appearances: [.light, .dark])
            await assertComponentSnapshot(accessoryRows(height: 680), named: "accessibility", appearances: [.largeText])
        }

        private func accessoryRows(height: CGFloat) -> some View {
            NavigationStack {
                FormSection {
                    UniversalRow("Next payment", icon: "calendar", accessory: .info("12 October"))
                    UniversalRow("Quiet hours", icon: "moon.fill", hint: "No notifications at night",
                                 accessory: .toggle(.constant(true)))
                    UniversalRow("Language", icon: "globe", value: "English", accessory: .navigation { EmptyView() })
                    UniversalRow("Repeat", icon: "repeat", accessory: .menu(.constant("month"), options: [
                        (label: "Weekly", value: "week"), (label: "Monthly", value: "month"),
                    ]))
                    UniversalRow("Fish caught", icon: "number", accessory: .stepper(.constant(3), in: 0...99) { "\($0) pcs" })
                    UniversalRow("Delete all data", icon: "trash", role: .destructive, accessory: .action {})
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .toolbar(.hidden, for: .navigationBar)
            }
            .frame(height: height)
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
                    .toolbar(.hidden, for: .navigationBar)
                }
                // A NavigationStack has no size of its own.
                .frame(height: 260),
                appearances: [.light, .dark]
            )
        }

        /// A settings card of form rows (6.1.0): each with `.standard`, so all pad alike, the
        /// slider included; inset dividers between them. A home background's photo settings.
        @Test func settingsCard() async {
            await assertComponentSnapshot(
                FormSection {
                    UniversalRow("Change photo", icon: "photo.on.rectangle", titleColor: AppColors.accent)
                    UniversalRow("Blur", icon: "camera.filters", accessory: .toggle(.constant(true)))
                    UniversalRow("Intensity", icon: "circle.lefthalf.filled",
                                 accessory: .slider(.constant(0.35), in: 0.05...1, valueText: "35%"))
                    UniversalRow("Remove photo", icon: "trash", role: .destructive, accessory: .action {})
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
