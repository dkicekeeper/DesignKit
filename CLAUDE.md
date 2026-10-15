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
├── DesignSupport/     → DesignTokens — icons (IconSource/IconStyle/Icon),
│                      formatting, haptics, DominantColorExtractor, host hooks
└── DesignComponents/  → DesignTokens + DesignSupport — by what a component does (1.13.0,
                       docs/gallery-structure.md): Actions, TextInput, Selection, Amounts,
                       Rows, Cards, Charts, Progress, Feedback, Navigation, Media, Content,
                       Sheets, Effects
Gallery/               showcase app (xcodegen; the .xcodeproj is not in git): Foundations and
                       17 component sections by what a component does (docs/gallery-structure.md);
                       every public component has a ComponentPage — header, preview canvas
                       (light/dark), controls for its parameters and states (Loading = its
                       skeleton), usage notes; an Updates screen reads CHANGELOG.md; ships to
                       TestFlight (docs/testflight.md)
Gallery/SnapshotTests/ snapshot tests hosted in the Gallery app; references in __Snapshots__
scripts/               snapshot-tests.sh (CI and local runs of the snapshot tests)
Shaders/               Metal sources (Ripple, EdgeGlow, Grain, Holographic, Dissolve) + build.sh;
                       CI compiles them into the .metallib files in Sources/DesignComponents/
                       Resources/Shaders (.github/workflows/shaders.yml), so apps need no Metal
                       Toolchain (docs/motion.md §6)
Tests/                 swift-testing unit tests (formatting, ExpressionEvaluator, calculator
                       model) — run by CI on an iOS Simulator
