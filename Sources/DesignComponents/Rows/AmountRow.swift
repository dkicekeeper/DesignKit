//
//  AmountRow.swift
//  DesignKit
//
//  A row about money: an icon, a name, and an amount, a share or a limit (2.1.0). It merges four
//  rows that were built the same way: BalanceRow (an account), ProgressRingRow (a category with
//  its budget ring), BreakdownRow (a part of a breakdown) and InsightEntityRow (an item of an
//  insight). Their layouts move here as they were; the old names are deprecated wrappers.
//
//  2.1.0 also fixes ProgressRingRow's staircase: a limit row keeps the ring's room around its
//  icon with or without a limit, so a list of categories with and without a budget lines up.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A row with an icon, a name and money.
///
/// Two styles:
/// - `.list`: a `List` row with no padding of its own (the list's insets place it). The name in
///   `h4`, the value under it. An account, a category with its limit.
/// - `.info`: padded vertically like `UniversalRow(.info)`, the name in `body`, the value on the
///   trailing edge (under the name at accessibility text sizes). A breakdown's part, an
///   insight's item.
///
/// ```swift
/// // An account (BalanceRow before 2.1)
/// AmountRow("Kaspi Gold", leading: .icon(.sfSymbol("creditcard.fill")),
///           value: .amount(1_250_000, color: AppColors.Text.secondary), currency: "KZT", style: .list)
///
/// // A category with its budget (ProgressRingRow): the ring goes around the icon
/// AmountRow("Food", leading: .tinted(.sfSymbol("fork.knife"), .orange),
///           value: .limit(LimitProgress(spent: 185_000, limit: 250_000)), currency: "KZT", style: .list)
/// AmountRow("Transport", leading: .tinted(.sfSymbol("car.fill"), .blue),
///           value: .limit(nil, placeholder: "No budget set"), currency: "KZT", style: .list)
///
/// // A part of a breakdown (BreakdownRow)
/// AmountRow("Food", subtitle: "Groceries, Cafés", subtitleLineLimit: 1,
///           leading: .tinted(.sfSymbol("fork.knife"), AppColors.warning),
///           value: .share(85_000, percentage: 42), currency: "KZT", accessory: .chevron)
///
/// // An insight's item (InsightEntityRow)
/// AmountRow("Netflix", subtitle: "Monthly", leading: .icon(.brandService("netflix")),
///           value: .amount(4_990, caption: "per month"), currency: "KZT")
/// ```
///
/// A limit row (`.limit`, list style) keeps the ring's room (`AppIconSize.Tile.lg`) around its
/// icon whether a limit is set or not, so rows with and without one line up.
///
/// Make it tappable with a `Button` (`.buttonStyle(.plain)`, `.contentShape(Rectangle())`) or a
/// `NavigationLink` (`accessory: .chevron`), and add `.swipeActions` at the call site.
public struct AmountRow: View {
    /// Where the value goes and how big the name is.
    public enum Style: Hashable, Sendable {
        /// The name in `h4`, the value under it; no padding (a `List` row).
        case list
        /// The name in `body`, the value on the trailing edge; `UniversalRow(.info)` padding.
        case info
    }

    /// What stands before the name.
    public enum Leading {
        /// The source in `Icon`'s own style for it (a category symbol, a brand logo), 44 pt;
        /// `nil` draws `Icon`'s placeholder.
        case icon(IconSource?)
        /// The symbol in a colour on a pale disc of it, 44 pt.
        case tinted(IconSource?, Color)
        /// Nothing: the name starts at the leading edge.
        case none
    }

    /// The money the row shows.
    public enum Value {
        /// An amount in `color`, with an optional line under it ("per month").
        case amount(Double, color: Color = AppColors.Text.primary, caption: String? = nil)
        /// An amount over its share in per cent, 0…100 ("85 000 ₸ / 42.0%").
        case share(Double, percentage: Double)
        /// List style: "spent / limit (74%)" and a ring around the icon, in the destructive
        /// colour over the limit; with no limit, `placeholder` (or nothing). The icon keeps the
        /// ring's room either way. Info style: the spent amount over "74%", no ring.
        case limit(LimitProgress?, placeholder: String? = nil)
    }

    /// The mark on the trailing edge.
    public enum Accessory: Hashable, Sendable {
        case none
        /// `DisclosureChevron`, for a row in a `NavigationLink`.
        case chevron
        /// A secondary SF Symbol (a lock on a locked balance).
        case systemImage(String)
    }

    /// A caption line under the value: text, then an optional amount in `amountColor`.
    public struct Detail {
        public let text: String
        public let amount: Double?
        public let amountColor: Color

