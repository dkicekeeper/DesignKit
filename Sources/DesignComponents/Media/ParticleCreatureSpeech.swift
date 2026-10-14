//
//  ParticleCreatureSpeech.swift
//  DesignKit
//
//  The creature speaks (4.10.0): a short line in a cartoon bubble beside it, after the owner's
//  comic references. White with a thick graphite outline in both colour schemes (a sticker on a
//  dark page), rounded bold type, and a shape for each way of saying it: an oval with a curved
//  tail for a line, a burst with a spike for an exclamation, a cloud with bubbles rising to it for
//  a thought, a dashed oval for a whisper. The bubble pops out of the creature, the line types in
//  letter by letter with a pause at a comma or a full stop, and the mouth talks while it types
//  (a thought keeps the mouth still and the eyes on the cloud); then the bubble waits and goes.
//  Outside a chat: a greeting, a hint, a reaction. The conversation itself is `MessageBubble`.
//

import SwiftUI
import DesignTokens

/// A line `ParticleCreature` says (4.10.0), in a cartoon bubble beside it.
///
/// ```swift
/// ParticleCreature(mood: .happy, speech: CreatureSpeech("Hi, Daulet!"))
/// ParticleCreature(mood: .celebrating, speech: CreatureSpeech("Goal!", style: .shout))
/// ParticleCreature(mood: .idle, speech: CreatureSpeech("3 payments this week", placement: .trailing) {
///     showPayments()
/// })
/// ```
///
/// A new line (another text or `id`) replaces the one on screen; `nil` takes it away. Keep it
/// short: a bubble holds about two lines, a shout a few words. The hero style only: the compact
/// sphere has no room.
public struct CreatureSpeech: Equatable {
    /// How it is said, and so the bubble's shape.
    public enum Style: Hashable, Sendable {
        /// A line: an oval with a curved tail.
        case say
        /// An exclamation: a burst with one spike to the creature, bigger and bolder type, the
        /// mouth opening wide. A few words.
        case shout
        /// A thought: a cloud with two bubbles rising to it. The mouth stays still and the eyes
        /// look up at the cloud.
        case think
        /// A quiet word: an oval with a dashed outline, smaller type, the mouth barely moving.
        case whisper
    }

    /// Where the bubble hangs. The creature's view does not grow for it: leave room on that side.
    public enum Placement: Hashable, Sendable {
        /// Over the creature, the tail down to it.
        case above
        /// Beside it, after it in the layout's direction.
        case trailing
        /// Beside it, before it.
        case leading
    }

    /// How long the bubble stays.
    public enum Duration: Hashable, Sendable {
        /// While it types, then about 2 s more, longer for a longer line (5 s at most).
        case automatic
        /// This many seconds from when it appears.
        case seconds(Double)
        /// Until the line changes or becomes `nil`.
        case untilChanged
    }

    public let text: String
    public let style: Style
    public let placement: Placement
    public let duration: Duration
    let id: AnyHashable
    let action: (() -> Void)?

    /// - Parameters:
    ///   - id: Tells two lines with the same text apart, so the same words can be said again.
    ///     The text by default.
    ///   - action: Runs on a tap on the bubble (the bubble is then a button for VoiceOver).
    public init(
        _ text: String,
        style: Style = .say,
        placement: Placement = .above,
        duration: Duration = .automatic,
        id: AnyHashable? = nil,
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self.style = style
        self.placement = placement
        self.duration = duration
        self.id = id ?? AnyHashable(text)
        self.action = action
    }

    public static func == (a: CreatureSpeech, b: CreatureSpeech) -> Bool {
        a.id == b.id && a.text == b.text && a.style == b.style && a.placement == b.placement
            && a.duration == b.duration
    }

