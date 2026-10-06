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

        @Test func messageComposer() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    MessageComposer(text: .constant(""), placeholder: "Add a comment…") {}
                    MessageComposer(
                        text: .constant("Same here, the ice was thin near the north shore"),
                        placeholder: "Reply…",
                        quote: MessageQuote(title: "Replying to Aida", text: "Was anyone on the lake this weekend?"),
                        errorMessage: "No connection. Try again.",
                        onCancelQuote: {}
                    ) {}
                    MessageComposer(text: .constant(""), placeholder: "Sign in to comment") {}
                        .disabled(true)
                }
                .frame(maxWidth: .infinity),
                appearances: [.light, .dark, .largeText]
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
                    FormattedAmountView(amount: 1_234_567.89, currency: "KZT")
                    FormattedAmountView(amount: 4_990, currency: "USD", prefix: "+", color: AppColors.income)
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
                    BulkDeleteButton(count: 3) {}
                    HStack(spacing: AppSpacing.sm) {
                        EntityActionButton(title: "Edit", systemImage: "pencil") {}
                        EntityActionButton(title: "Delete", systemImage: "trash", role: .destructive) {}
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }
    }
}
