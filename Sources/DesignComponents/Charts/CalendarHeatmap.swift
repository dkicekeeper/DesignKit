//
//  CalendarHeatmap.swift
//  DesignKit
//
//  Days as a grid of small squares, a week per column, today at the trailing end (8.3.0, the
//  owner's list after the charts audit): each square tinted by the day's value in five steps,
//  from an empty grey square to the full colour, so the busy days and the quiet weeks stand
//  out at a glance (spending by day, kilometres by day). A tap picks a day; the banner above
//  shows it, today until then.
//
//  One Canvas for the grid and the month names (a few hundred squares would be a few hundred
//  views), in a horizontal scroll view that opens on today.
//

import SwiftUI
import Accessibility
import DesignTokens
import DesignSupport

/// A calendar of days tinted by their values.
///
/// ```swift
/// CalendarHeatmap(values: spendingByDay, color: AppColors.destructive, valueFormat: .currency("KZT"))
/// ```
///
/// - The steps are the quartiles of the days that have a value, so one big day does not wash
///   the others out.
/// - Days after `today` are not drawn.
public struct CalendarHeatmap: View {
    let values: [Date: Double]
    let weeks: Int
    let color: Color
    let valueFormat: ChartValueFormat
    let today: Date
    let calendar: Calendar
    let emptyTitle: String
    let emptyMessage: String?

    @State private var selectedDay: Date?

    /// - Parameters:
    ///   - values: a value per day; dates are read by their day in `calendar`, and values of
    ///     the same day add up.
    ///   - weeks: how many weeks back from `today` (columns).
    ///   - color: the full colour of the busiest days.
    ///   - valueFormat: banner / VoiceOver value format.
    ///   - today: the last day drawn, selected until a tap picks another.
    ///   - calendar: the weeks' first day and the days' boundaries.
    ///   - emptyTitle / emptyMessage: empty state (keys `chart.empty.title` / `chart.empty.message`).
    public init(
        values: [Date: Double],
        weeks: Int = 26,
        color: Color = AppColors.accent,
        valueFormat: ChartValueFormat = .compact,
        today: Date = .now,
        calendar: Calendar = .current,
        emptyTitle: String = String(localized: "chart.empty.title"),
        emptyMessage: String? = String(localized: "chart.empty.message")
    ) {
        self.values = values
        self.weeks = max(1, weeks)
        self.color = color
        self.valueFormat = valueFormat
        self.today = today
        self.calendar = calendar
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
    }

    public var body: some View {
        if values.isEmpty {
            EmptyState(icon: "calendar", title: emptyTitle, description: emptyMessage, style: .compact)
        } else {
            let model = HeatmapModel(values: values, weeks: weeks, today: today, calendar: calendar)
            let selected = selectedDay ?? model.today
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ChartSelectionBanner(
                    title: model.title(of: selected),
                    entries: [.init(value: model.value(on: selected), color: color, showsDot: false)],
                    format: valueFormat
                )
                .animation(AppAnimation.chartBannerFade, value: selected)

                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    weekdayColumn(model)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HeatmapGrid(model: model, color: color, selected: selected) { day in
                            guard day != selected else { return }
                            selectedDay = day
                            HapticManager.selection()
                        }
                    }
                    .defaultScrollAnchor(.trailing)
                }

                legend
            }
            .accessibilityElement(children: .contain)
            .accessibilityChartDescriptor(HeatmapAudioGraph(model: model, format: valueFormat))
            .chartSelectionAnnouncement("\(model.title(of: selected)). \(valueFormat.spokenText(model.value(on: selected))).")
        }
    }

    /// The weekdays' short names by every other row (the first, third, fifth and seventh day of
    /// the week), so they never crowd.
    private func weekdayColumn(_ model: HeatmapModel) -> some View {
        VStack(alignment: .trailing, spacing: HeatmapMetrics.gap) {
            Color.clear.frame(height: HeatmapMetrics.monthRow + HeatmapMetrics.ringRoom)
            ForEach(0..<7, id: \.self) { row in
                Text(row.isMultiple(of: 2) ? model.weekdaySymbol(row: row) : "")
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.Text.secondary)
                    .lineLimit(1)
                    .frame(height: HeatmapMetrics.cell)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityHidden(true)
    }

    /// "Less ▢▢▢▢▢ More" (keys `chart.less`, `chart.more`).
    private var legend: some View {
        HStack(spacing: AppSpacing.xs) {
            Spacer(minLength: 0)
            Text(String(localized: "chart.less", defaultValue: "Less"))
            ForEach(0..<HeatmapMetrics.levels, id: \.self) { level in
                RoundedRectangle(cornerRadius: HeatmapMetrics.corner)
                    .fill(HeatmapModel.fill(level: level, color: color))
                    .frame(width: HeatmapMetrics.legendCell, height: HeatmapMetrics.legendCell)
            }
            Text(String(localized: "chart.more", defaultValue: "More"))
        }
        .font(AppTypography.caption2)
        .foregroundStyle(AppColors.Text.secondary)
        .accessibilityHidden(true)
    }
}

