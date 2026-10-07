//
//  AmountComparisonBar.swift
//  Tenra
//
//  Two amounts compared as a proportion bar with the values underneath
//  (e.g. expenses vs income on the home summary card). The bar itself is
//  a ProportionBar — this component only adds the amount labels.
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct AmountComparisonBar: View {
    let expenseAmount: Double
    let incomeAmount: Double
    let currency: String
    /// Sweep-from-zero entrance (see ProportionBar). Disable in lazy lists.
    var animatesOnAppear: Bool = true

    private var total: Double {
        expenseAmount + incomeAmount
    }

    private var expensePercent: Double {
        total > 0 ? max(0, min(1, expenseAmount / total)) : 0.0
    }

    public init(
        expenseAmount: Double,
        incomeAmount: Double,
        currency: String,
        animatesOnAppear: Bool = true
    ) {
        self.expenseAmount = expenseAmount
        self.incomeAmount = incomeAmount
        self.currency = currency
        self.animatesOnAppear = animatesOnAppear
    }

    public var body: some View {
        VStack(spacing: AppSpacing.sm) {
            if total > 0 {
                ProportionBar(
                    ratio: expensePercent,
                    leftColor: AppColors.destructive,
                    rightColor: AppColors.income,
                    height: AppSpacing.md,
                    animatesOnAppear: animatesOnAppear
                )
            } else {
                // No data yet — keep the slot height stable with a muted track.
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(AppColors.Background.neutral2)
                    .frame(height: AppSpacing.md)
            }

            // Amounts below the bar
            HStack {
                FormattedAmountText(
                    amount: expenseAmount,
                    currency: currency,
                    fontSize: AppTypography.h4,
                    fontWeight: .semibold,
                    color: AppColors.Text.primary
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

// MARK: - Skeleton

/// Placeholder of an `AmountComparisonBar`: the bar, then an amount under each end.
public struct AmountComparisonBarSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Skeleton(height: AppSpacing.md, cornerRadius: AppRadius.xl)
            HStack {
                SkeletonText(AppTypography.h4, width: 110)
                Spacer()
                SkeletonText(AppTypography.h4, width: 110)
            }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
