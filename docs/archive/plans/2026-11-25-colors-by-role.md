# Colours by role Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One name per colour role in `AppColors`, no finance colours in the core, accent text that
reads at 4.5:1, `CurrencyList` on the cards everyone else uses; every old name deprecated with its
replacement, no existing value changed except where the spec lists a visual change.

**Architecture:** New role tokens next to the old ones; the old ones forward to the new and carry
`@available(*, deprecated, message:)`. DesignKit's sources and the Gallery move off every
deprecated name, so a build of the package and the Gallery has no deprecation warning from
`AppColors`. Apps keep compiling (warnings only) until 9.0.0 removes the names; rewrites for them
go to `scripts/migrations/9.0.0.json`.

**Tech Stack:** Swift 5 mode, SwiftUI, iOS 26, swift-testing, swift-snapshot-testing, Python 3 (scripts).

**Spec:** `docs/superpowers/specs/2026-11-25-colors-mercury-refresh-gallery-design.md` (part A).
Starts after the `.surfaceBackground` release has merged: the branch restarts from `main`.

## Global Constraints

- No value of an existing token changes (spec A, goal "Ни один существующий токен не меняет
  значения"). Visual changes come only from components switching tokens (A4, A5, A8).
- Container look unchanged (owner's decision 6): opaque `secondarySystemBackground` /
  `systemGray5` on glass, `tertiarySystemFill` / `secondarySystemFill` under `SurfaceStyle.fill`.
- `accent` and `accentFill` stay flat and not deprecated.
- Hash palette: 14 colours, order and values frozen; `paletteIndex(for:)` unchanged.
- Release note `.changes/focused-noether-pwdn1m-2026-11-25-roles.md`, `bump: minor`; sections in
  CLAUDE.md order; `vNext` for the version; English, no em dash.
- Deprecation messages name the replacement: `"Use AppColors.Status.negative."`.

## Review Focus

1. A Color-typed parameter given a deprecated token whose replacement is a `ShapeStyle`
   (`bgMuted` → `Background.containerStrong`): the build fails, not warns. Use
   `SurfaceStyle.containerStrong` (a `Color`) there; Task 2's step 3 greps for it.
2. Accent as text in dark mode on a `.fill` card (Platina's old blue read 3.49:1): `Text.action`
   must reach 4.5 on `#1C1C1E` — `ContrastTests.actionTextReads` covers Tenra, Dalada, Platina.
3. A deprecated name used inside DesignTokens itself would warn in the package build: the new
   tokens are built from `UIColor` values, never from the deprecated names.
4. `AppColors.Data.color(for:)` must give the same colour as `CategoryColors.color(for:)` for every
   name, or every category re-colours — `DataColorsTests.sameAsCategoryColors`.
5. Snapshots that use `AppColors.income` for sample money must not change because the token is
   deprecated: the Gallery gets `GallerySamples.income` with the same value.

---

### Task 1: Role tokens and the container style

**Files:**
- Modify: `Sources/DesignTokens/AppColors+Semantic.swift` (Background: `page`, `card`, `sheet`, `floating`, `container`, `containerStrong`; deprecations of `base`, `elevation1/2/3`, `neutral1`, `neutral2`, `fill`)
- Modify: `Sources/DesignTokens/AppSurface.swift` (`SurfaceStyle.container` / `.containerStrong`; `SurfaceContainer`; deprecate `SurfaceStyle.neutral1/2`, `SurfaceNeutral`, `.surfaceNeutral1/2`; `surfaceBackground` reads `page` / `card`)
- Modify: `Sources/DesignTokens/AppModifiers.swift` (`CardSurface` draws `Background.card`)
- Test: `Tests/DesignComponentsTests/SurfaceStyleTests.swift`

**Interfaces:**
- Produces:
  - `AppColors.Background.page: Color` (`.systemBackground`), `.card: Color` (`.secondarySystemBackground`), `.sheet: Color` (white / `#1C1C1E`), `.floating: Color` (white / `#3A3A3C`).
  - `AppColors.Background.container: SurfaceContainer`, `.containerStrong: SurfaceContainer`.
  - `public struct SurfaceContainer: ShapeStyle { public enum Level { case standard, strong }; public init(_ level: Level) }`
  - `SurfaceStyle.container: Color`, `SurfaceStyle.containerStrong: Color` (the values of today's `neutral1` / `neutral2`).

- [ ] **Step 1: Failing tests** in `SurfaceStyleTests`: `rolesKeepTodaysValues` (`page == Color(.systemBackground)`, `card == Color(.secondarySystemBackground)`, `sheet` and `floating` resolve to the `elevation1` / `elevation3` RGB in both themes); `containerFollowsSurface` (`SurfaceStyle.glass.container == AppColors.Background.card`, `SurfaceStyle.fill.container == Color(.tertiarySystemFill)`, `SurfaceStyle.fill.containerStrong == Color(.secondarySystemFill)`, `SurfaceContainer(.standard).resolve(in:)` per surface). Update the three `surfaceBackground…` tests to `page` / `card`. Existing tests on deprecated names move to the new names.
- [ ] **Step 2: Push; RED on CI** (missing names). Expected: the package tests job fails to compile `SurfaceStyleTests`.
- [ ] **Step 3: Implement** the names above; old names forward to new ones with deprecation messages: `base` → "Use AppColors.Background.page.", `elevation1` → `sheet`, `elevation3` → `floating`, `elevation2` → "Use AppColors.Background.sheet or .floating.", `neutral1` → "Use AppColors.Background.card for an opaque grey surface, AppColors.Background.container inside a card.", `neutral2` → `containerStrong`, `fill` → `container`, `SurfaceStyle.neutral1/2` → `container` / `containerStrong`, `SurfaceNeutral` / `.surfaceNeutral1/2` → `AppColors.Background.container` / `.containerStrong`.
- [ ] **Step 4: Push; GREEN on CI** (package tests job).
- [ ] **Step 5: Commit** — "Background roles: page, card, sheet, floating, container".

### Task 2: DesignKit and the Gallery off the deprecated background names; `CurrencyList` on cards

**Files:**
- Modify: every Source and Gallery file listed by `rg -l "Background\.(base|elevation[123]|neutral[12]|fill)\b|surfaceNeutral[12]|\.neutral[12]\b|SurfaceNeutral\b" Sources Gallery`
- Modify: `Sources/DesignComponents/Amounts/CurrencyList.swift` (no `baseAlt` page, cards are `cardStyle()`)

- [ ] **Step 1: Replace** by role: page backgrounds → `page`; the grey surface `MessageBanner` draws under `.fill` → `card`; shapes inside a card (plates, fields, chips, tracks, skeletons) → `AppColors.Background.container` / `.containerStrong`; `Tooltip` → `floating`; `PickerCarousel`, `MessageComposer` → `sheet`.
- [ ] **Step 2: `CurrencyList`** — drop `.background(AppColors.Background.baseAlt)`; the two card backgrounds become `.cardStyle()` with the same radius.
- [ ] **Step 3: Verify** — Run: `rg -n "Background\.(base|elevation[123]|neutral[12]|fill)\b|surfaceNeutral[12]|SurfaceNeutral\b" Sources Gallery`. Expected: matches only inside `AppColors+Semantic.swift` / `AppSurface.swift` definitions. Run: `rg -n "Color = AppColors\.Background\.container" Sources Gallery` — Expected: nothing (a `Color` parameter takes `SurfaceStyle.container`).
- [ ] **Step 4: Push; CI** — Expected: package + Gallery build green; snapshot job fails only on `CurrencyList` references.
- [ ] **Step 5: Record** `record_snapshots: failed`, then a `never` run green. Commit — "Components and the Gallery read the background roles; CurrencyList on cards".

### Task 3: Readable accent text

**Files:**
- Modify: `Sources/DesignTokens/AppColors+Semantic.swift` (`Text.action`)
- Modify: components that colour text or a symbol with `AppColors.accent` (`rg -n "foregroundStyle\(AppColors\.accent\)" Sources` and the `color:` / `tint` call sites that end in a `Text`)
- Test: `Tests/DesignComponentsTests/ContrastTests.swift`

- [ ] **Step 1: Failing test** `actionTextReads`: for Tenra's `.indigo`, Dalada's green pair, Platina's Plasma (`#D6006F` / `#FF4FA0`) set as `DesignKitTheme.accent` (restore after), `AppColors.contrastRatio(AppColors.Text.action, background)` ≥ 4.5 for background in [`Background.page`, `Background.card`] × [light, dark].
- [ ] **Step 2: Push; RED on CI** — Expected: fails for Tenra's indigo on the dark card (3.36:1 raw) and Dalada's green on the light card (3.80:1 raw); Plasma already passes raw.
- [ ] **Step 3: Implement** `Text.action: Color { AppColors.readable(DesignKitTheme.accent) }` (computed: the accent is set at launch). Switch text and symbols that read on the page or a card from `AppColors.accent` to `AppColors.Text.action`; leave `tint`, `fill`, `stroke`, `strokeBorder`, selection outlines, accent fills and `.opacity` tints on `accent`.
- [ ] **Step 4: Push; GREEN on CI**; snapshots that change are recorded with `failed` (list them in the note's `### Changed`).
- [ ] **Step 5: Commit** — "Accent text reads at 4.5:1: Text.action is the readable accent".

### Task 4: `AppColors.Data` and one palette source

**Files:**
- Modify: `Sources/DesignTokens/AppColors.swift` (`CategoryColors` forwards to `AppColors.Data`, deprecated)
- Modify: `Sources/DesignTokens/AppColors+Palette.swift` (internal hue table; `Palette.rgb` and the hash/picker lists read it)
- Create: `Sources/DesignTokens/AppColors+Data.swift`
- Modify: `Sources/DesignComponents/Rows/RowAccessory.swift:160`, `Sources/DesignComponents/Effects/ParticleBurst.swift:41`, Gallery uses of `CategoryColors`
- Test: `Tests/DesignComponentsTests/CategoryColorsTests.swift` → rename to `DataColorsTests.swift`

**Interfaces:**
- Produces: `public extension AppColors { enum Data { static func color(for: String, opacity: Double = 1) -> Color; static func paletteIndex(for: String) -> Int; static var palette: [Color]; static let pickerPalette: [String]; static let series: [Color] } }`

- [ ] **Step 1: Failing tests** in `DataColorsTests`: the existing four tests rewritten against `AppColors.Data`; `sameAsCategoryColors` (for 200 names `"name\(i)"` and `["Food", "Транспорт", "🍕"]`, `Data.paletteIndex == CategoryColors.paletteIndex`); `hashPaletteFrozen` (`pickerPalette.prefix(14) == ["#3b82f6", "#8b5cf6", "#ec4899", "#f97316", "#eab308", "#22c55e", "#14b8a6", "#06b6d4", "#6366f1", "#d946ef", "#f43f5e", "#a855f7", "#10b981", "#f59e0b"]`); `seriesNeighboursDiffer` (8 colours, all distinct, adjacent hues ≥ 45° apart on the colour wheel, measured with `UIColor.getHue`).
- [ ] **Step 2: Push; RED on CI.**
- [ ] **Step 3: Implement** — `series` order: blue `#3b82f6`, orange `#f97316`, teal `#14b8a6`, pink `#ec4899`, violet `#8b5cf6`, yellow `#eab308`, green `#22c55e`, rose `#f43f5e`. The hue table holds each hex once; `Palette`'s 13 deep values unchanged.
- [ ] **Step 4: Push; GREEN on CI.** Commit — "AppColors.Data: colours for named things and chart series".

### Task 5: Finance colours leave the core; flat names deprecated

**Files:**
- Modify: `Sources/DesignTokens/AppColors.swift` (deprecate `bgBase`, `bgCard`, `bgMuted`, `textPrimary`, `textSecondary`, `textTertiary`, `staticWhite`, `destructive`, `success`, `warning`, `planned`, `income`, `incomeText`, `expense`, `transfer`; English comments, no "iOS<26")
- Modify: `Sources/DesignComponents/Feedback/TrendBadge.swift:31` (`.up` → `Status.positive`)
- Modify: `Sources/DesignComponents/Progress/AmountComparisonBar.swift` (add `incomeColor: Color = AppColors.Status.positive` as the last init parameter; use it at :75)
- Modify: `Sources/DesignComponents/Cards/PayoffProgressCard.swift` (add `progressColor: Color = AppColors.Status.positive` before `accessory`; the "done" mark `Text.positive`)
- Modify: `Sources/DesignComponents/Rows/ScheduleRow.swift` (`detailColor` default `Text.primary`; done mark `Text.positive`)
- Modify: `Sources/DesignComponents/Rows/AmountRow.swift:108` (default `Status.info`)
- Modify: `Sources/DesignComponents/Rows/TransactionRow.swift:33-36` (doc example uses the app's own colours)
- Modify: all other Source and Gallery uses of the deprecated names; `Gallery/Gallery/GallerySamples.swift` gains `income` / `transfer` sample colours with today's values

- [ ] **Step 1: Write the failing check** — Run: `rg -c "AppColors\.(bgBase|bgCard|bgMuted|textPrimary|textSecondary|textTertiary|staticWhite|destructive|success|warning|planned|income|incomeText|expense|transfer)\b" Sources Gallery`. Expected now: about 400 matches (the RED for a rename is the list of sites).
- [ ] **Step 2: Implement** the deprecations and the component defaults above; replace every site: `textPrimary/Secondary/Tertiary` → `Text.*`, `staticWhite` → `Text.primaryOnDark`, `destructive` → `Status.negative`, `success` → `Status.positive`, `warning` → `Status.warning`, `planned` → `Status.info`, `bgBase` → `Background.page`, `bgCard` → `Background.card` or `.container` by role, `bgMuted` → `.containerStrong` (or `SurfaceStyle.containerStrong` where a `Color` is required), `income` / `transfer` in the Gallery → `GallerySamples.income` / `.transfer`, `incomeText` → `AppColors.readable(GallerySamples.income)`, `expense` → `Text.primary`.
- [ ] **Step 3: Verify** — the Step 1 command. Expected: matches only in `AppColors.swift` (the deprecated declarations).
- [ ] **Step 4: Push; CI** — package, Gallery, Dalada, Tenra build; record `failed` snapshots (TrendBadge up, AmountComparisonBar, PayoffProgressCard, ScheduleRow, AmountRow defaults) and list them under `### Changed`. Dalada or Tenra failing because they treat warnings as errors: stop and ask (spec).
- [ ] **Step 5: Commit** — "Finance colours and flat names deprecated: roles only in the core".

### Task 6: Docs, Gallery Colors screen, migrations, note

**Files:**
- Modify: `docs/design-system.md` §1 Colors (roles, the "which colour where" table from the proposals page, `SurfaceStyle.fill` renamed in 9.0.0, flat names and `CategoryColors` as deprecated, `AppColors.Data`)
- Modify: `docs/agents.md` rule 1 (groups, `accent`, `accentFill`, `Background.container`, `.surfaceBackground`, `Text.action`; finance colours are the app's)
- Modify: `CLAUDE.md:364` (`.surfaceNeutral1/2` → `Background.container` / `.containerStrong`)
- Modify: `Gallery/Gallery/Screens/ColorsScreen.swift` (sections "Flat names (1.x)" and "Financial" removed; Background shows the roles; "Category palette" becomes "Data" with `series`)
- Create: `scripts/migrations/9.0.0.json` (rewrites for every one-to-one rename above; TODOs for `bgCard`, `neutral1`, `income`, `incomeText`, `expense`, `transfer`)
- Create: `.changes/focused-noether-pwdn1m-2026-11-25-roles.md`
- Test: the Changelog job's script tests (`scripts/` tests already cover `migrate.py`; add a case for 9.0.0 if the test file lists majors)

- [ ] **Step 1: Failing check** — Run: `python3 scripts/migrate.py --from 8.18.0 --to 9.0.0 --source Gallery` (dry). Expected: error, no rules for 9.0.0.
- [ ] **Step 2: Write** `9.0.0.json`, the docs, the screen and the note.
- [ ] **Step 3: Verify** — Run the Step 1 command on a scratch copy of a file holding each old name. Expected: every one-to-one name rewritten, a TODO above each judgement call. Run `python3 .github/scripts/release.py check --base origin/main` and `python3 .github/scripts/changelog.py check`. Expected: pass, "would release" a minor.
- [ ] **Step 4: Push; CI green.** Commit — "Docs, the Colors screen and 9.0.0 rewrites for the colour roles".
