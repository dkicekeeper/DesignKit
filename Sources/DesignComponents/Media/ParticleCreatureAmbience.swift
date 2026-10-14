//
//  ParticleCreatureAmbience.swift
//  DesignKit
//
//  The creature's life of its own (4.11.0): while it is idle and nothing happens it looks round,
//  stretches with its eyes shut, rocks from side to side or gives a little bounce now and then,
//  and, if asked, dozes off after a while (sleepy, then asleep) and wakes at a touch, a line or a
//  gesture; and it daydreams, thinking a picture the app gives it now and then. Off by default: a
//  creature on a screen someone reads should not move on its own.
//  Like the gestures, a fidget is a function of its progress, 0…1, drawn through the sphere.
//

import SwiftUI

/// What `ParticleCreature` does on its own while it is idle and nothing happens (4.11.0). Give
/// it with `.creatureAmbience(_:)`.
///
/// ```swift
/// ParticleCreature(mood: .idle, isInteractive: true)
///     .creatureAmbience(CreatureAmbience(dozesAfter: 40))   // fidgets, dozes after 40 s
/// ```
public struct CreatureAmbience: Hashable, Sendable {
    /// Now and then (about every 11 s, the first after 6 s of quiet) it looks round, stretches,
    /// rocks or bounces. The hero style only.
    public var fidgets: Bool
    /// Seconds of quiet after which it dozes off: sleepy, then asleep 5 s later. A touch, a
    /// line, a gesture or a new mood wakes it. `nil` never.
    public var dozesAfter: Double?
    /// SF Symbols it daydreams of, taking turns: about every 30 to 60 s while idle, with nothing
    /// said, it thinks one for a few seconds (a picture thought, hidden from VoiceOver). Give it
    /// what is on the person's mind: the next payment, a goal. Empty: no daydreams.
    public var daydreams: [String]

    public init(fidgets: Bool = true, dozesAfter: Double? = nil, daydreams: [String] = []) {
        self.fidgets = fidgets
        self.dozesAfter = dozesAfter.map { max($0, 1) }
        self.daydreams = daydreams
    }

    /// Nothing of its own: the default.
    public static let still = CreatureAmbience(fidgets: false)
    /// Fidgets, never dozes.
    public static let lively = CreatureAmbience()
}

public extension View {
    /// What the `ParticleCreature` inside this view does on its own while it is idle (4.11.0).
    /// Nothing under Reduce Motion or with `.designKitMotion(false)`.
    func creatureAmbience(_ ambience: CreatureAmbience) -> some View {
        environment(\.creatureAmbience, ambience)
    }
}

extension EnvironmentValues {
    @Entry var creatureAmbience: CreatureAmbience = .still
}

enum CreatureAmbienceMetrics {
    /// The quiet before the first fidget, and one fidget in each period after.
    static let firstFidget: Double = 6
    static let fidgetPeriod: Double = 11
    /// Sleepy for this long before it falls asleep.
    static let drowse: Double = 5
    /// A daydream comes after `daydreamEvery` plus up to `daydreamSpread` seconds, and stays this
    /// long.
    static let daydreamEvery: Double = 30
    static let daydreamSpread: Double = 30
    static let daydreamLength: Double = 3.5

    /// The wait before daydream `turn`, the same for the same turn.
    static func daydreamWait(_ turn: Int) -> Double {
        let v = sin(Double(turn) * 12.9898 + 4.7) * 43758.5453
        return daydreamEvery + daydreamSpread * (v - v.rounded(.down))
    }
}

/// A small movement of the creature's own while idle.
enum CreatureFidget: CaseIterable {
    /// The eyes go to one side, then the other, the sphere turning a little with them.
    case lookAround
    /// It stretches up with its eyes shut and settles.
    case stretch
    /// It rocks from side to side, looking up, as if humming.
    case rock
    /// Two little bounces.
    case bounce

    var duration: Double {
        switch self {
        case .lookAround: 3.2
        case .stretch: 1.8
        case .rock: 2.4
        case .bounce: 0.9
        }
    }

    /// The fidget `quiet` seconds into a quiet spell, its progress and its first side (1 right,
    /// -1 left); `nil` between fidgets. The same quiet gives the same fidget.
    static func at(quiet: Double) -> (fidget: CreatureFidget, progress: Double, side: Double)? {
        let first = CreatureAmbienceMetrics.firstFidget
        let period = CreatureAmbienceMetrics.fidgetPeriod
        guard quiet >= first else { return nil }
        let u = quiet - first
        let k = (u / period).rounded(.down)
        let pick = Self.noise(k * 12.9898 + 1.3)
        let fidget = allCases[min(allCases.count - 1, Int(pick * Double(allCases.count)))]
        let start = Self.noise(k * 78.233 + 4.1) * (period - fidget.duration - 1)
        let progress = (u - k * period - start) / fidget.duration
        guard progress >= 0, progress < 1 else { return nil }
        return (fidget, progress, Self.noise(k * 39.425 + 7.7) < 0.5 ? 1 : -1)
    }

    /// 0…1, the same for the same input.
    private static func noise(_ x: Double) -> Double {
        let v = sin(x) * 43758.5453
        return v - v.rounded(.down)
    }
}

extension CreatureMotion {
    /// The motion of a fidget at `progress` (0…1), starting to `side`.
    static func fidget(_ fidget: CreatureFidget, progress p: Double, side: Double) -> CreatureMotion {
        var m = CreatureMotion()
        let p = min(max(p, 0), 1)
        switch fidget {
        case .lookAround:
            // To one side, hold, to the other, hold, back.
            let first = ease(p / 0.12) * (1 - ease((p - 0.42) / 0.12))
            let second = ease((p - 0.42) / 0.12) * (1 - ease((p - 0.84) / 0.16))
            let look = side * (first - second)
            m.gazeX = look >= 0 ? 0.9 : -0.9
            m.gazeY = -0.15
            m.gazeWeight = abs(look)
            m.tilt = 0.035 * look
            m.dx = 0.025 * look
        case .stretch:
            let rise = ease(p / 0.4) * (1 - ease((p - 0.62) / 0.2))
            let settle = p > 0.82 ? sin(.pi * (p - 0.82) / 0.18) : 0
            m.sy = 1 + 0.1 * rise - 0.05 * settle
            m.sx = 1 - 0.05 * rise + 0.03 * settle
            m.dy = -0.05 * rise
            m.blink = ease((p - 0.12) / 0.15) * (1 - ease((p - 0.66) / 0.12))
        case .rock:
            let swing = sin(2 * .pi * 2 * p) * sin(.pi * p)
            m.tilt = 0.07 * swing * side
            m.dx = 0.02 * swing * side
            m.gazeY = -0.5
            m.gazeWeight = sin(.pi * p)
        case .bounce:
            let air = abs(sin(2 * .pi * p))
            m.dy = -0.12 * air
            m.sy = 1 + 0.03 * air
            m.sx = 1 - 0.02 * air
            m.lift = 0.4 * air
        }
        return m
    }

    private static func ease(_ x: Double) -> Double {
        let c = min(max(x, 0), 1)
        return c * c * (3 - 2 * c)
    }
}
