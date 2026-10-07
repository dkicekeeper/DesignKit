//
//  VoiceWave.swift
//  DesignKit
//
//  The voice made visible (2.4.0): the picture by the microphone while a person speaks. Two
//  styles of the same motion, in the colours of the aurora:
//
//  • .ribbons — four translucent ribbons of light, each on its own frequency and phase. Quiet,
//    they lie in a thin breathing line; speech lifts them, each a little out of step, so the
//    sound looks alive rather than metered. (The Siri wave of iOS 7–13, lit like an aurora.)
//  • .orb — a liquid sphere of mesh-gradient colour whose rim ripples and whose glow swells
//    with the voice. (The voice orb of iOS 14+ and of voice assistants.)
//
//  Phases: `.listening` follows the level; `.thinking` (while the words are being understood)
//  draws the ribbons into a line with a light running along it, or turns the orb's colours
//  faster under a shine. When it is done, remove the view with a transition.
//
//  Light: one Canvas, paths computed from the time and the smoothed level (VoiceLevelDriver),
//  up to 60 fps only while it is on screen and motion is allowed. Under Reduce Motion or
//  `.designKitMotion(false)` it is one still frame at the given level.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A wave (or an orb) that moves with the voice.
///
/// ```swift
/// VoiceWave(level: voice.level)                                   // ribbons, listening
///     .frame(height: 120)
/// VoiceWave(level: voice.level, phase: .thinking, style: .orb)
///     .frame(width: 200, height: 200)
/// ```
///
/// Give it a size: ribbons look right about 100–160 pt tall, the orb in a square. Decorative:
/// hidden from VoiceOver; say "Listening" in the screen's own text.
public struct VoiceWave: View {
    /// How the voice is drawn.
    public enum Style: Hashable, Sendable {
        /// Ribbons of light across the width.
        case ribbons
        /// A liquid sphere in the middle.
        case orb
    }

    /// What the app is doing with the voice.
    public enum Phase: Hashable, Sendable {
        /// Recording: the wave follows the level.
        case listening
        /// Understanding what was said: the wave settles and a light runs through it.
        case thinking
    }

    let level: Double?
    let phase: Phase
    let style: Style
    let colors: [Color]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    @State private var driver = VoiceLevelDriver()

    /// - Parameters:
    ///   - level: The voice level, 0…1. `nil` breathes gently on its own.
    ///   - colors: Four colours or so; by default the accent's aurora palette.
    public init(level: Double? = nil, phase: Phase = .listening, style: Style = .ribbons, colors: [Color]? = nil) {
        self.level = level.map { min(max($0, 0), 1) }
        self.phase = phase
        self.style = style
        let given = colors ?? []
        self.colors = given.isEmpty ? Self.defaultColors : given
    }

    /// The accent and three neighbours on the colour wheel, from `AuroraBackground.palette`.
    static var defaultColors: [Color] {
        let palette = AuroraBackground.palette(around: AppColors.accent)
        return [palette[0], palette[1], palette[3], palette[5]]
    }

