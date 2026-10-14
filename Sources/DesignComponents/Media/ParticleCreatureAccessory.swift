//
//  ParticleCreatureAccessory.swift
//  DesignKit
//
//  What the creature wears (4.12.0): a party hat, a crown, a winter beanie, a taqiya (the Kazakh
//  skullcap, for Nauryz), headphones, round glasses, sunglasses or a sleep mask. Drawn in its own
//  light, as the hand of a gesture is: a soft fill and a thin outline of the mood's colours, ink
//  on a light page, with dots of light along the outline. Put on, the dots leave the sphere and
//  gather into the outline, then the outline and the fill come; taken off, they scatter. A hat
//  sits on the top of the sphere and moves with it (a hop, a tilt, a squash); glasses and masks
//  sit on the eyes and follow the gaze. The compact sphere wears hats only, as a silhouette.
//

import SwiftUI

/// Something `ParticleCreature` wears (4.12.0): `ParticleCreature(accessory: .partyHat)`.
public enum CreatureAccessory: String, CaseIterable, Hashable, Sendable {
    /// A cone with stripes and a pompom, a little askew: a celebration, the New Year.
    case partyHat
    /// Five points with a gem on three: a goal reached.
    case crown
    /// A knitted cap with a turned-up band and a pompom: winter.
    case beanie
    /// A taqiya, the Kazakh skullcap, with an ornament: Nauryz.
    case taqiya
    /// A band over the head and two cups: music, listening.
    case headphones
    /// Round glasses: reading, analysing.
    case glasses
    /// Dark lenses with a glint: summer, cool.
    case sunglasses
    /// A mask over the eyes with closed eyes drawn on it: sleep.
    case sleepMask

    /// A hat sits on the head; the rest on the face.
    public var isOnHead: Bool {
        switch self {
        case .partyHat, .crown, .beanie, .taqiya, .headphones: true
        case .glasses, .sunglasses, .sleepMask: false
        }
    }
}

enum CreatureAccessoryMetrics {
    /// Putting it on: the dots gather over `wear`, the last leaving `spread` after the first;
    /// taking it off: the dots scatter over `shed`.
    static let wear: Double = 0.9
    static let spread: Double = 0.35
    static let flight: Double = 0.45
    static let shed: Double = 0.6
    /// About one dot this far apart along the outline, in the sphere's radius.
    static let dotSpacing: Double = 0.085
    /// The fill once formed (as the hand's), and the solid parts': a pompom, the gems, the cups.
    static let inkFill: Double = 0.26
    static let lightFill: Double = 0.16
    static let inkSolid: Double = 0.6
    static let lightSolid: Double = 0.42
    /// A hat's brim, in the outline's radius above the centre, and the avatar's hat's size.
    static let brim: Double = 0.86
    static let compactHat: Double = 0.8
}

/// The drawing of an accessory: polylines in its own units round its origin, y down. A hat's
/// units are the sphere's outline radius, its origin the sphere's centre; a face piece's are the
/// face's radius, its origin the face's anchor, so it follows the eyes.
struct CreatureAccessoryDrawing {
    /// Outlined, with a soft fill when closed.
    var shapes: [[CGPoint]] = []
    /// Lines with no fill.
    var lines: [[CGPoint]] = []
    /// Filled strongly: pompoms, gems, ear cups, dark lenses, the mask.
    var solids: [[CGPoint]] = []
    /// Lines drawn over the solids: the closed eyes on the mask, a glint.
    var marks: [[CGPoint]] = []

