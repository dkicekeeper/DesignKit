//
//  ParticleCreatureGesture.swift
//  DesignKit
//
//  The creature's gestures (4.10.0): one-shot movements on top of its mood. The sphere nods,
//  shakes its head, hops, shrugs, flinches or perks up; to wave or to point, about thirty of its
//  particles leave the sphere, gather into a small mitten beside it (Rayman's hands: no arm) and
//  flow back after. Like everything the creature draws, a gesture is a function of its progress,
//  0…1: the engine asks for the frame of the moment and draws the sphere through it.
//

import SwiftUI

/// A one-shot movement of `ParticleCreature` (4.10.0). Play it with
/// `.creatureGesture(_:trigger:)`; the creature goes back to its mood after.
public enum CreatureGesture: Hashable, Sendable {
    /// Two nods: yes, done.
    case nod
    /// The head shakes twice, the eyes leading: no, not found.
    case shake
    /// A hop with a squash on landing: glad, look.
    case hop
    /// It squashes down and looks up: I don't know.
    case shrug
    /// A quick flinch and a blink: something went wrong.
    case flinch
    /// It stretches up with wide eyes: something new.
    case perk
    /// A hand of particles waves three times beside it: hello, goodbye. A hop in `.compact`.
    case wave
    /// A hand of particles points that way and holds, the eyes looking there too: a hint at a
    /// button. A perk in `.compact`.
    case point(Direction)

    /// Where `.point` points, in the layout's direction.
    public enum Direction: Hashable, Sendable {
        case leading, trailing, up, down
    }

    /// How long it lasts, in seconds.
    var duration: Double {
        switch self {
        case .nod, .shake: 0.9
        case .hop: 0.85
        case .shrug: 1.1
        case .flinch: 0.55
        case .perk: 0.7
        case .wave: 1.8
        case .point: 2.0
        }
    }

    /// The compact sphere has no room for a hand.
    func shown(in style: ParticleCreature.Style) -> CreatureGesture {
        guard style == .compact else { return self }
        switch self {
        case .wave: return .hop
        case .point: return .perk
        default: return self
        }
    }
}

public extension View {
    /// Plays `gesture` on the `ParticleCreature` inside this view each time `trigger` changes
    /// (4.10.0), as `sensoryFeedback(_:trigger:)` does. Nothing plays when the view appears,
    /// under Reduce Motion or with `.designKitMotion(false)`.
    ///
    /// ```swift
    /// ParticleCreature(mood: .happy, speech: CreatureSpeech("Hi!"))
    ///     .creatureGesture(.wave, trigger: greetedAt)
    /// ```
    func creatureGesture(_ gesture: CreatureGesture, trigger: some Hashable) -> some View {
        environment(\.creatureGestureRequest, CreatureGestureRequest(gesture: gesture, trigger: AnyHashable(trigger)))
    }

    /// Holds `gesture` at `progress` (0…1) in the creature's still frame: a poster, a preview, a
    /// snapshot. A moving creature ignores it.
    func creatureGestureFrame(_ gesture: CreatureGesture, progress: Double) -> some View {
        environment(\.creatureGestureFrame, CreatureGestureFrame(gesture: gesture, progress: min(max(progress, 0), 1)))
    }
}

struct CreatureGestureRequest: Equatable {
    let gesture: CreatureGesture
    let trigger: AnyHashable
}

struct CreatureGestureFrame: Equatable {
    let gesture: CreatureGesture
    let progress: Double
}

extension EnvironmentValues {
    @Entry var creatureGestureRequest: CreatureGestureRequest? = nil
    @Entry var creatureGestureFrame: CreatureGestureFrame? = nil
}

// MARK: - Motion

/// What a gesture does to the creature at one moment. Offsets and the hand's place are in
/// sphere radii from the sphere's centre; the sphere scales and turns round its bottom.
struct CreatureMotion {
    var dx = 0.0
    var dy = 0.0
    var sx = 1.0
    var sy = 1.0
    var tilt = 0.0
    /// 0 on the ground … 1 at the top of a hop: the shadow shrinks.
    var lift = 0.0
    /// Where the eyes look (-1…1), and how much that wins over their own gaze.
    var gazeX = 0.0
    var gazeY = 0.0
    var gazeWeight = 0.0
    var eyeScale = 1.0
    /// 0 open … 1 shut.
    var blink = 0.0
    var hand: CreatureHand?

    static let none = CreatureMotion()

    var movesSphere: Bool { dx != 0 || dy != 0 || sx != 1 || sy != 1 || tilt != 0 }

