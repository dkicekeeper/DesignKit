//
//  RefreshDropletGeometryTests.swift
//  DesignKit
//
//  vNext: the mercury of `.dsRefreshable` is a pure function of its phase and the source it
//  runs out of (the Dynamic Island, or the top edge), so its shape is pinned here.
//

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
import Testing
@testable import DesignComponents

@Suite("Refresh droplets")
struct RefreshDropletGeometryTests {
    /// The island of a 393 pt iPhone (safe area 59).
    private let island = CGRect(x: 133.5, y: 11, width: 126, height: 37)

    // MARK: The island's frame

    @Test("Island phones: 126 × 37 pt, centred, 48 pt above the safe area's top")
    func islandOnPhones() {
        #expect(DynamicIslandFrame.frame(safeAreaTop: 59, screenWidth: 393, isPhone: true, isPortrait: true, overlayMinY: 0)
                == CGRect(x: 133.5, y: 11, width: 126, height: 37))
        #expect(DynamicIslandFrame.frame(safeAreaTop: 62, screenWidth: 402, isPhone: true, isPortrait: true, overlayMinY: 0)
                == CGRect(x: 138, y: 14, width: 126, height: 37))
    }

    @Test("No island under a notch or with a home button")
    func noIslandOnNotchOrHomeButton() {
        #expect(DynamicIslandFrame.frame(safeAreaTop: 47, screenWidth: 390, isPhone: true, isPortrait: true, overlayMinY: 0) == nil)
        #expect(DynamicIslandFrame.frame(safeAreaTop: 20, screenWidth: 375, isPhone: true, isPortrait: true, overlayMinY: 0) == nil)
    }

    @Test("No island in landscape")
    func landscape() {
        #expect(DynamicIslandFrame.frame(safeAreaTop: 0, screenWidth: 852, isPhone: true, isPortrait: false, overlayMinY: 0) == nil)
        #expect(DynamicIslandFrame.frame(safeAreaTop: 59, screenWidth: 852, isPhone: true, isPortrait: false, overlayMinY: 0) == nil)
    }

    @Test("No island when the scroll view is not at the screen's top (a sheet, under a header)")
    func notAtScreenTop() {
        #expect(DynamicIslandFrame.frame(safeAreaTop: 59, screenWidth: 393, isPhone: true, isPortrait: true, overlayMinY: 120) == nil)
    }

    @Test("No island on an iPad or a Mac")
    func notOnAPad() {
        #expect(DynamicIslandFrame.frame(safeAreaTop: 24, screenWidth: 1024, isPhone: false, isPortrait: true, overlayMinY: 0) == nil)
    }

    // MARK: The droplets

    @Test("Idle and an untouched pull draw nothing")
    func idleDrawsNothing() {
        for phase in [RefreshPhase.idle, .pulling(progress: 0, elapsed: 0)] {
            let frame = RefreshDropletGeometry.frame(for: phase, source: island)
            #expect(frame.all.allSatisfy { $0.radius == 0 }, "\(phase)")
        }
    }

    @Test("A full pull stretches the thread without breaking it: refreshing breaks it")
    func pullStretchesWithoutBreaking() {
        let frame = RefreshDropletGeometry.frame(for: .pulling(progress: 1, elapsed: 0), source: island)
        #expect(frame.neck.count == 8)
        #expect(frame.neck.allSatisfy { $0.radius >= RefreshMetrics.unbrokenNeck }, "\(frame.neck.map(\.radius))")
        #expect(frame.drop.radius > 0)
    }

    @Test("Drips fall from the island while pulling and join the pool")
    func dripsFall() {
        let early = RefreshDropletGeometry.frame(for: .pulling(progress: 0.6, elapsed: 0.1), source: island)
        #expect(early.drips.allSatisfy { $0.radius == 0 })
        let later = RefreshDropletGeometry.frame(for: .pulling(progress: 0.6, elapsed: 0.3), source: island)
        #expect(later.drips.contains { $0.radius > 0 && $0.center.y > island.maxY && $0.center.y < later.drop.center.y })
    }

    @Test("Refreshing: six beads of 7 pt circling 40 pt under the island")
    func refreshingCircles() {
        let frame = RefreshDropletGeometry.frame(for: .refreshing(elapsed: 1), source: island)
        let centre = CGPoint(x: island.midX, y: island.maxY + 40)
        #expect(frame.beads.count == 6)
        for bead in frame.beads {
            #expect(bead.radius == 7)
            let distance = hypot(bead.center.x - centre.x, bead.center.y - centre.y)
            #expect(distance >= 16 * 0.76 - 0.1 && distance <= 16 * 1.24 + 0.1, "\(distance)")
        }
        #expect(frame.neck.allSatisfy { $0.radius == 0 })
    }

    @Test("Finishing ends inside the island")
    func finishingEndsInTheSource() {
        let frame = RefreshDropletGeometry.frame(for: .finishing(elapsed: 1.05), source: island)
        for circle in frame.all where circle.radius > 0 {
            #expect(island.insetBy(dx: 0, dy: -4).contains(circle.center), "\(circle)")
        }
    }

    @Test("No radius is ever negative")
    func radiiNeverNegative() {
        var phases: [RefreshPhase] = []
        for step in 0...20 {
            let p = Double(step) / 20
            for t in stride(from: 0.0, through: 1.2, by: 0.05) {
                phases.append(.pulling(progress: p, elapsed: t))
            }
        }
        for t in stride(from: 0.0, through: 1.2, by: 0.05) {
            phases.append(.refreshing(elapsed: t))
            phases.append(.finishing(elapsed: t))
        }
        for phase in phases {
            let frame = RefreshDropletGeometry.frame(for: phase, source: island)
            #expect(frame.all.allSatisfy { $0.radius >= 0 && $0.radius.isFinite }, "\(phase)")
        }
    }

    @Test("The source springs when the mercury flows back in, then settles")
    func sourceSprings() {
        #expect(RefreshDropletGeometry.frame(for: .finishing(elapsed: 0.5), source: island).sourceScale == 1)
        #expect(RefreshDropletGeometry.frame(for: .finishing(elapsed: 0.8), source: island).sourceScale != 1)
        #expect(abs(RefreshDropletGeometry.frame(for: .finishing(elapsed: 1.6), source: island).sourceScale - 1) < 0.01)
    }
}
