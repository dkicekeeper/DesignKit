//
//  AmbientMotionGate.swift
//  Tenra
//
//  Single answer to "may this view keep redrawing an ambient animation right now?"
//
//  Two signals turn ambient motion off:
//  - Reduce Motion — the accessibility setting these views already honored.
//  - `systemPrefersReducedResourceUsage` (iOS 27) — the system telling apps to back
//    off, e.g. under thermal or power pressure. Continuously redrawing decoration is
//    exactly the work worth dropping first: it carries no information.
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

    public init(@ViewBuilder content: @escaping (_ allowsAmbientMotion: Bool) -> Content) {
        self.content = content
    }

    public var body: some View {
        #if compiler(>=6.4)
        if #available(iOS 27, *) {
            ResourceAwareAmbientMotionGate(reduceMotion: reduceMotion, content: content)
        } else {
            content(!reduceMotion)
        }
        #else
        content(!reduceMotion)
        #endif
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

    let reduceMotion: Bool
    @ViewBuilder var content: (_ allowsAmbientMotion: Bool) -> Content

    @Environment(\.systemPrefersReducedResourceUsage) private var prefersReducedResourceUsage

    var body: some View {
        content(!reduceMotion && !prefersReducedResourceUsage)
    }
}
#endif
