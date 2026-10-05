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
    @State private var paymentDate = Date()

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

            ShowcaseSection(title: "CalculatorKeypad", subtitle: "Drives a CalculatorAmountDisplay") {
                VStack(spacing: AppSpacing.md) {
                    CalculatorAmountDisplay(model: calc, baseFontSize: 44)
                        .frame(maxWidth: .infinity)
                    CalculatorKeypad(model: calc)
                }
                .cardContentPadding()
                .cardStyle()
            }

            ShowcaseSection(title: "OrbChart", subtitle: "Breakdown sphere for any [DonutSlice]") {
                OrbChart(slices: slices, size: 240)
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
            }

            ShowcaseSection(title: "MiniDonut", subtitle: "Compact ring for cards") {
                MiniDonut(slices: slices)
                    .frame(width: 80, height: 80)
            }

            ShowcaseSection(title: "MiniProportionBar", subtitle: "Compact stacked bar for cards") {
                MiniProportionBar(segments: slices)
                    .frame(maxWidth: .infinity)
            }

            ShowcaseSection(title: "HeroProportionBar", subtitle: "Stacked bar with a legend") {
                HeroProportionBar(segments: slices, currency: "KZT")
            }

            ShowcaseSection(title: "HeroHalfGauge", subtitle: "Half-gauge with a norm and zone ticks") {
                HeroHalfGauge(value: 0.62, norm: 0.5, maxValue: 1, zoneTicks: [0.3, 0.7], color: AppColors.success, diameter: 220)
                    .frame(maxWidth: .infinity)
            }

            ShowcaseSection(title: "MiniHalfGauge", subtitle: "Compact half-gauge for cards") {
                MiniHalfGauge(value: 0.62, norm: 0.5, maxValue: 1, color: AppColors.success)
            }

            ShowcaseSection(title: "HeroMilestoneGauge", subtitle: "Progress towards a target on a scale") {
                HeroMilestoneGauge(value: 4.2, target: 6, maxValue: 12, color: AppColors.accent)
            }

            ShowcaseSection(title: "MiniMilestoneGauge", subtitle: "Compact milestone gauge for cards") {
                MiniMilestoneGauge(value: 4.2, target: 6, maxValue: 12, color: AppColors.accent)
            }

            ShowcaseSection(title: "HeroBarPair", subtitle: "Previous vs current period") {
                HeroBarPair(previous: 320_000, current: 280_000, color: AppColors.accent, currency: "KZT")
                    .frame(maxWidth: .infinity)
            }

            ShowcaseSection(title: "MiniBarPair", subtitle: "Compact pair for cards · projection") {
                MiniBarPair(previous: 320_000, current: 280_000, color: AppColors.accent, isProjection: true)
            }

            ShowcaseSection(title: "UniversalFilterButton", subtitle: "A filter chip") {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(["week", "month"], id: \.self) { key in
                        UniversalFilterButton(title: key.capitalized, isSelected: filter == key, onTap: { filter = key })
                    }
                }
            }

            ShowcaseSection(title: "UniversalCarousel", subtitle: "The only horizontal scroller") {
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

            ShowcaseSection(title: "DateButtonsView", subtitle: "Yesterday · Today · a past date (no future dates)") {
                DateButtonsView(selectedDate: $paymentDate) { _ in }
                Text(paymentDate, format: .dateTime.day().month().year())
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

#Preview { NavigationStack { InputsScreen() } }