    /// How long the bubble stays, from when it appears; `nil` while the line stands.
    var visibleDuration: Double? {
        switch duration {
        case .automatic:
            let typing = CreatureSpeechTiming.typingDuration(of: text)
            let dwell = min(max(1.6 + 0.045 * Double(text.count), CreatureSpeechMetrics.minimumDwell),
                            CreatureSpeechMetrics.maximumDwell)
            return typing + dwell
        case .seconds(let seconds):
            return max(seconds, 0.5)
        case .untilChanged:
            return nil
        }
    }
}

public enum CreatureSpeechMetrics {
    /// The widest a bubble is offered; its text wraps inside, less its padding.
    public static let maxWidth: CGFloat = 240
    /// A cartoon bubble in both colour schemes: white, a graphite outline, near-black type.
    static let paper = Color.white
    static let outline = Color(white: 0.2)
    static let ink = Color(white: 0.1)
    static let outlineWidth: CGFloat = 3
    /// The whisper's dashes.
    static let whisperDash: [CGFloat] = [7, 5]
    /// The tail's base where it leaves an oval.
    static let tailBase: CGFloat = 22
    /// How far the cloud's bumps rise above its line.
    static let cloudBump: CGFloat = 9
    /// The gap between the tail's tip and the creature's rim.
    static let gap: CGFloat = 2
    /// The height a bubble over the creature may take; a bubble beside it is centred on its tail.
    static let room: CGFloat = 200
    /// Where a bubble beside the creature meets it: the upper side of the rim (radians from the
    /// horizontal, up is negative).
    static let sideAngle: Double = -0.45
    /// The wait after the line is typed, for `.automatic`.
    static let minimumDwell: Double = 2
    static let maximumDwell: Double = 5

    /// The room the tail (or a thought's bubbles) takes beside the bubble.
    static func tailLength(_ style: CreatureSpeech.Style) -> CGFloat {
        switch style {
        case .say, .whisper: 20
        case .shout: 18
        case .think: 30
        }
    }

    /// The text's distance from the bubble's frame: an oval, a cloud and a burst need more at
    /// the sides than a box, or the corners of the text poke out.
    static func padding(_ style: CreatureSpeech.Style) -> EdgeInsets {
        switch style {
        case .say: EdgeInsets(top: 16, leading: 22, bottom: 16, trailing: 22)
        case .whisper: EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        case .shout: EdgeInsets(top: 32, leading: 40, bottom: 32, trailing: 40)
        case .think: EdgeInsets(top: 24, leading: 30, bottom: 24, trailing: 30)
        }
    }

    /// Rounded bold type that scales with Dynamic Type; bigger for a shout, smaller for a whisper.
    static func font(_ style: CreatureSpeech.Style) -> Font {
        switch style {
        case .say: .system(.body, design: .rounded).weight(.semibold)
        case .shout: .system(.title3, design: .rounded).weight(.heavy)
        case .think: .system(.body, design: .rounded).weight(.medium)
        case .whisper: .system(.callout, design: .rounded).weight(.medium)
        }
    }
}

// MARK: - Timing

/// When each letter of a line appears, and what the mouth does meanwhile. The bubble and the
/// creature's mouth read the same schedule, so the mouth stops when the letters do.
enum CreatureSpeechTiming {
    /// About 35 letters a second, a longer pause after a full stop than after a comma.
    static let perLetter = 1.0 / 35
    static let sentencePause = 0.35
    static let clausePause = 0.18

    /// The moment each letter appears, from the start.
    static func schedule(_ text: String) -> [Double] {
        var times: [Double] = []
        times.reserveCapacity(text.count)
        var t = 0.0
        for character in text {
            times.append(t)
            t += perLetter
            if ".!?…".contains(character) {
                t += sentencePause
            } else if ",;:—".contains(character) {
                t += clausePause
            }
        }
        return times
    }

    static func typingDuration(of text: String) -> Double {
        (schedule(text).last ?? 0) + perLetter
    }

    /// How many letters show `elapsed` seconds in.
    static func shownCount(_ schedule: [Double], at elapsed: Double) -> Int {
        var low = 0
        var high = schedule.count
        while low < high {
            let mid = (low + high) / 2
            if schedule[mid] <= elapsed { low = mid + 1 } else { high = mid }
        }
        return low
    }

