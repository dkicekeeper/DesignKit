# DesignKit — Project Guide for Claude

SwiftUI design system shared by **Tenra** (personal finance, the reference implementation),
**Dalada** (outdoor trips) and **Platina** (PlayStation trophies). One package, three layered
targets, a Gallery app, no app logic.

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
there**: `.github/workflows/ci.yml` builds the package, the Gallery, and **Dalada, Tenra and
Platina against this checkout** on macOS (Platina on GitHub's Xcode 27 image) for every push to
`main` and `claude/**`, and runs the unit and
snapshot tests. Push, then read the job logs. The macOS jobs run only when the change can affect
what they build (CI's `What to build` job, `.github/scripts/ci_changes.py`): a change of docs,
release notes or tooling runs the Linux jobs alone, and a PR's own run of a `claude/**` branch
leaves the build to the branch's push run. The account runs a few macOS jobs at a time, shared
with the apps' CI.

**Snapshot tests** (`Gallery/SnapshotTests`, hosted in the Gallery app) compare components with
reference PNGs in light, dark and large text; CI's `Snapshot tests` job fails on a visual
difference. An intentional change is re-recorded by a manual CI run with `record_snapshots`
(`missing` / `failed` / `all`): [docs/snapshots.md](docs/snapshots.md).

**TestFlight**: `.github/workflows/testflight.yml` archives the Gallery and uploads it (version =
`VERSION`, build = run number). A release's build is started by the release bot on the release's
tag; any other push to `main` that touches `Sources/`, `Gallery/` or `Package.swift` builds too,
except a merge that carries a release note (its version is not set until the bot runs).
Setup and troubleshooting: [docs/testflight.md](docs/testflight.md).

**Releases are numbered at merge**: a PR adds a note in `.changes/` and writes the token
`vNext` where its version goes; the release bot (`.github/workflows/release.yml`) gives it the
next number after the merge ([docs/releasing.md](docs/releasing.md)).

## Package Layout

```
Sources/
├── DesignTokens/      leaf — colors, spacing, radius, icon sizes, layout (a large screen's
│                      column, 8.13.0; its side column, 8.15.0), typography (Inter), animation,
│                      modifiers, surfaces (SurfaceStyle: glass or a grey fill, 8.12.0), button
│                      styles, AmbientMotionGate, DesignKitTheme, fonts
├── DesignSupport/     → DesignTokens — icons (IconSource/IconStyle/Icon),
│                      formatting, haptics, DominantColorExtractor, host hooks
└── DesignComponents/  → DesignTokens + DesignSupport — by what a component does (1.13.0,
                       docs/gallery-structure.md): Actions, TextInput, Selection, Amounts,
                       Rows, Cards, Charts, Progress, Feedback, Navigation, Media, Content,
                       Sheets, Effects
Gallery/               showcase app (xcodegen; the .xcodeproj is not in git): Foundations and
                       17 component sections by what a component does (docs/gallery-structure.md);
                       every public component has a ComponentPage — header, preview canvas
                       (light/dark; on the page, in a card or on colour, 8.21.0), controls for
                       its parameters and states (Loading = its skeleton), usage notes;
                       Patterns, whole screens made of the components (8.17.4); the home screen
                       searches the pages and picks an app's preset (accent and surfaces,
                       8.21.0); an Updates screen reads CHANGELOG.md; ships to TestFlight
                       (docs/testflight.md)
Gallery/SnapshotTests/ snapshot tests hosted in the Gallery app; references in __Snapshots__
scripts/               snapshot-tests.sh (CI and local runs of the snapshot tests); for the apps
                       (8.9.0): designkit_lint.py (their design and section-rows lint, run from
                       the pinned version), migrate.py + migrations/ (rewrites and TODOs for a
                       major), sync_agents_block.py (docs/agents.md into an app's CLAUDE.md)
.github/scripts/       ci_changes.py (CI's What to build job: whether a run needs the macOS
                       jobs), changelog.py (CI's Changelog job, release notes), gallery_badges.py (CI's
                       Gallery badges job: each page's `apps:` against Tenra's, Dalada's and
                       Platina's code),
                       components_reference.py (docs/components.md + .json; the release bot
                       writes them), release.py (release notes, the branch check, the release
                       bot; docs/releasing.md)
.changes/              release notes of the PRs not released yet, one file each (docs/releasing.md)
Shaders/               Metal sources (Ripple, EdgeGlow, Grain, Holographic, Dissolve) + build.sh;
                       CI compiles them into the .metallib files in Sources/DesignComponents/
                       Resources/Shaders (.github/workflows/shaders.yml), so apps need no Metal
                       Toolchain (docs/motion.md §6)
Tests/                 swift-testing unit tests (formatting, ExpressionEvaluator, calculator
                       model, contrast, calendars, chart windows, search, shaders, surfaces, …)
                       — run by CI on an iOS Simulator
docs/                  design-system.md, components.md (+ .json, generated), agents.md, charts.md,
                       motion.md, gotchas.md, localization-keys.md, snapshots.md, testflight.md,
                       gallery-structure.md, adoption.md, benchmark.md, migration-X.0.md
CHANGELOG.md           every release, newest first: what it added and changed, how to move an
                       app to it (the GitHub Release notes and the Gallery's Updates screen)
```

Dependencies only point down the list. One product, `DesignKit`, exports all three modules;
consumers `import DesignTokens` / `DesignSupport` / `DesignComponents` as needed.

## Consumers

| App | How it depends | Notes |
|---|---|---|
| Dalada | `ios/Packages/DaladaKit/Package.swift`, `exact: "X.Y.Z"` | Swift 6, iOS 26; green accent via `DesignKitTheme.accent`; uses tokens, `cardStyle`, buttons, `EmptyState`, `SectionHeader`, `RecommendationBox`, since 1.12.0 `MessageComposer` and the community and progress components (people, comments, threads, reviews, reactions, achievements, checklists, stats, streak, thumbnails), since 2.7.0 effects (`.holographic`, `.interactiveTilt`, `.celebration`, `.completionMoment`, `AuroraBackground`; `.dissolve` and `PlusTabLabel` it has dropped since), and since 2.8.0 its photos (`PhotoTile`, `PhotoStrip`, `PhotoGrid`, `PhotoCarousel`, `PhotoViewer`), share pictures (`ShareCardSheet`, `ShareCardFrame`), `LiveSessionBar`, `DownloadRow`, `ArticleBody`, `ChipPicker(allTitle:)` and `PersonRow(style: .card)`, since 3.0.0 its forms (`EditSheetContainer`, `FormSection`, the form rows), and since 3.1.0 its photo loading (`RemotePhoto` over its `PhotoCache` through `DesignKitPhotoLoader`), `ChipPicker(inset:)` in form cards and a row label for its photo pickers (a `UniversalRow` since 7.0.0, as are all its form rows), since 3.5.0 search suggestions (`.dsSearchSuggestions` in places and people search), since 5.3.0 (its 0919342, docs/adoption.md) `StatusBanner` on offline maps, `.spotlight` over the map's buttons, `StepTracker` for a new place, `HeroSymbol` in its placeholders, `OnboardingStepIndicator` after the first sign-in, `AvatarGroup` for a trip's members, `TagInput` and `FlowLayout` for gear tags, and `.skeletonReveal` wherever a skeleton gives way, with thin adapters over its models (its `ShareCard.Style.dalada`). From 8.9.0's proposals (its #80, docs/adoption.md) `SearchablePicker` for a packing list's gear, `.infoTip` on a place's pressure and `AppColors.Status.*Text` for its own status text; `MessageBubble` and `ConversationDivider` declined (its threads are `CommentRow`s). Its guide to DesignKit: `CLAUDE.md`, «Компоненты интерфейса» (a table from what a screen needs to the components) |
| Tenra | `Tenra.xcodeproj` package reference, exact version | Reference look. `Tenra/Utils/DesignKitBridge.swift` re-exports the three modules, wires the host hooks and keeps the Tenra-model adapters (custom category colours, logo registry, breakdown → `DonutSlice`, the stat-card sparkline). Since 2.9.0 its transaction rows (`TransactionRow` under `TransactionCardView`), account and category card pickers (`SnapCardPicker`), live transcript (`StreamingText`), custom period sheet (`DateRangePickerSheet`), background options (`OptionCardPicker`), voice cards (`.cascadeIn`), period pagers (`PagerArrows`) and backup overlay (`.progressOverlay`) are DesignKit's too, as thin adapters over its models. Its Finances cards use `PackedCircleIcons(style: .shelf)` (4.5.0; whole 48 pt tiles in a 160 pt row since 4.15.0, 36 pt in a pocket from 4.5.1, the rest in "+N"; 4.4.0's shelf replaced 3.3.0's `.fan`). Since 3.5.0 search suggestions (`.dsSearchSuggestions`: History with its categories and subcategories, link payments, subcategory search). Since 4.6.0 the pieces of its AI assistant: `ParticleCreature` (the mascot), `MessageBubble`, `SuggestionChips`; since 4.8.0 its tab (`CreatureTabLabel` over `CreatureGlyph`) and its field's attach menu and microphone (`MessageComposer(leading:onVoice:)`). Since 4.10.0 Ten speaks in words of light and gestures (`speech:`, `.creatureGesture`), since 4.11.0 it lives on its own and thinks pictures (`.creatureAmbience`, `CreatureSpeech(symbol:label:)`), since 4.12.0 it wears accessories (`accessory:`: holidays, a crown, its wardrobe), since 4.13.0 it stands in its empty lists (`EmptyState(…) { artwork }`, a line and a point at the button). Since 4.14.0 the last generic views it drew itself: `AmountEntrySheet` (money towards a goal or a debt), `ListCard` (its assistant's cards; `FormSection(style: .glass)` since 5.0.0), `NoticeCard` ("Ten writes"), `VoiceOrbButton` (the voice stop orb), `PickerCarousel` (Ten's wardrobe) and `NavigationPickerRow(style: .list)` (Settings' voice language; since 7.0.0 every form and settings row of it is a `UniversalRow`). Since 5.3.0 (its #79, docs/adoption.md) every mood, emotion and gesture of Ten (`.working(progress:)` while a statement is read, gesture haptics on reactions, `.creatureFollowsTilt()` on Home, `ParticleCreature.image` on notifications), `MessageBubbleTransition` in the chat (its step in words under `.thinkingShimmer` while Ten thinks, in place of 5.3.0's `TypingIndicator`), `OptionCardPicker` for Home's background (a carousel of previews only since 6.0.0), and `StatusBanner`, `HeroSymbol`, `StepTracker`, `.spotlight` (its first-launch hints), `LiveAmountText`, `SpentBudgetText`, `.sparkleBurst`. Since 8.2.0 its assets are `HoldingCard`s (`AssetCard`, its #105). From 8.9.0's list (2026-11-25, docs/adoption.md) its subcategory picker is `SearchablePicker`, Ten's chat has day lines (`ConversationDivider`), saves and a statement's import are spoken (`AccessibilityAnnouncer`) and Ten's reply text is read by `ArticleBody.Block.parse(markdown:)`; `InfoTip` and `MessageBubble(markdown:)` for replies it declined. Its guide: `docs/design-system.md` (the bridge, every adapter and the component under it, screen patterns, amount rules) |

**Platina** (2026-11, a PlayStation trophy tracker, in development) is the third consumer:
`ios/project.yml` (XcodeGen), `exactVersion: "X.Y.Z"`, moved by its own DesignKit update workflow
since 2026-11-25 (on the Xcode 27 image; its CI lints at the pinned version, and the bump runs
`sync_agents_block.py`). Swift 6, iOS 26, iPhone and iPad (a Mac runs
it as "Designed for iPad"; its content keeps to `.readableWidth()`, 8.13.0); accent
Plasma (light `#D6006F`, dark `#FF4FA0`; the owner's choice of 2026-11-25, `#3573BA` before) through
`DesignKitTheme.accent`; since 8.12.0 (its #1) grey surfaces
(`DesignKitTheme.surface = .fill`). All of its interface is DesignKit's: forms and lists
(`FormSection`, `UniversalRow`, `CardList`, `ItemRow`, `ChecklistRow`), its assistant Plati
(`ParticleCreature`, `CreatureTabLabel`, `MessageBubble(markdown:)`, `ConversationDivider`,
`MessageComposer`, `TypingIndicator`, `SuggestionChips`), progress and trophies (`ProgressRing`,
`LinearProgressBar`, `StreakCard`, `CalendarHeatmap`, `BarChart`, `AchievementMedal`,
`.holographic`), sessions (`LiveSessionBar`, `RelativeTime`), friends (`PersonRow`, `.card` on a
friend's screen), guides (`ArticleBody`,
`ExpandableText`), picking (`SearchablePicker`), its game screen
(`.heroBackground(clearHeight:picture:)`, 8.14.0), sharing (`ShareCardSheet`). Its guide:
`CLAUDE.md` («DesignKit») and `docs/domains/design.md`. CI's `platina` job builds it against this checkout
on GitHub's Xcode 27 image, as its own CI does (since 8.17.4), and the Gallery's badges read its code
since 8.17.1 (CI's `Gallery badges` job checks it out with Tenra and Dalada).

**Dalada since 8.12.0** (its #77, version 1.0.4) draws its surfaces as a grey fill too
(`DesignKitTheme.surface = .fill` in its `AppEnvironment`); Tenra keeps Liquid Glass.

A consumer sees a DesignKit change when its pin moves. Each app's **DesignKit update** workflow
(`.github/workflows/designkit.yml` in the app) checks for a newer release tag daily, bumps the
pin, builds and tests, and commits the bump to the app's `main` when green (Platina's since
2026-11-25). CI's `dalada`, `tenra` and `platina` jobs build the three apps against the current
checkout, so a change that would break one fails here first (manual runs take `dalada_ref` /
`tenra_ref` / `platina_ref` to check an app branch).

## Source of Truth & Sync

- **Since 2026-10 (DesignKit 0.3.0):** both apps consume DesignKit, and it is the only place
  design-system code lives. Apps add or change components by PR here (develop with Xcode's
  local package override: drag the local DesignKit folder into the app's project), or ask for one
  with the issue template "Component request" (`.github/ISSUE_TEMPLATE/`), CI builds
  every consumer, merge → release tag → each app's update workflow bumps it. Tenra's look stays
  the reference: a visual change to a shared component is a design decision, called out under
  `### Changed` in the PR's release note (`.changes/`, which becomes the CHANGELOG.md section).
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

Host hooks (set once in `App.init()`): `DesignKitTheme.accent`, `DesignKitTheme.surface` (8.12.0,
`.glass` or a grey `.fill`), `DesignKitFonts.registerIfNeeded()`,
`DesignKitLogoLoader.loader`, `DesignKitPhotoLoader.loader` / `.cached` (3.1.0, `RemotePhoto`),
`DesignKitIconPhotos.save` / `.isPhoto` (8.5.0, `IconPicker`'s Photo tab),
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
   settings list is `UniversalRow(_:icon:accessory:)` (7.0.0), in a `FormSection` card that
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
   badges` job compares them with Tenra's, Dalada's and Platina's sources (5.2.0; Platina 8.17.1). Give it `dos:` / `donts:` when
   there is a way it is misused (8.9.0); its `since:` is the token `vNext`, which the release bot
   turns into the number. `python3 .github/scripts/components_reference.py build` shows the
   page reads; the release bot writes docs/components.md after the merge. Add a snapshot test in `Gallery/SnapshotTests` (the skeleton's in
   `SkeletonsSnapshotTests`; one Liquid Glass card per snapshot; `named:` tells them apart),
   then record it with a manual CI run, `record_snapshots: missing` (docs/snapshots.md).
5. Add any new `String(localized:)` key to `docs/localization-keys.md` and its English value
   to `Gallery/Gallery/Localizable.xcstrings`.
6. Update `docs/design-system.md` (§0 inventory + the component's section), and add the
   component under `### Added` in the PR's note in `.changes/` (with the app view it replaces
   under `### Migration`).
7. Push; CI must be green on the package, Gallery, snapshot, Dalada and Tenra jobs.

## API Stability & Versioning

- Semantic versioning with git tags (`0.2.0`, …). Consumers pin a version (`exact:` or
  `.upToNextMinor(from:)`), never a branch.
- **Cutting a release:** the PR that should ship adds a note, `.changes/<branch>-<date>-<word>.md`,
  with `bump: patch | minor | major` (a major also `version: X.0.0`) and the release's text,
  and writes the token `vNext` wherever it would name its version. It never edits `VERSION`,
  the `## X.Y.Z` headings of CHANGELOG.md or docs/components.md(.json). On merge, the release
  bot (`.github/workflows/release.yml`, `.github/scripts/release.py run`) gives the notes the
  next number, writes the CHANGELOG section with the PR link, `VERSION` and the component
  reference, replaces the token, commits `Release X.Y.Z`, tags it and creates the GitHub Release
  whose notes are that section (tags are created by Actions; the Claude session's git proxy
  only pushes branches), then starts TestFlight's Gallery build on the tag, with the section as
  "What to Test"; the Gallery's Updates screen shows it. CI's `Changelog` job checks the branch
  and says what a merge would release now ([docs/releasing.md](docs/releasing.md)).
- **A release's text** (the note, then the CHANGELOG section the bot makes of it) is a line or
  two on what the release is, then the sections that apply, in this order: `### Added` (new
  API), `### Changed` (what looks or behaves differently in an app after the bump),
  `### Deprecated` (old → new), `### Removed` (majors only), `### Fixed`, `### Migration` (what
  an app changes, old → new, a code block where the API changes) and `### Gallery and tooling`.
  English, no em dashes, one level of `- ` items. CI's `Changelog` job
  (`.github/scripts/changelog.py check`, `release.py check`) fails when the format is off.
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

## Open Work

Open tasks are files in [docs/backlog/](docs/backlog/) (the project standard's block below says how
they are written); designs and plans in flight are in `docs/plans/`. New benchmark candidates go
in [docs/benchmark.md](docs/benchmark.md) first, then become a task. How the system got here,
release by release (the audits, the owner's reviews, the majors): [CHANGELOG.md](CHANGELOG.md) and
[docs/archive/known-gaps.md](docs/archive/known-gaps.md).

## Reference Docs

| Working on… | Read first |
|---|---|
| Tokens, modifiers, any component, amount formatting, animation rules | [docs/design-system.md](docs/design-system.md) |
| One component: what it is for, initialisers, rules, do and don't, skeleton (generated) | [docs/components.md](docs/components.md) |
| DesignKit's rules for an app's agent (the block the apps' CLAUDE.md carries) | [docs/agents.md](docs/agents.md) |
| Charts, progress, gauges, OrbChart, Swift Charts patterns | [docs/charts.md](docs/charts.md) |
| Motion and effects: springs, budgets, SF Symbol motion, transitions, celebrations, Reduce Motion | [docs/motion.md](docs/motion.md) |
| Package traps (public API, Xcode 26/27, bundles) and SwiftUI layout traps | [docs/gotchas.md](docs/gotchas.md) |
| Localized strings used by components | [docs/localization-keys.md](docs/localization-keys.md) |
| Gallery TestFlight pipeline | [docs/testflight.md](docs/testflight.md) |
| Cutting a release: the note in `.changes/`, the version token, what the release bot does, recovering a failed run | [docs/releasing.md](docs/releasing.md) |
| Snapshot tests: what is covered, recording references, the pinned Xcode | [docs/snapshots.md](docs/snapshots.md) |
| What each version added and changed, and how to move an app to it (also the Gallery's Updates screen) | [CHANGELOG.md](CHANGELOG.md) |
| Moving an app to 2.0 (renames, `DSButton`, icon sizes, visual changes) | [docs/migration-2.0.md](docs/migration-2.0.md) |
| Moving an app to 3.0 (removed names and their replacements, card colours) | [docs/migration-3.0.md](docs/migration-3.0.md) |
| Moving an app to 4.0 (`SectionHeader.Style.list` removed) | [docs/migration-4.0.md](docs/migration-4.0.md) |
| Moving an app to 5.0 (`ListCard` removed, `FormSection(style: .glass)` in its place) | [docs/migration-5.0.md](docs/migration-5.0.md) |
| Moving an app to 6.0 (`OptionCardPicker`'s `style:` and `OptionCard` removed) | [docs/migration-6.0.md](docs/migration-6.0.md) |
| Moving an app to 7.0 (the twelve rows → `UniversalRow(accessory:)`, the icon rule) | [docs/migration-7.0.md](docs/migration-7.0.md) |
| Moving an app to 8.0 (glass sections and their dividers, `CardList`, `.compact` and `style:` removed) | [docs/migration-8.0.md](docs/migration-8.0.md) |
| Moving an app to 9.0 (the colour names deprecated in 8.21.0: roles, `AppColors.Data`, finance colours in the app) | [docs/migration-9.0.md](docs/migration-9.0.md) |
| The project's passport, the index of these documents, open tasks | [docs/project.md](docs/project.md), [docs/README.md](docs/README.md), `docs/backlog/` |
| What exists vs Apple HIG / Material / Fluent / Carbon / Polaris / Atlassian / Astryx, next candidates | [docs/benchmark.md](docs/benchmark.md) |
| Components no app uses yet and where they could go (for the app sessions) | [docs/adoption.md](docs/adoption.md) |
| Where a component goes (Gallery sections, source folders), how its Gallery page is built | [docs/gallery-structure.md](docs/gallery-structure.md) |
| How an app uses DesignKit (its adapters, screens, effects in use) | Tenra's `docs/design-system.md`, Dalada's `CLAUDE.md` («Компоненты интерфейса»), Platina's `CLAUDE.md` («DesignKit») and `docs/domains/design.md` |

<!-- warehouse:standard:start -->
<!-- Стандарт Warehouse, версия 1. Не править здесь: блок переписывает workflow standard.yml из standard/agents.md репозитория Warehouse. -->

## Стандарт ведения проекта

Один порядок во всех проектах владельца. Источник: `standard/` в репозитории
[Warehouse](https://github.com/dkicekeeper/Warehouse). Соблюдение проверяет CI (workflow
`standard.yml`); локально: `python3 -I <Warehouse>/standard/lint.py --root .`

### Где что лежит

```
docs/
├── README.md      оглавление: строка на каждый документ docs/ и docs/domains/
├── project.md     паспорт проекта
├── backlog/       открытые задачи, файл на задачу
├── plans/         дизайн-документы и планы в работе (и навыков superpowers тоже)
├── decisions/     действующие решения владельца, файл на решение
├── domains/       по файлу на предметную область
├── public/        сайт GitHub Pages
├── archive/       всё неактуальное: backlog/, plans/, decisions/ и остальная история
└── <имя>.md       остальные актуальные документы, плоско
```

- В `docs/` только актуальное: проект как он есть и работа в ходу. Неактуальное уезжает в
  `docs/archive/` тем же коммитом, который сделал его неактуальным.
- Новых папок в `docs/` не заводят. Путь, который читает инструмент, вносится в
  `docs/.standard.json` (`{"ignore": [{"path": "…", "reason": "…"}]}`).
- Имена: строчные латинские буквы и цифры, слова через дефис, даты ISO. Исключения:
  `README.md`, коды локалей.
- В актуальных документах нет истории («раньше было так»): она в сообщении коммита и в архиве.
- Новый документ получает строку в `docs/README.md`. Ссылки внутри `docs/` и из `CLAUDE.md`
  должны вести на существующие файлы.
- Бессрочные документы (стратегия, продвижение) лежат плоско; в `docs/plans/` только работа
  с концом.

### Форматы

Шапка: YAML между строками `---` в начале файла. Только эти ключи и значения.

**Задача** `docs/backlog/<ГГГГ-ММ-ДД>-<слово>.md` (имя файла и есть её id; счётчика нет):

```
---
status: ready        # idea | ready | in-progress | blocked | done | dropped
type: feature        # feature | bug | chore | research | content | growth
priority: 2          # 1 срочно, 2 обычно, 3 когда-нибудь
size: m              # s до часа, m одна сессия, l нужен план
created: 2026-11-26
updated: 2026-11-26
---
# Название задачи

Зачем: какую боль это снимает.

Готово, когда:
- проверяемое условие.

Заметки: что известно, ссылки.
```

Ещё четыре ключа, когда они нужны: `needs-owner: "что нужно от владельца"` (такая задача
`blocked`, не `ready`), `plan: plans/<файл>.md` (путь от `docs/`), `branch: claude/…` (ставит
сессия, которая взяла задачу), `pr: 142` (когда PR открыт). Списки пишутся в одну строку в
скобках. В репозиториях с английскими документами разделы называются `Why`, `Done when`,
`Notes`. У `idea` достаточно заголовка и абзаца; `priority` и `size` обязательны с `ready`.

**План** `docs/plans/<ГГГГ-ММ-ДД>-<тема>.md`: `status` (draft | approved | in-progress | done |
dropped), `kind` (design | plan), `created`, `updated`, `approved` (дата одобрения владельцем,
обязательна с `approved`), `tasks: [id, id]`.

**Решение** `docs/decisions/<ГГГГ-ММ-ДД>-<тема>.md`: `status` (active | superseded), `decided`,
`by` (owner | claude), `supersedes: <id>`; в тексте строки «Решение: …» и «Почему: …».

**Паспорт** `docs/project.md`: `name`, `stage` (idea | development | beta | live | maintenance),
`kind` (ios-app | web | library | service), `platforms: [ios]`, `standard: 1`, `links:` с
вложенными `store`, `site`, `testflight`; ниже — что это, для кого и чем проект занят сейчас.

Закрытое живёт только в архиве: задача `done` или `dropped` — в `docs/archive/backlog/`, план
`done` или `dropped` — в `docs/archive/plans/`, решение `superseded` — в
`docs/archive/decisions/`. Переносит файл (`git mv`) тот же PR, который его закрыл.

### Готово к работе (DoR)

Задача `ready`, когда:

1. Есть «Зачем» и «Готово, когда» с проверяемыми условиями.
2. Нет открытого вопроса к владельцу (иначе она `blocked` с `needs-owner`).
3. Стоят `type`, `priority`, `size`.
4. У задачи размера `l` есть одобренный план (`plan`, статус плана `approved` или дальше).

Задачу, которая не `ready`, в работу не берут: сначала доведи её до `ready` или спроси владельца.

### Сделано (DoD)

Задача `done`, когда:

1. Все условия «Готово, когда» выполнены и проверены, а не предположены.
2. CI репозитория зелёный на ветке.
3. Документы, которые изменение сделало устаревшими, обновлены тем же PR.
4. Изменение, которое видит пользователь, записано в заметки к выпуску проекта, если они есть.
5. Файл задачи перенесён в `docs/archive/backlog/` со статусом `done` и номером PR; план, у
   которого закрыты все задачи, — в `docs/archive/plans/`.
6. Новое, что всплыло по ходу и не сделано, записано задачами в `docs/backlog/`.

### Чеклисты

**Начало работы.** Прочитай `docs/project.md`. Найди задачу в `docs/backlog/` или создай её.
Проверь DoR. В своей рабочей ветке поставь `status: in-progress`, `branch` и обнови `updated`.

**Завершение.** Пройди DoD по пунктам. Закончи сообщение строкой состояния (ниже).

**Выпуск** (приложения). Версия поднята. Заметки к выпуску на всех языках проекта. Сборка в
TestFlight из зелёного `main`. Шаги владельца перечислены в строке состояния. Подробности
проекта — в его `docs/release.md`.

**Новый проект.** Скопируй `standard/template/` из Warehouse. Заполни `docs/project.md`. Запиши
первую задачу. Добавь `.github/workflows/standard.yml` (копия `standard/workflow.yml`) и хук
отчёта сессии (`hooks/` в Warehouse).

### Строка состояния для Warehouse

Каждое сообщение, после которого ты останавливаешься, заканчивай отдельной последней строкой:

`Статус: <состояние> — <одна строка>`

- `ждёт владельца` — без владельца дальше нельзя: что именно от него нужно (решение, мерж, проверка на устройстве, секрет).
- `работаю` — ты остановился, но вернёшься сам: чего ждёшь (CI, событие PR, таймер). Если следишь за PR и чинишь его — `работаю — слежу за PR #N`.
- `готово` — работа закончена и от владельца ничего не нужно: что сделано.

Строку читает сервис Warehouse и показывает владельцу; без неё сессия попадает в список «без статуса».

<!-- warehouse:standard:end -->
