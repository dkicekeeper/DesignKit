//
//  ChartDrawIn.swift
//  DesignKit
//
//  A chart drawn in from left to right as it first appears (2.3.0): the line is traced, the
//  bars rise one after another. One mask whose width animates once; the chart's own marks
//  and data are untouched, so it works on Swift Charts and Canvas charts alike.
//
//  LineChart, HeroSparkline and BarChart use it on their entrance, with `.chartAppear()`.
//  Under Reduce Motion or `.designKitMotion(false)` the chart is simply there.
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
    /// 0 = hidden, 1 = fully drawn.
    @State private var progress: CGFloat = 0
    @State private var hasStarted = false

    private var allowsMotion: Bool { !reduceMotion && designKitMotion }

    func body(content: Content) -> some View {
        // Without motion the chart is fully shown from the first frame (snapshots, Reduce Motion).
        let reveal = allowsMotion ? progress : ChartDrawInMetrics.overshoot
        content
            .mask(alignment: .leading) {
                GeometryReader { proxy in
                    // The reveal's front edge is soft, like ink still spreading.
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: max(0, proxy.size.width * reveal))
                        LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: ChartDrawInMetrics.edge)
                    }
                }
            }
            .onAppear {
                guard !hasStarted else { return }
                hasStarted = true
                withAnimation(.easeInOut(duration: ChartDrawInMetrics.duration).delay(AppAnimation.chartAppearDelay + delay)) {
                    progress = ChartDrawInMetrics.overshoot
                }
            }
    }
}

enum ChartDrawInMetrics {
    static let duration: Double = 0.9
    /// The soft front edge.
    static let edge: CGFloat = 24
    /// Past the trailing edge, so the soft edge leaves the chart fully visible.
    static let overshoot: CGFloat = 1.15
}
