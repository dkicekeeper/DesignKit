# Mercury pull to refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `.dsRefreshable { await … }` replaces `.refreshable` in every app: the system's mechanics,
its spinner hidden, and over the scroll view a liquid that runs black out of the Dynamic Island,
turns the accent, breaks into six beads that circle while refreshing and flows back into the island.

**Architecture:** A pure geometry (`RefreshDropletGeometry`: phase, progress, time, source rect →
circles) and a pure island estimate (`DynamicIslandFrame`) carry all the logic and are unit
tested. `RefreshIndicator(phase:source:)` draws the circles: a `Canvas` with blur and alpha
threshold as a mask over a black-to-accent gradient. `.dsRefreshable` wraps `.refreshable`, reads
the pull from `onScrollGeometryChange`, keeps the phase and lays the indicator over the scroll view.

**Tech Stack:** Swift 5 mode, SwiftUI, iOS 26, swift-testing, swift-snapshot-testing, Python 3 (lint).

**Spec:** `docs/superpowers/specs/2026-11-25-colors-mercury-refresh-gallery-design.md` (part B).
The prototype the metrics come from: the proposals page's JS (https://claude.ai/artifact/A8pDYoYfZApwG5KuCRHVFT),
in CSS px of a 300 px phone; × 1.34 gives points on a 402 pt iPhone.

## Global Constraints

- Signature as the system's: `func dsRefreshable(action: @escaping @Sendable () async -> Void) -> some View`.
- One look in every app; colour `AppColors.accent`; black `#000000` down to the island's bottom,
  accent from the island's bottom + 18 pt; no island → all accent. No glow.
- Under the navigation bar: a plain `.overlay`, no window-level layer.
- On `\.heroTone == .onColor`: same colours, beads below the island's bottom + 6 pt get a shadow
  black 30 %, radius 4 pt, y 2 pt.
- Reduce Motion: an accent ring 18 pt wide, filling with the pull, spinning while refreshing.
- Shown at least 0.6 s; finishing lasts 1.0 s; no timeline while idle with no pull.
- Lint rule `system-refreshable` is a warning now (`::warning`, not counted in failures or the baseline).
- Release note `.changes/focused-noether-pwdn1m-2026-11-25-refresh.md`, `bump: minor`; `since: "vNext"`.

## Review Focus

1. The system spinner still showing on the first screen: `UIRefreshControl.appearance().tintColor
   = .clear` must run before the first `UIRefreshControl` exists, i.e. in the modifier's `body`,
   not `onAppear`. Checked on the Gallery page in TestFlight; noted in the Gallery page's usage.
2. A scroll view that is not at the top of the screen (a sheet, below a header): no island, the
   source is the overlay's top edge — `DynamicIslandFrameTests.notAtScreenTop`.
3. Landscape on an island iPhone: no island — `DynamicIslandFrameTests.landscape`.
4. The action returns in 50 ms: the beads still circle 0.6 s, then finish — `RefreshPhaseClockTests.minimumShowing`.
5. A second pull while refreshing or finishing does not start a second action: the system does not
   call `refreshable` again while one runs; the clock ignores a start while not idle —
   `RefreshPhaseClockTests.noRestartWhileBusy`.

---

### Task 1: Island frame and droplet geometry (pure, tested)

**Files:**
- Create: `Sources/DesignComponents/Feedback/RefreshDropletGeometry.swift` (also `DynamicIslandFrame`, `RefreshMetrics`)
- Test: `Tests/DesignComponentsTests/RefreshDropletGeometryTests.swift` (`@testable import DesignComponents`)

**Interfaces:**
- Produces:
  - `enum DynamicIslandFrame { static func frame(safeAreaTop: CGFloat, screenWidth: CGFloat, isPhone: Bool, isPortrait: Bool, overlayMinY: CGFloat) -> CGRect? }`
  - `struct DropletCircle: Equatable { var center: CGPoint; var radius: CGFloat }`
  - `enum RefreshDropletGeometry { static func circles(for phase: RefreshIndicator.Phase, source: CGRect, width: CGFloat) -> [DropletCircle] }` — the source blob is not in the list; `source.maxY` is where the liquid leaves it.
  - `enum RefreshMetrics` (internal constants below).

- [ ] **Step 1: Failing tests**
  - `islandOnPhones`: top 59, width 393, phone, portrait, minY 0 → `CGRect(x: 133.5, y: 11, width: 126, height: 37)`; top 62, width 402 → `y: 14`, `x: 138`.
  - `noIslandOnNotchOrHomeButton`: top 47 → nil; top 20 → nil.
  - `landscape`: `isPortrait: false` → nil. `notAtScreenTop`: `overlayMinY: 120` → nil. iPad (`isPhone: false`) → nil.
  - `idleDrawsNothing`: `.idle` and `.pulling(progress: 0)` → every radius 0.
  - `pullStretchesWithoutBreaking`: `.pulling(progress: 1, elapsed: 0)` → the 8 neck circles all have radius > 0 (the thread breaks only when refreshing starts).
  - `refreshingCircles`: `.refreshing(elapsed: 1)` → exactly 6 beads of radius 7 whose centres are 16 × (1 ± 0.24) pt from a centre at `source.maxY + 40`.
  - `finishingEndsInTheSource`: `.finishing(elapsed: 1.05)` → every circle has radius 0 or a centre inside `source.insetBy(dx: 0, dy: -4)`.
  - `radiiNeverNegative`: for progress 0…1 step 0.05 and elapsed 0…1.2 step 0.05 in each phase, every radius ≥ 0.
