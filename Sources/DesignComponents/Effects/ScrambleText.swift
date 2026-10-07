//
//  ScrambleText.swift
//  DesignKit
//
//  Text that decodes itself (2.6.0): each character flickers through random ones of its kind
//  (digits for a digit, letters for a letter) and settles, left to right. For a result that
//  was just worked out: an analysis total, a code, a score.
//
//  Light: a TimelineView at 30 fps only while it decodes (0.7 s), paused otherwise. The text
//  keeps its final width all along, so nothing around it moves. VoiceOver reads the final
//  text. Under Reduce Motion or `.designKitMotion(false)` the text simply appears.
//

import SwiftUI
import DesignTokens

/// Text that decodes itself when it appears and whenever it changes.
///
/// ```swift
/// ScrambleText("78 / 100")
///     .font(AppTypography.h1)
/// ```
///
/// Style it like `Text` (font, colour); monospaced digits keep the flicker steady.
public struct ScrambleText: View {
    let text: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    @State private var start: Date?
    @State private var runs = 0

    public init(_ text: String) {
        self.text = text
    }

    private var allowsMotion: Bool { !reduceMotion && designKitMotion }

    public var body: some View {
        // The final text sets the width; the decoding text is drawn over it.
        Text(verbatim: text)
            .hidden()
            .overlay(alignment: .leading) {
                TimelineView(.animation(minimumInterval: ScrambleMetrics.frameInterval, paused: start == nil)) { timeline in
                    Text(verbatim: Self.scrambled(text, since: start, at: timeline.date, seed: runs))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .monospacedDigit()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: text))
            .onAppear { play() }
            .onChange(of: text) { play() }
    }

    private func play() {
        guard allowsMotion else { return }
        runs += 1
        let run = runs
        start = .now
        Task {
            try? await Task.sleep(for: .seconds(ScrambleMetrics.duration))
            if runs == run { start = nil }
        }
    }

    /// The text at `date`: settled characters as they are, the rest random ones of their kind.
    static func scrambled(_ text: String, since start: Date?, at date: Date, seed: Int) -> String {
        guard let start else { return text }
        let elapsed = date.timeIntervalSince(start)
        let characters = Array(text)
        guard !characters.isEmpty else { return text }
        // A new random character every frame; the same frame always draws the same text.
        var random = SeededRandom(seed: UInt64(seed) &* 1_000_003 &+ UInt64(max(elapsed, 0) * 30))
        return String(characters.enumerated().map { index, character in
            let settlesAt = ScrambleMetrics.duration * 0.25 + ScrambleMetrics.duration * 0.75 * Double(index + 1) / Double(characters.count)
            guard elapsed < settlesAt else { return character }
            if character.isNumber { return ScrambleMetrics.digits[Int(random.next() % UInt64(ScrambleMetrics.digits.count))] }
            if character.isLetter { return ScrambleMetrics.letters[Int(random.next() % UInt64(ScrambleMetrics.letters.count))] }
            return character
        })
    }
}

enum ScrambleMetrics {
    /// Start to the last character settling.
    static let duration: Double = 0.7
    static let frameInterval: Double = 1.0 / 30
    static let digits = Array("0123456789")
    static let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")
}
