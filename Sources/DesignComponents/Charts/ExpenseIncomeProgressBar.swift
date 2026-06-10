//
//  ExpenseIncomeProgressBar.swift
//  Tenra
//
//  Progress bar component showing expense and income amounts
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct ExpenseIncomeProgressBar: View {
    let expenseAmount: Double
    let incomeAmount: Double
    let currency: String

    public init(expenseAmount: Double, incomeAmount: Double, currency: String) {
        self.expenseAmount = expenseAmount
        self.incomeAmount = incomeAmount
        self.currency = currency
    }

    @State private var displayExpensePercent: Double = 0
    @State private var displayIncomePercent: Double = 0

    private var total: Double {
        expenseAmount + incomeAmount
    }

    private var expensePercent: Double {
        total > 0 ? max(0, min(1, expenseAmount / total)) : 0.0
    }

    private var incomePercent: Double {
        total > 0 ? max(0, min(1, incomeAmount / total)) : 0.0
    }

    private static let barAnimation = AppAnimation.progressBarSpring

    public var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Progress bar
            GeometryReader { geometry in
                HStack(spacing: AppSpacing.xs) {
                    // Always render both bars; animated width drives show/hide naturally.
                    if expensePercent > 0 || displayExpensePercent > 0 {
                        Rectangle()
                            .foregroundStyle(AppColors.destructive)
                            .frame(width: geometry.size.width * displayExpensePercent)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                    if incomePercent > 0 || displayIncomePercent > 0 {
                        Rectangle()
                            .foregroundStyle(AppColors.income)
                            .frame(width: geometry.size.width * displayIncomePercent)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                }
                .clipped()
            }
            .frame(height: AppSpacing.md)
            .onAppear {
                withAnimation(Self.barAnimation) {
                    displayExpensePercent = expensePercent
                    displayIncomePercent = incomePercent
                }
            }
            .onChange(of: expensePercent) { _, newValue in
                withAnimation(Self.barAnimation) {
                    displayExpensePercent = newValue
                }
            }
            .onChange(of: incomePercent) { _, newValue in
                withAnimation(Self.barAnimation) {
                    displayIncomePercent = newValue
                }
            }
            
            // Amounts below progress bar
            HStack {
                FormattedAmountText(
                    amount: expenseAmount,
                    currency: currency,
                    fontSize: AppTypography.h4,
                    fontWeight: .semibold,
                    color: AppColors.textPrimary
                )

                Spacer()

                FormattedAmountText(
                    amount: incomeAmount,
                    currency: currency,
                    fontSize: AppTypography.h4,
                    fontWeight: .semibold,
                    color: AppColors.income
                )
            }
        }
    }
}

