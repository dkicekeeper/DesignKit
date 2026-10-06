//
//  BreakdownRow.swift
//  DesignKit
//
//  One part of a breakdown: a tinted icon, a name with an optional detail line, and the part's
//  amount over its share. Ported from Tenra's CategoryBreakdownRow (with AmountPercentageView);
//  the mapping from Tenra's breakdown item and its category names stays in Tenra as an adapter.
//
//  Navigation is left to the caller: wrap the row in a `NavigationLink` and pass
//  `showsChevron: true` so it shows the disclosure chevron.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Trailing "amount over percentage" stack of breakdown rows.
public struct AmountPercentageView: View {
    let amount: Double
    let currency: String
    let percentage: Double

    /// - Parameter percentage: 0…100, shown with one decimal ("42.0%").
    public init(amount: Double, currency: String, percentage: Double) {
        self.amount = amount
        self.currency = currency
        self.percentage = percentage
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: AppSpacing.xs) {
            FormattedAmountText(amount: amount, currency: currency, color: AppColors.textPrimary)
            Text(String(format: "%.1f%%", percentage))
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

/// "🍴 Food / Groceries, Cafés ……… 85 000 ₸ / 42.0%".
///
/// ```swift
/// BreakdownRow(iconSource: .sfSymbol("fork.knife"), color: AppColors.warning, title: "Food",
///              subtitle: "Groceries, Cafés", amount: 85_000, currency: "KZT", percentage: 42)
/// ```
public struct BreakdownRow: View {
    let iconSource: IconSource?
    let color: Color
    let title: String
    let subtitle: String?
    let amount: Double
    let currency: String
    let percentage: Double
    let showsChevron: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - color: Tints the icon and its circle.
    ///   - subtitle: One line under the title (the part's own parts, for example).
    ///   - percentage: The part's share, 0…100.
    ///   - showsChevron: Pass `true` when the row is wrapped in a `NavigationLink`.
    public init(
        iconSource: IconSource?,
        color: Color,
        title: String,
        subtitle: String? = nil,
        amount: Double,
        currency: String,
        percentage: Double,
        showsChevron: Bool = false
    ) {
        self.iconSource = iconSource
        self.color = color
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.currency = currency
        self.percentage = percentage
        self.showsChevron = showsChevron
    }

    public var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            stackedBody
        } else {
            rowBody
        }
    }

    private var leadingIcon: IconConfig {
        .custom(
            source: iconSource,
            style: .circle(
                size: AppIconSize.Tile.sm,
                tint: .monochrome(color),
                backgroundColor: AppColors.pale(color)
            )
        )
    }

    /// Accessibility text sizes: the amount and the share move under the title, which then
    /// has the row's full width.
    private var stackedBody: some View {
        UniversalRow(config: .info, leadingIcon: leadingIcon) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
                FormattedAmountText(amount: amount, currency: currency, color: AppColors.textPrimary)
                Text(String(format: "%.1f%%", percentage))
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        } trailing: {
            if showsChevron {
                DisclosureChevron()
            }
        }
    }

    private var rowBody: some View {
        // Built on UniversalRow(.info), the same base as InsightEntityRow: both breakdown rows
        // share the icon slot, spacing (md) and vertical padding (sm).
        UniversalRow(config: .info, leadingIcon: leadingIcon) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
        } trailing: {
            HStack(spacing: AppSpacing.md) {
                AmountPercentageView(amount: amount, currency: currency, percentage: percentage)
                if showsChevron {
                    DisclosureChevron()
                }
            }
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `BreakdownRow`: the round icon, the title and subtitle, and the amount with its
/// caption on the trailing edge; the amount goes under the title at accessibility text sizes,
/// like the row.
public struct BreakdownRowSkeleton: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init() {}

    public var body: some View {
        HStack(spacing: RowConfiguration.info.spacing) {
            IconViewSkeleton(size: AppIconSize.Tile.sm)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.body, width: 110)
                SkeletonText(AppTypography.bodySmall, width: 70)
                if dynamicTypeSize.isAccessibilitySize {
                    SkeletonText(AppTypography.body, width: 90)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if !dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    SkeletonText(AppTypography.body, width: 90)
                    SkeletonText(AppTypography.bodySmall, width: 40)
                }
            }
        }
        .shimmer()
        .padding(.vertical, RowConfiguration.info.verticalPadding)
        .skeletonLoadingLabel()
    }
}
