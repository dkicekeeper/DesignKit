//
//  PatternsScreen.swift
//  DesignKit Gallery
//
//  Whole screens put together from DesignKit's components, as docs/design-system.md §4 describes
//  them (docs/benchmark.md 24). The screens themselves stay in the apps: these show that the
//  pieces fit, with sample data and no app model. Each keeps to `.readableWidth()`, so an iPad
//  shows the column a large screen gets.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct PatternsScreen: View {
    static let title = "Patterns"

    @State private var showsEditSheet = false
    @State private var showsOnboarding = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                FormSection(header: "Screens",
                            footer: "Each is a whole screen made of DesignKit's components only, as docs/design-system.md §4 describes it. The apps build theirs over their own models.") {
                    UniversalRow("Settings", icon: "gearshape",
                                 hint: "FormSection cards of UniversalRow: menus, switches, a screen, actions",
                                 accessory: .navigation { SettingsPattern() })
                    UniversalRow("Detail", icon: "creditcard",
                                 hint: "HeroSection, two DSButtons, info rows, a day of TransactionRows",
                                 accessory: .navigation { DetailPattern() })
                    UniversalRow("Things a person keeps", icon: "square.stack",
                                 hint: "CardList and its toolbar; loading, empty and error",
                                 accessory: .navigation { KeptListPattern() })
                    UniversalRow("Dashboard", icon: "square.grid.2x2",
                                 hint: "StatsStrip, BalanceCards in a carousel, CashFlowCard, ProgressRingTileGrid",
                                 accessory: .navigation { DashboardPattern() })
                    UniversalRow("Conversation", icon: "bubble.left.and.bubble.right",
                                 hint: "MessageBubble, ConversationDivider, TypingIndicator, SuggestionChips, MessageComposer",
                                 accessory: .navigation { ConversationPattern() })
                }
                FormSection(header: "Sheets and flows") {
                    UniversalRow("Edit sheet", icon: "square.and.pencil",
                                 hint: "EditSheetContainer over FormSection cards, InlineStatusText",
                                 accessory: .action { showsEditSheet = true })
                    UniversalRow("Onboarding", icon: "hand.wave",
                                 hint: "OnboardingPager of OnboardingPages, DSButtons",
                                 accessory: .action { showsOnboarding = true })
                }
            }
            .screenPadding()
            .padding(.vertical, AppSpacing.md)
            .readableWidth()
        }
        .navigationTitle(Self.title)
        .sheet(isPresented: $showsEditSheet) { EditSheetPattern() }
        .fullScreenCover(isPresented: $showsOnboarding) {
            SampleOnboarding { showsOnboarding = false }
        }
    }
}

// MARK: - Settings

/// docs/design-system.md §4, Lists: settings. Glass sections of rows on the page; no `List`.
private struct SettingsPattern: View {
    @State private var currency = "KZT"
    @State private var appearance = 0
    @State private var language = "English"
    @State private var reminders = true
    @State private var daysBefore = 1
    @State private var sounds = false
    @State private var confirmsDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                FormSection(header: "General") {
                    UniversalRow("Main currency", icon: "dollarsign.circle",
                                 accessory: .menu($currency, options: [
                                     (label: "Tenge", value: "KZT"),
                                     (label: "Dollar", value: "USD"),
                                     (label: "Euro", value: "EUR"),
                                 ]))
                    UniversalRow("Appearance", icon: "circle.lefthalf.filled",
                                 accessory: .menu($appearance, options: [
                                     (label: "System", value: 0),
                                     (label: "Light", value: 1),
                                     (label: "Dark", value: 2),
                                 ]))
                    UniversalRow("Language", icon: "globe", value: language,
                                 accessory: .navigation { LanguagePattern(selection: $language) })
                }
                FormSection(header: "Reminders", footer: "A reminder arrives before a payment is due.") {
                    UniversalRow("Reminders", icon: "bell", accessory: .toggle($reminders))
                    if reminders {
                        UniversalRow("Days before", icon: "calendar.badge.clock",
                                     accessory: .stepper($daysBefore, in: 1...7, format: { $0 == 1 ? "1 day" : "\($0) days" }))
                        UniversalRow("Sounds", icon: "speaker.wave.2", accessory: .toggle($sounds))
                    }
                }
                FormSection(header: "Data") {
                    UniversalRow("Export", icon: "square.and.arrow.up", accessory: .action {})
                    UniversalRow("Delete all data", icon: "trash", role: .destructive,
                                 accessory: .action { confirmsDelete = true })
                }
            }
            .screenPadding()
            .padding(.vertical, AppSpacing.md)
            .readableWidth()
        }
        .navigationTitle("Settings")
        .animation(AppAnimation.contentSpring, value: reminders)
        .confirmationDialog("Delete all data?", isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {}
        } message: {
            Text("Accounts, transactions and settings leave this device.")
        }
    }
}

