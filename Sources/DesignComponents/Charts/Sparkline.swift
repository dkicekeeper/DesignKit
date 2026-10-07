//
//  Sparkline.swift
//  DesignKit
//
//  Lightweight Canvas sparkline for cards and feeds (Tenra's MiniSparkline): no Swift
//  Charts render tree per card, cheap inside a LazyVStack.
//
//  - Solid line + area fading towards the bottom, linear interpolation.
//  - Signed colouring tints the whole sparkline by the sign of the LAST value and adds a
//    dashed zero baseline when the range dips below zero.
//  - "You are here" dot on the last point; the plot is inset by the dot radius so the
//    dot never clips.
//  - Optional forecast: the fact line takes ~72 % of the width and a dashed tail runs to
//    `projectedValue` with a hollow end (dashed / hollow = not yet real).
//  - Optional extremes: max → success dot, min → destructive dot.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Compact trend line. Needs at least two values to draw.
///
/// ```swift
/// Sparkline(values: weeklyKm, coloring: .solid(AppColors.accent))
/// Sparkline(dataPoints: months, series: netFlow, height: 24, endDotRadius: 2.5)
/// ```
public struct Sparkline: View {
    let values: [Double]
    let coloring: ChartColoring
    let baseline: ChartBaseline
    let lineWidth: CGFloat
    let height: CGFloat
    let endDotRadius: CGFloat
    let projectedValue: Double?
    let markExtremes: Bool

    /// - Parameters:
    ///   - values: the series, oldest first.
    ///   - coloring: `.solid(color)` or `.signed(positive:negative:)` (tinted by the last value).
    ///   - baseline: `.zero` (Y from 0) or `.signed` (Y may go below 0).
    ///   - endDotRadius: radius of the last-point dot; doubles as the plot inset.
    ///   - projectedValue: forecast endpoint (dashed tail, hollow dot).
    ///   - markExtremes: success dot on the max, destructive dot on the min.
    public init(
        values: [Double],
        coloring: ChartColoring = .solid(AppColors.accent),
        baseline: ChartBaseline = .zero,
        lineWidth: CGFloat = 1.5,
        height: CGFloat = 60,
        endDotRadius: CGFloat = 3,
        projectedValue: Double? = nil,
        markExtremes: Bool = false
    ) {
        self.values = values
        self.coloring = coloring
        self.baseline = baseline
        self.lineWidth = lineWidth
        self.height = height
        self.endDotRadius = endDotRadius
        self.projectedValue = projectedValue
        self.markExtremes = markExtremes
    }

    /// Sparkline of one series over chart points (same series as the full charts).
    public init<Point>(
        dataPoints: [Point],
        series: ChartSeries<Point>,
        lineWidth: CGFloat = 1.5,
        height: CGFloat = 60,
        endDotRadius: CGFloat = 3,
        projectedValue: Double? = nil,
        markExtremes: Bool = false
    ) {
        self.init(
            values: dataPoints.map(series.value),
            coloring: series.coloring,
            baseline: series.baseline,
            lineWidth: lineWidth,
            height: height,
            endDotRadius: endDotRadius,
            projectedValue: projectedValue,
            markExtremes: markExtremes
        )
    }

    private var series: ChartSeries<Double> {
        ChartSeries(id: "sparkline", name: "", coloring: coloring, baseline: baseline) { $0 }
    }

    /// Line + area colour: the solid colour, or the sign of the last value.
    private var tintColor: Color {
        series.color(for: values.last ?? 0)
    }

