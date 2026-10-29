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
.github/scripts/       changelog.py (CI's Changelog job, release notes), gallery_badges.py (CI's
                       Gallery badges job: each page's `apps:` against Tenra's and Dalada's code)
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
| Dalada | `ios/Packages/DaladaKit/Package.swift`, `exact: "X.Y.Z"` | Swift 6, iOS 26; green accent via `DesignKitTheme.accent`; uses tokens, `cardStyle`, buttons, `EmptyState`, `SectionHeader`, `RecommendationBox`, `PlusTabLabel`, since 1.12.0 `MessageComposer` and the community and progress components (people, comments, threads, reviews, reactions, achievements, checklists, stats, streak, thumbnails), since 2.7.0 effects (`.holographic`, `.interactiveTilt`, `.celebration`, `.completionMoment`, `.dissolve`, `AuroraBackground`), and since 2.8.0 its photos (`PhotoTile`, `PhotoStrip`, `PhotoGrid`, `PhotoCarousel`, `PhotoViewer`), share pictures (`ShareCardSheet`, `ShareCardFrame`), `LiveSessionBar`, `DownloadRow`, `ArticleBody`, `ChipPicker(allTitle:)` and `PersonRow(style: .card)`, since 3.0.0 its forms (`EditSheetContainer`, `FormSection`, the form rows), and since 3.1.0 its photo loading (`RemotePhoto` over its `PhotoCache` through `DesignKitPhotoLoader`), `ChipPicker(inset:)` in form cards and a row label for its photo pickers (a `UniversalRow` since 7.0.0, as are all its form rows), since 3.5.0 search suggestions (`.dsSearchSuggestions` in places and people search), since 5.3.0 (its 0919342, docs/adoption.md) `StatusBanner` on offline maps, `.spotlight` over the map's buttons, `StepTracker` for a new place, `HeroSymbol` in its placeholders, `OnboardingStepIndicator` after the first sign-in, `AvatarGroup` for a trip's members, `TagInput` and `FlowLayout` for gear tags, and `.skeletonReveal` wherever a skeleton gives way, with thin adapters over its models (its `ShareCard.Style.dalada`). Its guide to DesignKit: `CLAUDE.md`, «Компоненты интерфейса» (a table from what a screen needs to the components) |
| Tenra | `Tenra.xcodeproj` package reference, exact version | Reference look. `Tenra/Utils/DesignKitBridge.swift` re-exports the three modules, wires the host hooks and keeps the Tenra-model adapters (custom category colours, logo registry, breakdown → `DonutSlice`, the stat-card sparkline). Since 2.9.0 its transaction rows (`TransactionRow` under `TransactionCardView`), account and category card pickers (`SnapCardPicker`), live transcript (`StreamingText`), custom period sheet (`DateRangePickerSheet`), background options (`OptionCardPicker`), voice cards (`.cascadeIn`), period pagers (`PagerArrows`) and backup overlay (`.progressOverlay`) are DesignKit's too, as thin adapters over its models. Its Finances cards use `PackedCircleIcons(style: .shelf)` (4.5.0; whole 48 pt tiles in a 160 pt row since 4.15.0, 36 pt in a pocket from 4.5.1, the rest in "+N"; 4.4.0's shelf replaced 3.3.0's `.fan`). Since 3.5.0 search suggestions (`.dsSearchSuggestions`: History with its categories and subcategories, link payments, subcategory search). Since 4.6.0 the pieces of its AI assistant: `ParticleCreature` (the mascot), `MessageBubble`, `SuggestionChips`; since 4.8.0 its tab (`CreatureTabLabel` over `CreatureGlyph`) and its field's attach menu and microphone (`MessageComposer(leading:onVoice:)`). Since 4.10.0 Ten speaks in words of light and gestures (`speech:`, `.creatureGesture`), since 4.11.0 it lives on its own and thinks pictures (`.creatureAmbience`, `CreatureSpeech(symbol:label:)`), since 4.12.0 it wears accessories (`accessory:`: holidays, a crown, its wardrobe), since 4.13.0 it stands in its empty lists (`EmptyState(…) { artwork }`, a line and a point at the button). Since 4.14.0 the last generic views it drew itself: `AmountEntrySheet` (money towards a goal or a debt), `ListCard` (its assistant's cards; `FormSection(style: .glass)` since 5.0.0), `NoticeCard` ("Ten writes"), `VoiceOrbButton` (the voice stop orb), `PickerCarousel` (Ten's wardrobe) and `NavigationPickerRow(style: .list)` (Settings' voice language; since 7.0.0 every form and settings row of it is a `UniversalRow`). Since 5.3.0 (its #79, docs/adoption.md) every mood, emotion and gesture of Ten (`.working(progress:)` while a statement is read, gesture haptics on reactions, `.creatureFollowsTilt()` on Home, `ParticleCreature.image` on notifications), `MessageBubbleTransition` and `TypingIndicator` in the chat, `OptionCardPicker` for Home's background (a carousel of previews only since 6.0.0), and `StatusBanner`, `HeroSymbol`, `StepTracker`, `Tooltip`, `LiveAmountText`, `SpentBudgetText`, `.sparkleBurst`. Its guide: `docs/design-system.md` (the bridge, every adapter and the component under it, screen patterns, amount rules) |

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
   (`DSButton(iconPlacement: .top)`, `SectionHeader(style: .card)`); a row of a form or a
   settings list is `UniversalRow(_:icon:accessory:)` (7.0.0), in a `FormSection` glass card that
   draws its dividers (8.0.0), and a list of things a person keeps is a `CardList`. Every symbol is an `Icon`: under
   44 pt a glyph with no plate, from 44 pt a tile on its plate (7.0.0, the owner's rule); iOS's
   own bars, menus, swipe actions, tabs and segments, and a symbol inside a line of text, are the
   exceptions (docs/design-system.md, "Icon Sizes").
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
   needs `xcodegen generate`. Its `apps:` names the apps whose code uses it: CI's `Gallery
   badges` job compares them with Tenra's and Dalada's sources (5.2.0). Add a snapshot test in `Gallery/SnapshotTests` (the skeleton's in
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
  `NavigationSettingsRow(value:)`; one `.selectionOutline` (2 pt) for every picked option. And
  `EdgeBackdrop` went: compared on a device, the owner chose the system's hard scroll edge effect
  for a bar over a chat ([docs/migration-5.0.md](docs/migration-5.0.md); what the comparison
  taught about the system's effect is in docs/gotchas.md).
- The owner's review of the Gallery (5.2.0, 2026-10): fourteen fixes (`DateRangePickerSheet`'s
  own calendar, `OptionCardPicker(style: .carousel)`, message entrances, `CreatureGlyph`'s eyes
  cut out of its core, …), CI's `Gallery badges` job, and [docs/adoption.md](docs/adoption.md):
  the components no app uses and where they could go. 5.3.0 gave Ten its answering ring and
  waves, `.working(progress:)`, its eyes on the phone's tilt, gesture haptics and a still
  picture. Both apps took their part of the list (Tenra's #79, which uses every mood, emotion and
  gesture of Ten; Dalada's 0919342). What Dalada then asked for is 5.5.0: `Tooltip(arrowAlignment:)`
  for a corner button (and `.spotlight`'s tail over its view by the screen's edge), and
  `AvatarGroup(_:avatar:)`, a slot for the app's own avatar view with the photo.
- DesignKit 6.0.0 (2026-10, the owner's review of Tenra's background screen): `OptionCardPicker`
  is a carousel of large previews only; `style:` (`.list`, `.carousel`), `OptionCard` and the row
  of small cards under one preview went, and its settings are DesignKit's form rows
  ([docs/migration-6.0.md](docs/migration-6.0.md)).
- DesignKit 6.1.0 (2026-10, the owner's review of Tenra's background settings on a device):
  `SliderRow(config:)` pads it in a `FormSection` card, and `AuroraBackground(_ spots:)` shows
  its colours bright (denser pools, hues meeting in OKLab with their chroma, a 9×9 mesh, colours
  read as linear light); the Gallery shows settings rows in a card or a `List` with their config.
- DesignKit 7.0.0 (2026-10, the owner's review of the rows and icons): one row,
  `UniversalRow(_:icon:value:hint:role:config:accessory:)`, for every form card and settings
  list (a switch, a menu, a list, a date, a stepper, a slider, a check, a screen, an action, a
  value); the twelve rows that each did one of these are removed, both apps moved in the same
  step. And the icon rule: every symbol is an `Icon`, a glyph under 44 pt, a tile on its plate
  from 44 pt; row icons are 24 pt in forms and lists alike. `PackedCircleIconsStyle.fan` went
  too: no deprecated API is left ([docs/migration-7.0.md](docs/migration-7.0.md)).
- DesignKit 8.0.0 (2026-10, the owner's review of the apps' screens): one look, Tenra's
  Analytics and Finances everywhere. Every section is a Liquid Glass `FormSection` on the white
  page (Material and `style:` gone), rows are 56 pt with one `RowDivider` under their text, a
  section's title is bold in sentence case (`SectionHeader.Style.compact` removed), and the
  things a person keeps are a `CardList` (a card per item, or rows in one card) with one set of
  actions: a tap opens, a long press shows Edit and Delete, the toolbar selects, reorders and
  adds; no swipe actions ([docs/migration-8.0.md](docs/migration-8.0.md)). Both apps move their
  forms, lists and `List` screens in the same step.
- DesignKit 8.1.0 (2026-10, the owner's look at Tenra after 8.0.0): the rows made for a `List`
  are rows of a glass section. `ItemRow` pads itself 12 pt and `ChecklistRow` 8 pt above and
  below (`verticalPadding: 0` in a spaced stack or a `List`), and both start the divider under
  their text; a link around a row keeps its inset to its label, so it takes
  `.rowDividerInset(ItemRowStyle.standard.symbolDividerInset)`. Both apps' `section_rows_lint.py`
  (CI) fails on a section row without its own vertical padding and on a linked icon row without
  `.rowDividerInset`.
- DesignKit 8.2.0 (2026-10, the owner's audit of the trend charts): `LineChart`, `BarChart` and
  `ChartSwitcher` open on the current period, selected and centred in the window (empty periods
  after the last one), the banner always above them naming the series; `ChartPoint.chartIsPartial`
  marks a period that is not over; one `TrendChartFrame` under both charts reads the data once.
  The zoom magnifiers stay: the period's length is the app's global granularity (docs/charts.md).
  Then the owner's whole list of additions: forecasts, a year ago, average and limit lines,
  records, a picked stretch, a selection that follows the scroll, stacked bars, a glow in dark
  mode, the entrance on new periods, and `CalendarHeatmap`. After the owner tried them: the
  scroll that follows a ruler no longer redraws the chart under the finger (it shook), the
  person turns the extras on and off in a `ChartSwitcher` menu kept for every chart
  (`.chartDisplayOptions`), Tenra keeps its `OrbChart` over stacked bars, and `MiniBars` draws
  the weekdays on Tenra's new "By day" insight card.
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
| Moving an app to 6.0 (`OptionCardPicker`'s `style:` and `OptionCard` removed) | [docs/migration-6.0.md](docs/migration-6.0.md) |
| Moving an app to 7.0 (the twelve rows → `UniversalRow(accessory:)`, the icon rule) | [docs/migration-7.0.md](docs/migration-7.0.md) |
| Moving an app to 8.0 (glass sections and their dividers, `CardList`, `.compact` and `style:` removed) | [docs/migration-8.0.md](docs/migration-8.0.md) |
| What exists vs Apple HIG / Material / Fluent / Carbon / Polaris / Atlassian, next candidates | [docs/benchmark.md](docs/benchmark.md) |
| Components no app uses yet and where they could go (for the app sessions) | [docs/adoption.md](docs/adoption.md) |
| Where a component goes (Gallery sections, source folders), how its Gallery page is built | [docs/gallery-structure.md](docs/gallery-structure.md) |
| How an app uses DesignKit (its adapters, screens, effects in use) | Tenra's `docs/design-system.md`, Dalada's `CLAUDE.md` («Компоненты интерфейса») |