        /// - Parameters:
        ///   - text: Caption text, in secondary. Include the separator before the amount
        ///     ("Posting: 30 Oct  ·  "); at accessibility text sizes, where the amount goes on
        ///     the next line, trailing spaces and "·" are dropped.
        ///   - amount: Follows the text on the same line, in the row's currency.
        ///   - amountColor: `AppColors.planned` by default.
        public init(_ text: String, amount: Double? = nil, amountColor: Color = AppColors.planned) {
            self.text = text
            self.amount = amount
            self.amountColor = amountColor
        }
    }

    let title: String
    let subtitle: AnyView?
    let subtitleLineLimit: Int?
    let leading: Leading
    let value: Value
    let currency: String
    let style: Style
    let detail: Detail?
    let accessory: Accessory
    let transitionSourceID: String?
    let transitionNamespace: Namespace.ID?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - subtitle: A line under the name, `bodySmall` secondary.
    ///   - subtitleLineLimit: The subtitle's lines (`1` for a list of parts); `nil`, no limit.
    ///   - detail: A caption line under the value.
    ///   - transitionSourceID: With `transitionNamespace`, makes the icon (with its ring) the
    ///     source of a `.navigationTransition(.zoom(sourceID:in:))` (list style).
    public init(
        _ title: String,
        subtitle: String? = nil,
        subtitleLineLimit: Int? = nil,
        leading: Leading,
        value: Value,
        currency: String,
        style: Style = .info,
        detail: Detail? = nil,
        accessory: Accessory = .none,
        transitionSourceID: String? = nil,
        transitionNamespace: Namespace.ID? = nil
    ) {
        self.title = title
        self.subtitle = subtitle.map {
            AnyView(Text($0)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary))
        }
        self.subtitleLineLimit = subtitleLineLimit
        self.leading = leading
        self.value = value
        self.currency = currency
        self.style = style
        self.detail = detail
        self.accessory = accessory
        self.transitionSourceID = transitionSourceID
        self.transitionNamespace = transitionNamespace
    }

    /// A row whose subtitle is a view of its own (a relative date, a badge).
    public init<Subtitle: View>(
        _ title: String,
        leading: Leading,
        value: Value,
        currency: String,
        style: Style = .info,
        detail: Detail? = nil,
        accessory: Accessory = .none,
        transitionSourceID: String? = nil,
        transitionNamespace: Namespace.ID? = nil,
        @ViewBuilder subtitle: () -> Subtitle
    ) {
        self.title = title
        self.subtitle = AnyView(subtitle())
        self.subtitleLineLimit = nil
        self.leading = leading
        self.value = value
        self.currency = currency
        self.style = style
        self.detail = detail
        self.accessory = accessory
        self.transitionSourceID = transitionSourceID
        self.transitionNamespace = transitionNamespace
    }

    public var body: some View {
        switch style {
        case .list:
            listRow
        case .info:
            if dynamicTypeSize.isAccessibilitySize {
                stackedInfoRow
            } else {
                infoRow
            }
        }
    }

    // MARK: - List style (BalanceRow, ProgressRingRow before 2.1)

    private var listRow: some View {
        HStack(spacing: AppSpacing.md) {
            listLeading
                .matchedTransitionSourceIfPresent(
                    id: transitionSourceID,
                    namespace: transitionNamespace
                )

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.h4)

                subtitleView

                listValue

                if let detail {
                    detailLine(detail)
                }
            }

            if accessory == .none {
                Spacer(minLength: 0)
            } else {
                Spacer()
                accessoryView
            }
        }
    }

    @ViewBuilder
    private var listLeading: some View {
        if case .limit(let progress, _) = value {
            // A limit row keeps the ring's room with or without a limit: rows with and
            // without one line up (2.1.0; the icon moved by the ring's width before).
            ZStack {
                if let progress {
                    ProgressRing(
                        progress: progress.percentage / 100,
                        size: AppIconSize.Tile.lg,
                        lineWidth: AmountRowMetrics.ringWidth,
                        isOverBudget: progress.isOverLimit,
                        animatesOnAppear: false // list row — onAppear re-fires on scroll
                    )
                }
                leadingIcon
            }
            .frame(width: AppIconSize.Tile.lg, height: AppIconSize.Tile.lg)
        } else {
            leadingIcon
        }
    }

    @ViewBuilder
    private var leadingIcon: some View {
        switch leading {
        case .icon(let source):
            Icon(source: source, size: AppIconSize.Tile.sm)
        case .tinted(let source, let color):
            Icon(source: source, style: Self.tintedStyle(color))
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var listValue: some View {
        switch value {
        case .amount(let amount, let color, let caption):
            FormattedAmountText(
                amount: amount,
                currency: currency,
                fontSize: AppTypography.bodySmall,
                color: color
            )
            if let caption {
                Text(caption)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        case .share(let amount, let percentage):
            HStack(spacing: AppSpacing.xs) {
                FormattedAmountText(
                    amount: amount,
                    currency: currency,
                    fontSize: AppTypography.bodySmall,
                    color: AppColors.Text.secondary
                )
                Text(Self.percentText(percentage))
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        case .limit(let progress, let placeholder):
            if let progress {
                limitLine(progress)
            } else if let placeholder {
                Text(placeholder)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
    }

    @ViewBuilder
    private func limitLine(_ progress: LimitProgress) -> some View {
        let amountColor = progress.isOverLimit ? AppColors.destructive : AppColors.Text.secondary
        if dynamicTypeSize.isAccessibilitySize {
            // Accessibility text sizes: on one line both amounts were cut to "185… / 250…".
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                FormattedAmountText(
                    amount: progress.spent,
                    currency: currency,
                    fontSize: AppTypography.bodySmall,
                    fontWeight: .semibold,
                    color: amountColor
                )
                HStack(spacing: 0) {
                    Text(verbatim: "/ ")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(amountColor)
                    FormattedAmountText(
                        amount: progress.limit,
                        currency: currency,
                        fontSize: AppTypography.bodySmall,
                        fontWeight: .semibold,
                        color: amountColor
                    )
                }
                limitPercentage(progress)
            }
        } else {
            HStack(spacing: AppSpacing.xs) {
                SpentBudgetText(
                    spent: progress.spent,
                    budget: progress.limit,
                    currency: currency,
                    fontWeight: .semibold,
                    amountColor: amountColor,
                    separatorColor: amountColor
                )
                limitPercentage(progress)
            }
        }
    }

    private func limitPercentage(_ progress: LimitProgress) -> some View {
        Text(verbatim: "(\(Int(progress.percentage))%)")
            .font(AppTypography.bodySmall)
            .foregroundStyle(AppColors.Text.secondary)
    }

    @ViewBuilder
    private func detailLine(_ detail: Detail) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            // Accessibility text sizes: text and amount side by side broke the text mid-phrase
            // and abbreviated the amount ("12K"), so the amount goes on its own line.
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(detail.text.trimmingCharacters(in: Self.trailingSeparator))
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)

                if let detailAmount = detail.amount {
                    FormattedAmountText(
                        amount: detailAmount,
                        currency: currency,
                        fontSize: AppTypography.caption,
                        color: detail.amountColor
                    )
                }
            }
        } else {
            HStack(spacing: 0) {
                Text(detail.text)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)

                if let detailAmount = detail.amount {
                    FormattedAmountText(
                        amount: detailAmount,
                        currency: currency,
                        fontSize: AppTypography.caption,
                        color: detail.amountColor
                    )
                }
            }
        }
    }

    /// Spaces and the "·" that separate a detail's text from its amount on one line.
    private static let trailingSeparator = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "·"))

    // MARK: - Info style (BreakdownRow, InsightEntityRow before 2.1)

    private var infoRow: some View {
        UniversalRow(config: .info, leadingIcon: infoLeading) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                infoTitle
                subtitleView
                if let detail {
                    detailLine(detail)
                }
            }
        } trailing: {
            HStack(spacing: AppSpacing.md) {
                infoValue(alignment: .trailing)
                accessoryView
            }
        }
    }

    /// Accessibility text sizes: the value moves under the name, which then has the row's
    /// full width and does not break mid-word.
    private var stackedInfoRow: some View {
        UniversalRow(config: .info, leadingIcon: infoLeading) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                infoTitle
                subtitleView
                if let detail {
                    detailLine(detail)
                }
                infoValue(alignment: .leading)
            }
        } trailing: {
            accessoryView
        }
    }

    private var infoTitle: some View {
        Text(title)
            .font(AppTypography.body)
            .foregroundStyle(AppColors.Text.primary)
    }

    private var infoLeading: IconConfig? {
        switch leading {
        case .icon(let source):
            if let source {
                return .auto(source: source, size: AppIconSize.Tile.sm)
            }
            return .custom(source: nil, style: .placeholder(size: AppIconSize.Tile.sm))
        case .tinted(let source, let color):
            return .custom(source: source, style: Self.tintedStyle(color))
        case .none:
            return nil
        }
    }

    /// The amount (`body` semibold) over its caption (`bodySmall` secondary).
    @ViewBuilder
    private func infoValue(alignment: HorizontalAlignment) -> some View {
        switch value {
        case .amount(let amount, let color, let caption):
            infoAmount(amount, color: color, caption: caption, alignment: alignment)
        case .share(let amount, let percentage):
            infoAmount(amount, color: AppColors.Text.primary, caption: Self.percentText(percentage),
                       alignment: alignment)
        case .limit(let progress, let placeholder):
            if let progress {
                infoAmount(progress.spent,
                           color: progress.isOverLimit ? AppColors.destructive : AppColors.Text.primary,
                           caption: "\(Int(progress.percentage))%",
                           alignment: alignment)
            } else if let placeholder {
                Text(placeholder)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
    }

    private func infoAmount(_ amount: Double, color: Color, caption: String?, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: AppSpacing.xs) {
            FormattedAmountText(
                amount: amount,
                currency: currency,
                fontSize: AppTypography.body,
                fontWeight: .semibold,
                color: color
            )
            if let caption {
                Text(caption)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
    }

    // MARK: - Shared

    @ViewBuilder
    private var subtitleView: some View {
        if let subtitle {
            subtitle
                .lineLimit(subtitleLineLimit)
        }
    }

    @ViewBuilder
    private var accessoryView: some View {
        switch accessory {
        case .none:
            EmptyView()
        case .chevron:
            DisclosureChevron()
        case .systemImage(let name):
            Image(systemName: name)
                .foregroundStyle(.secondary)
                .font(.system(size: AppIconSize.sm))
        }
    }

    static func tintedStyle(_ color: Color) -> IconStyle {
        .circle(
            size: AppIconSize.Tile.sm,
            tint: .monochrome(color),
            backgroundColor: AppColors.pale(color)
        )
    }

    /// "42.0%".
    static func percentText(_ percentage: Double) -> String {
        String(format: "%.1f%%", percentage)
    }
}

enum AmountRowMetrics {
    /// The limit ring's stroke.
    static let ringWidth: CGFloat = 3
}

// MARK: - Skeleton

/// Placeholder of an `AmountRow` in its style: the icon (with the ring's track for a limit row),
/// the name and the value lines.
public struct AmountRowSkeleton: View {
    let style: AmountRow.Style
    let showsRing: Bool
    let showsDetail: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - showsRing: The ring's track around the icon: a limit row (list style).
    ///   - showsDetail: The detail's caption line (list style).
    public init(style: AmountRow.Style = .info, showsRing: Bool = false, showsDetail: Bool = false) {
        self.style = style
        self.showsRing = showsRing
        self.showsDetail = showsDetail
    }

    public var body: some View {
        switch style {
        case .list:
            if showsRing {
                ringList
            } else {
                plainList
            }
        case .info:
            info
        }
    }

    private var plainList: some View {
        HStack(spacing: AppSpacing.md) {
            IconSkeleton(size: AppIconSize.Tile.sm)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.h4, width: 130)
                SkeletonText(AppTypography.bodySmall, width: 90)
                if showsDetail {
                    SkeletonText(AppTypography.caption, width: 150)
                }
            }
            Spacer()
        }
        .shimmer()
        .skeletonLoadingLabel()
    }

    private var ringList: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .stroke(Skeleton.fill, lineWidth: AmountRowMetrics.ringWidth)
                    .frame(width: AppIconSize.Tile.lg, height: AppIconSize.Tile.lg)
                IconSkeleton(size: AppIconSize.Tile.sm)
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.h4, width: 120)
                SkeletonText(AppTypography.bodySmall, width: 150)
                if showsDetail {
                    SkeletonText(AppTypography.caption, width: 150)
                }
            }
            Spacer(minLength: 0)
        }
        .shimmer()
        .skeletonLoadingLabel()
    }

    private var info: some View {
        HStack(spacing: RowConfiguration.info.spacing) {
            IconSkeleton(size: AppIconSize.Tile.sm)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.body, width: 110)
                SkeletonText(AppTypography.bodySmall, width: 70)
                if dynamicTypeSize.isAccessibilitySize {
                    SkeletonText(AppTypography.body, width: 90)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if !dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    SkeletonText(AppTypography.body, width: 90)
                    SkeletonText(AppTypography.bodySmall, width: 40)
                }
            }
        }
        .shimmer()
        .padding(.vertical, RowConfiguration.info.verticalPadding)
        .skeletonLoadingLabel()
    }
}
