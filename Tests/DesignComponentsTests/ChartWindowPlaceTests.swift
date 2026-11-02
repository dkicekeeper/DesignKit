//
//  ChartWindowPlaceTests.swift
//  DesignComponentsTests
//
//  Pins where a chart that follows the scroll stands (8.4.3 / 8.5.0): the point under the
//  ruler and the leading category, from the scroll's exact offset. Numbers measured on the
//  simulator: 34 categories (5 empty, 24 points, 5 empty) over 955 pt of content.
//

import Testing
import CoreGraphics
@testable import DesignComponents

struct ChartWindowPlaceTests {

    private let window = ChartWindow(
        labels: (0..<24).map { "m\($0)" },
        centerIndex: 23,
        zoomScale: 1,
        followsScroll: true
    )

    @Test("The window opens with the last point under the ruler, at Swift Charts' own offset")
    func opening() {
        #expect(window.categories.count == 34)
        let place = window.place(of: ChartScrollSpot(offset: 646, contentWidth: 955))
        #expect(place.centerIndex == 23)
        #expect(place.leadingLabel == window.categories[23])
    }

    @Test("At rest on a boundary the leading category is the one after it, not the one before")
    func restOnBoundary() {
        let period = 955.0 / 34
        let place = window.place(of: ChartScrollSpot(offset: 12 * period - 0.2, contentWidth: 955))
        #expect(place.centerIndex == 12)
        #expect(place.leadingLabel == window.categories[12])
    }

    @Test("Mid-scroll the ruler's point is the nearest one")
    func midScroll() {
        let period = 955.0 / 34
        #expect(window.place(of: ChartScrollSpot(offset: 8.4 * period, contentWidth: 955)).centerIndex == 8)
        #expect(window.place(of: ChartScrollSpot(offset: 8.6 * period, contentWidth: 955)).centerIndex == 9)
    }

    @Test("The first point at the start; past the points nothing is under the ruler")
    func pastThePoints() {
        #expect(window.place(of: ChartScrollSpot(offset: 0, contentWidth: 955)).centerIndex == 0)
        #expect(window.place(of: ChartScrollSpot(offset: -200, contentWidth: 955)).centerIndex == nil)
        #expect(window.place(of: ChartScrollSpot(offset: 0, contentWidth: 0)).centerIndex == nil)
    }
}
