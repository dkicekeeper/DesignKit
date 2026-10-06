//
//  MonthCalendar.swift
//  DesignKit
//
//  Week strip that expands to a month grid, with markers on the days things happen. Moved
//  from Tenra's SubscriptionCalendarView (0.7.0): Tenra puts subscription logos and the
//  period's total on it, Dalada can put trips and fishing bans. The app decides what an
//  item is, how its marker looks and what the header shows for the visible period.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Card with a swipeable week strip; tapping the header expands it to swipeable months.
///
/// ```swift
/// @State private var range = CalendarRange()
/// @State private var byDay: [Date: [Trip]] = [:]
///
/// MonthCalendar(range: range, itemsByDay: byDay, itemName: \.title) { trip in
///     Image(systemName: "tent.fill").foregroundStyle(AppColors.accent)
/// } accessory: { period in
///     Text(verbatim: "\(count(in: period))")
/// }
/// .onAppear { byDay = range.itemsByDay(trips) { trip, _ in trip.days } }
/// ```
///
/// Markers are drawn `AppIconSize.md` in a circle, up to `maxMarkers` per day, then "+N".
/// VoiceOver reads each day as its date and the names of its items.
public struct MonthCalendar<Item: Identifiable, Marker: View, Accessory: View>: View {
    let range: CalendarRange
    let itemsByDay: [Date: [Item]]
    let maxMarkers: Int
    let itemName: (Item) -> String
    let marker: (Item) -> Marker
    let accessory: (CalendarPeriod) -> Accessory

    @State private var isExpanded = false
    @State private var monthIndex = 0
    @State private var weekIndex: Int

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private static var cellHeight: CGFloat { 80 }

    /// - Parameters:
    ///   - itemsByDay: items keyed by the start of their day (`CalendarRange.itemsByDay`).
    ///   - itemName: what VoiceOver reads for an item.
    ///   - marker: the item's mark on its day, e.g. a logo or a symbol.
    ///   - accessory: trailing header content for the visible week or month, e.g. a total.
    public init(
        range: CalendarRange,
        itemsByDay: [Date: [Item]],
        maxMarkers: Int = 3,
        itemName: @escaping (Item) -> String,
        @ViewBuilder marker: @escaping (Item) -> Marker,
        @ViewBuilder accessory: @escaping (CalendarPeriod) -> Accessory
    ) {
        self.range = range
        self.itemsByDay = itemsByDay
        self.maxMarkers = max(1, maxMarkers)
        self.itemName = itemName
        self.marker = marker
        self.accessory = accessory
        _weekIndex = State(initialValue: range.todayWeekIndex)
    }

    private var calendar: Calendar { range.calendar }

    private var visiblePeriod: CalendarPeriod? {
        if isExpanded {
            return range.months.indices.contains(monthIndex) ? range.months[monthIndex] : nil
        }
        return range.weeks.indices.contains(weekIndex) ? range.weeks[weekIndex] : nil
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            header
            weekdayRow
            pages
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: AppSpacing.sm) {
            Group {
                if isExpanded {
                    // Tapping the month name returns to the current month.
                    Button {
                        withAnimation(AppAnimation.contentSpring) { monthIndex = 0 }
                    } label: {
                        title
                    }
                    .buttonStyle(.plain)
                } else {
                    title
                }
            }
            .animation(.easeInOut(duration: AppAnimation.standard), value: isExpanded)

            Spacer()

            if let period = visiblePeriod {
                accessory(period)
                    .animation(.easeInOut(duration: AppAnimation.standard), value: isExpanded)
            }

            Image(systemName: "chevron.down")
                .font(AppTypography.bodySmall.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .animation(AppAnimation.contentSpring, value: isExpanded)
                .accessibilityHidden(true)
        }
        .padding(.vertical, AppSpacing.sm)
        .contentShape(Rectangle())
        .onTapGesture { toggleExpanded() }
        .accessibilityAction(named: Text(isExpanded
            ? String(localized: "calendar.showWeek", defaultValue: "Show week")
            : String(localized: "calendar.showMonth", defaultValue: "Show month"))) {
            toggleExpanded()
        }
    }

