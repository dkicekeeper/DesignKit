//
//  FeedbackScreen.swift
//  DesignKit Gallery
//
//  Status and feedback: badges, banners, inline status, empty states, steps, progress, and the
//  skeleton primitives every component skeleton is made of.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct FeedbackScreen: View {
    static let title = "Status & Feedback"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        BadgePage()
        TrendBadgePage()
        StatusIndicatorBadgePage()
        StatusBannerPage()
        MessageBannerPage()
        InlineStatusTextPage()
        TooltipPage()
        SpotlightPage()
        TypingIndicatorPage()
        EmptyStatePage()
        StepTrackerPage()
        ImportProgressSheetPage()
        ProgressOverlayPage()
        PendingItemCardPage()
        NoticeCardPage()
        LoadMoreFooterPage()
        SkeletonPrimitivesPage()
    }
}

private struct LoadMoreFooterPage: View {
    @State private var state = 1
    @State private var showsMessage = false
    @State private var cardPlaceholder = false
    @State private var rows = 2
    @State private var loads = 0

    private var loadState: LoadMoreState {
        switch state {
        case 0: .more
        case 2: .failed(message: showsMessage ? "No connection" : nil)
        case 3: .end
        default: .loading
        }
    }

    var body: some View {
        ComponentPage(
            name: "LoadMoreFooter",
            summary: "The end of a list that loads in pages: it asks for the next page when it shows, placeholders while it comes, \"Couldn't load more\" with Retry, nothing at the end.",
            since: "4.1.0",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "The app maps its flags to LoadMoreState and keeps one request in flight; the footer may ask again while it stays on screen.",
                ".onReachEnd(of:in:threshold:) asks a few rows before the end (a feed of tall cards).",
                "Strings: loadMore.failed, common.retry.",
            ]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ForEach(0..<2, id: \.self) { index in
                    ItemRow("Review \(index + 1)", meta: [MetaLine([.text("Aida"), .text("3 days ago")])],
                            leading: .symbol("star.bubble"), verticalPadding: 0)
                }
                LoadMoreFooter(state: loadState, rows: rows, onLoad: { loads += 1 }) {
                    if cardPlaceholder {
                        ReviewCardSkeleton()
                    } else {
                        SkeletonRow()
                    }
                }
                Text("onLoad called \(loads) times")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.tertiary)
            }
        } controls: {
            ChoiceControl("State", selection: $state, options: [("More", 0), ("Loading", 1), ("Failed", 2), ("End", 3)])
            ToggleControl("Reason", isOn: $showsMessage)
            ToggleControl("Card placeholder", isOn: $cardPlaceholder)
            ChoiceControl("Rows", selection: $rows, options: [("1", 1), ("2", 2), ("3", 3)])
        }
    }
}

private struct PendingItemCardPage: View {
    @State private var state: SpecimenState = .content
    @State private var failed = true
    @State private var showsMessage = true
    @State private var showsContent = true
    @State private var showsSymbol = true
    @State private var showsTime = true
    @State private var ownQuestion = false
    @State private var log = ""

