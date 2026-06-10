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
            amountsSection
            cardsSection
            rowsSection
            feedbackSection
            progressSection
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
                                 color: AppColors.expense, previous: 870_000, upIsGood: false)
            }
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
        }
    }

    // MARK: Feedback

    private var feedbackSection: some View {
        ShowcaseSection(title: "Feedback") {
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
        ShowcaseSection(title: "Progress & Charts") {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                TokenLabel(name: "BudgetProgressBar", value: "72%")
                BudgetProgressBar(percentage: 72, isOverBudget: false, color: AppColors.accent)
                TokenLabel(name: "over budget", value: "140%")
                BudgetProgressBar(percentage: 140, isOverBudget: true, color: AppColors.accent)
                TokenLabel(name: "ProportionBar")
                ProportionBar(ratio: 0.65, leftColor: AppColors.income, rightColor: AppColors.bgMuted)
            }

            HStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.xs) {
                    BudgetProgressCircle(progress: 0.45, size: AppIconSize.budgetRing, lineWidth: 5)
                    Text("45%").font(AppTypography.caption2).foregroundStyle(AppColors.textSecondary)
                }
                VStack(spacing: AppSpacing.xs) {
                    BudgetProgressCircle(progress: 0.88, size: AppIconSize.budgetRing, lineWidth: 5)
                    Text("88%").font(AppTypography.caption2).foregroundStyle(AppColors.textSecondary)
                }
                VStack(spacing: AppSpacing.xs) {
                    BudgetProgressCircle(progress: 1.15, size: AppIconSize.budgetRing, lineWidth: 5, isOverBudget: true)
                    Text("115%").font(AppTypography.caption2).foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                TokenLabel(name: "ExpenseIncomeProgressBar")
                ExpenseIncomeProgressBar(expenseAmount: 921_300, incomeAmount: 640_000, currency: "KZT")
            }
        }
    }
}

#Preview { NavigationStack { ComponentsScreen() } }
