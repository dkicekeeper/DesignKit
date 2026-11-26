//
//  RefreshPhaseClock.swift
//  DesignKit
//
//  8.21.0: which phase `.dsRefreshable` draws when. Foundation only, so it is tested without a
//  screen.
//

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// The times of a pull to refresh: when the pull began, when the refresh started and when it
/// finished. `phase(at:pull:)` turns them and the current pull into what `RefreshIndicator` draws.
struct RefreshPhaseClock: Equatable {
    private(set) var pullStart: Date?
    private(set) var refreshStart: Date?
    private(set) var finishStart: Date?

    /// The scroll view's pull (points past the top) changed.
    mutating func pull(_ pull: CGFloat, at date: Date) {
        if pull > 0 {
            if pullStart == nil { pullStart = date }
        } else {
            pullStart = nil
        }
    }

    /// The system started a refresh. False, and nothing changes, while one is still showing or
    /// flowing back: the action runs once.
    mutating func start(at date: Date) -> Bool {
        guard !isBusy(at: date) else { return false }
        refreshStart = date
        finishStart = nil
        return true
    }

    /// When the beads may stop: when the action returned, but not before they have shown for
    /// `RefreshMetrics.minimumShowing`.
    func finishAt(returnedAt date: Date) -> Date {
        guard let refreshStart else { return date }
        return max(date, refreshStart.addingTimeInterval(RefreshMetrics.minimumShowing))
    }

    /// The beads begin to flow back.
    mutating func finish(at date: Date) {
        finishStart = date
    }

    func phase(at date: Date, pull: CGFloat) -> RefreshPhase {
        if let refreshStart, finishStart == nil {
            return .refreshing(elapsed: date.timeIntervalSince(refreshStart))
        }
        if let finishStart, date.timeIntervalSince(finishStart) < RefreshMetrics.finishing {
            return .finishing(elapsed: max(0, date.timeIntervalSince(finishStart)))
        }
        guard pull > 0 else { return .idle }
        let progress = min(1, Double(pull / RefreshMetrics.triggerDistance))
        return .pulling(progress: progress, elapsed: pullStart.map { date.timeIntervalSince($0) } ?? 0)
    }

    /// Nothing to animate: no pull, no refresh, nothing flowing back.
    func isQuiet(at date: Date, pull: CGFloat) -> Bool {
        phase(at: date, pull: pull) == .idle
    }

    private func isBusy(at date: Date) -> Bool {
        guard refreshStart != nil else { return false }
        guard let finishStart else { return true }
        return date.timeIntervalSince(finishStart) < RefreshMetrics.finishing
    }
}