    var body: some View {
        ComponentPage(
            name: "PendingItemCard",
            summary: "Something made offline that is not on the server yet: its title and how long ago, waiting or failed with the reason, Retry and Delete (asks first), and its own content under it.",
            since: "3.6.0",
            apps: [.dalada],
            canvas: .fill,
            notes: [
                "The queue, the retry and the delete stay in the app: onRetry and onDiscard are async.",
                "discardConfirmation words Delete's question for the item (\"Delete the trip and its track?\"); pending.discard.confirm by default.",
                "Strings: pending.waiting, pending.failed, common.retry, pending.discard, pending.discard.confirm.",
            ]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if state == .loading {
                    PendingItemCardSkeleton(contentLines: showsContent ? 1 : 0)
                } else {
                    PendingItemCard(
                        title: "Morning on Kapchagay",
                        systemImage: showsSymbol ? "figure.fishing" : nil,
                        date: showsTime ? Date().addingTimeInterval(-300) : nil,
                        state: failed ? .failed(message: showsMessage ? "No connection" : "") : .waiting,
                        discardConfirmation: ownQuestion ? "Delete the trip and its track? It won’t reach the server." : nil,
                        onRetry: { log = "Retry" },
                        onDiscard: { log = "Deleted" }
                    ) {
                        if showsContent {
                            MetaLine([.text("14.2 km"), .text("3 h 10 min"), .label("2", systemImage: "photo.on.rectangle")])
                                .font(AppTypography.caption)
                        }
                    }
                }
                if !log.isEmpty {
                    Text(log)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Text.secondary)
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Failed", isOn: $failed)
            ToggleControl("Reason", isOn: $showsMessage)
            ToggleControl("Content", isOn: $showsContent)
            ToggleControl("Symbol", isOn: $showsSymbol)
            ToggleControl("Time", isOn: $showsTime)
            ToggleControl("Own Delete question", isOn: $ownQuestion)
        }
    }
}

private struct BadgePage: View {
    @State private var filled = false
    @State private var showsIcon = true
    @State private var tone = 0
    @State private var text = "Free camping"
    @State private var state: SpecimenState = .content

    private let tones: [(String, Color)] = [
        ("Accent", AppColors.accent), ("Positive", AppColors.Status.positive),
        ("Warning", AppColors.Status.warning), ("Negative", AppColors.Status.negative),
    ]

    var body: some View {
        ComponentPage(
            name: "Badge",
            summary: "A short label in a capsule: tinted (pale background, coloured text) or filled.",
            since: "0.4.0",
            apps: [.tenra, .dalada],
            styles: ["tinted", "filled"]
        ) {
            if state == .loading {
                BadgeSkeleton(width: 96)
            } else {
                Badge(text, systemImage: showsIcon ? "flame.fill" : nil, color: tones[tone].1,
                          style: filled ? .filled : .tinted)
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Colour", selection: $tone, options: tones.indices.map { (tones[$0].0, $0) })
            ToggleControl("Filled", isOn: $filled)
            ToggleControl("Icon", isOn: $showsIcon)
            TextControl("Text", text: $text)
        }
    }
}

private struct TrendBadgePage: View {
    @State private var change = 12.4
    @State private var style: TrendBadge.Style = .pill
    @State private var onColor = false
    @State private var state: SpecimenState = .content

    private var direction: TrendBadge.Direction { change > 0.5 ? .up : change < -0.5 ? .down : .flat }

    var body: some View {
        ComponentPage(
            name: "TrendBadge",
            summary: "A change in per cent with an arrow: green up, red down, grey flat (or your colour).",
            since: "0.4.0",
            apps: [.tenra],
            canvas: onColor ? .bleed : .standard,
            notes: ["Inside .heroBackground (4.5.0) it is white, the pill a translucent white capsule."],
            styles: ["pill", "inline", "changeIndicator"]
        ) {
            if state == .loading {
                TrendBadgeSkeleton(style: style)
            } else {
                TrendBadge(direction: direction, changePercent: change, style: style)
                    .galleryHeroBackground(onColor, color: AppColors.accent)
            }
        } controls: {
            StateControl(state: $state)
            HeroBackgroundControl(onColor: $onColor)
            SliderControl("Change", value: $change, in: -50...50, step: 0.1) { "\($0.formatted(.number.precision(.fractionLength(1))))%" }
            ChoiceControl("Style", selection: $style, options: [("Pill", .pill), ("Inline", .inline), ("Indicator", .changeIndicator)])
        }
    }
}

private struct StatusIndicatorBadgePage: View {
    @State private var status: EntityStatus = .active
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "StatusIndicatorBadge",
            summary: "The status of a subscription or loan: active, paused, archived, pending.",
            apps: [.tenra]
        ) {
            if state == .loading {
                StatusIndicatorBadgeSkeleton()
            } else {
                StatusIndicatorBadge(status: status)
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Status", selection: $status, options: [
                ("Active", .active), ("Paused", .paused), ("Archived", .archived), ("Pending", .pending),
            ])
        }
    }
}

