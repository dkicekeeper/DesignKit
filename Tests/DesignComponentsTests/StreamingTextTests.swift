//
//  StreamingTextTests.swift
//  DesignKit
//
//  How StreamingText splits and keeps its words (2.9.0, from Tenra's AnimatedTranscriptionText;
//  every script and its punctuation since 5.1.1), and how PagerArrows steps.
//

import Foundation
import SwiftUI
import Testing
@testable import DesignComponents

@MainActor
@Suite("Streaming text")
struct StreamingTextTests {
    /// The text as the layout draws it: a gap before every word that does not join the previous one.
    private func rendered(_ words: [StreamingText.Word]) -> String {
        words.enumerated().map { index, word in
            index == 0 || word.joinsPrevious ? word.text : " " + word.text
        }.joined()
    }

    private func words(_ text: String, highlights: [StreamingText.Highlight] = []) -> [StreamingText.Word] {
        StreamingText.words(in: text, highlights: highlights)
    }

    private func highlight(_ part: String, in text: String) -> StreamingText.Highlight {
        .init(range: (text as NSString).range(of: part), color: .green)
    }

    @Test("a highlight tints every word it overlaps")
    func highlights() {
        let text = "Coffee 2500 tenge"
        let words = words(text, highlights: [highlight("2500", in: text)])
        #expect(words.map(\.text) == ["Coffee", "2500", "tenge"])
        #expect(words[1].color == .green)
        #expect(words[0].color != .green)
    }

    @Test(
        "every script shows exactly its characters, with a gap only where the text has a space",
        arguments: [
            "Coffee, 2500 tenge. Taxi?",
            "Сколько я потратил? «Кофе», 2500 тенге.",
            "コンビニで500円使った。",
            "「楽しい」と思った。タクシーに1,800円払った！",
            "Suicaで 1,200円 払った",
            "점심 12,000원 썼어?",
            "我花了50块钱。",
            "กินข้าว 100 บาท",
            "Coffee ☕️ 2500 ₸",
        ]
    )
    func rendersEveryCharacter(text: String) {
        #expect(rendered(words(text)) == text)
    }

    @Test("punctuation stays with its word")
    func punctuation() {
        #expect(words("\"Coffee,\" she said. 2500?").map(\.text) == ["\"Coffee,\"", "she", "said.", "2500?"])
        #expect(words("Сколько я потратил?").map(\.text) == ["Сколько", "я", "потратил?"])
        #expect(words("Сколько я потратил?").allSatisfy { !$0.joinsPrevious })
    }

    @Test("a Korean number keeps its counter word, and a highlight tints the whole word")
    func korean() {
        let text = "점심 12,000원 썼어?"
        let words = words(text, highlights: [highlight("12,000", in: text)])
        #expect(words.map(\.text) == ["점심", "12,000원", "썼어?"])
        #expect(words.allSatisfy { !$0.joinsPrevious })
        #expect(words.map { $0.color == .green } == [false, true, false])
    }

    @Test("Japanese is cut into words that join without a gap, so a long line can wrap")
    func japanese() {
        let text = "コンビニで500円使った。"
        let words = words(text, highlights: [highlight("500円", in: text)])
        #expect(words.count > 1)
        #expect(words.first?.joinsPrevious == false)
        #expect(words.dropFirst().allSatisfy { $0.joinsPrevious })
        #expect(words.first?.text.hasPrefix("コンビニ") == true)
        // The full stop closes the last word; a line never starts with it.
        #expect(words.last?.text.hasSuffix("。") == true)
        #expect(words.allSatisfy { !$0.text.hasPrefix("。") })
        // The tinted words are exactly the ones that make up "500円".
        #expect(words.filter { $0.color == .green }.map(\.text).joined() == "500円")
    }

