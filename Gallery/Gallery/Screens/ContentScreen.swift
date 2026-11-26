//
//  ContentScreen.swift
//  DesignKit Gallery
//
//  Content and layout: folded text, timeline, month calendar, flow layout, form sections, the
//  edit sheet and its hero, message bubbles, times that stay current, the readable column, card
//  grid and side column of a large screen.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct ContentScreen: View {
    static let title = "Content & Layout"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        ExpandableTextPage()
        ActivityTimelinePage()
        MonthCalendarPage()
        FlowLayoutPage()
        ReadableWidthPage()
        AdaptiveColumnsPage()
        FormSectionPage()
        CardListPage()
        EditSheetContainerPage()
        EditableHeroPage()
        ArticleBodyPage()
        MessageBubblePage()
        ConversationDividerPage()
        RelativeTimePage()
    }
}

private struct ConversationDividerPage: View {
    @State private var state: SpecimenState = .content
    @State private var kind = 0
    @State private var event = "Ten changed the October budget"

    var body: some View {
        ComponentPage(
            name: "ConversationDivider",
            summary: "A line across a conversation: the day the next messages are from, or something that happened in it.",
            since: "8.9.0",
            apps: [.tenra, .platina],
            canvas: .fill,
            notes: [
                "ConversationDivider(date:) reads “Today”, “Yesterday”, then the day (Formatting.dayTitle, the DesignKitDateFormat.day hook); VoiceOver hears it as a heading.",
                "ConversationDivider(_:systemImage:) for an event: “Alex joined”, “Ten changed the budget”.",
            ],
            dos: [
                "Put a day divider before the first message of each day.",
                "Name an event the way a person would say it: “Ten changed the October budget”.",
            ],
            donts: [
                "Use it as a section header outside a conversation (that is SectionHeader).",
            ],
            code: dividerCode,
            cases: dividerCases
        ) {
            if state == .loading {
                ConversationDividerSkeleton()
            } else {
                VStack(spacing: AppSpacing.sm) {
                    MessageBubble("How much did I spend on cafés?", time: Date.now.addingTimeInterval(-90_000), status: .read)
                    divider
                    MessageBubble("And on taxis?", time: .now, status: .sent)
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Divider", selection: $kind, options: [("Today", 0), ("A week ago", 1), ("Last year", 2), ("Event", 3)])
            if kind == 3 {
                TextControl("Event", text: $event)
            }
        }
    }

    @ViewBuilder
    private var divider: some View {
        switch kind {
        case 1: ConversationDivider(date: Date.now.addingTimeInterval(-7 * 86_400))
        case 2: ConversationDivider(date: Date.now.addingTimeInterval(-400 * 86_400))
        case 3: ConversationDivider(event, systemImage: "pencil")
        default: ConversationDivider(date: .now)
        }
    }

    /// The call as the controls set it: a message's day, or the event.
    private var dividerCode: String {
        if state == .loading {
            return SwiftCode.call("ConversationDividerSkeleton")
        }
        if kind == 3 {
            return SwiftCode.call("ConversationDivider", [
                .positional(SwiftCode.string(event)),
                .text("systemImage", "pencil"),
            ])
        }
        return SwiftCode.call("ConversationDivider", [.labeled("date", "message.sentAt")])
    }

    /// Days and events as a chat shows them.
    private var dividerCases: [SpecimenCase] {
        [
            SpecimenCase("Today") { kind = 0; state = .content },
            SpecimenCase("Last year") { kind = 2; state = .content },
            SpecimenCase("Budget change") {
                kind = 3; event = "Ten changed the October budget"; state = .content
            },
            SpecimenCase("Long event") {
                kind = 3; event = "Aigerim renamed the trip to Weekend at Big Almaty Lake and added 12 photos"
                state = .content
            },
            SpecimenCase("Long file name") {
                kind = 3; event = "Ten imported kaspi_gold_statement_2026-10-01_2026-10-31.pdf"; state = .content
            },
        ]
    }
}

private struct RelativeTimePage: View {
    @State private var style: RelativeTime.Style = .relative
    @State private var offset: TimeInterval = 5 * 60
    /// The moment the page opened: the specimen's date is this, minus the chosen offset.
    @State private var anchor = Date.now

    private static let offsets: [(String, TimeInterval)] = [
        ("20 seconds", 20), ("5 minutes", 5 * 60), ("3 hours", 3 * 3600),
        ("A day", 26 * 3600), ("A week", 8 * 86_400), ("Over a year", 400 * 86_400),
    ]

    var body: some View {
        ComponentPage(
            name: "RelativeTime",
            summary: "When something happened, or how long it has run, kept current on screen: “5 min. ago”, “Yesterday, 14:20”, “1 hr, 2 min”, “1:02:34”.",
            since: "8.9.0",
            apps: [.tenra, .dalada, .platina],
            notes: [
                "Style it as text (.font, .foregroundStyle). .relative redraws every 30 seconds, .elapsed and .clock every second; .clock keeps its digits one width.",
                "Under a minute “Just now”, under an hour minutes, the same day hours, the next day over “Yesterday, 14:20”, then the day (with the year in another year). The day follows DesignKitDateFormat.day.",
                "VoiceOver reads the units in full (“5 minutes ago”). A long press on iPad or Mac shows the full date.",
                "The texts alone: Formatting.relativeTime(_:), .elapsedTime(_:), .clockTime(_:).",
            ],
            dos: [
                "Show when something happened in a feed, a comment, a history row.",
                "Use .clock for a running session and give it a numbers font.",
            ],
            donts: [
                "Format the date by hand next to it: older dates follow DesignKitDateFormat.day.",
                "Use it for a date the person picks or plans (that is a date row).",
            ],
            code: timeCode,
            cases: timeCases
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
                RelativeTime(anchor.addingTimeInterval(-offset), style: style)
                    .font(style == .clock ? AppTypography.numbers(AppTypography.h2) : AppTypography.body)
                    .foregroundStyle(AppColors.Text.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } controls: {
            ChoiceControl("Style", selection: $style, options: [("Relative", .relative), ("Elapsed", .elapsed), ("Clock", .clock)])
            ChoiceControl(style == .relative ? "Happened" : "Started", selection: $offset, options: Self.offsets.map { ("\($0.0) ago", $0.1) })
            ActionControl("Now", systemImage: "arrow.clockwise") { anchor = .now }
        }
    }

    private var label: String {
        switch style {
        case .relative: "Commented"
        case .elapsed: "On the trail for"
        case .clock: "Session"
        }
    }

    /// The call as the controls set it, styled as the preview is.
    private var timeCode: String {
        let date: String
        switch style {
        case .relative: date = "comment.createdAt"
        case .elapsed: date = "trip.startedAt"
        case .clock: date = "session.startedAt"
        }
        let call = SwiftCode.call("RelativeTime", [
            .positional(date),
            .option("style", ".\(style)", default: ".relative"),
        ])
        let font = style == .clock ? "AppTypography.numbers(AppTypography.h2)" : "AppTypography.body"
        let styled = SwiftCode.modifier(call, "font", [.positional(font)])
        return SwiftCode.modifier(styled, "foregroundStyle", [.positional("AppColors.Text.primary")])
    }

    /// Times from a feed and a running session.
    private var timeCases: [SpecimenCase] {
        [
            SpecimenCase("Just now") { style = .relative; offset = 20; anchor = .now },
            SpecimenCase("Yesterday") { style = .relative; offset = 26 * 3600; anchor = .now },
            SpecimenCase("A year ago") { style = .relative; offset = 400 * 86_400; anchor = .now },
            SpecimenCase("On the trail") { style = .elapsed; offset = 3 * 3600; anchor = .now },
            SpecimenCase("Session clock") { style = .clock; offset = 5 * 60; anchor = .now },
        ]
    }
}

private struct ExpandableTextPage: View {
    /// A place's notes, as Dalada shows them.
    private static let lakeNotes = "A quiet lake two hours from the city. The road is good until the last two kilometres, then a dirt track that turns into mud after rain. Bring your own firewood: there is none left near the shore. Pike in the morning, perch in the afternoon. The ranger asks for a fee at the gate."

    @State private var lineLimit = 3
    @State private var state: SpecimenState = .content
    /// The text folded; the cases change it.
    @State private var text = ExpandableTextPage.lakeNotes

    var body: some View {
        ComponentPage(
            name: "ExpandableText",
            summary: "Text folded to a few lines with “More” when it does not fit.",
            since: "0.6.0",
            apps: [.dalada, .platina],
            canvas: .fill,
            code: textCode,
            cases: textCases
        ) {
            if state == .loading {
                ExpandableTextSkeleton(lines: lineLimit)
            } else {
                ExpandableText(
                    text,
                    lineLimit: lineLimit
                )
            }
        } controls: {
            StateControl(state: $state)
            StepperControl("Lines", value: $lineLimit, in: 1...6)
        }
    }

    /// The call as the controls set it, the defaults left out.
    private var textCode: String {
        if state == .loading {
            return SwiftCode.call("ExpandableTextSkeleton", [.number("lines", Double(lineLimit), default: 3)])
        }
        return SwiftCode.call("ExpandableText", [
            .positional(SwiftCode.string(text)),
            .number("lineLimit", Double(lineLimit), default: 3),
        ])
    }

    /// Texts from a place's page, short and long.
    private var textCases: [SpecimenCase] {
        [
            SpecimenCase("Place notes") { text = ExpandableTextPage.lakeNotes; lineLimit = 3; state = .content },
            SpecimenCase("Short") { text = "Shady shore, good for kids."; lineLimit = 3; state = .content },
            SpecimenCase("One line") { text = ExpandableTextPage.lakeNotes; lineLimit = 1; state = .content },
            SpecimenCase("Long link") {
                text = "https://dalada.kz/places/big-almaty-lake?share=trip&from=2026-10-12&to=2026-10-14&members=aigerim,daulet,alex,marat"
                lineLimit = 2; state = .content
            },
            SpecimenCase("Long review") {
                text = "We came for the weekend with two kids and a dog. The first evening was windy, so pitch the tent behind the big rocks on the left shore. The water is cold even in August, but the kids swam near the reeds where it is shallow. Pike bit early in the morning on a spinner; by ten the lake was full of boats and nothing bit. Take cash: the ranger at the gate does not take cards, and the nearest shop is forty minutes back towards the city."
                lineLimit = 4; state = .content
            },
        ]
    }
}

private struct ActivityTimelinePage: View {
    @State private var markers = true
    @State private var count = 4
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ActivityTimeline",
            summary: "Events on a vertical line with a dot or a symbol for each.",
            since: "0.7.0",
            apps: [.dalada, .platina],
            canvas: .fill
        ) {
            if state == .loading {
                ActivityTimelineSkeleton(count: count)
            } else if markers {
                ActivityTimeline(Array(SampleEvent.samples.prefix(count))) { event in
                    TimelineMarker(systemImage: event.symbol, color: event.color)
                } content: { event in
                    eventContent(event)
                }
            } else {
                ActivityTimeline(Array(SampleEvent.samples.prefix(count))) { event in
                    eventContent(event)
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Symbol markers", isOn: $markers)
            StepperControl("Events", value: $count, in: 1...4)
        }
    }

    private func eventContent(_ event: SampleEvent) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(event.title).font(AppTypography.bodyEmphasis)
            Text(event.detail)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.Text.secondary)
        }
    }
}

