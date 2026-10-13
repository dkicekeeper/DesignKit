//
//  ParticleCreature.swift
//  DesignKit
//
//  A character made of light (4.6.0): a swarm of particles in a dark glass sphere, and a face in
//  the manner of a desk robot's screen: two glowing eyes drawn as solid shapes (a rounded lens
//  with a top lid and a cheek, an arc, a chevron, a heart, a spiral) and, for some moods, a small
//  mouth (ParticleCreatureFace.swift). The swarm's moods are shapes: listening, it ripples with
//  the voice; thinking, it gathers into a small core with three rings that spin in their own
//  planes while the planes turn round the centre, like a gyroscope; answering, it pours into a
//  bar chart with the face on the tallest bar; `.glyph("₸")`, it draws a sign in a ring like a
//  coin. The face carries the rest: ^ ^ for happy, > < for a celebration, hearts, slanted lids
//  for cross, worried and sad, half-closed lids for sleepy, a wink with a tongue, a tear.
//
//  Two styles: `.hero`, the full creature with its glow, the links between the nearest
//  particles and its extras (z's, hearts, sparkles, a question mark); `.compact`, a small
//  sphere for an avatar or a tab icon, with fewer particles clipped to the glass and the chart,
//  coin and burst moods shown as happy.
//
//  Interactive (`isInteractive:`, hero): the eyes follow the finger and squint when it comes
//  close, the particles move out of its way, a tap scatters them and cheers the creature up,
//  three quick taps make it dizzy.
//
//  Light: one Canvas at 30 fps (60 while a finger is on it), positions computed from the time.
//  A change of mood carries every particle from where it was to the new shape in about 0.7 s,
//  each a little after the other, with a small overshoot. The particles are bucketed by colour
//  and depth, so a few hundred dots are a few dozen fills per frame. Under Reduce Motion,
//  `.designKitMotion(false)` or while the system saves resources it is one still frame of the
//  mood.
//
//  Tenra's assistant is the first user; which mood each of its states shows stays in the app.
//

import SwiftUI
import UIKit
import DesignTokens
import DesignSupport

/// A creature made of a swarm of light in a glass sphere, with a glowing face and moods.
///
/// ```swift
/// ParticleCreature(mood: isThinking ? .thinking : .idle)          // hero
///     .frame(width: 260, height: 260)
/// ParticleCreature(mood: .happy, style: .compact)                 // avatar, tab icon
///     .frame(width: 40, height: 40)
/// ParticleCreature(mood: .listening, level: voice.level, isInteractive: true)
/// ```
///
/// Give it a square: the hero looks right from about 160 pt, the compact style from 24 pt.
/// The hero's sphere takes about 70% of the square; the rest is room for the burst, the chart
/// and the extras. Decorative: hidden from VoiceOver, say what it is doing in text.
public struct ParticleCreature: View {
    /// What the creature feels or does.
    public enum Mood: Hashable, Sendable {
        /// At rest: the sphere breathes, the eyes glance around and blink.
        case idle
        /// Listening: the swarm ripples with the voice (`level:`), the eyes open wide and pulse.
        case listening
        /// Thinking: a small core inside three gyroscope rings, the eyes look up and aside.
        case thinking
        /// An answer is ready: the swarm pours into a bar chart.
        case answering
        /// Pleased: ^ ^ eyes and a smile, the sphere bounces.
        case happy
        /// A goal reached: the swarm bursts out and gathers back, > < eyes and an open mouth.
        case celebrating
        /// Something unexpected: round eyes and an "o", the sphere swells for a moment.
        case surprised
        /// Thanked: heart eyes, the sphere beats like a heart, hearts rise.
        case love
        /// Proud of the person: smiling eyes, a smile and sparkles.
        case proud
        /// A joke or a secret: one eye winks, a tongue out, the head tilts.
        case wink
        /// Did not understand: one lid lower, the head tilts, a question mark.
        case confused
        /// Working hard: lids slanted down to the middle, the swarm turns faster.
        case determined
        /// Concerned: lids slanted up, a small frown, amber; the sphere shrinks a little.
        case worried
        /// Sad: lids slanted up, a frown and a tear.
        case sad
        /// Late in the day: half-closed lids, slow blinks, a yawn.
        case sleepy
        /// Asleep: closed eyes, dim and slow, z's rise.
        case asleep
        /// The swarm draws `text` (one character, a currency sign) inside a ring, like a coin.
        case glyph(String)
    }

    /// How much of the creature is drawn.
    public enum Style: Hashable, Sendable {
        /// The full creature: a few hundred particles, glow, links and extras.
        case hero
        /// A small sphere for an avatar or a tab icon.
        case compact
    }

    let mood: Mood
    let style: Style
    let level: Double?
    let isInteractive: Bool

    @Environment(\.designKitMotion) private var designKitMotion
    @State private var engine = ParticleCreatureEngine()
    @State private var isTouching = false

    /// - Parameters:
    ///   - mood: What the creature shows. A change moves the swarm into the new shape.
    ///   - style: `.hero` or `.compact`.
    ///   - level: The voice level, 0…1, for `.listening`; `nil` ripples on its own.
    ///   - isInteractive: Follows and reacts to touches (hero only).
    public init(mood: Mood = .idle, style: Style = .hero, level: Double? = nil, isInteractive: Bool = false) {
        self.mood = mood
        self.style = style
        self.level = level.map { min(max($0, 0), 1) }
        self.isInteractive = isInteractive
    }

    public var body: some View {
        AmbientMotionGate { allowsAmbientMotion in
            if allowsAmbientMotion && designKitMotion {
                TimelineView(.animation(minimumInterval: isTouching
                    ? ParticleCreatureMetrics.touchFrameInterval
                    : ParticleCreatureMetrics.frameInterval)) { timeline in
                    canvas(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                canvas(time: nil)
            }
        }
        .contentShape(Rectangle())
        .gesture(touchGesture, including: isInteractive && style == .hero ? .all : .none)
        .accessibilityHidden(true)
    }

    private func canvas(time: Double?) -> some View {
        let engine = engine
        let mood = mood
        let style = style
        let level = level
        return Canvas { context, size in
            engine.render(in: &context, size: size, mood: mood, style: style, level: level, time: time)
        }
    }

    private var touchGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                engine.pointer = value.location
                if !isTouching { isTouching = true }
            }
            .onEnded { value in
                engine.pointer = nil
                isTouching = false
                let moved = hypot(value.translation.width, value.translation.height)
                if moved < ParticleCreatureMetrics.tapSlop {
                    engine.poke(at: value.location, date: Date())
                    HapticManager.play(.tap)
                }
            }
    }
}

