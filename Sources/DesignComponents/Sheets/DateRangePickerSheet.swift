//
//  DateRangePickerSheet.swift
//  DesignKit
//
//  A period of days picked on a calendar, in a sheet (2.9.0). For a custom period of a filter,
//  a trip's dates. Ported from Tenra's CustomPeriodPickerSheet; the filter it sets stays in
//  Tenra.
//
//  5.2.0: one calendar of DesignKit's own in place of the system's two, which could neither show
//  the period nor say which one was picked. The period is written on top ("Sep 12 – Oct 3, 2026",
//  "22 days") over a field for each end, the one the next tap sets outlined; on the calendar the
//  ends are filled circles in the accent and the days between them lie on a pale band. A tap
//  sets "From", the next one "To"; months turn with the arrows.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A calendar for a range of days, in a sheet.
///
/// ```swift
/// .sheet(isPresented: $picking) {
///     DateRangePickerSheet(range: filter.range) { range in
///         filter.setCustomRange(range)
///         picking = false
///     }
/// }
/// ```
///
/// The first tap sets the start (and makes the period that one day), the next sets the end; a
/// day before the start becomes the start instead. Tapping a field on top picks which end the
/// next tap sets. Apply hands the range to `onApply`, both ends at the start of their day;
/// Cancel dismisses.
public struct DateRangePickerSheet: View {
    let title: String
    let fromTitle: String
    let toTitle: String
    let onApply: (ClosedRange<Date>) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var environmentCalendar
    @Environment(\.locale) private var locale
    @State private var range: ClosedRange<Date>
    @State private var editing: DateRangeEnd = .start
    /// Any day of the month the calendar shows.
    @State private var month: Date

    /// - Parameters:
    ///   - range: The period the sheet opens on; the calendar shows its first month.
    ///   - title, fromTitle, toTitle: The sheet's title and each end's label.
    public init(
        range: ClosedRange<Date>,
        title: String = String(localized: "timeFilter.customPeriod", defaultValue: "Custom period"),
        fromTitle: String = String(localized: "timeFilter.from", defaultValue: "From"),
        toTitle: String = String(localized: "timeFilter.to", defaultValue: "To"),
        onApply: @escaping (ClosedRange<Date>) -> Void
    ) {
        self.title = title
        self.fromTitle = fromTitle
        self.toTitle = toTitle
        self.onApply = onApply
        self._range = State(initialValue: range)
        self._month = State(initialValue: range.lowerBound)
    }

    private var calendar: Calendar {
        var calendar = environmentCalendar
        calendar.locale = locale
        return calendar
    }

    /// The period in whole days.
    private var days: ClosedRange<Date> {
        calendar.startOfDay(for: range.lowerBound)...calendar.startOfDay(for: range.upperBound)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    DateRangeSummary(
                        range: days,
                        editing: $editing,
                        fromTitle: fromTitle,
                        toTitle: toTitle,
                        calendar: calendar,
                        locale: locale
                    )
                    DateRangeCalendar(range: $range, editing: $editing, month: $month, calendar: calendar, locale: locale)
                }
                .screenPadding()
                .padding(.vertical, AppSpacing.md)
            }
            .navigationTitle(Text(verbatim: title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.apply", defaultValue: "Apply")) {
                        onApply(days)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

/// Which end of the period the next tap on the calendar sets.
enum DateRangeEnd: Hashable {
    case start, end
}

// MARK: - Summary

/// "Sep 12 – Oct 3, 2026 · 22 days" over the two ends, the one the next tap sets outlined.
private struct DateRangeSummary: View {
    let range: ClosedRange<Date>
    @Binding var editing: DateRangeEnd
    let fromTitle: String
    let toTitle: String
    let calendar: Calendar
    let locale: Locale

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            VStack(spacing: AppSpacing.xxs) {
                Text(verbatim: periodText)
                    .font(AppTypography.h3)
                    .foregroundStyle(AppColors.Text.primary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())
                Text(verbatim: lengthText)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            HStack(spacing: AppSpacing.sm) {
                field(.start, title: fromTitle, date: range.lowerBound)
                field(.end, title: toTitle, date: range.upperBound)
            }
        }
        .animation(AppAnimation.snappy, value: range)
        .animation(AppAnimation.snappy, value: editing)
    }

    private func field(_ end: DateRangeEnd, title: String, date: Date) -> some View {
        let isEditing = editing == end
        return Button {
            HapticManager.selection()
            editing = end
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(verbatim: title)
                    .font(AppTypography.caption)
                    .foregroundStyle(isEditing ? AppColors.accent : AppColors.Text.secondary)
                Text(verbatim: date.formatted(.dateTime.day().month(.abbreviated).year().locale(locale)))
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.Background.neutral1, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .selectionOutline(isEditing, cornerRadius: AppRadius.md)
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isEditing ? .isSelected : [])
    }

    /// "Sep 12 – Oct 3, 2026", or one day.
    private var periodText: String {
        let style = Date.IntervalFormatStyle(date: .abbreviated, time: .omitted, locale: locale, calendar: calendar)
        if range.lowerBound == range.upperBound {
            return range.lowerBound.formatted(.dateTime.day().month(.abbreviated).year().locale(locale))
        }
        return (range.lowerBound..<range.upperBound).formatted(style)
    }

    /// "22 days", in the locale's words.
    private var lengthText: String {
        let count = (calendar.dateComponents([.day], from: range.lowerBound, to: range.upperBound).day ?? 0) + 1
        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day]
        return formatter.string(from: DateComponents(day: count)) ?? "\(count)"
    }
}