private struct MonthCalendarPage: View {
    @State private var range = CalendarRange()
    @State private var tripsByDay: [Date: [SampleTrip]] = [:]
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "MonthCalendar",
            summary: "A week that opens into the month; markers on the days, a summary of the period. Swipe weeks or months.",
            since: "0.7.0",
            apps: [.tenra, .dalada],
            canvas: .fill
        ) {
            if state == .loading {
                MonthCalendarSkeleton()
            } else {
                MonthCalendar(range: range, itemsByDay: tripsByDay, itemName: \.name) { trip in
                    Image(systemName: trip.symbol)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppColors.Text.primaryOnDark)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(trip.color)
                } accessory: { period in
                    let count = SampleTrip.samples.filter { trip in trip.days.contains { period.interval.contains($0) } }.count
                    if count > 0 {
                        Badge("\(count) trips", color: AppColors.accent)
                    }
                }
            }
        } controls: {
            StateControl(state: $state)
        }
        .onAppear {
            tripsByDay = range.itemsByDay(SampleTrip.samples) { trip, _ in trip.days }
        }
    }
}

private struct FlowLayoutPage: View {
    @State private var spacing = Double(AppSpacing.sm)
    @State private var count = 7
    @State private var alignment = 0

    private let tags = ["Lake", "Free camping", "Fire allowed", "No motorboats", "Pike", "Road: 4x4", "Toilets", "Kids", "Shade"]