    /// The mouth `elapsed` seconds in: 0 shut … 1 open; `nil` once the line is typed. Shut in
    /// the pause after a comma or a full stop, otherwise opening and closing about four times a
    /// second, like syllables.
    static func mouth(_ schedule: [Double], letters: [Character], at elapsed: Double) -> Double? {
        guard let last = schedule.last, elapsed >= 0, elapsed < last + perLetter else { return nil }
        let index = max(0, shownCount(schedule, at: elapsed) - 1)
        if index < letters.count, ".!?…,;:—".contains(letters[index]), elapsed - schedule[index] > perLetter * 1.5 {
            return 0
        }
        return 0.15 + 0.85 * abs(sin(elapsed * 2 * .pi * 4.2))
    }
}

// MARK: - The bubble

/// A cartoon bubble for `speech`, its tail (or a thought's bubbles) on `tailEdge`, the line
/// typed in from `start` when `isTyping`. It hugs its text and wraps at the width it is offered.
/// Laid out left to right (the creature places it by its own sides); the text keeps the app's
/// direction (`textDirection`).
struct CreatureSpeechBubble: View {
    let speech: CreatureSpeech
    let start: Date
    let isTyping: Bool
    let tailEdge: Edge
    let textDirection: LayoutDirection

    var body: some View {
        let schedule = CreatureSpeechTiming.schedule(speech.text)
        Group {
            if isTyping, !schedule.isEmpty {
                TimelineView(.explicit(schedule.map { start.addingTimeInterval($0) })) { context in
                    line(shown: CreatureSpeechTiming.shownCount(schedule, at: context.date.timeIntervalSince(start)))
                }
            } else {
                line(shown: speech.text.count)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(speech.text)
        .accessibilityAddTraits(speech.action == nil ? [] : .isButton)
    }

    private func line(shown: Int) -> some View {
        // The whole line is laid out from the start (the rest clear), so the bubble keeps its
        // size while the letters come in.
        var visible = AttributedString(String(speech.text.prefix(shown)))
        visible.foregroundColor = CreatureSpeechMetrics.ink
        var rest = AttributedString(String(speech.text.dropFirst(shown)))
        rest.foregroundColor = Color.clear
        let style = speech.style
        let shape = CreatureSpeechBubbleShape(style: style, tailEdge: tailEdge)
        let stroke = StrokeStyle(
            lineWidth: CreatureSpeechMetrics.outlineWidth,
            lineCap: .round,
            lineJoin: .round,
            dash: style == .whisper ? CreatureSpeechMetrics.whisperDash : []
        )
        let bubble = Text(visible + rest)
            .font(CreatureSpeechMetrics.font(style))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.layoutDirection, textDirection)
            .padding(CreatureSpeechMetrics.padding(style))
            .padding(tailEdge.set, CreatureSpeechMetrics.tailLength(style))
            .background {
                shape.fill(CreatureSpeechMetrics.paper)
                shape.stroke(CreatureSpeechMetrics.outline, style: stroke)
            }
        return Group {
            if let action = speech.action {
                Button(action: action) { bubble }
                    .buttonStyle(.plain)
            } else {
                bubble
            }
        }
    }
}

/// The bubble's outline: an oval with a curved tail, a burst with a long spike, or a cloud with
/// two bubbles towards the creature. The tail's tip (or the last bubble) touches the middle of
/// `tailEdge`. Leading is the left: the creature lays its bubble out left to right.
struct CreatureSpeechBubbleShape: Shape {
    let style: CreatureSpeech.Style
    let tailEdge: Edge

