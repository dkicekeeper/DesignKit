//
//  ContentScreen.swift
//  DesignKit Gallery
//
//  Content and layout: folded text, timeline, month calendar, flow layout, form sections, the
//  edit sheet and its hero.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct ContentScreen: View {
    var body: some View {
        ShowcasePage(title: "Content & Layout") {
            ExpandableTextPage()
            ActivityTimelinePage()
            MonthCalendarPage()
            FlowLayoutPage()
            FormSectionPage()
            EditSheetContainerPage()
            EditableHeroPage()
            ArticleBodyPage()
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

    private let tags = ["Lake", "Free camping", "Fire allowed", "No motorboats", "Pike", "Road: 4x4", "Toilets", "Kids", "Shade"]

    var body: some View {
        ComponentPage(
            name: "FlowLayout",
            summary: "A layout that wraps its views to new lines like words: tags, badges, chips.",
            since: "0.7.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            FlowLayout(spacing: spacing, lineSpacing: spacing) {
                ForEach(tags.prefix(count), id: \.self) {
                    Badge($0, color: AppColors.accent)
                }
            }
        } controls: {
            SliderControl("Spacing", value: $spacing, in: 0...24, step: 2) { "\(Int($0)) pt" }
            StepperControl("Items", value: $count, in: 1...9)
        }
    }
}

private struct FormSectionPage: View {
    @State private var showsHeader = true
    @State private var showsFooter = true
    @State private var title = "Groceries"
    @State private var note = ""

    var body: some View {
        ComponentPage(
            name: "FormSection",
            summary: "A titled group of form rows on a material card, with a footer.",
            apps: [.tenra],
            canvas: .fill,
            notes: [
                "Material, not glass: native menus in it morph from it otherwise.",
                "The section adds no padding: its rows pad themselves (docs/design-system.md §10). A field goes in a row's trailing slot, UniversalRow(config: .standard), with a Divider between rows.",
            ]
        ) {
            FormSection(header: showsHeader ? "Transaction" : nil, footer: showsFooter ? "Shown on the transaction detail." : nil) {
                UniversalRow(config: .standard) {
                    Text("Title").font(AppTypography.body)
                } trailing: {
                    FormTextField(text: $title, placeholder: "Title", style: .inline)
                }
                Divider().padding(.leading, AppSpacing.lg)
                UniversalRow(config: .standard) {
                    Text("Note").font(AppTypography.body)
                } trailing: {
                    FormTextField(text: $note, placeholder: "Optional", style: .inline)
                }
            }
        } controls: {
            ToggleControl("Header", isOn: $showsHeader)
            ToggleControl("Footer", isOn: $showsFooter)
        }
    }
}

private struct EditSheetContainerPage: View {
    @State private var isPresented = false
    @State private var name = "Kaspi Gold"

    var body: some View {
        ComponentPage(
            name: "EditSheetContainer",
            summary: "The shell of an edit sheet: navigation bar with Cancel and Save, a form inside.",
            apps: [.tenra]
        ) {
            DSButton("Open the sheet", appearance: .secondary, fullWidth: true) { isPresented = true }
            .sheet(isPresented: $isPresented) {
                EditSheetContainer(
                    title: "Edit account",
                    isSaveDisabled: name.isEmpty,
                    onSave: { isPresented = false },
                    onCancel: { isPresented = false }
                ) {
                    Section("Name") {
                        TextField("Account name", text: $name)
                    }
                }
            }
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
            apps: [.dalada],
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
