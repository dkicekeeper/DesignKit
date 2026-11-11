//
//  ArticleMarkdownTests.swift
//  DesignKit
//
//  ArticleBody.Block.parse(markdown:) (8.9.0): which blocks plain Markdown becomes.
//

import Testing
@testable import DesignComponents

struct ArticleMarkdownTests {
    @Test func headingsParagraphsAndLists() {
        let blocks = ArticleBody.Block.parse(markdown: """
        # Budget
        You spent **42,300 ₸**.
        Most of it on cafés.

        - Coffee
        * Lunch out
        1. Open Budgets
        2) Pick October
        ### Details
        > Recomputed nightly.
        > From your cards.
        """)
        #expect(blocks == [
            .heading("Budget", level: 2),
            .paragraph("You spent **42,300 ₸**.\nMost of it on cafés."),
            .bullets(["Coffee", "Lunch out"]),
            .steps(["Open Budgets", "Pick October"]),
            .heading("Details", level: 3),
            .note("Recomputed nightly.\nFrom your cards."),
        ])
    }

    @Test func textAfterAListStartsAParagraph() {
        let blocks = ArticleBody.Block.parse(markdown: "- One\n- Two\nAnd then")
        #expect(blocks == [.bullets(["One", "Two"]), .paragraph("And then")])
    }

    @Test func notMarkdownStaysAParagraph() {
        #expect(ArticleBody.Block.parse(markdown: "#hashtag 2024.5 -dash") == [.paragraph("#hashtag 2024.5 -dash")])
        #expect(ArticleBody.Block.parse(markdown: "\n\n").isEmpty)
    }
}
