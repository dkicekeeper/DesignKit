//
//  ContentScreen.swift
//  DesignKit Gallery
//
//  Content and layout: folded text, timeline, month calendar, flow layout, form sections, the
//  edit sheet and its hero, message bubbles, times that stay current.
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
            apps: [],
            canvas: .fill,
            notes: [
                "ConversationDivider(date:) reads “Today”, “Yesterday”, then the day (Formatting.dayTitle, the DesignKitDateFormat.day hook); VoiceOver hears it as a heading.",
                "ConversationDivider(_:systemImage:) for an event: “Alex joined”, “Ten changed the budget”.",
            ]
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
            apps: [],
            notes: [
                "Style it as text (.font, .foregroundStyle). .relative redraws every 30 seconds, .elapsed and .clock every second; .clock keeps its digits one width.",
                "Under a minute “Just now”, under an hour minutes, the same day hours, the next day over “Yesterday, 14:20”, then the day (with the year in another year). The day follows DesignKitDateFormat.day.",
                "VoiceOver reads the units in full (“5 minutes ago”). A long press on iPad or Mac shows the full date.",
                "The texts alone: Formatting.relativeTime(_:), .elapsedTime(_:), .clockTime(_:).",
            ]
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
}

private struct ExpandableTextPage: View {
    @State private var lineLimit = 3
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ExpandableText",
            summary: "Text folded to a few lines with “More” when it does not fit.",
            since: "0.6.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            if state == .loading {
                ExpandableTextSkeleton(lines: lineLimit)
            } else {
                ExpandableText(
                    "A quiet lake two hours from the city. The road is good until the last two kilometres, then a dirt track that turns into mud after rain. Bring your own firewood: there is none left near the shore. Pike in the morning, perch in the afternoon. The ranger asks for a fee at the gate.",
                    lineLimit: lineLimit
                )
            }
        } controls: {
            StateControl(state: $state)
            StepperControl("Lines", value: $lineLimit, in: 1...6)
        }
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
            apps: [.dalada],
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
                .foregroundStyle(AppColors.textSecondary)
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
                        .foregroundStyle(AppColors.staticWhite)
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
            apps: [.dalada],
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
            summary: "A titled group of rows on a Liquid Glass card (8.0.0: one look for forms, settings and short lists). It pads its rows at the sides and draws the divider between them, under each row's text.",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "Rows pad themselves only vertically (UniversalRow .standard, 12 pt: a 48 pt row); the card pads them 16 pt at the sides, and the header stands 12 pt above it (docs/design-system.md §10).",
                "No Divider between rows: the section draws a RowDivider under the upper row's text, 16 pt short of the card's edge. A custom row with something before its text says where with .rowDividerInset(_:).",
                "One row: a menu in a one-row section is the case iOS 26 once collapsed into its popover on glass. Tap it on a device (TestFlight) to check the menu opens from the row.",
            ]
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
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "cards: a glass card per item, padded 16 pt; section: every item a row in one glass card, a divider under each row's text; stack: items that are cards already (a PayoffProgressCard), the circle and the handle beside them.",
                "cardListToolbar(mode:selection:allIDs:onAdd:onDeleteSelected:) is the same toolbar on every list: select, change the order, add; Done; Delete N under the list.",
                "Reordering: a long press lifts a card, moving it over another puts it there (a tick on each step). VoiceOver: move up, move down.",
            ]
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
            ChoiceControl("Layout", selection: $layout, options: [("Cards", .cards), ("Section", .section), ("Stack", .stack)])
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
}

private struct EditSheetContainerPage: View {
    @State private var isPresented = false
    @State private var name = "Kaspi Gold"
    @State private var isSaving = false

    var body: some View {
        ComponentPage(
            name: "EditSheetContainer",
            summary: "The shell of an edit sheet: navigation bar with Cancel and Save, a form inside.",
            apps: [.tenra, .dalada]
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

    private let blocks: [ArticleBody.Block] = [
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
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: ["The app parses its article format into blocks; inline Markdown inside a block is DesignKit's."]
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
            apps: [.tenra],
            canvas: .fill,
            notes: [
                "The bubble grows to about 80% of the width; the text is selectable.",
                "A new message enters with .transition(.messageBubble(role)): the person's own grows from the field's corner, a reply comes into focus on the left. The history a chat opens with does not move.",
                "Not sent: the bubble shakes once, the failure line rises in, the error haptic plays. Under Reduce Motion only the fades stay.",
                "Rich replies (cards, charts) are the app's own views under an incoming bubble or in its place.",
                "8.9.0: MessageBubble(markdown:) reads an answer's paragraphs, lists, headings, notes, bold and links; time: and status: put “14:20 · Read” under the bubble. Strings: message.sending, message.sent, message.read.",
            ]
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
