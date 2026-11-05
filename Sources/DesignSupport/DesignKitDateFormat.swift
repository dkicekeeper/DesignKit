//
//  DesignKitDateFormat.swift
//  DesignKit
//
//  How a date reads is an app setting (Tenra: Settings > Formats). DesignKit asks the host for
//  the text of a day; with no hook set every label reads as before.
//

import Foundation

public enum DesignKitDateFormat {
    /// App-provided day text: `(date, includeYear) -> "3 ноября 2026"`, `"03.11.2026"`, …
    /// `MonthCalendar`'s week label ("3 нояб. – 9 нояб.", no year) and `DateRangePickerSheet`'s
    /// period and boundary fields (with the year) use it. `nil` keeps the locale's own format.
    public nonisolated(unsafe) static var day: (@Sendable (_ date: Date, _ includeYear: Bool) -> String)?
}