    var body: some View {
        ComponentPage(
            name: "FlowLayout",
            summary: "A layout that wraps its views to new lines like words: tags, badges, chips.",
            since: "0.7.0",
            apps: [.dalada, .platina],
            canvas: .fill,
            notes: ["alignment (2.9.0): each row leading, centred or trailing."]
        ) {
            FlowLayout(spacing: spacing, lineSpacing: spacing, alignment: [HorizontalAlignment.leading, .center, .trailing][alignment]) {
                ForEach(tags.prefix(count), id: \.self) {
                    Badge($0, color: AppColors.accent)
                }
            }
        } controls: {
            SliderControl("Spacing", value: $spacing, in: 0...24, step: 2) { "\(Int($0)) pt" }
            StepperControl("Items", value: $count, in: 1...9)
            ChoiceControl("Alignment", selection: $alignment, options: [("Leading", 0), ("Center", 1), ("Trailing", 2)])
        }
    }
}

private struct ReadableWidthPage: View {
    @State private var screen: CGFloat = 1194
    @State private var grid = false
    @State private var readable = true
    @State private var reminder = true

    private let trips = [
        ("Big Almaty Lake", "mountain.2.fill", 0.8),
        ("Charyn Canyon", "sun.max.fill", 0.45),
        ("Kolsai Lakes", "drop.fill", 0.6),
        ("Altyn-Emel", "leaf.fill", 0.25),
        ("Shymbulak", "snowflake", 1.0),
        ("Turgen Falls", "water.waves", 0.35),
    ]

    var body: some View {
        ComponentPage(
            name: ".readableWidth() · AppLayout",
            summary: "A screen's content on an iPad or in a Mac window: a centred column of cards and text no wider than 720 pt, or a grid of cards side by side no wider than 1120 pt. On a phone nothing changes.",
            since: "8.13.0",
            apps: [.platina],
            canvas: .fill,
            notes: [
                "Put it on the scroll view's content after .screenPadding(): the column's 720 pt include the margins, and the scroll bar stays at the screen's edge.",
                "The column grows with the person's text size, as the system's readable width does.",
                "A grid of cards: LazyVGrid(columns: AppLayout.cardColumns(), spacing: AppSpacing.lg) under .readableWidth(AppLayout.wideWidth), or CardList(layout: .grid) for the things a person keeps (8.15.0). A phone holds one card in a row, an iPad two or three.",
                "A list and what it opens side by side is the system's NavigationSplitView; each column's screen keeps its own .readableWidth() (docs/design-system.md, Large screens).",
            ],
            dos: [
                "Give every scrolling screen of an app that runs on an iPad or a Mac its column.",
                "Put cards that stand on their own (games, accounts, trips) in a card grid.",
            ],
            donts: [
                "Check for an iPhone or a screen size: the column and the grid follow the width they get.",
                "Put a form's rows in a card grid: a form is one column.",
            ]
        ) {
            LayoutScreenPreview(width: screen) {
                let content = specimen.screenPadding()
                if readable {
                    content.readableWidth(grid ? AppLayout.wideWidth : AppLayout.readableWidth)
                } else {
                    content
                }
            }
        } controls: {
            ChoiceControl("Screen", selection: $screen, options: [("iPhone", 402), ("iPad mini", 744), ("iPad", 1194), ("Mac", 1512)])
            ChoiceControl("Content", selection: $grid, options: [("Column", false), ("Card grid", true)])
            ToggleControl("Readable width", isOn: $readable)
        }
    }

    @ViewBuilder private var specimen: some View {
        if grid {
            LazyVGrid(columns: AppLayout.cardColumns(), spacing: AppSpacing.lg) {
                ForEach(trips, id: \.0) { title, symbol, progress in
                    HStack(spacing: AppSpacing.md) {
                        Icon(source: .sfSymbol(symbol), size: AppIconSize.Tile.sm)
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(title).font(AppTypography.h4)
                                .foregroundStyle(AppColors.Text.primary)
                            LinearProgressBar(value: progress, animatesOnAppear: false)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardContentPadding()
                    .cardStyle()
                }
            }
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                FormSection(header: "Trip") {
                    UniversalRow("Reminder", icon: "clock", accessory: .toggle($reminder))
                    UniversalRow("Route", icon: "map", accessory: .info("Big Almaty Lake"))
                    UniversalRow("Group", icon: "person.2", accessory: .info("4 people"))
                }
                Text("The lake lies at 2,500 m, an hour's drive above the city. The road closes after heavy snow; the last stretch is a walk of about forty minutes along the pipeline.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.Text.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardContentPadding()
                    .cardStyle()
            }
        }
    }
}

private struct AdaptiveColumnsPage: View {
    private enum TripPart: String, CaseIterable, Hashable {
        case route, weather, group

        var title: String {
            switch self {
            case .route: "Route"
            case .weather: "Weather"
            case .group: "Group"
            }
        }
    }

    @State private var screen: CGFloat = 1194
    @State private var chips = true
    @State private var part: TripPart? = .route

