//
//  ChartSelectionBanner.swift
//  DesignKit
//
//  Card above a chart showing the selected point: a title and one or more coloured values.
//  Ported from Tenra (its `.dual(income:expenses:)` / `.single(value:color:)` modes are
//  two or one `Entry`). The title's first letter is capitalised: Russian `MMMM`
//  formatters return lowercase month names.
//
//  8.2.0: an entry can carry its series' name (with several series the banner is the
//  chart's legend), the title a note ("so far" for a period that is not over), and the
//  values roll from one to the next.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Selection banner of `LineChart`, `BarChart` and `HeroSparkline`; usable on its own.
///
/// ```swift
/// ChartSelectionBanner(title: "январь 2025", entries: [
///     .init(value: 480_000, color: AppColors.success, label: "Income"),
///     .init(value: 275_000, color: AppColors.destructive, label: "Expenses"),
/// ], format: .currency("KZT"))
/// ```
public struct ChartSelectionBanner: View {
    public struct Entry {
        public let value: Double
        public let color: Color
        /// A colour dot before the value (or its label); on by default, off for a lone value.
        public let showsDot: Bool
        /// The series' name over its value (8.2.0). With several series it is the legend.
        public let label: String?

        public init(value: Double, color: Color, showsDot: Bool = true, label: String? = nil) {
            self.value = value
            self.color = color
            self.showsDot = showsDot
            self.label = label
        }
    }

    let title: String
    let note: String?
    let entries: [Entry]
    let format: ChartValueFormat

    /// - Parameters:
    ///   - title: the period ("January 2026"); its first letter is capitalised.
    ///   - note: a word after the title in the secondary colour ("so far", 8.2.0).
    ///   - entries: one value per series.
    ///   - format: how the values read.
    public init(title: String, note: String? = nil, entries: [Entry], format: ChartValueFormat = .compact) {
        self.title = title
        self.note = note
        self.entries = entries
        self.format = format
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                Text(Self.capitalizedFirstLetter(title))
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                if let note {
                    Text(note)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                }
            }
            .lineLimit(1)

            HStack(alignment: .top, spacing: AppSpacing.lg) {
                ForEach(entries.indices, id: \.self) { i in
                    entryView(entries[i])
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func entryView(_ entry: Entry) -> some View {
        if let label = entry.label {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xs) {
                    if entry.showsDot { dot(entry.color) }
                    Text(label)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Text.secondary)
                        .lineLimit(1)
                }
                valueText(entry)
            }
        } else {
            HStack(spacing: AppSpacing.xs) {
                if entry.showsDot { dot(entry.color) }
                valueText(entry)
            }
        }
    }

    private func dot(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }

    @ViewBuilder
    private func valueText(_ entry: Entry) -> some View {
        switch format {
        case .currency(let code) where !code.isEmpty:
            FormattedAmountText(
                amount: entry.value,
                currency: code,
                fontSize: AppTypography.body,
                fontWeight: .regular,
                color: entry.color
            )
            .lineLimit(1)
        case .custom(let text):
            Text(verbatim: text(entry.value))
                .font(AppTypography.numbers(AppTypography.body))
                .foregroundStyle(entry.color)
                .lineLimit(1)
                .contentTransition(.numericText(value: entry.value))
        default:
            Text(verbatim: ChartValueFormat.compactString(entry.value))
                .font(AppTypography.numbers(AppTypography.body))
                .foregroundStyle(entry.color)
                .lineLimit(1)
                .contentTransition(.numericText(value: entry.value))
        }
    }

    static func capitalizedFirstLetter(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}

// MARK: - Skeleton

/// Placeholder of a `ChartSelectionBanner` (8.2.0): its glass card with a grey title and a grey
/// value. `values: 2` for a chart of two series, whose banner names each.
public struct ChartSelectionBannerSkeleton: View {
    let values: Int

    public init(values: Int = 1) {
        self.values = max(1, values)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SkeletonText(AppTypography.bodyEmphasis, width: 140)
            HStack(alignment: .top, spacing: AppSpacing.lg) {
                ForEach(0..<values, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 2) {
                        if values > 1 {
                            SkeletonText(AppTypography.caption, width: 60)
                        }
                        SkeletonText(AppTypography.body, width: 96)
                    }
                }
            }
        }
        .shimmer()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
