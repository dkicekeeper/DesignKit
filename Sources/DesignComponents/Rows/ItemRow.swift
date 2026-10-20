//
//  ItemRow.swift
//  DesignKit
//
//  A list row for an item of the app's own (3.6.0, audit round 5): a symbol, the title, a
//  description, lines of short facts joined by "·", and an accessory on the trailing edge.
//  Dalada's trips, places, articles and gear and Tenra's backups and subcategories built this
//  row by hand, each a little differently; what each line says stays in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

// MARK: - Meta line

/// One fact in a `MetaLine`: text, text with a symbol, or a symbol alone.
public struct MetaItem {
    enum Kind {
        case text(Text)
        case label(Text, systemImage: String)
        case symbol(String, accessibilityLabel: Text)
    }

    let kind: Kind
    /// The item's colour; the line's by default.
    let tint: Color?

    /// A symbol alone follows the facts without a dot ("4 min 🔖").
    var isSymbol: Bool {
        if case .symbol = kind { return true }
        return false
    }

    public static func text(_ string: String, tint: Color? = nil) -> MetaItem {
        MetaItem(kind: .text(Text(verbatim: string)), tint: tint)
    }

    /// Formatted or localized text: `Text(date, format: …)`, `Text("trips.minutes \(n)")`.
    public static func text(_ text: Text, tint: Color? = nil) -> MetaItem {
        MetaItem(kind: .text(text), tint: tint)
    }

    public static func label(_ string: String, systemImage: String, tint: Color? = nil) -> MetaItem {
        MetaItem(kind: .label(Text(verbatim: string), systemImage: systemImage), tint: tint)
    }

    public static func label(_ text: Text, systemImage: String, tint: Color? = nil) -> MetaItem {
        MetaItem(kind: .label(text, systemImage: systemImage), tint: tint)
    }

    /// A symbol alone ("saved", "pinned"); VoiceOver reads `accessibilityLabel`.
    public static func symbol(_ systemImage: String, accessibilityLabel: String, tint: Color? = nil) -> MetaItem {
        MetaItem(kind: .symbol(systemImage, accessibilityLabel: Text(verbatim: accessibilityLabel)), tint: tint)
    }
}

/// Short facts on one line: "12 Oct · 14.2 km · 3 h", or labels with symbols side by side.
/// It takes the font around it (`ItemRow` sets it; elsewhere, `.font(AppTypography.caption)`)
/// and draws in `tint`, an item's own tint over it. A long fact wraps; `.lineLimit(1)` on the
/// line keeps each to one line. At accessibility text sizes the facts go one under another,
/// without dots (a symbol alone stays after its fact).
public struct MetaLine: View {
    public enum Separator {
        /// "·" between the items: facts of one kind (a date, a distance, a duration). A symbol
        /// alone follows without one.
        case dot
        /// Space between the items: labels with symbols ("Friends", "Pending").
        case space
    }

    let items: [MetaItem]
    let separator: Separator
    let tint: Color

    @Environment(\.itemRowStyle) private var style
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - tint: The line's colour; the secondary grey by default, the tertiary for a fainter
    ///     line (a note under the facts).
    public init(_ items: [MetaItem], separator: Separator = .dot, tint: Color = AppColors.Text.secondary) {
        self.items = items
        self.separator = separator
        self.tint = tint
    }

    private var spacing: CGFloat {
        switch separator {
        case .dot: style == .large ? AppSpacing.sm : AppSpacing.xs
        case .space: AppSpacing.sm
        }
    }

