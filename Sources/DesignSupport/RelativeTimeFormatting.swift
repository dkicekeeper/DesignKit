//
//  RelativeTimeFormatting.swift
//  DesignKit
//
//  When something happened, the way a person says it (8.9.0, benchmark round 4: Astryx's
//  Timestamp and Timer): "Just now", "5 min ago", "3 hr ago", "Yesterday, 14:20", then the day.
//  And how long something has run: "42 sec", "5 min", "1 hr, 2 min", or a clock "1:02:34".
//  `RelativeTime` shows them and keeps them current; these are the texts.
//

import Foundation

public extension Formatting {
    /// How the units of a relative time or a duration are written.
    enum TimeUnitsStyle: Sendable {
        /// "5 min. ago", "1 hr, 2 min": for the screen.
        case abbreviated
        /// "5 minutes ago", "1 hour, 2 minutes": for VoiceOver.
        case full
    }

    /// When `date` was (or will be), seen from `now`:
    ///
    /// | How far | Reads |
    /// |---|---|
    /// | under a minute | "Just now" (key `time.justNow`) |
    /// | under an hour | "5 min ago", "in 10 min" |
    /// | the same day | "3 hr ago", "in 2 hr" |
    /// | the day before or after | "Yesterday, 14:20", "Tomorrow, 09:00" (key `time.dayAndTime`) |
    /// | earlier or later | the day: "3 Nov", "3 Nov 2025" in another year |
    ///
    /// The day comes from the `DesignKitDateFormat.day` hook when the app sets it (`day:`), so it
    /// reads as the app's other dates do.
    static func relativeTime(
        _ date: Date,
        now: Date = .now,
        unitsStyle: TimeUnitsStyle = .abbreviated,
        calendar: Calendar = .current,
        locale: Locale = .current,
        day: (@Sendable (_ date: Date, _ includeYear: Bool) -> String)? = DesignKitDateFormat.day
    ) -> String {
        let seconds = date.timeIntervalSince(now)
        if abs(seconds) < 60 {
            return String(localized: "time.justNow", defaultValue: "Just now")
        }

        let relative = RelativeDateTimeFormatter()
        relative.locale = locale
        relative.calendar = calendar
        relative.unitsStyle = unitsStyle == .full ? .full : .short
        relative.dateTimeStyle = .numeric
        relative.formattingContext = .beginningOfSentence

        if abs(seconds) < 3600 || calendar.isDate(date, inSameDayAs: now) {
            return relative.localizedString(for: date, relativeTo: now)
        }

        let startOfToday = calendar.startOfDay(for: now)
        let startOfDay = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startOfToday, to: startOfDay).day ?? 0
        if abs(days) == 1 {
            relative.dateTimeStyle = .named
            let dayWord = relative.localizedString(from: DateComponents(day: days))
            let time = date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar,
                                                         timeZone: calendar.timeZone))
            return String(localized: "time.dayAndTime", defaultValue: "\(dayWord), \(time)")
        }

        let includeYear = !calendar.isDate(date, equalTo: now, toGranularity: .year)
        if let day {
            return day(date, includeYear)
        }
        var style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .day().month(.abbreviated)
        if includeYear {
            style = style.year()
        }
        return date.formatted(style)
    }

    /// How long something has run: "42 sec" under a minute, "5 min" under an hour, "1 hr, 2 min"
    /// past it (`.abbreviated`), or "42 seconds", "1 hour, 2 minutes" (`.full`).
    static func elapsedTime(
        _ interval: TimeInterval,
        unitsStyle: TimeUnitsStyle = .abbreviated,
        locale: Locale = .current
    ) -> String {
        let seconds = max(0, interval.rounded(.down))
        let formatter = DateComponentsFormatter()
        var calendar = Calendar.current
        calendar.locale = locale
        formatter.calendar = calendar
        formatter.unitsStyle = unitsStyle == .full ? .full : .short
        formatter.zeroFormattingBehavior = .dropAll
        switch seconds {
        case ..<60: formatter.allowedUnits = [.second]
        case ..<3600: formatter.allowedUnits = [.minute]
        default: formatter.allowedUnits = [.hour, .minute]
        }
        // `.dropAll` leaves nothing for zero seconds; "0 sec" then.
        if seconds < 1 {
            formatter.zeroFormattingBehavior = .default
        }
        return formatter.string(from: seconds) ?? ""
    }

    /// A running clock: "0:42", "12:05", "1:02:34" (minutes and seconds, hours once there are
    /// any).
    static func clockTime(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval.rounded(.down)))
        let hours = total / 3600
        let minutes = total % 3600 / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
