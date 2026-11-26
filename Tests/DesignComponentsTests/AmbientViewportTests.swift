//
//  AmbientViewportTests.swift
//  DesignKit
//
//  8.22.0: an ambient loop stops while scrolled well out of sight. vNext: a view with no size
//  gives no answer, so content that draws nothing while stopped cannot start and stop it again
//  in the same layout pass (Platina's screens hung on a skeleton's shimmer).
//

import CoreGraphics
import Testing
@testable import DesignTokens

@Suite("Ambient viewport")
struct AmbientViewportTests {
    private let card = CGSize(width: 300, height: 100)

    @Test("Without a size there is no answer", arguments: [
        CGSize.zero, CGSize(width: 300, height: 0), CGSize(width: 0, height: 100),
    ])
    func noSizeNoAnswer(size: CGSize) {
        let visible = CGRect(x: 0, y: 2000, width: 400, height: 800)
        #expect(AmbientViewport.isNear(size: size, vertical: visible, horizontal: nil) == nil)
        #expect(AmbientViewport.isNear(size: size, vertical: nil, horizontal: nil) == nil)
    }

    @Test("Outside a scroll view a view is near")
    func noScrollView() {
        #expect(AmbientViewport.isNear(size: card, vertical: nil, horizontal: nil) == true)
    }

    @Test("In sight, and within half a viewport of it, a view is near")
    func inSight() {
        let visible = CGRect(x: 0, y: 0, width: 400, height: 800)
        #expect(AmbientViewport.isNear(size: card, vertical: visible, horizontal: nil) == true)
        // The view's top is 300 pt below the visible part, inside the margin of 400 pt.
        let below = CGRect(x: 0, y: -1100, width: 400, height: 800)
        #expect(AmbientViewport.isNear(size: card, vertical: below, horizontal: nil) == true)
    }

    @Test("More than half a viewport out of sight, down or across, a view is far")
    func farOut() {
        let above = CGRect(x: 0, y: 1000, width: 400, height: 800)
        #expect(AmbientViewport.isNear(size: card, vertical: above, horizontal: nil) == false)
        let below = CGRect(x: 0, y: -1400, width: 400, height: 800)
        #expect(AmbientViewport.isNear(size: card, vertical: below, horizontal: nil) == false)
        let across = CGRect(x: 1000, y: 0, width: 400, height: 100)
        #expect(AmbientViewport.isNear(size: card, vertical: nil, horizontal: across) == false)
    }

    @Test("Out of sight in any scroll view round it, a view is far")
    func nested() {
        let page = CGRect(x: 0, y: 3000, width: 400, height: 800)
        let carousel = CGRect(x: 0, y: 0, width: 400, height: 100)
        #expect(AmbientViewport.isNear(size: card, vertical: page, horizontal: carousel) == false)
        #expect(AmbientViewport.isNear(size: card, vertical: .init(x: 0, y: 0, width: 400, height: 800),
                                       horizontal: carousel) == true)
    }
}
