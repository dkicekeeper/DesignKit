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

    func body(content: Content) -> some View {
        ViewThatFits(in: .horizontal) {
            // Fits: as it is.
            content.lineLimit(1)
            // Does not fit: the whole line, clipped to the space there is, its end faded.
            content
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()
                .mask {
                    HStack(spacing: 0) {
                        Rectangle()
                        LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: fadeLength)
                    }
                    .flipsForRightToLeftLayoutDirection(true)
                }
        }
    }
}