private struct StatusBannerPage: View {
    @State private var status: StatusBanner.Status = .info
    @State private var compact = false
    @State private var hasAction = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "StatusBanner",
            summary: "A status message in a pale box of its colour, or inline; an optional action.",
            since: "1.7.0",
            apps: [.tenra, .dalada],
            canvas: .fill,
            styles: ["standard", "compact"]
        ) {
            if state == .loading {
                StatusBannerSkeleton(style: compact ? .compact : .standard)
            } else {
                StatusBanner("Offline. Changes will be sent when you are back online.", status: status,
                             style: compact ? .compact : .standard, action: hasAction ? {} : nil)
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Status", selection: $status, options: [
                ("Info", .info), ("Positive", .positive), ("Warning", .warning), ("Negative", .negative), ("Neutral", .neutral),
            ])
            ToggleControl("Compact", isOn: $compact)
            ToggleControl("Action", isOn: $hasAction)
        }
    }
}

private struct MessageBannerPage: View {
    @State private var type: MessageBanner.MessageType = .success
    @State private var hasAction = false

    var body: some View {
        ComponentPage(
            name: "MessageBanner",
            summary: "A floating banner on glass after something happened: saved, failed, a warning; with an action.",
            apps: [.tenra],
            canvas: .fill
        ) {
            if hasAction {
                MessageBanner(message: "Couldn't sync the last changes.", type: type, actionTitle: "Retry") {}
            } else {
                MessageBanner(message: "Transaction saved.", type: type)
            }
        } controls: {
            ChoiceControl("Type", selection: $type, options: [
                ("Success", .success), ("Error", .error), ("Warning", .warning), ("Info", .info),
            ])
            ToggleControl("Action", isOn: $hasAction)
        }
    }
}

private struct InlineStatusTextPage: View {
    @State private var type: InlineStatusText.StatusType = .error

    var body: some View {
        ComponentPage(
            name: "InlineStatusText",
            summary: "A one-line status under a form or a field: error, warning, info, success.",
            apps: [.tenra, .dalada],
            canvas: .fill
        ) {
            InlineStatusText(message: "Amount must be positive", type: type)
        } controls: {
            ChoiceControl("Type", selection: $type, options: [
                ("Error", .error), ("Warning", .warning), ("Info", .info), ("Success", .success),
            ])
        }
    }
}

private struct TooltipPage: View {
    @State private var text = "1 250 000 ₸"
    @State private var below = false
    @State private var amountStyle = true
    @State private var arrowAlignment: TooltipArrowAlignment = .center

    var body: some View {
        ComponentPage(
            name: "Tooltip",
            summary: "A short value or hint in an opaque bubble with a tail pointing at its target: the amount over a tapped bar.",
            since: "2.0.0",
            apps: [],
            notes: [
                "Put it in an overlay of its target with .tooltipAnchor(.top) (or .bottom with arrowEdge: .top), so it never moves the layout.",
                "A target by the edge of the screen takes arrowAlignment: .leading or .trailing (5.5.0): the tail sits by that corner, still over the target's middle, and the bubble runs on to the side with room.",
                "A hint longer than 280 pt wraps into lines (5.5.0); a value stays on one line.",
                "Give the target a higher zIndex than its neighbours while the tooltip shows.",
                "It shows a value already on screen, on a tap, so it has no skeleton.",
            ]
        ) {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.accent)
                .frame(width: 64, height: 80)
                .overlay(alignment: below ? .bottom : .top) {
                    tooltip
                        .tooltipAnchor(below ? .bottom : .top)
                }
                .padding(.vertical, AppSpacing.xxxl + AppSpacing.lg)
                // A corner tail is for a target by that edge: the target goes there.
                .frame(maxWidth: .infinity, alignment: targetAlignment)
        } controls: {
            ChoiceControl("Tail", selection: $below, options: [("Bottom (above the target)", false), ("Top (below the target)", true)])
            ChoiceControl("Tail position", selection: $arrowAlignment, options: [("Leading", .leading), ("Center", .center), ("Trailing", .trailing)])
            ToggleControl("Amount style", isOn: $amountStyle)
            TextControl("Text", text: $text)
        }
    }

    private var targetAlignment: Alignment {
        switch arrowAlignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    @ViewBuilder
    private var tooltip: some View {
        if amountStyle {
            Tooltip(arrowEdge: below ? .top : .bottom, arrowAlignment: arrowAlignment) {
                Text(text)
                    .font(AppTypography.numbers(AppTypography.bodySmall.bold()))
                    .foregroundStyle(AppColors.accent)
            }
        } else {
            Tooltip(text, arrowEdge: below ? .top : .bottom, arrowAlignment: arrowAlignment)
        }
    }
}