- [ ] **Step 2: Push; RED on CI** (missing types).
- [ ] **Step 3: Implement.** `RefreshIndicator.Phase` is declared here as `public enum Phase: Equatable, Sendable { case idle; case pulling(progress: Double, elapsed: TimeInterval = 0); case refreshing(elapsed: TimeInterval); case finishing(elapsed: TimeInterval) }` in an `extension RefreshIndicator` once Task 2's struct exists — until then a placeholder `public struct RefreshIndicator {}` in this file, replaced in Task 2. Metrics (points): island 126 × 37, top = safe area − 48, island when `safeAreaTop >= 54`; neck 8 circles, drop centre `source.maxY + 5 + p·59`, drop radius `p < 0.02 ? 0 : 4 + p·14`, neck top radius `lerp(12, 8, p)·0.72`, bottom `dropR·0.8`, waist `1 − p²·0.82·sin(π f)`; pool `dropR·0.75 + min(4, 0.47 · landed drips)`; drips from elapsed 0.25 s every 0.21 s, radius `5.2 + 1.5·fract(sin(k·12.9898)·43758.5453)`, `y = source.maxY + 3 + 54τ + 938τ²`, removed on landing; refreshing: neck slides to `source.maxY − 13` and shrinks over 0.3 s, centre eases from `source.maxY + 64` to `+ 40`, ring radius `16·(1 − e^(−6.5t)(cos 10.4t + 0.625 sin 10.4t))·(1 + 0.24 sin(t/0.26))`, beads radius 7 at angle `t/0.36 + i·2π/6`, core radius `max(0, 10.7 − R·0.7)`; finishing: ring radius to 0 over 0.3 s, core grows to 12, after 0.3 s the centre rises to `source.minY + source.height/2` over 0.4 s while radii shrink to 0 by 1.0 s. `RefreshMetrics.triggerDistance = 110` (tuned on a device), `minimumShowing = 0.6`, `finishing = 1.0`, `gradientRun = 18`, `shadow = (0.3, 4, 2)`, `reduceMotionRing = 18`.
- [ ] **Step 4: Push; GREEN on CI.** Commit — "Refresh droplet geometry and the island's frame".

### Task 2: `RefreshIndicator` (drawing) with snapshots

**Files:**
- Create: `Sources/DesignComponents/Feedback/RefreshIndicator.swift`
- Modify: `Sources/DesignComponents/Feedback/RefreshDropletGeometry.swift` (drop the placeholder)
- Test: `Gallery/SnapshotTests/FeedbackSnapshotTests.swift` (`refreshIndicator`)

**Interfaces:**
- Consumes: `RefreshDropletGeometry.circles`, `DynamicIslandFrame.frame`, `RefreshMetrics`.
- Produces: `public struct RefreshIndicator: View { public enum Source: Hashable, Sendable { case automatic, island, topEdge }; public init(phase: Phase, source: Source = .automatic) }` — `.automatic` asks `DynamicIslandFrame` (safe area and global frame from a `GeometryReader`; no `UIApplication`, DesignKit builds for extensions); `.island` uses the 59 pt frame centred; `.topEdge` uses a 150 × 40 pt rect above the top.

