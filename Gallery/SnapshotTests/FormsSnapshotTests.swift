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
                    SettingsSectionHeaderView(title: "Subscription")
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
