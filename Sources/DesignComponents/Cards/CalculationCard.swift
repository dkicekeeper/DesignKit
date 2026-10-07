//
//  CalculationCard.swift
//  DesignKit
//
//  "How it's calculated": a headline value, the rows it is computed from (the result row
//  emphasised), an explanation and a recommendation. Ported from Tenra's InsightFormulaCard;
//  Tenra's formula model, its localization keys and value formats stay in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A card that shows how a figure was computed.
///
/// ```swift
/// CalculationCard(
///     systemImage: "banknote.fill",
///     color: AppColors.success,
///     title: "How it's calculated",
///     heroLabel: "Savings rate",
///     heroValue: "18.4%",
///     rows: [
///         .init(label: "Income", value: .amount(640_000, currency: "KZT")),
///         .init(label: "Expenses", value: .amount(522_000, currency: "KZT")),
///         .init(label: "Savings rate", value: .text("18.4%"), isEmphasised: true),
///     ],
///     explanation: "The share of income you did not spend.",
///     recommendation: "Aim for 20% or more."
/// )
/// ```
public struct CalculationCard: View {
    public struct Row: Identifiable {
        public enum Value {
            /// A money amount, drawn by `FormattedAmountText`.
            case amount(Double, currency: String)
            /// Any other value, already formatted ("1.8 months", "12.4%").
            case text(String)
        }

        public let id: String
        public let label: String
        public let value: Value
        /// The result row: bold, in the card's colour.
        public let isEmphasised: Bool

        public init(id: String? = nil, label: String, value: Value, isEmphasised: Bool = false) {
            self.id = id ?? label
            self.label = label
            self.value = value
            self.isEmphasised = isEmphasised
        }
    }

    let systemImage: String
    let color: Color
    let title: String
    let heroLabel: String?
    let heroValue: String?
    let rows: [Row]
    let explanation: String?
    let recommendation: String?

    /// - Parameters:
    ///   - heroLabel: Label of the headline value; the headline shows when `heroValue` is set.
    ///   - heroValue: The headline value, already formatted. `nil` hides it, for a screen that
    ///     shows the figure above the card.
    public init(
        systemImage: String,
        color: Color,
        title: String,
        heroLabel: String? = nil,
        heroValue: String? = nil,
        rows: [Row],
        explanation: String? = nil,
        recommendation: String? = nil
    ) {
        self.systemImage = systemImage
        self.color = color
        self.title = title
        self.heroLabel = heroLabel
        self.heroValue = heroValue
        self.rows = rows
        self.explanation = explanation
        self.recommendation = recommendation
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            headerRow
            if let heroValue {
                heroRow(value: heroValue)
            }
            rowsSection
            if let explanation {
                Text(explanation)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let recommendation {
                RecommendationBox(text: recommendation, color: color)
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    private var headerRow: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: AppIconSize.md))
                .foregroundStyle(color)
                .frame(width: 28)

            Text(title)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(AppColors.Text.primary)

            Spacer()
        }
    }

    private func heroRow(value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(heroLabel ?? "")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.Text.secondary)
            Text(value)
                .font(AppTypography.h1.bold())
                .foregroundStyle(AppColors.Text.primary)
        }
        .padding(.vertical, AppSpacing.md)
    }

    private var rowsSection: some View {
        VStack(spacing: AppSpacing.xs) {
            ForEach(rows) { row in
                rowView(row)
                if row.id != rows.last?.id {
                    Divider().opacity(0.4)
                }
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: Row) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(row.label)
                .font(row.isEmphasised ? AppTypography.bodyEmphasis : AppTypography.body)
                .foregroundStyle(row.isEmphasised ? AppColors.Text.primary : AppColors.Text.secondary)
            Spacer()
            switch row.value {
            case .amount(let amount, let currency):
                FormattedAmountText(
                    amount: amount,
                    currency: currency,
                    fontSize: row.isEmphasised ? AppTypography.bodyEmphasis : AppTypography.body,
                    fontWeight: row.isEmphasised ? .bold : .semibold,
                    color: row.isEmphasised ? color : AppColors.Text.primary
                )
            case .text(let text):
                Text(text)
                    .font(row.isEmphasised ? AppTypography.bodyEmphasis : AppTypography.body)
                    .fontWeight(row.isEmphasised ? .bold : .semibold)
                    .foregroundStyle(row.isEmphasised ? color : AppColors.Text.primary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Skeleton

/// Placeholder of a `CalculationCard`: the same card, the header, the hero value and `rows`
/// label/value lines.
public struct CalculationCardSkeleton: View {
    let rows: Int
    let showsHero: Bool

    public init(rows: Int = 3, showsHero: Bool = true) {
        self.rows = max(0, rows)
        self.showsHero = showsHero
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack(spacing: AppSpacing.md) {
                Skeleton.circle(AppIconSize.md)
                    .frame(width: 28)
                SkeletonText(AppTypography.bodyEmphasis, width: 140)
                Spacer()
            }
            if showsHero {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    SkeletonText(AppTypography.body, width: 100)
                    SkeletonText(AppTypography.h1, width: 160)
                }
                .padding(.vertical, AppSpacing.md)
            }
            VStack(spacing: AppSpacing.xs) {
                ForEach(0..<rows, id: \.self) { _ in
                    HStack {
                        SkeletonText(AppTypography.body, width: 110)
                        Spacer()
                        SkeletonText(AppTypography.body, width: 80)
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
            }
        }
        .shimmer()
        .padding(AppSpacing.lg)
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