// MARK: - Model

/// The grid of a heatmap: its days, their values and steps.
struct HeatmapModel {
    let calendar: Calendar
    /// The first day of the first column (a week's first day).
    let start: Date
    let today: Date
    let weeks: Int
    let byDay: [Date: Double]
    /// The values that start steps 2, 3 and 4 (the quartiles of the days with a value).
    let thresholds: [Double]

    init(values: [Date: Double], weeks: Int, today: Date, calendar: Calendar) {
        self.calendar = calendar
        self.weeks = weeks
        let lastDay = calendar.startOfDay(for: today)
        self.today = lastDay
        let earliest = calendar.date(byAdding: .day, value: -(weeks - 1) * 7, to: lastDay) ?? lastDay
        self.start = calendar.dateInterval(of: .weekOfYear, for: earliest)?.start ?? earliest

        var byDay = [Date: Double]()
        for (date, value) in values {
            byDay[calendar.startOfDay(for: date), default: 0] += value
        }
        self.byDay = byDay

        let sorted = byDay.values.filter { $0 > 0 }.sorted()
        if sorted.isEmpty {
            thresholds = []
        } else {
            thresholds = [0.25, 0.5, 0.75].map { sorted[min(sorted.count - 1, Int(Double(sorted.count) * $0))] }
        }
    }

    func day(column: Int, row: Int) -> Date? {
        calendar.date(byAdding: .day, value: column * 7 + row, to: start)
    }

    func value(on day: Date) -> Double {
        byDay[calendar.startOfDay(for: day)] ?? 0
    }

    /// "Wednesday, October 29" in the calendar's time zone.
    func title(of day: Date) -> String {
        day.formatted(Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone).weekday(.wide).day().month(.wide))
    }

    /// 0: no value; 1 to 4: by quartile.
    func level(of value: Double) -> Int {
        guard value > 0 else { return 0 }
        return 1 + thresholds.filter { value >= $0 }.count.clamped(max: HeatmapMetrics.levels - 2)
    }

    /// The short name of a row's weekday ("Mon").
    func weekdaySymbol(row: Int) -> String {
        guard let day = day(column: 0, row: row) else { return "" }
        let index = calendar.component(.weekday, from: day) - 1
        let symbols = calendar.shortWeekdaySymbols
        return symbols.indices.contains(index) ? symbols[index] : ""
    }

    /// The step's colour: the empty grey, then the colour at a quarter, a half, three quarters
    /// and in full.
    static func fill(level: Int, color: Color) -> Color {
        level == 0 ? AppColors.Background.neutral2 : color.opacity(Double(level) / Double(HeatmapMetrics.levels - 1))
    }
}

private extension Int {
    func clamped(max upper: Int) -> Int { Swift.min(self, upper) }
}

// MARK: - Grid

/// The squares and the month names, in one Canvas; a tap picks a day.
private struct HeatmapGrid: View {
    let model: HeatmapModel
    let color: Color
    let selected: Date
    let onSelect: (Date) -> Void

    private var step: CGFloat { HeatmapMetrics.cell + HeatmapMetrics.gap }

