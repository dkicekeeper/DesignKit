//
//  ParticleCreatureFace.swift
//  DesignKit
//
//  The particle creature's face (4.6.0): two glowing eyes and, for some moods, a small mouth,
//  drawn as solid shapes in the manner of a desk robot's screen face. An eye is a rounded lens
//  with a top lid (its height and angle make it sleepy, cross or sad) and a cheek that pushes up
//  from below (smiling eyes), or one of a few forms: an arc (^), a chevron (> <), a heart, a
//  sparkle, a spiral.
//
//  A change of mood eases every number of the face to the new one (lids slide, eyes widen or
//  narrow); an eye that changes form closes and opens again in the new one. On top of that each
//  frame adds what lives in time: the gaze (the far eye a little smaller), blinks, the heartbeat
//  of heart eyes, the voice in listening eyes, the spin of a sparkle or a spiral.
//

import SwiftUI
import DesignTokens

/// One eye, in units of the sphere's radius around the face's anchor.
struct CreatureEye: Equatable {
    enum Form: Equatable { case lens, arc, chevron, heart, sparkle, spiral }

    var form: Form = .lens
    var x: Double = 0.25
    var y: Double = 0
    var width: Double = 0.26
    var height: Double = 0.30
    /// 0: square corners; 1: the short side fully round.
    var roundness: Double = 0.6
    /// The top lid: the share of the height it covers at the eye's middle.
    var lid: Double = 0
    /// The lid's slant: positive brings the inner corner down (cross), negative raises it (sad).
    var lidAngle: Double = 0
    /// A cheek pushing up from below: the share of the height it covers (smiling eyes).
    var cheek: Double = 0
    var color: SIMD3<Double> = CreatureFace.cyan
}

struct CreatureMouth: Equatable {
    enum Form: Equatable { case none, smile, frown, open, tongue }

    var form: Form = .none
    var y: Double = 0.26
    var width: Double = 0.12
    /// How far an `.open` mouth is open: its height, as a share of its width (talking, 4.10.0).
    var open: Double = 0.8
}

struct CreatureFace: Equatable {
    var anchor: CGPoint = .zero
    var left = CreatureEye(x: -0.25)
    var right = CreatureEye(x: 0.25)
    var mouth = CreatureMouth()

    static let cyan: SIMD3<Double> = [90, 215, 255]
    static let pink: SIMD3<Double> = [255, 105, 150]
    static let dimCyan: SIMD3<Double> = [70, 140, 200]
    /// The face is drawn this much larger than its numbers: big screen eyes.
    static let scale: Double = 1.3
    /// The mouth's width while the creature talks (4.10.0).
    static let talkWidth: Double = 0.1

    /// Both eyes the same, mirrored.
    private static func pair(_ eye: CreatureEye, mouth: CreatureMouth = CreatureMouth()) -> CreatureFace {
        var left = eye
        left.x = -abs(eye.x)
        var right = eye
        right.x = abs(eye.x)
        return CreatureFace(left: left, right: right, mouth: mouth)
    }

    /// The face of each pose, before time adds the gaze, blinks and beats.
    static func of(_ pose: CreaturePose) -> CreatureFace {
        switch pose {
        case .idle:
            return pair(CreatureEye())
        case .listening:
            return pair(CreatureEye(width: 0.28, height: 0.36, roundness: 0.7))
        case .thinking:
            var face = pair(CreatureEye(y: -0.06, height: 0.24, lid: 0.18, lidAngle: -0.12))
            face.right.lid = 0.38
            face.right.lidAngle = 0.18
            return face
        case .answering:
            return pair(CreatureEye(form: .arc, x: 0.08, width: 0.12, height: 0.11))
        case .glyph:
            return pair(CreatureEye(form: .arc, x: 0.2, width: 0.16, height: 0.12))
        case .happy:
            return pair(CreatureEye(form: .arc, y: -0.02, width: 0.24, height: 0.16), mouth: CreatureMouth(form: .smile))
        case .celebrating:
            return pair(CreatureEye(form: .chevron, x: 0.24, width: 0.17, height: 0.2), mouth: CreatureMouth(form: .open, width: 0.1))
        case .surprised:
            return pair(CreatureEye(y: -0.06, width: 0.27, height: 0.31, roundness: 1), mouth: CreatureMouth(form: .open, width: 0.07))
        case .love:
            return pair(CreatureEye(form: .heart, width: 0.27, height: 0.25, color: pink), mouth: CreatureMouth(form: .smile, width: 0.1))
        case .proud:
            return pair(CreatureEye(width: 0.27, height: 0.28, lid: 0.12, cheek: 0.42), mouth: CreatureMouth(form: .smile))
        case .wink:
            var face = pair(CreatureEye(), mouth: CreatureMouth(form: .tongue))
            face.left = CreatureEye(form: .arc, x: -0.25, width: 0.24, height: 0.16)
            return face
        case .confused:
            var face = pair(CreatureEye(height: 0.32))
            face.right = CreatureEye(x: 0.25, width: 0.24, height: 0.22, lid: 0.32, lidAngle: 0.35)
            return face
        case .determined:
            return pair(CreatureEye(width: 0.28, height: 0.27, roundness: 0.5, lid: 0.36, lidAngle: 0.45))
        case .worried:
            return pair(CreatureEye(y: 0.02, width: 0.24, height: 0.28, lid: 0.28, lidAngle: -0.45), mouth: CreatureMouth(form: .frown, width: 0.08))
        case .sad:
            return pair(CreatureEye(y: 0.05, width: 0.24, height: 0.26, lid: 0.34, lidAngle: -0.55), mouth: CreatureMouth(form: .frown, width: 0.1))
        case .sleepy:
            return pair(CreatureEye(y: 0.03, width: 0.28, height: 0.26, lid: 0.55))
        case .asleep:
            return pair(CreatureEye(y: 0.04, width: 0.26, height: 0.035, roundness: 1, color: dimCyan))
        case .dizzy:
            return pair(CreatureEye(form: .spiral, width: 0.24, height: 0.24), mouth: CreatureMouth(form: .open, width: 0.06))
        }
    }

