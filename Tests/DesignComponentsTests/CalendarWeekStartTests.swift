//
//  CalendarWeekStartTests.swift
//  DesignKit
//
//  The calendar follows the first weekday the app passes in its Calendar, and the week label
//  takes its dates from DesignKitDateFormat.day when the app sets it.
//

import Testing
import Foundation
import DesignSupport
@testable import DesignComponents

@Suite("CalendarWeekStart", .serialized)
struct CalendarWeekStartTests {

    private func calendar(firstWeekday: Int) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = firstWeekday
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ c: Calendar, _ y: Int, _ m: Int, _ d: Int) -> Date {
        c.date(from: DateComponents(year: y, month: m, day: d))!
    }

    @Test func weekStartsOnSunday() {
        let c = calendar(firstWeekday: 1)
        let range = CalendarRange(today: date(c, 2026, 11, 5), calendar: c)
        #expect(range.weeks[range.todayWeekIndex].interval.start == date(c, 2026, 11, 1))
    }

    @Test func weekdayHeaderFollowsCalendar() {
        let sunday = calendar(firstWeekday: 1)
        let monday = calendar(firstWeekday: 2)
        let a = CalendarRange(today: date(sunday, 2026, 11, 5), calendar: sunday).weekdaySymbols
        let b = CalendarRange(today: date(monday, 2026, 11, 5), calendar: monday).weekdaySymbols
        #expect(a.first == sunday.veryShortStandaloneWeekdaySymbols[0])
        #expect(b.first == monday.veryShortStandaloneWeekdaySymbols[1])
        #expect(a != b)
    }

    @Test func dayHookIsUsed() {
        let c = calendar(firstWeekday: 2)
        let range = CalendarRange(today: date(c, 2026, 11, 5), calendar: c)
        let week = range.weeks[range.todayWeekIndex]
        DesignKitDateFormat.day = { date, includeYear in "D\(Int(date.timeIntervalSince1970))/\(includeYear)" }
        defer { DesignKitDateFormat.day = nil }
        let start = week.interval.start
        let end = c.date(byAdding: .day, value: 6, to: start)!
        #expect(CalendarText.weekRange(week, calendar: c)
            == "D\(Int(start.timeIntervalSince1970))/false – D\(Int(end.timeIntervalSince1970))/false")
    }
}