    var body: some View {
        Canvas { context, _ in
            var lastMonthColumn = -3
            for column in 0..<model.weeks {
                // A month's name over the column where it starts, if the previous name is far
                // enough away.
                if let first = model.day(column: column, row: 0),
                   let last = model.day(column: column, row: 6),
                   column == 0 || model.calendar.component(.month, from: first) != model.calendar.component(.month, from: last)
                   || model.calendar.component(.day, from: first) == 1,
                   column - lastMonthColumn >= 3,
                   // A name needs about two columns: none where it would run off the end.
                   column <= model.weeks - 2 || model.weeks < 2 {
                    let monthDay = column == 0 ? first : last
                    let name = monthDay.formatted(Date.FormatStyle(calendar: model.calendar, timeZone: model.calendar.timeZone).month(.abbreviated))
                    context.draw(
                        Text(name).font(AppTypography.caption2).foregroundStyle(AppColors.Text.secondary),
                        at: CGPoint(x: CGFloat(column) * step, y: HeatmapMetrics.monthRow / 2),
                        anchor: .leading
                    )
                    lastMonthColumn = column
                }
                for row in 0..<7 {
                    guard let day = model.day(column: column, row: row), day <= model.today else { continue }
                    let rect = cellRect(column: column, row: row)
                    let level = model.level(of: model.value(on: day))
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: HeatmapMetrics.corner),
                        with: .color(HeatmapModel.fill(level: level, color: color))
                    )
                    if day == selected {
                        context.stroke(
                            Path(roundedRect: rect.insetBy(dx: -1.5, dy: -1.5), cornerRadius: HeatmapMetrics.corner + 1.5),
                            with: .color(AppColors.Text.primary),
                            lineWidth: 2
                        )
                    }
                }
            }
        }
        .frame(
            width: CGFloat(model.weeks) * step - HeatmapMetrics.gap,
            height: HeatmapMetrics.monthRow + 7 * step - HeatmapMetrics.gap
        )
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { location in
            let column = Int(location.x / step)
            let row = Int((location.y - HeatmapMetrics.monthRow) / step)
            guard (0..<model.weeks).contains(column), (0..<7).contains(row),
                  let day = model.day(column: column, row: row), day <= model.today else { return }
            onSelect(day)
        }
        // Room for the selected day's ring, which is drawn just outside its square.
        .padding(HeatmapMetrics.ringRoom)
        .accessibilityHidden(true)
    }

    private func cellRect(column: Int, row: Int) -> CGRect {
        CGRect(
            x: CGFloat(column) * step,
            y: HeatmapMetrics.monthRow + CGFloat(row) * step,
            width: HeatmapMetrics.cell,
            height: HeatmapMetrics.cell
        )
    }
}

// MARK: - Audio Graph

/// VoiceOver's Audio Graph of the days, oldest first.
private struct HeatmapAudioGraph: AXChartDescriptorRepresentable {
    let model: HeatmapModel
    let format: ChartValueFormat

    func makeChartDescriptor() -> AXChartDescriptor {
        var days = [Date]()
        for column in 0..<model.weeks {
            for row in 0..<7 {
                if let day = model.day(column: column, row: row), day <= model.today { days.append(day) }
            }
        }
        let values = days.map { model.value(on: $0) }
        let titles = days.map(model.title(of:))
        let xAxis = AXCategoricalDataAxisDescriptor(title: "", categoryOrder: titles)
        let yAxis = AXNumericDataAxisDescriptor(
            title: "",
            range: 0...max(values.max() ?? 1, 1),
            gridlinePositions: [],
            valueDescriptionProvider: { [format] in format.spokenText($0) }
        )
        let series = AXDataSeriesDescriptor(
            name: "",
            isContinuous: false,
            dataPoints: zip(titles, values).map { AXDataPoint(x: $0, y: $1) }
        )
        return AXChartDescriptor(title: nil, summary: nil, xAxis: xAxis, yAxis: yAxis, additionalAxes: [], series: [series])
    }
}

enum HeatmapMetrics {
    static let cell: CGFloat = 16
    static let gap: CGFloat = 4
    static let corner: CGFloat = 4
    static let monthRow: CGFloat = 18
    static let legendCell: CGFloat = 12
    /// Room around the grid for the selected day's ring.
    static let ringRoom: CGFloat = 2
    /// The empty grey and four steps of the colour.
    static let levels = 5
}

// MARK: - Skeleton

/// Placeholder of a `CalendarHeatmap`: the banner's card, then the grid of grey squares.
public struct CalendarHeatmapSkeleton: View {
    let weeks: Int

    public init(weeks: Int = 16) {
        self.weeks = max(1, weeks)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            ChartSelectionBannerSkeleton()
            Canvas { context, size in
                let step = HeatmapMetrics.cell + HeatmapMetrics.gap
                let columns = Int((size.width + HeatmapMetrics.gap) / step)
                for column in 0..<min(columns, weeks) {
                    for row in 0..<7 {
                        let rect = CGRect(x: CGFloat(column) * step, y: CGFloat(row) * step,
                                          width: HeatmapMetrics.cell, height: HeatmapMetrics.cell)
                        context.fill(Path(roundedRect: rect, cornerRadius: HeatmapMetrics.corner),
                                     with: .color(Skeleton.fill))
                    }
                }
            }
            .frame(height: 7 * (HeatmapMetrics.cell + HeatmapMetrics.gap) - HeatmapMetrics.gap)
            .padding(.top, HeatmapMetrics.monthRow)
            .shimmer()
        }
        .skeletonLoadingLabel()
    }
}
