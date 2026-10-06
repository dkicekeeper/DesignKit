//
//  ProgressRingRow.swift
//  DesignKit
//
//  A row whose icon wears a progress ring: the name, then "spent / limit (74%)", or a
//  placeholder line when there is no limit. Ported from Tenra's CategoryRow; its category
//  model, the tap, the swipe-to-delete and the over-budget haptic stay in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "(🍴) Food / 185 000 / 250 000 ₸ (74%)", the ring around the icon at 74%.
///
/// At accessibility text sizes "spent / limit (74%)" does not fit beside the ring: the spent
/// amount, "/ limit" and the share go on three lines.
///
/// A `List` row: it has no padding of its own, the list's row insets place it. Make it
/// tappable with a `Button` (`.buttonStyle(.plain)`, `.contentShape(Rectangle())`) and add
/// `.swipeActions` at the call site.
///
/// ```swift
/// ProgressRingRow(iconSource: .sfSymbol("fork.knife"), color: .orange, title: "Food",
///                 progress: LimitProgress(spent: 185_000, limit: 250_000), currency: "KZT")
/// ProgressRingRow(iconSource: .sfSymbol("car.fill"), color: .blue, title: "Transport",
///                 progress: nil, currency: "KZT", placeholder: "No budget set")
/// ```
public struct ProgressRingRow: View {
    let iconSource: IconSource?
    let color: Color
    let title: String
    let progress: LimitProgress?
    let currency: String
    let placeholder: String?
    let transitionSourceID: String?
    let transitionNamespace: Namespace.ID?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - color: Tints the icon and its circle.
    ///   - progress: Draws the ring and the "spent / limit (N%)" line, in the destructive
    ///     colour when over the limit; `nil` shows `placeholder` instead.
    ///   - placeholder: The line under the title when there is no limit; `nil` shows nothing.
    ///   - transitionSourceID: With `transitionNamespace`, makes the icon (with its ring) the
    ///     source of a `.navigationTransition(.zoom(sourceID:in:))`.
    public init(
        iconSource: IconSource?,
        color: Color,
        title: String,
        progress: LimitProgress?,
        currency: String,
        placeholder: String? = nil,
        transitionSourceID: String? = nil,
        transitionNamespace: Namespace.ID? = nil
    ) {
        self.iconSource = iconSource
        self.color = color
        self.title = title
        self.progress = progress
        self.currency = currency
        self.placeholder = placeholder
        self.transitionSourceID = transitionSourceID
        self.transitionNamespace = transitionNamespace
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon with the limit's progress ring
            ZStack {
                if let progress {
                    ProgressRing(
                        progress: progress.percentage / 100,
                        size: AppIconSize.categoryIcon,
                        lineWidth: 3,
                        isOverBudget: progress.isOverLimit,
                        animatesOnAppear: false // list row — onAppear re-fires on scroll
                    )
                }

                IconView(
                    source: iconSource,
                    style: .circle(
                        size: AppIconSize.xxl,
                        tint: .monochrome(color),
                        backgroundColor: AppColors.pale(color)
                    )
                )
            }
            .matchedTransitionSourceIfPresent(
                id: transitionSourceID,
                namespace: transitionNamespace
            )

            // Name and the limit
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.h4)

                if let progress {
                    limitLine(progress)
                } else if let placeholder {
                    Text(placeholder)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func limitLine(_ progress: LimitProgress) -> some View {
        let amountColor = progress.isOverLimit ? AppColors.destructive : AppColors.textSecondary
        if dynamicTypeSize.isAccessibilitySize {
            // Accessibility text sizes: on one line both amounts were cut to "185… / 250…".
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                FormattedAmountText(
                    amount: progress.spent,
                    currency: currency,
                    fontSize: AppTypography.bodySmall,
                    fontWeight: .semibold,
                    color: amountColor
                )
                HStack(spacing: 0) {
                    Text(verbatim: "/ ")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(amountColor)
                    FormattedAmountText(
                        amount: progress.limit,
                        currency: currency,
                        fontSize: AppTypography.bodySmall,
                        fontWeight: .semibold,
                        color: amountColor
                    )
                }
                percentageText(progress)
            }
        } else {
            HStack(spacing: AppSpacing.xs) {
                SpentBudgetText(
                    spent: progress.spent,
                    budget: progress.limit,
                    currency: currency,
                    fontWeight: .semibold,
                    amountColor: amountColor,
                    separatorColor: amountColor
                )

                percentageText(progress)
            }
        }
    }

    private func percentageText(_ progress: LimitProgress) -> some View {
        Text(verbatim: "(\(Int(progress.percentage))%)")
            .font(AppTypography.bodySmall)
            .foregroundStyle(AppColors.textSecondary)
    }
}

// MARK: - Skeleton

/// Placeholder of a `ProgressRingRow`: the ring's track around the round icon, the title
/// and the limit line.
public struct ProgressRingRowSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .stroke(SkeletonView.fill, lineWidth: 3)
                    .frame(width: AppIconSize.categoryIcon, height: AppIconSize.categoryIcon)
                IconViewSkeleton(size: AppIconSize.xxl)
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.h4, width: 120)
                SkeletonText(AppTypography.bodySmall, width: 150)
            }
            Spacer(minLength: 0)
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