    var body: some View {
        ComponentPage(
            name: "AdaptiveColumns",
            summary: "A screen's main column with a side column beside it when the width allows: on an iPad a trip's route with its weather and group beside it. Narrower, as on a phone, the screen's own narrow layout: chips that switch between the parts, or the side under the main column.",
            since: "8.15.0",
            apps: [.platina],
            canvas: .fill,
            notes: [
                "What decides is the width the view gets: the main column's minimum (AppLayout.mainColumnMinWidth, 400 pt), the gap (24 pt) and the side (AppLayout.sideColumnWidth, 340 pt), 764 pt in all, more at a larger text size.",
                "Put it on a scroll view's content after .screenPadding(), under .readableWidth(AppLayout.wideWidth): an iPad gets the columns, a phone and an iPad mini in portrait the narrow layout, and a Mac window switches as it is resized.",
                "narrow: is the phone's screen as it is, often a ChipPicker over one part at a time; without it the side stacks under the main column.",
                "The two layouts are different views: keep state (the picked chip, a filter) in the screen, not inside the columns.",
            ],
            dos: [
                "Put what the screen is for in the main column, and summaries, what comes next and the latest items in the side.",
                "Show in the side the cards the phone shows, so the person finds the same things.",
            ],
            donts: [
                "Put a form in two columns: a form is one column.",
                "Check for an iPad to choose the layout: a panel or a split window narrows the screen too.",
            ]
        ) {
            LayoutScreenPreview(width: screen) {
                specimen
                    .screenPadding()
                    .readableWidth(AppLayout.wideWidth)
            }
        } controls: {
            ChoiceControl("Screen", selection: $screen, options: [("iPhone", 402), ("iPad mini", 744), ("iPad", 1194), ("Mac", 1512)])
            ChoiceControl("Narrow layout", selection: $chips, options: [("Chips", true), ("Side under main", false)])
        }
    }

    @ViewBuilder private var specimen: some View {
        if chips {
            AdaptiveColumns {
                route
            } side: {
                weather
                group
            } narrow: {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ChipPicker(options: TripPart.allCases, selection: $part) { $0.title }
                    switch part ?? .route {
                    case .route: route
                    case .weather: weather
                    case .group: group
                    }
                }
            }
        } else {
            AdaptiveColumns {
                route
            } side: {
                weather
                group
            }
        }
    }

    private var route: some View {
        FormSection(header: "Route") {
            UniversalRow("Almaty", icon: "mappin", accessory: .info("08:00"))
            UniversalRow("Big Almaty Lake", icon: "drop", accessory: .info("09:30"))
            UniversalRow("The observatory", icon: "sparkles", accessory: .info("12:00"))
            UniversalRow("Back in the city", icon: "house", accessory: .info("17:00"))
        }
    }

    private var weather: some View {
        sideCard("Weather", symbol: "sun.max.fill", detail: "+18°, clear; wind 4 m/s at the lake")
    }

    private var group: some View {
        sideCard("Group", symbol: "person.2.fill", detail: "4 people; Aigerim drives")
    }

    private func sideCard(_ title: String, symbol: String, detail: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Icon(source: .sfSymbol(symbol), size: AppIconSize.Tile.sm)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title).font(AppTypography.h4)
                    .foregroundStyle(AppColors.Text.primary)
                Text(detail).font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardContentPadding()
        .cardStyle()
    }
}

/// A screen `width` points wide drawn smaller to fit the page, so a phone shows how an iPad or a
/// Mac window lays the content out.
private struct LayoutScreenPreview<Content: View>: View {
    let width: CGFloat
    @ViewBuilder var content: Content

    private var height: CGFloat { max(420, width * 0.62) }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(1, proxy.size.width / width)
            VStack(spacing: 0) { content }
                .padding(.vertical, AppSpacing.lg)
                .frame(width: width, height: height, alignment: .top)
                .background(AppColors.Background.page)
                .scaleEffect(scale, anchor: .topLeading)
        }
        .aspectRatio(width / height, contentMode: .fit)
        .clipShape(.rect(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).strokeBorder(AppColors.Border.normal, lineWidth: 0.5))
    }
}

private struct FormSectionPage: View {
    @State private var showsHeader = true
    @State private var showsFooter = true
    @State private var rows = 4
    @State private var title = "Groceries"
    @State private var period = "month"
    @State private var quiet = true
    @State private var state: SpecimenState = .content

    private let periods: [(label: String, value: String)] = [
        (label: "Weekly", value: "week"), (label: "Monthly", value: "month"), (label: "Yearly", value: "year"),
    ]

