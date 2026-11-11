//
//  RelativeTime.swift
//  DesignKit
//
//  A time that stays current on screen (8.9.0, benchmark round 4: Astryx's Timestamp and Timer).
//  "5 min. ago" becomes "6 min. ago" a minute later without the screen asking; a running session
//  counts up. Dalada's comments, threads, reviews and session bar, Tenra's history and backups.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// When something happened, or how long it has run, kept current.
///
/// ```swift
/// RelativeTime(comment.createdAt)                          // "Just now", "5 min. ago", "Yesterday, 14:20", "3 Nov"
/// RelativeTime(session.startedAt, style: .elapsed)         // "42 sec", "5 min", "1 hr, 2 min"
/// RelativeTime(session.startedAt, style: .clock)           // "0:42", "1:02:34"
///     .font(AppTypography.numbers(AppTypography.h3))
/// ```
///
/// Style it as text (`.font`, `.foregroundStyle`); `.clock` keeps its digits one width so the
/// count does not jitter. `.relative` redraws every 30 seconds, `.elapsed` and `.clock` every
/// second. VoiceOver reads the units in full ("5 minutes ago"); a long press on iPad or Mac shows
/// the full date. The texts are `Formatting.relativeTime(_:)`, `.elapsedTime(_:)` and
/// `.clockTime(_:)`; the day of an older date follows the `DesignKitDateFormat.day` hook.
/// Strings: `time.justNow`, `time.dayAndTime`. It formats a date the caller already has, so it has
/// no skeleton: a skeleton of the row it stands in uses `SkeletonText`.
public struct RelativeTime: View {
    /// What the time says.
    public enum Style: Hashable, Sendable {
        /// When it happened: "5 min. ago", "Yesterday, 14:20", "3 Nov".
        case relative
        /// How long since: "42 sec", "5 min", "1 hr, 2 min".
        case elapsed
        /// A running clock since: "0:42", "1:02:34".
        case clock
    }

    let date: Date
    let style: Style

    /// - Parameters:
    ///   - date: When it happened (`.relative`) or started (`.elapsed`, `.clock`).
    public init(_ date: Date, style: Style = .relative) {
        self.date = date
        self.style = style
    }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: style == .relative ? RelativeTimeMetrics.relativeRefresh : 1)) { context in
            text(at: context.date)
                .accessibilityLabel(Text(verbatim: spoken(at: context.date)))
        }
        .help(Text(date.formatted(date: .long, time: .shortened)))
    }

    @ViewBuilder
    private func text(at now: Date) -> some View {
        switch style {
        case .relative:
            Text(verbatim: Formatting.relativeTime(date, now: now))
        case .elapsed:
            Text(verbatim: Formatting.elapsedTime(now.timeIntervalSince(date)))
        case .clock:
            Text(verbatim: Formatting.clockTime(now.timeIntervalSince(date)))
                .monospacedDigit()
        }
    }

    private func spoken(at now: Date) -> String {
        switch style {
        case .relative:
            Formatting.relativeTime(date, now: now, unitsStyle: .full)
        case .elapsed, .clock:
            Formatting.elapsedTime(now.timeIntervalSince(date), unitsStyle: .full)
        }
    }
}

enum RelativeTimeMetrics {
    /// How often a relative time redraws: often enough that "5 min. ago" is never two minutes
    /// stale.
    static let relativeRefresh: TimeInterval = 30
}
