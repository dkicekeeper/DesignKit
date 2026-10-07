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
    var body: some View {
        ShowcasePage(title: "Status & Feedback") {
            BadgePage()
            TrendBadgePage()
            StatusIndicatorBadgePage()
            StatusBannerPage()
            MessageBannerPage()
            InlineStatusTextPage()
            TooltipPage()
            TypingIndicatorPage()
            EmptyStatePage()
            StepTrackerPage()
            ImportProgressSheetPage()
            SkeletonPrimitivesPage()
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
            apps: [.tenra, .dalada]
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
    @State private var state: SpecimenState = .content

    private var direction: TrendBadge.Direction { change > 0.5 ? .up : change < -0.5 ? .down : .flat }

    var body: some View {
        ComponentPage(
            name: "TrendBadge",
            summary: "A change in per cent with an arrow: green up, red down, grey flat (or your colour).",
            since: "0.4.0",
            apps: [.tenra]
        ) {
            if state == .loading {
                TrendBadgeSkeleton(style: style)
            } else {
                TrendBadge(direction: direction, changePercent: change, style: style)
            }
        } controls: {
            StateControl(state: $state)
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
            canvas: .fill
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
            apps: [.tenra],
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

    var body: some View {
        ComponentPage(
            name: "Tooltip",
            summary: "A short value or hint in an opaque bubble with a tail pointing at its target: the amount over a tapped bar.",
            since: "2.0.0",
            apps: [.tenra],
            notes: [
                "Put it in an overlay of its target with .tooltipAnchor(.top) (or .bottom with arrowEdge: .top), so it never moves the layout.",
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
                .frame(maxWidth: .infinity)
        } controls: {
            ChoiceControl("Tail", selection: $below, options: [("Bottom (above the target)", false), ("Top (below the target)", true)])
            ToggleControl("Amount style", isOn: $amountStyle)
            TextControl("Text", text: $text)
        }
    }

    @ViewBuilder
    private var tooltip: some View {
        if amountStyle {
            Tooltip(arrowEdge: below ? .top : .bottom) {
                Text(text)
                    .font(AppTypography.numbers(AppTypography.bodySmall.bold()))
                    .foregroundStyle(AppColors.accent)
            }
        } else {
            Tooltip(text, arrowEdge: below ? .top : .bottom)
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
            apps: [.dalada],
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

    var body: some View {
        ComponentPage(
            name: "EmptyState",
            summary: "Nothing to show yet, or a failure: an icon, a title, a line of explanation and an action.",
            apps: [.tenra, .dalada],
            canvas: .tall(minHeight: 280)
        ) {
            EmptyState(
                icon: style == .error ? "wifi.slash" : "tray",
                title: style == .error ? "Couldn't load" : "No transactions yet",
                description: hasDescription ? (style == .error ? "Check the connection and try again." : "Add the first one with +.") : nil,
                actionTitle: hasAction ? (style == .error ? "Retry" : "Add") : nil,
                action: hasAction ? {} : nil,
                style: style
            )
        } controls: {
            ChoiceControl("Style", selection: $style, options: [("Standard", .standard), ("Compact", .compact), ("Error", .error)])
            ToggleControl("Description", isOn: $hasDescription)
            ToggleControl("Action", isOn: $hasAction)
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
            apps: [.dalada],
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

#Preview { NavigationStack { FeedbackScreen() } }
