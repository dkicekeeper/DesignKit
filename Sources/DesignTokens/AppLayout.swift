//
//  AppLayout.swift
//  DesignKit
//
//  A screen on a large screen (8.13.0): how wide its content runs on an iPad or in a Mac window,
//  and the grid that puts cards side by side there. On a phone nothing changes.
//

import SwiftUI

/// How wide a screen's content runs on a large screen (8.13.0).
///
/// On an iPad, or in a Mac window, a column of cards and text across the whole screen is hard to
/// read: lines of 150 characters, a switch a long way from its label. The content keeps to a
/// centred column instead (`.readableWidth()`), and cards that stand on their own go side by side
/// (`AppLayout.cardColumns()`). A phone is narrower than both, so its screens look as before.
public enum AppLayout {
    /// 720 pt: the widest a column of cards, rows and text runs, its margins included
    /// (`.readableWidth()`), at the default text size; it grows with the person's text size, as
    /// the system's readable width does. A phone (up to 440 pt) is narrower.
    public static let readableWidth: CGFloat = 720

    /// 1120 pt: the widest a grid of cards runs (`.readableWidth(AppLayout.wideWidth)`), three
    /// cards of `cardMinWidth` side by side, so a 13-inch iPad or a wide window does not stretch
    /// them further.
    public static let wideWidth: CGFloat = 1120

    /// 320 pt: the narrowest a card gets in a grid of cards (`cardColumns()`). A phone holds one
    /// in a row, an iPad two or three.
    public static let cardMinWidth: CGFloat = 320

    /// 340 pt: the side column beside a screen's main column (`AdaptiveColumns`, 8.15.0), where
    /// cards made for a phone keep their look: a summary, what comes next, the latest items.
    public static let sideColumnWidth: CGFloat = 340

    /// 400 pt: the narrowest a screen's main column gets with a side column beside it
    /// (`AdaptiveColumns`, 8.15.0), about a phone's width. Narrower, the side column folds away:
    /// the two columns need 764 pt at the default text size, more at a larger one.
    public static let mainColumnMinWidth: CGFloat = 400

    /// The columns of a grid of cards: as many side by side as fit at `minimum` each, one on a
    /// phone. `LazyVGrid(columns: AppLayout.cardColumns(), spacing: AppSpacing.lg) { … }`.
    ///
    /// - Parameters:
    ///   - minimum: The narrowest a card gets (`cardMinWidth`).
    ///   - spacing: The gap between the columns (`AppSpacing.lg`, as between cards in a column).
    public static func cardColumns(
        minimum: CGFloat = cardMinWidth,
        spacing: CGFloat = AppSpacing.lg
    ) -> [GridItem] {
        [GridItem(.adaptive(minimum: minimum), spacing: spacing, alignment: .top)]
    }
}

// MARK: - Readable width

public extension View {
    /// Keeps a screen's content in a centred column no wider than `width` (8.13.0): on an iPad or
    /// in a Mac window the cards and text stay readable instead of running across the screen; on a
    /// phone, narrower than the column, nothing changes. Put it on the scroll view's content,
    /// after `.screenPadding()`; the column grows with the person's text size.
    ///
    /// ```swift
    /// ScrollView {
    ///     VStack(spacing: AppSpacing.lg) { … }
    ///         .screenPadding()
    ///         .readableWidth()
    /// }
    /// ```
    ///
    /// - Parameter width: The column's widest at the default text size, its margins included:
    ///   `AppLayout.readableWidth` for cards and text, `AppLayout.wideWidth` for a grid of cards
    ///   (`AppLayout.cardColumns()`).
    func readableWidth(_ width: CGFloat = AppLayout.readableWidth) -> some View {
        modifier(ReadableWidthModifier(width: width))
    }
}

/// The column of `.readableWidth()`: no wider than its width, which scales with the text size
/// like the system's readable content guide, and centred in what is left.
private struct ReadableWidthModifier: ViewModifier {
    @ScaledMetric private var width: CGFloat

    init(width: CGFloat) {
        _width = ScaledMetric(wrappedValue: width, relativeTo: .body)
    }

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: width)
            .frame(maxWidth: .infinity)
    }
}
