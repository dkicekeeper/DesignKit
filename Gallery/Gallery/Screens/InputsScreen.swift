//
//  InputsScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct InputsScreen: View {
    @State private var pickedCurrency = "KZT"
    @State private var enteredAmount = "1250"
    @State private var pickedIcon: IconSource? = .sfSymbol("cart.fill")
    @State private var showsIconPicker = false
    @State private var amount = "1250"
    @State private var title = ""
    @State private var segment = 0
    @State private var calc = CalculatorInputModel()
    @State private var zoom: CGFloat = 1
    @State private var colorHex = "#6366f1"
    @State private var filter = "month"
    @State private var paymentDate = Date()
    @State private var message = ""
    @State private var replyText = "Same here, the ice was thin"
    @State private var replyQuote: MessageQuote? = MessageQuote(
        title: "Replying to Aida", text: "Was anyone on the lake this weekend?"
    )
    @State private var isSendingMessage = false

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

            ShowcaseSection(title: "CurrencyPickerMenu", subtitle: "The currency chip: a menu of currencies · Customize…") {
                CurrencyPickerMenu(selection: $pickedCurrency, currencies: ["KZT", "USD", "EUR", "RUB"]) {}
            }

            ShowcaseSection(title: "CurrencyAmountInput", subtitle: "Amount, ≈ base currency, currency chip, error") {
                CurrencyAmountInput(amount: $enteredAmount, currency: $pickedCurrency, baseCurrency: "KZT",
                                    currencies: ["KZT", "USD", "EUR"],
                                    errorMessage: enteredAmount.isEmpty ? "Enter an amount" : nil)
            }

            ShowcaseSection(title: "CurrencyList", subtitle: "Popular, then all · search · pushed from a chip") {
                NavigationLink {
                    CurrencyList(selection: pickedCurrency) { pickedCurrency = $0 }
                        .navigationTitle("Currency")
                } label: {
                    Text("Currency: \(pickedCurrency)").filterChipStyle()
                }
                .buttonStyle(.plain)
            }

            ShowcaseSection(title: "IconPicker", subtitle: "SF Symbols by group · logos from DesignKitLogoCatalog") {
                Button {
                    showsIconPicker = true
                } label: {
                    IconView(source: pickedIcon, style: .glassHero(size: AppIconSize.mega))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showsIconPicker) {
                    IconPicker(selection: $pickedIcon)
                }
            }

            ShowcaseSection(title: ".carouselItemTransition()", subtitle: "Cards dim and shrink as they scroll off") {
                UniversalCarousel(config: .cards) {
                    ForEach(["Kaspi Gold", "Halyk", "Freedom", "Jusan"], id: \.self) { name in
                        BalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: name,
                                    amount: 120_000, currency: "KZT")
                            .carouselItemTransition()
                    }
                }
            }

            ShowcaseSection(title: "MessageComposer", subtitle: "Glass field · send inside · quote · error · disabled") {
                VStack(spacing: AppSpacing.lg) {
                    MessageComposer(text: $message, placeholder: "Add a comment…", isSending: isSendingMessage) {
                        isSendingMessage = true
                        Task {
                            try? await Task.sleep(for: .seconds(1))
                            message = ""
                            isSendingMessage = false
                        }
                    }
                    MessageComposer(
                        text: $replyText,
                        placeholder: "Reply…",
                        quote: replyQuote,
                        errorMessage: "No connection. Try again.",
                        onCancelQuote: { replyQuote = nil }
                    ) {}
                    MessageComposer(text: .constant(""), placeholder: "Sign in to comment") {}
                        .disabled(true)
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
