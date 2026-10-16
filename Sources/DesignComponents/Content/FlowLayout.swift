//
//  FlowLayout.swift
//  DesignKit
//
//  Places views left to right and wraps to a new line when the row is full, like words in a
//  paragraph: tags, chips that should not scroll, filters. (SwiftUI has no built-in one.)
//

import SwiftUI
import DesignTokens

/// Rows of subviews at their ideal size, wrapping at the proposed width.
///
/// ```swift
/// FlowLayout {
///     ForEach(tags, id: \.self) { Badge($0) }
/// }
/// ```
///
/// Leading-aligned by default (right-to-left aware); `alignment` (2.9.0) centres or right-aligns
/// each row instead. A subview wider than the row gets the row's width.
public struct FlowLayout: Layout {
    public var spacing: CGFloat
    public var lineSpacing: CGFloat
    public var alignment: HorizontalAlignment

    public init(
        spacing: CGFloat = AppSpacing.sm,
        lineSpacing: CGFloat = AppSpacing.sm,
        alignment: HorizontalAlignment = .leading
    ) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.alignment = alignment
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x: CGFloat
            switch alignment {
            case .center: x = bounds.minX + (bounds.width - row.width) / 2
            case .trailing: x = bounds.maxX - row.width
            default: x = bounds.minX
            }
            for (position, item) in row.items.enumerated() {
                if position > 0 { x += item.gap }
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        /// `gap`: the space before the subview when it is not first in its row.
        var items: [(index: Int, size: CGSize, gap: CGFloat)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat?, subviews: Subviews) -> [Row] {
        let maxWidth = width ?? .infinity
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            var size = subviews[index].sizeThatFits(.unspecified)
            if size.width > maxWidth {
                size = subviews[index].sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
                size.width = min(size.width, maxWidth)
            }
            let gap = subviews[index][FlowJoinsPrevious.self] ? 0 : spacing
            let needed = row.items.isEmpty ? size.width : row.width + gap + size.width
            if needed > maxWidth, !row.items.isEmpty {
                rows.append(row)
                row = Row()
            }
            row.width = row.items.isEmpty ? size.width : row.width + gap + size.width
            row.height = max(row.height, size.height)
            row.items.append((index, size, gap))
        }
        if !row.items.isEmpty { rows.append(row) }
        return rows
    }
}

/// A subview that sits right after the previous one, with no `spacing` between them; a row may
/// still end between the two. `StreamingText` (5.1.1) sets it on the words of a line written
/// without spaces (Japanese, Chinese, Thai), so the line wraps between words without gaps.
struct FlowJoinsPrevious: LayoutValueKey {
    static let defaultValue = false
}
