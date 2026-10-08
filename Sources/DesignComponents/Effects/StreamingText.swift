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
    }

    struct Word: Equatable {
        let text: String
        let color: Color
    }

    /// The text's words, each in its highlight's colour or the primary one.
    static func words(in text: String, highlights: [Highlight]) -> [Word] {
        guard !text.isEmpty else { return [] }
        var result: [Word] = []
        let string = text as NSString
        string.enumerateSubstrings(in: NSRange(location: 0, length: string.length), options: .byWords) { word, range, _, _ in
            guard let word, !word.isEmpty else { return }
            let color = highlights.first { NSIntersectionRange($0.range, range).length > 0 }?.color
            result.append(Word(text: word, color: color ?? AppColors.Text.primary))
        }
        return result
    }

    /// Matches the new words against the shown ones from the start: a word in the same place with
    /// the same text keeps its identity (no entrance again, its colour refreshed); the others get
    /// new identities; shown words past the end go.
    static func reconcile(previous: [Token], words: [Word], nextID: Int) -> (tokens: [Token], nextID: Int) {
        var next = nextID
        let tokens = words.enumerated().map { index, word in
            if index < previous.count, previous[index].text == word.text {
                return Token(id: previous[index].id, text: word.text, color: word.color)
            }
            defer { next += 1 }
            return Token(id: next, text: word.text, color: word.color)
        }
        return (tokens, next)
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
