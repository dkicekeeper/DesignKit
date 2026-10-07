//
//  ParticleBurst.swift
//  DesignKit
//
//  One-shot bursts for moments that matter (2.2.0):
//  • .celebration(trigger:) — confetti from the view's centre: a goal reached, a debt paid
//    off, an achievement unlocked, a trip finished. With the success haptic.
//  • .sparkleBurst(trigger:) — a small ring of sparkles around a control: a like, a reaction,
//    a favourite.
//
//  Light by construction: the particles' paths are computed from the time since the burst
//  (no per-particle state, no physics engine), one Canvas draws them, and the canvas exists
//  only while the burst plays (1.4 s / 0.7 s). Nothing runs before or after. Under Reduce
//  Motion or `.designKitMotion(false)` there are no particles; the haptic stays.
//
//  Celebrate rarely: a burst that plays on every tap stops meaning anything.
//

import SwiftUI
import DesignTokens
import DesignSupport

public extension View {
    /// Confetti bursts from the view's centre each time `trigger` changes, with the success
    /// haptic. For moments that matter: a goal reached, a debt paid off, an achievement.
    ///
    /// ```swift
    /// TargetProgressCard(…)
    ///     .celebration(trigger: goal.isReached)
    /// ```
    ///
    /// - Parameter colors: The confetti's colours; the category palette by default.
    func celebration<Trigger: Equatable>(
        trigger: Trigger,
        colors: [Color]? = nil,
        playsHaptic: Bool = true
    ) -> some View {
        modifier(ParticleBurstModifier(
            style: .confetti,
            trigger: trigger,
            colors: colors ?? CategoryColors.paletteColors,
            playsHaptic: playsHaptic
        ))
    }

    /// A small ring of sparkles around the view each time `trigger` changes: a like, a
    /// reaction, a favourite. No haptic of its own (the control plays one).
    func sparkleBurst<Trigger: Equatable>(trigger: Trigger, tint: Color = AppColors.accent) -> some View {
        modifier(ParticleBurstModifier(style: .sparkles, trigger: trigger, colors: [tint], playsHaptic: false))
    }
}

// MARK: - Modifier

enum ParticleBurstStyle {
    case confetti
    case sparkles

    var duration: Double {
        switch self {
        case .confetti: MotionBudget.celebration
        case .sparkles: 0.7
        }
    }

    /// The canvas, centred on the view: room for the particles' whole flight.
    var canvasSize: CGSize {
        switch self {
        case .confetti: CGSize(width: 560, height: 640)
        case .sparkles: CGSize(width: 200, height: 200)
        }
    }

    var particleCount: Int {
        switch self {
        case .confetti: 44
        case .sparkles: 10
        }
    }
}

struct ParticleBurstModifier<Trigger: Equatable>: ViewModifier {
    let style: ParticleBurstStyle
    let trigger: Trigger
    let colors: [Color]
    let playsHaptic: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    @State private var burst: Burst?
    @State private var count = 0

    struct Burst: Equatable {
        let id: Int
        let start: Date
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                if let burst {
                    ParticleBurstCanvas(style: style, colors: colors, seed: burst.id, start: burst.start)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .onChange(of: trigger) {
                if playsHaptic { HapticManager.success() }
                guard !reduceMotion, designKitMotion else { return }
                count += 1
                let id = count
                burst = Burst(id: id, start: .now)
                Task {
                    try? await Task.sleep(for: .seconds(style.duration))
                    if burst?.id == id { burst = nil }
                }
            }
    }
}

// MARK: - Canvas

/// Draws one burst. The particles are fixed at creation (from the seed); each frame places
/// them by the time since `start`.
struct ParticleBurstCanvas: View {
    let style: ParticleBurstStyle
    let start: Date
    private let particles: [Particle]