    /// Each fact with the symbols alone that follow it.
    private var groups: [[MetaItem]] {
        var groups: [[MetaItem]] = []
        for item in items {
            if item.isSymbol, !groups.isEmpty {
                groups[groups.count - 1].append(item)
            } else {
                groups.append([item])
            }
        }
        return groups
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                        groupView(group)
                    }
                }
            } else {
                HStack(spacing: spacing) {
                    ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                        if separator == .dot && index > 0 {
                            Text(verbatim: "·")
                                .accessibilityHidden(true)
                        }
                        groupView(group)
                    }
                }
            }
        }
        .foregroundStyle(tint)
    }

    private func groupView(_ group: [MetaItem]) -> some View {
        HStack(spacing: spacing) {
            ForEach(Array(group.enumerated()), id: \.offset) { _, item in
                itemView(item)
            }
        }
    }

    @ViewBuilder
    private func itemView(_ item: MetaItem) -> some View {
        switch item.kind {
        case .text(let text):
            text.foregroundStyle(item.tint ?? tint)
        case .label(let text, let systemImage):
            Label { text } icon: { Icon(systemImage, size: AppIconSize.xs) }
                .labelStyle(.titleAndIcon)
                .foregroundStyle(item.tint ?? tint)
        case .symbol(let systemImage, let accessibilityLabel):
            Icon(systemImage, size: AppIconSize.xs)
                .foregroundStyle(item.tint ?? tint)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel)
        }
    }
}

// MARK: - Row

/// The look of an `ItemRow` (and the `MetaLine`s in it).
public enum ItemRowStyle: Hashable {
    /// Title in bodyEmphasis, facts in caption.
    case standard
    /// Title in body, facts in bodySmall, a little more air.
    case large
}

/// What stands before an `ItemRow`'s title.
public enum ItemRowLeading {
    /// A symbol on a pale circle of its tint, centred on the row.
    case symbol(String, tint: Color = AppColors.accent)
    /// A symbol alone, at the top of the row (next to a description).
    case glyph(String, tint: Color = AppColors.accent)
}

/// A row for an item of the app's own (a trip, a place, an article, a backup): a symbol, the
/// title with an optional badge, a description, lines of facts (`MetaLine`) and an accessory.
/// No padding of its own: it lives in a `List` or a card's stack, which spaces it.
///
/// ```swift
/// NavigationLink(value: trip.id) {
///     ItemRow(trip.title, meta: [MetaLine([.text(date), .text(distance), .text(duration)])],
///             leading: .symbol(trip.activity.systemImage), titleLineLimit: 1) {
///         DisclosureChevron()
///     }
/// }
/// ```
///
/// - `.standard`: title in bodyEmphasis, facts in caption (Dalada's lists).
/// - `.large`: title in body, facts in bodySmall, a little more air (Tenra's settings lists).
public struct ItemRow<Accessory: View>: View {
    public typealias Style = ItemRowStyle
    public typealias Leading = ItemRowLeading

    let title: String
    let badge: String?
    let detail: String?
    let meta: [MetaLine]
    let leading: Leading?
    let style: Style
    let titleFont: Font?
    let titleLineLimit: Int?
    let accessory: Accessory

    /// The glyph grows with the text, as a `.title3` symbol would.
    @ScaledMetric(relativeTo: .title3) private var glyphSize: CGFloat = AppIconSize.md
    @ScaledMetric(relativeTo: .title3) private var glyphSlot: CGFloat = AppIconSize.lg + AppSpacing.xs

    /// - Parameters:
    ///   - badge: A `Badge` right after the title ("Auto").
    ///   - detail: A description under the title, up to two lines (an article's summary).
    ///   - meta: Lines of facts under it; the first in the secondary grey, pass a tint for a
    ///     fainter one.
    ///   - titleFont: Overrides the style's title font, for a row that had another one.
    ///   - accessory: The trailing edge: `DisclosureChevron()`, a status symbol, a button.
    public init(
        _ title: String,
        badge: String? = nil,
        detail: String? = nil,
        meta: [MetaLine] = [],
        leading: Leading? = nil,
        style: Style = .standard,
        titleFont: Font? = nil,
        titleLineLimit: Int? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.badge = badge
        self.detail = detail
        self.meta = meta
        self.leading = leading
        self.style = style
        self.titleFont = titleFont
        self.titleLineLimit = titleLineLimit
        self.accessory = accessory()
    }

    private var isTopAligned: Bool {
        if case .glyph = leading { return true }
        return false
    }

