//
//  FormsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Form sections with their picker rows, settings headers, the entity-detail hero.
//  Dates are fixed, so the picture does not depend on the day the test runs.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Forms")
    struct Forms {
        @Test func formSection() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeader("Subscription", style: .list)
                    FormSection(header: "Payment", footer: "Charged on the 17th of every month") {
                        DatePickerRow(icon: "calendar", title: "Start date", selection: .constant(FormsSample.startDate))
                        MenuPickerRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Frequency",
                            selection: .constant("monthly"),
                            options: [(label: "Weekly", value: "weekly"), (label: "Monthly", value: "monthly")]
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// The rows Dalada's forms needed (3.0.0): a stepper, a switch and an action without icons.
        @Test func formRows3() async {
            await assertComponentSnapshot(
                FormSection(header: "Catch") {
                    StepperRow(icon: "fish", title: "Fish caught", value: .constant(3), in: 0...99)
                    StepperRow(title: "Spare hooks", value: .constant(12), in: 0...50) { "\($0) pcs" }
                    ToggleSettingsRow(title: "Released", isOn: .constant(true))
                    ActionSettingsRow(title: "Delete catch", isDestructive: true) {}
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// Fields that fill a FormSection row on their own (3.0.0): a name and a note.
        @Test func rowFields() async {
            await assertComponentSnapshot(
                FormSection(header: "Trip") {
                    FormTextField(text: .constant("Kapchagay weekend"), placeholder: "Name", style: .row)
                    Divider().padding(.leading, AppSpacing.lg)
                    FormTextField(text: .constant(""), placeholder: "Note", style: .rowMultiline(min: 2, max: 4))
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// A choice from a long list (3.0.0). A NavigationLink: drawn enabled only inside a
        /// NavigationStack, so the stack is here, its bar hidden, at a fixed height.
        @Test func navigationPickerRow() async {
            await assertComponentSnapshot(
                NavigationStack {
                    FormSection(header: "Catch") {
                        NavigationPickerRow(icon: "fish", title: "Species", selection: .constant("pike"),
                                            options: [(label: "Pike", value: "pike"), (label: "Perch", value: "perch")])
                        Divider().padding(.leading, AppSpacing.lg)
                        NavigationPickerRow(title: "Packing list", selection: .constant("winter"),
                                            options: [(label: "Winter fishing", value: "winter")])
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .toolbar(.hidden, for: .navigationBar)
                }
                .frame(height: 170),
                appearances: [.light, .dark]
            )
        }

        @Test func editableHero() async {
            await assertComponentSnapshot(
                EditableHero(
                    icon: .constant(.sfSymbol("creditcard.fill")),
                    title: .constant("Kaspi Gold"),
                    titlePlaceholder: "Account name",
                    amount: .constant("125000"),
                    currency: .constant("KZT"),
                    // No currency chip: it is a NavigationLink, dimmed outside a NavigationStack.
                    options: .init(showsAmount: true)
                )
                .frame(maxWidth: .infinity),
                appearances: [.light, .dark]
            )
        }

        @Test func heroSection() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.xl) {
                    HeroSection(
                        icon: .sfSymbol("fork.knife"),
                        title: "Food",
                        iconTint: .monochrome(.orange),
                        primaryAmount: 185_000,
                        primaryCurrency: "KZT",
                        subtitle: "This month",
                        progress: ProgressConfig(current: 185_000, total: 250_000, label: "Budget", color: .orange)
                    )
                    HeroSection(icon: .sfSymbol("tv.fill"), title: "Streaming", primaryText: "3 services")
                }
                .frame(maxWidth: .infinity)
                // The progress ring is wider than the icon and reaches above the hero's frame.
                .padding(.vertical, AppSpacing.md)
            )
        }
    }
}

private enum FormsSample {
    /// 17 June 2026, noon, in the simulator's time zone.
    static let startDate: Date = {
        let components = DateComponents(year: 2026, month: 6, day: 17, hour: 12)
        return Calendar(identifier: .gregorian).date(from: components) ?? Date(timeIntervalSince1970: 0)
    }()
}