    /// The motion of `gesture` at `progress` (0…1). `isRTL` flips leading and trailing.
    static func of(_ gesture: CreatureGesture, progress p: Double, isRTL: Bool) -> CreatureMotion {
        var m = CreatureMotion()
        let p = min(max(p, 0), 1)
        let trailing: Double = isRTL ? -1 : 1
        switch gesture {
        case .nod:
            // Two dips, the eyes glancing down with them.
            let dip = pow(sin(2 * .pi * p), 2)
            m.dy = 0.08 * dip
            m.sy = 1 - 0.03 * dip
            m.gazeY = 0.6
            m.gazeWeight = dip
        case .shake:
            let swing = sin(4 * .pi * p) * sin(.pi * p)
            m.dx = 0.07 * swing
            m.tilt = 0.05 * swing
            m.gazeX = swing > 0 ? 0.8 : -0.8
            m.gazeWeight = abs(swing)
        case .hop:
            if p < 0.18 {
                let crouch = sin(.pi * p / 0.18)
                m.sy = 1 - 0.1 * crouch
                m.sx = 1 + 0.06 * crouch
            } else if p < 0.7 {
                let air = sin(.pi * (p - 0.18) / 0.52)
                m.dy = -0.38 * air
                m.sy = 1 + 0.05 * air
                m.sx = 1 - 0.03 * air
                m.lift = air
            } else {
                let land = (p - 0.7) / 0.3
                let squash = sin(.pi * land) * (1 - land)
                m.sy = 1 - 0.12 * squash
                m.sx = 1 + 0.08 * squash
            }
        case .shrug:
            let hold = Self.smooth(p / 0.2) * Self.smooth((1 - p) / 0.2)
            m.sy = 1 - 0.09 * hold
            m.sx = 1 + 0.05 * hold
            m.tilt = 0.05 * hold * trailing
            m.gazeX = 0.25 * trailing
            m.gazeY = -0.9
            m.gazeWeight = hold
        case .flinch:
            let jolt = p < 0.12 ? p / 0.12 : exp(-(p - 0.12) * 7)
            m.sx = 1 - 0.1 * jolt
            m.sy = 1 - 0.1 * jolt
            m.dx = 0.03 * sin(p * 60) * jolt
            m.blink = max(0, 1 - p / 0.4)
        case .perk:
            let rise = p < 0.15 ? Self.smooth(p / 0.15) : exp(-(p - 0.15) * 4)
            m.sy = 1 + 0.08 * rise
            m.sx = 1 - 0.04 * rise
            m.dy = -0.05 * rise
            m.eyeScale = 1 + 0.18 * rise
        case .wave:
            let reach = Self.smooth(p / 0.22) * Self.smooth((1 - p) / 0.2)
            let u = min(max((p - 0.18) / 0.67, 0), 1)
            let swing = 0.42 * sin(2 * .pi * 3 * u) * sin(.pi * u)
            m.hand = CreatureHand(shape: .open, x: 1.3 * trailing, y: -0.42, angle: swing * trailing,
                                  reach: reach, mirrored: isRTL)
            m.tilt = 0.04 * reach * trailing
            m.gazeX = 0.8 * trailing
            m.gazeY = -0.4
            m.gazeWeight = reach
        case .point(let direction):
            let reach = Self.smooth(p / 0.2) * Self.smooth((1 - p) / 0.18)
            let u = min(max((p - 0.2) / 0.62, 0), 1)
            let poke = 0.06 * sin(2 * .pi * 2 * u) * sin(.pi * u)
            var vx = 0.0
            var vy = 0.0
            switch direction {
            case .trailing: vx = trailing
            case .leading: vx = -trailing
            case .up: vy = -1
            case .down: vy = 1
            }
            // Close to the rim (the fist overlaps it a little), so the finger stays inside the
            // creature's square: it has less room above the sphere than beside or below it.
            let distance = (direction == .up ? 1.02 : 1.15) + poke
            // The finger points along the direction; angle 0 is up.
            let angle = atan2(vx, -vy)
            m.hand = CreatureHand(shape: .pointing, x: vx * distance, y: vy * distance, angle: angle,
                                  reach: reach, mirrored: vx < 0)
            m.tilt = 0.05 * reach * vx
            m.gazeX = 0.9 * vx
            m.gazeY = 0.9 * vy
            m.gazeWeight = reach
        }
        return m
    }

    private static func smooth(_ x: Double) -> Double {
        let c = min(max(x, 0), 1)
        return c * c * (3 - 2 * c)
    }
}

// MARK: - The hand