    // MARK: Blending

    /// From `a` to `b` at `e` (0…1, may overshoot a little).
    static func blend(_ a: CreatureFace, _ b: CreatureFace, _ e: Double) -> CreatureFace {
        CreatureFace(
            anchor: CGPoint(x: a.anchor.x + (b.anchor.x - a.anchor.x) * e, y: a.anchor.y + (b.anchor.y - a.anchor.y) * e),
            left: blend(a.left, b.left, e),
            right: blend(a.right, b.right, e),
            mouth: blend(a.mouth, b.mouth, e)
        )
    }

    private static func blend(_ a: CreatureEye, _ b: CreatureEye, _ e: Double) -> CreatureEye {
        guard a.form == b.form else {
            // Close the old form, open the new one.
            let t = min(max(e, 0), 1)
            var eye = t < 0.5 ? a : b
            eye.height *= t < 0.5 ? 1 - t * 2 : t * 2 - 1
            eye.x = a.x + (b.x - a.x) * t
            eye.y = a.y + (b.y - a.y) * t
            return eye
        }
        var eye = b
        eye.x = mix(a.x, b.x, e)
        eye.y = mix(a.y, b.y, e)
        eye.width = mix(a.width, b.width, e)
        eye.height = max(0, mix(a.height, b.height, e))
        eye.roundness = min(max(mix(a.roundness, b.roundness, e), 0), 1)
        eye.lid = min(max(mix(a.lid, b.lid, e), 0), 0.95)
        eye.lidAngle = mix(a.lidAngle, b.lidAngle, e)
        eye.cheek = min(max(mix(a.cheek, b.cheek, e), 0), 0.95)
        eye.color = a.color + (b.color - a.color) * min(max(e, 0), 1)
        return eye
    }

    private static func blend(_ a: CreatureMouth, _ b: CreatureMouth, _ e: Double) -> CreatureMouth {
        let t = min(max(e, 0), 1)
        guard a.form == b.form else {
            var mouth = t < 0.5 ? a : b
            mouth.width *= t < 0.5 ? 1 - t * 2 : t * 2 - 1
            return mouth
        }
        var mouth = b
        mouth.y = mix(a.y, b.y, t)
        mouth.width = mix(a.width, b.width, t)
        mouth.open = mix(a.open, b.open, t)
        return mouth
    }

    private static func mix(_ a: Double, _ b: Double, _ e: Double) -> Double {
        a + (b - a) * e
    }
}

// MARK: - Drawing

