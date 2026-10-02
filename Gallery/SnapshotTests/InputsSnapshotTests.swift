//
//  InputsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Pickers, chips, rating input, text fields, tags. Nothing is focused.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Inputs")
    struct Inputs {
        @Test func pickers() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    SegmentedPickerView(
                        title: "Period",
                        selection: .constant("month"),
                        options: [(label: "Week", value: "week"), (label: "Month", value: "month"), (label: "Year", value: "year")]
                    )
                    ChipPicker("Weather", options: ["Sunny", "Cloudy", "Rain"], selection: .constant(Optional("Cloudy"))) { $0 }
                    ChipPicker(
                        options: ["Lake", "River", "Camp"],
                        selection: .constant(Set(["Lake", "Camp"])),
                        systemImage: { _ in "drop" }
                    ) { $0 }
                    RatingPicker(rating: .constant(3))
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func textFieldsAndTags() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    FormTextField(text: .constant(""), placeholder: "Place name")
                    FormTextField(text: .constant("Big Almaty Lake"), placeholder: "Place name", helpText: "Shown on the map")
                    FormTextField(text: .constant("-5"), placeholder: "Amount", errorMessage: "Amount must be positive")
                    TagInput("Add a tag", tags: .constant(["Pike", "Early morning"]), suggestions: ["Perch", "Night"])
                }
            )
        }
    }
}