enum CreatureHandMetrics {
    /// About this many particles leave the sphere for the hand.
    static let particles = 32
    /// The hand's fill once formed: colour on a light page, light in the dark.
    static let inkFill: Double = 0.3
    static let lightFill: Double = 0.18
}

/// A hand of particles beside the sphere: where it is, how it is turned, how far it has formed.
struct CreatureHand {
    enum Shape { case open, pointing }

    var shape: Shape
    /// Its centre, in sphere radii from the sphere's centre.
    var x: Double
    var y: Double
    /// Its turn, radians; 0 holds the fingers (or the pointing finger) up.
    var angle: Double
    /// 0 still in the sphere … 1 formed.
    var reach: Double
    /// The thumb on the other side: a hand on the left.
    var mirrored: Bool

    /// The pieces of the hand, in sphere radii round its centre, fingers up, the thumb on the left
    /// (towards the sphere when the hand is on its right).
    private var parts: [CreatureHandPart] {
        switch shape {
        case .open:
            return [
                CreatureHandPart(cx: 0, cy: 0, rx: 0.25, ry: 0.34, exponent: 2.6, turn: 0),
                CreatureHandPart(cx: -0.25, cy: 0.08, rx: 0.105, ry: 0.16, exponent: 2, turn: -0.5),
            ]
        case .pointing:
            // The index finger rises next to the thumb, as a hand points: a finger from the
            // middle of the fist reads as another gesture.
            return [
                CreatureHandPart(cx: 0, cy: 0.07, rx: 0.2, ry: 0.18, exponent: 2.6, turn: 0),
                CreatureHandPart(cx: -0.09, cy: -0.27, rx: 0.066, ry: 0.24, exponent: 2.2, turn: 0),
                CreatureHandPart(cx: -0.2, cy: 0.06, rx: 0.072, ry: 0.1, exponent: 2, turn: -0.6),
            ]
        }
    }

    /// The hand's outline as paths, one per piece, in the view's coordinates.
    func paths(center: CGPoint, radius r: Double) -> [Path] {
        parts.map { part in
            var path = Path()
            let steps = 40
            for k in 0...steps {
                let point = place(part.point(Double(k) / Double(steps) * 2 * .pi), center: center, radius: r)
                if k == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            return path
        }
    }

    /// `count` points spread along the outline (the parts of a piece inside another left out),
    /// for the particles that form the hand.
    func points(count: Int, center: CGPoint, radius r: Double) -> [CGPoint] {
        guard count > 0 else { return [] }
        let pieces = parts
        var outline: [(Double, Double)] = []
        for (index, part) in pieces.enumerated() {
            let steps = 60
            for k in 0..<steps {
                let point = part.point(Double(k) / Double(steps) * 2 * .pi)
                let covered = pieces.indices.contains { $0 != index && pieces[$0].contains(point) }
                if !covered { outline.append(point) }
            }
        }
        guard !outline.isEmpty else { return [] }
        return (0..<count).map { k in
            let point = outline[min(outline.count - 1, k * outline.count / count)]
            return place(point, center: center, radius: r)
        }
    }

    /// A point of the hand's own drawing (sphere radii, fingers up) in the view. An open hand
    /// turns at the wrist (it waves); a pointing one round its middle (it aims).
    private func place(_ point: (Double, Double), center: CGPoint, radius r: Double) -> CGPoint {
        let pivot = shape == .open ? 0.3 : 0
        let px = mirrored ? -point.0 : point.0
        let py = point.1 - pivot
        let c = cos(angle)
        let s = sin(angle)
        return CGPoint(
            x: center.x + (x + px * c - py * s) * r,
            y: center.y + (y + pivot + px * s + py * c) * r
        )
    }
}

/// A rounded piece of the hand: a superellipse, turned.
private struct CreatureHandPart {
    let cx: Double
    let cy: Double
    let rx: Double
    let ry: Double
    let exponent: Double
    let turn: Double

    func point(_ a: Double) -> (Double, Double) {
        let c = cos(a)
        let s = sin(a)
        let ex = 2 / exponent
        let lx = rx * (c < 0 ? -1 : 1) * pow(abs(c), ex)
        let ly = ry * (s < 0 ? -1 : 1) * pow(abs(s), ex)
        return (cx + lx * cos(turn) - ly * sin(turn), cy + lx * sin(turn) + ly * cos(turn))
    }

    func contains(_ point: (Double, Double)) -> Bool {
        let dx = point.0 - cx
        let dy = point.1 - cy
        let lx = dx * cos(turn) + dy * sin(turn)
        let ly = -dx * sin(turn) + dy * cos(turn)
        return pow(abs(lx / rx), exponent) + pow(abs(ly / ry), exponent) < 0.98
    }
}
