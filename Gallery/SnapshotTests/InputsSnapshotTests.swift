//
//  InputsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Pickers, chips, rating input, text fields, tags, the message composer, the calculator
//  keypad, amount text, action buttons. Nothing is focused.
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
                    SegmentedPicker(
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

        /// One composer per snapshot: three glass fields stacked in one picture settled in one of
        /// two layouts from run to run (October 2026), half a pixel apart.
        @Test func messageComposer() async {
            await assertComponentSnapshot(
                MessageComposer(text: .constant(""), placeholder: "Add a comment…") {},
                named: "empty"
            )
            await assertComponentSnapshot(
                MessageComposer(
                    text: .constant("Same here, thin ice up north"),
                    placeholder: "Reply…",
                    quote: MessageQuote(title: "Replying to Aida", text: "Was anyone on the lake this weekend?"),
                    errorMessage: "No connection. Try again.",
                    onCancelQuote: {}
                ) {},
                named: "reply",
                appearances: [.light, .dark, .largeText]
            )
            await assertComponentSnapshot(
                MessageComposer(text: .constant(""), placeholder: "Sign in to comment") {}
                    .disabled(true),
                named: "disabled"
            )
        }

        @Test func calculatorKeypad() async {
            await assertComponentSnapshot(
                CalculatorKeypad(model: CalculatorInputModel(seed: "1250"))
            )
        }

        @Test func currencyInputs() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    CurrencyPickerMenu(selection: .constant("KZT"), currencies: ["KZT", "USD"])
                    // The calculator's display (no cursor); the base currency, so no ≈ line.
                    CurrencyAmountInput(
                        amount: .constant("1250"),
                        currency: .constant("KZT"),
                        baseCurrency: "KZT",
                        currencies: ["KZT", "USD"],
                        errorMessage: "Not enough on the account",
                        calculatorModel: CalculatorInputModel(seed: "1250")
                    )
                }
                .frame(maxWidth: .infinity),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func amountText() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    AmountDigitDisplay(rawAmount: "1250.5")
                    // FormattedAmountView before 2.0: the same text in body semibold.
                    FormattedAmountText(amount: 1_234_567.89, currency: "KZT",
                                        fontSize: AppTypography.body, fontWeight: .semibold, color: AppColors.Text.primary)
                    FormattedAmountText(amount: 4_990, currency: "USD", prefix: "+",
                                        fontSize: AppTypography.body, fontWeight: .semibold, color: AppColors.income)
                    SpentBudgetText(spent: 185_000, budget: 250_000, currency: "KZT")
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func amountSignAndUnit() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    FormattedAmountText(amount: 5_000, currency: "KZT", fontSize: AppTypography.h4,
                                        color: AppColors.income, sign: .always)
                    FormattedAmountText(amount: -1_200.5, currency: "KZT", fontSize: AppTypography.h4, sign: .always)
                    FormattedAmountText(amount: -1_200.5, currency: "KZT", fontSize: AppTypography.h4, sign: .never)
                    FormattedAmountText(amount: 49.9, currency: "USD", fontSize: AppTypography.h4, currencyDisplay: .code)
                    FormattedAmountText(amount: 1_250, currency: "KZT", fontSize: AppTypography.h4,
                                        color: AppColors.warning, sign: .always,
                                        currencyDisplay: .systemImage("star.fill"))
                    FormattedAmountText(amount: 318_400, currency: "KZT", fontSize: AppTypography.h4,
                                        currencyDisplay: .numberOnly)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }

        @Test func hiddenAmounts() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    FormattedAmountText(amount: 1_284_500, currency: "KZT", fontSize: AppTypography.h1,
                                        fontWeight: .bold, color: AppColors.Text.primary)
                    FormattedAmountText(amount: -1_200.5, currency: "USD", fontSize: AppTypography.h4,
                                        sign: .always, currencyDisplay: .code)
                    SpentBudgetText(spent: 185_000, budget: 250_000, currency: "KZT")
                    HeroProportionBar(segments: [
                        DonutSlice(id: "food", amount: 42_000, color: AppColors.accent, label: "Food", percentage: 58),
                        DonutSlice(id: "rent", amount: 30_000, color: AppColors.success, label: "Rent", percentage: 42),
                    ], currency: "KZT")
                    AmountVisibilityToggle(isHidden: .constant(true))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .amountsHidden(),
                appearances: [.light, .largeText]
            )
        }

        @Test func actionButtons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    HStack(spacing: AppSpacing.xl) {
                        PlusTabLabel(isExpanded: false)
                        PlusTabLabel(isExpanded: true)
                    }
                    .font(AppTypography.bodyEmphasis)
                    // BulkDeleteButton and EntityActionButton before 2.0.
                    DSButton("Delete (3)", role: .destructive, shape: .capsule, fullWidth: true) {}
                    HStack(spacing: AppSpacing.sm) {
                        DSButton("Edit", systemImage: "pencil", iconPlacement: .top) {}
                        DSButton("Delete", systemImage: "trash", iconPlacement: .top, role: .destructive) {}
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }

        /// DSButton (2.0.0): the icon before, after, alone; the three appearances with a role;
        /// full width. No loading state: its spinner turns on a clock.
        @Test func dsButtons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.sm) {
                        DSButton("Save", systemImage: "checkmark", size: .medium) {}
                        DSButton("Next", systemImage: "arrow.right", iconPlacement: .trailing,
                                 appearance: .secondary, size: .medium) {}
                        DSButton("Close", systemImage: "xmark", iconPlacement: .only,
                                 appearance: .secondary, size: .medium) {}
                    }
                    HStack(spacing: AppSpacing.sm) {
                        DSButton("Delete", systemImage: "trash", role: .destructive, size: .small) {}
                        DSButton("Cancel", appearance: .flat, role: .neutral, size: .small) {}
                        DSButton("Disabled", size: .small, isDisabled: true) {}
                    }
                    DSButton("Start trip", fullWidth: true) {}
                    DSButton("Share", systemImage: "square.and.arrow.up", appearance: .secondary,
                             shape: .capsule, fullWidth: true) {}
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// One row of glass buttons per snapshot.
        @Test func dateButtons() async {
            await assertComponentSnapshot(
                DateButtons(selectedDate: .constant(Date()), onSave: { _ in }),
                named: "enabled",
                appearances: [.light, .dark, .largeText]
            )
            await assertComponentSnapshot(
                DateButtons(selectedDate: .constant(Date()), isDisabled: true, onSave: { _ in }),
                named: "disabled"
            )
        }

        @Test func animatedTitleInput() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.xl) {
                    AnimatedTitleInput(text: .constant(""), placeholder: "Account name")
                    AnimatedTitleInput(text: .constant("Kaspi Gold"), placeholder: "Account name")
                    AnimatedTitleInput(text: .constant("Savings"), placeholder: "Name",
                                       font: AppTypography.h3, alignment: .leading)
                }
                .frame(maxWidth: .infinity),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func amountPercentageView() async {
            await assertComponentSnapshot(
                AmountPercentage(amount: 42_000, currency: "KZT", percentage: 42)
                    .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .largeText]
            )
        }
    }
}
