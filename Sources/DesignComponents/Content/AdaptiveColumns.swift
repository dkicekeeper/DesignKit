//
//  AdaptiveColumns.swift
//  DesignKit
//
//  A screen's main column with a side column beside it where the width allows (8.15.0): on an
//  iPad or in a wide Mac window a game's trophies with its guide and sessions beside them, a
//  trip's route with its weather and group. Narrower, as on a phone, the screen's own narrow
//  layout: the side under the main column, or chips that switch between the parts.
//

import SwiftUI
import DesignTokens

/// A main column and a side column side by side when they fit, the narrow layout when not
/// (8.15.0).
///
/// ```swift
/// ScrollView {
///     AdaptiveColumns {
///         TrophyList(game)                 // the main column: what the screen is for
///     } side: {
///         GuideSummaryCard(game)           // the side: summaries and what comes next
///         SessionsCard(game)
///     } narrow: {
///         ChipPicker(…)                    // a phone: one part at a time
///         selectedPart
///     }
///     .screenPadding()
///     .readableWidth(AppLayout.wideWidth)
/// }
/// ```
///
/// What decides is the width the view gets, never the device: two columns need
/// `mainColumnMinWidth` + `spacing` + `sideColumnWidth` (764 pt at the default text size; both
/// widths grow with the person's text size). So an iPad shows them side by side, a phone, an iPad
/// mini in portrait or a screen that gave room to a panel shows the narrow layout, and a Mac
/// window switches as it is resized. Without `narrow:`, the side stacks under the main column.
///
/// The two layouts are different views: state kept inside the columns (a field's text, a scroll
/// position) starts over when the layout switches, so keep it in the screen.
public struct AdaptiveColumns<Main: View, Side: View, Narrow: View>: View {
    @ScaledMetric private var sideWidth: CGFloat
    @ScaledMetric private var mainMinWidth: CGFloat
    private let spacing: CGFloat
    private let main: Main
    private let side: Side
    private let narrow: Narrow

    /// A main column, a side column beside it, and the screen's own narrow layout.
    ///
    /// - Parameters:
    ///   - sideWidth: The side column's width at the default text size (`AppLayout.sideColumnWidth`).
    ///   - mainMinWidth: The narrowest the main column gets beside it (`AppLayout.mainColumnMinWidth`).
    ///   - spacing: The gap between the columns (`AppSpacing.xxl`).
    ///   - main: The main column: what the screen is for. It takes the rest of the width.
    ///   - side: The side column's content, top to bottom, `AppSpacing.lg` apart.
    ///   - narrow: What shows when the two do not fit, as on a phone.
    public init(
        sideWidth: CGFloat = AppLayout.sideColumnWidth,
        mainMinWidth: CGFloat = AppLayout.mainColumnMinWidth,
        spacing: CGFloat = AppSpacing.xxl,
        @ViewBuilder main: () -> Main,
        @ViewBuilder side: () -> Side,
        @ViewBuilder narrow: () -> Narrow
    ) {
        _sideWidth = ScaledMetric(wrappedValue: sideWidth, relativeTo: .body)
        _mainMinWidth = ScaledMetric(wrappedValue: mainMinWidth, relativeTo: .body)
        self.spacing = spacing
        self.main = main()
        self.side = side()
        self.narrow = narrow()
    }

    public var body: some View {
        // ViewThatFits picks the first child whose ideal width fits: the columns' ideal width is
        // exactly the main column's minimum, the gap and the side's width, so they show as soon
        // as both fit, the main column then taking whatever is left.
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: spacing) {
                main
                    .frame(minWidth: mainMinWidth, idealWidth: mainMinWidth, maxWidth: .infinity, alignment: .topLeading)
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    side
                }
                .frame(width: sideWidth, alignment: .topLeading)
            }
            narrow
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

public extension AdaptiveColumns where Narrow == AdaptiveColumnsStack<Main, Side> {
    /// A main column with a side column beside it, and under it where they do not fit.
    ///
    /// - Parameters:
    ///   - sideWidth: The side column's width at the default text size (`AppLayout.sideColumnWidth`).
    ///   - mainMinWidth: The narrowest the main column gets beside it (`AppLayout.mainColumnMinWidth`).
    ///   - spacing: The gap between the columns (`AppSpacing.xxl`); stacked, they are
    ///     `AppSpacing.lg` apart, as cards in a column.
    ///   - main: The main column: what the screen is for.
    ///   - side: The side column's content, top to bottom.
    init(
        sideWidth: CGFloat = AppLayout.sideColumnWidth,
        mainMinWidth: CGFloat = AppLayout.mainColumnMinWidth,
        spacing: CGFloat = AppSpacing.xxl,
        @ViewBuilder main: () -> Main,
        @ViewBuilder side: () -> Side
    ) {
        let mainColumn = main()
        let sideColumn = side()
        self.init(sideWidth: sideWidth, mainMinWidth: mainMinWidth, spacing: spacing) {
            mainColumn
        } side: {
            sideColumn
        } narrow: {
            AdaptiveColumnsStack(main: mainColumn, side: sideColumn)
        }
    }
}

/// The narrow layout of `AdaptiveColumns` without one of its own: the main column, then the side
/// column's content under it, `AppSpacing.lg` apart.
public struct AdaptiveColumnsStack<Main: View, Side: View>: View {
    let main: Main
    let side: Side

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            main
            side
        }
    }
}