enum ParticleCreatureMetrics {
    /// Ambient motion: 30 fps (docs/motion.md §9).
    static let frameInterval: Double = 1.0 / 30
    /// While a finger is on it the creature follows the finger: display rate.
    static let touchFrameInterval: Double = 1.0 / 60
    /// A touch that moved less than this is a tap.
    static let tapSlop: Double = 10
    /// How long a change of mood carries the particles, and how much later the last one starts.
    static let transition: Double = 0.5
    static let stagger: Double = 0.2
    /// How long a change of face takes: lids slide, an eye closes and opens in a new form.
    static let faceTransition: Double = 0.32
}

// MARK: - Engine

/// Builds the swarm and draws one frame of it. Positions come from the time; the only state is
/// what a change needs: the mood, when it began, where the particles were then, the last touch.
final class ParticleCreatureEngine {
    typealias RGB = SIMD3<Double>

    private struct Particle {
        let index: Int
        let tone: Int
        let ux: Double, uy: Double, uz: Double
        let theta: Double
        let phase: Double
        /// 0…1: when the particle starts moving in a change of mood.
        let delay: Double
    }

    /// The finger, in the view's coordinates; set by the gesture.
    var pointer: CGPoint?

    private var particles: [Particle] = []
    private var builtStyle: ParticleCreature.Style?
    private var builtCount = 0

    private var origin: Double?
    private var requested: ParticleCreature.Mood = .idle
    private var pose: CreaturePose = .idle
    private var poseAt: Double = 0
    private var started = false
    private var blending = false
    private var glyphText = ""
    private var glyphPoints: [CGPoint] = [.zero]

    private var fromParts: [CGPoint] = []
    private var fromDepth: [Double] = []
    private var fromFace: CreatureFace?
    private var fromPalette: [RGB] = CreaturePalette.idle
    private var fromShell: Double = 1
    private var lastParts: [CGPoint] = []
    private var lastDepth: [Double] = []
    private var lastFace: CreatureFace?
    private var lastPalette: [RGB] = CreaturePalette.idle
    private var lastShell: Double = 1

    private var pokeAt: Double = -100
    private var pokePoint: CGPoint = .zero
    private var pokes: [Double] = []
    private var dizzyUntil: Double = -1

    // MARK: Events

    func poke(at point: CGPoint, date: Date) {
        guard let origin else { return }
        let t = date.timeIntervalSinceReferenceDate - origin
        pokeAt = t
        pokePoint = point
        pokes = pokes.filter { t - $0 < 2 } + [t]
        if pokes.count >= 3 {
            dizzyUntil = t + 2.4
            pokes = []
        }
    }

    // MARK: Frame

    func render(
        in context: inout GraphicsContext,
        size: CGSize,
        mood: ParticleCreature.Mood,
        style: ParticleCreature.Style,
        level: Double?,
        time: Double?
    ) {
        let geo = Geometry(size: size, style: style)
        guard geo.radius > 1 else { return }
        let animated = time != nil
        if let time, origin == nil { origin = time }
        let t = time.map { $0 - (origin ?? $0) } ?? 0
        build(style: style, radius: geo.radius)

        let mapped = Self.map(mood, style: style)
        var forced = false
        if mapped != requested {
            requested = mapped
            if case .glyph(let text) = mapped, text != glyphText {
                glyphText = text
                glyphPoints = GlyphSampler.points(for: text)
                forced = true
            }
        }
        let shown = animated ? effectivePose(at: t) : CreaturePose(mapped)
        if shown != pose || forced || !started {
            begin(shown, at: t, animated: animated && started)
        }
        started = true
        // A still frame shows the mood settled: bursts over, swells gone.
        let mt = animated ? t - poseAt : 10
        let cy = centerY(geo, t: t, mt: mt)
        let paletteMix = blending ? smoothStep(mt / 0.9) : 1
        let palette = (0..<4).map { fromPalette[$0] + (CreaturePalette.of(pose)[$0] - fromPalette[$0]) * paletteMix }
        let shellTarget: Double = pose == .answering ? 0 : 1
        let shell = blending ? fromShell + (shellTarget - fromShell) * smoothStep(mt / 0.6) : shellTarget
        let gaze = animated ? gazeDirection(geo, t: t) : (x: 0, y: 0)

        var parts = [CGPoint](repeating: .zero, count: particles.count)
        var depth = [Double](repeating: 0.5, count: particles.count)
        for n in particles.indices {
            var (point, z) = target(particles[n], geo, t: t, mt: mt, cy: cy, level: level)
            if blending, n < fromParts.count {
                let e = Self.carry(mt - particles[n].delay * ParticleCreatureMetrics.stagger)
                point = blend(fromParts[n], point, e)
                z = fromDepth[n] + (z - fromDepth[n]) * e
            }
            if style == .hero && animated { point = displaced(point, geo, t: t) }
            parts[n] = point
            depth[n] = z
        }

        var faceTarget = CreatureFace.of(pose)
        faceTarget.anchor = faceAnchor(geo, cy: cy)
        var face = faceTarget
        if let fromFace, animated {
            face = CreatureFace.blend(fromFace, faceTarget, Self.carryFace(mt))
            if mt > ParticleCreatureMetrics.faceTransition + 0.2 { self.fromFace = nil }
        }
        lastFace = face
        let shownFace = animated ? living(face, geo, t: t, gaze: gaze, level: level) : face
        var tear: CGPoint?
        if pose == .sad && animated && style == .hero {
            let progress = (t * 0.55).truncatingRemainder(dividingBy: 1)
            let eye = shownFace.left
            tear = CGPoint(
                x: shownFace.anchor.x + eye.x * geo.radius,
                y: shownFace.anchor.y + (eye.y + eye.height / 2) * geo.radius + progress * geo.radius * 0.45
            )
        }

        if blending && mt > ParticleCreatureMetrics.transition + ParticleCreatureMetrics.stagger + 0.3 { blending = false }
        lastParts = parts
        lastDepth = depth
        lastPalette = palette
        lastShell = shell

        draw(in: &context, geo: geo, style: style, t: t, cy: cy, palette: palette, shell: shell,
             parts: parts, depth: depth, face: shownFace, tear: tear)
    }

