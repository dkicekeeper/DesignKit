//
//  DataRowsScreen.swift
//  DesignKit Gallery
//
//  Rows that show data: balances, breakdowns, budgets, schedules, people, comments, checklists,
//  pictures.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct DataRowsScreen: View {
    var body: some View {
        ShowcasePage(title: "Rows: Data") {
            BalanceRowPage()
            BreakdownRowPage()
            ProgressRingRowPage()
            InsightEntityRowPage()
            NetAmountRowPage()
            ScheduleRowPage()
            PersonRowPage()
            CommentRowPage()
            ChecklistRowPage()
            ChecklistSummaryRowPage()
            ThumbnailRowPage()
        }
    }
}

/// Data rows sit in a glass card in the apps; the preview does the same.
private struct InCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) { content }
            .cardContentPadding()
            .cardStyle()
    }
}

private struct BalanceRowPage: View {
    @State private var detail = 1
    @State private var lock = true
    @State private var hidden = false
    @State private var state: SpecimenState = .content

    private var rowDetail: BalanceRow.Detail? {
        switch detail {
        case 1: return .init("Posting: 30 Oct  ·  ", amount: 12_400)
        case 2: return .init("Next posting: 1 Nov")
        default: return nil
        }
    }

    var body: some View {
        ComponentPage(
            name: "BalanceRow",
            summary: "An account or deposit in a list: icon, name, balance, a caption line (with an amount) and a trailing mark.",
            since: "1.5.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            InCard {
                if state == .loading {
                    BalanceRowSkeleton(showsDetail: detail != 0)
                } else {
                    BalanceRow(
                        iconSource: .sfSymbol("banknote.fill"),
                        title: "Deposit",
                        amount: 2_000_000,
                        currency: "KZT",
                        detail: rowDetail,
                        trailingSystemImage: lock ? "lock.square.stack.fill" : nil
                    )
                    .amountsHidden(hidden)
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Caption", selection: $detail, options: [("None", 0), ("With amount", 1), ("Text", 2)])
            ToggleControl("Trailing mark", isOn: $lock)
            ToggleControl("Amounts hidden", isOn: $hidden)
        }
    }
}

private struct BreakdownRowPage: View {
    @State private var percentage = 42.0
    @State private var showsSubtitle = true
    @State private var showsChevron = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "BreakdownRow",
            summary: "A part of a whole: icon in its colour, name, amount and share; stacks at large text sizes.",
            since: "1.2.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            InCard {
                if state == .loading {
                    BreakdownRowSkeleton()
                } else {
                    BreakdownRow(iconSource: .sfSymbol("fork.knife"), color: AppColors.warning, title: "Food",
                                 subtitle: showsSubtitle ? "Groceries, Cafés" : nil,
                                 amount: 85_000, currency: "KZT", percentage: percentage,
                                 showsChevron: showsChevron)
                }
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Share", value: $percentage, in: 0...100, step: 1) { "\(Int($0))%" }
            ToggleControl("Subtitle", isOn: $showsSubtitle)
            ToggleControl("Chevron", isOn: $showsChevron)
        }
    }
}

private struct ProgressRingRowPage: View {
    @State private var spent = 185_000.0
    @State private var hasLimit = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ProgressRingRow",
            summary: "A budget in a list: the icon inside its progress ring, spent / limit and the share; red once over.",
            since: "1.5.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            InCard {
                if state == .loading {
                    ProgressRingRowSkeleton()
                } else {
                    ProgressRingRow(iconSource: .sfSymbol("fork.knife"), color: .orange, title: "Food",
                                    progress: hasLimit ? LimitProgress(spent: spent, limit: 250_000) : nil,
                                    currency: "KZT", placeholder: "No budget set")
                }
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Spent of 250 000", value: $spent, in: 0...400_000, step: 1_000)
            ToggleControl("Has a limit", isOn: $hasLimit)
        }
    }
}

private struct InsightEntityRowPage: View {
    @State private var showsCaption = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "InsightEntityRow",
            summary: "An item in an insight's list: icon, title and subtitle, an amount with a caption.",
            since: "1.2.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            InCard {
                if state == .loading {
                    InsightEntityRowSkeleton()
                } else {
                    InsightEntityRow(iconSource: .sfSymbol("tv.fill"), title: "Streaming",
                                     subtitle: "3 services", amount: 12_900, currency: "KZT",
                                     amountCaption: showsCaption ? "per month" : nil)
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Amount caption", isOn: $showsCaption)
        }
    }
}

private struct NetAmountRowPage: View {
    @State private var net = 210_000.0
    @State private var single = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "NetAmountRow",
            summary: "A period's net with what came in and went out; or a single value.",
            since: "1.1.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            InCard {
                if state == .loading {
                    NetAmountRowSkeleton(showsFlows: !single)
                } else if single {
                    NetAmountRow(label: "March 2026", inflow: 0, outflow: 0, net: 0, currency: "KZT",
                                 singleValue: 410_000, singleColor: AppColors.success)
                } else {
                    NetAmountRow(label: "May 2026", inflow: 530_000, outflow: 530_000 - net, net: net, currency: "KZT")
                }
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Net", value: $net, in: -200_000...400_000, step: 1_000)
            ToggleControl("Single value", isOn: $single)
        }
    }
}

