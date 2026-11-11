//
//  RelativeTimeFormattingTests.swift
//  DesignKit
//
//  Formatting.relativeTime / elapsedTime / clockTime (8.9.0): which form a time takes at each
//  distance. The words themselves are Foundation's, so the expectations compare with what its
//  formatters say for the same input instead of spelling English out.
//

import Foundation
import Testing
@testable import DesignSupport

struct RelativeTimeFormattingTests {
    private static let locale = Locale(identifier: "en_US")
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = locale
        return calendar
    }()
    /// Wednesday 11 November 2026, 15:00 UTC.
    private static let now = Date(timeIntervalSince1970: 1_794_409_200)

    private func relative(_ offset: TimeInterval, day: (@Sendable (Date, Bool) -> String)? = nil) -> String {
        Formatting.relativeTime(Self.now.addingTimeInterval(offset), now: Self.now,
                                calendar: Self.calendar, locale: Self.locale, day: day)
    }

    private func foundationRelative(_ offset: TimeInterval) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Self.locale
        formatter.calendar = Self.calendar
        formatter.unitsStyle = .short
        formatter.dateTimeStyle = .numeric
        formatter.formattingContext = .beginningOfSentence
        return formatter.localizedString(for: Self.now.addingTimeInterval(offset), relativeTo: Self.now)
    }

    @Test func underAMinuteIsJustNow() {
        #expect(relative(-30) == "Just now")
        #expect(relative(20) == "Just now")
    }

    @Test func underAnHourCountsMinutes() {
        #expect(relative(-5 * 60) == foundationRelative(-5 * 60))
        #expect(relative(10 * 60) == foundationRelative(10 * 60))
    }

    @Test func theSameDayCountsHours() {
        #expect(relative(-3 * 3600) == foundationRelative(-3 * 3600))
    }

    @Test func yesterdayAndTomorrowNameTheDayAndTheTime() {
        let yesterday = relative(-20 * 3600)   // 10 November, 19:00
        #expect(yesterday.hasPrefix("Yesterday, "))
        #expect(yesterday.contains("7:00"))
        let tomorrow = relative(20 * 3600)     // 12 November, 11:00
        #expect(tomorrow.hasPrefix("Tomorrow, "))
    }

    @Test func olderDatesAreTheDayWithTheYearOnlyInAnotherYear() {
        #expect(relative(-8 * 86_400) { _, includeYear in includeYear ? "with year" : "no year" } == "no year")
        #expect(relative(-400 * 86_400) { _, includeYear in includeYear ? "with year" : "no year" } == "with year")
        let lastWeek = relative(-8 * 86_400)
        #expect(lastWeek.contains("Nov"))
        #expect(lastWeek.contains("3"))
        #expect(!lastWeek.contains("2026"))
    }

    @Test func elapsedTimePicksTheUnitByLength() {
        let seconds = Formatting.elapsedTime(42, locale: Self.locale)
        #expect(seconds.contains("42"))
        #expect(!seconds.contains("min"))
        let minutes = Formatting.elapsedTime(5 * 60 + 12, locale: Self.locale)
        #expect(minutes.contains("5"))
        #expect(!minutes.contains("12"))
        let hours = Formatting.elapsedTime(3600 + 2 * 60, locale: Self.locale)
        #expect(hours.contains("1"))
        #expect(hours.contains("2"))
        #expect(!Formatting.elapsedTime(0, locale: Self.locale).isEmpty)
    }

    @Test func clockShowsHoursOnlyOnceThereAreAny() {
        #expect(Formatting.clockTime(42) == "0:42")
        #expect(Formatting.clockTime(12 * 60 + 5) == "12:05")
        #expect(Formatting.clockTime(3600 + 2 * 60 + 34) == "1:02:34")
        #expect(Formatting.clockTime(-5) == "0:00")
    }
}
