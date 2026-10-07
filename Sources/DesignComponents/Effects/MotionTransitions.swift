//
//  MotionTransitions.swift
//  DesignKit
//
//  Insertion and removal transitions that know Reduce Motion (2.2.0). Each moves a little
//  and fades; under Reduce Motion (or `.designKitMotion(false)`) the movement goes and only
//  the fade stays, which is what the HIG asks for: replace motion with a dissolve, do not
//  drop the change of state.
//
//  • .popIn  — grows from 92 % while fading in: a chip, a badge, a toast, a tooltip.
//  • .riseIn — rises 12 pt and sharpens from a light blur: a card, a section, a banner.
//  (.blurSlideHero / .blurSlideWord stay the transitions for text, BlurSlideTransition.swift.)
//

import SwiftUI
import DesignTokens

/// Grows from 92 % while fading in; shrinks back while fading out.
public struct PopInTransition: Transition {
    public init() {}

    public func body(content: Content, phase: TransitionPhase) -> some View {
        content.modifier(PopInEffect(phase: phase))
    }
}

/// Rises from 12 pt below and sharpens from a light blur while fading in; keeps rising while
/// fading out.
public struct RiseInTransition: Transition {
    public init() {}

    public func body(content: Content, phase: TransitionPhase) -> some View {
        content.modifier(RiseInEffect(phase: phase))
    }
}

public extension Transition where Self == PopInTransition {
    /// Grows from 92 % while fading in (a chip, a badge, a toast); a fade under Reduce Motion.
    static var popIn: PopInTransition { PopInTransition() }
}

public extension Transition where Self == RiseInTransition {
    /// Rises 12 pt and sharpens while fading in (a card, a section, a banner); a fade under
    /// Reduce Motion.
    static var riseIn: RiseInTransition { RiseInTransition() }
}

enum MotionTransitionMetrics {
    static let popScale: CGFloat = 0.92
    static let rise: CGFloat = 12
    static let blur: CGFloat = 4
}

// A transition cannot read the environment; its modifier can.

private struct PopInEffect: ViewModifier {
    let phase: TransitionPhase

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion

    func body(content: Content) -> some View {
        let moves = !reduceMotion && designKitMotion && !phase.isIdentity
        content
            .scaleEffect(moves ? MotionTransitionMetrics.popScale : 1)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

private struct RiseInEffect: ViewModifier {
    let phase: TransitionPhase

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion

    func body(content: Content) -> some View {
        let moves = !reduceMotion && designKitMotion && !phase.isIdentity
        content
            // In from below, out upwards.
            .offset(y: moves ? (phase == .willAppear ? MotionTransitionMetrics.rise : -MotionTransitionMetrics.rise) : 0)
            .blur(radius: moves ? MotionTransitionMetrics.blur : 0)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}