// MARK: - Calendar

/// One month of days: the ends of the period in filled accent circles, the days between on a
/// pale band. A tap sets the end `editing` names.
struct DateRangeCalendar: View {
    @Binding var range: ClosedRange<Date>
    @Binding var editing: DateRangeEnd
    @Binding var month: Date
    let calendar: Calendar
    let locale: Locale
    var today: Date = Date()

    private var monthStart: Date {
        calendar.dateInterval(of: .month, for: month)?.start ?? calendar.startOfDay(for: month)
    }

    private var start: Date { calendar.startOfDay(for: range.lowerBound) }
    private var end: Date { calendar.startOfDay(for: range.upperBound) }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            header
            weekdayRow
            VStack(spacing: AppSpacing.xs) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                            if let day {
                                dayCell(day)
                            } else {
                                Color.clear.frame(height: DateRangeCalendarMetrics.cellHeight)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .animation(AppAnimation.snappy, value: range)
            .id(monthStart)
            .transition(.opacity)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(verbatim: monthTitle)
                .font(AppTypography.h4)
                .foregroundStyle(AppColors.Text.primary)
                .contentTransition(.numericText())
                .accessibilityAddTraits(.isHeader)
            Spacer()
            monthButton(step: -1, systemImage: "chevron.left",
                        label: String(localized: "pager.previous", defaultValue: "Previous"))
            monthButton(step: 1, systemImage: "chevron.right",
                        label: String(localized: "pager.next", defaultValue: "Next"))
        }
    }

    /// "October 2026", "Октябрь 2026": the month's own name (standalone) and the year.
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("LLLLyyyy")
        let text = formatter.string(from: monthStart)
        return text.prefix(1).uppercased(with: locale) + text.dropFirst()
    }

    private func monthButton(step: Int, systemImage: String, label: String) -> some View {
        DSButton(label, systemImage: systemImage, iconPlacement: .only, appearance: .flat, size: .small) {
            guard let next = calendar.date(byAdding: .month, value: step, to: monthStart) else { return }
            withAnimation(AppAnimation.smooth) { month = next }
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(verbatim: symbol)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.Text.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    /// The very short names from the calendar's first weekday on.
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// The month's days in weeks, `nil` before the first and after the last.
    private var weeks: [[Date?]] {
        guard let count = calendar.range(of: .day, in: .month, for: monthStart)?.count else { return [] }
        let leading = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<count {
            cells.append(calendar.date(byAdding: .day, value: offset, to: monthStart))
        }
        cells += Array(repeating: nil, count: (7 - cells.count % 7) % 7)
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }

    // MARK: Day

    private func dayCell(_ day: Date) -> some View {
        let isStart = day == start
        let isEnd = day == end
        let isEndpoint = isStart || isEnd
        let isInside = day > start && day < end
        let isToday = calendar.isDate(day, inSameDayAs: today)
        return Button {
            pick(day)
        } label: {
            Text(verbatim: "\(calendar.component(.day, from: day))")
                .font(isEndpoint || isToday ? AppTypography.bodyEmphasis : AppTypography.body)
                .monospacedDigit()
                .foregroundStyle(isEndpoint ? AppColors.Text.onAccent : (isToday ? AppColors.accent : AppColors.Text.primary))
                .frame(width: DateRangeCalendarMetrics.circle, height: DateRangeCalendarMetrics.circle)
                .background {
                    if isEndpoint {
                        Circle().fill(AppColors.accent)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: DateRangeCalendarMetrics.cellHeight)
                .background(band(isStart: isStart, isEnd: isEnd, isInside: isInside))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: day.formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(locale))))
        .accessibilityAddTraits(isEndpoint || isInside ? .isSelected : [])
    }

    /// The pale band under the period: the whole cell between the ends, half a cell towards the
    /// inside at each end, nothing for a one-day period.
    @ViewBuilder
    private func band(isStart: Bool, isEnd: Bool, isInside: Bool) -> some View {
        let fill = AppColors.pale(AppColors.accent)
        let height = DateRangeCalendarMetrics.circle
        if isInside {
            fill.frame(height: height)
        } else if isStart != isEnd {
            HStack(spacing: 0) {
                if isStart { Color.clear }
                fill
                if isEnd { Color.clear }
            }
            .frame(height: height)
        }
    }

    /// The first tap sets the start (a one-day period), the next the end; a day before the start
    /// becomes the start.
    private func pick(_ day: Date) {
        HapticManager.selection()
        switch editing {
        case .start:
            range = day...day
            editing = .end
        case .end where day < start:
            // Earlier than the start: the period starts there, the end is still to pick.
            range = day...day
        case .end:
            range = start...day
            editing = .start
        }
    }
}

enum DateRangeCalendarMetrics {
    /// A day's circle, and the band's height.
    static let circle: CGFloat = 40
    /// A day's row.
    static let cellHeight: CGFloat = 44
}
