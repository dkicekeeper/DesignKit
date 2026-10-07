//
//  Dissolve.swift
//  DesignKit
//
//  A view breaking into dust as it is removed (2.6.0): a grain of noise decides which pixels go
//  first, the edge of what remains glows, loose grains drift up. Inserted, the same dust
//  gathers into the view. For deleting something the person owned: a transaction, a trip.
//  Keep it for the delete, not for every disappearance.
//
//  One Metal layer effect (Shaders/Dissolve.metal), only while the transition plays. Under
//  Reduce Motion, `.designKitMotion(false)` or without the compiled shaders it is a fade.
//

import SwiftUI
import DesignTokens

/// Breaks the view into dust as it is removed; gathers it as it is inserted.
public struct DissolveTransition: Transition {
    let edge: Color?

    /// - Parameter edge: The glow at the edge of what remains; the accent by default.
    public init(edge: Color? = nil) {
        self.edge = edge
    }

    public func body(content: Content, phase: TransitionPhase) -> some View {
        content.modifier(DissolveEffect(progress: phase.isIdentity ? 0 : 1, edge: edge ?? AppColors.accent))
    }
}

public extension Transition where Self == DissolveTransition {
    /// Breaks the view into dust as it is removed (a fade under Reduce Motion).
    ///
    /// ```swift
    /// ForEach(trips) { trip in
    ///     TripRow(trip).transition(.dissolve)
    /// }
    /// withAnimation(.easeIn(duration: 0.6)) { trips.remove(trip) }
    /// ```
    static var dissolve: DissolveTransition { DissolveTransition() }

    /// Breaks the view into dust as it is removed, its edge glowing in `edge`.
    static func dissolve(edge: Color) -> DissolveTransition { DissolveTransition(edge: edge) }
}

/// The dissolve at one moment: 0 whole, 1 gone. Animatable, so a transition's animation runs it.
struct DissolveEffect: ViewModifier, Animatable {
    var progress: Double
    let edge: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        if let library = DesignKitShaders.library, !reduceMotion, designKitMotion {
            let progress = progress
            let edge = edge
            content.visualEffect { view, proxy in
                view.layerEffect(
                    library.Dissolve(.float2(proxy.size), .float(progress), .color(edge)),
                    // Loose grains are sampled up to 10 pt below where they are drawn.
                    maxSampleOffset: CGSize(width: 0, height: 10),
                    isEnabled: progress > 0
                )
            }
        } else {
            content.opacity(1 - progress)
        }
    }
}