    // MARK: Building

    private func build(style: ParticleCreature.Style, radius: Double) {
        let count: Int = switch style {
        case .hero: min(max(Int(radius * 3.4), 150), 400)
        case .compact: 90
        }
        guard style != builtStyle || count != builtCount else { return }
        builtStyle = style
        builtCount = count

        let golden = Double.pi * (3 - 5.0.squareRoot())
        particles = (0..<count).map { i in
            let y = 1 - Double(i) / Double(count - 1) * 2
            let r = max(0, 1 - y * y).squareRoot()
            let theta = Double(i) * golden
            return Particle(
                index: i,
                tone: i % 4,
                ux: cos(theta) * r, uy: y, uz: sin(theta) * r,
                theta: theta,
                phase: Double((i * 9301 + 49297) % 233280) / 233280,
                delay: Double((i * 37) % 50) / 50
            )
        }
        lastParts = []
        lastDepth = []
        blending = false
    }

    private func begin(_ next: CreaturePose, at t: Double, animated: Bool) {
        fromFace = animated ? lastFace : nil
        if animated && lastParts.count == particles.count {
            fromParts = lastParts
            fromDepth = lastDepth
            fromPalette = lastPalette
            fromShell = lastShell
            blending = true
        } else {
            fromPalette = CreaturePalette.of(next)
            fromShell = next == .answering ? 0 : 1
            blending = false
        }
        pose = next
        poseAt = t
    }

    /// The compact sphere has no room for the chart, the coin or the burst.
    private static func map(_ mood: ParticleCreature.Mood, style: ParticleCreature.Style) -> ParticleCreature.Mood {
        guard style == .compact else { return mood }
        switch mood {
        case .answering, .celebrating, .glyph: return .happy
        default: return mood
        }
    }

    private func effectivePose(at t: Double) -> CreaturePose {
        let base = CreaturePose(requested)
        if t < dizzyUntil { return .dizzy }
        let cheerable: [CreaturePose] = [.idle, .listening, .asleep, .sleepy, .sad, .worried]
        if t - pokeAt < 1.3 && cheerable.contains(base) { return .happy }
        return base
    }

    // MARK: Motion

    /// A change of mood: 0 → 1 over `transition`, with a small overshoot.
    private static func carry(_ elapsed: Double) -> Double {
        let x = min(max(elapsed / ParticleCreatureMetrics.transition, 0), 1)
        let s = 1.2
        let m = x - 1
        return 1 + (s + 1) * m * m * m + s * m * m
    }

    private func tilt(_ t: Double) -> Double {
        switch pose {
        case .confused: 0.13 * sin(t * 1.8)
        case .wink: 0.09
        case .dizzy: 0.15 * sin(t * 5)
        default: 0
        }
    }

    private func centerY(_ geo: Geometry, t: Double, mt: Double) -> Double {
        let r = geo.radius
        var cy = geo.restY
        switch pose {
        case .happy: cy -= abs(sin(t * 4.2)) * r * 0.14
        case .celebrating where mt >= 0.5: cy -= abs(sin(t * 4.2)) * r * 0.14
        case .proud: cy -= abs(sin(t * 2.4)) * r * 0.05
        case .worried: cy += r * 0.08 + sin(t * 1.2) * r * 0.03
        case .sad: cy += r * 0.08
        case .sleepy: cy += r * 0.03
        case .surprised: cy -= r * 0.06 * exp(-mt * 3)
        default: break
        }
        return cy
    }

    /// Saccades: quick jumps between resting points, sometimes back to the centre. The finger
    /// wins when there is one.
    private func gazeDirection(_ geo: Geometry, t: Double) -> (x: Double, y: Double) {
        if let pointer {
            return (clampValue((pointer.x - geo.cx) / (geo.radius * 1.4), -1, 1),
                    clampValue((pointer.y - geo.restY) / (geo.radius * 1.4), -1, 1))
        }
        let period = 1.7
        let k = (t / period).rounded(.down)
        let now = Self.saccade(k)
        let before = Self.saccade(k - 1)
        let s = smoothStep((t - k * period) / 0.14)
        return (before.x + (now.x - before.x) * s, before.y + (now.y - before.y) * s)
    }

    private static func saccade(_ k: Double) -> (x: Double, y: Double) {
        let a = fraction(sin(k * 91.7 + 3.1) * 43758.5453)
        let b = fraction(sin(k * 57.3 + 1.7) * 24634.6345)
        return a < 0.25 ? (0, 0) : ((a - 0.5) * 1.5, (b - 0.5) * 0.9)
    }

    private struct Bars {
        let x0: Double
        let width: Double
        let gap: Double
        let base: Double
        static let values: [Double] = [0.38, 0.58, 0.34, 0.74, 0.5, 0.95]
    }

    private func bars(_ geo: Geometry) -> Bars {
        let span = min(geo.width * 0.8, geo.radius * 3.52)
        let count = Double(Bars.values.count)
        let width = span / count * 0.62
        return Bars(x0: geo.cx - span / 2, width: width, gap: (span - count * width) / (count - 1), base: geo.restY + geo.radius * 1.02)
    }

    private static let ringRadius: [Double] = [0.66, 0.88, 1.06]
    private static let ringTilt: [Double] = [1.05, 0.55, 1.35]
    private static let ringSpin: [Double] = [1.6, -1.25, 1.0]
    private static let ringPrecession: [Double] = [0.55, 0.8, -0.45]