enum CreatureFaceRenderer {
    /// Draws the face; `radius` is the sphere's, `spin` turns sparkles and spirals. `ink`, 0…1:
    /// how far the face is drawn for a light page (4.6.1; 1 there since 4.7.0), its colours deeper
    /// and its glow fainter by as much, so the eyes read on white.
    static func draw(
        _ face: CreatureFace,
        in context: inout GraphicsContext,
        radius: Double,
        hero: Bool,
        time: Double,
        ink: Double = 0
    ) {
        var face = face
        if ink > 0 {
            face.left.color = inked(face.left.color, ink)
            face.right.color = inked(face.right.color, ink)
        }
        let glow = 1 - CreatureInk.faceGlowCut * ink
        let glowRadius = radius * (hero ? 0.09 : 0.06)
        let r = radius * CreatureFace.scale
        for (eye, isRight) in [(face.left, false), (face.right, true)] where eye.height > 0.001 && eye.width > 0.001 {
            context.drawLayer { glowing in
                glowing.addFilter(.shadow(color: color(eye.color, 0.9 * glow), radius: glowRadius))
                drawEye(eye, isRight: isRight, anchor: face.anchor, radius: r, time: time, in: &glowing)
            }
        }
        if hero, face.mouth.form != .none, face.mouth.width > 0.001 {
            context.drawLayer { glowing in
                glowing.addFilter(.shadow(color: color(face.left.color, 0.8 * glow), radius: glowRadius * 0.7))
                drawMouth(face.mouth, anchor: face.anchor, radius: r, color: face.left.color, in: &glowing)
            }
        }
    }

    /// A colour of the face deepened as far as `amount` of `CreatureInk.faceDepth`.
    private static func inked(_ rgb: SIMD3<Double>, _ amount: Double) -> SIMD3<Double> {
        rgb * (1 - CreatureInk.faceDepth * min(max(amount, 0), 1))
    }

    private static func drawEye(_ eye: CreatureEye, isRight: Bool, anchor: CGPoint, radius r: Double, time: Double, in context: inout GraphicsContext) {
        let center = CGPoint(x: anchor.x + eye.x * r, y: anchor.y + eye.y * r)
        let w = eye.width * r
        let h = eye.height * r
        let fill = color(eye.color, 1)
        switch eye.form {
        case .lens:
            let rect = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
            let corner = eye.roundness * min(w, h) / 2
            let lens = Path(roundedRect: rect, cornerRadius: corner, style: .continuous)
            context.drawLayer { shaped in
                if eye.lid > 0.001 {
                    shaped.clip(to: lidPath(rect: rect, lid: eye.lid, angle: eye.lidAngle, isRight: isRight), options: .inverse)
                }
                if eye.cheek > 0.001 {
                    let cheekTop = rect.maxY - eye.cheek * h
                    let cheek = Path(ellipseIn: CGRect(x: center.x - w * 0.75, y: cheekTop, width: w * 1.5, height: h * 1.2))
                    shaped.clip(to: cheek, options: .inverse)
                }
                shaped.fill(lens, with: .color(fill))
            }
        case .arc:
            var arc = Path()
            arc.addArc(center: CGPoint(x: center.x, y: center.y + h * 0.45), radius: w / 2,
                       startAngle: .radians(.pi), endAngle: .radians(2 * .pi), clockwise: false)
            context.stroke(arc, with: .color(fill), style: StrokeStyle(lineWidth: max(h * 0.5, 0.5), lineCap: .round))
        case .chevron:
            // Pointing inwards: ">" on the left, "<" on the right.
            let tip = isRight ? -1.0 : 1.0
            var chevron = Path()
            chevron.move(to: CGPoint(x: center.x - tip * w / 2, y: center.y - h / 2))
            chevron.addLine(to: CGPoint(x: center.x + tip * w / 2, y: center.y))
            chevron.addLine(to: CGPoint(x: center.x - tip * w / 2, y: center.y + h / 2))
            context.stroke(chevron, with: .color(fill), style: StrokeStyle(lineWidth: max(r * 0.065, 0.5), lineCap: .round, lineJoin: .round))
        case .heart:
            context.fill(heart(center: center, width: w, height: h), with: .color(fill))
        case .sparkle:
            context.fill(sparkle(center: center, radius: w / 2, rotation: time * 0.8), with: .color(fill))
        case .spiral:
            var spiral = Path()
            let turns = 2.2
            let direction = isRight ? -1.0 : 1.0
            for k in 0...48 {
                let u = Double(k) / 48
                let a = u * turns * 2 * .pi * direction + time * 6 * direction
                let p = CGPoint(x: center.x + cos(a) * w / 2 * u, y: center.y + sin(a) * h / 2 * u)
                if k == 0 { spiral.move(to: p) } else { spiral.addLine(to: p) }
            }
            context.stroke(spiral, with: .color(fill), style: StrokeStyle(lineWidth: max(r * 0.04, 0.5), lineCap: .round))
        }
    }

