//
//  AppMotion.swift
//  DesignKit
//
//  The motion system's vocabulary (2.2.0): four springs named for what they do, the timing
//  budgets, and one switch for DesignKit's own motion. docs/motion.md has the rules.
//
//  The older tokens in AppAnimation.swift (contentSpring, gentleSpring, heroSpring, …) keep
//  working; new code picks a spring by its purpose here.
//

import SwiftUI

// MARK: - Springs by purpose

public extension AppAnimation {
    /// A direct answer to a touch: a toggle, a selection, a chip, a press. Quick, no bounce
    /// (Apple's `.snappy`, 0.25 s).
    static let snappy = Animation.snappy(duration: 0.25)

    /// Content that changes or moves: a value, a list, a card's layout. Settles without
    /// overshoot (`.smooth`, 0.35 s).
    static let smooth = Animation.smooth(duration: 0.35)

    /// A playful confirmation: an item added, a like, a step done. A small overshoot
    /// (`.bouncy`, 0.4 s).
    static let bouncy = Animation.bouncy(duration: 0.4, extraBounce: 0.05)

    /// A moment that matters: a goal reached, a hero's first appearance. A visible, springy
    /// settle (0.55 s, bounce 0.3). Rare by design.
    static let expressive = Animation.spring(duration: 0.55, bounce: 0.3)

    /// `animation`, or `nil` when motion is off: under Reduce Motion, or with
    /// `.designKitMotion(false)`. A `nil` animation makes the change instant; pair movement
    /// with an opacity change so it still reads (docs/motion.md, "Reduce Motion").
    static func motion(_ animation: Animation, reduceMotion: Bool, isEnabled: Bool = true) -> Animation? {
        (reduceMotion || !isEnabled) ? nil : animation
    }
}

// MARK: - Budgets

/// How long motion may take. Interface motion is felt more than seen: it should end before
/// the eye starts waiting.
public enum MotionBudget {
    /// A press, a toggle, a selection: the answer to a touch.
    public static let feedback: Double = 0.25
    /// Something entering the screen: a sheet's content, a card, a banner.
    public static let entrance: Double = 0.35
    /// A celebration from start to fade-out.
    public static let celebration: Double = 1.4
    /// The delay between neighbours in a staggered entrance.
    public static let stagger: Double = 0.04
    /// The longest a whole stagger may run: later items appear together.
    public static let maxStagger: Double = 0.3

    /// The delay of item `index` in a staggered entrance, capped at `maxStagger`.
    public static func staggerDelay(_ index: Int) -> Double {
        min(Double(max(0, index)) * stagger, maxStagger)
    }
}

// MARK: - DesignKit's own motion

public extension EnvironmentValues {
    /// Whether DesignKit's components play their motion: symbol effects, celebrations,
    /// shine, ambient backgrounds. `true` by default. Reduce Motion turns movement off on its
    /// own; this switch also turns it off for a subtree (snapshot tests, an app's "reduce
    /// effects" setting).
    @Entry var designKitMotion: Bool = true
}

public extension View {
    /// Turns DesignKit's motion on or off below (`EnvironmentValues.designKitMotion`).
    func designKitMotion(_ isEnabled: Bool) -> some View {
        environment(\.designKitMotion, isEnabled)
    }
}