    private func target(_ p: Particle, _ geo: Geometry, t: Double, mt: Double, cy: Double, level: Double?) -> (CGPoint, Double) {
        let r0 = geo.radius
        let cx = geo.cx
        switch pose {
        case .thinking:
            if p.index % 5 == 0 {
                let a = t * 2.2 + p.theta
                let x = p.ux * cos(a) + p.uz * sin(a)
                let z = -p.ux * sin(a) + p.uz * cos(a)
                return (CGPoint(x: cx + x * r0 * 0.28, y: cy + p.uy * r0 * 0.28), (z + 1) / 2)
            }
            // Gyroscope: each ring spins in its own plane and the plane turns round the centre.
            let ring = p.index % 3
            let rr = r0 * Self.ringRadius[ring] * (1 + (p.phase - 0.5) * 0.06)
            let tiltAngle = Self.ringTilt[ring]
            let spin = p.theta * 3 + t * Self.ringSpin[ring]
            let precession = t * Self.ringPrecession[ring] + Double(ring) * 2.1
            let x = cos(spin) * rr
            let z = sin(spin) * rr
            let y1 = -z * sin(tiltAngle)
            let z1 = z * cos(tiltAngle)
            let x2 = x * cos(precession) + z1 * sin(precession)
            let z2 = -x * sin(precession) + z1 * cos(precession)
            let view = 0.32
            let y3 = y1 * cos(view) - z2 * sin(view)
            let z3 = y1 * sin(view) + z2 * cos(view)
            return (CGPoint(x: cx + x2, y: cy + y3), clampValue(0.5 + 0.5 * z3 / (r0 * 1.1), 0, 1))

        case .answering:
            let g = bars(geo)
            let count = Bars.values.count
            let bar = p.index % count
            let j = p.index / count
            let perBar = (particles.count + count - 1) / count
            let columns = 4
            let rows = (perBar + columns - 1) / columns
            let left = g.x0 + Double(bar) * (g.width + g.gap)
            let height = Bars.values[bar] * r0 * 1.9
            return (CGPoint(
                x: left + g.width * (Double(j % columns) + 0.5) / Double(columns),
                y: g.base - height * (Double(j / columns) + 0.5) / Double(rows)
            ), 0.55 + 0.45 * Bars.values[bar])

        case .glyph:
            let wobble = cos(0.5 * sin(t * 2.2))
            let ringCount = Int(Double(particles.count) * 0.38)
            let x: Double
            let y: Double
            if p.index < ringCount {
                let a = Double(p.index) / Double(ringCount) * 2 * .pi + t * 0.3
                let rr = r0 * (p.index % 2 == 1 ? 0.96 : 0.86)
                x = cos(a) * rr
                y = sin(a) * rr
            } else {
                // The golden-ratio sequence spreads the particles evenly over the sign's points
                // (a stride through the scan order lined them up in stripes).
                let step = fraction(Double(p.index - ringCount) * 0.618_033_988_749_895)
                let q = glyphPoints[min(glyphPoints.count - 1, Int(step * Double(glyphPoints.count)))]
                x = q.x * r0 * 1.2
                y = q.y * r0 * 1.2 + r0 * 0.1
            }
            return (CGPoint(x: cx + x * wobble, y: cy + y), 0.75 + 0.25 * sin(p.phase * 2 * .pi + t))

        case .celebrating where mt < 0.5:
            let e = 1 - pow(1 - mt / 0.5, 3)
            let length = max(hypot(p.ux, p.uy), 0.0001)
            let d = r0 * (1 + 1.5 * e) * (0.8 + 0.4 * p.phase)
            return (CGPoint(x: cx + p.ux / length * d, y: cy + p.uy / length * d), (p.uz + 1) / 2)

        default:
            return sphere(p, geo, t: t, mt: mt, cy: cy, level: level)
        }
    }

    private func sphere(_ p: Particle, _ geo: Geometry, t: Double, mt: Double, cy: Double, level: Double?) -> (CGPoint, Double) {
        let r0 = geo.radius
        let spin: Double = switch pose {
        case .listening: 0.6
        case .asleep: 0.12
        case .sleepy, .sad: 0.15
        case .determined: 0.8
        case .confused: 0.25
        case .dizzy: 1.2
        default: 0.35
        }
        let a = t * spin
        let lean = 0.25 * sin(t * 0.3)
        let x = p.ux * cos(a) + p.uz * sin(a)
        let z0 = -p.ux * sin(a) + p.uz * cos(a)
        let y = p.uy * cos(lean) - z0 * sin(lean)
        let z = p.uy * sin(lean) + z0 * cos(lean)
        var r = r0 * (0.93 + 0.07 * sin(t * 1.3 + p.phase * 2 * .pi))
        switch pose {
        case .listening:
            let voice = level.map { 0.2 + 0.8 * $0 } ?? (0.45 + 0.55 * abs(sin(t * 2.7) * sin(t * 1.3 + 1)))
            r = r0 * (1 + 0.16 * voice * sin(p.uy * 10 - t * 8))
        case .worried:
            r = r * 0.84 + (fraction(sin(t * 37 + p.phase * 113) * 4375.85) - 0.5) * r0 * 0.02
        case .asleep:
            r *= 0.9
        case .surprised:
            r *= 1 + 0.14 * exp(-mt * 4)
        case .love:
            let beat = pow(max(0, sin(t * 7)), 8) + 0.6 * pow(max(0, sin(t * 7 - 0.9)), 8)
            r *= 1 + 0.06 * beat
        case .proud:
            r *= 1.04
        case .sad, .determined:
            r *= 0.92
        default:
            break
        }
        var sx = 1.0
        var sy = 1.0
        switch pose {
        case .happy, .celebrating:
            sx = 1 + 0.06 * cos(t * 8.4)
            sy = 1 / sx
        case .sad:
            sy = 0.9
        case .sleepy:
            let yawn = pow(max(0, sin(t * 1.05)), 12)
            sy = 1 + 0.09 * yawn
            sx = 1 - 0.03 * yawn
        default:
            break
        }
        var px = x * r * sx
        var py = y * r * sy
        let angle = tilt(t)
        if angle != 0 {
            (px, py) = (px * cos(angle) - py * sin(angle), px * sin(angle) + py * cos(angle))
        }
        let wobble = pose == .dizzy ? (sin(t * 6) * r0 * 0.05, cos(t * 6) * r0 * 0.03) : (0.0, 0.0)
        return (CGPoint(x: geo.cx + px + wobble.0, y: cy + py + wobble.1), (z + 1) / 2)
    }

