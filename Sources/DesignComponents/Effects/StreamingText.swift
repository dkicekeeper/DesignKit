//
//  StreamingText.swift
//  DesignKit
//
//  Text that arrives word by word (2.9.0): live speech recognition, an answer being written. Each
//  new word slides up out of a blur (`.blurSlideWord`); words already on screen keep still, even
//  when the recogniser refines the text, and a word can be tinted (a recognised amount, a
//  category). Ported from Tenra's AnimatedTranscriptionText; the recognised entities and their
//  confidence colours stay in Tenra, which passes highlights.
//
//  Light: the words are split once per text change, not per frame; a word whose text matches the
//  previous snapshot keeps its identity, so only new words animate.
//
//  Every script (5.1.1): a word is what the text has between spaces, with its punctuation, so a
//  gap shows exactly where the text has a space. A line in a script written without spaces
//  (Japanese, Chinese, Thai) is cut into its dictionary words, drawn with no gap between them, so
//  it still wraps.
//

import SwiftUI
import DesignTokens

/// Words that slide in as the text grows.
///
/// ```swift
/// StreamingText(voice.transcript, highlights: entities.map {
///     .init(range: $0.range, color: $0.confidence > 0.8 ? AppColors.success : AppColors.warning)
/// })
/// ```
public struct StreamingText: View {
    /// A tinted stretch of the text: every word that overlaps `range` takes `color`.
    public struct Highlight: Equatable {
        /// In UTF-16 units of the text (`NSRange`, as `NSString` and the Speech framework count).
        public let range: NSRange
        public let color: Color

        public init(range: NSRange, color: Color) {
            self.range = range
            self.color = color
        }
    }

    let text: String
    let highlights: [Highlight]
    let font: Font
    let alignment: HorizontalAlignment

    @State private var tokens: [Token] = []
    @State private var nextID = 0

    /// - Parameters:
    ///   - highlights: Words to tint; the rest are in the primary text colour.
    ///   - alignment: How each line sits: leading, centred or trailing.
    public init(
        _ text: String,
        highlights: [Highlight] = [],
        font: Font = AppTypography.h1,
        alignment: HorizontalAlignment = .leading
    ) {
        self.text = text
        self.highlights = highlights
        self.font = font
        self.alignment = alignment
    }

    public var body: some View {
        FlowLayout(spacing: AppSpacing.sm, lineSpacing: StreamingTextMetrics.lineSpacing, alignment: alignment) {
            ForEach(tokens) { token in
                Text(verbatim: token.text)
                    .font(font)
                    .foregroundStyle(token.color)
                    .layoutValue(key: FlowJoinsPrevious.self, value: token.joinsPrevious)
                    .transition(.blurSlideWord)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: text))
        .onAppear { refresh() }
        .onChange(of: text) { _, _ in refresh() }
        .onChange(of: highlights) { _, _ in refresh() }
    }

    private func refresh() {
        let next = Self.reconcile(previous: tokens, words: Self.words(in: text, highlights: highlights), nextID: nextID)
        withAnimation(AppAnimation.gentleSpring) {
            tokens = next.tokens
        }
        nextID = next.nextID
    }

    // MARK: Words

    struct Token: Identifiable, Equatable {
        let id: Int
        let text: String
        let color: Color
        let joinsPrevious: Bool
    }

    struct Word: Equatable {
        let text: String
        let color: Color
        /// Drawn right after the previous word, with no gap: the next word of a line written
        /// without spaces.
        let joinsPrevious: Bool
    }

    /// The text's words, each in its highlight's colour or the primary one.
    ///
    /// A word is a stretch of the text between spaces and line breaks, with its punctuation
    /// ("потратил?", "12,000원"), so every character of the text is drawn and the gaps fall where
    /// its spaces are. A stretch in a script written without spaces is cut into its dictionary
    /// words, which join each other: "コンビニで500円使った。" stays one line of text that can wrap
    /// between its words.
    static func words(in text: String, highlights: [Highlight]) -> [Word] {
        let string = text as NSString
        var result: [Word] = []
        for run in runs(in: string) {
            var start = run.location
            for end in cuts(in: run, of: string) + [NSMaxRange(run)] where end > start {
                let range = NSRange(location: start, length: end - start)
                let color = highlights.first { NSIntersectionRange($0.range, range).length > 0 }?.color
                result.append(Word(
                    text: string.substring(with: range),
                    color: color ?? AppColors.Text.primary,
                    joinsPrevious: start > run.location
                ))
                start = end
            }
        }
        return result
    }

