//
//  AmbientMotionGate.swift
//  Tenra
//
//  Single answer to "may this view keep redrawing an ambient animation right now?"
//
//  Three signals turn ambient motion off:
//  - Reduce Motion — the accessibility setting these views already honored.
//  - `systemPrefersReducedResourceUsage` (iOS 27) — the system telling apps to back
//    off, e.g. under thermal or power pressure. Continuously redrawing decoration is
//    exactly the work worth dropping first: it carries no information.
//  - Off screen (8.22.0) — scrolled well out of sight: a creature at the top of a long
//    screen, a background preview in a carousel, a skeleton far down a list. A view
//    more than half a scroll view's size outside its visible part stops; it starts again
//    before it comes back into sight, so its still frame is never seen.
//
//  Only views driven by a `TimelineView` (display-rate or 30 fps) need this. A
//  one-shot transition is not ambient motion.
//

import SwiftUI

public struct AmbientMotionGate<Content: View>: View {

    /// Receives `false` when ambient motion should be suspended; render a static
    /// frame in that case rather than removing the view, so layout does not shift.
    @ViewBuilder var content: (_ allowsAmbientMotion: Bool) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Whether the view is near the visible part of the scroll views round it (8.22.0). True
    /// until it is measured, and outside a scroll view.
    @State private var isNearScreen = true

    public init(@ViewBuilder content: @escaping (_ allowsAmbientMotion: Bool) -> Content) {
        self.content = content
    }

    public var body: some View {
        gated(!reduceMotion && isNearScreen)
            .onGeometryChange(for: Bool?.self) { proxy in
                AmbientViewport.isNear(proxy)
            } action: { near in
                // No size, no answer (vNext): content that draws nothing while stopped would
                // otherwise read as near, start, measure far, stop, and never settle.
                if let near { isNearScreen = near }
            }
    }

    @ViewBuilder
    private func gated(_ allows: Bool) -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27, *) {
            ResourceAwareAmbientMotionGate(allows: allows, content: content)
        } else {
            content(allows)
        }
        #else
        content(allows)
        #endif
    }
}

/// Where a view is against the scroll views round it (8.22.0).
enum AmbientViewport {
    /// How far outside a scroll view's visible part a view still moves, as a share of that
    /// part's size: it starts again before it shows, and a card peeking past the edge of a
    /// carousel that does not clip keeps moving.
    static let margin: CGFloat = 0.5

    /// Whether any of the view is within `margin` of the visible part of every scroll view round
    /// it, down and across: a card scrolled off a carousel that is itself off the page is out.
    /// Outside a scroll view it is near. Without a size there is no answer (nil): the gate keeps
    /// what it had (vNext). A view that drew nothing while stopped read as near here, started,
    /// read as far, stopped again, and so on in one layout pass: a skeleton's shimmer scrolled out
    /// of sight hung the layout of a screen pushed onto a navigation stack (Platina, 8.22.0).
    static func isNear(_ proxy: GeometryProxy) -> Bool? {
        isNear(size: proxy.size,
               vertical: proxy.bounds(of: .scrollView(axis: .vertical)),
               horizontal: proxy.bounds(of: .scrollView(axis: .horizontal)))
    }

    /// `isNear(_:)` on plain values: the view's size and the visible parts of the scroll views
    /// round it, in its own space (tests).
    static func isNear(size: CGSize, vertical: CGRect?, horizontal: CGRect?) -> Bool? {
        let own = CGRect(origin: .zero, size: size)
        guard own.width > 0, own.height > 0 else { return nil }
        return isNear(own, vertical) && isNear(own, horizontal)
    }

    /// Whether `own` is within `margin` of `visible`, a scroll view's visible part in the view's
    /// own space; no scroll view, near.
    static func isNear(_ own: CGRect, _ visible: CGRect?) -> Bool {
        guard let visible else { return true }
        return visible.insetBy(dx: -visible.width * margin, dy: -visible.height * margin).intersects(own)
    }
}

// `systemPrefersReducedResourceUsage` exists only in the iOS 27 SDK (Xcode 27). DesignKit
// must also build with Xcode 26 (consumers' CI), so the iOS 27 path is compiled only by a
// toolchain that ships that SDK; on Xcode 26 the gate honours Reduce Motion alone.
#if compiler(>=6.4)
/// Split into its own type because `@Environment(\.systemPrefersReducedResourceUsage)`
/// is iOS 27-only: a stored property cannot carry an availability annotation, so the
/// type carries it instead.
@available(iOS 27, *)
private struct ResourceAwareAmbientMotionGate<Content: View>: View {

    /// What Reduce Motion and the view's place on screen allow.
    let allows: Bool
    @ViewBuilder var content: (_ allowsAmbientMotion: Bool) -> Content

    @Environment(\.systemPrefersReducedResourceUsage) private var prefersReducedResourceUsage

    var body: some View {
        content(allows && !prefersReducedResourceUsage)
    }
}
#endif
