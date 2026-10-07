//
//  ScrollHero.swift
//  DesignKit
//
//  A hero that lives with the scroll (2.3.0), for the image or header at the top of a detail
//  screen: pulled down, it stretches to fill the gap instead of leaving an empty band; scrolled
//  away, it drifts slower than the content and fades. (HIG: "stretchy" headers in Music,
//  App Store; Material: collapsing / parallax app bar.)
//
//  Light: one `visualEffect` reads the hero's place in the scroll view each frame; nothing
//  re-renders. Under Reduce Motion or `.designKitMotion(false)` there is no parallax; the
//  stretch stays, because it follows the finger.
//

import SwiftUI
import DesignTokens

public extension View {
    /// Stretches the view when the scroll view is pulled down, and lets it drift and fade as
    /// it scrolls away. For the first view inside a vertical `ScrollView`.
    ///
    /// ```swift
    /// ScrollView {
    ///     AsyncImage(url: trip.cover).frame(height: 280).clipped()
    ///         .scrollHero()
    ///     TripDetails(trip)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - parallax: How much slower than the content the hero leaves: 0 scrolls with it,
    ///     0.5 at half its speed.
    ///   - fades: The hero fades as it scrolls away.
    func scrollHero(parallax: CGFloat = ScrollHeroMetrics.parallax, fades: Bool = true) -> some View {
        modifier(ScrollHeroModifier(parallax: parallax, fades: fades))
    }
}

public enum ScrollHeroMetrics {
    /// The default parallax: the hero leaves at 70 % of the content's speed.
    public static let parallax: CGFloat = 0.3
    /// How faint the hero is once scrolled its own height away.
    static let fadeDepth: Double = 0.6
}

struct ScrollHeroModifier: ViewModifier {
    let parallax: CGFloat
    let fades: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    /// Where the hero sits at rest (the scroll view's top inset); measured once.
    @State private var rest: CGFloat?

    func body(content: Content) -> some View {
        let rest = rest
        let drifts = !reduceMotion && designKitMotion
        let parallax = parallax
        let fades = fades
        content
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.frame(in: .scrollView).minY
            } action: { minY in
                // Written once, so scrolling never re-renders the hero.
                if self.rest == nil { self.rest = minY }
            }
            .visualEffect { view, proxy in
                let frame = proxy.frame(in: .scrollView)
                let height = max(frame.height, 1)
                let shift = rest.map { frame.minY - $0 } ?? 0
                let pull = max(shift, 0)
                let scrolled = max(-shift, 0)
                return view
                    // Grows from its bottom edge by exactly the pull, so no gap opens above.
                    .scaleEffect(1 + pull / height, anchor: .bottom)
                    .offset(y: drifts ? scrolled * parallax : 0)
                    .opacity(fades ? 1 - Double(min(scrolled / height, 1)) * ScrollHeroMetrics.fadeDepth : 1)
            }
    }
}
