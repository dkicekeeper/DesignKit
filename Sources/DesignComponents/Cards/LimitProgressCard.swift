//
//  LimitProgressCard.swift
//  DesignKit
//
//  Progress towards a limit: icon, name and percentage, a progress bar, "spent / limit" and a
//  caption. Ported from Tenra's BudgetProgressRow; the mapping from Tenra's budget item (and
//  its "days left" copy) stays in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A card that tracks a value against a limit (a budget, a quota, a plan).
///
/// ```swift
/// LimitProgressCard(
///     iconSource: .sfSymbol("fork.knife"),
///     title: "Food",
///     color: .orange,
///     spent: 185_000,
///     limit: 250_000,
///     currency: "KZT",
///     percentage: 74,
///     caption: "9 days left"
/// )
/// ```
public struct LimitProgressCard: View {
    let iconSource: IconSource?
    let title: String
    let color: Color
    let spent: Double
    let limit: Double
    let currency: String
    let percentage: Double
    let isOverLimit: Bool
    let caption: String?

    /// - Parameters:
    ///   - percentage: `spent` as a share of `limit`, 0…100+ (not clamped).
    ///   - isOverLimit: Draws the percentage and the overshoot of the bar in the destructive
    ///     colour; `percentage > 100` when not given.
    ///   - caption: Trailing text under the bar ("9 days left"); `nil` hides it.
    public init(
        iconSource: IconSource?,
        title: String,
        color: Color,
        spent: Double,
        limit: Double,
        currency: String,
        percentage: Double,
        isOverLimit: Bool? = nil,
        caption: String? = nil
    ) {
        self.iconSource = iconSource
        self.title = title
        self.color = color
        self.spent = spent
        self.limit = limit
        self.currency = currency
        self.percentage = percentage
        self.isOverLimit = isOverLimit ?? (percentage > 100)
        self.caption = caption
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                IconView(
                    source: iconSource,
                    style: .circle(
                        size: AppIconSize.xxl,
                        tint: .monochrome(color),
                        backgroundColor: AppColors.pale(color)
                    )
                )
                Text(title)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text(String(format: "%.0f%%", percentage))
                    .font(AppTypography.body)
                    .foregroundStyle(isOverLimit ? AppColors.destructive : AppColors.textPrimary)
            }

            LinearProgressBar(
                percentage: percentage,
                isOverBudget: isOverLimit,
                color: color
            )

            HStack {
                SpentBudgetText(
                    spent: spent,
                    budget: limit,
                    currency: currency,
                    font: AppTypography.caption,
                    separatorColor: AppColors.textTertiary
                )
                Spacer()
                if let caption {
                    Text(caption)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle(radius: AppRadius.xl)
    }
}
