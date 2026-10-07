//
//  NetAmountRow.swift
//  DesignKit
//
//  A labelled net amount with what came in and went out beneath it, or a single amount.
//  Like every row it owns its vertical padding (the `.info` preset's) and none horizontally.
//  Ported from Tenra's PeriodBreakdownRow; Tenra's period metrics (which value a list shows
//  for a period) stay in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "May 2026 ……… 210 000 ₸" with "+530 000 ₸ −320 000 ₸" under the amount, or one amount
/// when `singleValue` is set.
///
/// ```swift
/// NetAmountRow(label: "May 2026", inflow: 530_000, outflow: 320_000, net: 210_000, currency: "KZT")
/// NetAmountRow(label: "June 2026", inflow: 0, outflow: 0, net: 0, currency: "KZT",
///              singleValue: 410_000, singleColor: AppColors.success)
/// ```
public struct NetAmountRow: View {
    let label: String
    let inflow: Double
    let outflow: Double
    let net: Double
    let currency: String
    let singleValue: Double?
    let singleColor: Color

    /// - Parameters:
    ///   - net: The headline amount; destructive when negative.
    ///   - singleValue: Shows this amount instead of the net, with no inflow / outflow line.
    ///   - singleColor: Colour of `singleValue`.
    public init(
        label: String,
        inflow: Double,
        outflow: Double,
        net: Double,
        currency: String,
        singleValue: Double? = nil,
        singleColor: Color = AppColors.Text.primary
    ) {
        self.label = label
        self.inflow = inflow
        self.outflow = outflow
        self.net = net
        self.currency = currency
        self.singleValue = singleValue
        self.singleColor = singleColor
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(label)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.primary)

                    Spacer()

                    if let singleValue {
                        FormattedAmountText(
                            amount: singleValue,
                            currency: currency,
                            fontSize: AppTypography.body,
                            fontWeight: .semibold,
                            color: singleColor
                        )
                    } else {
                        FormattedAmountText(
                            amount: net,
                            currency: currency,
                            fontSize: AppTypography.body,
                            fontWeight: .semibold,
                            color: net >= 0 ? AppColors.Text.primary : AppColors.destructive
                        )
                    }
                }

                if singleValue == nil {
                    HStack(spacing: AppSpacing.md) {
                        FormattedAmountText(
                            amount: inflow,
                            currency: currency,
                            prefix: "+",
                            fontSize: AppTypography.bodySmall,
                            fontWeight: .regular,
                            color: AppColors.success
                        )
                        FormattedAmountText(
                            amount: outflow,
                            currency: currency,
                            prefix: "-",
                            fontSize: AppTypography.bodySmall,
                            fontWeight: .regular,
                            color: AppColors.destructive
                        )
                    }
                }
            }
            .padding(.vertical, RowConfiguration.info.verticalPadding)
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `NetAmountRow`: the label and the net amount, then the in and out flows.
public struct NetAmountRowSkeleton: View {
    let showsFlows: Bool

    /// - Parameter showsFlows: The "+in −out" line (a row with a single value has none).
    public init(showsFlows: Bool = true) {
        self.showsFlows = showsFlows
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: AppSpacing.xs) {
            HStack {
                SkeletonText(AppTypography.body, width: 110)
                Spacer()
                SkeletonText(AppTypography.body, width: 90)
            }
            if showsFlows {
                HStack(spacing: AppSpacing.md) {
                    SkeletonText(AppTypography.bodySmall, width: 70)
                    SkeletonText(AppTypography.bodySmall, width: 70)
                }
            }
        }
        .shimmer()
        .padding(.vertical, RowConfiguration.info.verticalPadding)
        .skeletonLoadingLabel()
    }
}
