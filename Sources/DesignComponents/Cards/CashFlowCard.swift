//
//  CashFlowCard.swift
//  DesignKit
//
//  Money in against money out for a period: a title, the expense / income comparison bar and
//  an optional extra line, with empty and loading states that cross-fade. Ported from Tenra's
//  TransactionsSummaryCard; the mapping from Tenra's summary model stays in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "History" over an `AmountComparisonBar`, an optional "Planned 5 000 ₸" line under it.
/// `isEmpty` shows `EmptyCardView`; `totals == nil` (and not empty) shows a skeleton.
///
/// ```swift
/// CashFlowCard(
///     title: "History",
///     totals: .init(income: 50_000, expenses: 35_000, extra: .init(label: "Planned", amount: 5_000)),
///     currency: "KZT",
///     emptyMessage: "No transactions yet"
/// )
/// ```
public struct CashFlowCard: View {
    public struct Totals: Equatable {
        public let income: Double
        public let expenses: Double
        /// A line under the bar; `nil` hides it.
        public let extra: Line?

        public init(income: Double, expenses: Double, extra: Line? = nil) {
            self.income = income
            self.expenses = expenses
            self.extra = extra
        }
    }

    /// "Planned ……… 5 000 ₸".
    public struct Line: Equatable {
        public let label: String
        public let amount: Double

        public init(label: String, amount: Double) {
            self.label = label
            self.amount = amount
        }
    }

    let title: String
    let totals: Totals?
    let currency: String
    let isEmpty: Bool
    let emptyMessage: String
    let loadingLabel: String

    /// - Parameters:
    ///   - totals: `nil` while loading.
    ///   - isEmpty: Shows `EmptyCardView` with `title` and `emptyMessage` instead of the totals.
    ///   - loadingLabel: What VoiceOver reads for the skeleton.
    public init(
        title: String,
        totals: Totals?,
        currency: String,
        isEmpty: Bool = false,
        emptyMessage: String,
        loadingLabel: String = String(localized: "skeleton.loading", defaultValue: "Loading")
    ) {
        self.title = title
        self.totals = totals
        self.currency = currency
        self.isEmpty = isEmpty
        self.emptyMessage = emptyMessage
        self.loadingLabel = loadingLabel
    }

    public var body: some View {
        // ZStack + .transition(.opacity) + .animation fade between loading, loaded and empty
        // instead of replacing the view abruptly.
        ZStack {
            if isEmpty {
                EmptyCardView(
                    sectionTitle: title,
                    emptyTitle: emptyMessage
                )
                .transition(.opacity)
            } else if let totals {
                // No .id(…) here: it would recreate the card on every change and break the
                // number transitions.
                loadedState(totals: totals)
                    .transition(.opacity)
            } else {
                loadingState
                    .transition(.opacity)
            }
        }
        .animation(AppAnimation.gentleSpring, value: isEmpty)
        .animation(AppAnimation.gentleSpring, value: totals != nil)
    }

    // MARK: - Loaded State

    private func loadedState(totals: Totals) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text(title)
                    .font(AppTypography.h3)
                    .foregroundStyle(AppColors.Text.primary)
                Spacer()
            }

            AmountComparisonBar(
                expenseAmount: totals.expenses,
                incomeAmount: totals.income,
                currency: currency
            )

            if let extra = totals.extra {
                HStack {
                    Text(extra.label)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.primary)
                    Spacer()
                    FormattedAmountText(
                        amount: extra.amount,
                        currency: currency,
                        fontSize: AppTypography.body,
                        color: AppColors.Text.primary
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    // MARK: - Loading State

    private var loadingState: some View {
        CashFlowCardSkeleton(loadingLabel: loadingLabel)
    }
}

// MARK: - Skeleton

/// Placeholder of a `CashFlowCard`, and its own loading state: the same card, the title,
/// then the comparison bar with an amount under each end.
public struct CashFlowCardSkeleton: View {
    let loadingLabel: String

    /// - Parameter loadingLabel: What VoiceOver reads (key `skeleton.loading`, "Loading").
    public init(loadingLabel: String = String(localized: "skeleton.loading", defaultValue: "Loading")) {
        self.loadingLabel = loadingLabel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            SkeletonText(AppTypography.h3, width: 120)
            AmountComparisonBarSkeleton()
        }
        .shimmer()
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(loadingLabel)
    }
}
