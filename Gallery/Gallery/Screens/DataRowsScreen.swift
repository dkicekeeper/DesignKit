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
    static let title = "Rows: Data"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        AmountRowPage()
        AmountRowLimitListPage()
        NetAmountRowPage()
        ScheduleRowPage()
        PersonRowPage()
        CommentRowPage()
        ChecklistRowPage()
        ChecklistSummaryRowPage()
        ThumbnailRowPage()
        DownloadRowPage()
        TransactionRowPage()
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

private struct AmountRowPage: View {
    @State private var style: AmountRow.Style = .info
    @State private var leading = 1
    @State private var value = 0
    @State private var spent = 185_000.0
    @State private var showsSubtitle = true
    @State private var detail = 0
    @State private var accessory = 0
    @State private var hidden = false
    @State private var state: SpecimenState = .content

    private var rowLeading: AmountRow.Leading {
        switch leading {
        case 0: .icon(.sfSymbol("banknote.fill"))
        case 1: .tinted(.sfSymbol("fork.knife"), AppColors.warning)
        default: .none
        }
    }

    private var rowValue: AmountRow.Value {
        switch value {
        case 0: .amount(85_000, color: style == .list ? AppColors.Text.secondary : AppColors.Text.primary,
                        caption: style == .info ? "per month" : nil)
        case 1: .share(85_000, percentage: 42)
        case 2: .limit(LimitProgress(spent: spent, limit: 250_000))
        default: .limit(nil, placeholder: "No budget set")
        }
    }

    private var rowDetail: AmountRow.Detail? {
        switch detail {
        case 1: .init("Posting: 30 Oct  ·  ", amount: 12_400)
        case 2: .init("Next posting: 1 Nov")
        default: nil
        }
    }

    private var rowAccessory: AmountRow.Accessory {
        switch accessory {
        case 1: .chevron
        case 2: .systemImage("lock.square.stack.fill")
        default: .none
        }
    }