docs/                  design-system.md, charts.md, gotchas.md, localization-keys.md, benchmark.md
CHANGELOG.md           every release, newest first: what it added and changed, how to move an
                       app to it (the GitHub Release notes and the Gallery's Updates screen)
```

Dependencies only point down the list. One product, `DesignKit`, exports all three modules;
consumers `import DesignTokens` / `DesignSupport` / `DesignComponents` as needed.

## Consumers

| App | How it depends | Notes |
|---|---|---|
| Dalada | `ios/Packages/DaladaKit/Package.swift`, `exact: "X.Y.Z"` | Swift 6, iOS 26; green accent via `DesignKitTheme.accent`; uses tokens, `cardStyle`, buttons, `EmptyState`, `SectionHeader`, `RecommendationBox`, `PlusTabLabel`, since 1.12.0 `MessageComposer` and the community and progress components (people, comments, threads, reviews, reactions, achievements, checklists, stats, streak, thumbnails), since 2.7.0 effects (`.holographic`, `.interactiveTilt`, `.celebration`, `.completionMoment`, `.dissolve`, `AuroraBackground`), and since 2.8.0 its photos (`PhotoTile`, `PhotoStrip`, `PhotoGrid`, `PhotoCarousel`, `PhotoViewer`), share pictures (`ShareCardSheet`, `ShareCardFrame`), `LiveSessionBar`, `DownloadRow`, `ArticleBody`, `ChipPicker(allTitle:)` and `PersonRow(style: .card)`, since 3.0.0 its forms (`EditSheetContainer`, `FormSection`, the form rows), and since 3.1.0 its photo loading (`RemotePhoto` over its `PhotoCache` through `DesignKitPhotoLoader`), `ChipPicker(inset:)` in form cards and `ActionRowLabel` for its photo pickers, since 3.5.0 search suggestions (`.dsSearchSuggestions` in places and people search), with thin adapters over its models (its `ShareCard.Style.dalada`). Its guide to DesignKit: `CLAUDE.md`, «Компоненты интерфейса» (a table from what a screen needs to the components) |
| Tenra | `Tenra.xcodeproj` package reference, exact version | Reference look. `Tenra/Utils/DesignKitBridge.swift` re-exports the three modules, wires the host hooks and keeps the Tenra-model adapters (custom category colours, logo registry, breakdown → `DonutSlice`, the stat-card sparkline). Since 2.9.0 its transaction rows (`TransactionRow` under `TransactionCardView`), account and category card pickers (`SnapCardPicker`), live transcript (`StreamingText`), custom period sheet (`DateRangePickerSheet`), background options (`OptionCard`), voice cards (`.cascadeIn`), period pagers (`PagerArrows`) and backup overlay (`.progressOverlay`) are DesignKit's too, as thin adapters over its models. Its Finances cards use `PackedCircleIcons(style: .shelf)` (4.5.0; whole 48 pt tiles in a 160 pt row since 4.15.0, 36 pt in a pocket from 4.5.1, the rest in "+N"; 4.4.0's shelf replaced 3.3.0's `.fan`). Since 3.5.0 search suggestions (`.dsSearchSuggestions`: History with its categories and subcategories, link payments, subcategory search). Since 4.6.0 the pieces of its AI assistant: `ParticleCreature` (the mascot), `MessageBubble`, `SuggestionChips`; since 4.8.0 its tab (`CreatureTabLabel` over `CreatureGlyph`) and its field's attach menu and microphone (`MessageComposer(leading:onVoice:)`). Since 4.10.0 Ten speaks in words of light and gestures (`speech:`, `.creatureGesture`), since 4.11.0 it lives on its own and thinks pictures (`.creatureAmbience`, `CreatureSpeech(symbol:label:)`), since 4.12.0 it wears accessories (`accessory:`: holidays, a crown, its wardrobe), since 4.13.0 it stands in its empty lists (`EmptyState(…) { artwork }`, a line and a point at the button). Since 4.14.0 the last generic views it drew itself: `AmountEntrySheet` (money towards a goal or a debt), `ListCard` (its assistant's cards; `FormSection(style: .glass)` since 5.0.0), `NoticeCard` ("Ten writes"), `VoiceOrbButton` (the voice stop orb), `PickerCarousel` (Ten's wardrobe) and `NavigationPickerRow(style: .list)` (Settings' voice language); and `.edgeBackdrop` behind Ten in the chat. Its guide: `docs/design-system.md` (the bridge, every adapter and the component under it, screen patterns, amount rules) |

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
  the reference: a visual change to a shared component is a design decision, called out under
  **Changed** in the release's CHANGELOG.md section.
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
`DesignKitLogoLoader.loader`, `DesignKitPhotoLoader.loader` / `.cached` (3.1.0, `RemotePhoto`),
`DesignKitCurrencyConverter.convert` / `.convertSync`, `DesignKitLogoCatalog` (the icon picker's
brands). Add a new hook (same shape:
a `public static var` closure/value in `DesignSupport` or `DesignTokens`, documented default)
rather than importing an app type.

## Porting a Component (checklist)

1. Copy the file into the matching `Sources/DesignComponents/<Group>/` folder (the group by what
   the component does, docs/gallery-structure.md); drop `#Preview`
   blocks (the Gallery replaces them) and add `import DesignTokens` / `import DesignSupport`.
   Name it for what it is, without `View` or `App` (`SectionHeader`, `Avatar`, `DSButton`;
   2.0.0, docs/migration-2.0.md); tokens keep their `App` prefix (`AppColors`, `AppSpacing`).
   A variant of an existing component is a parameter or a style of it, not a new view
   (`DSButton(iconPlacement: .top)`, `SectionHeader(style: .card)`).
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
4. Add a Gallery page: a `ComponentPage` (with `styles:`, the values of its `style:` parameter,
   if it has one) in its section's screen's `pages` (`Gallery/Gallery/Screens/`, by
   what the component does), with a control for each parameter and a `StateControl` whose
   "Loading" shows its skeleton (plus Empty / Error / Disabled when it has them); a new screen
   needs `xcodegen generate`. Add a snapshot test in `Gallery/SnapshotTests` (the skeleton's in
   `SkeletonsSnapshotTests`; one Liquid Glass card per snapshot; `named:` tells them apart),
   then record it with a manual CI run, `record_snapshots: missing` (docs/snapshots.md).
5. Add any new `String(localized:)` key to `docs/localization-keys.md` and its English value
   to `Gallery/Gallery/Localizable.xcstrings`.
6. Update `docs/design-system.md` (§0 inventory + the component's section), and add the
   component under **Added** in the release's CHANGELOG.md section (with the app view it
   replaces under **Migration**).
7. Push; CI must be green on the package, Gallery, snapshot, Dalada and Tenra jobs.

## API Stability & Versioning

- Semantic versioning with git tags (`0.2.0`, …). Consumers pin a version (`exact:` or
  `.upToNextMinor(from:)`), never a branch.
- **Cutting a release:** bump `VERSION` and add its section at the top of
  [CHANGELOG.md](CHANGELOG.md) in the PR that should ship. On merge,
  `.github/workflows/release.yml` tags that commit `X.Y.Z` and creates a GitHub Release whose
  notes are that section (tags are created by Actions — the Claude session's git proxy only
  pushes branches). TestFlight's Gallery build carries the same version, with the section as
  "What to Test", and the Gallery's Updates screen shows it.
- **A CHANGELOG section** is `## X.Y.Z - YYYY-MM-DD`, a line or two on what the release is with
  its PR link, then the sections that apply, in this order: `### Added` (new API), `### Changed`
  (what looks or behaves differently in an app after the bump), `### Deprecated` (old → new),
  `### Removed` (majors only), `### Fixed`, `### Migration` (what an app changes, old → new, a
  code block where the API changes) and `### Gallery and tooling`. English, no em dashes, one
  level of `- ` items. CI's `Changelog` job (`.github/scripts/changelog.py check`) fails when
  the section for `VERSION` is missing or the format is off.
- **Never remove or rename public API in a minor release.** Deprecate with
  `@available(*, deprecated, message: "… Use X.")` naming the replacement; remove only in the
  next major, once no consumer uses it. Tenra retiring a component is not a reason to delete it
  here.
- Visual changes to shared components land in every consumer on its next bump: list them under
  **Changed** in the CHANGELOG section. The changed snapshot PNGs in the PR show exactly what
  changed.

## Toolchains & Language

- iOS 26+, Swift 5 language mode (`swiftLanguageModes: [.v5]`), no default MainActor isolation.
- Must compile with **Xcode 26 and Xcode 27**: iOS 27 SDK APIs go behind
  `#if compiler(>=6.4)` **and** `#available(iOS 27, *)`. CI's `Package on Xcode 27` job builds
  the package with Xcode 27 once the runner image has it; until then it passes with a warning.
- Tokens that nonisolated app code reads are `nonisolated`.

## Known Gaps / Follow-ups

- Audit round 4 (2026-10, owner-approved) found the last generic views in the apps: Dalada's
  photos, share pictures, session bar, downloads, articles, "All" chips and profile card went
  into 2.8.0; Tenra's transaction row, card pickers, streaming transcript, date-range sheet,
  option cards, card cascade, pager arrows and progress overlay into 2.9.0. After that,
  nothing generic is known to be left. Tenra keeps screens over its models (filter sheets, home
  sections, transaction lists, entity detail screens, the lock screen, `PremiumLockedView` by
  the owner's choice) and its date parsing; Dalada keeps its sign-in card, map layers, weather
  and rules views.
- DesignKit 3.0.0 (2026-10) removed every deprecated name (no app used one), drew `cardStyle()`'s
  glass behind the content and added the form pieces Dalada's forms needed (`StepperRow`,
  `NavigationPickerRow`, `FormTextField(.row)`, `EditSheetContainer(isSaving:)`)
  ([docs/migration-3.0.md](docs/migration-3.0.md)).
- Audit round 5 (2026-10, owner-approved) found three more things the apps drew by hand:
  the item row (Dalada's trips, places, articles, gear; Tenra's backups, subcategories) became
  `ItemRow` + `MetaLine`, Dalada's queued-item card `PendingItemCard`, and `CurrencyList`'s row
  the public `CurrencyRow` (Tenra's quick-access currencies), all in 3.6.0.
- Dalada's map drew its place types, layers and zones in system colours (some white symbols at
  2.2:1, and a marker image keeps the theme it was drawn in): 3.7.0's `AppColors.Palette` gives
  fixed deep hues with `UIColor`; Dalada maps its types and layers onto them in `MapColors`.
- DesignKit 4.0.0 (2026-10) removed the last deprecated name, `SectionHeader.Style.list`
  (`.compact` since 3.2.0); nothing else changed ([docs/migration-4.0.md](docs/migration-4.0.md)).
  No deprecated API is left.
- Benchmark round 3 (2026-10, owner-approved) after 4.0.0: `RatingSummary` (Dalada's reviews
  block), `LoadMoreFooter` + `.onReachEnd` (paged lists in both apps) and `limit:` character
  counts on `MessageComposer` / `FormTextField`, all in 4.1.0.
- The hero score (4.2.0, owner-approved from a reference): `ScoreGaugeCard(style: .hero)` over
  `HeroHalfGauge(style: .bleed)`, a gauge wider than the screen with a knob, on a gradient of its
  colour (`tone: .onColor`) or on the page; `AppTypography.display` for its number. Tenra's
  Financial Health screen uses it.
- Insight details on colour (4.5.0, owner-approved): `.heroBackground(color)` behind any hero
  with its pieces in white (`\.heroTone`), `.heroScrollEdge()` on the screen's scroll view so
  the colour reaches the top of the screen, and `ScoreGaugeCard(amount:)`. Tenra's insight
  details open on the colour of their tone. 4.5.1 (owner's review on a device): the gradient
  starts at the screen's top edge, is a pale tint with black text in light mode (deep with
  white in dark mode), and a long amount shrinks inside the arc.
- The assistant as a character (2026-10, the owner's plan): 4.10.0 speech and gestures (words of
  light that fly out of the mouth with an emotion; a comic bubble was tried and dropped by the
  owner), 4.11.0 thoughts in pictures and a life of its own, 4.12.0 eight accessories of light.
  In Tenra (its #62) Ten daydreams of the person's data (the next payment, a goal, rising
  spending, a debt due) and earns its accessories by days in a row in Tenra and by goals; 4.13.0's
  `EmptyState` artwork puts it in Tenra's empty lists, saying a line and pointing at the button.
- DesignKit 5.0.0 (2026-10, the owner's review of 4.14.0's ports): what repeated existing
  components was folded in and the duplicates removed at once, not deprecated. `ListCard` became
  `FormSection(style: .glass)`; `PickerCarousel` runs on `SnapCardPicker(style: .centered(width:))`;
  `AmountEntrySheet` on `EditSheetContainer`; `NavigationPickerRow(.list)` on
  `NavigationSettingsRow(value:)`; one `.selectionOutline` (2 pt) for every picked option
  ([docs/migration-5.0.md](docs/migration-5.0.md)).
- Search with suggestions (the last benchmark candidate) is 3.5.0's `.dsSearchSuggestions`: the
  lines live in the system's suggestion list under `.searchable`, so Tenra's "system search
  only" rule holds. New candidates go in [docs/benchmark.md](docs/benchmark.md) first.

## Reference Docs

| Working on… | Read first |
|---|---|
| Tokens, modifiers, any component, amount formatting, animation rules | [docs/design-system.md](docs/design-system.md) |
| Charts, progress, gauges, OrbChart, Swift Charts patterns | [docs/charts.md](docs/charts.md) |
| Motion and effects: springs, budgets, SF Symbol motion, transitions, celebrations, Reduce Motion | [docs/motion.md](docs/motion.md) |
| Package traps (public API, Xcode 26/27, bundles) and SwiftUI layout traps | [docs/gotchas.md](docs/gotchas.md) |
| Localized strings used by components | [docs/localization-keys.md](docs/localization-keys.md) |
| Gallery TestFlight pipeline | [docs/testflight.md](docs/testflight.md) |
| Snapshot tests: what is covered, recording references, the pinned Xcode | [docs/snapshots.md](docs/snapshots.md) |
| What each version added and changed, and how to move an app to it (also the Gallery's Updates screen) | [CHANGELOG.md](CHANGELOG.md) |
| Moving an app to 2.0 (renames, `DSButton`, icon sizes, visual changes) | [docs/migration-2.0.md](docs/migration-2.0.md) |
| Moving an app to 3.0 (removed names and their replacements, card colours) | [docs/migration-3.0.md](docs/migration-3.0.md) |
| Moving an app to 4.0 (`SectionHeader.Style.list` removed) | [docs/migration-4.0.md](docs/migration-4.0.md) |
| Moving an app to 5.0 (`ListCard` removed, `FormSection(style: .glass)` in its place) | [docs/migration-5.0.md](docs/migration-5.0.md) |
| What exists vs Apple HIG / Material / Fluent / Carbon / Polaris / Atlassian, next candidates | [docs/benchmark.md](docs/benchmark.md) |
| Where a component goes (Gallery sections, source folders), how its Gallery page is built | [docs/gallery-structure.md](docs/gallery-structure.md) |
| How an app uses DesignKit (its adapters, screens, effects in use) | Tenra's `docs/design-system.md`, Dalada's `CLAUDE.md` («Компоненты интерфейса») |