    func path(in rect: CGRect) -> Path {
        let tail = CreatureSpeechMetrics.tailLength(style)
        var body = rect
        let tip: CGPoint
        switch tailEdge {
        case .top:
            body.origin.y += tail
            body.size.height -= tail
            tip = CGPoint(x: rect.midX, y: rect.minY)
        case .bottom:
            body.size.height -= tail
            tip = CGPoint(x: rect.midX, y: rect.maxY)
        case .leading:
            body.origin.x += tail
            body.size.width -= tail
            tip = CGPoint(x: rect.minX, y: rect.midY)
        case .trailing:
            body.size.width -= tail
            tip = CGPoint(x: rect.maxX, y: rect.midY)
        }
        guard body.width > 4, body.height > 4 else { return Path() }
        switch style {
        case .say, .whisper: return Self.oval(body, tip: tip, vertical: tailEdge == .top || tailEdge == .bottom)
        case .shout: return Self.burst(body, tip: tip)
        case .think: return Self.cloud(body, tip: tip, vertical: tailEdge == .top || tailEdge == .bottom)
        }
    }

    /// A fat oval (a superellipse, rounder at the corners than an ellipse, so a line of text fits)
    /// with a tail like a comma: it leaves the oval a little to one side of the tip and bows on
    /// its way there.
    private static func oval(_ body: CGRect, tip: CGPoint, vertical: Bool) -> Path {
        let outline = superellipse(body, exponent: 2.4, steps: 144)
        // Where the tail leaves: off the straight line to the tip, so it curves in.
        let toward = vertical
            ? CGPoint(x: tip.x + body.width * 0.18, y: tip.y)
            : CGPoint(x: tip.x, y: tip.y - body.height * 0.3)
        let base = nearest(outline, to: toward)
        let half = max(1, Int((CreatureSpeechMetrics.tailBase / 2) / step(outline)))
        let count = outline.count
        let start = (base + half) % count
        let end = (base - half + count) % count
        var path = Path()
        path.move(to: outline[start])
        var k = start
        while k != end {
            k = (k + 1) % count
            path.addLine(to: outline[k])
        }
        // Both edges bow the same way: a swoosh.
        let from = outline[base]
        let dx = tip.x - from.x
        let dy = tip.y - from.y
        let length = max(hypot(dx, dy), 1)
        let bow = CGPoint(x: dy / length * length * 0.22, y: -dx / length * length * 0.22)
        let near = outline[end]
        let far = outline[start]
        path.addQuadCurve(to: tip, control: CGPoint(x: (near.x + tip.x) / 2 + bow.x, y: (near.y + tip.y) / 2 + bow.y))
        path.addQuadCurve(to: far, control: CGPoint(x: (tip.x + far.x) / 2 + bow.x, y: (tip.y + far.y) / 2 + bow.y))
        path.closeSubpath()
        return path
    }