private struct TypingIndicatorPage: View {
    @State private var isTyping = true
    @State private var tint = 0

    var body: some View {
        ComponentPage(
            name: "TypingIndicator",
            summary: "Three dots rising in a wave in a bubble: a reply is on its way, an assistant is thinking.",
            since: "2.2.0",
            apps: [.tenra],
            canvas: .tall(minHeight: 120),
            notes: [
                "Insert it with .transition(.popIn) under the last message.",
                "30 fps from the time, only while AmbientMotionGate allows; otherwise the dots stand still. VoiceOver: “Typing”.",
            ]
        ) {
            ZStack {
                if isTyping {
                    TypingIndicator(tint: tint == 0 ? AppColors.Text.secondary : AppColors.accent)
                        .transition(.popIn)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        } controls: {
            ActionControl(isTyping ? "Reply arrived" : "Start typing") {
                withAnimation(AppAnimation.bouncy) { isTyping.toggle() }
            }
            ChoiceControl("Dots", selection: $tint, options: [("Secondary", 0), ("Accent", 1)])
        }
    }
}

private struct EmptyStatePage: View {
    @State private var style: EmptyState.Style = .standard
    @State private var hasAction = true
    @State private var hasDescription = true
    @State private var mascot = false
    @State private var greeted = 0

    var body: some View {
        ComponentPage(
            name: "EmptyState",
            summary: "Nothing to show yet, or a failure: an icon, a title, a line of explanation and an action.",
            apps: [.tenra, .dalada],
            canvas: .tall(minHeight: 280),
            notes: [
                "The icon draws itself on (2.2.0) in an SF Symbols 7 gradient (2.3.0); the error icon wiggles once.",
                "Artwork (4.13.0): EmptyState(title:description:actionTitle:action:) { … } puts any picture in place of the icon, such as an app's mascot pointing at the button.",
            ],
            styles: ["standard", "compact", "error"]
        ) {
            if mascot {
                EmptyState(
                    title: "No goals yet",
                    description: hasDescription ? "Save towards something and see how close it is." : nil,
                    actionTitle: hasAction ? "New goal" : nil,
                    action: hasAction ? {} : nil
                ) {
                    ParticleCreature(mood: .happy, speech: CreatureSpeech("Shall we save for something?", id: greeted))
                        .creatureGesture(.point(.down), trigger: greeted)
                        .frame(width: 140, height: 140)
                        .padding(.top, 60)
                        .task { greeted += 1 }
                }
            } else {
                EmptyState(
                    icon: style == .error ? "wifi.slash" : "tray",
                    title: style == .error ? "Couldn't load" : "No transactions yet",
                    description: hasDescription ? (style == .error ? "Check the connection and try again." : "Add the first one with +.") : nil,
                    actionTitle: hasAction ? (style == .error ? "Retry" : "Add") : nil,
                    action: hasAction ? {} : nil,
                    style: style
                )
            }
        } controls: {
            ChoiceControl("Style", selection: $style, options: [("Standard", .standard), ("Compact", .compact), ("Error", .error)])
            ToggleControl("Description", isOn: $hasDescription)
            ToggleControl("Action", isOn: $hasAction)
            ToggleControl("Mascot artwork", isOn: $mascot)
        }
    }
}

private struct StepTrackerPage: View {
    @State private var current = 1
    @State private var showsLabels = true

    var body: some View {
        ComponentPage(
            name: "StepTracker",
            summary: "Where a multi-step process is: done, current, upcoming.",
            since: "0.6.0",
            apps: [.tenra, .dalada],
            canvas: .fill
        ) {
            StepTracker(steps: ["Place", "Details", "Photos", "Publish"], current: current, showsLabels: showsLabels)
        } controls: {
            StepperControl("Current step", value: $current, in: 0...3)
            ToggleControl("Labels", isOn: $showsLabels)
        }
    }
}

private struct ImportProgressSheetPage: View {
    @State private var progress = 0.4

    var body: some View {
        ComponentPage(
            name: "ImportProgressSheet",
            summary: "A long import's progress: rows done of the total, a bar, Cancel.",
            apps: [.tenra],
            canvas: .tall(minHeight: 240)
        ) {
            ImportProgressSheet(currentRow: Int(progress * 250), totalRows: 250, progress: progress) {}
        } controls: {
            SliderControl("Progress", value: $progress, in: 0...1, step: 0.01) { "\(Int($0 * 100))%" }
        }
    }
}

private struct SkeletonPrimitivesPage: View {
    @State private var shimmers = true

    var body: some View {
        ComponentPage(
            name: "Skeleton primitives",
            summary: "The shapes every component skeleton is made of: a block, a line of text by its style, a circle, a capsule, a row.",
            since: "0.6.0",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                "Each component's own skeleton is its “Loading” state on its page.",
                "A skeleton keeps its component's container and corner; a shape with no corner of its own takes AppRadius.soft.",
            ]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Skeleton(height: 48)
                SkeletonText(AppTypography.h3, width: 160)
                SkeletonText(AppTypography.body, lines: 2)
                HStack(spacing: AppSpacing.md) {
                    Skeleton.circle(AppIconSize.Tile.sm)
                    IconSkeleton(style: .roundedSquare(size: AppIconSize.Tile.sm))
                    Skeleton.capsule(height: 32, width: 96)
                }
                SkeletonRow()
            }
            .skeletonShimmer(shimmers)
        } controls: {
            ToggleControl("Shimmer", isOn: $shimmers)
        }
    }
}

