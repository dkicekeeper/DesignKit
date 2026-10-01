//
//  ChartPoint.swift
//  DesignKit
//
//  Data model of the category-axis chart family (LineChart, BarChart, ChartSwitcher,
//  HeroSparkline, Sparkline). Ported from Tenra's PeriodDataPoint charts: the app keeps
//  its own point type and conforms it to `ChartPoint`; a series says how to read a value
//  from a point and how to colour it.
//

import SwiftUI
import DesignTokens
import DesignSupport

// MARK: - Point

/// One bucket on the X axis: a month, a week, a day, a trip.
///
/// Conform your own model (only `chartLabel` is required):
/// ```swift
/// extension MonthStats: ChartPoint {
///     var chartLabel: String { key }                 // "2025-01", unique
///     var chartAxisLabel: String { shortMonth }      // "JAN"
///     var chartTitle: String { fullMonth }           // "January 2025"
///     var chartDate: Date? { start }                 // first future bucket gets "Today"
/// }
/// ```
/// or use `ChartValuePoint` for plain data.
public protocol ChartPoint: Identifiable, Hashable {
    /// Category on the X axis. Unique within a dataset; also the selection key.
    var chartLabel: String { get }
    /// Compact text under the axis tick ("JAN", "W07"). Defaults to `chartLabel`.
    var chartAxisLabel: String { get }
    /// Title of the selection banner ("January 2025"). Defaults to `chartLabel`.
    var chartTitle: String { get }
    /// Start of the bucket. The first point that starts after now gets the "Today" marker.
    /// Defaults to `nil` (no marker).
    var chartDate: Date? { get }
}

public extension ChartPoint {
    var chartAxisLabel: String { chartLabel }
    var chartTitle: String { chartLabel }
    var chartDate: Date? { nil }
}

/// Ready-made point: a label and values by series id.
///
/// ```swift
/// let points = [
///     ChartValuePoint(label: "Mon", values: ["km": 12.4]),
///     ChartValuePoint(label: "Tue", values: ["km": 8.1]),
/// ]
/// LineChart(dataPoints: points, series: .keyed("km", name: "Distance", coloring: .solid(AppColors.accent)))
/// ```
public struct ChartValuePoint: ChartPoint {
    public let id: String
    public let chartLabel: String
    public let chartAxisLabel: String
    public let chartTitle: String
    public let chartDate: Date?
    public let values: [String: Double]

    public init(
        label: String,
        axisLabel: String? = nil,
        title: String? = nil,
        date: Date? = nil,
        values: [String: Double]
    ) {
        self.id = label
        self.chartLabel = label
        self.chartAxisLabel = axisLabel ?? label
        self.chartTitle = title ?? label
        self.chartDate = date
        self.values = values
    }

    /// Value of a series; 0 when the point has none.
    public subscript(series: String) -> Double { values[series] ?? 0 }
}

// MARK: - Series

/// Colouring of a chart series.
public enum ChartColoring {
    /// One colour for line, area, points and bars.
    case solid(Color)
    /// Positive values in one colour, negative in another; adds a dashed zero rule.
    case signed(positive: Color, negative: Color)

    /// Colour of one value.
    public func color(for value: Double) -> Color {
        switch self {
        case .solid(let color): return color
        case .signed(let positive, let negative): return value >= 0 ? positive : negative
        }
    }
}

/// Where a series' Y axis starts.
public enum ChartBaseline: Hashable, Sendable {
    /// Y axis from 0 (counts, amounts, distances).
    case zero
    /// Y axis may go below 0 (net flow, balance, elevation change).
    case signed
}

/// How a series reads its value from a point and how it is drawn.
///
/// Colouring and baseline reproduce Tenra's insight series:
/// - spending: `.solid(AppColors.destructive)`, `.zero`
/// - income: `.solid(AppColors.success)`, `.zero`
/// - cash flow: `.signed(positive: success, negative: destructive)`, `.signed` — the line
///   turns from green to red where it crosses zero, with a dashed zero rule
/// - balance: `.solid(AppColors.accent)`, `.signed`, line width 2.5
public struct ChartSeries<Point> {
    public typealias Coloring = ChartColoring
    public typealias Baseline = ChartBaseline

    /// Stable id: groups marks of one series (`series:` / `position(by:)`).
    public let id: String
    /// Name read by VoiceOver when a chart shows several series ("Income: 480 000").
    public let name: String
    public let coloring: Coloring
    public let baseline: Baseline
    /// Line width in full-size charts.
    public let lineWidth: CGFloat
    public let value: (Point) -> Double

    public init(
        id: String,
        name: String,
        coloring: Coloring,
        baseline: Baseline = .zero,
        lineWidth: CGFloat = 2,
        value: @escaping (Point) -> Double
    ) {
        self.id = id
        self.name = name
        self.coloring = coloring
        self.baseline = baseline
        self.lineWidth = lineWidth
        self.value = value
    }