    /// The stretches between spaces and line breaks. A no-break space ("2 500") is part of its
    /// stretch, as it is of the word it holds together.
    private static func runs(in string: NSString) -> [NSRange] {
        var runs: [NSRange] = []
        var start: Int?
        for index in 0..<string.length {
            if isSeparator(string.character(at: index)) {
                if let runStart = start {
                    runs.append(NSRange(location: runStart, length: index - runStart))
                    start = nil
                }
            } else if start == nil {
                start = index
            }
        }
        if let runStart = start {
            runs.append(NSRange(location: runStart, length: string.length - runStart))
        }
        return runs
    }

    private static func isSeparator(_ unit: unichar) -> Bool {
        // Every space and line break is one UTF-16 unit; half of a surrogate pair is no scalar.
        guard let scalar = Unicode.Scalar(unit), !noBreakSpaces.contains(scalar.value) else { return false }
        return CharacterSet.whitespacesAndNewlines.contains(scalar)
    }

    private static let noBreakSpaces: Set<UInt32> = [0x00A0, 0x2007, 0x202F]

    /// Where a stretch written without spaces splits into words: at the start of each word but
    /// the first, moved back over an opening bracket or quote so that it opens the next word.
    /// Other punctuation (、。」！) stays at the end of the word before it, so a line never starts
    /// with it. None for a stretch in a script that spaces its words.
    private static func cuts(in run: NSRange, of string: NSString) -> [Int] {
        guard isWrittenWithoutSpaces(string.substring(with: run)) else { return [] }
        var cuts: [Int] = []
        string.enumerateSubstrings(in: run, options: [.byWords, .substringNotRequired]) { _, word, _, _ in
            let floor = cuts.last ?? run.location
            var cut = word.location
            while cut > floor, opensNextWord(string, before: cut) {
                cut = max(floor, string.rangeOfComposedCharacterSequence(at: cut - 1).location)
            }
            if cut > floor { cuts.append(cut) }
        }
        return cuts
    }

    private static func opensNextWord(_ string: NSString, before index: Int) -> Bool {
        let character = string.substring(with: string.rangeOfComposedCharacterSequence(at: index - 1))
        switch character.unicodeScalars.first?.properties.generalCategory {
        case .openPunctuation?, .initialPunctuation?: return true
        default: return false
        }
    }

    /// Chinese, Japanese, Thai, Lao, Khmer and Myanmar put no spaces between words (Korean does).
    private static func isWrittenWithoutSpaces(_ run: String) -> Bool {
        run.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x0E00...0x0EFF,   // Thai, Lao
                 0x1000...0x109F,   // Myanmar
                 0x1780...0x17FF,   // Khmer
                 0x2E80...0x2FDF,   // CJK and Kangxi radicals
                 0x3040...0x30FF,   // Hiragana, Katakana
                 0x3100...0x312F,   // Bopomofo
                 0x31A0...0x31FF,   // Bopomofo extended, CJK strokes, Katakana extensions
                 0x3400...0x4DBF,   // CJK extension A
                 0x4E00...0x9FFF,   // CJK unified ideographs
                 0xF900...0xFAFF,   // CJK compatibility ideographs
                 0xFF66...0xFF9F,   // halfwidth Katakana
                 0x20000...0x3FFFF: // CJK extensions B and later
                return true
            default:
                return false
            }
        }
    }

    /// Matches the new words against the shown ones from the start: a word in the same place with
    /// the same text keeps its identity (no entrance again, its colour and its gap refreshed), and
    /// so does one that only gained or lost punctuation around it (the recogniser adds a "?" to
    /// "потратил"); the others get new identities; shown words past the end go.
    static func reconcile(previous: [Token], words: [Word], nextID: Int) -> (tokens: [Token], nextID: Int) {
        var next = nextID
        let tokens = words.enumerated().map { index, word in
            if index < previous.count, isSameWord(previous[index].text, word.text) {
                return Token(id: previous[index].id, text: word.text, color: word.color, joinsPrevious: word.joinsPrevious)
            }
            defer { next += 1 }
            return Token(id: next, text: word.text, color: word.color, joinsPrevious: word.joinsPrevious)
        }
        return (tokens, next)
    }

    private static func isSameWord(_ shown: String, _ new: String) -> Bool {
        if shown == new { return true }
        let core = shown.trimmingCharacters(in: .punctuationCharacters)
        return !core.isEmpty && core == new.trimmingCharacters(in: .punctuationCharacters)
    }
}

enum StreamingTextMetrics {
    static let lineSpacing: CGFloat = 6
}

// MARK: - Skeleton

/// Placeholder of a `StreamingText`: two lines of the text's style.
public struct StreamingTextSkeleton: View {
    let font: Font

    public init(font: Font = AppTypography.h1) {
        self.font = font
    }

    public var body: some View {
        SkeletonText(font, lines: 2)
            .shimmer()
            .skeletonLoadingLabel()
    }
}