    /// The finger pushes particles aside; a tap scatters them and they spring back.
    private func displaced(_ point: CGPoint, _ geo: Geometry, t: Double) -> CGPoint {
        var x = point.x
        var y = point.y
        if let pointer {
            let dx = x - pointer.x
            let dy = y - pointer.y
            let d = hypot(dx, dy)
            let reach = geo.radius * 0.5
            if d < reach && d > 0.01 {
                let push = (1 - d / reach) * geo.radius * 0.12
                x += dx / d * push
                y += dy / d * push
            }
        }
        let since = t - pokeAt
        if since >= 0 && since < 1.2 {
            let dx = point.x - pokePoint.x
            let dy = point.y - pokePoint.y
            let d = hypot(dx, dy) + 1
            let strength = geo.radius * 0.4 * exp(-d / (geo.radius * 0.6))
            let tau = 0.12
            let kick = (since / tau) * exp(1 - since / tau)
            x += dx / d * strength * kick
            y += dy / d * strength * kick
        }
        return CGPoint(x: x, y: y)
    }

    // MARK: Face

    /// A change of face: quicker than the swarm, with a small overshoot.
    private static func carryFace(_ elapsed: Double) -> Double {
        let x = min(max(elapsed / ParticleCreatureMetrics.faceTransition, 0), 1)
        let s = 1.4
        let m = x - 1
        return 1 + (s + 1) * m * m * m + s * m * m
    }

    /// Where the face sits: on the sphere, over the chart's tallest bar, or over the coin.
    private func faceAnchor(_ geo: Geometry, cy: Double) -> CGPoint {
        let r0 = geo.radius
        switch pose {
        case .answering:
            let g = bars(geo)
            let last = Bars.values.count - 1
            let left = g.x0 + Double(last) * (g.width + g.gap)
            return CGPoint(x: left + g.width / 2, y: g.base - Bars.values[last] * r0 * 1.9 - r0 * 0.15)
        case .glyph:
            return CGPoint(x: geo.cx, y: cy - r0 * 0.55)
        default:
            return CGPoint(x: geo.cx, y: cy - r0 * 0.04)
        }
    }

    /// What time adds to a face: the gaze, blinks, a squint at the finger, the voice, the
    /// heartbeat, a little breathing.
    private func living(_ face: CreatureFace, _ geo: Geometry, t: Double, gaze: (x: Double, y: Double), level: Double?) -> CreatureFace {
        var face = face
        var lx = gaze.x
        var ly = gaze.y
        switch pose {
        case .thinking:
            lx = 0.45 + 0.15 * sin(t * 0.9)
            ly = -0.6
        case .asleep, .dizzy, .answering, .glyph:
            lx = 0
            ly = 0
        default:
            break
        }
        // Looking aside turns the head: both eyes slide, the far one a little smaller.
        face.left.x += lx * 0.1
        face.right.x += lx * 0.1
        face.left.y += ly * 0.07
        face.right.y += ly * 0.07
        face.left.width *= 1 + 0.08 * lx
        face.left.height *= 1 + 0.05 * lx
        face.right.width *= 1 - 0.08 * lx
        face.right.height *= 1 - 0.05 * lx
        face.anchor.y += sin(t * 1.3) * geo.radius * 0.012

        let blink = blinkAmount(t)
        if blink > 0 {
            if face.left.form == .lens { face.left.height *= 1 - 0.92 * blink }
            if face.right.form == .lens { face.right.height *= 1 - 0.92 * blink }
        }
        if pose == .idle, let pointer, hypot(pointer.x - face.anchor.x, pointer.y - face.anchor.y) < geo.radius * 0.5 {
            face.left.lid = min(face.left.lid + 0.3, 0.9)
            face.right.lid = min(face.right.lid + 0.3, 0.9)
        }
        if pose == .listening {
            let voice = level ?? (0.4 + 0.4 * abs(sin(t * 2.7) * sin(t * 1.3 + 1)))
            face.left.height *= 1 + 0.1 * voice
            face.right.height *= 1 + 0.1 * voice
        }
        if pose == .love {
            let beat = 1 + 0.1 * (pow(max(0, sin(t * 7)), 8) + 0.6 * pow(max(0, sin(t * 7 - 0.9)), 8))
            face.left.width *= beat
            face.left.height *= beat
            face.right.width *= beat
            face.right.height *= beat
        }
        return face
    }

    /// 0 open … 1 closed. A blink every 4.3 s, a double one every third time; slow and long
    /// when sleepy; shut for a moment after a tap.
    private func blinkAmount(_ t: Double) -> Double {
        if t - pokeAt < 0.3 { return 1 }
        if pose == .sleepy {
            let c = t.truncatingRemainder(dividingBy: 3)
            return c < 0.5 ? sin(c / 0.5 * .pi) : 0
        }
        let c = t.truncatingRemainder(dividingBy: 4.3)
        let pulse: (Double, Double) -> Double = { start, length in
            c >= start && c < start + length ? sin((c - start) / length * .pi) : 0
        }
        let second = Int((t / 4.3).rounded(.down)) % 3 == 2 ? pulse(0.22, 0.14) : 0
        return max(pulse(0, 0.14), second)
    }

    // MARK: Drawing

