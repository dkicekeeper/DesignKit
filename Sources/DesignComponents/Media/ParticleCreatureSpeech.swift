//
//  ParticleCreatureSpeech.swift
//  DesignKit
//
//  The creature speaks (4.10.0): words of light, with no bubble (the owner's choice: a comic
//  bubble was a flat sticker next to a creature made of light). Each letter leaves its mouth,
//  flies to its place on an arc and lands, while the mouth talks; then the line lives the way
//  the creature feels: calm letters rest, joyful ones hop in a wave with sparkles, a thought
//  sways in a slant, a whisper glimmers small and pale, worried letters tremble, dizzy ones
//  spin, sad ones sink. The words are in the mood's colour, ink on a light page and light with
//  a glow in the dark, with a soft halo of the page round each letter so they read over
//  anything. Outside a chat: a greeting, a hint, a reaction. The conversation is `MessageBubble`.
//

import SwiftUI
import DesignTokens

/// A line `ParticleCreature` says (4.10.0): words that fly out of its mouth and move the way it
/// feels.
///
/// ```swift
/// ParticleCreature(mood: .happy, speech: CreatureSpeech("Hi, Daulet!"))
/// ParticleCreature(mood: .celebrating, speech: CreatureSpeech("Goal!"))          // joy, from the mood
/// ParticleCreature(mood: .idle, speech: CreatureSpeech("Hmm…", emotion: .thought, placement: .trailing))
/// ```
///
/// A new line (another text or `id`) replaces the one on screen; `nil` takes it away. Keep it
/// short: about two lines. The hero style only: the compact sphere has no room.
public struct CreatureSpeech: Equatable {
    /// How the words move once they land, and how the mouth talks.
    public enum Emotion: Hashable, Sendable {
        /// From the creature's mood when the line comes: joy when it is happy, celebrating,
        /// proud or in love; a thought while thinking; worry when worried; sadness when sad; a
        /// whisper when sleepy or asleep; calm otherwise.
        case automatic
        /// The letters land and rest.
        case calm
        /// Bigger and bolder; a wave of hops runs along the line now and then, sparkles round it;
        /// the mouth opens wide.
        case joy
        /// Slanted and a little pale, swaying slowly. The mouth stays still and the eyes look at
        /// the words.
        case thought
        /// Small and pale, the letters come out of a blur and glimmer; the mouth barely moves.
        case whisper
        /// The letters tremble.
        case worry
        /// The letters spin and sway.
        case dizzy
        /// The letters sink and fade a little.
        case sad
    }

    /// Where the words hang. The creature's view does not grow for them: leave room on that side.
    public enum Placement: Hashable, Sendable {
        /// Over the creature.
        case above
        /// Beside it, after it in the layout's direction.
        case trailing
        /// Beside it, before it.
        case leading
    }

    /// How long the words stay.
    public enum Duration: Hashable, Sendable {
        /// While they come out, then about 2 s more, longer for a longer line (5 s at most).
        case automatic
        /// This many seconds from when they start.
        case seconds(Double)
        /// Until the line changes or becomes `nil`.
        case untilChanged
    }

    public let text: String
    public let emotion: Emotion
    public let placement: Placement
    /// The widest the line may be: narrower where the creature has little room beside it (a
    /// creature in a navigation bar).
    public let maxWidth: CGFloat
    public let duration: Duration
    let id: AnyHashable
    let action: (() -> Void)?

    /// - Parameters:
    ///   - id: Tells two lines with the same text apart, so the same words can be said again.
    ///     The text by default.
    ///   - action: Runs on a tap on the words (they are then a button for VoiceOver).
    public init(
        _ text: String,
        emotion: Emotion = .automatic,
        placement: Placement = .above,
        maxWidth: CGFloat = CreatureSpeechMetrics.maxWidth,
        duration: Duration = .automatic,
        id: AnyHashable? = nil,
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self.emotion = emotion
        self.placement = placement
        self.maxWidth = maxWidth
        self.duration = duration
        self.id = id ?? AnyHashable(text)
        self.action = action
    }