    /// The shape of `accessory`; a face piece is fitted to `face`'s eyes (in face units).
    static func of(_ accessory: CreatureAccessory, face: CreatureFace) -> CreatureAccessoryDrawing {
        var d = CreatureAccessoryDrawing()
        switch accessory {
        case .partyHat:
            // A cone askew on the top of the head, two stripes, a pompom on its tip.
            let pivot = CGPoint(x: 0, y: -0.86)
            let turn = -0.16
            let left = CGPoint(x: -0.4, y: -0.84)
            let right = CGPoint(x: 0.4, y: -0.84)
            let apex = CGPoint(x: 0.06, y: -1.3)
            var cone = [left, apex, right]
            cone += arc(center: CGPoint(x: 0, y: -0.84), rx: 0.4, ry: 0.07, from: 0, to: .pi, steps: 10)
            d.shapes = [rotate(cone, by: turn, around: pivot)]
            for s in [0.3, 0.6] {
                let a = lerp(left, apex, s)
                let b = lerp(right, apex, s - 0.08)
                d.lines.append(rotate([a, b], by: turn, around: pivot))
            }
            let tip = rotate([apex], by: turn, around: pivot)[0]
            d.solids = [circle(center: tip, radius: 0.075)]
        case .crown:
            let base = arc(center: CGPoint(x: 0, y: -0.86), rx: 0.44, ry: 0.05, from: 0, to: .pi, steps: 8)
            let top: [CGPoint] = [
                CGPoint(x: -0.44, y: -0.86), CGPoint(x: -0.46, y: -1.26), CGPoint(x: -0.23, y: -1.06),
                CGPoint(x: 0, y: -1.32), CGPoint(x: 0.23, y: -1.06), CGPoint(x: 0.46, y: -1.26),
                CGPoint(x: 0.44, y: -0.86),
            ]
            d.shapes = [top + base]
            d.lines = [[CGPoint(x: -0.44, y: -0.97), CGPoint(x: 0.44, y: -0.97)]]
            d.solids = [
                circle(center: CGPoint(x: -0.46, y: -1.26), radius: 0.045),
                circle(center: CGPoint(x: 0, y: -1.32), radius: 0.05),
                circle(center: CGPoint(x: 0.46, y: -1.26), radius: 0.045),
            ]
        case .beanie:
            var dome = arc(center: CGPoint(x: 0, y: -0.8), rx: 0.64, ry: 0.42, from: .pi, to: 2 * .pi, steps: 18)
            dome.append(CGPoint(x: 0.64, y: -0.8))
            d.shapes = [
                dome,
                roundedRect(CGRect(x: -0.7, y: -0.9, width: 1.4, height: 0.2), radius: 0.08),
            ]
            d.lines = [-0.36, 0, 0.36].map { [CGPoint(x: $0, y: -0.87), CGPoint(x: $0, y: -0.73)] }
            d.solids = [circle(center: CGPoint(x: 0, y: -1.27), radius: 0.09)]
        case .taqiya:
            var cap = [CGPoint(x: -0.5, y: -0.82), CGPoint(x: -0.47, y: -1.02)]
            cap += arc(center: CGPoint(x: 0, y: -1.02), rx: 0.47, ry: 0.1, from: .pi, to: 2 * .pi, steps: 12)
            cap += [CGPoint(x: 0.5, y: -0.82)]
            cap += arc(center: CGPoint(x: 0, y: -0.82), rx: 0.5, ry: 0.06, from: 0, to: .pi, steps: 10)
            d.shapes = [cap]
            // The ornament: a zigzag round the cap and a diamond in front.
            d.lines = [(0...8).map { k in
                CGPoint(x: -0.4 + Double(k) * 0.1, y: k.isMultiple(of: 2) ? -0.88 : -0.96)
            }]
            d.solids = [[
                CGPoint(x: 0, y: -1.1), CGPoint(x: 0.05, y: -1.04), CGPoint(x: 0, y: -0.98), CGPoint(x: -0.05, y: -1.04),
            ]]
        case .headphones:
            let outer = arc(center: .zero, rx: 1.1, ry: 1.1, from: -.pi * 0.9, to: -.pi * 0.1, steps: 24)
            let inner = arc(center: .zero, rx: 1.03, ry: 1.03, from: -.pi * 0.1, to: -.pi * 0.9, steps: 24)
            d.shapes = [outer + inner]
            d.solids = [-1.0, 1.0].map { side in
                rotate(roundedRect(CGRect(x: side - 0.12, y: -0.5, width: 0.24, height: 0.44), radius: 0.1),
                       by: 0.22 * side, around: CGPoint(x: side, y: -0.28))
            }
        case .glasses:
            let l = CGPoint(x: face.left.x, y: face.left.y)
            let r = CGPoint(x: face.right.x, y: face.right.y)
            let lens = 0.2
            d.shapes = [circle(center: l, radius: lens), circle(center: r, radius: lens)]
            d.lines = [
                arc(center: CGPoint(x: (l.x + r.x) / 2, y: (l.y + r.y) / 2 - 0.01), rx: (r.x - l.x) / 2 - lens, ry: 0.05,
                    from: .pi, to: 2 * .pi, steps: 8),
                [CGPoint(x: l.x - lens, y: l.y - 0.03), CGPoint(x: l.x - lens - 0.2, y: l.y - 0.07)],
                [CGPoint(x: r.x + lens, y: r.y - 0.03), CGPoint(x: r.x + lens + 0.2, y: r.y - 0.07)],
            ]
        case .sunglasses:
            let lenses = [face.left, face.right].map { eye -> [CGPoint] in
                let c = CGPoint(x: eye.x, y: eye.y + 0.01)
                return [
                    CGPoint(x: c.x - 0.22, y: c.y - 0.13), CGPoint(x: c.x + 0.22, y: c.y - 0.13),
                    CGPoint(x: c.x + 0.17, y: c.y + 0.11), CGPoint(x: c.x - 0.17, y: c.y + 0.11),
                ]
            }
            d.solids = lenses
            d.lines = [[lenses[0][0], lenses[1][1]]]
            d.marks = lenses.map { lens in
                [lerp(lens[0], lens[3], 0.25).offset(0.08, 0), lerp(lens[0], lens[3], 0.6).offset(0.03, 0)]
            }
        case .sleepMask:
            let y = (face.left.y + face.right.y) / 2
            let half = max(face.right.x - face.left.x, 0.3) / 2 + 0.2
            let cx = (face.left.x + face.right.x) / 2
            var mask = arc(center: CGPoint(x: cx, y: y), rx: half, ry: 0.19, from: .pi, to: 2 * .pi, steps: 16)
            mask += [CGPoint(x: cx + half * 0.55, y: y + 0.16), CGPoint(x: cx, y: y + 0.09), CGPoint(x: cx - half * 0.55, y: y + 0.16)]
            d.solids = [mask]
            d.lines = [
                [CGPoint(x: cx - half, y: y - 0.02), CGPoint(x: cx - half - 0.22, y: y - 0.08)],
                [CGPoint(x: cx + half, y: y - 0.02), CGPoint(x: cx + half + 0.22, y: y - 0.08)],
            ]
            // Closed eyes drawn on it, with lashes.
            for eye in [face.left, face.right] {
                let c = CGPoint(x: eye.x, y: y + 0.01)
                d.marks.append(arc(center: c, rx: 0.1, ry: 0.06, from: 0, to: .pi, steps: 8))
                for k in [-1.0, 0, 1] {
                    let foot = CGPoint(x: c.x + k * 0.065, y: c.y + 0.05)
                    d.marks.append([foot, foot.offset(k * 0.03, 0.05)])
                }
            }
        }
        return d
    }