    var body: some View {
        ComponentPage(
            name: "AmountRow",
            summary: "A row about money: an icon, a name, and an amount, a share or a limit. List style (the value under the name) or info style (the value on the trailing edge).",
            since: "2.1.0",
            apps: [.tenra],
            canvas: .fill,
            notes: [
                "2.1.0 merged BalanceRow (list, .amount), ProgressRingRow (list, .limit), BreakdownRow (info, .share) and InsightEntityRow (info, .amount); the old names were removed in 3.0.0.",
                "A limit row keeps the ring's room around its icon with or without a limit, so a list of both lines up.",
                "The info style stacks the value under the name at accessibility text sizes.",
            ],
            styles: ["info", "list"]
        ) {
            InCard {
                if state == .loading {
                    AmountRowSkeleton(style: style, showsRing: value >= 2 && style == .list,
                                      showsDetail: detail != 0)
                } else {
                    AmountRow(
                        value >= 2 ? "Food" : "Deposit",
                        subtitle: showsSubtitle ? "Groceries, Cafés" : nil,
                        subtitleLineLimit: 1,
                        leading: rowLeading,
                        value: rowValue,
                        currency: "KZT",
                        style: style,
                        detail: rowDetail,
                        accessory: rowAccessory
                    )
                    .amountsHidden(hidden)
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Style", selection: $style, options: [("Info", .info), ("List", .list)])
            ChoiceControl("Icon", selection: $leading, options: [("Icon", 0), ("Tinted", 1), ("None", 2)])
            ChoiceControl("Value", selection: $value, options: [("Amount", 0), ("Share", 1), ("Limit", 2), ("No limit", 3)])
            if value == 2 {
                SliderControl("Spent of 250 000", value: $spent, in: 0...400_000, step: 1_000)
            }
            ToggleControl("Subtitle", isOn: $showsSubtitle)
            ChoiceControl("Detail", selection: $detail, options: [("None", 0), ("With amount", 1), ("Text", 2)])
            ChoiceControl("Accessory", selection: $accessory, options: [("None", 0), ("Chevron", 1), ("Mark", 2)])
            ToggleControl("Amounts hidden", isOn: $hidden)
        }
    }
}

/// Categories with and without a budget in one list: the names line up (2.1.0; before, a
/// row without a ring had its icon and name 8 pt to the left).
private struct AmountRowLimitListPage: View {
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "AmountRow: a list of limits",
            summary: "Categories with and without a budget: every limit row keeps the ring's room, so icons and names line up.",
            since: "2.1.0",
            apps: [.tenra],
            canvas: .fill
        ) {
            InCard {
                if state == .loading {
                    ForEach(0..<3, id: \.self) { _ in
                        AmountRowSkeleton(style: .list, showsRing: true)
                    }
                } else {
                    AmountRow("Food", leading: .tinted(.sfSymbol("fork.knife"), .orange),
                              value: .limit(LimitProgress(spent: 185_000, limit: 250_000)),
                              currency: "KZT", style: .list)
                    AmountRow("Transport", leading: .tinted(.sfSymbol("car.fill"), .blue),
                              value: .limit(nil, placeholder: "No budget set"),
                              currency: "KZT", style: .list)
                    AmountRow("Shopping", leading: .tinted(.sfSymbol("bag.fill"), AppColors.accent),
                              value: .limit(LimitProgress(spent: 320_000, limit: 300_000)),
                              currency: "KZT", style: .list)
                }
            }
        } controls: {
            StateControl(state: $state)
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
    @State private var showsDetail = false
    @State private var style: PersonRowStyle = .list
    @State private var trailing = 1
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "PersonRow",
            summary: "A person in a list: avatar, name, a line under it, a trailing slot. The app passes its photo avatar. The card style is the person at the top of their profile.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill,
            notes: ["style: .card (2.8.0): a 64 pt avatar, the name in h4, the @username and a third line (detail), in a card that pads itself."],
            styles: ["list", "card"]
        ) {
            if style == .card {
                specimen
            } else {
                InCard { specimen }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Style", selection: $style, options: [("List", .list), ("Card", .card)])
            ToggleControl("Subtitle", isOn: $showsSubtitle)
            ToggleControl("Detail", isOn: $showsDetail)
            ChoiceControl("Trailing", selection: $trailing, options: [("None", 0), ("Chevron", 1), ("Button", 2)])
        }
    }

    @ViewBuilder
    private var specimen: some View {
        if state == .loading {
            PersonRowSkeleton(showsSubtitle: showsSubtitle, style: style)
        } else {
            PersonRow(name: "Aida Nurlanovna", subtitle: showsSubtitle ? "@aida" : nil,
                      detail: showsDetail ? "Almaty" : nil, style: style) {
                switch trailing {
                case 1: DisclosureChevron()
                case 2: DSButton("Accept", size: .small) {}
                default: EmptyView()
                }
            }
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

private struct DownloadRowPage: View {
    @State private var status = 1
    @State private var progress = 0.4
    @State private var state: SpecimenState = .content

    private var rowStatus: DownloadRow.Status {
        switch status {
        case 0: .available
        case 1: .downloading(progress)
        case 2: .paused
        case 3: .downloaded
        default: .failed
        }
    }

    private var caption: String {
        switch status {
        case 0: "About 80 MB"
        case 1: "\(Int(progress * 100))% · \(Int(progress * 80)) MB"
        case 2: "Paused at \(Int(progress * 100))%"
        case 3: "Downloaded · 80 MB"
        default: "No connection. Try again."
        }
    }

    var body: some View {
        ComponentPage(
            name: "DownloadRow",
            summary: "Something to download for offline use: its name, its size or progress, and the action that fits (download, pause, resume); a check mark once it is here.",
            since: "2.8.0",
            apps: [.dalada],
            canvas: .fill,
            notes: ["The app formats the caption (sizes, percent) and adds .swipeActions to delete."]
        ) {
            InCard {
                if state == .loading {
                    DownloadRowSkeleton()
                } else {
                    DownloadRow("Almaty region", status: rowStatus, caption: caption,
                                onDownload: { status = 1 }, onPause: { status = 2 })
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Status", selection: $status, options: [
                ("Available", 0), ("Downloading", 1), ("Paused", 2), ("Downloaded", 3), ("Failed", 4),
            ])
            SliderControl("Progress", value: $progress, in: 0...1, step: 0.05)
        }
    }
}

private struct TransactionRowPage: View {
    @State private var kind = 0
    @State private var showsEquivalent = false
    @State private var isPending = false
    @State private var showsBadge = false
    @State private var state: SpecimenState = .content

    private let kaspi = TransactionRow.Account(name: "Kaspi Gold", icon: .sfSymbol("creditcard.fill"))
    private let deposit = TransactionRow.Account(name: "Halyk Deposit", icon: .sfSymbol("lock.fill"))

    var body: some View {
        ComponentPage(
            name: "TransactionRow",
            summary: "A money movement: its icon, the category and its details, the account and a note, the amount and its equivalent; a transfer from one account to another with both legs.",
            since: "2.9.0",
            apps: [.tenra],
            canvas: .fill,
            notes: [
                "The app passes what to show (the category's colours, the account's logo, the amount lines); its model and maths stay in the app.",
                "A deleted account keeps its name in italic, without a logo (TransactionRow.Account.deleted).",
            ]
        ) {
            InCard {
                if state == .loading {
                    TransactionRowSkeleton()
                } else {
                    row
                }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Kind", selection: $kind, options: [("Expense", 0), ("Income", 1), ("Transfer", 2), ("Deleted account", 3)])
            ToggleControl("Equivalent", isOn: $showsEquivalent)
            ToggleControl("Future", isOn: $isPending)
            ToggleControl("Recurring badge", isOn: $showsBadge)
        }
    }

    @ViewBuilder
    private var row: some View {
        switch kind {
        case 1:
            TransactionRow(
                .entry(title: "Salary", account: kaspi),
                icon: .sfSymbol("banknote.fill"), iconTint: .monochrome(AppColors.income),
                iconBackground: AppColors.pale(AppColors.income),
                badgeSystemImage: showsBadge ? "arrow.clockwise" : nil,
                amounts: [.init(450_000, currency: "KZT", prefix: "+", color: AppColors.income)],
                isPending: isPending,
                accessibilityLabel: "Salary, 450 000 tenge, Kaspi Gold"
            )
        case 2:
            TransactionRow(
                .transfer(from: kaspi, to: deposit),
                icon: .sfSymbol("arrow.left.arrow.right"), iconTint: .monochrome(AppColors.transfer),
                iconBackground: AppColors.pale(AppColors.transfer),
                amounts: [
                    .init(100_000, currency: "KZT", prefix: "-", color: AppColors.Text.primary),
                    .init(100_000, currency: "KZT", prefix: "+", color: AppColors.income),
                ],
                isPending: isPending,
                accessibilityLabel: "Transfer, 100 000 tenge, from Kaspi Gold to Halyk Deposit"
            )
        default:
            TransactionRow(
                .entry(title: "Groceries", details: "Vegetables, Bread",
                       account: kind == 3 ? .deleted("Old card") : kaspi),
                note: "Magnum",
                icon: .sfSymbol("cart.fill"), iconTint: .monochrome(.orange), iconBackground: AppColors.pale(.orange),
                badgeSystemImage: showsBadge ? "arrow.clockwise" : nil,
                amounts: expenseAmounts,
                isPending: isPending,
                accessibilityLabel: "Groceries, 18 500 tenge, Kaspi Gold"
            )
        }
    }

    /// The amount, and its equivalent in the account's currency under it.
    private var expenseAmounts: [TransactionRow.Amount] {
        var lines = [TransactionRow.Amount(18_500, currency: "KZT", prefix: "-", color: AppColors.Text.primary)]
        if showsEquivalent {
            lines.append(TransactionRow.Amount(36.5, currency: "USD", color: AppColors.Text.primary))
        }
        return lines
    }
}

#Preview { NavigationStack { DataRowsScreen() } }