private struct ProgressOverlayPage: View {
    @State private var isPresented = false
    @State private var showsMessage = true

    var body: some View {
        ComponentPage(
            name: ".progressOverlay",
            summary: "The screen waits for something it cannot do without: it dims, and a material panel shows a spinner, what is happening and what it means.",
            since: "2.9.0",
            apps: [.tenra],
            canvas: .tall(minHeight: 260),
            notes: ["For a restore, a migration, an import that must finish first. Disable the screen under it at the call site."]
        ) {
            VStack(spacing: AppSpacing.md) {
                Text("Settings")
                    .font(AppTypography.h3)
                Button(isPresented ? "Finish" : "Restore a backup") { isPresented.toggle() }
                    .dsButton(.secondary)
                    .zIndex(3)
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .progressOverlay(
                isPresented: isPresented,
                title: "Restoring the backup",
                message: showsMessage ? "Your data will be back in a moment." : nil
            )
            .animation(AppAnimation.gentleSpring, value: isPresented)
        } controls: {
            ToggleControl("Shown", isOn: $isPresented)
            ToggleControl("Message", isOn: $showsMessage)
        }
    }
}

private struct NoticeCardPage: View {
    @State private var showsLeading = true
    @State private var hasAction = true
    @State private var canHide = true
    @State private var state: SpecimenState = .content
    @State private var log = ""

