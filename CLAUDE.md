# DesignKit — Project Guide for Claude

SwiftUI design system shared by **Tenra** (personal finance, the reference implementation) and
**Dalada** (outdoor trips). One package, three layered targets, a Gallery app, no app logic.

## Quick Start

```bash
# Build the package (no Xcode project needed — xcodebuild reads Package.swift).
# Scheme: DesignKit-Package or DesignKit — `xcodebuild -list` shows which.
xcodebuild build -scheme DesignKit-Package -destination 'generic/platform=iOS Simulator' -quiet

# Gallery (showcase app). The .xcodeproj is generated from Gallery/project.yml and not in git:
cd Gallery && xcodegen generate
xcodebuild build -project Gallery.xcodeproj -scheme Gallery \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -quiet
```

Code is often written in a Linux container where SwiftUI cannot compile. **CI is the compiler
there**: `.github/workflows/ci.yml` builds the package, the Gallery, and **Dalada against this
checkout** on macOS for every push to `main` and `claude/**`. Push, then read the job logs.

**Snapshot tests** (`Gallery/SnapshotTests`, hosted in the Gallery app) compare components with
reference PNGs in light, dark and large text; CI's `Snapshot tests` job fails on a visual
difference. An intentional change is re-recorded by a manual CI run with `record_snapshots`
(`missing` / `failed` / `all`): [docs/snapshots.md](docs/snapshots.md).

**TestFlight**: `.github/workflows/testflight.yml` archives the Gallery and uploads it on every
push to `main` that touches `Sources/`, `Gallery/`, `Package.swift` or `VERSION` (version =
`VERSION`, build = run number). Setup and troubleshooting: [docs/testflight.md](docs/testflight.md).

## Package Layout

```
Sources/
├── DesignTokens/      leaf — colors, spacing, radius, icon sizes, typography (Inter), animation,
│                      modifiers, button styles, AmbientMotionGate, DesignKitTheme, fonts
├── DesignSupport/     → DesignTokens — icons (IconSource/IconStyle/IconView/BrandLogoView),
│                      formatting, haptics, DominantColorExtractor, host hooks
└── DesignComponents/  → DesignTokens + DesignSupport — Cards, Charts, Display, Feedback,
                       Forms, Headers, Icons, Input, Rows
Gallery/               showcase app (xcodegen; the .xcodeproj is not in git); every public
                       component has a specimen; each ShowcaseSection is a page of its
                       category (chips on top, swipe); ships to TestFlight (docs/testflight.md)
Gallery/SnapshotTests/ snapshot tests hosted in the Gallery app; references in __Snapshots__
scripts/               snapshot-tests.sh (CI and local runs of the snapshot tests)
Tests/                 swift-testing unit tests (formatting, ExpressionEvaluator, calculator
                       model) — run by CI on an iOS Simulator
docs/                  design-system.md, charts.md, gotchas.md, localization-keys.md, benchmark.md
```

Dependencies only point down the list. One product, `DesignKit`, exports all three modules;
consumers `import DesignTokens` / `DesignSupport` / `DesignComponents` as needed.

## Consumers

| App | How it depends | Notes |
|---|---|---|
| Dalada | `ios/Packages/DaladaKit/Package.swift`, `exact: "X.Y.Z"` | Swift 6, iOS 26; green accent via `DesignKitTheme.accent`; uses tokens, `cardStyle`, buttons, `EmptyStateView`, `SectionHeaderView`, `RecommendationBox`, `PlusTabLabel` |
| Tenra | `Tenra.xcodeproj` package reference, exact version | Reference look. `Tenra/Utils/DesignKitBridge.swift` re-exports the three modules, wires the host hooks and keeps the Tenra-model adapters (custom category colours, logo registry, breakdown → `DonutSlice`, the stat-card sparkline) |

A consumer sees a DesignKit change when its pin moves. Each app's **DesignKit update** workflow
(`.github/workflows/designkit.yml` in the app) checks for a newer release tag daily, bumps the
pin, builds and tests, and commits the bump to the app's `main` when green. CI's `dalada` and
`tenra` jobs build both apps against the current checkout, so a change that would break one
fails here first (manual runs take `dalada_ref` / `tenra_ref` to check an app branch).

## Source of Truth & Sync

