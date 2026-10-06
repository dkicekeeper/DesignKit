//
//  MetricCard.swift
//  DesignKit
//
//  One metric in a feed: a title, a one-to-three-line statement, a large value with an
//  optional unit and trend badge, and an optional chart, either a 120 pt mini chart on the
//  trailing edge or a full-width chart under the text. Ported from Tenra's InsightsCardView;
//  the insight model and the choice of chart for each kind of insight stay in Tenra as an
//  adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// The large value of a `MetricCard` (`MetricCard.Value`).
///
/// Top-level, not nested in the generic card, so one value can feed cards with different
/// charts.
public enum MetricCardValue: Equatable, Sendable {
    /// An amount through `FormattedAmountText`.
    case amount(Double, currency: String)
    /// A pre-formatted value ("21", "3.4×").
    case text(String)
}

/// The trend badge after a `MetricCard`'s value (`MetricCard.Trend`; `TrendBadge`, `.pill`).
public struct MetricCardTrend {
    public let direction: TrendBadge.Direction
    public let changePercent: Double?
    public let color: Color?

    /// - Parameter color: Overrides the direction's colour (expenses, where up is bad).
    public init(direction: TrendBadge.Direction, changePercent: Double?, color: Color? = nil) {
        self.direction = direction
        self.changePercent = changePercent
        self.color = color
    }
}

/// Where a `MetricCard`'s chart goes (`MetricCard.ChartPlacement`).
public enum MetricCardChartPlacement: Hashable, Sendable {
    /// 120 × 120 pt on the trailing edge; the text keeps clear of it.
    case trailing
    /// Full width under the text.
    case bottom
}

/// "Top category / Food took 38% of spending / 185 000 ₸ ↗ +12.4%" with a `MiniDonut` on the
/// right.
///
/// ```swift
/// MetricCard(title: "Top category", subtitle: "Food took 38% of spending",
///            value: .amount(185_000, currency: "KZT"),
///            trend: .init(direction: .up, changePercent: 12.4, color: AppColors.destructive)) {
///     MiniDonut(slices: slices)
/// }
///
/// MetricCard(title: "Savings rate", subtitle: "You kept a fifth of your income",
///            value: .text("21"), unit: "%")
/// ```
public struct MetricCard<ChartContent: View>: View {
    public typealias Value = MetricCardValue
    public typealias Trend = MetricCardTrend
    public typealias ChartPlacement = MetricCardChartPlacement

    let title: String
    let subtitle: String
    let value: Value
    let unit: String?
    let trend: Trend?
    let chartPlacement: ChartPlacement
    let chart: ChartContent

    // Mini-chart footprint. The chart is overlaid (not a layout sibling) so it can bleed to
    // the card's trailing edge; the text column reserves matching room so titles, amounts and
    // badges never run underneath it. Keep these in sync.
    static var miniChartWidth: CGFloat { 120 }
    static var miniChartHeight: CGFloat { 120 }

    /// - Parameters:
    ///   - title: One line, secondary.
    ///   - subtitle: Up to three lines, emphasised.
    ///   - unit: After the value, secondary ("%", "days").
    ///   - trend: A badge after the value; it drops under the value when both do not fit.
    ///   - chartPlacement: `.trailing` (a mini chart) or `.bottom` (a full-size chart).
    public init(
        title: String,
        subtitle: String,
        value: Value,
        unit: String? = nil,
        trend: Trend? = nil,
        chartPlacement: ChartPlacement = .trailing,
        @ViewBuilder chart: () -> ChartContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.unit = unit
        self.trend = trend
        self.chartPlacement = chartPlacement
        self.chart = chart()
    }

    private var hasChart: Bool { ChartContent.self != EmptyView.self }
    private var hasBottomChart: Bool { hasChart && chartPlacement == .bottom }
    private var hasMiniChart: Bool { hasChart && chartPlacement == .trailing }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Text column. Reserves trailing room for the mini-chart overlay below so the
            // title and the value + badge row can't collide with it.
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(3)

                metricRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // Keep clear of the full-bleed mini chart; full width without one.
            .padding(.trailing, hasMiniChart ? Self.miniChartWidth + AppSpacing.sm : 0)

            if hasBottomChart {
                chart
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
        // Mini chart overlaid OUTSIDE the clip region so it can bleed to the trailing edge.
        .overlay(alignment: .trailing) {
            if hasMiniChart {
                chart
                    .frame(width: Self.miniChartWidth, height: Self.miniChartHeight)
                    .padding(.trailing, AppSpacing.lg)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Metric Row

    /// Value (+ optional unit) with the trend badge. Keeps both on one line when they fit the
    /// reserved width, otherwise drops the badge to a second line.
    @ViewBuilder
    private var metricRow: some View {
        if trend != nil {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AppSpacing.sm) {
                    valueWithUnit
                    trendBadge
                }
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    valueWithUnit
                    trendBadge
                }
            }
        } else {
            valueWithUnit
        }
    }

    private var valueWithUnit: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            switch value {
            case .amount(let amount, let currency):
                FormattedAmountText(
                    amount: amount,
                    currency: currency,
                    fontSize: AppTypography.h2,
                    fontWeight: .bold,
                    color: AppColors.textPrimary
                )
            case .text(let text):
                Text(text)
                    .font(AppTypography.h2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.textPrimary)
            }

            if let unit {
                Text(unit)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private var trendBadge: some View {
        if let trend {
            TrendBadge(
                direction: trend.direction,
                changePercent: trend.changePercent,
                style: .pill,
                color: trend.color
            )
        }
    }
}

public extension MetricCard where ChartContent == EmptyView {
    /// A card without a chart: the text takes the full width.
    init(
        title: String,
        subtitle: String,
        value: Value,
        unit: String? = nil,
        trend: Trend? = nil
    ) {
        self.init(title: title, subtitle: subtitle, value: value, unit: unit, trend: trend) {
            EmptyView()
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `MetricCard`: the same card, the title, subtitle and value, and the
/// chart's slot (a soft block) where the card has one.
public struct MetricCardSkeleton: View {
    /// Where the card's chart is; `nil` for a card without one.
    let chartPlacement: MetricCardChartPlacement?

    public init(chartPlacement: MetricCardChartPlacement? = .trailing) {
        self.chartPlacement = chartPlacement
    }

    private var miniChartWidth: CGFloat { MetricCard<EmptyView>.miniChartWidth }
    private var miniChartHeight: CGFloat { MetricCard<EmptyView>.miniChartHeight }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SkeletonText(AppTypography.body, width: 100)
                SkeletonText(AppTypography.bodyEmphasis, width: 180)
                SkeletonText(AppTypography.h2, width: 130)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, chartPlacement == .trailing ? miniChartWidth + AppSpacing.sm : 0)

            if chartPlacement == .bottom {
                SkeletonView(height: miniChartHeight)
            }
        }
        .shimmer()
        .padding(AppSpacing.lg)
        .cardStyle()
        .overlay(alignment: .trailing) {
            if chartPlacement == .trailing {
                SkeletonView(height: miniChartHeight * 0.6, width: miniChartWidth)
                    .padding(.trailing, AppSpacing.lg)
            }
        }
        .skeletonLoadingLabel()
    }
}