    var body: some View {
        ComponentPage(
            name: "NoticeCard",
            summary: "A message the app writes to the person: a picture, a title and a line or two, a hide button and an action under the text, in line with it.",
            since: "4.14.0",
            apps: [.tenra],
            canvas: .fill,
            notes: [
                "What the message is, when it shows and what the action does stay in the app.",
                "The leading view comes at its own size, NoticeCardMetrics.leadingSize (48 pt) for a mascot or an icon; hide it from VoiceOver when it says nothing.",
                "5.2.0: the action moved into the text's column, so it starts where the text does.",
                "Strings: common.hide (the hide button's VoiceOver name, unless hideLabel is given).",
            ]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if state == .loading {
                    NoticeCardSkeleton(leadingSize: showsLeading ? NoticeCardMetrics.leadingSize : nil, showsAction: hasAction)
                } else {
                    NoticeCard(
                        title: "A payment is due tomorrow",
                        message: "Internet, 12 000 ₸. There is enough on the card.",
                        actionTitle: hasAction ? "Go through it" : nil,
                        actionSystemImage: "sparkles",
                        action: hasAction ? { log = "Go through it" } : nil,
                        onHide: canHide ? { log = "Hidden" } : nil
                    ) {
                        if showsLeading {
                            ParticleCreature(mood: .worried, style: .compact)
                                .frame(width: NoticeCardMetrics.leadingSize, height: NoticeCardMetrics.leadingSize)
                                .accessibilityHidden(true)
                        }
                    }
                }
                if !log.isEmpty {
                    Text(log)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Text.secondary)
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Picture", isOn: $showsLeading)
            ToggleControl("Action", isOn: $hasAction)
            ToggleControl("Hide button", isOn: $canHide)
        }
    }
}

#Preview { NavigationStack { FeedbackScreen() } }

/// A coach mark: the screen dims except one view (2.6.0).
private struct SpotlightPage: View {
    private enum Step: Int, CaseIterable {
        case filter, balance, add, insights

        var message: String {
            switch self {
            case .filter: "Filter by account or period. Here too: which transfers count and which accounts the totals take."
            case .balance: "Your balance across every account."
            case .add: "Add an expense or an income here."
            case .insights: "See where the money went."
            }
        }
    }

    @State private var step: Step?

    var body: some View {
        ComponentPage(
            name: ".spotlight",
            summary: "A coach mark: everything dims except a cut-out round one view, with a message beside it. For a new feature or the steps of a tour on the real screen.",
            since: "2.6.0",
            apps: [.tenra, .dalada],
            canvas: .tall(minHeight: 340),
            notes: [
                "Mark views with .spotlightAnchor(id); put .spotlight($current, message:) on the screen. Another id moves the cut-out there on a spring; nil lifts it.",
                "A tap anywhere calls onTap (the next step), or lifts it. VoiceOver reads the message; the escape gesture dismisses it.",
                "By the edge of the screen the message keeps off it and its tail moves to stay over the view (5.5.0): the filter button in the corner. A long message wraps inside the screen's margins.",
            ]
        ) {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    Text(verbatim: "Home")
                        .font(AppTypography.h3)
                    Spacer()
                    DSButton("Filter", systemImage: "line.3.horizontal.decrease", iconPlacement: .only, appearance: .secondary) {}
                        .spotlightAnchor(Step.filter)
                }
                BalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold", amount: 1_250_000, currency: "KZT")
                    .spotlightAnchor(Step.balance)
                HStack(spacing: AppSpacing.md) {
                    DSButton("Add", systemImage: "plus") {}
                        .spotlightAnchor(Step.add)
                    DSButton("Insights", systemImage: "chart.pie", appearance: .secondary) {}
                        .spotlightAnchor(Step.insights)
                }
            }
            .padding(AppSpacing.md)
            .spotlight($step, message: { $0.message }) {
                step = step.flatMap { Step(rawValue: $0.rawValue + 1) }
            }
        } controls: {
            ActionControl(step == nil ? "Start the tour" : "End the tour", systemImage: "lightbulb") {
                step = step == nil ? .filter : nil
            }
        }
    }
}
