//
//  MiniMilestoneGauge.swift
//  Tenra
//
//  Canvas-based segmented milestone scale for insight feed cards (2026-07
//  visual refresh). Used where the metric is progress toward a DISCRETE
//  milestone — emergency fund months (target 3 of 6). Discrete segments answer
//  "how many months" more precisely than a continuous arc or bar would.
//
//  Visual grammar (docs/domains/charts.md §Insight mini-visuals):
//  - filled segments = the fact (severity-colored), muted segments = the remainder
//  - the in-progress segment fills partially (0.4 months → 40% of a segment)
//  - tick = the target marker
//
//  No text inside — values live in the card's metric row (localization-free,
//  decorative for VoiceOver).
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct MiniMilestoneGauge: View {
    /// Measured value in milestone units (e.g. 2.4 months).
    let value: Double
    /// Target milestone the tick marks (e.g. 3 months).
    let target: Double
    /// Total segments on the scale (e.g. 6 months).
    let maxValue: Double
    /// Fill tint (severity — the generator knows).
    let color: Color

    var height: CGFloat = 60

    static let segmentHeight: CGFloat = 10
    static let segmentGap: CGFloat = 3
    static let cornerRadius: CGFloat = 3
    static let tickOvershoot: CGFloat = 7

    public init(
        value: Double,
        target: Double,
        maxValue: Double,
        color: Color,
        height: CGFloat = 60
    ) {
        self.value = value
        self.target = target
        self.maxValue = maxValue
        self.color = color
        self.height = height
    }

    public var body: some View {
        Canvas { context, size in
            let segments = max(1, Int(maxValue.rounded()))
            let gapTotal = Self.segmentGap * CGFloat(segments - 1)
            let segmentWidth = (size.width - gapTotal) / CGFloat(segments)
            let y = (size.height - Self.segmentHeight) / 2
            let clamped = min(max(value, 0), maxValue)

            for i in 0..<segments {
                let x = CGFloat(i) * (segmentWidth + Self.segmentGap)
                let rect = CGRect(x: x, y: y, width: segmentWidth, height: Self.segmentHeight)
                let shape = Path(roundedRect: rect, cornerRadius: Self.cornerRadius)

                // Muted base for every segment.
                context.fill(shape, with: .color(AppColors.Text.secondary.opacity(0.18)))

                // Fill: whole segments solid, the in-progress one partially —
                // clip the partial fill to the segment's rounded shape.
                let fillFraction = min(max(clamped - Double(i), 0), 1)
                guard fillFraction > 0 else { continue }
                if fillFraction >= 1 {
                    context.fill(shape, with: .color(color))
                } else {
                    var partial = context
                    partial.clip(to: shape)
                    partial.fill(
                        Path(CGRect(x: x, y: y, width: segmentWidth * CGFloat(fillFraction), height: Self.segmentHeight)),
                        with: .color(color)
                    )
                }
            }

            // Target tick — on the boundary after the `target`-th segment
            // (between segments, like a finish line).
            let targetIndex = min(max(target, 0), maxValue)
            let tickX = CGFloat(targetIndex) * (segmentWidth + Self.segmentGap) - Self.segmentGap / 2
            let tickRect = CGRect(
                x: tickX - 1.25,
                y: y - Self.tickOvershoot,
                width: 2.5,
                height: Self.segmentHeight + Self.tickOvershoot * 2
            )
            context.fill(
                Path(roundedRect: tickRect, cornerRadius: 1.25),
                with: .color(AppColors.Text.secondary.opacity(0.7))
            )
        }
        .frame(height: height)
    }
}

// MARK: - Previews

// MARK: - Skeleton

/// Placeholder of a `MiniMilestoneGauge`: its row of rounded segments.
public struct MiniMilestoneGaugeSkeleton: View {
    let segments: Int
    let height: CGFloat

    public init(segments: Int = 6, height: CGFloat = 60) {
        self.segments = max(1, segments)
        self.height = height
    }

    public var body: some View {
        HStack(spacing: MiniMilestoneGauge.segmentGap) {
            ForEach(0..<segments, id: \.self) { _ in
                Skeleton(height: MiniMilestoneGauge.segmentHeight, cornerRadius: MiniMilestoneGauge.cornerRadius)
            }
        }
        .frame(height: height)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
