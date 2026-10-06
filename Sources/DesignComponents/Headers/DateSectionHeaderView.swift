//
//  DateSectionHeaderView.swift
//  Tenra
//
//  Specialized section header for date-grouped transaction lists
//  Shows date label + optional total amount for the day
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Date section header with optional amount display
/// Used in HistoryView and transaction lists grouped by date
public struct DateSectionHeaderView: View {
    let dateKey: String
    let amount: Double?
    let currency: String?

    public init(
        dateKey: String,
        amount: Double? = nil,
        currency: String? = nil
    ) {
        self.dateKey = dateKey
        self.amount = amount
        self.currency = currency
    }

    public var body: some View {
        HStack {
            SectionHeaderView(dateKey)

            Spacer()

            if let amount = amount, amount > 0, let currency = currency {
                FormattedAmountText(
                    amount: amount,
                    currency: currency,
                    prefix: "-",
                    fontSize: AppTypography.bodySmall,
                    fontWeight: .semibold,
                    color: .gray
                )
            }
        }
        .textCase(nil)
        .padding(AppSpacing.lg)
        .cardStyle()
    }
}

// MARK: - Previews

// MARK: - Skeleton

/// Placeholder of a `DateSectionHeaderView`: the same card, the date and the day's total.
public struct DateSectionHeaderViewSkeleton: View {
    public init() {}

    public var body: some View {
        HStack {
            SkeletonText(AppTypography.bodyEmphasis, width: 100)
            Spacer()
            SkeletonText(AppTypography.bodySmall, width: 80)
        }
        .shimmer()
        .padding(AppSpacing.lg)
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
