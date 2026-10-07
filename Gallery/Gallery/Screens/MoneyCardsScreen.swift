//
//  MoneyCardsScreen.swift
//  DesignKit Gallery
//
//  Cards about money: balances, home sections, totals, comparisons, recurring payments,
//  calculations.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct MoneyCardsScreen: View {
    var body: some View {
        ShowcasePage(title: "Cards: Money") {
            BalanceCardPage()
            SelectableBalanceCardPage()
            FinanceCardPage()
            CashFlowCardPage()
            TotalsCardPage()
            ComparisonCardPage()
            RecurringPaymentCardPage()
            CalculationCardPage()
            WeightBreakdownCardPage()
        }
    }
}

private struct BalanceCardPage: View {
    @State private var amount = 1_250_000.0
    @State private var hidden = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "BalanceCard",
            summary: "An account in a carousel: icon, name, balance on Liquid Glass.",
            since: "1.5.0",
            apps: [.tenra],
            notes: ["Tappable: wrap in a Button with .buttonStyle(.bounce)."]
        ) {
            if state == .loading {
                BalanceCardSkeleton()
            } else {
                BalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold",
                            amount: amount, currency: "KZT")
                    .amountsHidden(hidden)
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Balance", value: $amount, in: 0...5_000_000, step: 1_000)
            ToggleControl("Amounts hidden", isOn: $hidden)
        }
    }
}

private struct SelectableBalanceCardPage: View {
    @State private var selected = "gold"
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "SelectableBalanceCard",
            summary: "An account to pick, e.g. the source of a transfer; the picked one is outlined.",
            since: "1.5.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            HStack(spacing: AppSpacing.md) {
                if state == .loading {
                    SelectableBalanceCardSkeleton()
                    SelectableBalanceCardSkeleton()
                } else {
                    SelectableBalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold",
                                          amount: 1_250_000, currency: "KZT",
                                          isSelected: selected == "gold") { selected = "gold" }
                    SelectableBalanceCard(iconSource: .sfSymbol("banknote.fill"), title: "Cash",
                                          amount: 45_000, currency: "KZT",
                                          isSelected: selected == "cash") { selected = "cash" }
                }
            }
        } controls: {
            StateControl(state: $state)
        }
    }
}

private struct FinanceCardPage: View {
    @State private var state: SpecimenState = .content
    @State private var showsTrailing = true

    var body: some View {
        ComponentPage(
            name: "FinanceCard",
            summary: "A home-screen section: title, a hero amount, a subtitle and a trailing slot; an empty state of its own.",
            apps: [.tenra],
            canvas: .fill
        ) {
            switch state {
            case .loading:
                FinanceCardSkeleton(showsTrailing: showsTrailing)
            default:
                FinanceCard(title: "Accounts", isEmpty: state == .empty, emptyTitle: "No accounts",
                            subtitle: "3 accounts") {
                    RedactableAmount(amount: 1_884_500, currency: "KZT", isLoading: false)
                } trailing: {
                    if showsTrailing {
                        HStack(spacing: -AppSpacing.sm) {
                            ForEach(0..<3, id: \.self) { index in
                                Icon(source: .sfSymbol(["creditcard.fill", "banknote.fill", "wallet.bifold.fill"][index]),
                                         style: .circle(size: AppIconSize.xxl, tint: .monochrome(.white),
                                                        backgroundColor: [AppColors.accent, AppColors.success, AppColors.warning][index]))
                                    .overlay(Circle().strokeBorder(AppColors.bgBase, lineWidth: 2))
                            }
                        }
                    }
                }
            }
        } controls: {
            StateControl(state: $state, states: [.content, .loading, .empty])
            ToggleControl("Trailing", isOn: $showsTrailing)
        }
    }
}

private struct CashFlowCardPage: View {
    @State private var state: SpecimenState = .content
    @State private var showsExtra = true

    var body: some View {
        ComponentPage(
            name: "CashFlowCard",
            summary: "Income and expenses of a period with an extra line; loading and empty are cross-faded.",
            since: "1.2.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            CashFlowCard(
                title: "History",
                totals: state == .content
                    ? .init(income: 50_000, expenses: 35_000,
                            extra: showsExtra ? .init(label: "Planned", amount: 5_000) : nil)
                    : nil,
                currency: "KZT",
                isEmpty: state == .empty,
                emptyMessage: "No transactions yet"
            )
        } controls: {
            StateControl(state: $state, states: [.content, .loading, .empty])
            ToggleControl("Extra line", isOn: $showsExtra)
        }
    }
}

private struct TotalsCardPage: View {
    @State private var count = 3
    @State private var showsTitle = true
    @State private var showsChange = true
    @State private var state: SpecimenState = .content

    private var items: [TotalsCard.Item] {
        let all: [TotalsCard.Item] = [
            .init(title: "Income", amount: 530_000, previous: showsChange ? 480_000 : nil, color: AppColors.success),
            .init(title: "Expenses", amount: 320_000, previous: showsChange ? 350_000 : nil,
                  color: AppColors.destructive, increaseIsGood: false),
            .init(title: "Net", amount: 210_000, previous: showsChange ? 130_000 : nil),
        ]
        return Array(all.prefix(count))
    }

