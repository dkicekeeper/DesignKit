//
//  InputsScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens
import DesignComponents

struct InputsScreen: View {
    @State private var amount = "1250"
    @State private var title = ""
    @State private var segment = 0
    @State private var calc = CalculatorInputModel()

    private let slices: [DonutSlice] = [
        DonutSlice(id: "food", amount: 42_000, color: AppColors.accent, label: "Food", percentage: 42),
        DonutSlice(id: "rent", amount: 30_000, color: AppColors.success, label: "Rent", percentage: 30),
        DonutSlice(id: "fun", amount: 18_000, color: AppColors.warning, label: "Fun", percentage: 18),
        DonutSlice(id: "misc", amount: 10_000, color: AppColors.transfer, label: "Misc", percentage: 10),
    ]

    var body: some View {
        ShowcasePage(title: "Inputs & Charts") {
            ShowcaseSection(title: "AmountInput", subtitle: "Animated numeric entry (.numericText)") {
                AmountInput(amount: $amount, baseFontSize: 48)
                    .frame(maxWidth: .infinity)
                    .cardContentPadding()
                    .cardStyle()
            }

            ShowcaseSection(title: "AnimatedTitleInput") {
                AnimatedTitleInput(text: $title, placeholder: "Untitled")
                    .frame(maxWidth: .infinity)
                    .cardContentPadding()
                    .cardStyle()
            }

            ShowcaseSection(title: "SegmentedPickerView", subtitle: "Generic Liquid Glass segments") {
                SegmentedPickerView(title: "Type", selection: $segment, options: [
                    (label: "Expense", value: 0),
                    (label: "Income", value: 1),
                    (label: "Transfer", value: 2),
                ])
            }

            ShowcaseSection(title: "Calculator", subtitle: "CalculatorAmountDisplay + CalculatorKeypad") {
                VStack(spacing: AppSpacing.md) {
                    CalculatorAmountDisplay(model: calc, baseFontSize: 44)
                        .frame(maxWidth: .infinity)
                    CalculatorKeypad(model: calc)
                }
                .cardContentPadding()
                .cardStyle()
            }

            ShowcaseSection(title: "DonutChart / MiniDonut", subtitle: "Ring charts for any slice series") {
                HStack(spacing: AppSpacing.xl) {
                    DonutChart(slices: slices)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                    MiniDonut(slices: slices)
                        .frame(width: 72, height: 72)
                }
            }
        }
    }
}

#Preview { NavigationStack { InputsScreen() } }