    @Test("an opening bracket goes with the word after it, a closing one with the word before")
    func japaneseBrackets() {
        let words = words("「楽しい」と思った。").map(\.text)
        #expect(words.first?.hasPrefix("「楽し") == true)
        #expect(words.contains { $0.hasSuffix("」") })
        #expect(words.allSatisfy { !$0.hasSuffix("「") && !$0.hasPrefix("」") && !$0.hasPrefix("。") })
    }

    @Test("a space between Japanese words is a gap, and the word after it starts a new run")
    func japaneseWithSpaces() {
        let words = words("Suicaで 1,200円 払った")
        #expect(words.first?.text == "Suica")
        let runStarts = words.filter { !$0.joinsPrevious }.map(\.text)
        #expect(runStarts.count == 3)
        #expect(runStarts.first == "Suica")
    }

    @Test("a no-break space stays inside the word; any run of spaces and new lines is one gap")
    func spaces() {
        #expect(words("2\u{00A0}500 ₸").map(\.text) == ["2\u{00A0}500", "₸"])
        #expect(words("  Coffee \n\n tenge  ").map(\.text) == ["Coffee", "tenge"])
        #expect(words(" \n ").isEmpty)
        #expect(words("").isEmpty)
    }

    @Test("a refinement keeps the words already shown and adds new identities")
    func reconcileKeepsIdentities() {
        let first = StreamingText.reconcile(
            previous: [],
            words: StreamingText.words(in: "Coffee two", highlights: []),
            nextID: 0
        )
        #expect(first.tokens.map(\.id) == [0, 1])
        let refined = StreamingText.reconcile(
            previous: first.tokens,
            words: StreamingText.words(in: "Coffee 2500 tenge", highlights: []),
            nextID: first.nextID
        )
        // "Coffee" stays; "two" became "2500", a new word; "tenge" is new.
        #expect(refined.tokens.map(\.id) == [0, 2, 3])
        #expect(refined.nextID == 4)
    }

    @Test("a word that only gains punctuation keeps its identity; a changed word does not")
    func reconcileKeepsIdentityWithPunctuation() {
        let first = StreamingText.reconcile(previous: [], words: words("Сколько я потратил"), nextID: 0)
        let punctuated = StreamingText.reconcile(previous: first.tokens, words: words("Сколько я потратил?"), nextID: first.nextID)
        #expect(punctuated.tokens.map(\.id) == [0, 1, 2])
        #expect(punctuated.tokens.last?.text == "потратил?")
        let changed = StreamingText.reconcile(previous: punctuated.tokens, words: words("Сколько я потратила?"), nextID: punctuated.nextID)
        #expect(changed.tokens.map(\.id) == [0, 1, 3])
        let mark = StreamingText.reconcile(previous: [], words: words("?"), nextID: 0)
        #expect(StreamingText.reconcile(previous: mark.tokens, words: words("!"), nextID: mark.nextID).tokens.map(\.id) == [1])
    }

    @Test("a word that only joins or leaves its neighbour keeps its identity")
    func reconcileKeepsIdentityWhenJoining() {
        let primary = Color.primary
        let first = StreamingText.reconcile(
            previous: [],
            words: [.init(text: "東京", color: primary, joinsPrevious: false), .init(text: "タワー", color: primary, joinsPrevious: false)],
            nextID: 0
        )
        let joined = StreamingText.reconcile(
            previous: first.tokens,
            words: [.init(text: "東京", color: primary, joinsPrevious: false), .init(text: "タワー", color: primary, joinsPrevious: true)],
            nextID: first.nextID
        )
        #expect(joined.tokens.map(\.id) == [0, 1])
        #expect(joined.tokens.map(\.joinsPrevious) == [false, true])
        #expect(joined.nextID == 2)
    }

    @Test("the pager stops at either end")
    func pagerSteps() {
        #expect(PagerArrows<EmptyView>.stepped(0, by: -1, count: 3) == nil)
        #expect(PagerArrows<EmptyView>.stepped(0, by: 1, count: 3) == 1)
        #expect(PagerArrows<EmptyView>.stepped(2, by: 1, count: 3) == nil)
    }
}
