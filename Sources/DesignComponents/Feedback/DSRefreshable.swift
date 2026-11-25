//
//  DSRefreshable.swift
//  DesignKit
//
//  vNext: pull to refresh with DesignKit's mercury, in every app. The system's `.refreshable`
//  does the work (the trigger, holding the content while loading, the haptic, VoiceOver, ⌘R on
//  a Mac); its spinner is hidden, and `RefreshIndicator` draws over the scroll view from the
//  pull (`onScrollGeometryChange`) and the action's progress (`RefreshPhaseClock`).
//

import SwiftUI
import UIKit
import DesignTokens

public extension View {
    /// Pull to refresh with DesignKit's mercury (vNext): the same closure as `.refreshable`. Black
    /// liquid runs out of the Dynamic Island as the person pulls, turns the accent, breaks into
    /// beads that circle while `action` runs (at least 0.6 s) and flows back into the island.
    /// Without an island it runs from the top edge; under Reduce Motion an accent ring.
    ///
    /// Apply it to the `List` or `ScrollView` itself, not to a view around it:
    ///
    /// ```swift
    /// List(trips) { TripRow(trip: $0) }
    ///     .dsRefreshable { await store.reload() }
    /// ```
    ///
    /// The system's refresh spinner is hidden app-wide the first time it is used, so every pull
    /// to refresh in the app is this one (the apps' lint warns on `.refreshable`).
    func dsRefreshable(action: @escaping @Sendable () async -> Void) -> some View {
        modifier(DSRefreshableModifier(action: action))
    }
}

struct DSRefreshableModifier: ViewModifier {
    let action: @Sendable () async -> Void

    @State private var clock = RefreshPhaseClock()
    @State private var pull: CGFloat = 0
    /// Bumped when the flow back has ended, so the timeline pauses.
    @State private var settled = 0

    /// Hides the system's spinner once, in `body`: before the first refresh control exists, or
    /// the first screen would show it.
    @MainActor private static let hidesSystemSpinner: Void = {
        UIRefreshControl.appearance().tintColor = .clear
    }()

    func body(content: Content) -> some View {
        let _ = Self.hidesSystemSpinner
        let _ = settled
        content
            .refreshable {
                let begun = await MainActor.run { clock.start(at: .now) }
                guard begun else { return }
                await action()
                let until = await MainActor.run { clock.finishAt(returnedAt: .now) }
                let wait = until.timeIntervalSinceNow
                if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
                await MainActor.run { clock.finish(at: .now) }
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                // Only past the top: ordinary scrolling stays 0, so the action does not run on
                // every frame of it.
                max(0, -(geometry.contentOffset.y + geometry.contentInsets.top))
            } action: { _, newValue in
                pull = newValue
                clock.pull(pull, at: .now)
            }
            .overlay(alignment: .top) {
                TimelineView(.animation(paused: clock.isQuiet(at: .now, pull: pull))) { context in
                    RefreshIndicator(phase: clock.phase(at: context.date, pull: pull))
                }
                .frame(height: RefreshMetrics.overlayHeight)
                .ignoresSafeArea(.container, edges: .top)
            }
            .task(id: clock.finishStart) {
                guard clock.finishStart != nil else { return }
                try? await Task.sleep(for: .seconds(RefreshMetrics.finishing))
                settled &+= 1
            }
    }
}
