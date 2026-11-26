# Rings on grey cards (`.surfaceBackground`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A knockout ring or disc (around an avatar, a calendar marker, a chart point, a gauge tick,
a transaction badge) is drawn in the colour of the surface it lies on, so a grey `.fill` card no
longer shows white rings.

**Architecture:** `cardStyle()`'s `CardSurface` marks its subtree as "on a card" in the
environment; a public computed `EnvironmentValues.surfaceBackground` resolves to the page colour,
or to the card's grey under `SurfaceStyle.fill`; a `ShapeStyle` `.surfaceBackground` reads it. The
knockouts in DesignComponents switch from `AppColors.Background.base` / `bgBase` to it. Values only
change on a `.fill` card, so Tenra (glass) does not change.

**Tech Stack:** Swift 5 mode, SwiftUI, iOS 26, swift-testing, swift-snapshot-testing (CI on macOS).

**Spec:** `docs/superpowers/specs/2026-11-25-colors-mercury-refresh-gallery-design.md` (part 0 and A1).

## Global Constraints

- Released on its own, first: `.changes/focused-noether-pwdn1m-2026-11-25-rings.md`. `bump: minor`,
  not `patch`: it adds public API, and docs/releasing.md lets `### Added` ship only in a minor
  (the spec's "patch" means "a small release of its own"). Sections in CLAUDE.md order, English,
  no em dash, `vNext` for the version.
- No public API removed or renamed; the only additions are `EnvironmentValues.surfaceBackground`
  (get-only) and the `ShapeStyle` `.surfaceBackground` (`SurfaceBackground`).
- Values: on the page and inside a glass card → `AppColors.Background.base`; inside a card under
  `SurfaceStyle.fill` → `AppColors.Background.neutral1` (the colour `CardSurface` draws).
- `HeroHalfGauge` keeps `color` when `tone == .onColor`; `HeroSparkline` keeps `.clear` when
  `onColor`.
- Linux has no SwiftUI: CI is the compiler; snapshots are recorded by a manual CI run with
  `record_snapshots: missing` (docs/snapshots.md).

## Review Focus

1. A `.fill` card inside a sheet in dark mode: the ring must be the card's raised grey, not the
   page's — guaranteed by resolving to the same token `CardSurface` draws (`neutral1`), no
   separate value; covered by `surfaceBackgroundFollowsCard`.
2. A glass subtree inside a `.fill` card (`.surfaceStyle(.glass)` on a glass card over a photo):
   ring is the page colour — covered by `surfaceBackgroundOnGlassCard`.
3. A `.fill` app's view outside any card (an avatar group on the page): page colour — covered by
   `surfaceBackgroundDefaultsToPage`.
4. `AvatarGroup`'s "+N" disc overlapping an avatar must stay opaque: its ring changes, its fill
   (`.surfaceNeutral2`) does not — checked in the snapshot `avatarGroupOnGreyCard`.
5. Charts' selected dot on a grey card (`ChartSelectedDot`) — the ring between dot and halo
   follows the card; checked in the snapshot `lineChartOnGreyCard`.

---

### Task 1: `surfaceBackground` in DesignTokens

**Files:**
- Modify: `Sources/DesignTokens/AppSurface.swift` (environment entry, computed value, `SurfaceBackground`)
- Modify: `Sources/DesignTokens/AppModifiers.swift` (`CardSurface` sets the entry)
- Test: `Tests/DesignComponentsTests/SurfaceStyleTests.swift`

**Interfaces:**
- Produces:
  - `extension EnvironmentValues { var isOnCard: Bool }` — internal, default `false`.
  - `public extension EnvironmentValues { var surfaceBackground: Color { get } }`.
  - `public struct SurfaceBackground: ShapeStyle { public init(); public func resolve(in: EnvironmentValues) -> Color }`
  - `public extension ShapeStyle where Self == SurfaceBackground { static var surfaceBackground: SurfaceBackground }`

- [ ] **Step 1: Write the failing tests** in `SurfaceStyleTests` (add `@testable import DesignTokens`):

```swift
@Test("A knockout is the page's colour off a card")
func surfaceBackgroundDefaultsToPage() {
    var values = EnvironmentValues()
    values.surfaceStyle = .fill
    #expect(values.surfaceBackground == AppColors.Background.base)
}

@Test("On a grey card a knockout is the card's grey")
func surfaceBackgroundFollowsCard() {
    var values = EnvironmentValues()
    values.surfaceStyle = .fill
    values.isOnCard = true
    #expect(values.surfaceBackground == AppColors.Background.neutral1)
}

@Test("On a glass card a knockout stays the page's colour")
func surfaceBackgroundOnGlassCard() {
    var values = EnvironmentValues()
    values.surfaceStyle = .glass
    values.isOnCard = true
    #expect(values.surfaceBackground == AppColors.Background.base)
    #expect(SurfaceBackground().resolve(in: values) == AppColors.Background.base)
}
```

- [ ] **Step 2: Confirm they fail** — no Swift toolchain for SwiftUI here: `grep -n "surfaceBackground" Sources/DesignTokens/AppSurface.swift` prints nothing (the names do not exist yet); CI's unit-test job is the real run.

- [ ] **Step 3: Implement** in `AppSurface.swift`: `@Entry var isOnCard = false` (internal), the
  computed `surfaceBackground` (`isOnCard && surfaceStyle == .fill ? neutral1 : base`), and
  `SurfaceBackground` resolving through it. In `AppModifiers.swift`, `CardSurface.body` ends with
  `.environment(\.isOnCard, true)` on the content (so the card's children see it, the card's own
  background does not need it). Doc comments say where to use it: "a ring or disc that cuts a
  shape out of whatever lies under it".

- [ ] **Step 4: Commit**

```bash
git add Sources/DesignTokens/AppSurface.swift Sources/DesignTokens/AppModifiers.swift Tests/DesignComponentsTests/SurfaceStyleTests.swift
git commit -m "Add .surfaceBackground: the colour of the surface under a knockout"
```

### Task 2: Knockouts follow the surface, with snapshots on a grey card

**Files:**
- Modify: `Sources/DesignComponents/Media/AvatarGroup.swift:81,82,92,118` (avatars' disc and ring, "+N" ring, skeleton ring)
- Modify: `Sources/DesignComponents/Content/MonthCalendar.swift:242`
- Modify: `Sources/DesignComponents/Charts/LineChart.swift:433` (`ChartForecastRing`)
- Modify: `Sources/DesignComponents/Charts/TrendChartFrame.swift:805` (`ChartSelectedDot`)
- Modify: `Sources/DesignComponents/Charts/HeroSparkline.swift:238`
- Modify: `Sources/DesignComponents/Progress/HeroHalfGauge.swift:236`
- Modify: `Sources/DesignComponents/Progress/MiniHalfGauge.swift:137` (Canvas: read `@Environment(\.surfaceBackground)` in the view, use it in the closure)
- Modify: `Sources/DesignComponents/Rows/TransactionRow.swift:206` (badge background)
- Modify: `Sources/DesignComponents/Media/ParticleCreatureSpeech.swift:399-400` (halo: a `halo: Color` property on `CreatureSpeechRenderer`, filled from the view's `@Environment(\.surfaceBackground)`)
- Test: `Gallery/SnapshotTests/FoundationsSnapshotTests.swift` (new test `knockoutsOnGreyCard`)

**Interfaces:**
- Consumes: `.surfaceBackground` (ShapeStyle) and `@Environment(\.surfaceBackground)` (Color) from Task 1.

- [ ] **Step 1: Write the snapshot test** `knockoutsOnGreyCard` in `FoundationsSnapshotTests`, three
  snapshots, each content in `.cardContentPadding().cardStyle().surfaceStyle(.fill)`, light and dark:
  - `named: "avatarGroupOnGreyCard"`: `AvatarGroup(names: ["Ayan", "Dana", "Marat", "Aru", "Timur", "Saule"], maxVisible: 4, size: 40)`;
  - `named: "monthCalendarOnGreyCard"`: the `monthCalendar()` setup from `DisplaySnapshotTests` (same fixed day and items);
  - `named: "lineChartOnGreyCard"`: a `LineChart` with a selected point and a forecast, built like the `forecastAndYearAgo` test in `ChartsSnapshotTests`.

- [ ] **Step 2: Replace each knockout** listed under Files: `AppColors.Background.base` / `AppColors.bgBase` → `.surfaceBackground` (ShapeStyle sites) or the environment colour (Canvas and renderer sites). Keep the `onColor` branches as they are. `AvatarGroupSkeleton`'s ring too. `rg -n "Background\.base|bgBase" Sources/DesignComponents` afterwards lists only page backgrounds (`OnboardingPageContainer`, `AuroraBackground`, `AmountEntrySheet`, `SquareImageCropper`).

- [ ] **Step 3: Commit and push; CI builds**

```bash
git add Sources/DesignComponents Gallery/SnapshotTests/FoundationsSnapshotTests.swift
git commit -m "Knockouts take the surface's colour: no white rings on grey cards"
git push -u origin claude/focused-noether-pwdn1m
```
Expected: the package, Gallery, Dalada, Tenra and unit-test jobs green; the snapshot job fails only on the three new references (no reference yet).

- [ ] **Step 4: Record the new references** — run the CI workflow on the branch with `record_snapshots: missing`, then again with `never`. Expected: the second run green. Look at the six new PNGs: rings grey (`#F2F2F7` light, `#1C1C1E` dark), not white.

### Task 3: Release note, docs, PR

**Files:**
- Create: `.changes/focused-noether-pwdn1m-2026-11-25-rings.md`
- Modify: `docs/design-system.md` (Surfaces paragraph in §1 Colors: one sentence on `.surfaceBackground`)
- Modify: `docs/agents.md` (one rule: a ring or disc that cuts a shape out uses `.surfaceBackground`, never `Background.base`)
- Modify: `docs/snapshots.md` (FoundationsSnapshotTests row: `knockoutsOnGreyCard`)

- [ ] **Step 1: Write the note**

```markdown
---
bump: minor
---
Rings and discs that cut a shape out of a card take the card's colour, so grey cards show no white rings.

### Added
- `.surfaceBackground` (`SurfaceBackground`) and `EnvironmentValues.surfaceBackground`: the colour of the surface under a view, the page's or, inside a card under `SurfaceStyle.fill`, the card's grey. For a ring or disc that cuts a shape out of whatever lies under it.

### Fixed
- `AvatarGroup`, `MonthCalendar`'s markers, `LineChart`'s forecast ring and selected point, `HeroSparkline`'s forecast point, `HeroHalfGauge` and `MiniHalfGauge` ticks, `TransactionRow`'s badge and `ParticleCreature`'s speech halo drew their ring in the page's colour: white rings on a grey `.fill` card (Dalada, Platina). They follow the surface now; glass cards do not change.

### Gallery and tooling
- Snapshots of `AvatarGroup`, `MonthCalendar` and `LineChart` on a grey card (`FoundationsSnapshotTests.knockoutsOnGreyCard`).
```

- [ ] **Step 2: Check the note** — Run: `python3 .github/scripts/release.py check` and `python3 .github/scripts/changelog.py check`. Expected: both pass and name a minor release.

- [ ] **Step 3: Docs** — the three doc lines above.

- [ ] **Step 4: Commit, push, CI green, open the PR** (the owner asked for it) with the repository's PR template if any; title "Rings on grey cards take the card's colour".

```bash
git add .changes docs
git commit -m "Release note and docs for .surfaceBackground"
git push
```