    public var body: some View {
        HStack(alignment: isTopAligned ? .top : .center, spacing: style == .large ? AppSpacing.sm : AppSpacing.md) {
            leadingView
            VStack(alignment: .leading, spacing: style == .large ? AppSpacing.xs : AppSpacing.xxs) {
                titleLine
                if let detail {
                    Text(verbatim: detail)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                        .lineLimit(2)
                }
                ForEach(Array(meta.enumerated()), id: \.offset) { _, line in
                    line
                }
                .font(style == .large ? AppTypography.bodySmall : AppTypography.caption)
            }
            Spacer(minLength: 0)
            accessory
        }
        .environment(\.itemRowStyle, style)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var titleLine: some View {
        let text = Text(verbatim: title)
            .font(titleFont ?? (style == .large ? AppTypography.body : AppTypography.bodyEmphasis))
            .foregroundStyle(AppColors.Text.primary)
            .lineLimit(titleLineLimit)
        if let badge {
            HStack(spacing: AppSpacing.sm) {
                text
                Badge(badge)
            }
        } else {
            text
        }
    }

    @ViewBuilder
    private var leadingView: some View {
        switch leading {
        case .symbol(let name, let tint):
            Icon(name, size: AppIconSize.md, scalesWithText: false)
                .foregroundStyle(tint)
                .frame(width: AppIconSize.xxl, height: AppIconSize.xxl)
                .background(AppColors.pale(tint), in: Circle())
                .accessibilityHidden(true)
        case .glyph(let name, let tint):
            Icon(name, size: glyphSize, scalesWithText: false)
                .foregroundStyle(tint)
                .frame(width: glyphSlot)
                .accessibilityHidden(true)
        case nil:
            EmptyView()
        }
    }
}

public extension ItemRow where Accessory == EmptyView {
    /// A row with nothing on the trailing edge.
    init(
        _ title: String,
        badge: String? = nil,
        detail: String? = nil,
        meta: [MetaLine] = [],
        leading: Leading? = nil,
        style: Style = .standard,
        titleFont: Font? = nil,
        titleLineLimit: Int? = nil
    ) {
        self.init(title, badge: badge, detail: detail, meta: meta, leading: leading, style: style,
                  titleFont: titleFont, titleLineLimit: titleLineLimit) { EmptyView() }
    }
}

// MARK: - Style environment

private struct ItemRowStyleKey: EnvironmentKey {
    static let defaultValue: ItemRowStyle? = nil
}

extension EnvironmentValues {
    /// The style of the `ItemRow` around a `MetaLine`, which spaces its dots by it.
    var itemRowStyle: ItemRowStyle? {
        get { self[ItemRowStyleKey.self] }
        set { self[ItemRowStyleKey.self] = newValue }
    }
}

// MARK: - Skeleton

/// Placeholder of an `ItemRow`: the pale circle (or none), a title line and `metaLines`
/// shorter lines, in the style's fonts.
public struct ItemRowSkeleton: View {
    let style: ItemRowStyle
    let showsLeading: Bool
    let showsDetail: Bool
    let metaLines: Int

    public init(
        style: ItemRowStyle = .standard,
        showsLeading: Bool = true,
        showsDetail: Bool = false,
        metaLines: Int = 1
    ) {
        self.style = style
        self.showsLeading = showsLeading
        self.showsDetail = showsDetail
        self.metaLines = metaLines
    }

    public var body: some View {
        HStack(spacing: style == .large ? AppSpacing.sm : AppSpacing.md) {
            if showsLeading {
                Skeleton.circle(AppIconSize.xxl)
            }
            VStack(alignment: .leading, spacing: style == .large ? AppSpacing.xs : AppSpacing.xxs) {
                SkeletonText(style == .large ? AppTypography.body : AppTypography.bodyEmphasis, width: 160)
                if showsDetail {
                    SkeletonText(AppTypography.bodySmall, width: 220)
                }
                ForEach(0..<max(metaLines, 0), id: \.self) { _ in
                    SkeletonText(style == .large ? AppTypography.bodySmall : AppTypography.caption, width: 120)
                }
            }
            Spacer(minLength: 0)
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
