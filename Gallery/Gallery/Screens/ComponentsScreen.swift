//
//  ComponentsScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct ComponentsScreen: View {
    @State private var cashFlowState = CashFlowSpecimenState.loaded
    @State private var hidesAmounts = true

    var body: some View {
        // Every ShowcaseSection is a page; the properties below group them by kind.
        ShowcasePage(title: "Components") {
            heroSection
            amountsSection
            cardsSection
            summaryCardsSection
            scoreCardsSection
            periodCardsSection
            paymentCardsSection
            rowsSection
            listRowsSection
            feedbackSection
            progressSection
        }
    }

    // MARK: Hero

    private var heroSection: some View {
        ShowcaseSection(title: "HeroSection", subtitle: "Entity-detail hero · icon entrance + progress ring") {
            HeroSection(
                icon: .sfSymbol("fork.knife"),
                title: "Food",
                iconTint: .monochrome(.orange),
                primaryAmount: 185_000,
                primaryCurrency: "KZT",
                subtitle: "This month",
                progress: ProgressConfig(current: 185_000, total: 250_000, label: "Budget", color: .orange)
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Amounts

    @ViewBuilder
    private var amountsSection: some View {
        ShowcaseSection(title: "FormattedAmountText", subtitle: "Smart decimals · dimmed .XX") {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                FormattedAmountText(amount: 1_284_500, currency: "KZT",
                                    fontSize: AppTypography.h2, fontWeight: .bold,
                                    color: AppColors.textPrimary)
                FormattedAmountText(amount: 49.90, currency: "USD",
                                    fontSize: AppTypography.h4, color: AppColors.income)
                FormattedAmountText(amount: -1200, currency: "EUR",
                                    prefix: "−", fontSize: AppTypography.h4,
                                    color: AppColors.destructive)
            }
            TokenLabel(name: "AmountDisplayPolicy.adaptive", value: "abbreviates only when it doesn't fit")
            HStack {
                Text("Balance").font(AppTypography.bodySmall).foregroundStyle(AppColors.textSecondary)
                Spacer()
                FormattedAmountText(amount: 148_920_450, currency: "KZT")
            }
            .frame(width: 150)
        }

        ShowcaseSection(title: "FormattedAmountView", subtitle: "Plain text, no dimmed decimals") {
            FormattedAmountView(amount: 4_990, currency: "USD", prefix: "+", color: AppColors.income)
        }

        ShowcaseSection(title: "ConvertedAmountView", subtitle: "≈ in another currency · DesignKitCurrencyConverter") {
            ConvertedAmountView(amount: 49.90, fromCurrency: "USD", toCurrency: "KZT",
                                fontSize: AppTypography.bodySmall, color: AppColors.textSecondary)
        }

        ShowcaseSection(title: "SpentBudgetText", subtitle: "Spent / budget") {
            SpentBudgetText(spent: 185_000, budget: 250_000, currency: "KZT")
        }

        ShowcaseSection(title: "Amount sign and unit", subtitle: "sign: .always / .never · currencyDisplay: code, symbol image, number only") {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                FormattedAmountText(amount: 5_000, currency: "KZT", fontSize: AppTypography.h4,
                                    color: AppColors.income, sign: .always)
                FormattedAmountText(amount: -1_200.5, currency: "KZT", fontSize: AppTypography.h4, sign: .always)
                FormattedAmountText(amount: -1_200.5, currency: "KZT", fontSize: AppTypography.h4, sign: .never)
                FormattedAmountText(amount: 49.9, currency: "USD", fontSize: AppTypography.h4, currencyDisplay: .code)
                FormattedAmountText(amount: 1_250, currency: "KZT", fontSize: AppTypography.h4,
                                    color: AppColors.warning, sign: .always, currencyDisplay: .systemImage("star.fill"))
                FormattedAmountText(amount: 318_400, currency: "KZT", fontSize: AppTypography.h4, currencyDisplay: .numberOnly)
            }
        }

        ShowcaseSection(title: "Hidden amounts", subtitle: ".amountsHidden() · AmountVisibilityToggle") {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    FormattedAmountText(amount: 1_284_500, currency: "KZT",
                                        fontSize: AppTypography.h1, fontWeight: .bold,
                                        color: AppColors.Text.primary)
                    AmountVisibilityToggle(isHidden: $hidesAmounts)
                }
                TotalsCard([
                    .init(title: "Income", amount: 530_000, previous: 480_000, color: AppColors.success),
                    .init(title: "Expenses", amount: 320_000, previous: 350_000, color: AppColors.destructive,
                          increaseIsGood: false),
                ], currency: "KZT")
                SpentBudgetText(spent: 185_000, budget: 250_000, currency: "KZT")
                HeroProportionBar(segments: [
                    DonutSlice(id: "food", amount: 42_000, color: AppColors.accent, label: "Food", percentage: 58),
                    DonutSlice(id: "rent", amount: 30_000, color: AppColors.success, label: "Rent", percentage: 42),
                ], currency: "KZT")
                Text(verbatim: "Own text: " + (hidesAmounts
                    ? Formatting.hiddenAmount(currency: "KZT")
                    : Formatting.formatCurrencySmart(48_000, currency: "KZT")))
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
            }
            .amountsHidden(hidesAmounts)
        }
    }

    // MARK: Cards

    @ViewBuilder
    private var cardsSection: some View {
        ShowcaseSection(title: "FinanceCard", subtitle: "Home-screen section shell · RedactableAmount") {
            FinanceCard(title: "Accounts", isEmpty: false, emptyTitle: "No accounts",
                        subtitle: "3 accounts") {
                RedactableAmount(amount: 1_884_500, currency: "KZT", isLoading: false)
            } trailing: {
                HStack(spacing: -AppSpacing.sm) {
                    ForEach(0..<3, id: \.self) { i in
                        IconView(source: .sfSymbol(["creditcard.fill", "banknote.fill", "wallet.bifold.fill"][i]),
                                 style: .circle(size: AppIconSize.avatar,
                                                tint: .monochrome(.white),
                                                backgroundColor: [AppColors.accent, AppColors.success, AppColors.warning][i]))
                            .overlay(Circle().strokeBorder(AppColors.bgBase, lineWidth: 2))
                    }
                }
            }
        }

        ShowcaseSection(title: "EmptyCardView", subtitle: "A home section with nothing in it yet") {
            EmptyCardView(sectionTitle: "Loans", emptyTitle: "No active loans")
        }

        ShowcaseSection(title: "InsightsStatCard", subtitle: "Total with a change badge and a footer slot") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                InsightsStatCard(title: "Income", amount: 640_000, currency: "KZT",
                                 color: AppColors.income, previous: 580_000, upIsGood: true)
                InsightsStatCard(title: "Expenses", amount: 921_300, currency: "KZT",
                                 color: AppColors.expense, previous: 870_000, upIsGood: false) {
                    // Trend footer slot (Tenra puts a MiniSparkline here).
                    ProportionBar(ratio: 0.7, leftColor: AppColors.destructive, rightColor: AppColors.bgMuted, height: 6)
                        .padding(.top, AppSpacing.xxs)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    // MARK: Summary cards (1.1.0, ported from Tenra)

    @ViewBuilder
    private var summaryCardsSection: some View {
        ShowcaseSection(title: "TotalsCard", subtitle: "Totals side by side with change badges") {
            TotalsCard([
                .init(title: "Income", amount: 530_000, previous: 480_000, color: AppColors.success),
                .init(title: "Expenses", amount: 320_000, previous: 350_000, color: AppColors.destructive,
                      increaseIsGood: false),
                .init(title: "Net", amount: 210_000, previous: 130_000),
            ], currency: "KZT", title: "May 2026")
        }

        ShowcaseSection(title: "LimitProgressCard", subtitle: "Progress towards a limit") {
            LimitProgressCard(iconSource: .sfSymbol("fork.knife"), title: "Food", color: .orange,
                              spent: 185_000, limit: 250_000, currency: "KZT", percentage: 74,
                              caption: "9 days left")
            LimitProgressCard(iconSource: .sfSymbol("bag.fill"), title: "Shopping", color: AppColors.accent,
                              spent: 132_000, limit: 100_000, currency: "KZT", percentage: 132)
        }

        ShowcaseSection(title: "WeightBreakdownCard", subtitle: "A whole split into weighted parts") {
            WeightBreakdownCard(
                title: "How the score works",
                message: "Each part counts by how much it matters for the whole.",
                caption: "Based on the last 3 months",
                segments: [
                    .init(title: "Savings", systemImage: "banknote.fill", color: AppColors.success, weight: 40),
                    .init(title: "Regular payments", systemImage: "repeat.circle", color: AppColors.accent, weight: 27),
                    .init(title: "Safety cushion", systemImage: "shield.lefthalf.filled", color: AppColors.income, weight: 20),
                    .init(title: "Cash flow", systemImage: "chart.line.uptrend.xyaxis", color: AppColors.destructive, weight: 13),
                ],
                footnote: "No budgets set, so their weight is shared among the other parts."
            )
        }

        ShowcaseSection(title: "CalculationCard", subtitle: "How a figure is calculated") {
            CalculationCard(
                systemImage: "banknote.fill",
                color: AppColors.success,
                title: "How it's calculated",
                heroLabel: "Savings rate",
                heroValue: "18.4%",
                rows: [
                    .init(label: "Income", value: .amount(640_000, currency: "KZT")),
                    .init(label: "Expenses", value: .amount(522_240, currency: "KZT")),
                    .init(label: "Savings rate", value: .text("18.4%"), isEmphasised: true),
                ],
                explanation: "The share of income you did not spend this month.",
                recommendation: "Aim for 20% or more: set aside the difference on payday."
            )
        }
    }

    // MARK: Score cards (1.2.0, ported from Tenra)

    @ViewBuilder
    private var scoreCardsSection: some View {
        ShowcaseSection(title: "ScoreGaugeCard", subtitle: "A score as a hero gauge · no data yet") {
            ScoreGaugeCard(score: 72, zoneTicks: [40, 70], grade: "Good",
                           color: AppColors.success, subtitle: "You're on track")
            ScoreGaugeCard(score: nil, zoneTicks: [40, 70], grade: "Not enough data",
                           color: AppColors.textSecondary, subtitle: "Add a month of income to see your score")
        }

        ShowcaseSection(title: "ScoreCard", subtitle: "A score in a feed, with a mini gauge") {
            ScoreCard(title: "Health score", grade: "Good", score: 72, color: AppColors.success)
            ScoreCard(title: "Health score", grade: "Needs attention", score: 34, color: AppColors.destructive)
        }

        ShowcaseSection(title: "TargetProgressCard", subtitle: "A metric against its target · muted") {
            TargetProgressCard(
                systemImage: "banknote.fill",
                color: AppColors.success,
                title: "Savings rate",
                badge: "Weight 30%",
                summary: "Score 50 of 100",
                currentLabel: "Current", currentValue: "10.0%",
                targetLabel: "Target", targetValue: "20% or more",
                progress: 0.5,
                explanation: "The share of income left after expenses.",
                recommendation: "Cut expenses by about 60 000 ₸ a month to reach 20%."
            )
            TargetProgressCard(
                systemImage: "gauge.with.dots.needle.33percent",
                color: AppColors.warning,
                title: "Budgets",
                badge: "Weight 25%",
                summary: "Score 0 of 100",
                currentLabel: "Current", currentValue: "—",
                targetLabel: "Target", targetValue: "Within budget",
                progress: 0,
                explanation: "How many categories stayed within their budget.",
                recommendation: "Set budgets on your categories to count this part.",
                isMuted: true
            )
        }
    }

    // MARK: Period cards (1.2.0, ported from Tenra)

    @ViewBuilder
    private var periodCardsSection: some View {
        ShowcaseSection(title: "ComparisonCard", subtitle: "Before and now · a rise is bad / good") {
            ComparisonCard(previousLabel: "Jan 2026", previousAmount: 95_000,
                           currentLabel: "Feb 2026", currentAmount: 120_000,
                           currency: "KZT", increaseIsGood: false)
            ComparisonCard(previousLabel: "Jan 2026", previousAmount: 530_000,
                           currentLabel: "Feb 2026", currentAmount: 620_000, currency: "KZT")
        }

        ShowcaseSection(title: "CashFlowCard", subtitle: "Loading / empty / loaded, cross-faded") {
            Picker("State", selection: $cashFlowState) {
                ForEach(CashFlowSpecimenState.allCases, id: \.self) { state in
                    Text(state.rawValue).tag(state)
                }
            }
            .pickerStyle(.segmented)

            CashFlowCard(
                title: "History",
                totals: cashFlowState == .loaded
                    ? .init(income: 50_000, expenses: 35_000, extra: .init(label: "Planned", amount: 5_000))
                    : nil,
                currency: "KZT",
                isEmpty: cashFlowState == .empty,
                emptyMessage: "No transactions yet"
            )
        }
    }

    // MARK: Payment cards (1.2.0, ported from Tenra)

    @ViewBuilder
    private var paymentCardsSection: some View {
        ShowcaseSection(title: "RecurringPaymentCard", subtitle: "A subscription or a bill · converted amount") {
            RecurringPaymentCard(iconSource: .brandService("Netflix"), title: "Netflix",
                                 amount: 9.99, currency: "USD", baseCurrency: "KZT",
                                 caption: "Next charge on 12 Oct", status: .active)
            RecurringPaymentCard(iconSource: .sfSymbol("dumbbell.fill"), title: "Gym",
                                 amount: 15_000, currency: "KZT", status: .paused)
        }

        ShowcaseSection(title: "PayoffProgressCard", subtitle: "Being paid off · repaid") {
            PayoffProgressCard(
                iconSource: .sfSymbol("car.fill"), title: "Car loan", subtitle: "Halyk Bank",
                remaining: 1_200_000, total: 3_000_000, currency: "KZT", progress: 0.6,
                phase: .inProgress(nextDate: "12 Nov 2026", remainingCaption: "18 left")
            ) {
                BadgeView("Credit", color: AppColors.expense)
            }
            PayoffProgressCard(
                iconSource: .sfSymbol("iphone"), title: "Phone", subtitle: "Kaspi",
                remaining: 0, total: 480_000, currency: "KZT", progress: 1,
                phase: .done(caption: "Closed 15 Jun 2026")
            ) {
                BadgeView("Paid off", color: AppColors.income)
            }
        }
    }

    // MARK: List rows (1.1.0, ported from Tenra)

    @ViewBuilder
    private var listRowsSection: some View {
        ShowcaseSection(title: "NetAmountRow", subtitle: "A period's net, with what came in and went out") {
            VStack(spacing: 0) {
                NetAmountRow(label: "May 2026", inflow: 530_000, outflow: 320_000, net: 210_000, currency: "KZT")
                Divider()
                NetAmountRow(label: "April 2026", inflow: 280_000, outflow: 340_000, net: -60_000, currency: "KZT")
                Divider()
                NetAmountRow(label: "March 2026", inflow: 0, outflow: 0, net: 0, currency: "KZT",
                             singleValue: 410_000, singleColor: AppColors.success)
            }
            .cardContentPadding()
            .cardStyle()
        }

        ShowcaseSection(title: "ScheduleRow", subtitle: "A schedule entry, done or upcoming") {
            VStack(spacing: AppSpacing.sm) {
                ScheduleRow(title: "#3", subtitle: "12 Mar 2026", amount: 45_000, currency: "KZT",
                            detail: "int: 3 200 ₸", isDone: true)
                ScheduleRow(title: "#4", subtitle: "12 Apr 2026", amount: 45_000, currency: "KZT",
                            detail: "int: 2 950 ₸", isDone: false)
            }
            .cardContentPadding()
            .cardStyle()
        }

        ShowcaseSection(title: "BreakdownRow", subtitle: "A part of a whole · AmountPercentageView") {
            VStack(spacing: 0) {
                BreakdownRow(iconSource: .sfSymbol("fork.knife"), color: AppColors.warning, title: "Food",
                             subtitle: "Groceries, Cafés", amount: 85_000, currency: "KZT", percentage: 42,
                             showsChevron: true)
                BreakdownRow(iconSource: .sfSymbol("car.fill"), color: AppColors.accent, title: "Transport",
                             amount: 38_000, currency: "KZT", percentage: 19)
            }
            .cardContentPadding()
            .cardStyle()
        }
    }

    // MARK: Rows

    @ViewBuilder
    private var rowsSection: some View {
        ShowcaseSection(title: "InfoRow", subtitle: "Label + value / amount") {
            VStack(spacing: 0) {
                InfoRow(icon: "calendar", label: "Date", value: "Jun 10, 2026")
                InfoRow(icon: "creditcard", label: "Paid", amount: 49.90, currency: "USD")
            }
            .cardContentPadding()
            .formCardStyle()
        }

        ShowcaseSection(title: "DisclosureChevron", subtitle: "Navigation chevron outside a List") {
            HStack {
                Text("Tap to open").font(AppTypography.body)
                Spacer()
                DisclosureChevron()
            }
            .padding(.vertical, AppSpacing.sm)
            .cardContentPadding()
            .formCardStyle()
        }

        ShowcaseSection(title: "DateSectionHeaderView", subtitle: "A day in a list, with its total") {
            DateSectionHeaderView(dateKey: "2026-09-30", amount: 45_000, currency: "KZT")
        }

        ShowcaseSection(title: "InsightEntityRow", subtitle: "Icon, title and subtitle, amount with a caption") {
            InsightEntityRow(iconSource: .sfSymbol("tv.fill"), title: "Streaming",
                             subtitle: "3 services", amount: 12_900, currency: "KZT",
                             amountCaption: "per month")
                .cardContentPadding()
                .cardStyle()
        }
    }

    // MARK: Feedback

    @ViewBuilder
    private var feedbackSection: some View {
        ShowcaseSection(title: "MessageBanner", subtitle: "Success · error · warning · info") {
            VStack(spacing: AppSpacing.sm) {
                MessageBanner.success("Saved successfully")
                MessageBanner.error("Failed to load")
                MessageBanner.warning("Low balance")
                MessageBanner.info("Sync completed")
            }
        }

        ShowcaseSection(title: "StatusBanner", subtitle: "A notice that stays · 5 statuses · compact · with an action") {
            VStack(spacing: AppSpacing.sm) {
                StatusBanner("Your statement for September is ready", status: .info) {}
                StatusBanner("Payment sent", status: .positive)
                StatusBanner("Card expires on 30 Nov", status: .warning)
                StatusBanner("Transfer failed: try again later", status: .negative) {}
                StatusBanner("Subscription paused", status: .neutral)
                StatusBanner("Synced a minute ago", status: .positive, style: .compact)
            }
        }

        ShowcaseSection(title: "StatusIndicatorBadge", subtitle: "Active · paused · archived · pending") {
            HStack(spacing: AppSpacing.lg) {
                StatusIndicatorBadge(status: .active)
                StatusIndicatorBadge(status: .paused)
                StatusIndicatorBadge(status: .archived)
                StatusIndicatorBadge(status: .pending)
            }
        }

        ShowcaseSection(title: "RecommendationBox", subtitle: "Advice at the bottom of a card") {
            RecommendationBox(text: "You spent 18% less on dining this month.",
                              color: AppColors.success)
        }

        ShowcaseSection(title: "InlineStatusText", subtitle: "Error · warning · success under a field") {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                InlineStatusText(message: "Amount must be greater than zero", type: .error)
                InlineStatusText(message: "Rate is older than 24h", type: .warning)
                InlineStatusText(message: "Synced just now", type: .success)
            }
        }

        ShowcaseSection(title: "EmptyStateView", subtitle: "Nothing to show yet") {
            EmptyStateView(icon: "tray", title: "Nothing here yet",
                           description: "Add your first transaction to get started.",
                           style: .standard)
                .frame(height: 240)
        }
    }

    // MARK: Progress

    @ViewBuilder
    private var progressSection: some View {
        ShowcaseSection(title: "LinearProgressBar", subtitle: "Within the limit · over it") {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                TokenLabel(name: "72%")
                LinearProgressBar(percentage: 72, isOverBudget: false, color: AppColors.accent)
                TokenLabel(name: "over budget", value: "140%")
                LinearProgressBar(percentage: 140, isOverBudget: true, color: AppColors.accent)
            }
        }

        ShowcaseSection(title: "ProportionBar", subtitle: "One share of two") {
            ProportionBar(ratio: 0.65, leftColor: AppColors.income, rightColor: AppColors.bgMuted)
        }

        ShowcaseSection(title: "ProgressRing", subtitle: "45% · 88% · over 100%") {
            HStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.xs) {
                    ProgressRing(progress: 0.45, size: AppIconSize.budgetRing, lineWidth: 5, showsTrack: true)
                    Text("45%").font(AppTypography.caption2).foregroundStyle(AppColors.textSecondary)
                }
                VStack(spacing: AppSpacing.xs) {
                    ProgressRing(progress: 0.88, size: AppIconSize.budgetRing, lineWidth: 5, showsTrack: true)
                    Text("88%").font(AppTypography.caption2).foregroundStyle(AppColors.textSecondary)
                }
                VStack(spacing: AppSpacing.xs) {
                    ProgressRing(progress: 1.15, size: AppIconSize.budgetRing, lineWidth: 5, isOverBudget: true, showsTrack: true)
                    Text("115%").font(AppTypography.caption2).foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }

        ShowcaseSection(title: "AmountComparisonBar", subtitle: "Expenses against income") {
            AmountComparisonBar(expenseAmount: 921_300, incomeAmount: 640_000, currency: "KZT")
        }
    }
}

#Preview { NavigationStack { ComponentsScreen() } }

/// The CashFlowCard specimen's state switch.
private enum CashFlowSpecimenState: String, CaseIterable {
    case loading = "Loading"
    case empty = "Empty"
    case loaded = "Loaded"
}
