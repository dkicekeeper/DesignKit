//
//  ChartDrawIn.swift
//  DesignKit
//
//  A chart drawn in from left to right as it first appears (2.3.0): the line is traced. One
//  mask whose width animates once; the chart's own marks and data are untouched, so it works
//  on Swift Charts and Canvas charts alike.
//
//  LineChart and HeroSparkline use it on their entrance (BarChart's bars rise from zero
//  instead since 8.2.0). Under Reduce Motion, `.designKitMotion(false)` or after a
//  `ChartSwitcher` switch the chart is simply there.
//
//  8.2.0: 0.7 s (0.9 s before), and the mask goes once the chart is drawn, so a scrolling
//  chart no longer renders through it on every frame. Taking it away rebuilds the view under
//  it once: apply it outside any state that must survive (a chart's selection lives in the
//  chart's view, outside the `Chart`).
//

import SwiftUI
import DesignTokens

public extension View {
    /// Reveals the chart from its leading edge to its trailing edge once, on first appearance.
    ///
    /// ```swift
    /// Chart { … }.chartDrawIn()
    /// ```
    func chartDrawIn(delay: Double = 0) -> some View {
        modifier(ChartDrawInModifier(delay: delay))
    }
}

struct ChartDrawInModifier: ViewModifier {
    let delay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    @Environment(\.chartPlaysEntrance) private var playsEntrance
    /// 0 = hidden, `overshoot` = fully drawn.
    @State private var progress: CGFloat = 0
    @State private var isDrawn = false

    private var allowsMotion: Bool { !reduceMotion && designKitMotion && playsEntrance }

    @ViewBuilder
    func body(content: Content) -> some View {
        // Without motion the chart is fully shown from the first frame (snapshots, Reduce Motion).
        if isDrawn || !allowsMotion {
            content
        } else {
            content
                .mask(alignment: .leading) {
                    GeometryReader { proxy in
                        // The reveal's front edge is soft, like ink still spreading.
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: max(0, proxy.size.width * progress))
                            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: ChartDrawInMetrics.edge)
                        }
                    }
                }
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: ChartDrawInMetrics.duration).delay(AppAnimation.chartAppearDelay + delay)
                    ) {
                        progress = ChartDrawInMetrics.overshoot
                    } completion: {
                        isDrawn = true
                    }
                }
        }
    }
}

enum ChartDrawInMetrics {
    static let duration: Double = 0.7
    /// The soft front edge.
    static let edge: CGFloat = 24
    /// Past the trailing edge, so the soft edge leaves the chart fully visible.
    static let overshoot: CGFloat = 1.15
}
