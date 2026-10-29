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
//  chart's legend), its change from the previous period, lines under it (a forecast, a year
//  ago, an average) and a record; the title a note ("so far"); the values roll from one to
//  the next, and many entries wrap.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Selection banner of `LineChart`, `BarChart`, `HeroSparkline` and `CalendarHeatmap`; usable
/// on its own.
///
/// ```swift
/// ChartSelectionBanner(title: "январь 2025", entries: [
///     .init(value: 480_000, color: AppColors.success, label: "Income", changePercent: 12, better: .higher),
///     .init(value: 275_000, color: AppColors.destructive, label: "Expenses",
///           details: [.init("Forecast", value: 520_000)]),
/// ], format: .currency("KZT"))
/// ```
public struct ChartSelectionBanner: View {
    /// A line under an entry's value in the secondary colour: "Forecast 520 000 ₸" (8.2.0).
    public struct Detail {
        public let label: String
        public let value: Double

        public init(_ label: String, value: Double) {
            self.label = label
            self.value = value
        }
    }

    public struct Entry {
        public let value: Double
        public let color: Color
        /// A colour dot before the value (or its label); on by default, off for a lone value.
        public let showsDot: Bool
        /// The series' name over its value (8.2.0). With several series it is the legend.
        public let label: String?
        /// The change from the previous period, in percent, with its arrow (8.2.0).
        public let changePercent: Double?
        /// Which way is better: the change reads green when it goes that way, red when not;
        /// `nil` keeps it in the secondary colour (8.2.0).
        public let better: ChartBetter?
        /// Lines under the value: a forecast, a year ago, an average (8.2.0).
        public let details: [Detail]
        /// The best period of its series: a "Record" pill with sparkles (8.2.0).
        public let isRecord: Bool

        public init(
            value: Double,
            color: Color,
            showsDot: Bool = true,
            label: String? = nil,
            changePercent: Double? = nil,
            better: ChartBetter? = nil,
            details: [Detail] = [],
            isRecord: Bool = false
        ) {
            self.value = value
            self.color = color
            self.showsDot = showsDot
            self.label = label
            self.changePercent = changePercent
            self.better = better
            self.details = details
            self.isRecord = isRecord
        }
    }

    let title: String
    let note: String?
    let entries: [Entry]
    let format: ChartValueFormat

    /// The colour dot grows with the text beside it.
    @ScaledMetric(relativeTo: .caption) private var dotSize: CGFloat = 8

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

    /// One unlabelled value: its change goes on the title's line.
    private var isSingle: Bool { entries.count == 1 && entries[0].label == nil }

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
                if isSingle, let change = entries[0].changePercent {
                    Spacer(minLength: AppSpacing.sm)
                    ChartChangeText(percent: change, better: entries[0].better)
                }
            }
            .lineLimit(1)

            FlowLayout(spacing: AppSpacing.lg, lineSpacing: AppSpacing.sm) {
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
        VStack(alignment: .leading, spacing: 2) {
            if let label = entry.label {
                HStack(spacing: AppSpacing.xs) {
                    if entry.showsDot { dot(entry.color) }
                    Text(label)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Text.secondary)
                        .lineLimit(1)
                    if let change = entry.changePercent {
                        ChartChangeText(percent: change, better: entry.better)
                    }
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                if entry.label == nil && entry.showsDot { dot(entry.color) }
                valueText(entry.value, color: entry.color, font: AppTypography.body)
                if entry.isRecord {
                    ChartRecordPill(color: entry.color)
                }
            }
            ForEach(entry.details.indices, id: \.self) { i in
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                    Text(entry.details[i].label)
                    valueText(entry.details[i].value, color: AppColors.Text.secondary, font: AppTypography.caption)
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.Text.secondary)
                .lineLimit(1)
            }
        }
    }

    private func dot(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: dotSize, height: dotSize)
    }

    @ViewBuilder
    private func valueText(_ value: Double, color: Color, font: Font) -> some View {
        switch format {
        case .currency(let code) where !code.isEmpty:
            FormattedAmountText(
                amount: value,
                currency: code,
                fontSize: font,
                fontWeight: .regular,
                color: color
            )
            .lineLimit(1)
        case .custom(let text):
            Text(verbatim: text(value))
                .font(AppTypography.numbers(font))
                .foregroundStyle(color)
                .lineLimit(1)
                .contentTransition(.numericText(value: value))
        default:
            Text(verbatim: ChartValueFormat.compactString(value))
                .font(AppTypography.numbers(font))
                .foregroundStyle(color)
                .lineLimit(1)
                .contentTransition(.numericText(value: value))
        }
    }

    static func capitalizedFirstLetter(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}

// MARK: - Change and record

/// "↗ +12.4%" in the caption size: green when the change goes the better way, red when not,
/// secondary when neither is better (8.2.0).
struct ChartChangeText: View {
    let percent: Double
    let better: ChartBetter?

    private var direction: TrendBadge.Direction {
        if abs(percent) < 0.05 { return .flat }
        return percent > 0 ? .up : .down
    }

    private var color: Color {
        switch (direction, better) {
        case (.flat, _), (_, nil): return AppColors.Text.secondary
        case (.up, .higher), (.down, .lower): return AppColors.success
        default: return AppColors.destructive
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            Icon(direction.systemImage, size: AppIconSize.xs)
            Text(verbatim: TrendBadge.format(percent))
                .font(AppTypography.numbers(AppTypography.caption))
                .fontWeight(.semibold)
                .contentTransition(.numericText(value: percent))
        }
        .foregroundStyle(color)
        .lineLimit(1)
        .fixedSize()
    }
}

/// "Record" in a pill of the series' colour that sparkles as it appears (8.2.0, key
/// `chart.record`).
struct ChartRecordPill: View {
    let color: Color
    @State private var sparkles = false

    init(color: Color) {
        self.color = color
    }

    var body: some View {
        Text(String(localized: "chart.record", defaultValue: "Record"))
            .font(AppTypography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 2)
            .background(AppColors.pale(color), in: Capsule())
            .fixedSize()
            .sparkleBurst(trigger: sparkles, tint: color)
            .onAppear { sparkles = true }
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
