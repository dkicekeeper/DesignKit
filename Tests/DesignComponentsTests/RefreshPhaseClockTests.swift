//
//  RefreshPhaseClockTests.swift
//  DesignKit
//
//  8.21.0: which phase `.dsRefreshable` draws when: the pull becomes progress, the beads circle
//  at least 0.6 s, a second pull while busy starts nothing, and the flow back lasts 1 s.
//

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
import Testing
@testable import DesignComponents

@Suite("Refresh phase clock")
struct RefreshPhaseClockTests {
    private let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)

    private func elapsed(_ phase: RefreshPhase) -> TimeInterval? {
        switch phase {
        case .idle: return nil
        case .pulling(_, let elapsed), .refreshing(let elapsed), .finishing(let elapsed): return elapsed
        }
    }

    @Test("A fast answer still shows the beads for 0.6 s")
    func minimumShowing() {
        var clock = RefreshPhaseClock()
        let started1 = clock.start(at: t0)
        #expect(started1)
        #expect(clock.finishAt(returnedAt: t0.addingTimeInterval(0.05)) == t0.addingTimeInterval(0.6))
        #expect(clock.finishAt(returnedAt: t0.addingTimeInterval(2)) == t0.addingTimeInterval(2))
        let phase = clock.phase(at: t0.addingTimeInterval(0.3), pull: 0)
        guard case .refreshing = phase else { Issue.record("\(phase)"); return }
        #expect(abs((elapsed(phase) ?? 0) - 0.3) < 0.001)
    }

    @Test("A pull while refreshing or finishing starts nothing")
    func noRestartWhileBusy() {
        var clock = RefreshPhaseClock()
        let started2 = clock.start(at: t0)
        #expect(started2)
        let started3 = clock.start(at: t0.addingTimeInterval(0.1))
        #expect(!started3)
        clock.finish(at: t0.addingTimeInterval(0.7))
        let started4 = clock.start(at: t0.addingTimeInterval(0.8))
        #expect(!started4)
        let started5 = clock.start(at: t0.addingTimeInterval(1.8))
        #expect(started5)
    }

    @Test("While idle the pull is progress towards the trigger, with the time since it began")
    func pullBecomesProgress() {
        var clock = RefreshPhaseClock()
        #expect(clock.phase(at: t0, pull: 0) == .idle)
        clock.pull(55, at: t0)
        let half = clock.phase(at: t0.addingTimeInterval(0.2), pull: 55)
        guard case .pulling(let progress, let since) = half else { Issue.record("\(half)"); return }
        #expect(abs(progress - 0.5) < 0.001)
        #expect(abs(since - 0.2) < 0.001)
        clock.pull(300, at: t0.addingTimeInterval(0.3))
        guard case .pulling(let full, _) = clock.phase(at: t0.addingTimeInterval(0.3), pull: 300) else {
            Issue.record("not pulling"); return
        }
        #expect(full == 1)
        clock.pull(0, at: t0.addingTimeInterval(0.4))
        #expect(clock.phase(at: t0.addingTimeInterval(0.4), pull: 0) == .idle)
    }

    @Test("Finishing lasts a second, then idle")
    func finishingThenIdle() {
        var clock = RefreshPhaseClock()
        _ = clock.start(at: t0)
        let end = t0.addingTimeInterval(0.6)
        clock.finish(at: end)
        let mid = clock.phase(at: end.addingTimeInterval(0.5), pull: 0)
        guard case .finishing = mid else { Issue.record("\(mid)"); return }
        #expect(abs((elapsed(mid) ?? 0) - 0.5) < 0.001)
        #expect(clock.phase(at: end.addingTimeInterval(1.01), pull: 0) == .idle)
        #expect(clock.isQuiet(at: end.addingTimeInterval(1.01), pull: 0))
        #expect(!clock.isQuiet(at: end.addingTimeInterval(0.5), pull: 0))
    }
}
