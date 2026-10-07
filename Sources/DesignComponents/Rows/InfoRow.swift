//
//  InfoRow.swift
//  Tenra
//
//  Reusable info row component (label: value)
//  Migrated to UniversalRow architecture - 2026-02-16
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Label + trailing-value layout for info rows.
///
/// Single line: the trailing value keeps its full intrinsic width (higher layout
/// priority), and the leading label truncates with an ellipsis when the two can't
/// both fit. This keeps money amounts intact and never breaks the value onto a
/// second line.
public struct InfoRowLayout<Value: View>: View {
    let label: String
    @ViewBuilder let value: () -> Value

    public init(
        label: String,
        @ViewBuilder value: @escaping () -> Value
    ) {
        self.label = label
        self.value = value
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text(label)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.Text.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: AppSpacing.sm)
            value()
                .layoutPriority(1)
        }
    }
}

/// Info row component for displaying label + value pairs
/// Now built on top of UniversalRow for consistency
public struct InfoRow: View {
    let icon: String?
    let label: String
    let value: String
    let amountDisplay: InfoRowAmount?

    public init(icon: String? = nil, label: String, value: String) {
        self.icon = icon
        self.label = label
        self.value = value
        self.amountDisplay = nil
    }

    /// Money variant: trailing renders via FormattedAmountText (smart decimal hiding +
    /// dimmed `.XX`). `value` is computed via `formatCurrencySmart` as accessibility fallback.
    public init(
        icon: String? = nil,
        label: String,
        amount: Double,
        currency: String,
        prefix: String = ""
    ) {
        self.icon = icon
        self.label = label
        self.value = prefix + Formatting.formatCurrencySmart(amount, currency: currency)
        self.amountDisplay = InfoRowAmount(amount: amount, currency: currency, prefix: prefix)
    }

    public var body: some View {
        UniversalRow(
            config: .info,
            leadingIcon: icon.map { .sfSymbol($0, color: AppColors.accent, size: AppIconSize.lg) }
        ) {
            InfoRowLayout(label: label) {
                if let display = amountDisplay {
                    FormattedAmountText(
                        amount: display.amount,
                        currency: display.currency,
                        prefix: display.prefix,
                        fontSize: AppTypography.bodyEmphasis,
                        fontWeight: .semibold,
                        color: AppColors.Text.primary
                    )
                } else {
                    Text(value)
                        .font(AppTypography.bodyEmphasis)
                        .multilineTextAlignment(.trailing)
                }
            }
        } trailing: {
            EmptyView()
        }
    }
}


// MARK: - Skeleton

/// Placeholder of an `InfoRow`: the label and the value, and the icon when the row has one.
public struct InfoRowSkeleton: View {
    let showsIcon: Bool

    public init(showsIcon: Bool = false) {
        self.showsIcon = showsIcon
    }

    public var body: some View {
        HStack(spacing: RowConfiguration.info.spacing) {
            if showsIcon {
                Skeleton.circle(AppIconSize.lg)
            }
            HStack(spacing: AppSpacing.md) {
                SkeletonText(AppTypography.body, width: 100)
                Spacer(minLength: AppSpacing.sm)
                SkeletonText(AppTypography.bodyEmphasis, width: 90)
            }
        }
        .shimmer()
        .padding(.vertical, RowConfiguration.info.verticalPadding)
        .skeletonLoadingLabel()
    }
}