    public var body: some View {
        AmbientMotionGate { allowsAmbientMotion in
            if allowsAmbientMotion && designKitMotion {
                TimelineView(.animation(minimumInterval: VoiceWaveMetrics.frameInterval)) { timeline in
                    let target: Double? = phase == .thinking ? VoiceWaveMetrics.thinkingLevel : level
                    let frame = driver.advance(to: timeline.date, target: target)
                    canvas(VoiceWaveFrame(time: frame.time, level: frame.level, flow: frame.flow, phase: phase))
                }
            } else {
                let still = phase == .thinking ? VoiceWaveMetrics.thinkingLevel : (level ?? VoiceLevelDriver.restingLevel)
                canvas(VoiceWaveFrame(time: 0, level: still, flow: 0, phase: phase))
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func canvas(_ frame: VoiceWaveFrame) -> some View {
        let colors = colors
        let style = style
        return Canvas { context, size in
            switch style {
            case .ribbons: VoiceRibbons.draw(in: &context, size: size, frame: frame, colors: colors)
            case .orb: VoiceOrb.draw(in: &context, size: size, frame: frame, colors: colors)
            }
        }
    }
}

enum VoiceWaveMetrics {
    /// The wave follows a voice, like a finger: up to 60 fps while on screen.
    static let frameInterval: Double = 1.0 / 60
    /// The level the wave settles at while thinking.
    static let thinkingLevel: Double = 0.06
}

/// One frame of the wave.
struct VoiceWaveFrame {
    let time: Double
    let level: Double
    let flow: Double
    let phase: VoiceWave.Phase
}

// MARK: - Ribbons

enum VoiceRibbons {
    /// Each ribbon: how strongly it follows the voice, its frequency across the width, how fast
    /// its phase runs, and when its own swell peaks.
    private static let ribbons: [(gain: Double, frequency: Double, speed: Double, offset: Double)] = [
        (1.00, 2.2, 1.00, 0.0),
        (0.80, 3.1, 1.35, 1.7),
        (0.65, 1.6, 0.80, 3.1),
        (0.50, 4.0, 1.70, 4.6),
    ]

    static func draw(in context: inout GraphicsContext, size: CGSize, frame: VoiceWaveFrame, colors: [Color]) {
        let width = Double(size.width)
        let height = Double(size.height)
        guard width > 0, height > 0 else { return }
        let mid = height / 2
        let reach = height / 2 * 0.92
        let step = 3.0
        let across = (start: CGPoint.zero, end: CGPoint(x: width, y: 0))

        for (index, ribbon) in ribbons.enumerated() {
            let color = colors[index % colors.count]
            // Each ribbon swells on its own beat, so they never move as one.
            let swell = 0.6 + 0.4 * sin(frame.time * (1.1 + Double(index) * 0.37) + ribbon.offset)
            let amplitude = reach * (0.04 + frame.level * ribbon.gain * swell)
            let phase = frame.flow * 40 * ribbon.speed + ribbon.offset

            var top = Path()
            var bottom = [CGPoint]()
            var x = 0.0
            while x <= width {
                let u = x / width * 2 - 1                          // −1…1
                let envelope = pow(1 - u * u, 2)                   // 0 at the ends
                let y = amplitude * envelope * sin(ribbon.frequency * u * .pi + phase)
                let point = CGPoint(x: x, y: mid - y)
                if x == 0 { top.move(to: point) } else { top.addLine(to: point) }
                bottom.append(CGPoint(x: x, y: mid + y))
                x += step
            }

            var lens = top
            for point in bottom.reversed() { lens.addLine(to: point) }
            lens.closeSubpath()

            context.fill(lens, with: .linearGradient(
                Gradient(colors: [color.opacity(0), color.opacity(0.55), color.opacity(0)]),
                startPoint: across.start, endPoint: across.end
            ))
            context.stroke(top, with: .linearGradient(
                Gradient(colors: [color.opacity(0), color.opacity(0.9), color.opacity(0)]),
                startPoint: across.start, endPoint: across.end
            ), lineWidth: 1.5)
        }

        // The line the ribbons rise from; while thinking, a light runs along it.
        var line = Path()
        line.move(to: CGPoint(x: 0, y: mid))
        line.addLine(to: CGPoint(x: width, y: mid))
        if frame.phase == .thinking {
            let head = (frame.time * 0.7).truncatingRemainder(dividingBy: 1)
            let spot = Gradient(stops: [
                .init(color: .white.opacity(0.15), location: 0),
                .init(color: .white.opacity(0.15), location: max(head - 0.18, 0)),
                .init(color: .white.opacity(0.95), location: head),
                .init(color: .white.opacity(0.15), location: min(head + 0.06, 1)),
                .init(color: .white.opacity(0.15), location: 1),
            ])
            context.stroke(line, with: .linearGradient(spot, startPoint: across.start, endPoint: across.end), lineWidth: 2)
        } else {
            context.stroke(line, with: .linearGradient(
                Gradient(colors: [.white.opacity(0), .white.opacity(0.5), .white.opacity(0)]),
                startPoint: across.start, endPoint: across.end
            ), lineWidth: 1)
        }
    }
}

// MARK: - Orb

enum VoiceOrb {
    /// The rim's ripples: harmonic, share of the radius per unit of level, speed.
    private static let ripples: [(harmonic: Double, depth: Double, speed: Double)] = [
        (2, 0.05, 0.9), (3, 0.04, -1.3), (5, 0.025, 1.9),
    ]

    static func draw(in context: inout GraphicsContext, size: CGSize, frame: VoiceWaveFrame, colors: [Color]) {
        let side = Double(min(size.width, size.height))
        guard side > 0 else { return }
        let cx = Double(size.width) / 2
        let cy = Double(size.height) / 2
        let center = CGPoint(x: cx, y: cy)
        let thinking = frame.phase == .thinking
        let breathe = 0.03 * sin(frame.time * 1.3)
        let radius = side / 2 * (thinking ? 0.5 : 0.52 + 0.16 * frame.level + breathe)

        // The glow behind it swells with the voice.
        let glowRadius = radius * (1.25 + 0.35 * frame.level)
        context.fill(
            Path(ellipseIn: CGRect(x: cx - glowRadius, y: cy - glowRadius, width: glowRadius * 2, height: glowRadius * 2)),
            with: .radialGradient(
                Gradient(colors: [colors[0].opacity(0.45 * (0.5 + frame.level)), colors[0].opacity(0)]),
                center: center, startRadius: CGFloat(radius * 0.6), endRadius: CGFloat(glowRadius)
            )
        )

        // The liquid rim.
        var blob = Path()
        let points = 96
        for index in 0...points {
            let angle = Double(index) / Double(points) * 2 * .pi
            var r = 1.0
            for ripple in ripples {
                r += ripple.depth * (0.2 + frame.level * 1.6) * sin(ripple.harmonic * angle + frame.flow * 30 * ripple.speed)
            }
            let point = CGPoint(x: cx + radius * r * cos(angle), y: cy + radius * r * sin(angle))
            if index == 0 { blob.move(to: point) } else { blob.addLine(to: point) }
        }
        blob.closeSubpath()

        // Colour moving inside it: a mesh whose points drift, faster while thinking.
        let spin = frame.flow * (thinking ? 90 : 30)
        let drift = 0.18 + 0.1 * frame.level
        func wave(_ value: Double) -> Float { Float(drift * value) }
        let mesh = MeshGradient(
            width: 3,
            height: 3,
            points: [
                SIMD2(0, 0), SIMD2(0.5 + wave(sin(spin)), 0), SIMD2(1, 0),
                SIMD2(0, 0.5 + wave(cos(spin * 0.8))), SIMD2(0.5 + wave(sin(spin * 1.3)), 0.5 + wave(cos(spin * 1.1))), SIMD2(1, 0.5 + wave(sin(spin * 0.9))),
                SIMD2(0, 1), SIMD2(0.5 + wave(cos(spin * 1.2)), 1), SIMD2(1, 1),
            ],
            colors: (0..<9).map { colors[$0 % colors.count] }
        )
        context.fill(blob, with: .style(mesh))

        // A glassy highlight, and while thinking a shine running round the rim.
        context.fill(blob, with: .radialGradient(
            Gradient(colors: [.white.opacity(0.35), .white.opacity(0)]),
            center: CGPoint(x: cx - radius * 0.35, y: cy - radius * 0.4),
            startRadius: 0, endRadius: CGFloat(radius * 0.9)
        ))
        if thinking {
            context.stroke(blob, with: .conicGradient(
                Gradient(colors: [.white.opacity(0), .white.opacity(0.9), .white.opacity(0)]),
                center: center, angle: .radians(frame.time * 3)
            ), lineWidth: 2)
        }
    }
}