/// A screen a settings row opens: one choice out of a list, a check on the picked one.
private struct LanguagePattern: View {
    @Binding var selection: String

    private let languages = ["English", "Kazakh", "Russian"]

    var body: some View {
        ScrollView {
            FormSection {
                ForEach(languages, id: \.self) { language in
                    UniversalRow(language, accessory: .checkmark(isSelected: language == selection) {
                        selection = language
                    })
                }
            }
            .screenPadding()
            .padding(.vertical, AppSpacing.md)
            .readableWidth()
        }
        .navigationTitle("Language")
    }
}

// MARK: - Detail

/// docs/design-system.md §4, Detail screen: the hero, its actions, the facts, then the history by
/// day (Tenra's entity screens).
private struct DetailPattern: View {
    private let icon = IconSource.sfSymbol("creditcard.fill")
    private let tint = IconTint.monochrome(.orange)
    private let account = TransactionRow.Account(name: "Kaspi Gold", icon: .sfSymbol("creditcard.fill"))

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                HeroSection(icon: icon, title: "Kaspi Gold", iconTint: tint,
                            primaryAmount: 1_250_000, primaryCurrency: "KZT", subtitle: "Card account")
                    .screenPadding()
                    .scrollHero()

                // The glass buttons share one sampling region (glass cannot sample glass).
                GlassEffectContainer(spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.md) {
                        DSButton("Top up", systemImage: "plus", iconPlacement: .top) {}
                        DSButton("Transfer", systemImage: "arrow.left.arrow.right", iconPlacement: .top) {}
                    }
                }
                .screenPadding()

                FormSection {
                    UniversalRow("Bank", icon: "building.columns", config: .info, accessory: .info("Kaspi"))
                    UniversalRow("Opened", icon: "calendar", config: .info, accessory: .info("12 March 2024"))
                    UniversalRow("Card", icon: "creditcard", config: .info, accessory: .info("•• 4417"))
                }
                .screenPadding()

                today
                    .screenPadding()
            }
            .padding(.vertical, AppSpacing.md)
            .readableWidth()
        }
        .heroAccentGlow(icon: icon, tint: tint)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit", systemImage: "pencil") {}
                    Button("Delete", systemImage: "trash", role: .destructive) {}
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }

    /// One day of the history: a card with the day and its total on top, a divider under each
    /// row's text.
    private var today: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionHeader("Today")
                Spacer()
                FormattedAmountText(amount: 23_400, currency: "KZT", prefix: "-",
                                    fontSize: AppTypography.bodySmall, fontWeight: .semibold,
                                    color: AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.md)

            TransactionRow(
                .entry(title: "Groceries", details: "Vegetables, Bread", account: account),
                note: "Magnum",
                icon: .sfSymbol("cart.fill"), iconTint: .monochrome(.orange),
                iconBackground: AppColors.pale(.orange),
                amounts: [.init(18_500, currency: "KZT", prefix: "-")],
                accessibilityLabel: "Groceries, 18 500 tenge, Kaspi Gold"
            )
            RowDivider(inset: AppIconSize.Tile.sm + AppSpacing.md)
            TransactionRow(
                .entry(title: "Cafés", account: account),
                icon: .sfSymbol("cup.and.saucer.fill"), iconTint: .monochrome(.brown),
                iconBackground: AppColors.pale(.brown),
                amounts: [.init(4_900, currency: "KZT", prefix: "-")],
                accessibilityLabel: "Cafés, 4 900 tenge, Kaspi Gold"
            )
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Things a person keeps

/// docs/design-system.md §4, Lists, and "Empty, loading, error": a `CardList` with its toolbar
/// (a tap opens, a long press shows Edit and Delete, the toolbar selects, reorders and adds), its
/// skeleton while loading and `EmptyState` when there is nothing or it failed.
private struct KeptListPattern: View {
    struct Trip: Identifiable, Hashable {
        let id: Int
        let name: String
        let symbol: String
        let dates: String
        let distance: String
    }

    enum LoadState: String, CaseIterable, Identifiable {
        case loaded = "Loaded"
        case loading = "Loading"
        case empty = "Empty"
        case failed = "Error"

        var id: Self { self }
    }

