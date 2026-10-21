//
//  RowDivider.swift
//  DesignKit
//
//  8.0.0 (the owner's review of the app's screens): one divider between the rows of a card,
//  under the row's text and short of the card's trailing edge by the card's own padding, as in
//  a list of transactions. `FormSection` and `CardList(layout: .section)` draw it between their
//  rows by themselves; a row says where its text starts (`UniversalRow` does on its own).
//

import SwiftUI
import DesignTokens

extension ContainerValues {
    /// Where the divider under a row starts, from the row's leading edge.
    @Entry var rowDividerInset: CGFloat = 0
    /// An explicit `RowDivider` among the rows: no divider is drawn next to it.
    @Entry var isRowDivider: Bool = false
    /// A row that takes the card's whole width: the section does not pad it at the sides.
    @Entry var isFullWidthRow: Bool = false
}

public extension View {
    /// Where the divider under this row starts in a `FormSection` or a
    /// `CardList(layout: .section)`, from the row's leading edge (8.0.0): the width of what
    /// comes before the row's text, an icon and the space after it. `UniversalRow` sets it
    /// itself; a custom row sets it when it has something before its text.
    func rowDividerInset(_ inset: CGFloat) -> some View {
        containerValue(\.rowDividerInset, inset)
    }

    /// A row of a `FormSection` that takes the card's whole width (8.0.0): the section leaves
    /// its sides unpadded, for content that scrolls under the card's edges (chips, a strip of
    /// photos), which keeps itself off the edge with its own inset. The divider under it starts
    /// at the section's padding, as under any row. `ChipPicker` with an `inset` does it itself.
    func fullWidthRow() -> some View {
        containerValue(\.isFullWidthRow, true)
    }
}

/// The divider between two rows in a card (8.0.0): `inset` from the leading edge, where the
/// row's text starts. For rows stacked by hand in a card; `FormSection` and
/// `CardList(layout: .section)` draw it themselves.
///
/// ```swift
/// VStack(spacing: 0) {
///     TransactionRow(…)
///     RowDivider(inset: AppIconSize.Tile.sm + AppSpacing.md)
///     TransactionRow(…)
/// }
/// .padding(.horizontal, AppSpacing.lg)
/// .cardStyle()
/// ```
public struct RowDivider: View {
    let inset: CGFloat

    public init(inset: CGFloat = 0) {
        self.inset = inset
    }

    public var body: some View {
        Divider()
            .padding(.leading, inset)
            .containerValue(\.isRowDivider, true)
    }
}

/// Rows one under another with a `RowDivider` between each two, under the upper row's text.
/// The rows of a `FormSection` and of a `CardList(layout: .section)`. `padding` pads each row
/// at the sides (a `fullWidthRow()` not), and the dividers with it: the card's own padding.
struct DividedRows<Content: View>: View {
    var padding: CGFloat = 0
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    let fullWidth = row.containerValues.isFullWidthRow
                    row
                        .padding(.horizontal, fullWidth ? 0 : padding)
                    if index < rows.count - 1,
                       !row.containerValues.isRowDivider,
                       !rows[index + 1].containerValues.isRowDivider {
                        RowDivider(inset: padding + row.containerValues.rowDividerInset)
                            .padding(.trailing, padding)
                    }
                }
            }
        }
    }
}