    private var title: some View {
        Text(verbatim: titleText)
            .font(AppTypography.h4)
            .foregroundStyle(AppColors.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private var titleText: String {
        guard let period = visiblePeriod else { return "" }
        switch period.kind {
        case .month: return CalendarText.monthYear(period.interval.start)
        case .week: return CalendarText.weekRange(period, calendar: calendar)
        }
    }

    // MARK: - Weekday names

    private var weekdayRow: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(range.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(verbatim: symbol)
                    .font(AppTypography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(height: 20)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Pages

    @ViewBuilder
    private var pages: some View {
        if isExpanded {
            TabView(selection: $monthIndex) {
                ForEach(Array(range.months.enumerated()), id: \.offset) { index, month in
                    monthGrid(month)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: AppAnimation.standard), value: monthIndex)
            .frame(height: monthHeight)
            .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
        } else {
            TabView(selection: $weekIndex) {
                ForEach(Array(range.weeks.enumerated()), id: \.offset) { index, week in
                    weekRow(week)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: Self.cellHeight + AppSpacing.md)
            .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
        }
    }

    private func weekRow(_ week: CalendarPeriod) -> some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.xs) {
            ForEach(range.days(of: week), id: \.self) { day in
                dayCell(day)
            }
        }
        .padding(.top, AppSpacing.md)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func monthGrid(_ month: CalendarPeriod) -> some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.xs) {
            ForEach(Array(range.gridDays(of: month).enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear
                        .frame(height: Self.cellHeight)
                }
            }
        }
        .padding(.top, AppSpacing.md)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    /// Grid rows × cell height, plus the row spacing and the top padding.
    private var monthHeight: CGFloat {
        guard range.months.indices.contains(monthIndex) else { return Self.cellHeight }
        let rows = ceil(Double(range.gridDays(of: range.months[monthIndex]).count) / 7)
        return Self.cellHeight * rows + AppSpacing.xs * max(0, rows - 1) + AppSpacing.md
    }

    // MARK: - Day

    private func dayCell(_ day: Date) -> some View {
        let isToday = calendar.isDate(day, inSameDayAs: range.today)
        let items = itemsByDay[calendar.startOfDay(for: day)] ?? []

        return VStack(spacing: AppSpacing.xs) {
            Text(verbatim: "\(calendar.component(.day, from: day))")
                .font(isToday ? AppTypography.body.weight(.semibold) : AppTypography.body)
                .foregroundStyle(isToday ? AppColors.accent : AppColors.textPrimary)
                .frame(width: 48, height: 48)
                .background(isToday ? AppColors.pale(AppColors.accent) : Color.clear)
                .clipShape(Circle())
                .animation(.easeInOut(duration: AppAnimation.fast), value: isToday)

            if items.isEmpty {
                Spacer().frame(height: AppIconSize.md)
            } else {
                HStack(spacing: -AppSpacing.xs) {
                    ForEach(items.prefix(maxMarkers)) { item in
                        marker(item)
                            .frame(width: AppIconSize.md, height: AppIconSize.md)
                            .background(Circle().fill(AppColors.bgBase))
                            .clipShape(Circle())
                            .transition(.scale(scale: AppAnimation.facepileHiddenScale).combined(with: .opacity))
                    }
                    if items.count > maxMarkers {
                        Text(verbatim: "+\(items.count - maxMarkers)")
                            .font(.system(size: AppIconSize.sm, weight: .bold))
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: AppIconSize.md, height: AppIconSize.md)
                            .background(Circle().fill(AppColors.bgCard))
                            .transition(.scale(scale: AppAnimation.facepileHiddenScale).combined(with: .opacity))
                    }
                }
                .animation(AppAnimation.contentSpring, value: items.count)
            }
        }
        .frame(height: Self.cellHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilityText(day, items)))
    }

    private func accessibilityText(_ day: Date, _ items: [Item]) -> String {
        let date = day.formatted(date: .long, time: .omitted)
        guard !items.isEmpty else { return date }
        return ([date] + items.map(itemName)).joined(separator: ", ")
    }

    // MARK: - Toggle

    private func toggleExpanded() {
        if isExpanded {
            // Collapsing: keep the week if it is inside the shown month, else re-anchor.
            if range.months.indices.contains(monthIndex) {
                weekIndex = range.collapsedWeekIndex(
                    displayedMonth: range.months[monthIndex].interval.start,
                    currentWeekIndex: weekIndex
                )
            }
        } else if let index = range.monthIndex(forWeek: weekIndex) {
            monthIndex = index
        }
        withAnimation(AppAnimation.gentleSpring) {
            isExpanded.toggle()
        }
    }
}

public extension MonthCalendar where Accessory == EmptyView {
    /// Calendar without header content for the visible period.
    init(
        range: CalendarRange,
        itemsByDay: [Date: [Item]],
        maxMarkers: Int = 3,
        itemName: @escaping (Item) -> String,
        @ViewBuilder marker: @escaping (Item) -> Marker
    ) {
        self.init(
            range: range,
            itemsByDay: itemsByDay,
            maxMarkers: maxMarkers,
            itemName: itemName,
            marker: marker,
            accessory: { _ in EmptyView() }
        )
    }
}

/// Header texts. Fixed formats (not templates) so the strip reads "1 Jun – 7 Jun" and the
/// month "June 2026" / "Июнь 2026" in every locale, as Tenra showed them.
private enum CalendarText {
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    private static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    static func monthYear(_ date: Date) -> String {
        monthYearFormatter.string(from: date).capitalized
    }

    static func weekRange(_ week: CalendarPeriod, calendar: Calendar) -> String {
        let start = week.interval.start
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        return "\(dayMonthFormatter.string(from: start)) – \(dayMonthFormatter.string(from: end))"
    }
}