    private static let samples: [Trip] = [
        Trip(id: 0, name: "Altai in June", symbol: "figure.hiking", dates: "12–18 Jun", distance: "64 km"),
        Trip(id: 1, name: "Kapchagay, pike", symbol: "figure.fishing", dates: "3 Aug", distance: "6 km"),
        Trip(id: 2, name: "Kolsai lakes", symbol: "tent.fill", dates: "22–24 Sep", distance: "21 km"),
        Trip(id: 3, name: "Charyn canyon", symbol: "mountain.2.fill", dates: "12 Oct", distance: "9 km"),
    ]

    @State private var trips: [Trip] = Self.samples
    @State private var state: LoadState = .loaded
    @State private var mode: CardListMode = .browsing
    @State private var selection: Set<Int> = []

    var body: some View {
        ScrollView {
            content
                .screenPadding()
                .padding(.vertical, AppSpacing.md)
                .readableWidth()
        }
        .navigationTitle("Trips")
        .cardListToolbar(
            mode: $mode,
            selection: $selection,
            allIDs: trips.map(\.id),
            addLabel: "New trip",
            onAdd: { add() },
            onDeleteSelected: {
                trips.removeAll { selection.contains($0.id) }
                selection.removeAll()
                mode = .browsing
            }
        )
        // The Gallery's own control: the states the screen goes through.
        .safeAreaBar(edge: .bottom) {
            if mode == .browsing {
                Picker("State", selection: $state) {
                    ForEach(LoadState.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .screenPadding()
                .padding(.bottom, AppSpacing.sm)
            }
        }
        .animation(AppAnimation.contentSpring, value: state)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            CardListSkeleton(layout: .cards, count: 4)
        case .failed:
            EmptyState(title: "Trips did not load", description: "Check the connection and try again.",
                       actionTitle: "Try again", action: { state = .loaded }, style: .error)
        case .empty:
            empty
        case .loaded:
            if trips.isEmpty {
                empty
            } else {
                CardList(trips, layout: .cards, mode: mode, selection: $selection,
                         onMove: { trips.move(fromOffsets: $0, toOffset: $1) }) { trip in
                    ItemRow(trip.name, meta: [MetaLine([.text(trip.dates), .text(trip.distance)])],
                            leading: .symbol(trip.symbol), titleLineLimit: 1, verticalPadding: 0)
                        .contextMenu {
                            Button("Edit", systemImage: "pencil") {}
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                trips.removeAll { $0.id == trip.id }
                            }
                        }
                }
                .transition(.skeletonReveal)
            }
        }
    }

    private var empty: some View {
        EmptyState(icon: "map", title: "No trips yet",
                   description: "A trip keeps its places, its people and its packing list.",
                   actionTitle: "New trip", action: { add() })
    }

    private func add() {
        let next = (trips.map(\.id).max() ?? -1) + 1
        trips.append(Trip(id: next, name: "New trip", symbol: "map", dates: "Today", distance: "0 km"))
        state = .loaded
    }
}

// MARK: - Dashboard

/// docs/design-system.md §4, Dashboard: the summaries a home screen opens on (Tenra's Home and
/// Finances).
private struct DashboardPattern: View {
    private struct Account: Identifiable {
        let title: String
        let symbol: String
        let amount: Double

        var id: String { title }
    }

    private let accounts = [
        Account(title: "Kaspi Gold", symbol: "creditcard.fill", amount: 1_250_000),
        Account(title: "Halyk Deposit", symbol: "lock.fill", amount: 820_000),
        Account(title: "Cash", symbol: "banknote.fill", amount: 45_000),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                StatsStrip(items: [
                    .init(value: "2.1M ₸", title: "on accounts"),
                    .init(value: "312K ₸", title: "spent this month"),
                    .init(value: "14", title: "days in a row"),
                ])
                .screenPadding()

                UniversalCarousel(config: .cards) {
                    ForEach(accounts) { account in
                        BalanceCard(iconSource: .sfSymbol(account.symbol), title: account.title,
                                    amount: account.amount, currency: "KZT")
                    }
                }
                .screenPadding()

                CashFlowCard(title: "This month",
                             totals: .init(income: 450_000, expenses: 312_000),
                             currency: "KZT", emptyMessage: "No transactions yet")
                    .screenPadding()

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    SectionHeader("Budgets")
                    ProgressRingTileGrid(items: GallerySamples.tileItems, currency: "KZT") { _ in }
                }
                .screenPadding()
            }
            .padding(.vertical, AppSpacing.md)
            .readableWidth()
        }
        .navigationTitle("Home")
    }
}