    var body: some View {
        ComponentPage(
            name: "FormSection",
            summary: "A titled group of rows on a Liquid Glass card, or the grey of SurfaceStyle.fill (8.12.0); one look for forms, settings and short lists since 8.0.0. It pads its rows at the sides and draws the divider between them, under each row's text.",
            apps: [.tenra, .dalada, .platina],
            canvas: .fill,
            notes: [
                "Rows pad themselves only vertically (UniversalRow .standard, 12 pt: a 48 pt row); the card pads them 16 pt at the sides, and the header stands 12 pt above it (docs/design-system.md §10).",
                "No Divider between rows: the section draws a RowDivider under the upper row's text, 16 pt short of the card's edge. A custom row with something before its text says where with .rowDividerInset(_:).",
                "One row: a menu in a one-row section is the case iOS 26 once collapsed into its popover on glass. Tap it on a device (TestFlight) to check the menu opens from the row.",
            ],
            dos: [
                "Put a form's or a settings list's rows in it: it draws the glass card and the dividers.",
            ],
            donts: [
                "Use the system Form or a List for a form.",
                "Add dividers between its rows yourself.",
            ],
            code: sectionCode,
            cases: sectionCases
        ) {
            NavigationStack {
                Group {
                    if state == .loading {
                        CardListSkeleton(layout: .section, count: rows)
                    } else {
                        FormSection(header: showsHeader ? "Payment" : nil, footer: showsFooter ? "Charged on the 17th of every month." : nil) {
                            UniversalRow("Repeat", icon: "repeat", accessory: .menu($period, options: periods))
                            if rows > 1 {
                                UniversalRow("Reminder", icon: "bell", hint: "A day before the charge", accessory: .toggle($quiet))
                            }
                            if rows > 2 {
                                UniversalRow(config: .standard) {
                                    Text("Title").font(AppTypography.body)
                                } trailing: {
                                    FormTextField(text: $title, placeholder: "Title", style: .inline)
                                }
                            }
                            if rows > 3 {
                                UniversalRow("Language", icon: "globe", value: "English", accessory: .navigation { Text("Language").navigationTitle("Language") })
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .toolbar(.hidden, for: .navigationBar)
            }
            .frame(height: 420)
        } controls: {
            StateControl(state: $state)
            ToggleControl("Header", isOn: $showsHeader)
            ToggleControl("Footer", isOn: $showsFooter)
            StepperControl("Rows", value: $rows, in: 1...4)
        }
    }

    /// The call as the controls set it, with the preview's first rows.
    private var sectionCode: String {
        if state == .loading {
            return SwiftCode.call("CardListSkeleton", [
                .labeled("layout", ".section"),
                .number("count", Double(rows), default: 3),
            ])
        }
        var rowsCode = [
            SwiftCode.call("UniversalRow", [
                .positional(SwiftCode.string("Repeat")),
                .text("icon", "repeat"),
                .labeled("accessory", ".menu($period, options: periods)"),
            ]),
        ]
        if rows > 1 {
            rowsCode.append(SwiftCode.call("UniversalRow", [
                .positional(SwiftCode.string("Reminder")),
                .text("icon", "bell"),
                .text("hint", "A day before the charge"),
                .labeled("accessory", ".toggle($reminder)"),
            ]))
        }
        return SwiftCode.call("FormSection", [
            showsHeader ? .text("header", "Payment") : nil,
            showsFooter ? .text("footer", "Charged on the 17th of every month.") : nil,
        ], trailing: rowsCode.joined(separator: "\n"))
    }

    /// Sections as a subscription's edit sheet shows them.
    private var sectionCases: [SpecimenCase] {
        [
            SpecimenCase("Subscription") {
                showsHeader = true; showsFooter = true; rows = 4; title = "Groceries"; period = "month"
                quiet = true; state = .content
            },
            SpecimenCase("One row") {
                showsHeader = false; showsFooter = false; rows = 1; title = "Groceries"; period = "year"
                quiet = true; state = .content
            },
            SpecimenCase("No footer") {
                showsHeader = true; showsFooter = false; rows = 2; title = "Groceries"; period = "week"
                quiet = false; state = .content
            },
            SpecimenCase("Long title") {
                showsHeader = true; showsFooter = true; rows = 3; period = "month"; quiet = true
                title = "Groceries and household supplies for the whole family"; state = .content
            },
        ]
    }
}

/// CardList (8.0.0): the probe of the owner's step 0 on a device: drag a card to reorder, pick
/// several, a list of 200.
private struct CardListPage: View {
    struct Item: Identifiable, Hashable {
        let id: Int
        let name: String
        let symbol: String
        let amount: String
    }

    @State private var layout: CardListLayout = .cards
    @State private var mode: CardListMode = .browsing
    @State private var count = 5
    @State private var items: [Item] = CardListPage.make(5)
    @State private var selection: Set<Int> = []
    @State private var state: SpecimenState = .content

    private static let names = ["Main card", "Cash", "Savings", "Travel", "Car loan", "Mortgage", "Groceries", "Gifts"]
    private static let symbols = ["creditcard.fill", "banknote.fill", "lock.fill", "airplane", "car.fill", "house.fill", "cart.fill", "gift.fill"]

    private static func make(_ count: Int) -> [Item] {
        (0..<count).map { index in
            Item(
                id: index,
                name: names[index % names.count] + (index >= names.count ? " \(index / names.count + 1)" : ""),
                symbol: symbols[index % symbols.count],
                amount: "\((index + 1) * 12_500) ₸"
            )
        }
    }

    var body: some View {
        ComponentPage(
            name: "CardList",
            summary: "The things a person keeps (accounts, deposits, loans, categories, trips) with one set of actions: open, select several and delete, change the order by dragging. A card per item, or every item a row in one card.",
            since: "8.0.0",
            apps: [.tenra, .dalada, .platina],
            canvas: .fill,
            notes: [
                "cards: a card per item (glass, or the grey fill), padded 16 pt; section: every item a row in one card, a divider under each row's text; stack: items that are cards already (a PayoffProgressCard), the circle and the handle beside them.",
                "grid (8.15.0): the cards side by side in AppLayout.cardColumns() where the width holds two or more, on an iPad or in a Mac window under .readableWidth(AppLayout.wideWidth); one in a row on a phone, as here.",
                "cardListToolbar(mode:selection:allIDs:onAdd:onDeleteSelected:) is the same toolbar on every list: select, change the order, add; Done; Delete N under the list.",
                "Reordering: a long press lifts a card, moving it over another puts it there (a tick on each step). VoiceOver: move up, move down.",
            ],
            code: listCode,
            cases: listCases
        ) {
            NavigationStack {
                ScrollView {
                    if state == .loading {
                        CardListSkeleton(layout: layout, count: min(count, 6))
                            .screenPadding()
                    } else {
                        CardList(items, layout: layout, mode: mode, selection: $selection, onMove: { from, to in
                            items.move(fromOffsets: from, toOffset: to)
                        }) { item in
                            itemView(item)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        items.removeAll { $0.id == item.id }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        .screenPadding()
                    }
                }
                .navigationTitle("Accounts")
                .navigationBarTitleDisplayMode(.inline)
                .cardListToolbar(
                    mode: $mode,
                    selection: $selection,
                    allIDs: items.map(\.id),
                    addLabel: "New account",
                    onAdd: {
                        let next = (items.map(\.id).max() ?? -1) + 1
                        items.append(Item(id: next, name: "New account", symbol: "creditcard", amount: "0 ₸"))
                    },
                    onDeleteSelected: {
                        items.removeAll { selection.contains($0.id) }
                        selection.removeAll()
                        mode = .browsing
                    }
                )
            }
            .frame(height: 560)
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Layout", selection: $layout, options: [("Cards", .cards), ("Section", .section), ("Stack", .stack), ("Grid", .grid)])
            ChoiceControl("Mode", selection: $mode, options: [("Browsing", .browsing), ("Selecting", .selecting), ("Reordering", .reordering)])
            ChoiceControl("Items", selection: $count, options: [("5", 5), ("12", 12), ("200", 200)])
        }
        .onChange(of: count) { _, new in
            items = CardListPage.make(new)
            selection.removeAll()
        }
    }

    /// An item's row; in `.stack` a card of its own, as an app's ready-made card would be.
    @ViewBuilder
    private func itemView(_ item: Item) -> some View {
        let row = UniversalRow(
            item.name,
            leadingIcon: .sfSymbol(item.symbol, color: AppColors.accent, size: AppIconSize.Tile.sm),
            value: item.amount,
            config: .standard
        )
        if layout == .stack {
            row
                .padding(.horizontal, AppSpacing.lg)
                .cardStyle()
        } else {
            row
        }
    }

    /// The list and its toolbar as the controls set them.
    private var listCode: String {
        if state == .loading {
            return SwiftCode.call("CardListSkeleton", [
                .option("layout", ".\(layout)", default: ".cards"),
                .number("count", Double(min(count, 6)), default: 3),
            ])
        }
        var row = SwiftCode.call("UniversalRow", [
            .positional("account.name"),
            .labeled("leadingIcon", ".sfSymbol(account.symbol, color: AppColors.accent, size: AppIconSize.Tile.sm)"),
            .labeled("value", "account.balance"),
        ])
        if layout == .stack {
            row = SwiftCode.modifier(row, "padding", [.positional(".horizontal"), .positional("AppSpacing.lg")])
            row = SwiftCode.modifier(row, "cardStyle")
        }
        let call = SwiftCode.call("CardList", [
            .positional("accounts"),
            .option("layout", ".\(layout)", default: ".cards"),
            .labeled("mode", "mode"),
            .labeled("selection", "$selection"),
            .labeled("onMove", "{ accounts.move(fromOffsets: $0, toOffset: $1) }"),
        ])
        let list = "\(call) { account in\n\(SwiftCode.indent(row))\n}"
        return SwiftCode.modifier(list, "cardListToolbar", [
            .labeled("mode", "$mode"),
            .labeled("selection", "$selection"),
            .labeled("allIDs", "accounts.map(\\.id)"),
            .text("addLabel", "New account"),
            .labeled("onAdd", "addAccount"),
            .labeled("onDeleteSelected", "confirmDelete"),
        ])
    }

    /// A person's accounts, few and many, in each mode.
    private var listCases: [SpecimenCase] {
        [
            SpecimenCase("Accounts") {
                layout = .cards; mode = .browsing; count = 5; items = CardListPage.make(5); selection = []
                state = .content
            },
            SpecimenCase("In one card") {
                layout = .section; mode = .browsing; count = 12; items = CardListPage.make(12); selection = []
                state = .content
            },
            SpecimenCase("Picking two") {
                layout = .cards; mode = .selecting; items = CardListPage.make(count); selection = [0, 1]
                state = .content
            },
            SpecimenCase("Reordering") {
                layout = .stack; mode = .reordering; count = 5; items = CardListPage.make(5); selection = []
                state = .content
            },
            SpecimenCase("200 accounts") {
                layout = .section; mode = .browsing; count = 200; items = CardListPage.make(200); selection = []
                state = .content
            },
        ]
    }
}

private struct EditSheetContainerPage: View {
    @State private var isPresented = false
    @State private var name = "Kaspi Gold"
    @State private var isSaving = false

    var body: some View {
        ComponentPage(
            name: "EditSheetContainer",
            summary: "The shell of an edit sheet: navigation bar with Cancel and Save, a form inside.",
            apps: [.tenra, .dalada, .platina],
            code: sheetCode,
            cases: sheetCases
        ) {
            DSButton("Open the sheet", appearance: .secondary, fullWidth: true) { isPresented = true }
            .sheet(isPresented: $isPresented) {
                EditSheetContainer(
                    title: "Edit account",
                    isSaveDisabled: name.isEmpty,
                    isSaving: isSaving,
                    onSave: { isPresented = false },
                    onCancel: { isPresented = false }
                ) {
                    Section("Name") {
                        TextField("Account name", text: $name)
                    }
                }
            }
        } controls: {
            ToggleControl("Saving (3.0.0): a spinner for Save", isOn: $isSaving)
        }
    }

    /// The call as the controls set it, with the preview's one field.
    private var sheetCode: String {
        let form = """
            Section("Name") {
                TextField("Account name", text: $name)
            }
            """
        return SwiftCode.call("EditSheetContainer", [
            .text("title", "Edit account"),
            .labeled("isSaveDisabled", "name.isEmpty"),
            .flag("isSaving", isSaving),
            .labeled("onSave", "{ save() }"),
            .labeled("onCancel", "{ dismiss() }"),
        ], trailing: form)
    }

    /// Accounts to edit; each opens the sheet.
    private var sheetCases: [SpecimenCase] {
        [
            SpecimenCase("Edit account") { name = "Kaspi Gold"; isSaving = false; isPresented = true },
            SpecimenCase("Empty name") { name = ""; isSaving = false; isPresented = true },
            SpecimenCase("Saving") { name = "Kaspi Gold"; isSaving = true; isPresented = true },
            SpecimenCase("Long name") {
                name = "Joint savings for the summer trip to Issyk-Kul"; isSaving = false; isPresented = true
            },
        ]
    }
}

private struct EditableHeroPage: View {
    @State private var icon: IconSource? = .sfSymbol("creditcard.fill")
    @State private var title = "Kaspi Gold"
    @State private var amount = "120000"
    @State private var currency = "KZT"
    @State private var showsAmount = true

    var body: some View {
        ComponentPage(
            name: "EditableHero",
            summary: "The top of an edit sheet: the icon (opens IconPicker), the name typed in place, an amount with its currency.",
            since: "1.10.0",
            apps: [.tenra]
        ) {
            EditableHero(icon: $icon, title: $title, titlePlaceholder: "Account name",
                         amount: $amount, currency: $currency,
                         options: showsAmount ? .amountAndCurrency : .symbolsOnly)
        } controls: {
            ToggleControl("Amount and currency", isOn: $showsAmount)
        }
    }
}

// MARK: - Sample data

private struct SampleTrip: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let color: Color
    let days: [Date]

    static let samples: [SampleTrip] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        func days(_ from: Int, _ count: Int) -> [Date] {
            (0..<count).compactMap { calendar.date(byAdding: .day, value: from + $0, to: today) }
        }
        return [
            SampleTrip(name: "Big Almaty Lake", symbol: "tent.fill", color: .green, days: days(2, 2)),
            SampleTrip(name: "Charyn", symbol: "car.fill", color: .orange, days: days(9, 3)),
            SampleTrip(name: "Spawning ban", symbol: "nosign", color: .red, days: days(0, 14)),
            SampleTrip(name: "Kolsai", symbol: "figure.hiking", color: .blue, days: days(3, 1)),
            SampleTrip(name: "Kapchagay", symbol: "fish.fill", color: .teal, days: days(3, 1)),
        ]
    }()
}

private struct SampleEvent: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String?
    let color: Color?

    static let samples = [
        SampleEvent(title: "Left Almaty", detail: "06:10", symbol: "car.fill", color: nil),
        SampleEvent(title: "Check-in: Big Almaty Lake", detail: "08:45 · clear, 12 °C, calm", symbol: "mappin", color: .green),
        SampleEvent(title: "Caught a pike, 2.1 kg", detail: "10:20 · released", symbol: "fish.fill", color: .teal),
        SampleEvent(title: "Back home", detail: "19:30", symbol: nil, color: .gray),
    ]
}

private struct ArticleBodyPage: View {
    @State private var state: SpecimenState = .content
    /// The article shown; the cases change it.
    @State private var blocks: [ArticleBody.Block] = ArticleBodyPage.iceGuide

    /// The page's first article: a guide to the ice.
    private static let iceGuide: [ArticleBody.Block] = [
        .heading("Before you go", level: 2),
        .paragraph("Check the ice at the shore first: **10 cm** holds a person, *15 cm* a group."),
        .bullets(["A spare pair of gloves", "Ice picks around the neck", "A charged phone"]),
        .heading("On the ice", level: 3),
        .steps(["Walk in single file", "Test ahead with a spud bar", "Turn back at dark patches"]),
        .note("Fishing is closed from 1 April to 31 May on most lakes of the region."),
    ]

    var body: some View {
        ComponentPage(
            name: "ArticleBody",
            summary: "The text of an article: headings, paragraphs, bulleted and numbered lists, notes in a card; bold, italic and links inside a line.",
            since: "2.8.0",
            apps: [.tenra, .dalada, .platina],
            canvas: .fill,
            notes: ["The app parses its article format into blocks; inline Markdown inside a block is DesignKit's."],
            code: articleCode,
            cases: articleCases
        ) {
            if state == .loading {
                ArticleBodySkeleton()
            } else {
                ArticleBody(blocks)
            }
        } controls: {
            StateControl(state: $state)
        }
    }

    /// The article's blocks as Swift writes them.
    private var articleCode: String {
        if state == .loading {
            return SwiftCode.call("ArticleBodySkeleton")
        }
        let elements = blocks.map { Self.blockCode($0) }
        return "ArticleBody(\(SwiftCode.array(elements)))"
    }

    /// One block as Swift writes it.
    private static func blockCode(_ block: ArticleBody.Block) -> String {
        switch block {
        case .heading(let text, let level):
            return ".heading(\(SwiftCode.string(text)), level: \(level))"
        case .paragraph(let text):
            return ".paragraph(\(SwiftCode.string(text)))"
        case .bullets(let items):
            return ".bullets(\(SwiftCode.array(items.map { SwiftCode.string($0) })))"
        case .steps(let items):
            return ".steps(\(SwiftCode.array(items.map { SwiftCode.string($0) })))"
        case .note(let text):
            return ".note(\(SwiftCode.string(text)))"
        }
    }

    /// Articles from a guide, an update and a route.
    private var articleCases: [SpecimenCase] {
        [
            SpecimenCase("Ice guide") { blocks = ArticleBodyPage.iceGuide; state = .content },
            SpecimenCase("One paragraph") {
                blocks = [.paragraph("Leave the place cleaner than you found it: take your rubbish home.")]
                state = .content
            },
            SpecimenCase("Release notes") {
                blocks = [
                    .heading("New in 1.4", level: 2),
                    .bullets(["Offline maps for the whole region", "Trips shared with friends", "A **darker** map at night"]),
                    .note("Update the app on every phone in the group to see shared trips."),
                ]
                state = .content
            },
            SpecimenCase("Long text") {
                blocks = [
                    .heading("Getting there", level: 2),
                    .paragraph("Take the road south from the city past the ski resort turn-off. After the checkpoint the asphalt ends and the road climbs in tight bends for about sixteen kilometres; a regular car makes it in dry weather, but after rain only a four-wheel drive does. Leave early: the checkpoint closes the road to cars at 18:00, and parking at the dam fills up by ten on weekends."),
                    .paragraph("From the dam it is a walk of forty minutes along the pipeline to the viewpoint. Bring water and a warm layer: at 2,500 m the wind is cold even in July."),
                ]
                state = .content
            },
            SpecimenCase("Long link") {
                blocks = [.paragraph("Download the track: https://dalada.kz/routes/big-almaty-lake-observatory-loop-2026-10-12-final.gpx")]
                state = .content
            },
        ]
    }
}

#Preview { NavigationStack { ContentScreen() } }

private struct MessageBubblePage: View {
    private struct Sent: Identifiable {
        let id: Int
        let text: String
        let role: MessageBubble.Role
    }

    /// What Send adds: the person's question, then the reply.
    private static let exchange: [(String, String)] = [
        ("And on taxis?", "Taxis: 18,400 ₸, four rides."),
        ("Compared with September?", "A little less: September was 21,000 ₸."),
        ("Thanks!", "Any time."),
    ]

    @State private var text = "How much did I spend on cafés this month?"
    @State private var incoming = false
    @State private var failed = false
    @State private var state: SpecimenState = .content
    @State private var sent: [Sent] = []
    @State private var markdown = false
    @State private var showsTime = true
    @State private var status: MessageBubble.Status? = .read

    private static let markdownReply = """
    ## October so far
    You spent **42,300 ₸** on cafés, a little more than in September.
    - Coffee: 18,400 ₸
    - Lunch out: 23,900 ₸
    > Most of it on weekdays, before noon.
    """

    var body: some View {
        ComponentPage(
            name: "MessageBubble",
            summary: "One message in a conversation: the person's own on the right in the accent, the other side's on the left in grey. A message not sent says why, with Retry.",
            since: "4.6.0",
            apps: [.tenra, .platina],
            canvas: .fill,
            notes: [
                "The bubble grows to about 80% of the width; the text is selectable.",
                "A new message enters with .transition(.messageBubble(role)): the person's own grows from the field's corner, a reply comes into focus on the left. The history a chat opens with does not move.",
                "Not sent: the bubble shakes once, the failure line rises in, the error haptic plays. Under Reduce Motion only the fades stay.",
                "Rich replies (cards, charts) are the app's own views under an incoming bubble or in its place.",
                "8.9.0: MessageBubble(markdown:) reads an answer's paragraphs, lists, headings, notes, bold and links; time: and status: put “14:20 · Read” under the bubble. Strings: message.sending, message.sent, message.read.",
            ],
            dos: [
                "Use markdown: for an assistant's answers, plain text for what people type.",
                "Show time and status under the person's own messages where delivery matters.",
            ],
            donts: [
                "Put cards or charts inside the bubble: lay them out under it.",
                "Animate the history a conversation opens with: only new messages enter.",
            ],
            code: bubbleCode,
            cases: bubbleCases
        ) {
            if state == .loading {
                MessageBubbleSkeleton(role: incoming ? .incoming : .outgoing)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    if markdown {
                        MessageBubble(
                            markdown: Self.markdownReply,
                            role: incoming ? .incoming : .outgoing,
                            time: showsTime ? Date.now.addingTimeInterval(-120) : nil,
                            failure: failed ? "No connection" : nil,
                            onRetry: failed ? { failed = false } : nil
                        )
                    } else {
                        MessageBubble(
                            text,
                            role: incoming ? .incoming : .outgoing,
                            time: showsTime ? Date.now.addingTimeInterval(-120) : nil,
                            status: incoming ? nil : status,
                            failure: failed ? "No connection" : nil,
                            onRetry: failed ? { failed = false } : nil
                        )
                    }
                    ForEach(sent.suffix(4)) { message in
                        MessageBubble(message.text, role: message.role)
                            .transition(.messageBubble(message.role))
                    }
                }
                .animation(AppAnimation.bouncy, value: sent.count)
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Content", selection: $markdown, options: [("Text", false), ("Markdown reply", true)])
            TextControl("Text", text: $text)
            ToggleControl("Incoming", isOn: $incoming)
            ToggleControl("Time", isOn: $showsTime)
            ChoiceControl("Status", selection: $status, options: [("None", nil), ("Sending", .sending), ("Sent", .sent), ("Read", .read)])
            ToggleControl("Not sent", isOn: $failed)
            ActionControl("Send", systemImage: "arrow.up.circle.fill", action: send)
            ActionControl("Clear the conversation", systemImage: "xmark.circle") { sent = [] }
        }
    }

    /// The call as the controls set it, the defaults left out.
    private var bubbleCode: String {
        let role = incoming ? ".incoming" : ".outgoing"
        if state == .loading {
            return SwiftCode.call("MessageBubbleSkeleton", [.option("role", role, default: ".incoming")])
        }
        let time: SwiftCode.Argument? = showsTime ? .labeled("time", "message.sentAt") : nil
        let failure: SwiftCode.Argument? = failed ? .text("failure", "No connection") : nil
        let retry: String? = failed ? "retry()" : nil
        if markdown {
            return SwiftCode.call("MessageBubble", [
                .labeled("markdown", "answer"),
                .option("role", role, default: ".incoming"),
                time,
                failure,
            ], trailing: retry)
        }
        var statusArgument: SwiftCode.Argument? = nil
        if !incoming, let status {
            statusArgument = .labeled("status", ".\(status)")
        }
        return SwiftCode.call("MessageBubble", [
            .positional(SwiftCode.string(text)),
            .option("role", role, default: ".outgoing"),
            time,
            statusArgument,
            failure,
        ], trailing: retry)
    }

    /// Messages of a chat with an assistant: asked, on the way, not sent, answered.
    private var bubbleCases: [SpecimenCase] {
        [
            SpecimenCase("Question") {
                text = "How much did I spend on cafés this month?"; markdown = false; incoming = false
                showsTime = true; status = .read; failed = false; sent = []; state = .content
            },
            SpecimenCase("Sending") {
                text = "Move 20,000 ₸ to Savings"; markdown = false; incoming = false
                showsTime = true; status = .sending; failed = false; sent = []; state = .content
            },
            SpecimenCase("Not sent") {
                text = "Add 4,500 ₸ for a taxi yesterday"; markdown = false; incoming = false
                showsTime = false; status = nil; failed = true; sent = []; state = .content
            },
            SpecimenCase("Long word") {
                text = "Receipt KSP-20261017-0004821396-ALMATY-MEGA-PARK-POS0042"; markdown = false; incoming = false
                showsTime = true; status = .sent; failed = false; sent = []; state = .content
            },
            SpecimenCase("Answer") {
                text = "How much did I spend on cafés this month?"; markdown = true; incoming = true
                showsTime = true; status = nil; failed = false; sent = []; state = .content
            },
        ]
    }

    /// Adds the next question, and its reply a moment later.
    private func send() {
        let (question, reply) = Self.exchange[(sent.count / 2) % Self.exchange.count]
        let id = (sent.last?.id ?? 0) + 1
        sent.append(Sent(id: id, text: question, role: .outgoing))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.9))
            sent.append(Sent(id: id + 1, text: reply, role: .incoming))
        }
    }
}
