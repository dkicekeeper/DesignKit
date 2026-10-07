//
//  ScheduleRow.swift
//  DesignKit
//
//  One entry of a schedule (payments, instalments, sessions): a done / not-done mark, a title
//  and a date, an amount and an optional detail line. Entries not done yet are dimmed.
//  Like every row it owns its vertical padding (the `.info` preset's) and none horizontally:
//  the container insets it.
//  Ported from Tenra's AmortizationScheduleRow; the mapping from a loan's amortization entry
//  (number, date format, interest copy) stays in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A schedule entry: "✓ #3 · 12 Mar 2026 ……… 45 000 ₸ / int: 3 200 ₸".
///
/// ```swift
/// ScheduleRow(title: "#3", subtitle: "12 Mar 2026", amount: 45_000, currency: "KZT",
///             detail: "int: 3 200 ₸", isDone: true)
/// ```
public struct ScheduleRow: View {
    let title: String
    let subtitle: String
    let amount: Double
    let currency: String
    let detail: String?
    let detailColor: Color
    let isDone: Bool

    /// - Parameters:
    ///   - detail: A line under the amount (the interest part of a payment, for example).
    ///   - isDone: Checked mark when `true`; dimmed row with an empty circle otherwise.
    public init(
        title: String,
        subtitle: String,
        amount: Double,
        currency: String,
        detail: String? = nil,
        detailColor: Color = AppColors.expense,
        isDone: Bool
    ) {
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.currency = currency
        self.detail = detail
        self.detailColor = detailColor
        self.isDone = isDone
    }

    public var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: AppIconSize.lg))
                .foregroundStyle(isDone ? AppColors.income : AppColors.Text.secondary)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                Text(subtitle)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
            }

            Spacer(minLength: AppSpacing.sm)

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                FormattedAmountText(
                    amount: amount,
                    currency: currency,
                    fontSize: AppTypography.bodyEmphasis
                )
                if let detail {
                    Text(detail)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(detailColor)
                }
            }
        }
        .padding(.vertical, RowConfiguration.info.verticalPadding)
        .futureTransactionStyle(isFuture: !isDone)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Skeleton

/// Placeholder of a `ScheduleRow`: the status circle, the title and subtitle, the amount.
public struct ScheduleRowSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Skeleton.circle(AppIconSize.lg)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.bodyEmphasis, width: 120)
                SkeletonText(AppTypography.bodySmall, width: 90)
            }
            Spacer(minLength: AppSpacing.sm)
            SkeletonText(AppTypography.bodyEmphasis, width: 90)
        }
        .shimmer()
        .padding(.vertical, RowConfiguration.info.verticalPadding)
        .skeletonLoadingLabel()
    }
}
