//
//  DisplaySnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Badges, stat tiles, avatars, rating, timeline, calendar, expandable text, flow layout.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Display")
    struct Display {
        @Test func badges() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.sm) {
                        Badge("New")
                        Badge("Ban", systemImage: "nosign", color: AppColors.destructive)
                        Badge("Filled", color: AppColors.success, style: .filled)
                    }
                    HStack(spacing: AppSpacing.md) {
                        TrendBadge(direction: .up, changePercent: 12.5)
                        TrendBadge(direction: .down, changePercent: -3.2, style: .inline)
                        TrendBadge(direction: .flat, changePercent: 0, style: .changeIndicator)
                        StatusIndicatorBadge(status: .active)
                        StatusIndicatorBadge(status: .paused)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func statTilesAvatarsRating() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    HStack(spacing: AppSpacing.md) {
                        StatTile(title: "Distance", value: "12.4 km", systemImage: "figure.hiking")
                        StatTile(title: "Catches", value: "7", valueColor: AppColors.success)
                    }
                    HStack(spacing: AppSpacing.md) {
                        Avatar(name: "Ayan Seitkali")
                        Avatar(name: "Dana", size: 56, tint: AppColors.success)
                        Avatar(name: nil)
                        AvatarGroup(names: ["Ayan", "Dana", "Marat", "Aru", "Timur", "Saule"], size: 32)
                    }
                    HStack(spacing: AppSpacing.lg) {
                        Rating(rating: 4.3)
                        Rating(rating: 2.5, size: 20)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func activityTimeline() async {
            await assertComponentSnapshot(
                ActivityTimeline(TimelineSample.events) { event in
                    TimelineMarker(systemImage: event.symbol, color: event.color)
                } content: { event in
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(verbatim: event.title)
                            .font(AppTypography.bodyEmphasis)
                        Text(verbatim: event.detail)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        /// Fixed day (Wednesday 17 June 2026, weeks from Monday) so the strip never moves.
        @Test func monthCalendar() async {
            var calendar = Calendar(identifier: .gregorian)
            calendar.firstWeekday = 2
            calendar.locale = Locale(identifier: "en_US")
            let today = calendar.date(from: DateComponents(year: 2026, month: 6, day: 17))!
            let range = CalendarRange(today: today, calendar: calendar)
            let byDay = range.itemsByDay(CalendarSample.items) { item, _ in
                [calendar.date(from: DateComponents(year: 2026, month: 6, day: item.day))!]
            }

            await assertComponentSnapshot(
                MonthCalendar(range: range, itemsByDay: byDay, itemName: { $0.name }) { item in
                    Image(systemName: item.symbol)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.staticWhite)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(item.color)
                } accessory: { period in
                    Badge(period.kind == .week ? "Week" : "Month")
                }
            )
        }

        @Test func textAndFlow() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ExpandableText(
                        "Great spot for pike in the early morning. The road is rough after rain, a 4x4 is better. Camping is allowed on the north shore; bring your own firewood.",
                        lineLimit: 2
                    )
                    FlowLayout {
                        ForEach(["Lake", "Free camping", "Fire allowed", "No motorboats", "Pike", "Road: 4x4", "Toilets"], id: \.self) { tag in
                            Badge(tag)
                        }
                    }
                    HStack(spacing: AppSpacing.lg) {
                        HeroSymbol(systemImage: "bell.badge", size: 72)
                        HeroSymbol(systemImage: "location", size: 72, tint: AppColors.success)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }
    }
}

private struct TimelineSample: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let symbol: String?
    let color: Color?

    static let events = [
        TimelineSample(id: 1, title: "Left Almaty", detail: "06:10", symbol: "car.fill", color: nil),
        TimelineSample(id: 2, title: "Check-in: Big Almaty Lake", detail: "08:45 · clear, 12 °C", symbol: "mappin", color: .green),
        TimelineSample(id: 3, title: "Caught a pike, 2.1 kg", detail: "10:20 · released", symbol: "fish.fill", color: .teal),
        TimelineSample(id: 4, title: "Back home", detail: "19:30", symbol: nil, color: .gray),
    ]
}

private struct CalendarSample: Identifiable {
    let id: Int
    let name: String
    let day: Int
    let symbol: String
    let color: Color

    static let items = [
        CalendarSample(id: 1, name: "Netflix", day: 18, symbol: "play.fill", color: .red),
        CalendarSample(id: 2, name: "Spotify", day: 18, symbol: "music.note", color: .green),
        CalendarSample(id: 3, name: "Rent", day: 20, symbol: "house.fill", color: .blue),
        CalendarSample(id: 4, name: "Gym", day: 18, symbol: "dumbbell.fill", color: .orange),
        CalendarSample(id: 5, name: "Cloud", day: 18, symbol: "cloud.fill", color: .cyan),
    ]
}
