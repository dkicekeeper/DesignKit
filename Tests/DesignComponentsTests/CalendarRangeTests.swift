//
//  CalendarRangeTests.swift
//  DesignKit
//
//  The pages of MonthCalendar and its week/month toggle. The collapse cases moved from
//  Tenra's SubscriptionCalendarSyncTests with the calendar (0.7.0), including the regression
//  where collapsing the current month jumped today's week to the month's first week.
//

import Testing
import Foundation
@testable import DesignComponents

@Suite("CalendarRange")
struct CalendarRangeTests {

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2 // Monday
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d))!
    }

    /// Tuesday 30 June 2026: its week starts on Monday 29 June.
    private var range: CalendarRange {
        CalendarRange(today: date(2026, 6, 30), calendar: calendar)
    }

    @Test("8 weeks back, today's week, 47 ahead; 12 months from the current one")
    func pages() {
        let r = range
        #expect(r.weeks.count == 56)
        #expect(r.todayWeekIndex == 8)
        #expect(r.weeks[8].interval.start == date(2026, 6, 29))
        #expect(r.weeks[8].interval.end == date(2026, 7, 6))
        #expect(r.months.count == 12)
        #expect(r.months[0].interval.start == date(2026, 6, 1))
        #expect(r.months[0].interval.end == date(2026, 7, 1))
        #expect(r.months[11].interval.start == date(2027, 5, 1))
    }

    @Test("Month grid starts with blanks up to the first weekday")
    func gridDays() {
        // 1 June 2026 is a Monday: no blanks. 1 July is a Wednesday: two blanks.
        let r = range
        let june = r.gridDays(of: r.months[0])
        #expect(june.count == 30)
        #expect(june.first! == date(2026, 6, 1))
        let july = r.gridDays(of: r.months[1])
        #expect(july.count == 33)
        #expect(july[0] == nil && july[1] == nil)
        #expect(july[2] == date(2026, 7, 1))
    }

    @Test("Weekday symbols start on the calendar's first weekday")
    func weekdaySymbols() {
        let symbols = range.weekdaySymbols
        #expect(symbols.count == 7)
        #expect(symbols.first == calendar.veryShortStandaloneWeekdaySymbols[1]) // Monday
    }

    @Test("Items are keyed by the start of their day")
    func itemsByDay() {
        struct Item { let name: String; let dates: [Date] }
        let noon = date(2026, 7, 3).addingTimeInterval(12 * 3600)
        let items = [Item(name: "a", dates: [noon]), Item(name: "b", dates: [date(2026, 7, 3)])]
        let byDay = range.itemsByDay(items) { item, _ in item.dates }
        #expect(byDay[date(2026, 7, 3)]?.map(\.name) == ["a", "b"])
    }

    @Test("Collapsing the current month keeps today's week (the Tenra bug)")
    func keepsTodaysWeekOnCurrentMonth() {
        #expect(range.collapsedWeekIndex(displayedMonth: date(2026, 6, 1), currentWeekIndex: 8) == 8)
    }

    @Test("Collapsing after swiping to another month anchors to that month's first week")
    func anchorsToFirstWeekOfSwipedMonth() {
        let r = range
        let index = r.collapsedWeekIndex(displayedMonth: date(2026, 8, 1), currentWeekIndex: 8)
        let week = r.weeks[index].interval
        #expect(week.start <= date(2026, 8, 1) && date(2026, 8, 1) < week.end)
    }

    @Test("A week already inside the displayed month is kept")
    func preservesWeekAlreadyInMonth() {
        // Index 6 = two weeks before today's week: 15 June.
        #expect(range.collapsedWeekIndex(displayedMonth: date(2026, 6, 1), currentWeekIndex: 6) == 6)
    }

    @Test("Out-of-range index is returned unchanged")
    func outOfRangeIsSafe() {
        #expect(range.collapsedWeekIndex(displayedMonth: date(2026, 6, 1), currentWeekIndex: 999) == 999)
    }

    @Test("Expanding opens the month of the week's first day")
    func monthForWeek() {
        let r = range
        #expect(r.monthIndex(forWeek: 8) == 0)       // 29 June → June
        #expect(r.monthIndex(forWeek: 9) == 1)       // 6 July → July
        #expect(r.monthIndex(forWeek: 0) == nil)     // early May: before the first month
    }
}
