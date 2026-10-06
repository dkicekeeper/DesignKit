//
//  CalendarRange.swift
//  DesignKit
//
//  The pages MonthCalendar can show (weeks around today, months ahead) and the date logic
//  behind its week/month toggle. Plain values, so the app can compute what it puts on the
//  calendar (occurrences, totals) over the same periods, and the logic is unit-tested.
//

import Foundation

/// A week or a month the calendar shows.
public struct CalendarPeriod: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case week
        case month
    }

    public let kind: Kind
    /// From the first day at 00:00 up to the next period's start (not included).
    public let interval: DateInterval

    public init(kind: Kind, interval: DateInterval) {
        self.kind = kind
        self.interval = interval
    }

    /// `interval` ending one second before the next period, for APIs that test `date <= end`.
    public var closedInterval: DateInterval {
        DateInterval(start: interval.start, end: interval.end.addingTimeInterval(-1))
    }
}

/// Weeks and months for `MonthCalendar`, anchored on today.
///
/// ```swift
/// @State private var range = CalendarRange()   // 8 weeks back, 47 ahead, 12 months
/// let byDay = range.itemsByDay(subscriptions) { sub, interval in sub.occurrences(in: interval) }
/// ```
///
/// Keep it in `@State`: it is computed once, and the calendar keeps its page indices in it.
public struct CalendarRange: Sendable {
    public let calendar: Calendar
    /// Start of the day the range is anchored on.
    public let today: Date
    public let weeks: [CalendarPeriod]
    public let months: [CalendarPeriod]
    /// Index in `weeks` of the week containing `today`.
    public let todayWeekIndex: Int

    /// - Parameters:
    ///   - weeksBefore / weeksAfter: weeks around today's week the strip can swipe to.
    ///   - monthCount: months from the current one the expanded view can swipe to.
    public init(
        today: Date = Date(),
        weeksBefore: Int = 8,
        weeksAfter: Int = 47,
        monthCount: Int = 12,
        calendar: Calendar = .current
    ) {
        let day = calendar.startOfDay(for: today)
        self.calendar = calendar
        self.today = day

        let weekday = calendar.component(.weekday, from: day)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        let thisWeek = calendar.date(byAdding: .day, value: -offset, to: day) ?? day
        let before = max(0, weeksBefore)
        weeks = (-before...max(0, weeksAfter)).compactMap { index in
            guard let start = calendar.date(byAdding: .weekOfYear, value: index, to: thisWeek),
                  let end = calendar.date(byAdding: .day, value: 7, to: start)
            else { return nil }
            return CalendarPeriod(kind: .week, interval: DateInterval(start: start, end: end))
        }
        todayWeekIndex = min(before, max(0, weeks.count - 1))

        let firstMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: day)) ?? day
        months = (0..<max(1, monthCount)).compactMap { index in
            guard let start = calendar.date(byAdding: .month, value: index, to: firstMonth),
                  let end = calendar.date(byAdding: .month, value: 1, to: start)
            else { return nil }
            return CalendarPeriod(kind: .month, interval: DateInterval(start: start, end: end))
        }
    }

    /// Everything the calendar can show: the first week's start to the last page's end.
    public var interval: DateInterval {
        let start = min(weeks.first?.interval.start ?? today, months.first?.interval.start ?? today)
        let end = max(weeks.last?.interval.end ?? today, months.last?.interval.end ?? today)
        return DateInterval(start: start, end: end)
    }

    /// Groups items by the days they fall on. Keys are the start of each day, which is how
    /// `MonthCalendar` looks them up.
    ///
    /// - Parameter dates: the dates of one item inside the given interval (`interval`).
    public func itemsByDay<Item>(
        _ items: [Item],
        dates: (Item, DateInterval) -> [Date]
    ) -> [Date: [Item]] {
        let span = interval
        var result: [Date: [Item]] = [:]
        for item in items {
            for date in dates(item, span) {
                result[calendar.startOfDay(for: date), default: []].append(item)
            }
        }
        return result
    }

    // MARK: - Week / month toggle

    /// Week to show when the month view collapses.
    ///
    /// Keeps the shown week when it already falls inside the displayed month, so
    /// expand → collapse on the same month changes nothing. Only when the person swiped to a
    /// different month does it re-anchor: to today's week if that month is the current one,
    /// otherwise to the week of the month's first day. (Tenra bug: collapsing the current month
    /// used to jump from "29 Jun – 5 Jul" to "1 Jun – 7 Jun".)
    func collapsedWeekIndex(displayedMonth: Date, currentWeekIndex: Int) -> Int {
        guard weeks.indices.contains(currentWeekIndex) else { return currentWeekIndex }
        if calendar.isDate(weeks[currentWeekIndex].interval.start, equalTo: displayedMonth, toGranularity: .month) {
            return currentWeekIndex
        }
        let anchor = calendar.isDate(displayedMonth, equalTo: today, toGranularity: .month)
            ? today
            : displayedMonth
        return weeks.firstIndex { $0.interval.start <= anchor && anchor < $0.interval.end } ?? currentWeekIndex
    }

    /// Month to show when the week strip expands: the one containing the week's first day.
    func monthIndex(forWeek weekIndex: Int) -> Int? {
        guard weeks.indices.contains(weekIndex) else { return nil }
        let start = weeks[weekIndex].interval.start
        return months.firstIndex { calendar.isDate($0.interval.start, equalTo: start, toGranularity: .month) }
    }

    /// Days of a month laid out from the week's first day: `nil` for the leading blanks.
    func gridDays(of month: CalendarPeriod) -> [Date?] {
        let first = month.interval.start
        guard let count = calendar.range(of: .day, in: .month, for: first)?.count else { return [] }
        let weekday = calendar.component(.weekday, from: first)
        let blanks = (weekday - calendar.firstWeekday + 7) % 7
        let days: [Date?] = (0..<count).map { calendar.date(byAdding: .day, value: $0, to: first) }
        return Array(repeating: nil, count: blanks) + days
    }

    /// The seven days of a week.
    func days(of week: CalendarPeriod) -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.interval.start) }
    }

    /// One-letter weekday names starting from the calendar's first weekday.
    var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }
}
