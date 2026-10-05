//
//  ComponentsScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct ComponentsScreen: View {
    var body: some View {
        ShowcasePage(title: "Components") {
            heroSection
            amountsSection
            cardsSection
            summaryCardsSection
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
            TokenLabel(name: "FormattedAmountView", value: "plain text, no dimmed decimals")
            FormattedAmountView(amount: 4_990, currency: "USD", prefix: "+", color: AppColors.income)
            TokenLabel(name: "ConvertedAmountView", value: "≈ in another currency · DesignKitCurrencyConverter")
            ConvertedAmountView(amount: 49.90, fromCurrency: "USD", toCurrency: "KZT",
                                fontSize: AppTypography.bodySmall, color: AppColors.textSecondary)
            TokenLabel(name: "SpentBudgetText", value: "spent / budget")
            SpentBudgetText(spent: 185_000, budget: 250_000, currency: "KZT")
        }
    }

    // MARK: Cards

    private var cardsSection: some View {
        ShowcaseSection(title: "FinanceCard", subtitle: "Home-screen section shell") {
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

            EmptyCardView(sectionTitle: "Loans", emptyTitle: "No active loans")

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

    private var summaryCardsSection: some View {
        ShowcaseSection(title: "Summary cards", subtitle: "TotalsCard · LimitProgressCard · WeightBreakdownCard · CalculationCard") {
            TotalsCard([
                .init(title: "Income", amount: 530_000, previous: 480_000, color: AppColors.success),
                .init(title: "Expenses", amount: 320_000, previous: 350_000, color: AppColors.destructive,
                      increaseIsGood: false),
                .init(title: "Net", amount: 210_000, previous: 130_000),
            ], currency: "KZT", title: "May 2026")

            LimitProgressCard(iconSource: .sfSymbol("fork.knife"), title: "Food", color: .orange,
                              spent: 185_000, limit: 250_000, currency: "KZT", percentage: 74,
                              caption: "9 days left")
            LimitProgressCard(iconSource: .sfSymbol("bag.fill"), title: "Shopping", color: AppColors.accent,
                              spent: 132_000, limit: 100_000, currency: "KZT", percentage: 132)

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

    // MARK: List rows (1.1.0, ported from Tenra)

    private var listRowsSection: some View {
        ShowcaseSection(title: "NetAmountRow · ScheduleRow", subtitle: "Period totals · schedule entries") {
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

            VStack(spacing: AppSpacing.md) {
                ScheduleRow(title: "#3", subtitle: "12 Mar 2026", amount: 45_000, currency: "KZT",
                            detail: "int: 3 200 ₸", isDone: true)
                ScheduleRow(title: "#4", subtitle: "12 Apr 2026", amount: 45_000, currency: "KZT",
                            detail: "int: 2 950 ₸", isDone: false)
            }
            .cardContentPadding()
            .cardStyle()
        }
    }

    // MARK: Rows

    private var rowsSection: some View {
        ShowcaseSection(title: "InfoRow", subtitle: "Label + value / amount") {
            VStack(spacing: 0) {
                InfoRow(icon: "calendar", label: "Date", value: "Jun 10, 2026")
                InfoRow(icon: "creditcard", label: "Paid", amount: 49.90, currency: "USD")
                HStack {
                    Text("Tap to open").font(AppTypography.body)
                    Spacer()
                    DisclosureChevron()
                }
                .padding(.vertical, AppSpacing.sm)
            }
            .cardContentPadding()
            .formCardStyle()

            DateSectionHeaderView(dateKey: "2026-09-30", amount: 45_000, currency: "KZT")

            VStack(spacing: 0) {
                InsightEntityRow(iconSource: .sfSymbol("tv.fill"), title: "Streaming",
                                 subtitle: "3 services", amount: 12_900, currency: "KZT",
                                 amountCaption: "per month")
                HStack(spacing: AppSpacing.md) {
                    SelectionIndicator(isSelected: true)
                    Text("Selected row").font(AppTypography.body)
                    Spacer()
                }
                .padding(.vertical, AppSpacing.sm)
                HStack(spacing: AppSpacing.md) {
                    SelectionIndicator(isSelected: false)
                    Text("Not selected").font(AppTypography.body)
                    Spacer()
                }
                .padding(.vertical, AppSpacing.sm)
            }
            .cardContentPadding()
            .cardStyle()
        }
    }

    // MARK: Feedback

    private var feedbackSection: some View {
        ShowcaseSection(title: "Feedback") {
            VStack(spacing: AppSpacing.sm) {
                MessageBanner.success("Saved successfully")
                MessageBanner.error("Failed to load")
                MessageBanner.warning("Low balance")
                MessageBanner.info("Sync completed")
            }
            HStack(spacing: AppSpacing.lg) {
                StatusIndicatorBadge(status: .active)
                StatusIndicatorBadge(status: .paused)
                StatusIndicatorBadge(status: .archived)
                StatusIndicatorBadge(status: .pending)
            }
            RecommendationBox(text: "You spent 18% less on dining this month.",
                              color: AppColors.success)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                InlineStatusText(message: "Amount must be greater than zero", type: .error)
                InlineStatusText(message: "Rate is older than 24h", type: .warning)
                InlineStatusText(message: "Synced just now", type: .success)
            }
            EmptyStateView(icon: "tray", title: "Nothing here yet",
                           description: "Add your first transaction to get started.",
                           style: .standard)
                .frame(height: 240)
        }
    }

    // MARK: Progress

    private var progressSection: some View {
        ShowcaseSection(title: "Progress", subtitle: "LinearProgressBar · ProgressRing · AmountComparisonBar · ProportionBar") {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                TokenLabel(name: "LinearProgressBar", value: "72%")
                LinearProgressBar(percentage: 72, isOverBudget: false, color: AppColors.accent)
                TokenLabel(name: "over budget", value: "140%")
                LinearProgressBar(percentage: 140, isOverBudget: true, color: AppColors.accent)
                TokenLabel(name: "ProportionBar")
                ProportionBar(ratio: 0.65, leftColor: AppColors.income, rightColor: AppColors.bgMuted)
            }

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

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                TokenLabel(name: "AmountComparisonBar")
                AmountComparisonBar(expenseAmount: 921_300, incomeAmount: 640_000, currency: "KZT")
            }
        }
    }
}

#Preview { NavigationStack { ComponentsScreen() } }