private struct ScheduleRowPage: View {
    @State private var isDone = false
    @State private var showsDetail = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ScheduleRow",
            summary: "A schedule entry (a loan payment): number, date, amount, a detail; done ones are muted.",
            since: "1.1.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            InCard {
                if state == .loading {
                    ScheduleRowSkeleton()
                } else {
                    ScheduleRow(title: "#4", subtitle: "12 Apr 2026", amount: 45_000, currency: "KZT",
                                detail: showsDetail ? "int: 2 950 ₸" : nil, isDone: isDone)
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Done", isOn: $isDone)
            ToggleControl("Detail", isOn: $showsDetail)
        }
    }
}

private struct PersonRowPage: View {
    @State private var showsSubtitle = true
    @State private var trailing = 1
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "PersonRow",
            summary: "A person in a list: avatar, name, a line under it, a trailing slot. The app passes its photo avatar.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            InCard {
                if state == .loading {
                    PersonRowSkeleton(showsSubtitle: showsSubtitle)
                } else {
                    PersonRow(name: "Aida Nurlanovna", subtitle: showsSubtitle ? "@aida" : nil) {
                        switch trailing {
                        case 1: DisclosureChevron()
                        case 2: Button("Accept") {}.appButton(size: .small)
                        default: EmptyView()
                        }
                    }
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Subtitle", isOn: $showsSubtitle)
            ChoiceControl("Trailing", selection: $trailing, options: [("None", 0), ("Chevron", 1), ("Button", 2)])
        }
    }
}

private struct CommentRowPage: View {
    @State private var showsQuote = true
    @State private var showsActions = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "CommentRow",
            summary: "A comment or a reply: small avatar, author, time, a menu, the quoted message, the text, actions.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            InCard {
                if state == .loading {
                    CommentRowSkeleton()
                } else if showsActions {
                    CommentRow(
                        author: "Timur",
                        date: Date().addingTimeInterval(-120),
                        text: AttributedString("Thin near the north shore, fine in the bay."),
                        quote: showsQuote ? MessageQuote(title: "Aida", text: "Was anyone on the lake this weekend?") : nil
                    ) {
                        Image(systemName: "ellipsis").foregroundStyle(AppColors.textTertiary)
                    } actions: {
                        ReactionButton(systemImage: "hand.thumbsup", selectedSystemImage: "hand.thumbsup.fill",
                                       count: 12, isSelected: true, accessibilityLabel: "12") {}
                        Button("Reply") {}.buttonStyle(.borderless)
                    }
                } else {
                    CommentRow(
                        author: "Timur",
                        date: Date().addingTimeInterval(-120),
                        text: AttributedString("Thin near the north shore, fine in the bay."),
                        quote: showsQuote ? MessageQuote(title: "Aida", text: "Was anyone on the lake this weekend?") : nil
                    )
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Quote", isOn: $showsQuote)
            ToggleControl("Actions and menu", isOn: $showsActions)
        }
    }
}

private struct ChecklistRowPage: View {
    @State private var isChecked = false
    @State private var showsMark = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ChecklistRow",
            summary: "An item to tick off; struck through once done, an optional mark on the right.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            InCard {
                if state == .loading {
                    ChecklistRowSkeleton()
                } else {
                    ChecklistRow("Tent", isChecked: isChecked,
                                 accessorySystemImage: showsMark ? "backpack" : nil,
                                 accessoryLabel: showsMark ? "From gear" : nil) { isChecked.toggle() }
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Checked", isOn: $isChecked)
            ToggleControl("Mark", isOn: $showsMark)
        }
    }
}

private struct ChecklistSummaryRowPage: View {
    @State private var checked = 12
    @State private var total = 20
    @State private var showsDate = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ChecklistSummaryRow",
            summary: "A checklist in a list: its title (a seal once complete), the day, the bar and “12 of 20”.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            InCard {
                if state == .loading {
                    ChecklistSummaryRowSkeleton()
                } else {
                    ChecklistSummaryRow(title: "Weekend at the lake", subtitle: showsDate ? "Sat, 12 Oct" : nil,
                                        checked: min(checked, total), total: total)
                }
            }
        } controls: {
            StateControl(state: $state)
            StepperControl("Checked", value: $checked, in: 0...30)
            StepperControl("Total", value: $total, in: 0...30)
            ToggleControl("Date", isOn: $showsDate)
        }
    }
}

private struct ThumbnailRowPage: View {
    @State private var isVerified = true
    @State private var isSaved = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ThumbnailRow",
            summary: "Something with a picture in a list: a 64 pt picture, the title with a seal and a bookmark, details.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            InCard {
                if state == .loading {
                    ThumbnailRowSkeleton()
                } else {
                    ThumbnailRow(title: "Big Almaty Lake", isVerified: isVerified, isSaved: isSaved) {
                        ThumbnailPlaceholder(systemImage: "drop.fill")
                    } details: {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text("Lake · 28 km · ★ 4.6")
                            Text("Last report 2 days ago")
                        }
                    }
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Verified", isOn: $isVerified)
            ToggleControl("Saved", isOn: $isSaved)
        }
    }
}

#Preview { NavigationStack { DataRowsScreen() } }