// MARK: - Conversation

/// An assistant's chat (Tenra's Ten, Platina's Plati): bubbles under a day, the reply in Markdown,
/// the dots while it thinks, suggestions and the field in a bar the messages scroll under.
private struct ConversationPattern: View {
    struct Message: Identifiable {
        let id = UUID()
        let text: String
        let role: MessageBubble.Role
        let time: Date
        var status: MessageBubble.Status? = nil
    }

    @State private var messages: [Message] = [
        Message(text: "How much did I spend on food this month?", role: .outgoing,
                time: .now.addingTimeInterval(-600), status: .read),
        Message(text: "**48 200 ₸** on food, 12% less than in October:\n\n- Groceries: 36 700 ₸\n- Cafés: 11 500 ₸",
                role: .incoming, time: .now.addingTimeInterval(-590)),
    ]
    @State private var text = ""
    @State private var isThinking = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.sm) {
                ConversationDivider(date: .now)
                ForEach(messages) { message in
                    bubble(message)
                }
                if isThinking {
                    TypingIndicator()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .screenPadding()
            .padding(.vertical, AppSpacing.md)
            .readableWidth()
        }
        .defaultScrollAnchor(.bottom)
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaBar(edge: .bottom) {
            VStack(spacing: AppSpacing.sm) {
                if messages.count <= 2 && !isThinking {
                    SuggestionChips(["What is due this week?", "Where can I save?"],
                                    systemImage: "sparkles", inset: AppSpacing.lg) { send($0) }
                }
                MessageComposer(text: $text, placeholder: "Ask about your money…", isSending: isThinking) {
                    send(text)
                }
                .screenPadding()
            }
            .padding(.bottom, AppSpacing.sm)
            .readableWidth()
        }
        .navigationTitle("Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .animation(AppAnimation.contentSpring, value: messages.count)
        .animation(AppAnimation.contentSpring, value: isThinking)
    }

    @ViewBuilder
    private func bubble(_ message: Message) -> some View {
        if message.role == .incoming {
            MessageBubble(markdown: message.text, time: message.time)
        } else {
            MessageBubble(message.text, role: .outgoing, time: message.time, status: message.status)
        }
    }

    private func send(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        messages.append(Message(text: trimmed, role: .outgoing, time: .now, status: .sent))
        text = ""
        isThinking = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            isThinking = false
            messages.append(Message(text: "This is the Gallery, so the reply is a sample. In an app it comes from the assistant.",
                                    role: .incoming, time: .now))
        }
    }
}

// MARK: - Edit sheet

/// docs/design-system.md §4, Edit sheet: ✕ and ✓ in the toolbar over glass cards of rows, the
/// validation under them (Dalada's forms; Tenra's sheets add an `EditableHero` on top).
private struct EditSheetPattern: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = "Altai in June"
    @State private var kind = "hike"
    @State private var start = Date.now
    @State private var nights = 5
    @State private var shares = true
    @State private var notes = ""
    @State private var isSaving = false

    private var isNameMissing: Bool { name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        EditSheetContainer(
            title: "Edit trip",
            isSaveDisabled: isNameMissing,
            isSaving: isSaving,
            wrapInForm: false,
            onSave: { save() },
            onCancel: { dismiss() }
        ) {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    FormSection(header: "Trip") {
                        FormTextField(text: $name, placeholder: "Name", style: .row)
                        UniversalRow("Kind", icon: "figure.hiking",
                                     accessory: .menu($kind, options: [
                                         (label: "Hike", value: "hike"),
                                         (label: "Fishing", value: "fishing"),
                                         (label: "Camp", value: "camp"),
                                     ]))
                        UniversalRow("Start", icon: "calendar", accessory: .date($start))
                        UniversalRow("Nights", icon: "moon.stars", accessory: .stepper($nights, in: 1...30))
                    }
                    FormSection(footer: "Members see the plan and the packing list.") {
                        UniversalRow("Share with members", icon: "person.2", accessory: .toggle($shares))
                    }
                    FormSection(header: "Notes") {
                        FormTextField(text: $notes, placeholder: "What to remember",
                                      style: .rowMultiline(min: 3, max: 6))
                    }
                    if isNameMissing {
                        InlineStatusText(message: "A trip needs a name.", type: .warning)
                    }
                }
                .screenPadding()
                .padding(.vertical, AppSpacing.md)
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            dismiss()
        }
    }
}

#Preview { NavigationStack { PatternsScreen() } }