    /// A burst: spikes round an ellipse, a little uneven like a hand-drawn one, the spike
    /// nearest the creature reaching to the tip.
    private static func burst(_ body: CGRect, tip: CGPoint) -> Path {
        let cx = Double(body.midX)
        let cy = Double(body.midY)
        let a = Double(body.width / 2)
        let b = Double(body.height / 2)
        let spikes = max(10, min(18, Int((a + b) / 12)))
        let toTip = atan2((Double(tip.y) - cy) / b, (Double(tip.x) - cx) / a)
        var path = Path()
        for i in 0..<(spikes * 2) {
            let angle = toTip + Double.pi * Double(i) / Double(spikes)
            let point: CGPoint
            if i == 0 {
                point = tip
            } else {
                // Fixed unevenness per spike: the same burst every time.
                let wobble = fraction(sin(Double(i) * 12.9898) * 43758.5453)
                let r = i.isMultiple(of: 2) ? 0.94 + 0.06 * wobble : 0.76 + 0.06 * wobble
                point = CGPoint(x: cx + a * r * cos(angle), y: cy + b * r * sin(angle))
            }
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    /// A cloud: bumps along an ellipse, a little uneven, and two bubbles from its edge to the
    /// tip, the far one smaller.
    private static func cloud(_ body: CGRect, tip: CGPoint, vertical: Bool) -> Path {
        let bump = Double(CreatureSpeechMetrics.cloudBump)
        let inner = body.insetBy(dx: bump, dy: bump)
        let cx = Double(inner.midX)
        let cy = Double(inner.midY)
        let a = Double(inner.width / 2)
        let b = Double(inner.height / 2)
        let perimeter = Double.pi * (3 * (a + b) - ((3 * a + b) * (a + 3 * b)).squareRoot())
        let count = max(7, Int(perimeter / 26))
        var points: [CGPoint] = []
        for i in 0..<count {
            let wobble = fraction(sin(Double(i) * 78.233) * 43758.5453) - 0.5
            let angle = 2 * Double.pi * (Double(i) + wobble * 0.3) / Double(count)
            points.append(CGPoint(x: cx + a * cos(angle), y: cy + b * sin(angle)))
        }
        var path = Path()
        path.move(to: points[0])
        for i in 0..<count {
            let p = points[i]
            let q = points[(i + 1) % count]
            let mid = CGPoint(x: (p.x + q.x) / 2, y: (p.y + q.y) / 2)
            // Outwards from the centre, in the ellipse's own proportions.
            let nx = (Double(mid.x) - cx) / max(a, 1)
            let ny = (Double(mid.y) - cy) / max(b, 1)
            let norm = max(hypot(nx, ny), 0.001)
            let lift = bump * 2.2
            path.addQuadCurve(to: q, control: CGPoint(x: Double(mid.x) + nx / norm * lift, y: Double(mid.y) + ny / norm * lift))
        }
        path.closeSubpath()
        // The thought's bubbles rise from the cloud's edge, a little to one side, to the tip.
        let toward = vertical
            ? CGPoint(x: tip.x + body.width * 0.2, y: tip.y)
            : CGPoint(x: tip.x, y: tip.y - body.height * 0.3)
        let angle = atan2((Double(toward.y) - cy) / b, (Double(toward.x) - cx) / a)
        let edgeX = cx + (a + bump) * cos(angle)
        let edgeY = cy + (b + bump) * sin(angle)
        let tipX = Double(tip.x)
        let tipY = Double(tip.y)
        for (share, radius) in [(0.42, 6.5), (0.86, 3.6)] {
            let x = edgeX + (tipX - edgeX) * share
            let y = edgeY + (tipY - edgeY) * share
            path.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
        return path
    }

    // MARK: Helpers

    private static func superellipse(_ rect: CGRect, exponent: Double, steps: Int) -> [CGPoint] {
        let cx = Double(rect.midX)
        let cy = Double(rect.midY)
        let a = Double(rect.width / 2)
        let b = Double(rect.height / 2)
        let power = 2 / exponent
        return (0..<steps).map { k in
            let t = 2 * Double.pi * Double(k) / Double(steps)
            let c = cos(t)
            let s = sin(t)
            return CGPoint(
                x: cx + a * (c < 0 ? -1 : 1) * pow(abs(c), power),
                y: cy + b * (s < 0 ? -1 : 1) * pow(abs(s), power)
            )
        }
    }

    private static func nearest(_ points: [CGPoint], to target: CGPoint) -> Int {
        var best = 0
        var bestDistance = Double.infinity
        for (index, point) in points.enumerated() {
            let distance = hypot(point.x - target.x, point.y - target.y)
            if distance < bestDistance {
                bestDistance = distance
                best = index
            }
        }
        return best
    }

    /// The outline's average spacing.
    private static func step(_ points: [CGPoint]) -> CGFloat {
        guard points.count > 1 else { return 1 }
        var total: CGFloat = 0
        for index in points.indices {
            let p = points[index]
            let q = points[(index + 1) % points.count]
            total += hypot(q.x - p.x, q.y - p.y)
        }
        return max(total / CGFloat(points.count), 0.5)
    }

    private static func fraction(_ x: Double) -> Double {
        x - x.rounded(.down)
    }
}

private extension Edge {
    var set: Edge.Set {
        switch self {
        case .top: .top
        case .bottom: .bottom
        case .leading: .leading
        case .trailing: .trailing
        }
    }
}
