//
//  MiniBars.swift
//  DesignKit
//
//  Canvas row of small bars for insight feed cards (8.2.0): a value per weekday, per hour or
//  per month, one bar in colour (the busiest day, today) and the others muted. Tenra's
//  "By day" card: the weekday that spends the most. The grammar of MiniBarPair: muted grey =
//  context, the tinted bar = the signal, rounded tops on a hairline baseline.
//
//  Optional labels under the bars (a weekday's initial): the coloured bar's in its colour.
//  Decorative for VoiceOver: the card's text says what the bars show.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A row of small bars with one in colour, for a card's 120×60 pt slot.
///
/// ```swift
/// MiniBars(values: spentByWeekday, highlighted: busiest, color: AppColors.accent,
///          labels: Calendar.current.veryShortWeekdaySymbols)
/// ```
public struct MiniBars: View {
    let values: [Double]
    let highlighted: Int?
    let color: Color
    let labels: [String]?
    let height: CGFloat

    /// Bars shorter than this read as "missing": a zero value stays visible.
    private static let minBarHeight: CGFloat = 3
    static let gap: CGFloat = 4
    static let maxBarWidth: CGFloat = 14

    /// - Parameters:
    ///   - values: one bar each, in order (negative values draw as zero).
    ///   - highlighted: the bar in `color`; `nil`: the tallest.
    ///   - labels: one under each bar (a weekday's initial), or none.
    public init(
        values: [Double],
        highlighted: Int? = nil,
        color: Color = AppColors.accent,
        labels: [String]? = nil,
        height: CGFloat = 60
    ) {
        self.values = values
        self.highlighted = highlighted
        self.color = color
        self.labels = labels
        self.height = height
    }

    private var highlightedIndex: Int? {
        highlighted ?? values.indices.max { values[$0] < values[$1] }
    }

    public var body: some View {
        let accent = highlightedIndex
        Canvas { context, size in
            guard !values.isEmpty else { return }
            let count = CGFloat(values.count)
            let barWidth = min(Self.maxBarWidth, (size.width - Self.gap * (count - 1)) / count)
            let rowWidth = barWidth * count + Self.gap * (count - 1)
            let startX = (size.width - rowWidth) / 2

            // The labels' row, measured at the person's text size.
            let resolvedLabels: [GraphicsContext.ResolvedText]? = labels.map { labels in
                values.indices.map { i in
                    let isAccent = i == accent
                    return context.resolve(
                        Text(labels.indices.contains(i) ? labels[i] : "")
                            .font(AppTypography.caption2)
                            .fontWeight(isAccent ? .semibold : .regular)
                            .foregroundStyle(isAccent ? color : AppColors.Text.tertiary)
                    )
                }
            }
            let labelHeight = resolvedLabels?.map { $0.measure(in: size).height }.max() ?? 0
            let baselineY = size.height - 1 - (labelHeight > 0 ? labelHeight + 2 : 0)
            let plotHeight = max(baselineY - 2, 1)
            let maxValue = max(values.max() ?? 0, .leastNonzeroMagnitude)

            var baseline = Path()
            baseline.move(to: CGPoint(x: startX - 3, y: baselineY))
            baseline.addLine(to: CGPoint(x: startX + rowWidth + 3, y: baselineY))
            context.stroke(baseline, with: .color(AppColors.Text.secondary.opacity(0.2)), style: StrokeStyle(lineWidth: 1))

            let radius = min(MiniBarPair.cornerRadius, barWidth / 2)
            for i in values.indices {
                let x = startX + CGFloat(i) * (barWidth + Self.gap)
                let h = max(Self.minBarHeight, plotHeight * CGFloat(max(values[i], 0) / maxValue))
                let bar = Path(
                    roundedRect: CGRect(x: x, y: baselineY - h, width: barWidth, height: h),
                    cornerRadii: RectangleCornerRadii(topLeading: radius, bottomLeading: 0, bottomTrailing: 0, topTrailing: radius)
                )
                context.fill(bar, with: .color(i == accent ? color : AppColors.Text.secondary.opacity(0.35)))
                if let resolvedLabels {
                    context.draw(resolvedLabels[i], at: CGPoint(x: x + barWidth / 2, y: size.height), anchor: .bottom)
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Skeleton

/// Placeholder of a `MiniBars`: `count` bars of a few heights on the baseline, centred.
public struct MiniBarsSkeleton: View {
    let count: Int
    let height: CGFloat

    public init(count: Int = 7, height: CGFloat = 60) {
        self.count = count
        self.height = height
    }

    private static let shares: [CGFloat] = [0.55, 0.8, 0.45, 0.7, 1, 0.6, 0.85]

    public var body: some View {
        HStack(alignment: .bottom, spacing: MiniBars.gap) {
            ForEach(0..<count, id: \.self) { i in
                UnevenRoundedRectangle(
                    topLeadingRadius: MiniBarPair.cornerRadius,
                    topTrailingRadius: MiniBarPair.cornerRadius
                )
                .fill(Skeleton.fill)
                .frame(maxWidth: MiniBars.maxBarWidth)
                .frame(height: (height - 3) * Self.shares[i % Self.shares.count])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .frame(height: height)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
