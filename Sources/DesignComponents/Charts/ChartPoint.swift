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
///     var chartIsPartial: Bool { end > .now }        // this month is not over yet
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
    /// Defaults to `nil` (no marker). The charts open on the period that holds today: the
    /// last point that does not start after now (the last point when there are no dates).
    var chartDate: Date? { get }
    /// The period is not over yet (this month, this week), so its value is still growing
    /// (8.3.0). A bar fades towards its top, the line's last stretch is dashed and the banner
    /// says "so far" (key `chart.partial`). Defaults to `false`.
    var chartIsPartial: Bool { get }
}

public extension ChartPoint {
    var chartAxisLabel: String { chartLabel }
    var chartTitle: String { chartLabel }
    var chartDate: Date? { nil }
    var chartIsPartial: Bool { false }
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
    public let chartIsPartial: Bool
    public let values: [String: Double]

    /// - Parameter isPartial: the period is not over yet (8.3.0, `ChartPoint.chartIsPartial`).
    public init(
        label: String,
        axisLabel: String? = nil,
        title: String? = nil,
        date: Date? = nil,
        isPartial: Bool = false,
        values: [String: Double]
    ) {
        self.id = label
        self.chartLabel = label
        self.chartAxisLabel = axisLabel ?? label
        self.chartTitle = title ?? label
        self.chartDate = date
        self.chartIsPartial = isPartial
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

/// Which way a series is better (8.3.0): the colour of its change in the banner and which
/// period is its record.
public enum ChartBetter: Hashable, Sendable {
    /// More is better: income, savings, distance.
    case higher
    /// Less is better: spending, debt.
    case lower
}

/// What the banner shows for a stretch of periods picked with a long press and a drag (8.3.0).
public enum ChartRangeSummary: Hashable, Sendable {
    /// The sum of the periods, their average and the change from the first to the last:
    /// amounts that add up (spending, income, distance).
    case total
    /// The last value and the change from the first: a level, not a flow (a balance, a weight).
    case change
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
    /// Which way the series is better (8.3.0): its change reads green or red, and its best
    /// finished period is a record. `nil`: neither, the change in the secondary colour.
    public let better: ChartBetter?
    /// What the banner sums up for a picked stretch of periods (8.3.0).
    public let rangeSummary: ChartRangeSummary
    public let value: (Point) -> Double
    /// What a period that is not over is expected to reach (8.3.0): a forecast, drawn as a
    /// pale bar or a dashed rise above the value so far. Read for unfinished points only.
    public let projected: ((Point) -> Double?)?
    /// The same period one cycle before, a year ago (8.3.0): drawn as a pale shadow behind
    /// the value, and in the banner.
    public let comparison: ((Point) -> Double?)?

    /// - Parameters:
    ///   - better: which way is better: the change's colour and the record (8.3.0).
    ///   - rangeSummary: what a picked stretch of periods sums up to (8.3.0).
    ///   - value: the value at a point.
    ///   - projected: the forecast of an unfinished point (8.3.0).
    ///   - comparison: the same period one cycle before (8.3.0).
    public init(
        id: String,
        name: String,
        coloring: Coloring,
        baseline: Baseline = .zero,
        lineWidth: CGFloat = 2,
        better: ChartBetter? = nil,
        rangeSummary: ChartRangeSummary = .total,
        value: @escaping (Point) -> Double,
        projected: ((Point) -> Double?)? = nil,
        comparison: ((Point) -> Double?)? = nil
    ) {
        self.id = id
        self.name = name
        self.coloring = coloring
        self.baseline = baseline
        self.lineWidth = lineWidth
        self.better = better
        self.rangeSummary = rangeSummary
        self.value = value
        self.projected = projected
        self.comparison = comparison
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
    /// Series reading `point[id]` from `ChartValuePoint`s; the forecast and the comparison,
    /// when given, from `point[projectedKey]` and `point[comparisonKey]` (8.3.0).
    static func keyed(
        _ id: String,
        name: String,
        coloring: Coloring,
        baseline: Baseline = .zero,
        lineWidth: CGFloat = 2,
        better: ChartBetter? = nil,
        rangeSummary: ChartRangeSummary = .total,
        projectedKey: String? = nil,
        comparisonKey: String? = nil
    ) -> ChartSeries {
        let projected: ((ChartValuePoint) -> Double?)? = projectedKey.map { key in
            { (point: ChartValuePoint) -> Double? in point.values[key] }
        }
        let comparison: ((ChartValuePoint) -> Double?)? = comparisonKey.map { key in
            { (point: ChartValuePoint) -> Double? in point.values[key] }
        }
        return ChartSeries(
            id: id,
            name: name,
            coloring: coloring,
            baseline: baseline,
            lineWidth: lineWidth,
            better: better,
            rangeSummary: rangeSummary,
            value: { $0[id] },
            projected: projected,
            comparison: comparison
        )
    }
}

// MARK: - Value format

/// How the selection banner (and VoiceOver) shows a value. The Y axis always uses
/// `ChartValueFormat.compactString` ("1.5M", "75K"; "1,5 млн" in Russian).
public enum ChartValueFormat {
    /// "1.5M" / "75K" / "500".
    case compact
    /// A money amount via `FormattedAmountText` (ISO code, e.g. "KZT").
    case currency(String)
    /// Your own text, units included ("12.4 km").
    case custom((Double) -> String)

    /// Compact number in the person's language: 1_500_000 → "1.5M", 75_000 → "75K",
    /// 1_500 → "1.5K", 500 → "500", -30_000 → "-30K"; in Russian "1,5 млн", "75 тыс.".
    /// 8.3.0: before, the thousands were rounded to whole numbers (1 500 → "2K", so the axis
    /// could show the wrong value) and every language read "K" and "M".
    public static func compactString(_ value: Double) -> String {
        value.formatted(.number.notation(.compactName))
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

// MARK: - Reference lines

/// A horizontal line across a `LineChart` or `BarChart` (8.3.0): the average of a series, or a
/// fixed value such as a limit or a goal. Its label sits in a pill at the plot's leading edge,
/// over the line, and stays there while the chart scrolls.
///
/// ```swift
/// BarChart(dataPoints: months, series: spending,
///          referenceLines: [.average(), .value(500_000, label: "Limit", aboveColor: AppColors.warning)])
/// ```
public struct ChartReferenceLine: Identifiable {
    enum Value {
        /// The average of a series' finished periods (the first series when `nil`).
        case average(seriesID: String?)
        case fixed(Double)
    }

    public let id: String
    let value: Value
    let label: String
    let color: Color
    /// Bars above the line take this colour (a limit); `nil` keeps their own.
    let aboveColor: Color?

    /// The average of a series' finished periods: the first series unless `seriesID` names
    /// another. Its label is "Average" (key `chart.average`) and its value.
    public static func average(
        of seriesID: String? = nil,
        label: String = String(localized: "chart.average", defaultValue: "Average"),
        color: Color = AppColors.Text.secondary
    ) -> ChartReferenceLine {
        ChartReferenceLine(id: "average-\(seriesID ?? "")", value: .average(seriesID: seriesID), label: label,
                           color: color, aboveColor: nil)
    }

    /// A series' average, which the person's `.average` option stands in for.
    var isAverage: Bool {
        if case .average = value { return true }
        return false
    }

    /// A fixed value: a limit, a goal, a budget. `aboveColor` paints the bars that pass it.
    public static func value(
        _ value: Double,
        label: String,
        color: Color = AppColors.warning,
        aboveColor: Color? = nil
    ) -> ChartReferenceLine {
        ChartReferenceLine(id: "value-\(label)-\(value)", value: .fixed(value), label: label,
                           color: color, aboveColor: aboveColor)
    }
}

// MARK: - Display options

/// What the trend charts draw besides their values, as the person chose it (8.3.0). Hand it
/// to the charts with `.chartDisplayOptions(_:)`: each `LineChart`, `BarChart` and
/// `ChartSwitcher` below follows it, and a `ChartSwitcher` shows it as a menu next to its zoom.
/// An `OptionSet` over `Int`, so `@AppStorage` keeps it and every chart of the app opens the
/// way the person left the last one.
///
/// ```swift
/// @AppStorage("chartOptions") private var chartOptions = ChartDisplayOptions.standard
///
/// InsightsScreen()
///     .chartDisplayOptions($chartOptions)
/// ```
public struct ChartDisplayOptions: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// A dashed line at each series' average over its finished periods.
    public static let average = ChartDisplayOptions(rawValue: 1 << 0)
    /// Dots on each series' highest and lowest finished period (`marksExtremes:`).
    public static let records = ChartDisplayOptions(rawValue: 1 << 1)
    /// The forecast of a period that is not over (`ChartSeries.projected`).
    public static let forecast = ChartDisplayOptions(rawValue: 1 << 2)
    /// The same period a cycle back, a year ago (`ChartSeries.comparison`).
    public static let comparison = ChartDisplayOptions(rawValue: 1 << 3)
    /// A ruler in the middle of the window; the chart scrolls under it (`followsScroll:`).
    public static let followsScroll = ChartDisplayOptions(rawValue: 1 << 4)

    /// Forecasts and comparisons: what the charts draw when nobody chose.
    public static let standard: ChartDisplayOptions = [.forecast, .comparison]
}

extension EnvironmentValues {
    /// The person's chart options (`.chartDisplayOptions(_:)`); `nil`: each chart's parameters.
    @Entry var chartDisplayOptions: Binding<ChartDisplayOptions>? = nil
}

extension View {
    /// The trend charts below draw what `options` holds, and each `ChartSwitcher` shows it in a
    /// menu that changes it (8.3.0). It stands in for the charts' `.average()` reference lines
    /// (an average line per series when on), `marksExtremes:` and `followsScroll:`; other
    /// reference lines, a limit or a goal, stay.
    public func chartDisplayOptions(_ options: Binding<ChartDisplayOptions>) -> some View {
        environment(\.chartDisplayOptions, options)
    }
}
