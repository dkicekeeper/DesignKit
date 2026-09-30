//
//  InputsScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct InputsScreen: View {
    @State private var amount = "1250"
    @State private var title = ""
    @State private var segment = 0
    @State private var calc = CalculatorInputModel()
    @State private var zoom: CGFloat = 1
    @State private var colorHex = "#6366f1"
    @State private var filter = "month"

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

            ShowcaseSection(title: "OrbChart / MiniDonut", subtitle: "Breakdown sphere + compact ring for any [DonutSlice]") {
                OrbChart(slices: slices, size: 240)
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
                HStack(spacing: AppSpacing.xl) {
                    MiniDonut(slices: slices)
                        .frame(width: 80, height: 80)
                    MiniProportionBar(segments: slices)
                        .frame(maxWidth: .infinity)
                }
                HeroProportionBar(segments: slices, currency: "KZT")
            }

            ShowcaseSection(title: "Gauges", subtitle: "Hero / Mini half-gauge and milestone gauge") {
                HeroHalfGauge(value: 0.62, norm: 0.5, maxValue: 1, zoneTicks: [0.3, 0.7], color: AppColors.success, diameter: 220)
                    .frame(maxWidth: .infinity)
                HeroMilestoneGauge(value: 4.2, target: 6, maxValue: 12, color: AppColors.accent)
                HStack(spacing: AppSpacing.lg) {
                    MiniHalfGauge(value: 0.62, norm: 0.5, maxValue: 1, color: AppColors.success)
                    MiniMilestoneGauge(value: 4.2, target: 6, maxValue: 12, color: AppColors.accent)
                }
            }

            ShowcaseSection(title: "Bar pairs", subtitle: "Previous vs current period") {
                HeroBarPair(previous: 320_000, current: 280_000, color: AppColors.accent, currency: "KZT")
                    .frame(maxWidth: .infinity)
                MiniBarPair(previous: 320_000, current: 280_000, color: AppColors.accent, isProjection: true)
            }

            ShowcaseSection(title: "UniversalCarousel + UniversalFilterButton", subtitle: "The only horizontal scroller · filter chips") {
                UniversalCarousel(config: .filter) {
                    ForEach(["week", "month", "year", "all"], id: \.self) { key in
                        UniversalFilterButton(title: key.capitalized, isSelected: filter == key, onTap: { filter = key })
                    }
                }
            }

            ShowcaseSection(title: "ChartZoomControls", subtitle: "Glass +/− zoom") {
                ChartZoomControls(zoomScale: $zoom, range: 1...4)
                Text("zoom \(zoom, specifier: "%.1f")×").font(AppTypography.caption).foregroundStyle(AppColors.textSecondary)
            }

            ShowcaseSection(title: "ColorPickerRow") {
                ColorPickerRow(selectedColorHex: $colorHex, title: "Color")
                    .cardContentPadding()
                    .formCardStyle()
            }
        }
    }
}

#Preview { NavigationStack { InputsScreen() } }
