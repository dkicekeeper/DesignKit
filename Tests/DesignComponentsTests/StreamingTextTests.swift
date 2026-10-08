//
//  StreamingTextTests.swift
//  DesignKit
//
//  How StreamingText splits and keeps its words (2.9.0, from Tenra's AnimatedTranscriptionText),
//  and how PagerArrows steps.
//

import Foundation
import SwiftUI
import Testing
@testable import DesignComponents

@MainActor
@Suite("Streaming text")
struct StreamingTextTests {
    @Test("a highlight tints every word it overlaps")
    func highlights() {
        let text = "Coffee 2500 tenge"
        let range = (text as NSString).range(of: "2500")
        let words = StreamingText.words(in: text, highlights: [.init(range: range, color: .green)])
        #expect(words.map(\.text) == ["Coffee", "2500", "tenge"])
        #expect(words[1].color == .green)
        #expect(words[0].color != .green)
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

    @Test("the pager stops at either end")
    func pagerSteps() {
        #expect(PagerArrows<EmptyView>.stepped(0, by: -1, count: 3) == nil)
        #expect(PagerArrows<EmptyView>.stepped(0, by: 1, count: 3) == 1)
        #expect(PagerArrows<EmptyView>.stepped(2, by: 1, count: 3) == nil)
    }
}