    /// The region above a slanted lid line, to cut away.
    private static func lidPath(rect: CGRect, lid: Double, angle: Double, isRight: Bool) -> Path {
        let lineY = rect.minY + lid * rect.height
        // The inner corner is the one towards the middle of the face.
        let drop = tan(angle) * rect.width / 2
        let leftY = isRight ? lineY + drop : lineY - drop
        let rightY = isRight ? lineY - drop : lineY + drop
        let margin = rect.width
        var path = Path()
        path.move(to: CGPoint(x: rect.minX - margin, y: rect.minY - margin * 2))
        path.addLine(to: CGPoint(x: rect.maxX + margin, y: rect.minY - margin * 2))
        path.addLine(to: CGPoint(x: rect.maxX + margin, y: rightY + (rightY - leftY) / rect.width * margin))
        path.addLine(to: CGPoint(x: rect.minX - margin, y: leftY - (rightY - leftY) / rect.width * margin))
        path.closeSubpath()
        return path
    }

    private static func drawMouth(_ mouth: CreatureMouth, anchor: CGPoint, radius r: Double, color rgb: SIMD3<Double>, in context: inout GraphicsContext) {
        let center = CGPoint(x: anchor.x, y: anchor.y + mouth.y * r)
        let w = mouth.width * r
        let stroke = StrokeStyle(lineWidth: max(r * 0.04, 0.5), lineCap: .round)
        let fill = color(rgb, 1)
        switch mouth.form {
        case .none:
            break
        case .smile, .tongue:
            var smile = Path()
            smile.move(to: CGPoint(x: center.x - w / 2, y: center.y))
            smile.addQuadCurve(to: CGPoint(x: center.x + w / 2, y: center.y), control: CGPoint(x: center.x, y: center.y + w * 0.55))
            context.stroke(smile, with: .color(fill), style: stroke)
            if mouth.form == .tongue {
                let tongue = CGRect(x: center.x - w * 0.18, y: center.y + w * 0.12, width: w * 0.36, height: w * 0.34)
                context.fill(Path(roundedRect: tongue, cornerRadius: w * 0.17, style: .continuous), with: .color(color(CreatureFace.pink, 1)))
            }
        case .frown:
            var frown = Path()
            frown.move(to: CGPoint(x: center.x - w / 2, y: center.y + w * 0.2))
            frown.addQuadCurve(to: CGPoint(x: center.x + w / 2, y: center.y + w * 0.2), control: CGPoint(x: center.x, y: center.y - w * 0.3))
            context.stroke(frown, with: .color(fill), style: stroke)
        case .open:
            let h = max(w * mouth.open, w * 0.1)
            context.fill(Path(ellipseIn: CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)), with: .color(fill))
        }
    }

    /// A tear at `point` (under an eye, on its way down).
    /// A tear at `point`; `ink` as for the face (4.7.0), so it reads on a light page.
    static func tear(at point: CGPoint, radius: Double, in context: inout GraphicsContext, ink: Double = 0) {
        let size = radius * CreatureFace.scale * 0.055
        var drop = Path()
        drop.move(to: CGPoint(x: point.x, y: point.y - size * 1.6))
        drop.addQuadCurve(to: CGPoint(x: point.x + size, y: point.y + size * 0.2), control: CGPoint(x: point.x + size, y: point.y - size * 0.6))
        drop.addArc(center: CGPoint(x: point.x, y: point.y + size * 0.2), radius: size, startAngle: .radians(0), endAngle: .radians(.pi), clockwise: false)
        drop.addQuadCurve(to: CGPoint(x: point.x, y: point.y - size * 1.6), control: CGPoint(x: point.x - size, y: point.y - size * 0.6))
        context.drawLayer { glowing in
            glowing.addFilter(.shadow(color: color(inked([130, 200, 255], ink), 0.8 * (1 - CreatureInk.faceGlowCut * ink)), radius: size))
            glowing.fill(drop, with: .color(color(inked([150, 210, 255], ink), 0.95)))
        }
    }

    private static func heart(center: CGPoint, width: Double, height: Double) -> Path {
        var path = Path()
        for k in 0...40 {
            let a = Double(k) / 40 * 2 * .pi
            let sa = sin(a)
            let x = 16 * sa * sa * sa / 32 * width
            let y = -(13 * cos(a) - 5 * cos(2 * a) - 2 * cos(3 * a) - cos(4 * a)) / 30 * height
            let p = CGPoint(x: center.x + x, y: center.y + y + height * 0.05)
            if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    private static func sparkle(center: CGPoint, radius: Double, rotation: Double) -> Path {
        var path = Path()
        for k in 0...48 {
            let a = Double(k) / 48 * 2 * .pi
            let r = radius * (0.22 + 0.78 * pow(abs(cos(2 * a)), 6))
            let p = CGPoint(x: center.x + cos(a + rotation) * r, y: center.y + sin(a + rotation) * r)
            if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    static func color(_ rgb: SIMD3<Double>, _ alpha: Double) -> Color {
        Color(.sRGB, red: rgb.x / 255, green: rgb.y / 255, blue: rgb.z / 255, opacity: alpha)
    }
}