    init(style: ParticleBurstStyle, colors: [Color], seed: Int, start: Date) {
        self.style = style
        self.start = start
        self.particles = Particle.make(style: style, colors: colors.isEmpty ? [AppColors.accent] : colors, seed: seed)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                let centre = CGPoint(x: size.width / 2, y: size.height / 2)
                for particle in particles {
                    switch style {
                    case .confetti: drawConfetti(particle, time: time, centre: centre, in: context)
                    case .sparkles: drawSparkle(particle, time: time, centre: centre, in: context)
                    }
                }
            }
        }
        .frame(width: style.canvasSize.width, height: style.canvasSize.height)
    }

    /// Thrown up in a cone, slowed by the air, pulled down, turning and flipping; fades over
    /// the last third.
    private func drawConfetti(_ p: Particle, time: Double, centre: CGPoint, in context: GraphicsContext) {
        let life = time - p.delay
        guard life > 0 else { return }
        let duration = style.duration - p.delay
        let t = min(life, duration)
        let drag = ParticleBurstMetrics.drag
        let travel = (1 - exp(-drag * t)) / drag
        let x = p.velocity.dx * travel
        let y = p.velocity.dy * travel + 0.5 * ParticleBurstMetrics.gravity * t * t
        let fade = min(1, max(0, (duration - t) / (duration * 0.35)))
        guard fade > 0 else { return }

        var c = context
        c.opacity = fade
        c.translateBy(x: centre.x + x, y: centre.y + y)
        c.rotate(by: .radians(p.spin * t))
        // A flat piece turning in the air: its width swings with the flip.
        c.scaleBy(x: max(0.15, abs(cos(p.flip * t))), y: 1)
        let rect = CGRect(x: -p.size.width / 2, y: -p.size.height / 2, width: p.size.width, height: p.size.height)
        let path = p.isRound ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 1.5)
        c.fill(path, with: .color(p.color))
    }

    /// Out from the centre with an ease-out, growing then shrinking, turning a little.
    private func drawSparkle(_ p: Particle, time: Double, centre: CGPoint, in context: GraphicsContext) {
        let life = time - p.delay
        let duration = style.duration - p.delay
        guard life > 0, life < duration else { return }
        let progress = life / duration
        let eased = 1 - pow(1 - progress, 3)
        let distance = p.reach * eased
        let scale = sin(.pi * progress)

        var c = context
        c.opacity = min(1, scale * 1.4)
        c.translateBy(x: centre.x + p.direction.dx * distance, y: centre.y + p.direction.dy * distance)
        c.rotate(by: .radians(p.spin * life))
        c.scaleBy(x: scale, y: scale)
        c.fill(Self.star(size: p.size.width), with: .color(p.color))
    }

    /// A four-point star.
    private static func star(size: CGFloat) -> Path {
        let outer = size / 2
        let inner = outer * 0.32
        var path = Path()
        for index in 0..<8 {
            let angle = Double(index) * .pi / 4 - .pi / 2
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Particles

struct Particle {
    /// Confetti: the throw (pt/s).
    var velocity = CGVector.zero
    /// Sparkles: the direction (unit) and how far it flies (pt).
    var direction = CGVector.zero
    var reach: CGFloat = 0
    var size = CGSize.zero
    var color = Color.clear
    var isRound = false
    /// Turns per second (radians).
    var spin: Double = 0
    /// How fast a piece flips (radians per second).
    var flip: Double = 0
    var delay: Double = 0

    /// The same seed gives the same burst.
    static func make(style: ParticleBurstStyle, colors: [Color], seed: Int) -> [Particle] {
        var random = SeededRandom(seed: UInt64(truncatingIfNeeded: seed) &+ 0x9E37_79B9_7F4A_7C15)
        return (0..<style.particleCount).map { index in
            var p = Particle()
            p.color = colors[index % colors.count]
            switch style {
            case .confetti:
                // A cone upwards, ±43° around straight up.
                let angle = -Double.pi / 2 + random.next(in: -0.75...0.75)
                let speed = random.next(in: 520...920)
                p.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                p.size = CGSize(width: random.next(in: 6...10), height: random.next(in: 9...15))
                p.isRound = random.next(in: 0...1) < 0.25
                p.spin = random.next(in: -7...7)
                p.flip = random.next(in: 5...11)
                p.delay = random.next(in: 0...0.08)
            case .sparkles:
                let angle = Double(index) / Double(style.particleCount) * 2 * .pi + random.next(in: -0.2...0.2)
                p.direction = CGVector(dx: cos(angle), dy: sin(angle))
                p.reach = random.next(in: 30...56)
                let side = random.next(in: 8...14)
                p.size = CGSize(width: side, height: side)
                p.spin = random.next(in: -3...3)
                p.delay = random.next(in: 0...0.06)
            }
            return p
        }
    }
}

/// A small deterministic generator (SplitMix64): bursts look random but repeat by seed.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        let unit = Double(next() >> 11) / Double(1 << 53)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }
}

enum ParticleBurstMetrics {
    /// pt/s²: lighter than real gravity, so the confetti hangs a moment at the top.
    static let gravity: Double = 560
    /// Air drag (1/s).
    static let drag: Double = 2.2
}
