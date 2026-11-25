---
bump: minor
---
Pull to refresh with mercury: `.dsRefreshable` replaces the system's `.refreshable` in every app, with black liquid that runs out of the Dynamic Island and turns the accent.

### Added
- `.dsRefreshable(action:)`: pull to refresh with the same closure as `.refreshable`, on the `List` or `ScrollView` itself. The system's refresh does the work (the trigger, holding the content, the haptic, VoiceOver) and its spinner is hidden app-wide; over the scroll view black liquid runs out of the Dynamic Island as the person pulls, turns the accent, breaks into six beads that circle while the action runs (at least 0.6 s) and flows back into the island. From the top edge, all accent, where there is no island; a soft shadow under the beads on a coloured hero; an accent ring under Reduce Motion.
- `RefreshIndicator(phase:source:)` and `RefreshPhase`: the mercury in a fixed phase, from the island or the top edge.

### Migration
- Replace `.refreshable { … }` with `.dsRefreshable { … }`, the same closure, on the list or scroll view itself. The apps' lint warns on `.refreshable` from this version (`system-refreshable`); it becomes an error in 9.0.0, whose rewrites change it (`scripts/migrations/9.0.0.json`).

```swift
List(trips) { TripRow(trip: $0) }
    .dsRefreshable { await store.reload() }
```

### Gallery and tooling
- A page in Status & Feedback: a live list to pull, and the indicator in a phase you pick. Snapshots of six phases (`FeedbackSnapshotTests.refreshIndicator`).
- `scripts/designkit_lint.py` has warnings: reported as GitHub annotations, never counted in the failures or the baseline. The first is `system-refreshable`.
- Unit tests of the droplets' geometry, the island's frame and the phase clock.
