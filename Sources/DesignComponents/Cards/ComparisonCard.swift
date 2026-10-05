//
//  ComparisonCard.swift
//  DesignKit
//
//  Two amounts side by side, before and now, with the change between them in the middle.
//  Ported from Tenra's PeriodComparisonCard; its expense / income wording stays in Tenra as
//  an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "Jan 2026 95 000 ₸ ……… ↗ +26.3% ……… Feb 2026 120 000 ₸".
///
/// A change within ±`flatThreshold` percent reads as flat. With `increaseIsGood: false`
/// (spending, for example) a rise is drawn in the destructive colour and a fall in success.
/// At accessibility text sizes the three columns stack: before, now, then the change.
///
/// ```swift
/// ComparisonCard(previousLabel: "Jan 2026", previousAmount: 95_000,
///                currentLabel: "Feb 2026", currentAmount: 120_000,
///                currency: "KZT", increaseIsGood: false)
/// ```
public struct ComparisonCard: View {
    let previousLabel: String
    let previousAmount: Double
    let currentLabel: String
    let currentAmount: Double
    let currency: String
    let increaseIsGood: Bool
    let flatThreshold: Double

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - increaseIsGood: A rise is green when `true`, red when `false`.
    ///   - flatThreshold: The change, in percent, below which the arrow points sideways.
    public init(
        previousLabel: String,
        previousAmount: Double,
        currentLabel: String,
        currentAmount: Double,
        currency: String,
        increaseIsGood: Bool = true,
        flatThreshold: Double = 2
    ) {
        self.previousLabel = previousLabel
        self.previousAmount = previousAmount
        self.currentLabel = currentLabel
        self.currentAmount = currentAmount
        self.currency = currency
        self.increaseIsGood = increaseIsGood
        self.flatThreshold = flatThreshold
    }

    private var change: Double {
        guard previousAmount > 0 else { return 0 }
        return ((currentAmount - previousAmount) / previousAmount) * 100
    }

    private var direction: TrendBadge.Direction {
        change > flatThreshold ? .up : (change < -flatThreshold ? .down : .flat)
    }

    private var changeColor: Color {
        switch direction {
        case .up: return increaseIsGood ? AppColors.success : AppColors.destructive
        case .down: return increaseIsGood ? AppColors.destructive : AppColors.success
        case .flat: return AppColors.textSecondary
        }
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stackedLayout
            } else {
                rowLayout
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    /// Before | change | now, side by side.
    private var rowLayout: some View {
        HStack {
            // Previous period
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(previousLabel)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                FormattedAmountText(
                    amount: previousAmount,
                    currency: currency,
                    fontSize: AppTypography.h3,
                    fontWeight: .semibold,
                    color: AppColors.textSecondary
                )
            }

            Spacer()

            // Change indicator
            TrendBadge(
                direction: direction,
                changePercent: change,
                style: .changeIndicator,
                color: changeColor
            )

            Spacer()

            // Current period
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text(currentLabel)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                FormattedAmountText(
                    amount: currentAmount,
                    currency: currency,
                    fontSize: AppTypography.h3,
                    fontWeight: .bold,
                    color: AppColors.textPrimary
                )
            }
        }
    }

    /// Accessibility text sizes: the three columns do not fit side by side, so they stack.
    private var stackedLayout: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(previousLabel)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                FormattedAmountText(
                    amount: previousAmount,
                    currency: currency,
                    fontSize: AppTypography.h3,
                    fontWeight: .semibold,
                    color: AppColors.textSecondary
                )
            }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(currentLabel)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                FormattedAmountText(
                    amount: currentAmount,
                    currency: currency,
                    fontSize: AppTypography.h3,
                    fontWeight: .bold,
                    color: AppColors.textPrimary
                )
            }

            TrendBadge(
                direction: direction,
                changePercent: change,
                style: .inline,
                color: changeColor
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