    /// Colour of one value: points, bars, the banner amount.
    public func color(for value: Double) -> Color {
        coloring.color(for: value)
    }

    /// Whether to draw a dashed rule at y = 0 (signed colouring).
    public var showsZeroRule: Bool {
        if case .signed = coloring { return true }
        return false
    }

    /// Unpadded Y range for the given values: from 0 for `.zero`, through 0 for `.signed`.
    public func yDomain(values: [Double]) -> ClosedRange<Double> {
        switch baseline {
        case .zero:
            return 0...Swift.max(values.max() ?? 0, 1)
        case .signed:
            let low = Swift.min(values.min() ?? 0, 0)
            let high = Swift.max(values.max() ?? 0, 1)
            return low...high
        }
    }

    /// Line stroke. Signed colouring: a vertical gradient that switches colour exactly at
    /// y = 0. `yDomain` must be the marks' own unpadded envelope, not the padded axis domain.
    public func lineStyle(yDomain: ClosedRange<Double>) -> AnyShapeStyle {
        switch coloring {
        case .solid(let color):
            return AnyShapeStyle(color)
        case .signed(let positive, let negative):
            let total = yDomain.upperBound - yDomain.lowerBound
            guard total > 0 else { return AnyShapeStyle(positive) }
            let zeroRatio = (yDomain.upperBound - 0) / total
            if zeroRatio <= 0 { return AnyShapeStyle(negative) }
            if zeroRatio >= 1 { return AnyShapeStyle(positive) }
            let eps = 0.001
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: positive, location: 0),
                    .init(color: positive, location: Swift.max(0, zeroRatio - eps)),
                    .init(color: negative, location: Swift.min(1, zeroRatio + eps)),
                    .init(color: negative, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            ))
        }
    }

    /// Area fill: the line colour fading downwards. Signed colouring tints each side of zero.
    public func areaStyle(yDomain: ClosedRange<Double>) -> AnyShapeStyle {
        switch coloring {
        case .solid(let color):
            return Self.fade(color)
        case .signed(let positive, let negative):
            let total = yDomain.upperBound - yDomain.lowerBound
            guard total > 0 else { return Self.fade(positive) }
            let zeroRatio = (yDomain.upperBound - 0) / total
            if zeroRatio <= 0 {
                return AnyShapeStyle(LinearGradient(
                    colors: [negative.opacity(0.05), negative.opacity(0.3)],
                    startPoint: .top, endPoint: .bottom
                ))
            }
            if zeroRatio >= 1 { return Self.fade(positive) }
            let eps = 0.001
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: positive.opacity(0.35), location: 0),
                    .init(color: positive.opacity(0.05), location: Swift.max(0, zeroRatio - eps)),
                    .init(color: negative.opacity(0.05), location: Swift.min(1, zeroRatio + eps)),
                    .init(color: negative.opacity(0.35), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            ))
        }
    }

    private static func fade(_ color: Color) -> AnyShapeStyle {
        AnyShapeStyle(LinearGradient(
            colors: [color.opacity(0.3), color.opacity(0.05)],
            startPoint: .top, endPoint: .bottom
        ))
    }
}

public extension ChartSeries where Point == ChartValuePoint {
    /// Series reading `point[id]` from `ChartValuePoint`s.
    static func keyed(
        _ id: String,
        name: String,
        coloring: Coloring,
        baseline: Baseline = .zero,
        lineWidth: CGFloat = 2
    ) -> ChartSeries {
        ChartSeries(id: id, name: name, coloring: coloring, baseline: baseline, lineWidth: lineWidth) { $0[id] }
    }
}

// MARK: - Value format

/// How the selection banner (and VoiceOver) shows a value. The Y axis always uses
/// `ChartValueFormat.compactString` ("1.5M", "75K").
public enum ChartValueFormat {
    /// "1.5M" / "75K" / "500".
    case compact
    /// A money amount via `FormattedAmountText` (ISO code, e.g. "KZT").
    case currency(String)
    /// Your own text, units included ("12.4 km").
    case custom((Double) -> String)

    /// Compact number: 1_500_000 → "1.5M", 75_000 → "75K", 500 → "500", -30_000 → "-30K".
    public static func compactString(_ value: Double) -> String {
        let magnitude = Swift.abs(value)
        if magnitude >= 1_000_000 { return String(format: "%.1fM", value / 1_000_000) }
        if magnitude >= 1_000 { return String(format: "%.0fK", value / 1_000) }
        return String(format: "%.0f", value)
    }

    /// Plain text of a value, for VoiceOver.
    func spokenText(_ value: Double) -> String {
        switch self {
        case .compact:
            return AmountFormatter.format(Decimal(value))
        case .currency(let code):
            let amount = AmountFormatter.format(Decimal(value))
            return code.isEmpty ? amount : "\(amount) \(code)"
        case .custom(let format):
            return format(value)
        }
    }
}
