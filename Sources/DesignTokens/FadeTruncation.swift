//
//  FadeTruncation.swift
//  DesignKit
//
//  One-line text that fades out at its trailing edge instead of ending in "…", when it does
//  not fit. Suits names in carousels and tiles, where the ellipsis eats the last letters that
//  still fit.
//

import SwiftUI

public extension View {
    /// Shows one line; if it does not fit, the end fades out over `fadeLength` points instead
    /// of being cut with "…". When it fits, nothing changes.
    ///
    /// ```swift
    /// Text(account.name)
    ///     .font(AppTypography.h4)
    ///     .fadeTruncation()
    /// ```
    func fadeTruncation(fadeLength: CGFloat = 24) -> some View {
        modifier(FadeTruncationModifier(fadeLength: fadeLength))
    }
}

private struct FadeTruncationModifier: ViewModifier {
    let fadeLength: CGFloat
    @State private var textWidth: CGFloat = 0
    @State private var shownWidth: CGFloat = 0

    func body(content: Content) -> some View {
        let overflows = textWidth > shownWidth + 0.5
        // The whole line at its own width, in a frame as wide as the line or the space there
        // is, whichever is narrower; clipped, and its end faded only when it was cut.
        // (ViewThatFits drew its fallback at the line's full width, so the fade fell outside.)
        TruncatingLayout {
            content
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { textWidth = $0 }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { shownWidth = $0 }
        .clipped()
        .mask {
            HStack(spacing: 0) {
                Rectangle()
                LinearGradient(colors: [.black, overflows ? .clear : .black], startPoint: .leading, endPoint: .trailing)
                    .frame(width: fadeLength)
            }
            .flipsForRightToLeftLayoutDirection(true)
        }
    }
}

/// As wide as its one subview's ideal width, or the proposed width if that is narrower; the
/// subview keeps its ideal width inside, starting at the leading edge.
private struct TruncatingLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let line = subviews.first else { return .zero }
        let ideal = line.sizeThatFits(.unspecified)
        let width = proposal.width.map { min($0, ideal.width) } ?? ideal.width
        return CGSize(width: width, height: ideal.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let line = subviews.first else { return }
        let ideal = line.sizeThatFits(.unspecified)
        line.place(at: CGPoint(x: bounds.minX, y: bounds.minY), anchor: .topLeading, proposal: ProposedViewSize(ideal))
    }
}
