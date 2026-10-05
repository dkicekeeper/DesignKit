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
            rowsSection
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