- **Since 2026-10 (DesignKit 0.3.0):** both apps consume DesignKit, and it is the only place
  design-system code lives. Apps add or change components by PR here (develop with Xcode's
  local package override: drag the local DesignKit folder into the app's project), CI builds
  every consumer, merge → release tag → each app's update workflow bumps it. Tenra's look stays
  the reference: a visual change to a shared component is a design decision, called out in the
  release notes.
- **Before that:** DesignKit was synced FROM Tenra's own copy: three-way merge per file
  (base = the Tenra commit of the previous sync, theirs = Tenra `main`, ours = DesignKit),
  keeping DesignKit's `public` API and parameterization. The log below records those syncs.

### Sync log

| Date | Tenra commit | Notes |
|---|---|---|
| 2026-06-10 | `4392be3` (2026-06-04) | v0 extraction |
| 2026-09-30 | `74a12c5` (2026-09-26) | 20 changed files merged; 36 new files (components, charts, helpers); 5 retired components deprecated; docs ported |
| 2026-10-01 | `b23782c` | Last sync: Tenra's copy removed, Tenra consumes DesignKit 0.3.0 (its unit tests for formatting, the expression evaluator and the calculator model moved here) |

## What Belongs in DesignKit

```
New or changed UI code?
├─ Uses an app model, store, service, settings, networking or persistence?
│  ├─ Can the dependency become a parameter, a closure or an existing host hook? → DesignKit
│  │   (keep the app-specific adapter in the app as an extension — e.g. Tenra's
│  │    DonutSlice.from([CategoryBreakdownItem]) over DonutSlice.foldingSlivers)
│  └─ No → stays in the app
├─ Pure presentation (tokens, layout, animation, formatting, generic input)? → DesignKit
└─ A screen, navigation, or feature flow? → the app
```

**Every component that can be generic lives here, even if one app uses it** (owner's decision,
2026-10; the old "rule of two" is gone): DesignKit is the single source of truth for how things
look. A component ported from an app gets a **context-neutral name and API** that any app could
use: Tenra's `BudgetProgressRow` became `LimitProgressCard`, its `AmortizationScheduleRow`
became `ScheduleRow`, and the app keeps a thin adapter under the old name that maps its model.
The port is pixel-identical: the layout code moves as it is, only its inputs change.

Host hooks (set once in `App.init()`): `DesignKitTheme.accent`, `DesignKitFonts.registerIfNeeded()`,
`DesignKitLogoLoader.loader`, `DesignKitCurrencyConverter.convert` / `.convertSync`,
`DesignKitLogoCatalog` (the icon picker's brands). Add a new hook (same shape:
a `public static var` closure/value in `DesignSupport` or `DesignTokens`, documented default)
rather than importing an app type.

## Porting a Component (checklist)

1. Copy the file into the matching `Sources/DesignComponents/<Group>/` folder; drop `#Preview`
   blocks (the Gallery replaces them) and add `import DesignTokens` / `import DesignSupport`.
2. `public` on the type, `body`, nested types used in the API, and protocol requirements
   (`id`, `body(content:)`, `==`). Write an explicit `public init` — memberwise inits are internal.
   Padding follows docs/design-system.md §10: a card pads itself, a row pads only vertically
   (its `RowConfiguration` preset), a row that lives only in a `List` and a primitive not at all.
3. Replace app dependencies per the decision tree above. Leave a one-line comment naming what
   stayed in the app.
   **Every component that shows data has a skeleton** (owner's rule, 2026-10): `<Name>Skeleton`
   at the end of the component's file, the component's container and corner kept as they are,
   grey shapes for its text, amounts, icons and charts, `AppRadius.soft` for a shape with no
   corner of its own. One `.shimmer()` on the content, `.skeletonLoadingLabel()` on the whole
   (docs/design-system.md, "Component skeletons").
4. Add a Gallery specimen (one `ShowcaseSection` per component, so it gets its own page, in
   an existing screen file or a new one + `xcodegen generate`; the skeleton on the Skeletons
   page) and a snapshot test (the skeleton's in `SkeletonsSnapshotTests`) in
   `Gallery/SnapshotTests` (one Liquid Glass card per snapshot; `named:` tells them apart),
   then record it with a manual CI run, `record_snapshots: missing` (docs/snapshots.md).
5. Add any new `String(localized:)` key to `docs/localization-keys.md` and its English value
   to `Gallery/Gallery/Localizable.xcstrings`.
6. Update `docs/design-system.md` (§0 inventory + the component's section).
7. Push; CI must be green on the package, Gallery, snapshot, Dalada and Tenra jobs.

## API Stability & Versioning

- Semantic versioning with git tags (`0.2.0`, …). Consumers pin a version (`exact:` or
  `.upToNextMinor(from:)`), never a branch.
- **Cutting a release:** bump `VERSION` in the PR that should ship. On merge,
  `.github/workflows/release.yml` tags that commit `X.Y.Z` and creates a GitHub Release with the
  commits since the previous tag (tags are created by Actions — the Claude session's git proxy
  only pushes branches). TestFlight's Gallery build carries the same version.
- **Never remove or rename public API in a minor release.** Deprecate with
  `@available(*, deprecated, message: "… Use X.")` naming the replacement; remove only in the
  next major, once no consumer uses it. Tenra retiring a component is not a reason to delete it
  here.
- Visual changes to shared components land in every consumer on its next bump — call them out in
  the release notes. The changed snapshot PNGs in the PR show exactly what changed.

## Toolchains & Language

- iOS 26+, Swift 5 language mode (`swiftLanguageModes: [.v5]`), no default MainActor isolation.
- Must compile with **Xcode 26 and Xcode 27**: iOS 27 SDK APIs go behind
  `#if compiler(>=6.4)` **and** `#available(iOS 27, *)`. CI's `Package on Xcode 27` job builds
  the package with Xcode 27 once the runner image has it; until then it passes with a warning.
- Tokens that nonisolated app code reads are `nonisolated`.

## Known Gaps / Follow-ups

- Nothing generic is known to be left in the apps (1.10.0 ported Tenra's last batch and the
  components that waited for hooks). Tenra keeps screens over its models (filter sheets, home
  sections, transaction lists) and its date parsing.

## Reference Docs

| Working on… | Read first |
|---|---|
| Tokens, modifiers, any component, amount formatting, animation rules | [docs/design-system.md](docs/design-system.md) |
| Charts, progress, gauges, OrbChart, Swift Charts patterns | [docs/charts.md](docs/charts.md) |
| Package traps (public API, Xcode 26/27, bundles) and SwiftUI layout traps | [docs/gotchas.md](docs/gotchas.md) |
| Localized strings used by components | [docs/localization-keys.md](docs/localization-keys.md) |
| Gallery TestFlight pipeline | [docs/testflight.md](docs/testflight.md) |
| Snapshot tests: what is covered, recording references, the pinned Xcode | [docs/snapshots.md](docs/snapshots.md) |
| What exists vs Apple HIG / Material / Fluent / Carbon / Polaris / Atlassian, next candidates | [docs/benchmark.md](docs/benchmark.md) |