- [ ] **Step 1: Snapshot test** `refreshIndicator`, width 360, height 140, light and dark: `pulling-half` (`.pulling(progress: 0.5, elapsed: 0.6)`, `.island`), `pulling-full` (`progress: 0.95`), `refreshing` (`.refreshing(elapsed: 0.4)`, `.island`), `top-edge` (`.refreshing(elapsed: 0.4)`, `.topEdge`), `on-colour` (`.refreshing(elapsed: 0.4)`, `.island`, on `AppColors.accent` with `.environment(\.heroTone, .onColor)`), `reduce-motion` (`.refreshing(elapsed: 0.4)` with `.environment(\.accessibilityReduceMotion, true)` if the environment key is settable; otherwise an internal `reducesMotion` init parameter used only by the snapshot via `@testable`).
- [ ] **Step 2: Push; RED** — snapshot job fails on six missing references.
- [ ] **Step 3: Implement** — the island rect is drawn as the source blob (it widens by `1 + 0.12·e^(−8s)·sin(14s)` for `s` seconds after the core reaches it while finishing); `Canvas` layer: `.alphaThreshold(min: 0.5)` then `.blur(radius: 6)` over black circles; that canvas masks a `LinearGradient` (black to the island's bottom, accent from bottom + 18); on colour, a copy of the mask filled black 30 %, blurred 4, offset 2, clipped to `y > source.maxY + 6`, under it; Reduce Motion draws the ring instead. `.accessibilityHidden(true)`; `.allowsHitTesting(false)`.
- [ ] **Step 4: Record** `missing`, then a `never` run green; look at the 12 PNGs. Commit — "RefreshIndicator: mercury out of the island".

### Task 3: `.dsRefreshable`

**Files:**
- Create: `Sources/DesignComponents/Feedback/DSRefreshable.swift` (modifier and `RefreshPhaseClock`)
- Test: `Tests/DesignComponentsTests/RefreshPhaseClockTests.swift`

**Interfaces:**
- Consumes: `RefreshIndicator`, `RefreshMetrics`.
- Produces: `public extension View { func dsRefreshable(action: @escaping @Sendable () async -> Void) -> some View }`; internal `struct RefreshPhaseClock { mutating func start(at: Date) -> Bool; func finishAt(returnedAt: Date) -> Date; func phase(at: Date, pull: CGFloat) -> RefreshIndicator.Phase }`.

- [ ] **Step 1: Failing tests** — `minimumShowing` (start t0, action returns t0 + 0.05 → `finishAt == t0 + 0.6`; at t0 + 0.3 the phase is `.refreshing(elapsed: 0.3)`); `noRestartWhileBusy` (`start` returns false while refreshing or finishing); `pullBecomesProgress` (idle, pull 55 → `.pulling(progress: 0.5, …)`, pull 300 → progress 1); `finishingThenIdle` (at finishAt + 1.0 → `.idle`).
- [ ] **Step 2: Push; RED.**
- [ ] **Step 3: Implement** — modifier body: `let _ = Self.hidesSystemSpinner` (a `static let` closure setting `UIRefreshControl.appearance().tintColor = .clear`), then `content.refreshable { … clock.start; await action(); wait until finishAt … }`, `.onScrollGeometryChange(for: CGFloat.self) { -($0.contentOffset.y + $0.contentInsets.top) }`, `.overlay(alignment: .top) { TimelineView(.animation(paused: idle && pull <= 0)) { RefreshIndicator(phase: clock.phase(at: $0.date, pull: pull)) } }` ignoring the top safe area. Doc comment: apply it to the `List` / `ScrollView` itself.
- [ ] **Step 4: Push; GREEN.** Commit — "dsRefreshable: the system's refresh with mercury over it".

### Task 4: Gallery page, lint warning, docs, note

**Files:**
- Modify: `Gallery/Gallery/Screens/FeedbackScreen.swift` (a `ComponentPage` "dsRefreshable": live `List` of 12 rows with `.dsRefreshable` waiting 1.5 s and counting refreshes; controls: phase `ChoiceControl` (Pulling / Refreshing / Finishing), progress `SliderControl` 0…1, source `ChoiceControl` (Automatic / Island / Top edge); `since: "vNext"`, `apps: []`; `dos` "Apply it to the List or ScrollView itself", `donts` "Don't use the system .refreshable")
- Modify: `scripts/designkit_lint.py` (warning rules: `system-refreshable`, `\.refreshable\s*[({]`; printed as `::warning`, not in failures, not in the baseline)
- Modify: `scripts/test_designkit_lint.py` (`test_refreshable_is_a_warning`: code with `.refreshable {` → exit 0 and `::warning` with `design-lint system-refreshable` in the text)
- Modify: `scripts/migrations/9.0.0.json` (rewrite `\.refreshable\s*\{` → `.dsRefreshable {`; created in the colours plan, or here if that has not merged)
- Modify: `docs/design-system.md` (Feedback: `.dsRefreshable`, `RefreshIndicator`), `docs/motion.md` §6 (the effect, its budget, Reduce Motion), `docs/agents.md` (rule: pull to refresh is `.dsRefreshable`), `docs/gallery-structure.md` (Feedback list), `docs/snapshots.md` (FeedbackSnapshotTests row)
- Create: `.changes/focused-noether-pwdn1m-2026-11-25-refresh.md`

- [ ] **Step 1: Failing lint test** — Run: `python3 scripts/test_designkit_lint.py -k refreshable`. Expected: FAIL (no warning printed).
- [ ] **Step 2: Implement the warning rule**; Run the same. Expected: PASS; then `python3 scripts/test_designkit_lint.py` all pass.
- [ ] **Step 3: Page, docs, note**; Run: `python3 .github/scripts/release.py check --base origin/main`, `python3 .github/scripts/components_reference.py build`. Expected: pass; the reference lists `dsRefreshable`.
- [ ] **Step 4: Push; CI green** (Gallery pages snapshot re-recorded if the Feedback screen's pages test covers it). Commit — "Gallery page, lint warning and docs for dsRefreshable".
