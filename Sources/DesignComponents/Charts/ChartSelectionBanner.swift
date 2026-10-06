//
//  ChartSelectionBanner.swift
//  DesignKit
//
//  Card above a chart showing the tapped point: a title and one or more coloured values.
//  Ported from Tenra (its `.dual(income:expenses:)` / `.single(value:color:)` modes are
//  two or one `Entry`). The title's first letter is capitalised: Russian `MMMM`
//  formatters return lowercase month names.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Selection banner of `LineChart`, `BarChart` and `HeroSparkline`; usable on its own.
///
/// ```swift
/// ChartSelectionBanner(title: "январь 2025", entries: [
///     .init(value: 480_000, color: AppColors.success),
///     .init(value: 275_000, color: AppColors.destructive),
/// ], format: .currency("KZT"))
/// ```
public struct ChartSelectionBanner: View {
    public struct Entry {
        public let value: Double
        public let color: Color
        /// A colour dot before the value; on by default, off for a lone value.
        public let showsDot: Bool

        public init(value: Double, color: Color, showsDot: Bool = true) {
            self.value = value
            self.color = color
            self.showsDot = showsDot
        }
    }

    let title: String
    let entries: [Entry]
    let format: ChartValueFormat

    public init(title: String, entries: [Entry], format: ChartValueFormat = .compact) {
        self.title = title
        self.entries = entries
        self.format = format
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(Self.capitalizedFirstLetter(title))
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: AppSpacing.md) {
                ForEach(entries.indices, id: \.self) { i in
                    valueRow(entries[i])
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
    private func valueRow(_ entry: Entry) -> some View {
        HStack(spacing: AppSpacing.xs) {
            if entry.showsDot {
                Circle()
                    .fill(entry.color)
                    .frame(width: 8, height: 8)
            }
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
            default:
                Text(verbatim: ChartValueFormat.compactString(entry.value))
                    .font(AppTypography.numbers(AppTypography.body))
                    .foregroundStyle(entry.color)
            }
        }
    }

    static func capitalizedFirstLetter(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}