    var body: some View {
        ComponentPage(
            name: "TotalsCard",
            summary: "Totals side by side with change badges; stacks at large text sizes.",
            since: "1.1.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                TotalsCardSkeleton(count: count, showsTitle: showsTitle)
            } else {
                TotalsCard(items, currency: "KZT", title: showsTitle ? "May 2026" : nil)
            }
        } controls: {
            StateControl(state: $state)
            StepperControl("Totals", value: $count, in: 1...3)
            ToggleControl("Title", isOn: $showsTitle)
            ToggleControl("Change badges", isOn: $showsChange)
        }
    }
}

private struct ComparisonCardPage: View {
    @State private var current = 120_000.0
    @State private var increaseIsGood = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ComparisonCard",
            summary: "Before and now with the change; a rise is good or bad as you say.",
            since: "1.2.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                ComparisonCardSkeleton()
            } else {
                ComparisonCard(previousLabel: "Jan 2026", previousAmount: 95_000,
                               currentLabel: "Feb 2026", currentAmount: current,
                               currency: "KZT", increaseIsGood: increaseIsGood)
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Now (before: 95 000)", value: $current, in: 0...200_000, step: 1_000)
            ToggleControl("A rise is good", isOn: $increaseIsGood)
        }
    }
}

private struct RecurringPaymentCardPage: View {
    @State private var status: EntityStatus? = .active
    @State private var foreign = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "RecurringPaymentCard",
            summary: "A subscription or a bill: logo, name, amount (≈ in the base currency), next charge, status.",
            since: "1.2.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                RecurringPaymentCardSkeleton()
            } else {
                RecurringPaymentCard(iconSource: .brandService("Netflix"), title: "Netflix",
                                     amount: foreign ? 9.99 : 4_990, currency: foreign ? "USD" : "KZT",
                                     baseCurrency: foreign ? "KZT" : nil,
                                     caption: "Next charge on 12 Oct", status: status)
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Status", selection: $status, options: [
                ("None", nil), ("Active", .active), ("Paused", .paused), ("Pending", .pending),
            ])
            ToggleControl("Foreign currency", isOn: $foreign)
        }
    }
}

private struct CalculationCardPage: View {
    @State private var showsHero = true
    @State private var showsRecommendation = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "CalculationCard",
            summary: "How a figure is calculated: a hero value, the rows that make it, an explanation and advice.",
            since: "1.1.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                CalculationCardSkeleton(rows: 3, showsHero: showsHero)
            } else {
                CalculationCard(
                    systemImage: "banknote.fill",
                    color: AppColors.success,
                    title: "How it's calculated",
                    heroLabel: showsHero ? "Savings rate" : nil,
                    heroValue: showsHero ? "18.4%" : nil,
                    rows: [
                        .init(label: "Income", value: .amount(640_000, currency: "KZT")),
                        .init(label: "Expenses", value: .amount(522_240, currency: "KZT")),
                        .init(label: "Savings rate", value: .text("18.4%"), isEmphasised: true),
                    ],
                    explanation: "The share of income you did not spend this month.",
                    recommendation: showsRecommendation ? "Aim for 20% or more: set aside the difference on payday." : nil
                )
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Hero value", isOn: $showsHero)
            ToggleControl("Recommendation", isOn: $showsRecommendation)
        }
    }
}

private struct WeightBreakdownCardPage: View {
    @State private var segments = 4
    @State private var state: SpecimenState = .content

    private let all: [WeightBreakdownCard.Segment] = [
        .init(title: "Savings", systemImage: "banknote.fill", color: AppColors.success, weight: 40),
        .init(title: "Regular payments", systemImage: "repeat.circle", color: AppColors.accent, weight: 27),
        .init(title: "Safety cushion", systemImage: "shield.lefthalf.filled", color: AppColors.income, weight: 20),
        .init(title: "Cash flow", systemImage: "chart.line.uptrend.xyaxis", color: AppColors.destructive, weight: 13),
    ]

    var body: some View {
        ComponentPage(
            name: "WeightBreakdownCard",
            summary: "A whole split into weighted parts: a stacked bar and a row per part.",
            since: "1.1.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            if state == .loading {
                WeightBreakdownCardSkeleton(segments: segments)
            } else {
                WeightBreakdownCard(
                    title: "How the score works",
                    message: "Each part counts by how much it matters for the whole.",
                    caption: "Based on the last 3 months",
                    segments: Array(all.prefix(segments)),
                    footnote: "No budgets set, so their weight is shared among the other parts."
                )
            }
        } controls: {
            StateControl(state: $state)
            StepperControl("Parts", value: $segments, in: 1...4)
        }
    }
}

#Preview { NavigationStack { MoneyCardsScreen() } }
