//
//  MiniProportionBar.swift
//  Tenra
//
//  Horizontal stacked composition bar for insight feed cards (2026-07 visual
//  refresh): how a total splits into parts — the recurring cost card shows the
//  top subscriptions + "other". Takes the same `[DonutSlice]` as MiniDonut /
//  OrbChart so callers reuse one slice-building path.
//
//  A donut would also say "composition", but at 120×60 a donut next to the
//  wealth card's donut makes two adjacent cards read identically — the flat
//  bar keeps the feed visually diverse while using the same grammar.
//
//  No text inside (localization-free, decorative for VoiceOver).
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct MiniProportionBar: View {
    let segments: [DonutSlice]

    var barHeight: CGFloat = 10
    var segmentGap: CGFloat = 2
    var height: CGFloat = 60

    public init(
        segments: [DonutSlice],
        barHeight: CGFloat = 10,
        segmentGap: CGFloat = 2,
        height: CGFloat = 60
    ) {
        self.segments = segments
        self.barHeight = barHeight
        self.segmentGap = segmentGap
        self.height = height
    }

    public var body: some View {
        GeometryReader { geo in
            let total = segments.reduce(0.0) { $0 + $1.amount }
            if total > 0 {
                // Every intermediate is explicitly typed. As one fused expression this
                // mixed CGFloat, Double and literals across max/*/-//, and the constraint
                // solver spent 3.56s type-checking this body on every build (measured with
                // -warn-long-function-bodies). Annotating the steps makes it instant.
                let gapTotal: CGFloat = segmentGap * CGFloat(segments.count - 1)
                let available: CGFloat = geo.size.width - gapTotal
                let minWidth: CGFloat = barHeight / 2 // a sliver stays visible as a nub
                HStack(spacing: segmentGap) {
                    ForEach(segments) { segment in
                        let share: CGFloat = CGFloat(segment.amount / total)
                        Rectangle()
                            .fill(segment.color)
                            .frame(width: max(minWidth, available * share))
                    }
                }
                .frame(height: barHeight)
                .clipShape(Capsule())
                .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Previews

// MARK: - Skeleton

/// Placeholder of a `MiniProportionBar`: the capsule bar, centred in the same slot.
public struct MiniProportionBarSkeleton: View {
    let barHeight: CGFloat
    let height: CGFloat

    public init(barHeight: CGFloat = 10, height: CGFloat = 60) {
        self.barHeight = barHeight
        self.height = height
    }

    public var body: some View {
        Skeleton.capsule(height: barHeight)
            .frame(height: height)
            .skeletonLoadingLabel()
    }
}
