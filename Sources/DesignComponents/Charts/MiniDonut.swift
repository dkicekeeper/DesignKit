//
//  MiniDonut.swift
//  Tenra
//
//  Lightweight Canvas-based donut for mini-card overlays in the Insights feed.
//  Replaces `DonutChart(mode: .compact)` to avoid spinning up an Apple Charts
//  render-tree per insight card. With 25+ cards visible during scroll, the
//  Apple Charts hosting cost dominated frame time when LazyVStack materialised
//  a section. One stroked Path per slice is ~50× cheaper to instantiate.
//
//  Visual contract matches the compact `DonutChart`:
//  - Ring proportions: innerRadius = 0.6 × outerRadius
//  - Sectors separated by a small angular gap (matches `angularInset: 1`)
//  - Rounded line caps approximate `cornerRadius` on full-size sectors
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct MiniDonut: View {
    let slices: [DonutSlice]

    public init(slices: [DonutSlice]) {
        self.slices = slices
    }

    /// Gap between adjacent sectors, in radians. ~2.3° — matches the visual
    /// weight of `angularInset: 1` on a 60pt donut.
    private let gapRadians: CGFloat = 0.04

    /// Inner radius as fraction of outer.
    private let innerRatio: CGFloat = 0.6

    public var body: some View {
        Canvas { context, size in
            guard !slices.isEmpty else { return }
            let total = slices.reduce(0.0) { $0 + $1.amount }
            guard total > 0 else { return }

            let outerR = min(size.width, size.height) / 2
            let innerR = outerR * innerRatio
            let strokeR = (outerR + innerR) / 2
            let strokeWidth = outerR - innerR
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            // Angles in radians, starting at 12 o'clock (-π/2) going clockwise.
            var startAngle: CGFloat = -.pi / 2
            let twoPi: CGFloat = .pi * 2
            // When there's only one slice, draw a full ring without a gap.
            let perSliceGap = slices.count > 1 ? gapRadians : 0

            for slice in slices {
                let frac = CGFloat(slice.amount / total)
                let arcAngle = max(0, frac * twoPi - perSliceGap)
                guard arcAngle > 0 else {
                    startAngle += frac * twoPi
                    continue
                }
                let endAngle = startAngle + arcAngle

                let path = Path { p in
                    p.addArc(
                        center: center,
                        radius: strokeR,
                        startAngle: .radians(Double(startAngle)),
                        endAngle: .radians(Double(endAngle)),
                        clockwise: false
                    )
                }

                context.stroke(
                    path,
                    with: .color(slice.color),
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )

                startAngle = endAngle + perSliceGap
            }
        }
        .frame(height: 60)
    }
}

// MARK: - Previews



