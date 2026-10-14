//
//  ParticleCreatureSpeech.swift
//  DesignKit
//
//  The creature speaks (4.10.0): a short line in a comic bubble beside it, a white (dark in dark
//  mode) bubble with an outline in the mood's colour and a tail to the creature. The bubble pops
//  out of the creature, the line is typed letter by letter with a pause at a comma or a full stop,
//  and the creature's mouth talks while it types; then the bubble waits a moment and goes.
//  Outside a chat: a greeting, a hint, a reaction. The conversation itself is `MessageBubble`.
//

import SwiftUI
import DesignTokens

/// A line `ParticleCreature` says (4.10.0), in a speech bubble beside it.
///
/// ```swift
/// ParticleCreature(mood: .happy, speech: CreatureSpeech("Hi, Daulet!"))
/// ParticleCreature(mood: .idle, speech: CreatureSpeech("3 payments this week", placement: .trailing) {
///     showPayments()
/// })
/// ```
///
/// A new line (another text or `id`) replaces the one on screen; `nil` takes it away. Keep it
/// short: a bubble holds about two lines. The hero style only: the compact sphere has no room.
public struct CreatureSpeech: Equatable {
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
        placement: Placement = .above,
        duration: Duration = .automatic,
        id: AnyHashable? = nil,
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self.placement = placement
        self.duration = duration
        self.id = id ?? AnyHashable(text)
        self.action = action
    }

    public static func == (a: CreatureSpeech, b: CreatureSpeech) -> Bool {
        a.id == b.id && a.text == b.text && a.placement == b.placement && a.duration == b.duration
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
    /// The bubble's widest; its text wraps inside.
    public static let maxWidth: CGFloat = 240
    /// The tail's length and its width where it meets the bubble.
    static let tailLength: CGFloat = 10
    static let tailBase: CGFloat = 14
    /// The outline: a comic line in the mood's colour.
    static let outlineWidth: CGFloat = 2
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

/// A speech bubble with a comic outline and a tail on `tailEdge`, the line typed in from
/// `start` when `isTyping`. Laid out left to right (the creature places it by its own sides);
/// the text keeps the app's direction (`textDirection`).
struct CreatureSpeechBubble: View {
    let speech: CreatureSpeech
    let start: Date
    let isTyping: Bool
    let tailEdge: Edge
    let outline: Color
    let glows: Bool
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
        visible.foregroundColor = AppColors.Text.primary
        var rest = AttributedString(String(speech.text.dropFirst(shown)))
        rest.foregroundColor = Color.clear
        let shape = CreatureSpeechBubbleShape(tailEdge: tailEdge)
        let bubble = Text(visible + rest)
            .font(AppTypography.bodySmall.weight(.medium))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.layoutDirection, textDirection)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .padding(tailEdge.set, CreatureSpeechMetrics.tailLength)
            .background {
                shape.fill(AppColors.Background.elevation1)
                shape.stroke(outline, style: StrokeStyle(lineWidth: CreatureSpeechMetrics.outlineWidth, lineJoin: .round))
            }
            .shadow(color: glows ? outline.opacity(0.45) : .clear, radius: glows ? 6 : 0)
            .frame(maxWidth: CreatureSpeechMetrics.maxWidth)
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

/// A rounded bubble with a tail in the middle of one edge; its tip touches the frame's edge.
/// Leading is the left: the creature lays its bubble out left to right and places it itself.
struct CreatureSpeechBubbleShape: Shape {
    let tailEdge: Edge

    func path(in rect: CGRect) -> Path {
        let tail = CreatureSpeechMetrics.tailLength
        let base = CreatureSpeechMetrics.tailBase / 2
        var body = rect
        switch tailEdge {
        case .top: body.origin.y += tail; body.size.height -= tail
        case .bottom: body.size.height -= tail
        case .leading: body.origin.x += tail; body.size.width -= tail
        case .trailing: body.size.width -= tail
        }
        let corner = min(AppRadius.xl, body.height / 2, body.width / 2)
        let midX = body.midX
        let midY = body.midY
        var path = Path()
        path.move(to: CGPoint(x: body.minX + corner, y: body.minY))
        if tailEdge == .top {
            path.addLine(to: CGPoint(x: midX - base, y: body.minY))
            path.addLine(to: CGPoint(x: midX - base * 0.3, y: rect.minY))
            path.addLine(to: CGPoint(x: midX + base, y: body.minY))
        }
        path.addLine(to: CGPoint(x: body.maxX - corner, y: body.minY))
        path.addArc(tangent1End: CGPoint(x: body.maxX, y: body.minY), tangent2End: CGPoint(x: body.maxX, y: body.minY + corner), radius: corner)
        if tailEdge == .trailing {
            path.addLine(to: CGPoint(x: body.maxX, y: midY - base))
            path.addLine(to: CGPoint(x: rect.maxX, y: midY + base * 0.3))
            path.addLine(to: CGPoint(x: body.maxX, y: midY + base))
        }
        path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - corner))
        path.addArc(tangent1End: CGPoint(x: body.maxX, y: body.maxY), tangent2End: CGPoint(x: body.maxX - corner, y: body.maxY), radius: corner)
        if tailEdge == .bottom {
            path.addLine(to: CGPoint(x: midX + base, y: body.maxY))
            path.addLine(to: CGPoint(x: midX - base * 0.3, y: rect.maxY))
            path.addLine(to: CGPoint(x: midX - base, y: body.maxY))
        }
        path.addLine(to: CGPoint(x: body.minX + corner, y: body.maxY))
        path.addArc(tangent1End: CGPoint(x: body.minX, y: body.maxY), tangent2End: CGPoint(x: body.minX, y: body.maxY - corner), radius: corner)
        if tailEdge == .leading {
            path.addLine(to: CGPoint(x: body.minX, y: midY + base))
            path.addLine(to: CGPoint(x: rect.minX, y: midY + base * 0.3))
            path.addLine(to: CGPoint(x: body.minX, y: midY - base))
        }
        path.addLine(to: CGPoint(x: body.minX, y: body.minY + corner))
        path.addArc(tangent1End: CGPoint(x: body.minX, y: body.minY), tangent2End: CGPoint(x: body.minX + corner, y: body.minY), radius: corner)
        path.closeSubpath()
        return path
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
