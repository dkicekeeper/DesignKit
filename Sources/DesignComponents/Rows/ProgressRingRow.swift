//
//  ProgressRingRow.swift
//  DesignKit
//
//  A row whose icon wears a progress ring: the name, then "spent / limit (74%)", or a
//  placeholder line when there is no limit. Ported from Tenra's CategoryRow; its category
//  model, the tap, the swipe-to-delete and the over-budget haptic stay in Tenra as an adapter.
//  2.1.0: an `AmountRow` with a `.limit` value in the list style; this name is deprecated. The
//  icon keeps the ring's room with or without a limit, so a list of both lines up.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "(🍴) Food / 185 000 / 250 000 ₸ (74%)", the ring around the icon at 74%.
///
/// At accessibility text sizes "spent / limit (74%)" does not fit beside the ring: the spent
/// amount, "/ limit" and the share go on three lines.
///
/// A `List` row: it has no padding of its own, the list's row insets place it. Make it
/// tappable with a `Button` (`.buttonStyle(.plain)`, `.contentShape(Rectangle())`) and add
/// `.swipeActions` at the call site.
///
/// ```swift
/// ProgressRingRow(iconSource: .sfSymbol("fork.knife"), color: .orange, title: "Food",
///                 progress: LimitProgress(spent: 185_000, limit: 250_000), currency: "KZT")
/// ProgressRingRow(iconSource: .sfSymbol("car.fill"), color: .blue, title: "Transport",
///                 progress: nil, currency: "KZT", placeholder: "No budget set")
/// ```
@available(*, deprecated, message: "Use AmountRow(title, leading: .tinted(source, color), value: .limit(progress, placeholder:), currency:, style: .list).")
public struct ProgressRingRow: View {
    let iconSource: IconSource?
    let color: Color
    let title: String
    let progress: LimitProgress?
    let currency: String
    let placeholder: String?
    let transitionSourceID: String?
    let transitionNamespace: Namespace.ID?

    /// - Parameters:
    ///   - color: Tints the icon and its circle.
    ///   - progress: Draws the ring and the "spent / limit (N%)" line, in the destructive
    ///     colour when over the limit; `nil` shows `placeholder` instead.
    ///   - placeholder: The line under the title when there is no limit; `nil` shows nothing.
    ///   - transitionSourceID: With `transitionNamespace`, makes the icon (with its ring) the
    ///     source of a `.navigationTransition(.zoom(sourceID:in:))`.
    public init(
        iconSource: IconSource?,
        color: Color,
        title: String,
        progress: LimitProgress?,
        currency: String,
        placeholder: String? = nil,
        transitionSourceID: String? = nil,
        transitionNamespace: Namespace.ID? = nil
    ) {
        self.iconSource = iconSource
        self.color = color
        self.title = title
        self.progress = progress
        self.currency = currency
        self.placeholder = placeholder
        self.transitionSourceID = transitionSourceID
        self.transitionNamespace = transitionNamespace
    }

    public var body: some View {
        AmountRow(
            title,
            leading: .tinted(iconSource, color),
            value: .limit(progress, placeholder: placeholder),
            currency: currency,
            style: .list,
            transitionSourceID: transitionSourceID,
            transitionNamespace: transitionNamespace
        )
    }
}

// MARK: - Skeleton

/// Placeholder of a `ProgressRingRow`: `AmountRowSkeleton(style: .list, showsRing: true)`.
@available(*, deprecated, message: "Use AmountRowSkeleton(style: .list, showsRing: true).")
public struct ProgressRingRowSkeleton: View {
    public init() {}

    public var body: some View {
        AmountRowSkeleton(style: .list, showsRing: true)
    }
}