    private func draw(
        in context: inout GraphicsContext,
        geo: Geometry,
        style: ParticleCreature.Style,
        t: Double,
        cy: Double,
        palette: [RGB],
        shell: Double,
        parts: [CGPoint],
        depth: [Double],
        face: CreatureFace,
        tear: CGPoint?
    ) {
        let r0 = geo.radius
        let cx = geo.cx
        let shellRadius = r0 * 1.2
        let center = CGPoint(x: cx, y: cy)
        let sphereRect = CGRect(x: cx - shellRadius, y: cy - shellRadius, width: shellRadius * 2, height: shellRadius * 2)
        let globe = Path(ellipseIn: sphereRect)
        let glass = Path(ellipseIn: sphereRect.insetBy(dx: shellRadius * 0.03, dy: shellRadius * 0.03))
        let hero = style == .hero

        // The light on the ground.
        if hero {
            let groundY = geo.restY + r0 * 1.34
            let lift = pose == .happy || pose == .celebrating ? abs(sin(t * 4.2)) : 0
            let rx = r0 * 1.25 * (1 - lift * 0.2)
            let ry = r0 * 0.17
            context.fill(
                Path(ellipseIn: CGRect(x: cx - rx, y: groundY - ry, width: rx * 2, height: ry * 2)),
                with: .radialGradient(
                    Gradient(colors: [color(palette[0], 0.16 * shell), color(palette[0], 0)]),
                    center: CGPoint(x: cx, y: groundY), startRadius: 0, endRadius: r0 * 1.25
                )
            )
        }

        // The glass, its inner glow, and the sweep of light while thinking.
        if shell > 0.02 {
            var back = context
            back.opacity = shell
            back.fill(globe, with: .radialGradient(
                Gradient(stops: [
                    .init(color: CreaturePalette.glassLight, location: 0),
                    .init(color: CreaturePalette.glassMid, location: 0.55),
                    .init(color: CreaturePalette.glassDeep, location: 1),
                ]),
                center: CGPoint(x: cx - shellRadius * 0.3, y: cy - shellRadius * 0.35),
                startRadius: shellRadius * 0.05, endRadius: shellRadius * 1.35
            ))
            back.blendMode = .plusLighter
            let pulse = 0.75 + 0.25 * sin(t * 2)
            back.fill(globe, with: .radialGradient(
                Gradient(colors: [color(palette[0], 0.17 * pulse), color(palette[0], 0)]),
                center: center, startRadius: 0, endRadius: shellRadius * 0.85
            ))
            if pose == .thinking {
                back.fill(globe, with: .conicGradient(
                    Gradient(stops: [
                        .init(color: color(CreaturePalette.sweep, 0), location: 0),
                        .init(color: color(CreaturePalette.sweepPeak, 0.12), location: 0.08),
                        .init(color: color(CreaturePalette.sweep, 0), location: 0.18),
                        .init(color: color(CreaturePalette.sweep, 0), location: 1),
                    ]),
                    center: center, angle: .radians(t * 2.5)
                ))
            }
        }

        // The swarm, bucketed by colour and depth.
        let dim: Double = pose == .asleep ? 0.45 : pose == .sleepy ? 0.7 : 1
        var swarm = context
        swarm.blendMode = .plusLighter
        if !hero { swarm.clip(to: glass) }
        let levels = 6
        var dots = [[Path]](repeating: [Path](repeating: Path(), count: levels), count: 4)
        var halos = [Path](repeating: Path(), count: 4)
        let sizeFactor = hero ? 1.0 : 1.3
        for n in parts.indices {
            let z = depth[n]
            let level = min(levels - 1, max(0, Int(z * Double(levels))))
            let zl = (Double(level) + 0.5) / Double(levels)
            let radius = (0.7 + 1.8 * zl) * geo.unit * sizeFactor
            let p = parts[n]
            let tone = particles[n].tone
            dots[tone][level].addEllipse(in: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
            if hero && z > 0.86 {
                let halo = radius * 2.6
                halos[tone].addEllipse(in: CGRect(x: p.x - halo, y: p.y - halo, width: halo * 2, height: halo * 2))
            }
        }
        for tone in 0..<4 {
            for level in 0..<levels where !dots[tone][level].isEmpty {
                let zl = (Double(level) + 0.5) / Double(levels)
                swarm.fill(dots[tone][level], with: .color(color(whiten(palette[tone], 0.15 * zl), (0.16 + 0.6 * zl) * dim)))
            }
            if !halos[tone].isEmpty {
                swarm.fill(halos[tone], with: .color(color(whiten(palette[tone], 0.14), 0.035 * dim)))
            }
        }

        // Faint links between the nearest particles on the front.
        if hero && (pose == .idle || pose == .listening || pose == .happy) {
            let front = Array(parts.indices.filter { depth[$0] > 0.82 }.prefix(90))
            let reach = r0 * 0.17
            var links = [Path](repeating: Path(), count: 3)
            for a in front.indices {
                let pa = parts[front[a]]
                for b in (a + 1)..<front.count {
                    let pb = parts[front[b]]
                    let dx = pa.x - pb.x
                    let dy = pa.y - pb.y
                    let d2 = dx * dx + dy * dy
                    guard d2 < reach * reach else { continue }
                    let strength = 1 - d2.squareRoot() / reach
                    let bucket = min(2, Int(strength * 3))
                    links[bucket].move(to: pa)
                    links[bucket].addLine(to: pb)
                }
            }
            for bucket in 0..<3 where !links[bucket].isEmpty {
                let alpha = (Double(bucket) + 0.5) / 3 * 0.11 * dim
                swarm.stroke(links[bucket], with: .color(color(palette[1], alpha)), lineWidth: 0.6 * max(geo.unit, 0.6))
            }
        }

        // The face, turned with the head.
        var faceLayer = context
        if !hero { faceLayer.clip(to: glass) }
        let lean = tilt(t)
        if lean != 0 {
            faceLayer.translateBy(x: cx, y: geo.restY)
            faceLayer.rotate(by: .radians(lean))
            faceLayer.translateBy(x: -cx, y: -geo.restY)
        }
        CreatureFaceRenderer.draw(face, in: &faceLayer, radius: r0, hero: hero, time: t)
        if let tear { CreatureFaceRenderer.tear(at: tear, radius: r0, in: &faceLayer) }

        // The front of the glass: a fresnel rim, coloured edges, highlights.
        if shell > 0.02 {
            var front = context
            front.opacity = shell
            front.fill(globe, with: .radialGradient(
                Gradient(stops: [
                    .init(color: color(CreaturePalette.rim, 0), location: 0.78),
                    .init(color: color(CreaturePalette.rim, 0.22), location: 1),
                ]),
                center: center, startRadius: 0, endRadius: shellRadius
            ))
            if hero {
                let s = geo.scale
                for edge in CreaturePalette.edges {
                    let ring = Path(ellipseIn: CGRect(
                        x: cx + edge.dx * s - (shellRadius - 0.6 * s),
                        y: cy + edge.dy * s - (shellRadius - 0.6 * s),
                        width: (shellRadius - 0.6 * s) * 2,
                        height: (shellRadius - 0.6 * s) * 2
                    ))
                    front.stroke(ring, with: .color(color(edge.color, edge.alpha)), lineWidth: max(0.5, 1.2 * s))
                }
            } else {
                front.stroke(
                    Path(ellipseIn: sphereRect.insetBy(dx: 0.3, dy: 0.3)),
                    with: .color(.white.opacity(0.45)), lineWidth: 0.6 * r0 / 15.5
                )
            }
            let hx = cx - shellRadius * 0.38
            let hy = cy - shellRadius * 0.5
            let sheen = Path(ellipseIn: CGRect(x: -shellRadius * 0.42, y: -shellRadius * 0.26, width: shellRadius * 0.84, height: shellRadius * 0.52))
                .applying(CGAffineTransform(rotationAngle: -0.55).concatenating(CGAffineTransform(translationX: hx, y: hy)))
            front.fill(sheen, with: .radialGradient(
                Gradient(colors: [.white.opacity(0.2), .white.opacity(0)]),
                center: CGPoint(x: hx, y: hy), startRadius: 0, endRadius: shellRadius * 0.42
            ))
            let glint = Path(ellipseIn: CGRect(x: -shellRadius * 0.07, y: -shellRadius * 0.035, width: shellRadius * 0.14, height: shellRadius * 0.07))
                .applying(CGAffineTransform(rotationAngle: -0.6).concatenating(
                    CGAffineTransform(translationX: cx - shellRadius * 0.48, y: cy - shellRadius * 0.58)))
            front.fill(glint, with: .color(.white.opacity(0.6)))
            var arc = Path()
            arc.addArc(center: center, radius: shellRadius * 0.9, startAngle: .radians(.pi * 0.2), endAngle: .radians(.pi * 0.8), clockwise: false)
            front.stroke(arc, with: .color(.white.opacity(0.1)), lineWidth: hero ? 3 * geo.scale : r0 / 15.5)
        }

        if hero { drawExtras(in: &context, geo: geo, t: t, cy: cy) }
    }

    private func drawExtras(in context: inout GraphicsContext, geo: Geometry, t: Double, cy: Double) {
        let s = geo.scale
        let shellRadius = geo.radius * 1.2
        let cx = geo.cx
        var extras = context
        switch pose {
        case .asleep:
            let letter = extras.resolve(Text(verbatim: "z")
                .font(.system(size: 22 * s, weight: .heavy, design: .rounded))
                .foregroundStyle(color(CreaturePalette.sleepLetter, 1)))
            for k in 0..<3 {
                let ph = (t * 0.4 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                extras.opacity = sin(ph * .pi)
                extras.draw(letter, at: CGPoint(x: cx + shellRadius * 0.72 + ph * 30 * s, y: cy - shellRadius * 0.72 - ph * 60 * s), anchor: .bottomLeading)
            }
        case .love:
            for k in 0..<3 {
                let ph = (t * 0.35 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                extras.opacity = sin(ph * .pi) * 0.85
                let heart = Self.heart(
                    at: CGPoint(x: cx + shellRadius * (0.7 + 0.15 * sin(ph * 6 + Double(k))), y: cy - shellRadius * 0.5 - ph * 90 * s),
                    scale: (0.45 + 0.15 * Double(k)) * s
                )
                extras.fill(heart, with: .color(color(CreaturePalette.heart, 1)))
            }
        case .proud:
            for (k, spot) in CreaturePalette.sparkleSpots.enumerated() {
                extras.opacity = 0.25 + 0.75 * pow(abs(sin(t * 2.2 + Double(k) * 1.7)), 3)
                let spark = Self.sparkle(at: CGPoint(x: cx + spot.x * shellRadius, y: cy + spot.y * shellRadius), radius: (7 + Double(k)) * s)
                extras.fill(spark, with: .color(color(CreaturePalette.sparkle, 1)))
            }
        case .confused:
            extras.opacity = 0.9
            let mark = extras.resolve(Text(verbatim: "?")
                .font(.system(size: 34 * s, weight: .heavy, design: .rounded))
                .foregroundStyle(color(CreaturePalette.question, 1)))
            extras.draw(mark, at: CGPoint(x: cx + shellRadius * 0.68, y: cy - shellRadius * 0.72 + sin(t * 2.4) * 6 * s), anchor: .bottomLeading)
        default:
            break
        }
    }

    private static func heart(at point: CGPoint, scale: Double) -> Path {
        var path = Path()
        for k in 0...24 {
            let a = Double(k) / 24 * 2 * .pi
            let sa = sin(a)
            let p = CGPoint(
                x: point.x + 16 * sa * sa * sa * scale,
                y: point.y - (13 * cos(a) - 5 * cos(2 * a) - 2 * cos(3 * a) - cos(4 * a)) * scale
            )
            if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    private static func sparkle(at point: CGPoint, radius: Double) -> Path {
        var path = Path()
        for k in 0...32 {
            let a = Double(k) / 32 * 2 * .pi
            let r = radius * (0.25 + 0.75 * pow(abs(cos(2 * a)), 5))
            let p = CGPoint(x: point.x + cos(a) * r, y: point.y + sin(a) * r)
            if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    private func color(_ rgb: RGB, _ alpha: Double) -> Color {
        Color(.sRGB, red: rgb.x / 255, green: rgb.y / 255, blue: rgb.z / 255, opacity: alpha)
    }

    private func whiten(_ rgb: RGB, _ amount: Double) -> RGB {
        rgb + (RGB(repeating: 255) - rgb) * amount
    }
}

// MARK: - Geometry

private struct Geometry {
    let width: Double
    let height: Double
    let radius: Double
    let cx: Double
    /// The sphere's centre at rest; some moods bounce or sink from it.
    let restY: Double
    /// Particle and eye sizes.
    let unit: Double

    init(size: CGSize, style: ParticleCreature.Style) {
        width = size.width
        height = size.height
        let side = min(width, height)
        cx = width / 2
        switch style {
        case .hero:
            radius = side * 0.28
            restY = height * 0.47
            unit = radius / 105
        case .compact:
            radius = side * 0.337
            restY = height / 2
            unit = radius / 40
        }
    }

    /// The board's offsets and sizes were drawn for a radius of 150.
    var scale: Double { radius / 150 }
}

// MARK: - Poses, eyes, colours

/// The mood on screen: a requested mood, or a short reaction to a touch.
enum CreaturePose: Equatable {
    case idle, listening, thinking, answering, glyph, celebrating, happy, surprised, love, proud
    case wink, confused, determined, worried, sad, sleepy, asleep, dizzy

    init(_ mood: ParticleCreature.Mood) {
        switch mood {
        case .idle: self = .idle
        case .listening: self = .listening
        case .thinking: self = .thinking
        case .answering: self = .answering
        case .happy: self = .happy
        case .celebrating: self = .celebrating
        case .surprised: self = .surprised
        case .love: self = .love
        case .proud: self = .proud
        case .wink: self = .wink
        case .confused: self = .confused
        case .determined: self = .determined
        case .worried: self = .worried
        case .sad: self = .sad
        case .sleepy: self = .sleepy
        case .asleep: self = .asleep
        case .glyph: self = .glyph
        }
    }
}

/// The creature's own colours: four tones per pose for the swarm, and the glass. Its look is
/// its identity, so these are fixed rather than taken from the accent.
private enum CreaturePalette {
    typealias RGB = SIMD3<Double>

    static let idle: [RGB] = [[124, 108, 255], [64, 214, 255], [255, 112, 190], [176, 160, 255]]
    static let listening: [RGB] = [[96, 150, 255], [64, 228, 255], [150, 124, 255], [205, 196, 255]]
    static let thinking: [RGB] = [[124, 108, 255], [70, 200, 255], [230, 110, 220], [176, 160, 255]]
    static let answering: [RGB] = [[124, 108, 255], [150, 140, 255], [106, 92, 255], [176, 170, 255]]
    static let happy: [RGB] = [[46, 214, 150], [255, 214, 90], [90, 236, 180], [60, 200, 230]]
    static let coin: [RGB] = [[255, 212, 94], [255, 188, 58], [255, 236, 160], [240, 168, 40]]
    static let worried: [RGB] = [[245, 158, 40], [255, 186, 80], [255, 138, 70], [255, 214, 130]]
    static let asleep: [RGB] = [[120, 116, 190], [100, 130, 200], [150, 140, 210], [90, 100, 170]]
    static let surprised: [RGB] = [[90, 200, 255], [200, 230, 255], [130, 160, 255], [170, 240, 255]]
    static let love: [RGB] = [[255, 110, 170], [255, 160, 200], [230, 90, 150], [255, 190, 215]]
    static let proud: [RGB] = [[255, 200, 90], [176, 140, 255], [255, 226, 150], [140, 120, 255]]
    static let sad: [RGB] = [[110, 140, 210], [90, 120, 190], [140, 160, 220], [80, 110, 170]]
    static let determined: [RGB] = [[110, 90, 255], [80, 70, 220], [150, 120, 255], [60, 90, 230]]
    static let confused: [RGB] = [[150, 130, 255], [90, 200, 230], [200, 150, 255], [120, 170, 240]]
    static let sleepy: [RGB] = [[140, 130, 210], [110, 140, 210], [170, 160, 225], [100, 115, 190]]

    static func of(_ pose: CreaturePose) -> [RGB] {
        switch pose {
        case .idle, .wink, .dizzy: idle
        case .listening: listening
        case .thinking: thinking
        case .answering: answering
        case .happy, .celebrating: happy
        case .glyph: coin
        case .worried: worried
        case .asleep: asleep
        case .surprised: surprised
        case .love: love
        case .proud: proud
        case .sad: sad
        case .determined: determined
        case .confused: confused
        case .sleepy: sleepy
        }
    }

    static let glassLight = Color(.sRGB, red: 43 / 255, green: 36 / 255, blue: 102 / 255)
    static let glassMid = Color(.sRGB, red: 18 / 255, green: 15 / 255, blue: 44 / 255)
    static let glassDeep = Color(.sRGB, red: 6 / 255, green: 5 / 255, blue: 14 / 255)
    static let sweep: RGB = [120, 150, 255]
    static let sweepPeak: RGB = [130, 190, 255]
    static let rim: RGB = [176, 186, 255]
    static let sleepLetter: RGB = [186, 182, 232]
    static let heart: RGB = [255, 140, 190]
    static let sparkle: RGB = [255, 224, 140]
    static let question: RGB = [206, 198, 255]
    static let edges: [(color: RGB, alpha: Double, dx: Double, dy: Double)] = [
        ([255, 90, 140], 0.15, -0.9, 0),
        ([90, 255, 220], 0.13, 0.9, 0),
        ([150, 160, 255], 0.22, 0, 0.9),
    ]
    static let sparkleSpots: [CGPoint] = [
        CGPoint(x: -0.95, y: -0.7), CGPoint(x: 0.92, y: -0.55), CGPoint(x: -0.8, y: 0.75), CGPoint(x: 1.0, y: 0.6),
    ]
}

// MARK: - Glyph

/// The points of a character for `.glyph`, sampled once from a 160 pt rendering, as offsets
/// from the centre in units of its size.
private enum GlyphSampler {
    static func points(for text: String) -> [CGPoint] {
        let side = 160
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            let font = UIFont.systemFont(ofSize: 128, weight: .heavy)
            let string = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: UIColor.white])
            let bounds = string.size()
            string.draw(at: CGPoint(x: (Double(side) - bounds.width) / 2, y: (Double(side) - bounds.height) / 2 + 6))
        }
        guard let cgImage = image.cgImage else { return [.zero] }
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let base = buffer.baseAddress,
                  let bitmap = CGContext(
                    data: base, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else { return false }
            bitmap.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return [.zero] }
        var points: [CGPoint] = []
        for y in stride(from: 0, to: height, by: 3) {
            for x in stride(from: 0, to: width, by: 3) where pixels[(y * width + x) * 4 + 3] > 128 {
                points.append(CGPoint(
                    x: (Double(x) - Double(width) / 2) / Double(width),
                    y: (Double(y) - Double(height) / 2) / Double(height)
                ))
            }
        }
        return points.isEmpty ? [.zero] : points
    }
}

// MARK: - Helpers

private func clampValue(_ value: Double, _ low: Double, _ high: Double) -> Double {
    min(max(value, low), high)
}

private func fraction(_ value: Double) -> Double {
    value - value.rounded(.down)
}

private func smoothStep(_ x: Double) -> Double {
    let c = clampValue(x, 0, 1)
    return c * c * (3 - 2 * c)
}

private func blend(_ a: CGPoint, _ b: CGPoint, _ e: Double) -> CGPoint {
    CGPoint(x: a.x + (b.x - a.x) * e, y: a.y + (b.y - a.y) * e)
}

// MARK: - Skeleton

/// The creature's place while it loads: a grey sphere where the glass will be.
public struct ParticleCreatureSkeleton: View {
    let style: ParticleCreature.Style

    public init(style: ParticleCreature.Style = .hero) {
        self.style = style
    }

    public var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let diameter = side * (style == .hero ? 0.28 : 0.337) * 2.4
            Skeleton.circle(diameter)
                .position(x: proxy.size.width / 2, y: proxy.size.height * (style == .hero ? 0.47 : 0.5))
        }
        .skeletonLoadingLabel()
    }
}
