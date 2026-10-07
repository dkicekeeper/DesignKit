//
//  InteractiveTilt.swift
//  DesignKit
//
//  Depth you can touch (2.2.0):
//  • .interactiveTilt(in:)  — the view tilts towards the finger in 3D with a glare where it
//                             touches, and springs back on release: an achievement medal, a
//                             card on its own detail screen, a premium badge.
//  • .scrollReveal()        — rows and cards settle in as they scroll into view and recede
//                             at the edges (scrollTransition: no state, no timers).
//
//  Tilt is for an object shown on its own; inside a scrolling list it would fight the scroll.
//  Under Reduce Motion or `.designKitMotion(false)` neither moves: scrollReveal keeps a light
//  fade only.
//

import SwiftUI
import DesignTokens

public extension View {
    /// The view tilts towards the finger (up to `maxAngle`) with a glare clipped to `shape`, and
    /// springs back on release.
    ///
    /// ```swift
    /// AchievementMedal(…).interactiveTilt(in: Circle())
    /// ```
    func interactiveTilt<S: Shape>(in shape: S, maxAngle: Double = TiltMetrics.maxAngle) -> some View {
        modifier(InteractiveTiltModifier(shape: shape, maxAngle: maxAngle))
    }

    /// Settles in as it scrolls into view: at the top and bottom edges it is a little smaller,
    /// fainter and softer. For the rows and cards of a `ScrollView`.
    func scrollReveal() -> some View {
        modifier(ScrollRevealModifier())
    }
}

public enum TiltMetrics {
    /// The largest tilt, in degrees.
    public static let maxAngle: Double = 10
    /// The glare's brightest point.
    static let glareOpacity: Double = 0.35
    /// The scale while pressed.
    static let pressedScale: CGFloat = 0.98
}

// MARK: - Tilt

private struct InteractiveTiltModifier<S: Shape>: ViewModifier {
    let shape: S
    let maxAngle: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    /// The finger, in unit coordinates (0…1); `nil` at rest.
    @State private var touch: UnitPoint?
    /// The view's size, read without taking part in layout.
    @State private var size: CGSize = .zero

    private var allowsMotion: Bool { !reduceMotion && designKitMotion }

    func body(content: Content) -> some View {
        let tilt = angle(for: touch)
        content
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                size = newSize
            }
            // Simultaneous: a tap on a button inside still works.
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard allowsMotion, size.width > 0, size.height > 0 else { return }
                        let point = UnitPoint(
                            x: min(max(value.location.x / size.width, 0), 1),
                            y: min(max(value.location.y / size.height, 0), 1)
                        )
                        withAnimation(AppAnimation.snappy) { touch = point }
                    }
                    .onEnded { _ in
                        withAnimation(AppAnimation.bouncy) { touch = nil }
                    }
            )
            .overlay {
                if let touch {
                    RadialGradient(
                        colors: [.white.opacity(TiltMetrics.glareOpacity), .clear],
                        center: touch,
                        startRadius: 0,
                        endRadius: max(size.width, size.height) * 0.7
                    )
                    .clipShape(shape)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
            .rotation3DEffect(.degrees(tilt.x), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .rotation3DEffect(.degrees(tilt.y), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .scaleEffect(touch == nil ? 1 : TiltMetrics.pressedScale)
    }

    /// Pressing the top edge tips it away (it rotates about x), the right edge about y.
    private func angle(for touch: UnitPoint?) -> (x: Double, y: Double) {
        guard let touch else { return (0, 0) }
        return (x: (0.5 - touch.y) * 2 * maxAngle, y: (touch.x - 0.5) * 2 * maxAngle)
    }
}

// MARK: - Scroll reveal

private struct ScrollRevealModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion

    func body(content: Content) -> some View {
        let moves = !reduceMotion && designKitMotion
        content.scrollTransition(.interactive(timingCurve: .easeOut)) { view, phase in
            view
                .opacity(phase.isIdentity ? 1 : ScrollRevealMetrics.edgeOpacity)
                .scaleEffect(phase.isIdentity || !moves ? 1 : ScrollRevealMetrics.edgeScale)
                .blur(radius: phase.isIdentity || !moves ? 0 : ScrollRevealMetrics.edgeBlur)
        }
    }
}

enum ScrollRevealMetrics {
    static let edgeOpacity: Double = 0.5
    static let edgeScale: CGFloat = 0.95
    static let edgeBlur: CGFloat = 1.5
}