    public static func == (a: CreatureSpeech, b: CreatureSpeech) -> Bool {
        a.id == b.id && a.text == b.text && a.emotion == b.emotion && a.placement == b.placement
            && a.maxWidth == b.maxWidth && a.duration == b.duration
    }

    /// How long the words stay, from when they start; `nil` while the line stands.
    var visibleDuration: Double? {
        switch duration {
        case .automatic:
            let typing = CreatureSpeechTiming.typingDuration(of: text) + CreatureSpeechMetrics.flight
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
    /// The widest a line is by default (`CreatureSpeech(maxWidth:)`).
    public static let maxWidth: CGFloat = 240
    /// A letter's flight from the mouth to its place.
    static let flight: Double = 0.4
    /// The gap between the words and the creature's rim, its glow taken in (`rim` × its radius).
    static let gap: CGFloat = 8
    static let rim: Double = 1.1
    /// The mouth under the sphere's centre, in its radius: where the letters come from.
    static let mouth: Double = 0.3
    /// How far the mood's colour is taken towards white for words in the dark.
    static let lightWords: Double = 0.45
    /// The height the words over the creature may take; words beside it are centred on their
    /// anchor.
    static let room: CGFloat = 200
    /// Where words beside the creature meet it: the upper side of the rim (radians from the
    /// horizontal, up is negative).
    static let sideAngle: Double = -0.45
    /// The halo of the page round each letter, and the glow in the dark.
    static let haloRadius: CGFloat = 2.5
    static let glowRadius: CGFloat = 7
    /// The wait after the words are out, for `.automatic`.
    static let minimumDwell: Double = 2
    static let maximumDwell: Double = 5

    /// Rounded bold type that scales with Dynamic Type: bigger for joy, smaller for a whisper.
    static func font(_ emotion: CreatureSpeech.Emotion) -> Font {
        switch emotion {
        case .joy: .system(.title2, design: .rounded).weight(.heavy)
        case .whisper: .system(.callout, design: .rounded).weight(.semibold)
        case .thought: .system(.body, design: .rounded).weight(.semibold)
        case .automatic, .calm, .worry, .dizzy, .sad: .system(.title3, design: .rounded).weight(.bold)
        }
    }
}

// MARK: - Timing

/// When each letter of a line leaves the mouth, and what the mouth does meanwhile. The words
/// and the creature's mouth read the same schedule, so the mouth stops when the letters do.
enum CreatureSpeechTiming {
    /// About 35 letters a second, a longer pause after a full stop than after a comma.
    static let perLetter = 1.0 / 35
    static let sentencePause = 0.35
    static let clausePause = 0.18

    /// The moment each letter leaves, from the start.
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

    /// How many letters have left `elapsed` seconds in.
    static func shownCount(_ schedule: [Double], at elapsed: Double) -> Int {
        var low = 0
        var high = schedule.count
        while low < high {
            let mid = (low + high) / 2
            if schedule[mid] <= elapsed { low = mid + 1 } else { high = mid }
        }
        return low
    }

    /// The mouth `elapsed` seconds in: 0 shut … 1 open; `nil` once the letters are out. Shut in
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

// MARK: - The words

/// The words of a line, flying out of the mouth from `start` when `moves` (all in place
/// otherwise). `anchor` is the point of the text that touches its anchor by the creature (its
/// bottom over it, its leading or trailing edge beside it); `mouth` is the mouth's offset from
/// that point. Laid out left to right by the creature; the text keeps the app's direction.
struct CreatureSpeechWords: View {
    let speech: CreatureSpeech
    let emotion: CreatureSpeech.Emotion
    let start: Date
    let moves: Bool
    let color: Color
    let glows: Bool
    let anchor: UnitPoint
    let mouth: CGSize
    let textDirection: LayoutDirection

    var body: some View {
        let schedule = CreatureSpeechTiming.schedule(speech.text)
        Group {
            if moves {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    words(elapsed: context.date.timeIntervalSince(start), schedule: schedule)
                }
            } else {
                words(elapsed: nil, schedule: schedule)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(speech.text)
        .accessibilityAddTraits(speech.action == nil ? [] : .isButton)
    }

    private func words(elapsed: Double?, schedule: [Double]) -> some View {
        let line = Text(speech.text)
            .font(CreatureSpeechMetrics.font(emotion))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.layoutDirection, textDirection)
            .textRenderer(CreatureSpeechRenderer(
                elapsed: elapsed,
                schedule: schedule,
                emotion: emotion,
                anchor: anchor,
                mouth: mouth,
                sparkle: color
            ))
            // A halo of the page round each letter, so the words read over anything; in the
            // dark, a glow of their colour too.
            .shadow(color: AppColors.Background.base, radius: CreatureSpeechMetrics.haloRadius)
            .shadow(color: AppColors.Background.base, radius: CreatureSpeechMetrics.haloRadius)
            .shadow(color: glows ? color.opacity(0.55) : .clear, radius: glows ? CreatureSpeechMetrics.glowRadius : 0)
        return Group {
            if let action = speech.action {
                Button(action: action) { line }
                    .buttonStyle(.plain)
            } else {
                line
            }
        }
    }
}

/// Draws each letter on its own: its flight from the mouth, then its emotion. With no time (a
/// still frame) every letter is in place, in the emotion's resting pose.
struct CreatureSpeechRenderer: TextRenderer {
    let elapsed: Double?
    let schedule: [Double]
    let emotion: CreatureSpeech.Emotion
    let anchor: UnitPoint
    let mouth: CGSize
    let sparkle: Color

    /// Room outside the text for the letters' flight from the mouth, their arc and the sparkles.
    var displayPadding: EdgeInsets {
        let around = 56.0
        let side = abs(Double(mouth.width)) + around
        return EdgeInsets(top: around, leading: side, bottom: max(0, Double(mouth.height)) + around, trailing: side)
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        // The text's own bounds, to find the mouth in its coordinates.
        var bounds = CGRect.null
        for line in layout {
            bounds = bounds.union(line.typographicBounds.rect)
        }
        guard !bounds.isNull else { return }
        let anchorX = Double(bounds.minX + bounds.width * anchor.x)
        let anchorY = Double(bounds.minY + bounds.height * anchor.y)
        let mouthX = anchorX + Double(mouth.width)
        let mouthY = anchorY + Double(mouth.height)
        let time = elapsed ?? 0
        let flight = CreatureSpeechMetrics.flight

        var index = 0
        for line in layout {
            for run in line {
                for glyph in run {
                    defer { index += 1 }
                    let leaves = index < schedule.count ? schedule[index] : (schedule.last ?? 0)
                    // 0 at the mouth … 1 in place.
                    let landed = elapsed == nil ? 1 : min(max((time - leaves) / flight, 0), 1)
                    guard landed > 0 else { continue }
                    let rect = glyph.typographicBounds.rect
                    let slotX = Double(rect.midX)
                    let slotY = Double(rect.midY)
                    let since = elapsed == nil ? 10 : time - leaves - flight
                    let pose = Self.pose(emotion, index: index, since: since, time: time)

                    // The flight: out of the mouth on an arc that rises, growing as it goes.
                    let e = Self.easeOut(landed)
                    let lift = min(48, max(16, abs(slotY - mouthY) * 0.5 + 12))
                    let arc = -sin(Double.pi * landed) * lift
                    let x = mouthX + (slotX - mouthX) * e + pose.dx
                    let y = mouthY + (slotY - mouthY) * e + arc * (1 - e * 0.3) + pose.dy
                    let scale = (0.3 + 0.7 * e) * pose.scale

                    var letter = context
                    letter.opacity = min(1, landed * 2.5) * pose.opacity
                    if pose.blur > 0.05 { letter.addFilter(.blur(radius: pose.blur)) }
                    letter.translateBy(x: x, y: y)
                    letter.rotate(by: .radians(pose.rotation))
                    if pose.slant != 0 {
                        letter.concatenate(CGAffineTransform(a: 1, b: 0, c: pose.slant, d: 1, tx: 0, ty: 0))
                    }
                    letter.scaleBy(x: scale, y: scale)
                    letter.translateBy(x: -slotX, y: -slotY)
                    letter.draw(glyph)
                }
            }
        }

        // Joy: a few sparkles twinkle round the words once they are out.
        if emotion == .joy {
            let out: Double = elapsed.map { min(max(($0 - (schedule.last ?? 0) - flight) / 0.3, 0), 1) } ?? 1
            guard out > 0 else { return }
            let spots: [(Double, Double, Double)] = [(-0.08, 0.1, 0), (1.06, 0.25, 1.3), (0.2, -0.35, 2.1), (0.86, -0.3, 0.7), (0.55, 1.25, 1.7)]
            for (sx, sy, phase) in spots {
                let twinkle = elapsed == nil ? 0.8 : 0.5 + 0.5 * sin(time * 4 + phase * 2)
                let size = (4 + 2.5 * twinkle) * out
                let cx = Double(bounds.minX) + Double(bounds.width) * sx
                let cy = Double(bounds.minY) + Double(bounds.height) * sy
                var star = context
                star.opacity = 0.9 * twinkle * out
                star.fill(Self.sparklePath(x: cx, y: cy, radius: size), with: .color(sparkle))
            }
        }
    }

    /// What an emotion does to a letter once it has landed, `since` seconds ago, `time` into
    /// the line (a still frame passes a long `since` and no time: the resting pose).
    private struct Pose {
        var dx = 0.0
        var dy = 0.0
        var rotation = 0.0
        var scale = 1.0
        var slant = 0.0
        var opacity = 1.0
        var blur = 0.0
    }

    private static func pose(_ emotion: CreatureSpeech.Emotion, index: Int, since: Double, time: Double) -> Pose {
        var pose = Pose()
        let i = Double(index)
        switch emotion {
        case .automatic, .calm:
            break
        case .joy:
            // A landing bounce, then a wave of hops along the line every 1.8 s.
            if since >= 0 && since < 0.35 { pose.scale = 1 + 0.25 * sin(Double.pi * since / 0.35) }
            let wave = (time - i * 0.07).truncatingRemainder(dividingBy: 1.8)
            if wave > 0 && wave < 0.3 { pose.dy = -6 * sin(Double.pi * wave / 0.3) }
        case .thought:
            pose.slant = -0.2
            pose.opacity = 0.8
            pose.dy = 2.5 * sin(time * 1.8 + i * 0.5)
        case .whisper:
            pose.opacity = 0.62 + 0.13 * sin(time * 3 + i * 0.9)
            pose.blur = max(0, 3 * (1 - since / 0.5))
        case .worry:
            pose.dx = 0.9 * noise(time * 22 + i * 3.1)
            pose.dy = 0.9 * noise(time * 19 + i * 5.3)
        case .dizzy:
            pose.rotation = 0.25 * sin(time * 4 + i * 0.7)
            pose.dy = 4 * sin(time * 3 + i * 0.6)
        case .sad:
            let sink = min(1, max(since, 0) / 1.5)
            pose.dy = 4 * sink * (0.6 + 0.4 * sin(i * 1.7))
            pose.rotation = 0.06 * sink * sin(i * 2.3)
            pose.opacity = 1 - 0.25 * sink
        }
        return pose
    }

    private static func easeOut(_ x: Double) -> Double {
        let c = min(max(x, 0), 1)
        return 1 - pow(1 - c, 3)
    }

    /// A smooth value in -1…1, the same for the same input.
    private static func noise(_ x: Double) -> Double {
        sin(x) * 0.6 + sin(x * 2.3 + 1.7) * 0.4
    }

    private static func sparklePath(x: Double, y: Double, radius: Double) -> Path {
        var path = Path()
        for k in 0..<8 {
            let angle = Double(k) * Double.pi / 4 - Double.pi / 2
            let r = k.isMultiple(of: 2) ? radius : radius * 0.32
            let point = CGPoint(x: x + r * cos(angle), y: y + r * sin(angle))
            if k == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
