//
//  GradientOrbsBackground.swift
//  DesignKit
//
//  Soft blurred colour orbs as a gradient background. Each orb's size and brightness follow
//  its weight. Two depth layers (back/front) with different blur radii create a soft parallax
//  look. Ported from Tenra's CategoryGradientBackground; the mapping from its top expense
//  categories to colours stays in Tenra as an adapter.
//
//  Deprecated in 2.5.0: `AuroraBackground(_ spots:)` draws the same weighted pools of colour
//  as one still mesh, with no blur, no screen blend and no offscreen pass.
//

import SwiftUI
import DesignTokens

private enum OrbStyle {
    /// Opacity for gradient orbs — weight=1.0 → 0.45, weight=0.4 → 0.25.
    static func opacity(weight: CGFloat) -> Double {
        0.25 + Double(weight) * 0.20
    }

    /// Blur radius per layer. Back layer = deeper blur (farther), front = sharper (closer).
    static func blur(isBackLayer: Bool) -> CGFloat {
        isBackLayer ? 44 : 28
    }
}

/// Up to three soft, heavily blurred colour orbs, sized and brightened by weight.
///
/// **Usage**: place it *behind* a glass card, which picks up the orb colours:
/// ```swift
/// ZStack {
///     GradientOrbsBackground([
///         .init(color: .orange, weight: 1.0),
///         .init(color: .blue, weight: 0.6),
///         .init(color: .pink, weight: 0.4),
///     ])
///     .clipShape(.rect(cornerRadius: AppRadius.xl))
///     content
///         .cardStyle()
/// }
/// ```
///
/// **Performance**: the orbs are **static**. Animated breathing and drift were barely visible
/// behind the heavy blur, yet forced a per-frame blur + `.screen` blend + `drawingGroup`
/// re-rasterisation of a full-screen background. Rendered statically, the whole background
/// composites once. Never embed inside `List` / `ForEach`.
@available(*, deprecated, message: "Use AuroraBackground(_ spots:), the same weighted pools of colour as a still mesh with no blur: lighter under Liquid Glass. Orb(color:weight:) becomes AuroraBackground.Spot(color:weight:).")
public struct GradientOrbsBackground: View {
    /// One orb.
    public struct Orb: Equatable {
        public let color: Color
        /// 0…1; the heaviest orb is usually 1. Orbs are drawn in the given order, the first
        /// two in the back layer.
        public let weight: Double

        public init(color: Color, weight: Double) {
            self.color = color
            self.weight = weight
        }
    }

    let orbs: [Orb]

    /// - Parameter orbs: Heaviest first; only the first three are drawn.
    public init(_ orbs: [Orb]) {
        self.orbs = orbs
    }

    // MARK: - Orb Layout

    /// Deterministic positions for each orb index so the view is stable across
    /// recompositions.
    ///
    /// Values are fractional offsets relative to the view's width/height: `(dx, dy)` where
    /// ±0.5 puts the orb centre at the edge.
    private static let orbOffsets: [(dx: CGFloat, dy: CGFloat)] = [
        (-0.18,  0.08),  // 0 – dominant: left-centre
        ( 0.22, -0.22),  // 1 – top-right
        ( 0.05,  0.28),  // 2 – bottom-centre
        ( 0.28,  0.12),  // 3 – right-mid
        (-0.24, -0.18),  // 4 – top-left
    ]

    // MARK: - Orb

    /// A single static colour orb.
    private struct OrbView: View {
        let color: Color
        let diameter: CGFloat
        let baseOffset: CGPoint
        let weight: CGFloat
        let isBackLayer: Bool

        var body: some View {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(OrbStyle.opacity(weight: weight)),
                                 color.opacity(0.0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.5
                    )
                )
                .frame(width: diameter, height: diameter)
                .offset(x: baseOffset.x, y: baseOffset.y)
                .blur(radius: OrbStyle.blur(isBackLayer: isBackLayer))
        }
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let base = max(w, h) * 0.85
            // 3 orbs is enough to read as a soft gradient — a 4th/5th would be mostly lost
            // behind the heavy blur.
            let items = Array(orbs.prefix(3))

            // Back layer: first 2 orbs (highest weight) — larger, deeper blur.
            // Front layer: orb 3 — smaller, sharper blur.
            let backItems = Array(items.prefix(2))
            let frontItems = items.count > 2 ? Array(items.dropFirst(2)) : []

            ZStack {
                ForEach(Array(backItems.enumerated()), id: \.offset) { index, item in
                    orb(item: item, index: index, base: base, w: w, h: h, isBackLayer: true)
                }
                .blendMode(.screen)

                ForEach(Array(frontItems.enumerated()), id: \.offset) { index, item in
                    orb(item: item, index: index + 2, base: base, w: w, h: h, isBackLayer: false)
                }
                .blendMode(.screen)
            }
            .frame(width: w, height: h)
            .drawingGroup()
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    /// A single static orb positioned by index.
    private func orb(
        item: Orb,
        index: Int,
        base: CGFloat,
        w: CGFloat,
        h: CGFloat,
        isBackLayer: Bool
    ) -> some View {
        let diameter = base * (0.40 + item.weight * 0.60)
        let offset = Self.orbOffsets[index]

        return OrbView(
            color: item.color,
            diameter: diameter,
            baseOffset: CGPoint(x: offset.dx * w, y: offset.dy * h),
            weight: item.weight,
            isBackLayer: isBackLayer
        )
    }
}