    public var body: some View {
        let series = self.series
        let tint = tintColor
        GeometryReader { proxy in
            Canvas { context, size in
                guard values.count >= 2 else { return }
                let vals = values
                // The projection endpoint must fit inside the y-domain.
                var domainValues = vals
                if let projectedValue { domainValues.append(projectedValue) }
                let domain = series.yDomain(values: domainValues)
                let span = max(domain.upperBound - domain.lowerBound, .leastNonzeroMagnitude)

                let inset = endDotRadius
                let plotWidth = max(size.width - inset * 2, 1)
                let plotHeight = max(size.height - inset * 2, 1)
                // The fact line yields the right ~28 % to the projection tail.
                let factWidth = projectedValue != nil ? plotWidth * 0.72 : plotWidth
                let stepX = factWidth / CGFloat(max(vals.count - 1, 1))

                // Y is inverted in screen coordinates: higher value → smaller y.
                func yFor(_ value: Double) -> CGFloat {
                    let yNorm = CGFloat((value - domain.lowerBound) / span)
                    return inset + (1 - yNorm) * plotHeight
                }
                func plotPoint(index: Int, value: Double) -> CGPoint {
                    CGPoint(x: inset + CGFloat(index) * stepX, y: yFor(value))
                }

                var linePath = Path()
                for (idx, v) in vals.enumerated() {
                    let p = plotPoint(index: idx, value: v)
                    if idx == 0 {
                        linePath.move(to: p)
                    } else {
                        linePath.addLine(to: p)
                    }
                }

                // Area: the line closed down to the bottom (fact only, no fill under the tail).
                var areaPath = linePath
                areaPath.addLine(to: CGPoint(x: inset + factWidth, y: size.height))
                areaPath.addLine(to: CGPoint(x: inset, y: size.height))
                areaPath.closeSubpath()

                let gradient = Gradient(colors: [tint.opacity(0.30), tint.opacity(0.05)])
                context.fill(
                    areaPath,
                    with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
                )

                // Dashed zero baseline: signed colouring AND the range actually dips below 0.
                if series.showsZeroRule, domain.lowerBound < 0 {
                    let zeroY = plotPoint(index: 0, value: 0).y
                    var zeroPath = Path()
                    zeroPath.move(to: CGPoint(x: inset, y: zeroY))
                    zeroPath.addLine(to: CGPoint(x: inset + plotWidth, y: zeroY))
                    context.stroke(
                        zeroPath,
                        with: .color(AppColors.Text.secondary.opacity(0.35)),
                        style: StrokeStyle(lineWidth: 1, dash: [2, 3])
                    )
                }

                context.stroke(
                    linePath,
                    with: .color(tint),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )

                // Dashed projection tail ending in a hollow dot.
                if let projectedValue, let lastValue = vals.last {
                    let from = plotPoint(index: vals.count - 1, value: lastValue)
                    let to = CGPoint(x: inset + plotWidth, y: yFor(projectedValue))
                    var dash = Path()
                    dash.move(to: from)
                    dash.addLine(to: to)
                    context.stroke(dash, with: .color(tint), style: StrokeStyle(lineWidth: lineWidth, dash: [3, 4]))
                    let r = endDotRadius
                    context.stroke(
                        Path(ellipseIn: CGRect(x: to.x - r, y: to.y - r, width: r * 2, height: r * 2)),
                        with: .color(tint),
                        lineWidth: 1.5
                    )
                }

                // Extremes: max (success) and min (destructive).
                if markExtremes,
                   let maxIdx = vals.indices.max(by: { vals[$0] < vals[$1] }),
                   let minIdx = vals.indices.min(by: { vals[$0] < vals[$1] }),
                   maxIdx != minIdx {
                    for (idx, color) in [(maxIdx, AppColors.success), (minIdx, AppColors.destructive)] {
                        let c = plotPoint(index: idx, value: vals[idx])
                        let dotRect = CGRect(
                            x: c.x - endDotRadius, y: c.y - endDotRadius,
                            width: endDotRadius * 2, height: endDotRadius * 2
                        )
                        context.fill(Path(ellipseIn: dotRect), with: .color(color))
                    }
                }

                // "You are here" dot on the last point.
                if let lastValue = vals.last {
                    let center = plotPoint(index: vals.count - 1, value: lastValue)
                    let dotRect = CGRect(
                        x: center.x - endDotRadius, y: center.y - endDotRadius,
                        width: endDotRadius * 2, height: endDotRadius * 2
                    )
                    context.fill(Path(ellipseIn: dotRect), with: .color(tint))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(height: height)
    }
}

// MARK: - Skeleton

/// Placeholder of a `Sparkline`: its plot area with a soft corner.
public struct SparklineSkeleton: View {
    let height: CGFloat

    public init(height: CGFloat = 60) {
        self.height = height
    }

    public var body: some View {
        Skeleton(height: height)
            .skeletonLoadingLabel()
    }
}