    /// Points along the outlines and lines about `spacing` apart, for the dots of light.
    func dots(spacing: Double) -> [CGPoint] {
        var points: [CGPoint] = []
        for path in shapes.map({ $0 + [$0[0]] }) + lines {
            var carry = 0.0
            for (a, b) in zip(path, path.dropFirst()) {
                let length = hypot(b.x - a.x, b.y - a.y)
                var s = carry
                while s < length {
                    points.append(Self.lerp(a, b, s / length))
                    s += spacing
                }
                carry = s - length
            }
        }
        return points
    }

    // MARK: Geometry helpers

    static func lerp(_ a: CGPoint, _ b: CGPoint, _ s: Double) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * s, y: a.y + (b.y - a.y) * s)
    }

    private static func arc(center: CGPoint, rx: Double, ry: Double, from: Double, to: Double, steps: Int) -> [CGPoint] {
        (0...steps).map { k in
            let a = from + (to - from) * Double(k) / Double(steps)
            return CGPoint(x: center.x + rx * cos(a), y: center.y + ry * sin(a))
        }
    }

    private static func circle(center: CGPoint, radius: Double) -> [CGPoint] {
        Array(arc(center: center, rx: radius, ry: radius, from: 0, to: 2 * .pi, steps: 20).dropLast())
    }

    private static func roundedRect(_ rect: CGRect, radius: Double) -> [CGPoint] {
        let r = min(radius, Double(min(rect.width, rect.height)) / 2)
        let corners: [(CGPoint, Double)] = [
            (CGPoint(x: rect.maxX - r, y: rect.minY + r), -.pi / 2),
            (CGPoint(x: rect.maxX - r, y: rect.maxY - r), 0),
            (CGPoint(x: rect.minX + r, y: rect.maxY - r), .pi / 2),
            (CGPoint(x: rect.minX + r, y: rect.minY + r), .pi),
        ]
        return corners.flatMap { corner, start in
            arc(center: corner, rx: r, ry: r, from: start, to: start + .pi / 2, steps: 4)
        }
    }

    private static func rotate(_ points: [CGPoint], by angle: Double, around pivot: CGPoint) -> [CGPoint] {
        let c = cos(angle)
        let s = sin(angle)
        return points.map { p in
            let x = p.x - pivot.x
            let y = p.y - pivot.y
            return CGPoint(x: pivot.x + x * c - y * s, y: pivot.y + x * s + y * c)
        }
    }
}

private extension CGPoint {
    func offset(_ dx: Double, _ dy: Double) -> CGPoint {
        CGPoint(x: x + dx, y: y + dy)
    }
}
