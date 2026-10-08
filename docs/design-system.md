# UI Components & Design System Guide

> Reference for Claude: which components to use, where, and how.
>
> **Source.** Adapted from Tenra's `docs/design-system.md` (Tenra `74a12c5`, 2026-09-26) — Tenra's
> design system is the reference. Rules, tokens and component contracts are Tenra's; paths point
> into this package. Call-site examples ("Used in: …") name Tenra screens — they illustrate
> intent, they are not DesignKit code.
>
> **Availability.** Section 0 lists which documented components ship in DesignKit and which
> stay in the host app (they depend on app models or services). Anything marked *app-side* is
> documented here because the rules around it are part of the shared visual language.

---

## Table of Contents

0. [What ships in DesignKit](#0-what-ships-in-designkit)
1. [Design Tokens](#1-design-tokens)
2. [View Modifiers](#2-view-modifiers)
3. [Shared Components](#3-shared-components)
4. [View Patterns](#4-view-patterns)
5. [Decision Trees](#5-decision-trees)
6. [Formatting & Display](#6-formatting--display)
7. [Haptics](#7-haptics)
8. [Remaining Native Form Views](#8-remaining-native-form-views)
9. [Animation Guidelines](#9-animation-guidelines)
10. [cardStyle Padding Contract](#10-cardstyle-padding-contract)
11. [AnimatedInputComponents Deep Dive](#11-animatedinputcomponents-deep-dive)
12. [Amount Formatting Files](#12-amount-formatting-files)

---

## 0. What ships in DesignKit

| Module | Contents |
|---|---|
| `DesignTokens` | `AppColors` (grouped `Text` / `Background` / `Status` / `Border` since 1.6.0, `pale(_:)`, flat 1.x aliases), `CategoryColors`, `AppSpacing`, `AppRadius`, `AppIconSize`, `AppTypography`, `AppAnimation` (+ `AppMotion`: springs by purpose, `MotionBudget`, `designKitMotion`, 2.2.0), `AppModifiers` (`cardStyle`, `formCardStyle`, `filterChipStyle`, paddings, `chartAppear`, `staggeredEntrance`, inline field styles), `DSButtonStyle` (`.dsButton`, 2.0.0; `.bounce`), `AmbientMotionGate`, `DesignKitTheme`, `DesignKitFonts` (Inter) |
| `DesignSupport` | `IconSource`, `IconStyle`/`IconTint`, `Icon` (a brand logo is `Icon(source: .brandService(name))`; `BrandLogoView` was removed in 2.0.0), `Formatting`, `AmountFormatter`, `AmountDisplayConfiguration`, `AmountInputFormatting`, `ExpressionEvaluator`, `CurrencyInfo`, `HapticManager`, `HapticCue` (haptics by meaning, 2.3.0), `DominantColorExtractor`, host hooks (`DesignKitLogoLoader`, `DesignKitCurrencyConverter`), `amountsHidden` (1.7.0), `matchedTransitionSourceIfPresent`, `swipeActionsContainerIfAvailable` |
| `DesignComponents` | everything in §3 not marked *app-side*, plus the chart family in §0.2, and a skeleton for every component that shows data (`<Name>Skeleton`, 1.10.0; §3 "Component skeletons") |

**Names (2.0.0).** A component is named for what it is, without `View` or `App`: `SectionHeader`,
`EmptyState`, `Avatar`, `Badge`, `Icon`, `DSButton`. The names before 2.0 are deprecated
typealiases, so old code builds with a fix-it; [migration-2.0.md](migration-2.0.md) lists them.
The tokens keep their prefix (`AppColors`, `AppSpacing`, `AppIconSize`, …): a token namespace
is not a view, and `Color` / `Font` would clash with SwiftUI. The button is `DSButton` because
`Button` is SwiftUI's.

Coverage against Apple HIG, Material 3, Fluent 2, Carbon, Polaris and Atlassian, and the next
candidates: [benchmark.md](benchmark.md).

### 0.1 Host-app hooks

DesignKit ships no networking, persistence or FX. A host app wires these once, in `App.init()`:

| Hook | Default | Wire to |
|---|---|---|
| `DesignKitTheme.accent` | `.indigo` | Brand accent behind `AppColors.accent`. Also set the asset-catalog `AccentColor` to the same colour (system chrome never reads `AppColors`). |
| `DesignKitFonts.registerIfNeeded()` | — | Call once; registers the bundled Inter variable fonts. |
| `DesignKitLogoLoader.loader` | `nil` → fallback icon | Brand-logo images for `IconSource.brandService` (`Icon`, `heroAccentGlow`). |
| `DesignKitCurrencyConverter.convert` | `nil` → nothing rendered | FX for `ConvertedAmount` / `HeroSection(showBaseConversion:)` / `CurrencyAmountInput`. |
| `DesignKitCurrencyConverter.convertSync` *(1.10.0)* | `nil` → `convert` is asked | Instant conversion from cached rates, so `CurrencyAmountInput` shows "≈ …" while the user types, and at once when the currencies change (1.14.0). |
| `DesignKitLogoCatalog.sections` / `.search` / `.domainSuffixes` *(1.10.0)* | no sections → no logos tab; `["com"]` | The brands `IconPicker` offers (titled sections of domain + name), its search, and the domains tried for a typed name (Tenra: `["com", "kz"]`). |
| Localization keys | raw key shown | Components resolve `String(localized:)` in the **host app's** main bundle. The full key list is in [localization-keys.md](localization-keys.md). |

### 0.2 Charts in DesignKit

**Trend charts (0.5.0)** over the generic `ChartPoint` / `ChartSeries` model: `LineChart`, `BarChart`, `ChartSwitcher`, `HeroSparkline`, `Sparkline`, `ChartSelectionBanner`, `ChartValuePoint`, `ChartValueFormat`. `OrbChart` (+ `DonutSlice`, `DonutSlice.foldingSlivers`, `DonutSlice.opacityStepped`), `MiniDonut`, `ProportionBar`, `LinearProgressBar`, `ProgressRing` (+ `LimitProgress`, 1.5.0), `AmountComparisonBar`, `MiniProportionBar` / `HeroProportionBar`, `MiniHalfGauge` / `HeroHalfGauge`, `MiniMilestoneGauge` / `HeroMilestoneGauge`, `MiniBarPair` / `HeroBarPair`, `HeroChartEffects` (`chartGlow`, `materialize`, `glassBar`), `ChartZoomControls` + `ChartStyle`. See [charts.md](charts.md). (`SiriGlow` and `SiriWave` became `EdgeGlow` in 2.4.0, next to `VoiceWave`: [motion.md](motion.md).)

**Removed in 1.0** (retired from Tenra 2026-07, deprecated in DesignKit until then): `BudgetProgressBar` → `LinearProgressBar`, `BudgetProgressCircle` → `ProgressRing`, `ExpenseIncomeProgressBar` → `AmountComparisonBar`, `DonutChart` + `ChartDisplayMode` → `OrbChart` / `MiniDonut`.

### 0.3 App-side (documented here, not in DesignKit)

These depend on app models/services. Port one only after replacing the dependency with a
generic input or a host hook (see [CLAUDE.md](../CLAUDE.md) → *Porting a component*).

- **Tenra models** (`Transaction`, `Account`, `CustomCategory`, `RecurringSeries`, loans, deposits): `TransactionCard`, `BudgetSettingsSection`, `EntityDetailScaffold`, `GroupedTransactionList`, `CategoryStyleHelper` / `CategoryStyleCache`, `TransactionDisplayHelper`, `CategoryDisplay`.
- **`PeriodDataPoint` adapters** (Tenra): `PeriodDataPoint: ChartPoint`, `PeriodChartSeries` → `ChartSeries`, and convenience inits keeping the old call sites (`granularity:`, `currency:`). `PeriodBreakdownRow` and `ChartAxisHelpers`' period labels stay app-side.
- **Tenra services**: `DateFormatters`, `FastDateParser`. (`EditableHeroSection`, `IconPickerView`, `CurrencySelectorView`, `AmountInputView` and `CurrencyListContent` became `EditableHero`, `IconPicker`, `CurrencyPickerMenu`, `CurrencyAmountInput` and `CurrencyList` in 1.10.0, behind the `DesignKitLogoCatalog` and `convertSync` hooks.)
- **Screens over Tenra models**: the account, category and time filter sheets (built from `CheckmarkRow`), the home sections (`FinanceCard` + `PackedCircleIcons`).
- **Domain convenience inits / adapters**: `MenuPickerRow where T == RecurringFrequency / LoanType / ReminderOption`, `StatusIndicatorBadge`'s `RecurringSeries.entityStatus`, `DonutSlice.from([CategoryBreakdownItem])`, Tenra's `InsightTrendBadge` (`InsightTrend` → `TrendBadge`), Tenra's adapters under the old names of the components ported in 1.1.0–1.5.0 (`AccountRow` and `CategoryRow` → `AmountRow` since 2.1.0, `CategoryChip` → `ProgressRingTile`, `BudgetProgressRow` → `LimitProgressCard`, …), Dalada's `RuleStatusBadge` (`RuleStatus` → `Badge`).

---

## 1. Design Tokens

All tokens live in `Sources/DesignTokens/`. Never use raw values — always reference the token.

### Colors (`AppColors`)

**Semantic colours v2 (1.6.0)**: tokens are grouped by what they colour and named *group / name / modifier* (`AppColors.Text.secondaryOnDark`, `AppColors.Status.warningPale`). Every token has a doc comment saying where it goes; the Gallery's Colors page shows them with their use.

Modifiers:
- **`OnDark` / `OnLight`**: the same value in both themes, for content on photos, gradients and coloured headers (a trip photo in Dalada, `GradientOrbsBackground`, an accent hero).
- **`Pale`**: a tinted container behind status text, badges and icons. `AppColors.pale(_:)` makes one from any colour (a category colour too): 12% in light, 24% in dark. Since 1.8.0 every tinted container in DesignKit uses it, so they are equally strong everywhere: `Badge` (tinted), `TrendBadge` (pill), `RecommendationBox`, `HeroSymbol`, `Avatar` (initials), the round icons of `LimitProgressCard` and `AmountRow`'s tinted icon, `ActivityTimeline` markers, the `ScoreGaugeCard` grade and `TargetProgressCard` badge, `MonthCalendar`'s today, `TagInput` chips and the calculator's operator keys. Progress tracks and chart fills are not containers and keep their own opacity.
- **Opaque** (`Border.opaque`): no transparency, for outlines that overlap.

**`AppColors.Text`** — text and icons

| Token | Value | Use |
|---|---|---|
| `primary` / `secondary` / `tertiary` | `.primary` / `.secondary` / `.gray` | Main text; subtitles and metadata; hints, disclaimers, disabled labels |
| `action` | `DesignKitTheme.accent` | Links, text buttons |
| `positive` / `negative` / `warning` | `.green` / `.red` / `.orange` | A rise or "done"; a fall or an error; a warning |
| `onAccent` | `.white` | On an accent fill (filled button, badge) |
| `primaryOnDark` / `secondaryOnDark` / `tertiaryOnDark` | white; iOS dark-mode label grey at 60% / 30% | On dark photos and headers, both themes |
| `primaryOnLight` / `secondaryOnLight` / `tertiaryOnLight` | black; iOS light-mode label grey at 60% / 30% | On light photos and pale fills, both themes |

**`AppColors.Background`** — screens, surfaces, containers

| Token | Value (light / dark) | Use |
|---|---|---|
| `base` | `.systemBackground` | The screen |
| `baseAlt` | `.systemGroupedBackground` | A grouped-list screen |
| `elevation1` / `elevation2` / `elevation3` | white / `#1C1C1E`, `#2C2C2E`, `#3A3A3C` | Sheets and cards on base; cards on elevation 1; above everything. In light a shadow tells the levels apart, in dark the colour (iOS's own elevated backgrounds) |
| `neutral1` | `.secondarySystemBackground` | Opaque, minimal contrast: fields, grouped blocks, inactive chips |
| `neutral2` | `.systemGray5` | Opaque, more contrast: progress tracks, sunken controls, secondary buttons |
| `fill` | `.tertiarySystemFill` | Translucent container on any surface, glass included |
| `fillOnDark` / `fillOnLight` | white 15% / black 5% | Translucent container on dark / light photos, both themes |
| `overlayOnImage` | black 30% | Darkens a photo under text |

**`AppColors.Status`** — banners, badges, notices: `info` (`.blue`), `positive` (`.green`), `negative` (`.red`), `warning` (`.orange`), `neutral` (`.gray`), each with a `…Pale` container (`AppColors.pale`).

**`AppColors.Border`** — `normal` (`.separator`), `opaque` (`.opaqueSeparator`), `selected` (accent), `darkModeOnly` (clear in light, white 10% in dark: a hairline around logos, avatars and images that would melt into black), `onDark` (white 10%), `onLight` (black 5%).

**Flat names (1.x)** stay as aliases of the groups, with the same values: `bgBase` = `Background.base`, `bgCard` = `Background.neutral1`, `bgMuted` = `Background.neutral2`, `textPrimary` / `textSecondary` / `textTertiary` = `Text.*`, `destructive` = `Status.negative`, `success` = `Status.positive`, `warning` = `Status.warning`, `staticWhite` = `Text.primaryOnDark`, `planned` = `Status.info`. New code uses the groups. Since 1.15.0 every component reads `Background.*` and `Text.*`; `accent`, `destructive`, `success`, `warning` and `staticWhite` stay as they are, they name a role rather than a level.

| Token | Value | Use For |
|-------|-------|---------|
| `accent` | `DesignKitTheme.accent` (default `.indigo`) | Interactive elements, primary CTA tint. Per-app brand value — set `DesignKitTheme.accent` in `App.init()`. The host app's asset-catalog `AccentColor` must be the SAME colour — it drives system chrome (active tab tint, default buttons, search cursor). Keep the two in sync: an empty AccentColor silently falls back to system blue (Tenra shipped that until 2026-08-26). Tenra: system indigo (light 0x5856D6 / dark 0x5E5CE6). |
| `income` | RGB(0.13, 0.70, 0.37) | Income amounts (deliberately distinct from `success`) |
| `expense` | `.primary` | Expense amounts — deliberately NOT red (see comment in AppColors.swift) |
| `transfer` | Cyan-teal | Internal transfer amounts |
| `planned` | `.blue` (= `Status.info`) | Future/planned transactions |

For archived/inactive UI use `Color(.systemGray)` directly — there is no dedicated token.

**Category colors:** `CategoryColors.color(for:opacity:)` (`hexColor(for:)` before 2.1.0: it returns a colour, not a hex) — the 14-colour palette hashed by name; `CategoryColors.paletteColors` (1.10.0) is the palette itself, for an app's own name-coloured visuals (Tenra's letter avatars). DesignKit has no custom-category override; Tenra keeps its `customCategories:` / store-backed overloads app-side. The slot is `CategoryColors.paletteIndex(for:)`, an FNV-1a hash of the name: the same on every launch and device (since 0.7.0; before that it used `String.hashValue`, which Swift seeds per process, so the colour changed between launches). `CategoryColors.pickerPalette` (1.11.0) is what a user can pick (`ColorPickerRow`'s default): the 14 hash colours first, then 16 deeper and neutral shades (30 `#rrggbb` strings). The hash palette itself stays at 14: `paletteIndex` is `hash % count`, so growing it would re-colour every category and avatar that relies on the name; new colours go to the picker only.

### Spacing (`AppSpacing`)

4pt grid system. Token names are numeric only — no semantic aliases.

| Token | Value | Use For |
|-------|-------|---------|
| `xxs` | 2 | Minimum micro spacing |
| `xs` | 4 | Icon-to-text inline gaps |
| `sm` | 8 | Row vertical padding, small gaps |
| `md` | 12 | Default VStack/HStack spacing |
| `lg` | 16 | Screen horizontal padding (`.screenPadding()`), card content padding (`.cardContentPadding()`), between-card spacing |
| `xl` | 20 | Between major sections |
| `xxl` | 24 | Between screen sections |
| `xxxl` | 32 | Large screen margins |

**Horizontal-inset convention:** screen-edge insets use `.screenPadding()`; card content uses `.cardContentPadding()` (both 16pt). A bare `.padding(.horizontal, AppSpacing.lg)` that remains is *intentional internal/component spacing* (chips, rows inside cards, doubled banner insets) — do not mass-migrate it.

### Corner Radius (`AppRadius`)

| Token | Value | Use For |
|-------|-------|---------|
| `xs` | 4 | Badges, indicators |
| `md` / `card` / `button` | 12 | Standard cards and buttons |
| `lg` | 16 | Large cards |
| `xl` | 20 | Pills, filter chips, `.cardStyle()` default |
| `soft` | 12 | A skeleton shape whose component has no corner of its own (1.10.0) |

For full circles use `.infinity` inline (rare — only avatars/icon backgrounds use it). For values between tokens (8pt chips, 6pt compact corners) inline the numeric literal — no token.

### Icon Sizes (`AppIconSize`)

Two scales, named like `AppSpacing` (1.13.0): **glyphs** stand on their own, **tiles** carry
their own backing (a circle or rounded square, an avatar, a coin). A tile starts at 44 pt:
below it the backing leaves the symbol no room for `Icon`'s padding, so 40 pt is a glyph
(2.0.0).

| Glyph | Value | Use For |
|-------|-------|---------|
| `xs` | 12 | A glyph at caption size |
| `sm` | 16 | Inline icons in text |
| `md` | 20 | Toolbar, settings rows |
| `lg` | 24 | Emphasized list icons, form-row leading icons |
| `xl` | 32 | Large glyphs, bank logos in rows |
| `xxl` | 40 | An avatar, a logo in a row (`Tile.xs` before 2.0) |

| Tile (`AppIconSize.Tile`) | Value | Use For |
|-------|-------|---------|
| `sm` | 44 | The smallest tile: the icon of a content row (`Icon`'s default) |
| `md` | 48 | Empty-state icons |
| `lg` | 52 | Category coins in rows |
| `xl` | 64 | Category coins in grids, profile avatars |
| `xxl` | 72 | A ring around an `xl` tile (8 pt stroke) |
| `xxxl` | 80 | Hero icons, large action buttons (voice input) |

2.0.0: `Tile.xs` (40) is deprecated, renamed `AppIconSize.xxl`. The names deprecated in 1.13.0
are gone: `avatar` (40, now `xxl`), the old `xxl` (44, `Tile.sm`) and `xxxl` (48, `Tile.md`),
`categoryIcon` (`Tile.lg`), `mega` (`Tile.xl`), `budgetRing` (`Tile.xxl`), `ultra`
(`Tile.xxxl`).

### Container Sizes

There is no `AppSize` enum. Component-local sizes (cursor height/width, voice button diameter, CSV preview heights, etc.) live as numeric literals at use-site or as `private` constants in the component file. This is deliberate — global tokens are for 3+ shared use sites; everything else is local.

### Typography (`AppTypography`)

All use Inter variable font with Dynamic Type scaling:

| Token | Size | Weight | Use For |
|-------|------|--------|---------|
| `h1` | 34 | bold | Screen titles |
| `h2` | 28 | semibold | Detail view balances |
| `h3` | 24 | semibold | Section titles (Insights) |
| `h4` | 20 | semibold | Card headers, `EmptyState` titles |
| `bodyEmphasis` | 18 | semibold | Row names, button labels, section subheaders |
| `body` | 18 | regular | Default text |
| `bodySmall` | 16 | regular | Secondary text, subtitles |
| `caption` | 14 | regular | Timestamps, metadata, section headers |
| `caption2` | 12 | regular | Non-critical decorative text only |

For dynamic-size amount inputs use `Font.custom(AppTypography.fontFamily, …)` directly — that's the one place the family name is exposed.

**Numbers (1.8.0).** `AppTypography.numbers(_:)` is any of the styles above with tabular figures (every digit equally wide): amounts in a column line up and a number that changes (`.numericText()`) keeps its width. `FormattedAmountText`, `AmountDigitDisplay` (the amount input), `TrendBadge` percentages, `ChartSelectionBanner` readouts and the chart legend and pill amounts use it; `StatTile`, `CalculationCard` and `AvatarGroup` already used `.monospacedDigit()`. Use it for any other figure that changes or stacks: `Text(count, format: .number).font(AppTypography.numbers(AppTypography.h3))`.

**Accessibility text sizes (AX1–AX5).** Side-by-side layouts stack when `dynamicTypeSize.isAccessibilitySize` (Apple's HIG rule): a row of columns or a "title …… value" row does not truncate values or break words mid-word, it puts them one under another. Standard sizes keep the side-by-side layout untouched — branch on `isAccessibilitySize`, don't rework the regular layout. Since 1.3.0: `ComparisonCard` (before, now, change), `TotalsCard` (one total per line), `AmountRow`'s info style (the amount under the title), `MenuPickerRow` (the value under the title); since 1.5.1 `AmountRow`'s list style (a detail's amount under its text; spent, "/ limit" and the share on three lines). Snapshot tests check AX2 (`largeText`).

### Animations (`AppAnimation`)

**Springs by purpose (2.2.0)** — pick one by what the motion says; the rules, budgets, symbol
motion, transitions and effects are in [motion.md](motion.md):

| Token | Feels | Use For |
|-------|-------|---------|
| `snappy` | 0.25 s, no bounce | The answer to a touch: toggle, selection, chip, press |
| `smooth` | 0.35 s, no overshoot | Content that changes or moves |
| `bouncy` | 0.4 s, small overshoot | A playful confirmation: added, liked, done |
| `expressive` | 0.55 s, bounce 0.3 | A moment that matters (rare) |

`MotionBudget` holds the timing budgets (feedback 0.25 s, entrance 0.35 s, stagger 0.04 s ≤ 0.3 s);
`.designKitMotion(false)` stills DesignKit's motion below a view.

**2.6.0** adds surfaces and moments: `.holographic()` (a foil that follows the finger),
`.transition(.dissolve)` (a delete that breaks into dust), `ScrambleText` (a result that decodes
itself) and `.spotlight` (a coach mark round one view). All in [motion.md](motion.md).

**2.5.0** holds backgrounds still: `AuroraBackground(_ spots:)` (weighted pools of colour in
one still mesh; replaces `GradientOrbsBackground`), `.accentGlow` drawn as an aurora band by
default (`style: .soft` keeps the blurred circle), and `.grain()`. Why still: under Liquid
Glass a moving background makes the glass redraw each frame ([motion.md](motion.md)).

**2.4.0** makes the voice visible: `VoiceWave` (ribbons or an orb, listening or thinking) and
`EdgeGlow(level:)` (a Metal edge light that replaces `SiriGlow` and `SiriWave`), a comet
`.borderBeam` along the border, and `.thinkingShimmer` for text while the app works. All in
[motion.md](motion.md).

**2.3.0** adds motion for data and moments, all in [motion.md](motion.md): `LiveAmountText`
(roll-up and change flash), `.chartDrawIn` (built into `LineChart`, `BarChart`,
`HeroSparkline`), `.completionMoment` and `ProgressRing(celebratesCompletion:)`,
`SkeletonReveal` / `.skeletonReveal`, `HapticCue`, `.scrollHero`, the onboarding parallax,
`GlassActionMenu` (Liquid Glass morph) and the Metal `.ripple`. SF Symbol heroes draw in a
gradient of their tint.

The 1.x tokens, still used by the components that have them:

| Token | Type | Use For |
|-------|------|---------|
| `contentSpring` | response:0.3 damping:0.7 | Content transitions, toggles, validation errors |
| `gentleSpring` | response:0.4 damping:0.8 | Smooth value animations, amounts, empty↔loaded |
| `heroSpring` | response:0.6 damping:0.7 | Hero icon entrance (slower, dramatic) |
| `facepileSpring` | response:0.4 damping:0.7 | Staggered facepile icon pop-in |
| `progressBarSpring` | response:0.55 damping:0.72 | Animated bar width changes |
| `contentRevealAnimation` | easeOut(0.35) | Section fade-in during initialization |
| `fast` | 0.1s | Button press (raw `Double`) |
| `standard` | 0.25s | State changes (raw `Double`) |
| `slow` | 0.35s | Modals (raw `Double`) |
| `chartAppearAnimation` | spring(0.55, 0.82), reduce-motion aware | Chart entrance |
| `chartUpdateAnimation` | spring(0.5, 0.85), reduce-motion aware | Chart data updates |
| `chartBannerFade` | easeInOut(0.15), reduce-motion aware | Chart selection banner appear/disappear |

**Magic numbers:** `facepileHiddenScale` (0.5), `facepileStagger` (0.06s per icon), `chartHiddenScale` (0.94), `chartAppearDelay` (0.05s).

**Reduce-motion-aware:** `fastAnimation` (replaces `easeInOut(fast)`), `adaptiveSpring` (overshoot spring used by `BounceButtonStyle`). Check `isReduceMotionEnabled` flag directly when rolling your own.

**Component-local animation constants** live as `private enum` inside the component file (precedent: `BannerAnimation` in `MessageBanner.swift`, `OrbStyle.opacity/blur` in `GradientOrbsBackground.swift`). Don't pull single-component tunables back into `AppAnimation`.

**`BounceButtonStyle`:** `scaleEffect(0.96)` + `brightness(-0.05)` on press. Apply via `.buttonStyle(.bounce)`.

---

## 2. View Modifiers

### Layout Modifiers (`AppModifiers`)

| Modifier | Effect | When to Use |
|----------|--------|-------------|
| `.cardStyle(radius:)` | Liquid Glass (iOS 26+) or `.ultraThinMaterial` card background. Default radius: `AppRadius.xl` (20pt) | **Display cards only.** Account/Loan/Health hero cards, list cards, detail-view cards — anything without interactive `Picker(.menu)` / `Menu` inside |
| `.formCardStyle(radius:)` | `.ultraThinMaterial` card background on every iOS. Same shape/padding contract as `cardStyle`. | **Form-section cards.** `FormSection`, `BudgetSettingsSection` — any card that wraps `MenuPickerRow` / `Picker(.menu)` / `Menu`. iOS 26's `glassEffect` becomes the morph-source for menus, so single-row form sections would collapse the whole row into the popover at tap. `formCardStyle` uses Material to side-step that |
| `.filterChipStyle(isSelected:)` | Glass chip styling with accent tint when selected. Animated selection transition | Filter buttons, `UniversalFilterButton` |
| `.screenPadding()` | `.padding(.horizontal, AppSpacing.lg)` (16pt) | Screen-level horizontal insets |
| `.cardContentPadding()` | `.padding(AppSpacing.lg)` (16pt) | Internal card content padding — canonical, matches §10 |
| `.futureTransactionStyle(isFuture:)` | `.opacity(0.55)` when future | Planned/future transaction rows |
| `.chartAppear(delay:)` | Scale(0.94→1.0) + opacity entrance from bottom | Outermost chart container, scrollable list cards |
| `.staggeredEntrance(delay:)` | Scale(0.5→1.0) + opacity pop-in with spring | Facepile icons, overlapping avatar stacks |
| `.contentReveal(isReady:delay:)` | Opacity fade-in when ready | Staggered section reveals during initialization |
| `.borderBeam(isActive:colors:cornerRadius:lineWidth:duration:beams:)` | A comet of light running along the border itself (2.4.0): one speed and length on every side, a bloom at the head, a fading tail, a faint spill on the edge; one or two comets. `TimelineView`-driven; ticks only while `isActive == true`. Off under Reduce Motion and `.designKitMotion(false)` | Highlighting cards during transient active states (voice recognition preview, focus, processing). Match `cornerRadius` to the underlying card |

**`.fadeTruncation(fadeLength:)`** *(1.7.0)*: one line that fades out over 24 pt at its trailing edge instead of ending in "…", only when it does not fit. For names in carousels and tiles. RTL-aware.

### Buttons (`DSButton`, `.dsButton`) *(2.0.0)*

**One button.** `DSButton` (§3, Input components) is the button of the design system: a title
with an icon before, after or above it (or the icon alone), appearance × role × size, a shape,
full width, a loading state, haptics. `.dsButton(_:role:size:disabled:)` is its style, for a
`Button` whose label is built by hand (two lines, an amount). Before 2.0 the style was
`.appButton` with the shorthands `.primaryButton()` / `.secondaryButton()`, and loading,
deleting the selection and the detail-screen tiles were separate views (`LoadingButtonLabel`,
`BulkDeleteButton`, `EntityActionButton`); all are deprecated in favour of these two.

| Call | Visual | Usage |
|------|--------|-------|
| `DSButton(_:systemImage:iconPlacement:appearance:role:size:shape:fullWidth:isLoading:isDisabled:action:)` | appearance `.primary` (`.glassProminent`) / `.secondary` (`.glass`) / `.flat` (`.borderless`) × role `.normal` (accent; none on secondary) / `.destructive` (`Status.negative`) / `.neutral` (`Text.primary`) × size `.large` / `.medium` / `.small` (control sizes); icon `.leading` / `.trailing` / `.top` (a tile) / `.only`; shape `.automatic` / `.capsule` / `.roundedRectangle` | Every button |
| `.dsButton(_:role:size:disabled:)` | the same styles | A `Button` with a label of its own |
| `.buttonStyle(.bounce)` | Scale 0.96 and a slight darkening on press | Not a button look: a tappable **card or row** (Tenra's account cards, transaction rows, Finances tiles) |

| Before 2.0 | 2.0 |
|---|---|
| `Button { } label: { Text("Save").frame(maxWidth: .infinity) }.primaryButton()` | `DSButton("Save", fullWidth: true) { }` |
| `.secondaryButton()` | `.dsButton(.secondary)` or `DSButton(…, appearance: .secondary)` |
| `.appButton(a, role: r, size: s, disabled: d)` | `.dsButton(a, role: r, size: s, disabled: d)` |
| `LoadingButtonLabel("Save", isLoading: saving)` in a label + `disabled: saving` | `DSButton("Save", isLoading: saving) { }` |
| `BulkDeleteButton(count: n) { }` | `DSButton(String(format: String(localized: "bulk.deleteCount"), n), role: .destructive, shape: .capsule, fullWidth: true) { }` with the screen's own padding |
| `EntityActionButton(title: "Edit", systemImage: "pencil") { }` | `DSButton("Edit", systemImage: "pencil", iconPlacement: .top) { }` |

The role is applied by the style, never overridden by a tint: `DSButton(role: .destructive)` is
red in every appearance. (Before 1.7.0 `.primaryButton()` forced the accent tint over a
destructive role.)

**Group adjacent glass elements in `GlassEffectContainer`** (glass can't sample other glass → inconsistent rendering otherwise). Use it for rows of `.glass`/`.glassProminent` buttons or clusters of `.glassEffect()` views; set its `spacing:` to match the stack spacing. Used ungated in app code (app target = iOS 26). Precedents: `EntityDetailScaffold` action bar, `DateButtons`, `ChartZoomControls`. Leaf components that still support pre-iOS-26 (`CategoryChip`) gate glass with `#available(iOS 26)` + `.ultraThinMaterial` fallback. `SegmentedPicker` is the system control alone since 2.0.0: an interactive glass layer over it took the touch, so a quick tap did not move the selection.

---

## 3. Shared Components

### Container Components

#### `EditSheetContainer`
**Purpose:** Universal modal edit-sheet shell.

```swift
EditSheetContainer(
    title: String,
    isSaveDisabled: Bool,
    wrapInForm: Bool = true,     // false for hero-style edit views
    onSave: { },
    onCancel: { }
) {
    // Content
}
```

| Mode | `wrapInForm` | Content Structure | Used By |
|------|-------------|-------------------|---------|
| Hero-form | `false` | `ScrollView` → `VStack` → `EditableHeroSection` + `FormSection` | Account, Subscription, Category edit |
| Native form | `true` | `Form` → `Section` groups | Deposit, Loan edit, Payment/Rate forms |

#### `FormSection`
**Purpose:** Groups form rows with optional header/footer.

```swift
FormSection(header: "Settings", footer: nil, style: .card) {
    UniversalRow(config: .standard) { ... }
    Divider()
    MenuPickerRow(...)
}
```

| Style | Background | Use For |
|-------|-----------|---------|
| `.card` | `.formCardStyle()` (Material; **not** Liquid Glass) | Default; hero-form sections. Material is intentional — iOS 26 `glassEffect` would become the morph-source for any `Picker(.menu)` / `MenuPickerRow` inside, collapsing single-row sections into the popover at tap |
| `.list` | None | Inside `List` |
| `.plain` | None | Raw passthrough |

#### `EditableHero` *(1.10.0)*
The top of an edit sheet: a glass hero icon (entrance spring) that opens `IconPicker`, the name typed in place (`AnimatedTitleInput`), and with `.amountAndCurrency` an amount (`AmountInput`, 48 pt) and a currency chip that pushes `CurrencyList` (so put the hero in a `NavigationStack`). `iconTint` draws a symbol in that colour on glass (a category); `.symbolsOnly` hides the logos tab. Tenra: `EditableHeroSection` (its `HeroConfig` presets, the category hex colour) is an adapter.

```swift
EditableHero(icon: $icon, title: $name, titlePlaceholder: "Account name",
             amount: $balance, currency: $currency, options: .amountAndCurrency)
```

#### `HeroSection`
**Purpose:** Read-only icon + title (+ optional amount / subtitle / progress) hero for entity-**detail** screens and simple icon+title contexts (`InsightDetailView`, `InsightDeepDiveView`, `TransactionAddModal`). For edit flows with bindings use `EditableHeroSection` instead.

- ⚠️ **`icon: nil` renders a placeholder container** (intentional). To omit the icon block entirely (e.g. the icon lives elsewhere, like a `OrbChart` centre), pass **`showsIcon: false`** — not `icon: nil`.
- **`primaryAmount` / `primaryCurrency`** — built-in amount slot (h3). Prefer it over a sibling `FormattedAmountText`. **`primaryAmountColor`** overrides its colour (default `AppColors.textSecondary`).

---

### Row Components

#### `UniversalRow`
**The atomic building block for ALL form rows.** Every row inside `FormSection(.card)` must use it.

```swift
// Preferred — title is auto-styled (AppTypography.body + textPrimary).
// Use this form whenever the leading content is a plain string label.
UniversalRow(
    leadingIcon: .sfSymbol("star", color: .blue, size: .lg),
    title: "Label"
) {
    Text("Value").font(AppTypography.bodySmall)
}

// Full form — only when the leading content is NOT a plain string
// (e.g. a two-line VStack, a custom HStack, etc.).
UniversalRow(
    config: .standard,
    leadingIcon: .sfSymbol("star", color: .blue, size: .lg)
) {
    VStack(alignment: .leading) {
        Text("Loan name").font(AppTypography.body)
        Text("Bank").font(AppTypography.caption).foregroundStyle(.secondary)
    }
} trailing: {
    Text("Value").font(AppTypography.bodySmall)
}
```

**Rule:** do NOT manually apply `.font(AppTypography.body).foregroundStyle(AppColors.textPrimary)` to the title `Text` — use the `title:` initializer instead. Keeps form styling consistent.

**Configurations:**

| Preset | V-Padding | H-Padding | Context |
|--------|-----------|-----------|---------|
| `.standard` | 12 | 16 | Form rows in `FormSection` |
| `.settings` | 4 | 0 | Settings list rows |
| `.selectable` | 12 | 16 | Checkmark selection lists |
| `.sheetList` | 12 | 16 | Modal selection sheets |
| `.info` | 8 | 0 | Read-only label+value (container owns H-padding) |

**IconConfig factories:**

```swift
.sfSymbol("star", color: .blue, size: .lg)   // SF Symbol with color
.brandService("netflix", size: .xl)          // Brand service icon
.custom(source: iconSource, style: style)    // Custom IconSource + IconStyle
.auto(source: iconSource, size: .xl)         // Picks style by source (sfSymbol→categoryIcon, brandService→serviceLogo)
```

**Interaction modifiers:**

```swift
row.navigationRow { DetailView() }           // NavigationLink wrapper
row.actionRow(role: .destructive) { delete() } // Button wrapper
row.selectableRow(isSelected: true) { select() } // Tap gesture wrapper
```

#### Row token contract

Every row in `Views/Components/Rows/` follows these token rules. New rows MUST conform; deviations are bugs unless explicitly justified inline.

| Slot | Token | Notes |
|------|-------|-------|
| **Leading icon — content rows** | `AppIconSize.Tile.sm` (44); a limit row keeps the ring's `Tile.lg` (52) slot with or without a limit | AmountRow, LimitProgressCard |
| **Leading icon — form rows** | `AppIconSize.lg` (24) | InfoRow, MenuPickerRow, DatePickerRow |
| **Leading icon — settings rows** | `AppIconSize.md` (20) | ActionSettingsRow, NavigationSettingsRow |
| **HStack spacing (icon ↔ content)** | `AppSpacing.md` (12) | All rows |
| **Inner VStack (title ↔ subtitle)** | `AppSpacing.xs` (4) | Never `xxs` |
| **Title — management lists** | `AppTypography.h4` (20 semibold) | AmountRow `.list` (larger touch lists) |
| **Title — detail / breakdown rows** | `AppTypography.body` (18) or `bodyEmphasis` (18 semibold) | Insights detail rows. Use the `bodyEmphasis` **token** — never `body` + `.fontWeight(.semibold)` |
| **Subtitle / secondary line** | `AppTypography.bodySmall` (16) / `AppColors.textSecondary` | One token for all secondary subtitles |
| **Trailing amount** | `FormattedAmountText` (default body/semibold) | Never hand-format money |
| **Horizontal inset** | per-row `.screenPadding()` | Rows declare `hPad 0` (UniversalRow `.info`) and own their inset at the call site, so the full width — incl. padding — is tappable inside `NavigationLink`. Lists do NOT wrap the whole `VStack` (would double-pad self-padding `SectionHeader(.large)`) |
| **Navigation chevron (outside `List`)** | `DisclosureChevron` | `chevron.forward` (RTL-aware) + tertiary. Never hand-roll `chevron.right` |

**Shared row sub-components:** `AmountPercentage` (amount + %), `SpentBudgetText` (spent / budget), `DisclosureChevron`, `NetAmountRow`, `LimitProgressCard`. Reuse before building a new row.

#### `InfoRow`
Read-only label + value. Wrapper for `UniversalRow(config: .info)`.

```swift
InfoRow(icon: "calendar", label: "Next Payment", value: "March 15, 2026")
```

Use in: detail views for metadata display. NOT for editable fields.

#### `CheckmarkRow` *(1.10.0)*
A row of a choice list (a filter or picker sheet): `UniversalRow(.settings)` with an optional icon (`IconConfig`), the title in h4 medium, an optional trailing value (secondary h4, e.g. a balance), and the accent checkmark on the picked row. A tap plays the selection haptic and runs the action; VoiceOver hears a button, "Selected" on the picked one (`.selectableRow`). `CheckmarkRow("All accounts", isSelected: selection == nil) { selection = nil }`. Tenra: the rows of its account, category and time filters. Skeleton: `UniversalRowSkeleton.checkmark(iconStyle:)`.

#### `MenuPickerRow`
In-form single-select picker with dropdown menu.

```swift
MenuPickerRow(
    icon: "arrow.triangle.2.circlepath",
    title: "Frequency",
    selection: $frequency,
    options: [("Monthly", .monthly), ("Weekly", .weekly)]
)
```

Use in: form sections for frequency, period, reminder, etc.

#### `NetAmountRow` *(1.1.0)*
A label with a net amount (destructive when negative) and "+inflow −outflow" under it, or one amount (`singleValue`, `singleColor`) with no second line. Vertical padding of the `.info` preset (8; `AppSpacing.md` before 1.4.0); separate rows with `Divider()`. Tenra: `PeriodBreakdownRow` (period lists of the insights) is an adapter.

#### `ScheduleRow` *(1.1.0)*
A schedule entry: a checked circle when `isDone` (the row is dimmed with `futureTransactionStyle` when not), title + date subtitle, the amount and an optional detail line under it (`detailColor`, `AppColors.expense` by default). Vertical padding of the `.info` preset (8; none before 1.4.0). Tenra: `AmortizationScheduleRow` (payment number, date format, interest) is an adapter.

#### `AmountRow` *(2.1.0)*
A row about money: an icon, a name, and an amount, a share or a limit. It merges four rows that
were built the same way; their names are deprecated wrappers drawing the same pixels.

| Style | Look | Before 2.1 |
|---|---|---|
| `.list` | A `List` row, no padding (the list's insets place it). The name in `h4`, the value under it; the icon is the zoom-transition source with `transitionSourceID` / `transitionNamespace` | `BalanceRow` (`.amount`), `ProgressRingRow` (`.limit`) |
| `.info` | `UniversalRow(.info)` padding, the name in `body`, a `bodySmall` subtitle, the value on the trailing edge (`body` semibold over a caption); at accessibility sizes the value goes under the name | `BreakdownRow` (`.share`), `InsightEntityRow` (`.amount` with a caption) |

```swift
// An account                                   (BalanceRow)
AmountRow(account.name, leading: .icon(account.iconSource),
          value: .amount(balance, color: AppColors.Text.secondary), currency: code, style: .list,
          detail: .init("Posting: 30 Oct  ·  ", amount: 12_400), accessory: .systemImage("lock.square.stack.fill"))
// A category and its budget                     (ProgressRingRow)
AmountRow(category.name, leading: .tinted(category.icon, category.color),
          value: .limit(progress, placeholder: "No budget set"), currency: code, style: .list)
// A part of a breakdown                         (BreakdownRow)
AmountRow("Food", subtitle: "Groceries, Cafés", subtitleLineLimit: 1,
          leading: .tinted(.sfSymbol("fork.knife"), color), value: .share(85_000, percentage: 42),
          currency: code, accessory: .chevron)
// An insight's item, a subtitle of its own      (InsightEntityRow)
AmountRow(account.name, leading: .icon(account.iconSource), value: .amount(balance, color: AppColors.Text.secondary),
          currency: code) { Text(lastActivity, style: .relative) }
```

- `leading`: `.icon(source)` (`Icon`'s own style for the source, 44 pt; `nil` is the placeholder),
  `.tinted(source, color)` (the symbol on a pale disc of its colour), `.none`.
- `value`: `.amount(amount, color:, caption:)`, `.share(amount, percentage:)` ("42.0%"),
  `.limit(progress, placeholder:)`: in the list style "spent / limit (74%)" (`SpentBudgetText`,
  semibold, destructive over the limit; three lines at accessibility sizes) and a 3 pt
  `ProgressRing` around the icon, or the placeholder without a limit.
- **A limit row keeps the ring's room** (`Tile.lg`, 52 pt) around its icon whether a limit is set or
  not (2.1.0): a list of categories with and without a budget lines up. Before, a row without a
  ring had its icon and name 8 pt to the left and was 8 pt shorter.
- `detail`: a caption line under the value (text, then an amount in `AppColors.planned`); at
  accessibility sizes the amount goes under its text, which drops a trailing "·".
- `accessory`: `.chevron` (in a `NavigationLink`), `.systemImage(name)` (a secondary mark, a lock).
- The tap (`Button` + `.plain`, or a `NavigationLink`) and `.swipeActions` stay at the call site.
- Skeleton: `AmountRowSkeleton(style:showsRing:showsDetail:)`.
- Tenra: `AccountRow`, `CategoryRow` (the over-budget haptic), `CategoryBreakdownRow` and the
  insight lists are adapters. `AmountPercentage` (the amount over its share) stays public.

#### `DatePickerRow`
Inline `DatePicker` inside `UniversalRow`.

```swift
DatePickerRow(icon: "calendar", title: "Start Date", selection: $startDate)
```

#### `FormTextField`
**The single text-field component for the whole app.** Four styles — pick by context:

| Style | Use it for | Chrome |
|---|---|---|
| `.standard` | Stand-alone field with a label above (subscription name, transaction description). | Full-width, `AppRadius.lg`, padding `lg`, tinted bg, accent border on focus. |
| `.multiline(min:max:)` | Stand-alone multi-line (notes, descriptions). | Same chrome as `.standard`. |
| `.inline` | Editable trailing inside a `UniversalRow` — bank name, rate, amount. | **No chrome.** Right-aligned text only. Keeps row height stable. |
| `.inlineMultiline(min:max:)` | Multi-line trailing inside a `UniversalRow` — notes column. | **No chrome.** Right-aligned text, `lineLimit(min...max)` bounds the vertical growth. |

**Inline rationale:** the trailing slot of a `UniversalRow` already pairs the field with a row-level title and an icon, so a tinted chip on top of that would double the visual weight and stretch row height on focus. The inline styles render the TextField with native chrome only — alignment + keyboard + focus — so the row stays compact. `errorMessage`/`helpText` are suppressed in inline mode; surface validation at form level (`InlineStatusText`).

```swift
// Standalone — has its own label above. Tinted chrome.
FormTextField(text: $description, placeholder: "Optional", style: .multiline(min: 2, max: 4))

// Inside a UniversalRow — bare right-aligned field
UniversalRow(leadingIcon: .sfSymbol("building.columns"), title: "Bank") {
    FormTextField(text: $bankName, placeholder: "Bank name", style: .inline)
}

// Decimal input — keyboard variant
UniversalRow(leadingIcon: .sfSymbol("percent"), title: "Rate (year)") {
    FormTextField(text: $rate, placeholder: "0.0", style: .inline, keyboardType: .decimalPad)
}

// Auto-focus on appear (replaces ad-hoc @FocusState … .task patterns)
FormTextField(text: $rate, placeholder: "0.0", style: .inline,
              keyboardType: .decimalPad, autofocus: true)

// Multi-line trailing for notes — bounded so focus doesn't jump the row to 4 lines
UniversalRow(leadingIcon: .sfSymbol("note.text"), title: "Note") {
    FormTextField(text: $noteText, placeholder: "Optional",
                  style: .inlineMultiline(min: 1, max: 4))
}
```

**Do NOT:**
- Drop a bare `TextField` into a `UniversalRow` trailing — use `FormTextField(style: .inline)` (the old `inlineFieldStyle` / `inlineNoteStyle` modifiers were removed in 1.0).
- Wrap the inline field in an `HStack` with a suffix `Text("%")` / `Text("KZT")` — bake the unit into the row's title ("Rate (year)", "Term (month)", "Amount, KZT"). Keeps the row stable when typing.
- Roll a second TextField wrapper. There's exactly one component — `FormTextField`.

Use in: subscription/deposit/loan form sections. NOT for transaction dates (use `DateButtons`).

#### `BudgetSettingsSection` *(app-side, Tenra)*
Pre-built budget config card: amount + period + reset day.

```swift
BudgetSettingsSection(
    budgetAmount: $budgetAmount,
    selectedPeriod: $period,
    resetDay: $resetDay
)
```

Use in: `CategoryEditView` only.

---

### Card Components

All display cards share one contract: inner padding `AppSpacing.lg` (16), `.cardStyle()` (default radius `AppRadius.xl` = 20), section title `AppTypography.h3` / `AppColors.textPrimary`, entity-card title `AppTypography.h4`. Money always via `FormattedAmountText`. Conform new cards to this; don't hand-roll the glass shell.

#### `FinanceCard`
Shell for home-screen finance-product entry cards (accounts, deposits, loans, subscriptions, categories, subcategories). Owns the `HStack(title + hero/subtitle | icons)` layout, compact empty-state swap, padding and `.cardStyle()`. Each card supplies title, `isEmpty`, empty copy, `subtitle` (count line), a `hero` value view and a `trailing` facepile.

```swift
FinanceCard(
    title: ..., isEmpty: accounts.isEmpty, emptyTitle: ..., subtitle: ...
) {
    RedactableAmount(amount: total, currency: base, isLoading: loading) // or FormattedAmountText / count Text
} trailing: {
    PackedCircleIcons(items: ...)
}
```

- **`RedactableAmount`** — hero amount that shows a redacted placeholder while an async (FX) total computes, then cross-fades. Use for cards whose total needs conversion (accounts, deposits, subscriptions).
- Don't reintroduce the inline `HStack(.top, md) → VStack(.leading, lg) → title → if isEmpty …` shell in a new finance card — wrap `FinanceCard`.
- **`PackedCircleIcons`**: circles sized by amount, packed without overlap. A symbol sits on a
  pale disc of its item's `tint` (the accent without one), like every icon backing (2.0.0; a grey
  disc before); a brand logo fills its circle.

#### `RecommendationBox`
Tinted "lightbulb + advice" callout (icon + text on `color.opacity(0.10)`, `AppRadius.md`). Shared by `CalculationCard` and `TargetProgressCard`. Use for any card-bottom recommendation line.

#### `EmptyCard`
Distinct from `FinanceCard`'s inline empty state: a standalone, optionally-tappable empty card (section title + compact empty message) for empty home sections that act as an "add first item" CTA.

#### `TotalsCard` *(1.1.0)*
Labelled totals side by side (`[TotalsCard.Item]`: title, amount, optional `previous`, colour, `increaseIsGood`), an optional title above, and a small "↑ 12%" change badge under each value that has a `previous`. Full amounts via `FormattedAmountText` (`minimumScaleFactor(0.5)`, never "1.2M"). Tenra: `InsightsTotalsCard` (income / expenses / net flow) is an adapter over it.

#### `LimitProgressCard` *(1.1.0)*
Progress towards a limit: circle icon + title + percentage (destructive when over), `LinearProgressBar`, `SpentBudgetText` "spent / limit" and a trailing caption ("9 days left"). `percentage` is passed in (0…100+, not clamped); `isOverLimit` defaults to `percentage > 100`. Tenra: `BudgetProgressRow` is an adapter.

#### `WeightBreakdownCard` *(1.1.0)*
How a whole splits into weighted parts: title, explanation, a quieter caption, one 14 pt stacked bar (weights add up to 100) and a legend of icon, name and weight label, with an optional footnote. Tenra: `HealthScoreWeightingCard` (the health-score parts and weights) is an adapter.

#### `CalculationCard` *(1.1.0)*
"How it's calculated": icon + title, an optional headline value (`heroLabel` / `heroValue`; `nil` hides it when the screen shows the figure above), rows `label …… value` (`.amount(_:currency:)` through `FormattedAmountText`, or pre-formatted `.text`), the `isEmphasised` result row in the card's colour, an explanation and a `RecommendationBox`. Tenra: `InsightFormulaCard` maps its formula model onto it.

#### `ComparisonCard` *(1.2.0)*
Two amounts, before (leading, secondary, semibold) and now (trailing, bold), with a `TrendBadge(.changeIndicator)` between them. A change within ±`flatThreshold` percent (2 by default) reads as flat; `increaseIsGood: false` turns a rise red and a fall green. Tenra: `PeriodComparisonCard` (`isExpenseContext`) is an adapter.

#### `CashFlowCard` *(1.2.0)*
Money in against money out: the title (h3), `AmountComparisonBar` and an optional extra line (`Totals.extra`, e.g. "Planned"). `isEmpty` shows `EmptyCard` with the same title; `totals == nil` shows a skeleton in the card's shape (`loadingLabel` for VoiceOver, key `skeleton.loading` by default). The three states cross-fade with `AppAnimation.gentleSpring`. Tenra: `TransactionsSummaryCard` (home screen) is an adapter.

#### `ScoreGaugeCard` *(1.2.0)*
A score as a hero: `HeroHalfGauge` (220 pt, 16 pt line, `zoneTicks`) with the score (h1 bold) and a grade capsule inside, both with `materialize`, and a centred subtitle below. `score == nil` leaves the gauge empty and shows "—". `decodesScore: true` *(2.7.0)* shows the score as a `ScrambleText`: it decodes itself as the card appears and when it changes. Tenra: `HealthScoreHeroCard` (grade colour, grade-band copy) is an adapter.

#### `ScoreCard` *(1.2.0)*
A score in the insight feed: title, grade and "72 / 100" on the left, a 120 pt `MiniHalfGauge` on the trailing edge (the same footprint as the feed cards' mini charts). `decodesScore: true` *(2.7.0)* decodes the score as `ScoreGaugeCard` does; leave it off in a lazy feed, where scrolling back would replay it. Tenra: `HealthScoreCardView` is an adapter.

#### `TargetProgressCard` *(1.2.0)*
One metric against a target: icon, title and a grey capsule badge ("Weight 30%"), a summary line, "Current" (h2 bold) next to "Target", a `LinearProgressBar` (red below a third, amber below two thirds, green above, unless `progressColor` is set), an explanation and a `RecommendationBox`. `isMuted` dims the card to 60%. Tenra: `HealthComponentCard` (the health-score parts) is an adapter.

#### `RecurringPaymentCard` *(1.2.0)*
A recurring payment: `Icon` (44 pt), the name, the amount, the amount in `baseCurrency` when it differs (`ConvertedAmount`, so the host's `DesignKitCurrencyConverter`), a caption ("Next charge on 12 Oct") and a `StatusIndicatorBadge`. Tenra: `SubscriptionCard` (recurring series, next-charge date) is an adapter.

#### `PayoffProgressCard` *(1.2.0)*
Something being paid off: icon, name (h4) and subtitle with an `accessory` view on the right (a type badge), "left ……… total" over an income-tinted `ProgressView`, and a footer: `.inProgress(nextDate:remainingCaption:)` (calendar mark + date, "18 left") or `.done(caption:)` (check mark + "Closed 15 Jun 2026"). Tenra: `LoanCard` is an adapter; its `LoanTypeBadge` stays in Tenra and goes in the accessory.

#### `BalanceCard` *(1.5.0)*
A named balance sized for a carousel: `Icon` (44 pt), the name (h4) and the amount (bodySmall semibold), `AppSpacing.sm` apart, padded `lg` on `cardStyle`. `isLive: true` *(2.7.0)* shows the amount as a `LiveAmountText`: it rolls up from zero when the card first appears and flashes green or red when the balance changes. Navigation, `glassEffectID` and `matchedTransitionSource` go on it at the call site. Tenra: `AccountCard` (accounts carousel) is an adapter.

#### `MetricCard` *(1.5.0)*
One metric in a feed: a one-line title (secondary), a statement of up to three lines (bodyEmphasis), the value (`.amount` through `FormattedAmountText` or pre-formatted `.text`, h2 bold) with an optional unit and a `TrendBadge(.pill)` that drops under the value when both do not fit (`ViewThatFits`). An optional chart: `.trailing` overlays it at 120 × 120 pt on the trailing edge and the text keeps 128 pt clear; `.bottom` puts it full width under the text. Without a chart the text takes the full width. `Value`, `Trend` and `ChartPlacement` are typealiases of the top-level `MetricCardValue`, `MetricCardTrend` and `MetricCardChartPlacement`, so one value can feed cards with different charts. `ScoreCard` shares the mini-chart footprint. Tenra: `InsightsCardView` (the insight model and which mini chart each insight gets) is an adapter.

---

### Icon Components

#### `Icon`
**The single rendering engine for all entity icons.**

```swift
// Auto-style (convenience)
Icon(source: .sfSymbol("star.fill"), size: AppIconSize.xl)

// Explicit style
Icon(source: .bankLogo(.kaspi), style: .bankLogo(size: AppIconSize.xl))
```

**When to use `Icon`:** Entity/category icons with styled backgrounds — accounts, categories, subscriptions, brand logos.

**When to use `Image(systemName:)` directly:** Semantic UI indicators — chevron, checkmark, xmark, toolbar actions, inline arrows.

**Accessibility:** `Icon.body` has `accessibilityHidden(true)` — it is always decorative within its parent row/card. The parent element owns the accessibility label. Do not override this unless `Icon` is the sole content of an interactive element with no other text.

**Icon picker catalog** *(app-side, Tenra)*: `IconPickerView`'s Icons tab shows `IconCatalog` (`Tenra/Utils/IconCatalog.swift`):
~550 SF Symbols in 18 groups plus a "frequently used" row, with system `.searchable` search. The data file
`IconCatalog+Data.swift` is GENERATED by `scripts/generate_icon_catalog.py` from the SF Symbols metadata in
macOS (`CoreGlyphs.bundle`): only symbols available on the deployment target (iOS 26.0) are emitted, `.fill`
variants are preferred, and every name is checked. To add icons or search words, edit the script and run
`python3 scripts/generate_icon_catalog.py`; never edit the data file by hand. Search matches the query against
every language at once: 116 concepts with terms in all 11 app languages (including currency names), the
localized group titles, and Apple's English keywords. New group titles need a key in all 11 locales.
Pinned by `IconCatalogTests` (every symbol renders, concepts point into the catalog, multilingual queries).

**IconStyle presets:**

| Preset | Shape | Context |
|--------|-------|---------|
| `.categoryIcon(size:)` | Circle, accent tint | Category rows, chips |
| `.categoryCoin(size:)` | Circle, surface bg | Large category coins |
| `.bankLogo(size:)` | RoundedSquare, md radius | Account rows |
| `.bankLogoLarge(size:)` | RoundedSquare, lg radius | Account cards |
| `.serviceLogo(size:)` | RoundedSquare, md radius | Subscription cards |
| `.serviceLogoLarge(size:)` | RoundedSquare, lg radius | Subscription detail |
| `.placeholder(size:)` | Circle, secondary tint | Nil source fallback |
| `.glassHero(size:)` | Circle + glass | Detail view hero |
| `.glassService(size:)` | RoundedSquare + glass | Service hero |
| `.inline(tint:)` | Small circle | Text fields, chips |
| `.toolbar(tint:)` | Medium circle | Toolbar buttons |
| `.emptyState()` | XL circle | Empty state illustration |

---

### Carousel & Filter Components

#### `UniversalCarousel`
**The only horizontal scroll container. Never create raw `ScrollView(.horizontal) { HStack {} }`.**

```swift
UniversalCarousel(config: .filter) {
    ForEach(items) { item in
        UniversalFilterButton(title: item.name, isSelected: item.isSelected) { ... }
    }
}
```

| Preset | Spacing | H-Padding | Use For |
|--------|---------|-----------|---------|
| `.standard` | 12 | 16 | Account carousel, general horizontal lists |
| `.compact` | 8 | 8 | Color picker, tight grids |
| `.filter` | 12 | 16 | Filter chip rows |
| `.cards` | 12 | 0 | Edge-to-edge cards (apply `.screenPadding()` externally) |
| `.csvPreview` | 8 | 12 | CSV column preview (shows indicators) |


**`.carouselItemTransition(isEnabled:)`** *(1.10.0)*: a card in a carousel dims to 75% and shrinks to 95% as it scrolls off (`scrollTransition(.interactive)`). Pass `false` for a carousel too short to scroll. Tenra: the accounts carousel (`isEnabled: accounts.count >= 3`).
#### `UniversalFilterButton`
Filter chip in two modes.

```swift
// Button mode
UniversalFilterButton(title: "This Month", isSelected: true) { selectPeriod() }

// Menu mode
UniversalFilterButton(title: "Account", isSelected: hasFilter) {
    Button("All Accounts") { clearFilter() }
    ForEach(accounts) { acc in
        Button(acc.name) { selectAccount(acc) }
    }
}
```

---

### Input Components

#### `FormTextField`
Enhanced text field with error/help states.

```swift
FormTextField(
    text: $name,
    placeholder: "Enter name",
    style: .standard,         // or .multiline(min: 2, max: 6), .compact
    errorMessage: nameError,
    helpText: "Required field"
)
```

Use for: text inputs inside `FormSection`. NOT for amounts (use `AnimatedAmountInput`) or hero titles (use `AnimatedTitleInput`).

#### `AnimatedAmountInput` → `AmountInput`
Hero-style large formatted amount with `.numericText()` transition.

```swift
AnimatedAmountInput(amount: $amountString, baseFontSize: 48, color: .primary)
```

Use in: `EditableHeroSection` balance fields. NOT for compact form rows.

#### `AnimatedTitleInput`
Hero-style name input with `.interpolate` character transition.

```swift
AnimatedTitleInput(text: $name, placeholder: "Account Name", font: AppTypography.h1)
```

Use in: `EditableHeroSection` title fields only.

#### `DateButtons`
Yesterday / Today / Calendar picker for transaction forms.

```swift
// As safe-area bottom bar:
.dateButtonsSafeArea(selectedDate: $date, onSave: { saveDate($0) })
```

Use for: transaction entry/edit forms only. For other date fields use `DatePickerRow`.

#### `CurrencyPickerMenu` *(1.10.0)*
The currency of an amount as a filter chip, "₸ ⌄", that opens a menu of the given currencies (sorted by name, the chosen one checked) and, with `onCustomize`, a "Customize…" item (`currency.customizeAction`) under a divider. Which currencies to offer stays the caller's. Tenra: `CurrencySelectorView` (account currencies + quick picks, the customize sheet) is an adapter.

```swift
CurrencyPickerMenu(selection: $currency, currencies: ["KZT", "USD", "EUR"]) { showsQuickPicks = true }
```

#### `CurrencyAmountInput` *(1.10.0)*
The amount at the top of an add sheet: the 56 pt `AmountInput` (or `CalculatorAmountDisplay` with a `calculatorModel`), the "≈ 1 234 ₸" line when the amount is in another currency, the `CurrencyPickerMenu`, and the error in red. Tenra: `AmountInputView` is an adapter.

```swift
CurrencyAmountInput(amount: $amountText, currency: $currency, baseCurrency: "KZT",
                    equivalentCurrency: account.currency,   // optional (1.14.0)
                    currencies: ["KZT", "USD", "EUR"], errorMessage: error)
```

The "≈" line (1.14.0):
- **Its currency.** `equivalentCurrency`, such as the currency of the account the amount goes to; `baseCurrency` when the amount is already in it; no line when the amount is in both. Without `equivalentCurrency` (the default) the line is in `baseCurrency`, as before. With the account's currency this is the rule of Tenra's saved transaction rows: USD typed for a EUR card shows "≈ €" (before, "≈ ₸" while typing and "≈ €" once saved), EUR typed for it "≈ ₸".
- **Converting.** Through `DesignKitCurrencyConverter` (`convertSync`, then `convert`). Typing waits for a 0.3 s pause and keeps the previous value until the new one comes, so the number changes in place. A new line or new currencies convert at once: with `convertSync` the value shows in the same frame, otherwise a spinner until a rate comes; a value for the previous currencies is never shown. One conversion runs at a time and the latest input wins: a slower, older conversion that comes back later is dropped (before, it could overwrite the newer value).
- **No rate.** The line disappears, rather than keep the previous, now wrong number (before, it kept it, and spun forever without a converter).

The logic is `CurrencyEquivalent.swift` (internal), unit-tested in `CurrencyEquivalentTests`.

#### `CurrencyList` *(1.10.0)*
Every `CurrencyInfo` currency to pick from: "Popular", then all, in cards (a `ScrollView`, so the screen's background shows through), each row code, name and symbol, the chosen one checked, with a search in the navigation bar's drawer. `CurrencyList(selection: code) { code in … }`; the screen around it is the caller's. Tenra: `CurrencyListContent` (Settings, onboarding) is an adapter.

#### `IconPicker` / `IconCatalog` *(1.10.0)*
An icon picker sheet with its own navigation bar: SF Symbols from `IconCatalog` (DesignSupport; about 550 symbols available on iOS 26 in 18 groups, "Frequently Used" first, a search across 11 languages through concepts, group titles and Apple's keywords; data generated by `scripts/generate_icon_catalog.py`), and, when the app sets `DesignKitLogoCatalog`, a logos tab (sections, search, the typed name tried as a domain). Picking closes it. `IconPicker(selection: $icon, allowsLogos: false)` for symbols only. Tenra: `IconPickerView` is an adapter; its brand registry feeds the hook.

---

#### `ChipPicker` *(0.4.0)*
One or none from a horizontally scrolling row of chips; tapping the selected chip clears it.

```swift
ChipPicker("Weather", options: Weather.allCases, selection: $draft.weather) { $0.title }
```

Chips use `filterChipStyle(isSelected:)`. A fixed 2–4 way switch → `SegmentedPicker`; a
filter that opens a menu → `UniversalFilterButton`.

`allTitle:` *(2.8.0)* puts an "All" chip in front, selected while nothing is picked; tapping it
clears the selection (one or several). Dalada: the place-type filter. For chips that scroll
under the screen edges, give the picker `.contentMargins(.horizontal, AppSpacing.lg, for: .scrollContent)`.

Several at once (0.6.0): pass a `Binding<Set<Option>>`; optional `systemImage:` per chip.

```swift
ChipPicker(options: PlaceType.allCases, selection: $types, systemImage: { $0.systemImage }) { $0.title }
```

#### `GlassActionMenu` *(2.3.0)*
A floating Liquid Glass button that flows open into a column (or row) of glass actions and
melts them back in; the morph is the system's (`glassEffectID` in one `GlassEffectContainer`).
An action closes the menu after it runs. VoiceOver: each action's title; the button reads
"Actions" / "Close" (keys `menu.open`, `menu.close`).

```swift
GlassActionMenu(items: [
    .init("Scan a receipt", systemImage: "doc.viewfinder") { scan() },
    .init("Expense", systemImage: "minus") { addExpense() },
])
```

#### `DSButton` *(2.0.0)*
The button of the design system (§2, Buttons): a title with an icon, appearance × role × size,
a shape, full width or the label's own, a loading state that keeps the width and blocks taps.
A press plays a light haptic (a warning one for `.destructive`).

```swift
DSButton("Save", fullWidth: true, isLoading: isSaving) { Task { await save() } }
DSButton("Delete", systemImage: "trash", role: .destructive) { delete() }
DSButton("Next", systemImage: "arrow.right", iconPlacement: .trailing, appearance: .secondary) { next() }
DSButton("Close", systemImage: "xmark", iconPlacement: .only, appearance: .secondary) { close() }

// Actions under a detail screen's hero: tiles that share the row.
HStack(spacing: AppSpacing.md) {
    DSButton("Edit", systemImage: "pencil", iconPlacement: .top) { edit() }
    DSButton("Delete", systemImage: "trash", iconPlacement: .top, role: .destructive) { delete() }
}
```

- `iconPlacement: .top` draws a tile: the symbol (24 pt) over a two-line `bodySmall` medium
  title, padded `md` / `sm`, a rounded rectangle (`AppRadius.lg`) that fills the width it is
  given (EntityActionButton before 2.0, the same pixels).
- `.only` shows the symbol alone; the title is its VoiceOver label.
- The label takes the font around it, like a SwiftUI `Button`.
- Replaces `LoadingButtonLabel`, `BulkDeleteButton` and `EntityActionButton` (deprecated).

#### `ToggleSettingsRow` *(0.6.0)*
The settings row with a switch, next to `NavigationSettingsRow` and `ActionSettingsRow`.

```swift
ToggleSettingsRow(icon: "bell", title: "Reminders", isOn: $remindersOn)
ToggleSettingsRow(icon: "location", title: "Share location", hint: "Friends see your trip", isOn: $shares)
```

VoiceOver focuses the switch (title as label, `hint` as hint).

#### `SliderRow` *(1.15.0)*
A setting set with a slider: the title (body, with an optional symbol), the value on the trailing
edge (bodySmall, secondary, tabular digits), the slider in the accent, an optional hint (caption).
The app formats the value. Pads only vertically, like a row; put it in a form card.

```swift
SliderRow("Colour intensity", systemImage: "circle.lefthalf.filled",
          value: $opacity, in: 0.05...1, valueText: "\(Int((opacity * 100).rounded()))%")
```

VoiceOver reads the slider with the title as its label and `valueText` as its value. Skeleton:
`SliderRowSkeleton(showsHint:)`. Tenra's background-intensity row is its adapter.

#### `SelectionIndicator(isSelected:tint:)`
Check circle for multi-select and checklist rows; the row carries the label and the
`.isSelected` trait. `tint` (0.4.0, default accent) colours the filled check: `AppColors.success`
for a done checklist item, `textTertiary` for one that is already owned and disabled.

#### `SelectableBalanceCard` *(1.5.0)*
One option of a "pick a balance" list: a full-width card with `Icon` (44 pt), the name (body, secondary) and the amount (body semibold), outlined in `AppColors.accent` (2 pt, `gentleSpring`) when `isSelected`, `.bounce` on press, `.isSelected` trait. Tenra: `AccountRadioButton` (balance from its store) is an adapter.

#### `ProgressRingTile` *(1.5.0)*
A picker-grid tile: the name (bodyEmphasis, one line) over a 64 pt Liquid Glass circle with the symbol (h2) in `color`, the glass tinted with `color` at 30% when `isSelected`, and an optional 4 pt `ProgressRing` (72 pt) around it. As tall with a ring as without, so grid rows line up. VoiceOver label and hint at the call site. Tenra: `CategoryChip` (category style lookup) is an adapter.

#### `ProgressRingTileGrid` *(1.10.0)*
`ProgressRingTile`s in a `LazyVGrid` (rows 32 pt apart, columns 16), each with its amount under it (bodySmall, primary) and, when there is one, its limit under that (secondary). Columns: as many 108–180 pt columns as fit (four on an iPhone), or exactly `columns`. Items are `ProgressRingTileGridItem(id:title:systemImage:color:progress:amount:limit:accessibilityLabel:accessibilityHint:)`; the id is the tile's zoom-transition source in `transitionNamespace`; `onTap` gets the item. The empty state is the caller's (`EmptyCard`). Tenra: `CategoryGridView` (categories, budgets, the empty card) is an adapter. Skeleton: `ProgressRingTileGridSkeleton(count:columns:)`.

### Feedback & Status Components

#### `StatusBanner` *(1.7.0)*
A notice that stays in the layout, built like `RecommendationBox` (icon, wrapping text, a tinted `AppRadius.md` box) and coloured by status: `status:` `.info` / `.positive` / `.negative` / `.warning` / `.neutral` (icon and `AppColors.Status.*Pale` box), `style:` `.standard` (bodySmall, on a screen) or `.compact` (caption, inside a card). With an `action` it is a `.bounce` button with a `DisclosureChevron`. VoiceOver reads it as one element. For a message that comes and goes use `MessageBanner`; for one line under a field, `InlineStatusText`.

```swift
StatusBanner("Card expires on 30 Nov", status: .warning)
StatusBanner("Statement is ready", status: .info) { showStatement() }
```

#### `Tooltip` *(2.0.0)*
A short value or hint in an opaque bubble (`Background.elevation3`, a soft shadow,
`AppRadius.md`) with a tail pointing at its target: the amount over a tapped bar
(`HeroBarPair`), a one-line explanation over a control.

```swift
bar
    .overlay(alignment: .top) {
        if isSelected {
            Tooltip(amountText).tooltipAnchor(.top)          // the tail touches the bar's top
        }
    }
    .zIndex(isSelected ? 1 : 0)                              // over the neighbouring bars

Tooltip("Last month", arrowEdge: .top).tooltipAnchor(.bottom) // below its target
Tooltip { Text(amount).font(AppTypography.numbers(AppTypography.bodySmall.bold())).foregroundStyle(tint) }
```

Opaque so it reads over whatever it covers; in an overlay so it never moves the layout. No
skeleton: it shows a value already on screen, on a tap.

#### `MessageBanner`
Transient animated feedback banner.

```swift
MessageBanner.success("Saved successfully")
MessageBanner.error("Failed to load")
MessageBanner.warning("Low balance")
MessageBanner.info("Sync completed")
```

Show conditionally via `.overlay(alignment: .top)` + `.animation(AppAnimation.gentleSpring, value: message)`. For auto-dismiss after N seconds, set the state to `nil` inside a `Task` after `Task.sleep`:

```swift
@State private var errorMessage: String? = nil

// In catch block:
errorMessage = "Payment failed."
Task {
    try? await Task.sleep(for: .seconds(4))
    errorMessage = nil
}

// In body:
.overlay(alignment: .top) {
    if let msg = errorMessage {
        MessageBanner.error(msg)
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}
.animation(AppAnimation.gentleSpring, value: errorMessage)
```

#### `InlineStatusText`
Persistent inline validation/hint text.

```swift
InlineStatusText(message: "Amount must be positive", type: .error)
```

Use for: persistent form validation. NOT for transient post-action feedback (use `MessageBanner`).

#### `MessageBanner(message:type:actionTitle:action:)` *(0.6.0)*
Banner with a trailing action — "Undo" after a delete, "Retry" after a failure (snackbar). The
action does not dismiss the banner; clear your message state in it.

```swift
MessageBanner(message: "Trip deleted", type: .info, actionTitle: "Undo") { restore(); message = nil }
```

#### Component skeletons *(1.10.0)*
Every component that shows data has a skeleton, named after it (`BalanceCard` → `BalanceCardSkeleton`) and declared at the end of the component's file, so a layout change and its skeleton are edited together. Show it while the data loads, in the component's place:

```swift
if let accounts {
    ForEach(accounts) { AmountRow(…, style: .list) }
} else {
    ForEach(0..<3, id: \.self) { _ in AmountRowSkeleton(style: .list) }
}
```

To end loading softly (2.3.0), `SkeletonReveal` swaps the two with the content coming into focus
from a light blur (a cross-fade under Reduce Motion):

```swift
SkeletonReveal(isLoading: balance == nil) {
    BalanceCard(…)
} skeleton: {
    BalanceCardSkeleton()
}
```

**The corner rule.** A skeleton keeps its component's container and corner as they are: a card skeleton is the same glass card (`cardStyle`, the card's radius), a pale box (`RecommendationBox`, `StatusBanner`) keeps `AppRadius.md`, a chip keeps the chip's `AppRadius.xl`, a badge, pill or switch is a capsule, an icon keeps its `IconStyle` shape (`IconSkeleton(style:)`), a progress track keeps its corner (`AppRadius.xs` for `LinearProgressBar`, the round caps of rings and gauges, the segment corners of milestone gauges and bar pairs). A shape whose component has no corner of its own (a line of text, an amount, a chart's plot area, a star) takes the soft corner, `AppRadius.soft` (12 pt; a line of text gets fully round ends). `Skeleton` and `SkeletonText` use it by default since 1.10.0 (before: `AppRadius.xs`).

**Shimmer.** One band sweeps a whole skeleton (a shimmer inside another one is off). `.skeletonShimmer(false)` stops it under a view (snapshot tests do this); Reduce Motion stops it too. Each skeleton is one VoiceOver element that reads "Loading" (`skeleton.loading`).

| Component | Skeleton |
|---|---|
| `BalanceCard`, `SelectableBalanceCard`, `FinanceCard`, `CashFlowCard` (also its own loading state), `TotalsCard`, `ComparisonCard`, `InsightsStatCard`, `StatTile`, `RecurringPaymentCard`, `RecommendationBox` | `…Skeleton` (`TotalsCardSkeleton(count:showsTitle:amountFont:)`, `FinanceCardSkeleton(showsTrailing:)`, `RecommendationBoxSkeleton(lines:)`) |
| `LimitProgressCard`, `TargetProgressCard`, `PayoffProgressCard`, `ScoreCard`, `ScoreGaugeCard`, `MetricCard`, `WeightBreakdownCard`, `CalculationCard`, `ProgressRingTile`, `ProgressRingTileGrid` | `…Skeleton` (`MetricCardSkeleton(chartPlacement:)`, `WeightBreakdownCardSkeleton(segments:)`, `CalculationCardSkeleton(rows:showsHero:)`) |
| `UniversalRow` | `UniversalRowSkeleton(config:iconStyle:titleFont:showsSubtitle:trailing:)` |
| `NavigationSettingsRow`, `ToggleSettingsRow`, `ActionSettingsRow`, `MenuPickerRow`, `DatePickerRow`, `CheckmarkRow` | `UniversalRowSkeleton.navigationSettings`, `.toggleSettings`, `.actionSettings`, `.menuPicker`, `.datePicker`, `.checkmark(iconStyle:)` |
| `SliderRow` (1.15.0) | `SliderRowSkeleton(showsHint:)` |
| `AmountRow` (2.1.0) | `AmountRowSkeleton(style:showsRing:showsDetail:)` |
| `NetAmountRow`, `ScheduleRow`, `InfoRow`, `ColorPickerRow` | `…Skeleton` |
| `LineChart`, `BarChart`, `ChartSwitcher`, `HeroSparkline`, `Sparkline`, `OrbChart` | `…Skeleton` |
| `LinearProgressBar`, `ProportionBar`, `MiniProportionBar`, `AmountComparisonBar`, `HeroProportionBar`, `ProgressRing`, `MiniDonut`, `MiniHalfGauge`, `HeroHalfGauge`, `MiniMilestoneGauge`, `HeroMilestoneGauge`, `MiniBarPair`, `HeroBarPair` | `…Skeleton`, with the component's size parameters |
| `Icon` | `IconSkeleton(style:)` / `IconSkeleton(size:)` |
| `Avatar`, `AvatarGroup`, `HeroSymbol`, `PackedCircleIcons`, `Badge`, `TrendBadge`, `StatusIndicatorBadge`, `StatusBanner`, `Rating`, `ChipPicker` | `…Skeleton` |
| `FormattedAmountText`, `ConvertedAmount`, `SpentBudgetText`, `AmountPercentage` | `FormattedAmountTextSkeleton(font:width:)`; `RedactableAmount(isLoading: true)` draws one itself |
| `HeroSection`, `SectionHeader` (every style) | `HeroSectionSkeleton`, `SectionHeaderSkeleton(style:showsTrailing:)` |
| `ExpandableText`, `ActivityTimeline`, `MonthCalendar` | `…Skeleton` |
| `PersonRow`, `CommentRow`, `ThreadCard`, `ReviewCard`, `AchievementMedal`, `AchievementTile`, `AchievementProgressRow`, `ChecklistRow`, `ChecklistSummaryRow`, `StatsStrip`, `StreakCard`, `ThumbnailCard`, `ThumbnailRow` (1.12.0) | `…Skeleton` (`StatsStripSkeleton(count:)`, `AchievementTileSkeleton(medalSize:)`, `ThumbnailCardSkeleton(width:)`, `PersonRowSkeleton(showsSubtitle:style:)`) |
| `PhotoTile`, `PhotoStrip`, `PhotoGrid`, `PhotoCarousel`, `ShareCardFrame` (and `ShareCardSheet` while it loads), `LiveSessionBar`, `DownloadRow`, `ArticleBody` (2.8.0) | `…Skeleton` (`PhotoTileSkeleton(size:cornerRadius:)`, `PhotoStripSkeleton(count:size:)`, `PhotoGridSkeleton(count:columns:style:)`, `ShareCardSkeleton(format:)`, `ArticleBodySkeleton(paragraphs:)`) |

**No skeleton, on purpose:** views that show no data that loads. Inputs and controls (`AmountInput`, `CurrencyAmountInput`, `CurrencyPickerMenu`, `EditableHero`, `AnimatedTitleInput`, `FormTextField`, `MessageComposer`, `CalculatorKeypad`, `CalculatorAmountDisplay`, `AmountDigitDisplay`, `TagInput`, `RatingPicker`, `ReactionButton`, `SegmentedPicker`, `DateButtons`, `UniversalFilterButton`, `ChartZoomControls`, `AmountVisibilityToggle`, `DSButton`, which has its own loading state); containers (`FormSection`, `EditSheetContainer`, `UniversalCarousel`, `OnboardingPager`, `OnboardingPageContainer`: put the skeletons of their content inside); pickers over local data (`IconPicker`, `CurrencyList`); `PhotoViewer` (full screen over photos already shown; the app's image view shows its own loading); messages and flows that appear once something is known (`EmptyState`, `EmptyCard`, `MessageBanner`, `InlineStatusText`, `Tooltip`, `PromptSheet`, `NotificationPermissionPrompt`, `ImportProgressSheet`, `OnboardingPage`, `LoopOnboardingHero`, `StepTracker`, `OnboardingStepIndicator`, `ChartSelectionBanner`); decoration, effects and layouts (`AuroraBackground`, `GradientOrbsBackground`, `EdgeGlow`, `VoiceWave`, `AccentGlow`, `.borderBeam`, `PlusTabLabel`, `DisclosureChevron`, `SelectionIndicator`, `FlowLayout`, `InfoRowLayout`, `CirclePackingLayout`, the modifiers and button styles). A new component that shows data gets its skeleton in the same PR.

#### `SkeletonText` *(1.7.0)*
A text-line placeholder in a given style: `SkeletonText(AppTypography.h4, width: 140)`, `SkeletonText(AppTypography.bodySmall, lines: 2)` (the last of several lines is 60% wide). The line is as tall as the style's own line, so it grows with Dynamic Type; the bar is 70% of it. Shimmers like `Skeleton`. For a component, use its skeleton (above); `.skeleton(isLoading:)` redacts a real view in place, with the system's placeholder shapes.

#### `Skeleton` / `SkeletonRow` / `.skeleton(isLoading:)` *(0.6.0)*
Loading placeholders instead of a spinner: grey shapes in the layout of the content that is
coming, with a slow shimmer (static under Reduce Motion, via `AmbientMotionGate`).

```swift
if isLoading { ForEach(0..<5) { _ in SkeletonRow() } }          // list rows
Skeleton(height: 160)                                       // an image, soft corner
Skeleton.circle(40); Skeleton.capsule(height: 28, width: 80) // 1.10.0
TripRow(trip: trip ?? .placeholder).skeleton(isLoading: trip == nil) // redact a real view
```

`.skeleton` redacts text and images, ignores taps and reads "Loading" to VoiceOver (key
`skeleton.loading`). A stack of standalone shapes is hidden from VoiceOver: add
`.skeletonLoadingLabel()` (0.7.0) to it, or your own `accessibilityLabel`. Use a spinner (`ProgressView()`) only for short, layout-less waits.

#### `StepTracker` *(0.6.0)*
Where the user is in a multi-step flow: numbered circles, done steps checked, current outlined.

```swift
StepTracker(steps: ["Place", "Catch", "Photos", "Review"], current: 1)   // 0-based
```

VoiceOver: "Step 2 of 4: Catch" (key `steps.position`). Tenra's 3-symbol onboarding keeps
`OnboardingStepIndicator`.

#### Permission primers → `PromptSheet`
Our explanation before a system permission alert (HIG "Requesting permission") is a
`PromptSheet` (below) since 2.0.0: `onPrimary` is async and runs the system request while the
main button shows a spinner. `PermissionPrimerView` (0.7.0) was the same layout and is a
deprecated wrapper. Show it at the moment of first use (first check-in, first subscription),
not at launch.

```swift
.sheet(isPresented: $asksForPush) {
    PromptSheet(
        systemImage: "bell.badge",
        title: String(localized: "push.primer.title"), message: String(localized: "push.primer.body"),
        primaryTitle: String(localized: "push.primer.allow"), secondaryTitle: String(localized: "push.primer.later"),
        onPrimary: { await requestPermission() },
        onSecondary: {}
    )
}
```

`NotificationPermissionPrompt` (NotificationPermissionView before 2.0) is a `PromptSheet` with
Tenra's `notification.permission.*` texts; the app sets its detent.

#### `OnboardingPager` / `OnboardingPage` *(0.7.0)*
First-launch introduction: swipeable pages with dots, Skip at the top, the page's buttons at
the bottom. The app owns the pages enum and `selection`. Since 2.3.0 each page's `HeroSymbol`
lags behind its page as it swipes (parallax; off under Reduce Motion).

```swift
OnboardingPager(pages: Intro.allCases, selection: $page,
                canSkip: { $0 != .location }, onSkip: finish) { page in
    OnboardingPage(systemImage: page.symbol, title: page.title, message: page.text)
} actions: { page in
    DSButton("Next", fullWidth: true) { next() }
}
```

`OnboardingPage` takes an optional accessory under the text (a card, a sign-in button) and
scrolls at large Dynamic Type. A data-collection flow inside a `NavigationStack` (Tenra) keeps
`OnboardingPageContainer` + `OnboardingStepIndicator` (`symbols:` since 0.7.0).

#### `StatusIndicatorBadge`
Entity lifecycle status icon.

```swift
StatusIndicatorBadge(status: .active, font: AppTypography.h4)
```

Cases: `.active` (green checkmark), `.paused` (orange pause), `.archived` (gray archive), `.pending` (blue clock).

#### `Badge` *(0.4.0)*
Capsule with short text and an optional SF Symbol: a status, a tag or a counter.

```swift
Badge("Seasonal ban", color: AppColors.destructive)                       // .tinted: text on a 12 % tint
Badge("3", systemImage: "person.badge.plus", color: AppColors.destructive, style: .filled)
```

Use `.tinted` for statuses and tags, `.filled` only for counters that need attention. Icon-only
lifecycle status → `StatusIndicatorBadge`; a change over time → `TrendBadge`. Keep the domain
mapping (status → text + colour) in the app as a small wrapper (Dalada's `RuleStatusBadge`).

#### `TrendBadge` *(0.4.0)*
Direction arrow + signed percent ("↗ +12.4%"), from Tenra's insights.

```swift
TrendBadge(direction: .up, changePercent: 12.4)                                 // .pill
TrendBadge(direction: .up, changePercent: 8, style: .inline, color: AppColors.destructive) // up is bad
TrendBadge(direction: .down, changePercent: -3.2, style: .changeIndicator)      // icon over value
```

Default colours: up = `AppColors.income`, down = `destructive`, flat = `textSecondary`; pass
`color:` where the direction's meaning flips (expenses). Tenra's `InsightTrendBadge` is an
adapter over it (`InsightTrend` → direction + percent).

#### `EmptyState`
Empty/error state display.

```swift
EmptyState(
    icon: "tray",
    title: "No Transactions",
    description: "Add your first transaction to get started",
    actionTitle: "Add Transaction",
    action: { showAdd = true },
    style: .standard  // or .compact, .error
)
```

| Style | Context |
|-------|---------|
| `.standard` | Full-screen empty state (management views) |
| `.compact` | Inside cards (home summary) |
| `.error` | Load failures (with pulse icon + retry) |

#### `PromptSheet` *(1.5.0; 2.0.0 the one prompt and permission sheet)*
A short question or a permission request in a sheet: `HeroSymbol` (104 pt disc), the title
(`h2`) and message (`body`) centred, a full-width primary `DSButton` and a secondary one.

```swift
.sheet(isPresented: $showsSurvey) {
    PromptSheet(
        systemImage: "sparkles",
        title: "Enjoying the app?", message: "Your answer helps us decide what to improve next.",
        primaryTitle: "Love it!", secondaryTitle: "Not really",
        onPrimary: { requestReview() }, onSecondary: { openFeedbackMail() }
    )
}
```

- `onPrimary` is async: while it runs, the main button shows a spinner and both are disabled.
- `dismissesOnAnswer` (default `true`): the sheet closes after either answer; `false` leaves it to
  the app (a primer that waits for the system alert's result).
- `detent` (default `.medium`, with a drag indicator); `nil` when the app presents it its own way.
- Before 2.0: a 340 pt sheet with an `h3` title, a `bodySmall` message and a 44 pt symbol
  (`height:` init, deprecated). Tenra: `RatingSurveyView` is an adapter; Dalada's primers are
  `PromptSheet(detent: nil, dismissesOnAnswer: false)`.

---

### Display Components

#### `FormattedAmountText`
Currency amount with smart decimal hiding and numeric transition. For a hero amount that should
arrive and change visibly, `LiveAmountText` (2.3.0) wraps it: the digits roll up from zero on
first appearance and a change flashes green or red (skeleton: `LiveAmountTextSkeleton`).

```swift
FormattedAmountText(
    amount: 1234.56,
    currency: "KZT",
    prefix: "-",
    fontSize: AppTypography.h2,
    fontWeight: .semibold,
    color: AppColors.expense
)
```

Use for: ALL display-only amounts — detail view balances, row subtitles, card totals, section headers.

**Sign and unit (1.7.0).** `sign: .always` puts "+" before a positive amount and a true minus "−" (U+2212) before a negative one, for changes of money ("+5 000 ₸", "−1 200,50 ₸"); `.never` draws the absolute value; `.automatic` (default) is the 1.x behaviour. With a sign, `prefix` follows it. `currencyDisplay`: `.symbol` (default, "1 200 ₸"), `.code` ("49,90 USD", for foreign currencies or shared symbols), `.systemImage("star.fill")` (points, miles, bonuses), `.numberOnly` (a header names the currency). The compact forms ("1,2 млн") keep the chosen unit.

**Hidden amounts (1.7.0).** `.amountsHidden(_:)` (DesignSupport; environment `amountsHidden`) hides every `FormattedAmountText` below it, and so every card, row and badge built on it: "•••• ₸" (the number and sign go, the unit stays), VoiceOver reads "Hidden amount" (`amount.hidden`). Since 1.8.0 also the legend amounts of `HeroProportionBar` and the tap tooltip of `HeroBarPair`. Amount inputs and chart axes are not hidden. An amount the app writes into its own text reads the environment value and shows `Formatting.hiddenAmount(currency:)` ("•••• ₸"):

```swift
@Environment(\.amountsHidden) private var amountsHidden

Text(amountsHidden ? Formatting.hiddenAmount(currency: code) : Formatting.formatCurrencySmart(total, currency: code))
``` The app keeps the switch (a setting) and applies the modifier near the root; `AmountVisibilityToggle(isHidden:)` is the eye button for it (44 pt target, selection haptic, "Hide amounts" / "Show amounts").

```swift
@AppStorage("hidesAmounts") private var hidesAmounts = false

HStack {
    FormattedAmountText(amount: balance, currency: "KZT", fontSize: AppTypography.h1)
    AmountVisibilityToggle(isHidden: $hidesAmounts)
}
.amountsHidden(hidesAmounts)
```

#### `SectionHeader`
Section header text in five styles, and an optional action at the end of the line (1.15.0).
SectionHeaderView before 2.0; the list style was SettingsSectionHeaderView, the card style
DateSectionHeaderView.

```swift
SectionHeader("Transactions")                                      // .default: bodyEmphasis
SectionHeader("Settings", style: .compact)                         // bodySmall, secondary, uppercase, screen padding
SectionHeader("Spending", systemImage: "chart.bar", style: .large) // h3 + accent icon, screen padding
SectionHeader("Notifications", style: .list)                       // .compact's label, no padding: a List / Form header
SectionHeader("Yesterday", style: .card) {                         // .default's title on a padded glass card
    FormattedAmountText(amount: 45_000, currency: "KZT", prefix: "-",
                        fontSize: AppTypography.bodySmall, fontWeight: .semibold, color: AppColors.Text.tertiary)
}

SectionHeader("Trips", systemImage: "map") {                       // with an action
    NavigationLink("All") { TripsList() }
}
```

The icon shows in `.large` only. The action is any view (a `NavigationLink` "All", a button, a
spinner); it takes `AppTypography.bodySmall` and sits at the end of the line, inside the style's
padding. Title and action share an `HStack` with the system spacing and a `Spacer(minLength: 0)`,
the layout Dalada built by hand before. Skeleton: `SectionHeaderSkeleton(style:showsTrailing:)`.

`.card` is a transaction list's day header: the label is the app's own ("Today", "Yesterday",
the date), the day's total is the action (DateSectionHeaderView showed it only when above zero,
with a minus; the app decides that now).

#### `ProgressRing`
Circular progress arc for budget consumption.

```swift
ProgressRing(progress: 0.75, size: AppIconSize.Tile.lg, isOverBudget: false)
```

A goal ring (2.3.0): `celebratesCompletion: true` draws a checkmark in at 100 % and plays the
completion moment (a glow and the success haptic) when it gets there. Since 2.3.1 a goal ring is
green at any fill, one hue with depth like `overrideColor`, never the budget's amber and red,
also past 100 %. Off for budgets, where 100 % is not good news.

#### `LinearProgressBar(value:)` *(0.4.0)*
The budget bar's plain form for any progress (downloads, checklists, a followed route):
`value` is a fraction 0…1, no overshoot or forecast. Replaces the system `ProgressView(value:)`
so progress looks the same in every app. Both inits expose the percentage to VoiceOver.

```swift
LinearProgressBar(value: checklist.progress, color: AppColors.success, height: 6)
LinearProgressBar(value: download.fraction, animatesOnAppear: false)
```

#### `StatTile` *(0.4.0)*
One metric: caption over a large monospaced value. The caller formats the value, units included.

```swift
HStack {
    StatTile(title: "Distance", value: "12.4 km")
    StatTile(title: "Moving", value: "2 h 15 min")
}
StatTile(title: "Catches", value: "7", systemImage: "fish", valueColor: AppColors.accent)
```

Use for counts, distances, durations. A money amount compared with the previous period →
`InsightsStatCard`.

#### `Avatar` *(0.4.0)*
Round avatar: the photo when there is one, otherwise initials on a 15 % tint.

```swift
Avatar(name: profile.displayName ?? profile.username)          // AppIconSize.xxl (40)
Avatar(name: "Ayan Seitkali", size: 64)                         // h3 initials above 48 pt
Avatar(name: name, image: Image(uiImage: photo))
```

Decorative for VoiceOver: put the name in the row next to it. Several faces in a cluster →
`PackedCircleIcons`.

#### `AvatarGroup` *(0.6.0)*
Overlapping avatars with "+N" for the rest; each has a ring in the background colour and,
since 2.0.0, an opaque disc under its pale initials, so the avatar behind does not show through.

```swift
AvatarGroup(names: trip.members.map(\.displayName), accessibilityLabel: "Ayan, Dana and 4 more")
AvatarGroup(names: names, maxVisible: 3, size: 28)
```

Hidden from VoiceOver unless you pass `accessibilityLabel`.

#### `ExpandableText` *(0.6.0)*
Long text clamped to `lineLimit` lines; a More / Less button appears only when it overflows.

```swift
ExpandableText(review.body)
ExpandableText(place.description, lineLimit: 5, font: AppTypography.bodySmall)
```

Keys `text.more` / `text.less` (defaults "More" / "Less").

#### `MonthCalendar` / `CalendarRange` *(0.7.0)*
Swipeable week strip that expands to swipeable months (tap the header), with markers on the
days things happen. From Tenra's subscription calendar; Dalada can show trips and bans.

```swift
@State private var range = CalendarRange()               // 8 weeks back, 47 ahead, 12 months
@State private var byDay: [Date: [RecurringSeries]] = [:]

MonthCalendar(range: range, itemsByDay: byDay, itemName: \.description) { sub in
    Icon(source: sub.iconSource, size: AppIconSize.md)
} accessory: { period in                                  // visible week or month
    if let total = totals[period] { FormattedAmountText(amount: total, currency: base, ...) }
}
.onAppear { byDay = range.itemsByDay(subscriptions) { sub, interval in sub.occurrences(in: interval) } }
```

Keep the range in `@State`. `CalendarPeriod.interval` ends at the next period's start;
`closedInterval` ends a second earlier for APIs that test `date <= end`. Markers are drawn
`AppIconSize.md` in a circle, up to `maxMarkers` (3), then "+N". Header VoiceOver action:
keys `calendar.showMonth` / `calendar.showWeek`.

#### `ActivityTimeline` *(0.7.0)*
Events top to bottom on a continuous line: check-ins of a trip, history of a record.

```swift
ActivityTimeline(checkins) { checkin in
    TimelineMarker(systemImage: "mappin", color: AppColors.success)   // or .dot
} content: { checkin in
    VStack(alignment: .leading) { Text(checkin.title); Text(checkin.time).font(AppTypography.caption) }
}
```

Not lazy (put long histories in a `ScrollView` and page the data). Named "Activity" to avoid
SwiftUI's `TimelineView` and WidgetKit's `TimelineEntry`.

#### `TagInput` *(0.7.0)*
Free-form tags as removable chips, a field for the next one, and matching suggestions.

```swift
TagInput(String(localized: "gear.tags.placeholder"), tags: $item.tags, suggestions: common)
```

Return or a comma adds; duplicates (ignoring case) and blanks are dropped; `maxTags` hides the
field when full. VoiceOver on ×: key `tags.remove` ("Remove %@"). A fixed set of options →
`ChipPicker`.

#### `MessageComposer` *(1.12.0)*
The field at the bottom of a conversation (comments, replies): Liquid Glass that grows to five
lines, the send button inside it, the quote of the message being answered above the text, the
send error over the field.

```swift
List { … }
    .safeAreaBar(edge: .bottom) {
        MessageComposer(text: $text, placeholder: String(localized: "comments.placeholder"),
                        quote: quote, isSending: isSending, canSend: draft.isValid,
                        errorMessage: sendError, focus: $isFocused,
                        onCancelQuote: { quote = nil }) {
            Task { await send() }
        }
        .screenPadding()
        .padding(.bottom, AppSpacing.sm)
    }
```

- **Send button:** an accent circle with an arrow; grey while the text is blank (or `canSend` is
  false), a spinner while `isSending`. The glass corner is concentric with it (radius 20).
- **Placement:** the glass floats over the content, so use `safeAreaBar` (the scroll edge
  blurs under it), not a `.bar` background; the caller gives the side margins.
- **Disabled:** `.disabled(true)` greys it out; let the placeholder say why ("Sign in to
  comment").
- **Quote:** `MessageQuote(title: "Replying to Aida", text: …)`, the same type `CommentRow`
  shows in a reply; the × calls `onCancelQuote`.
- VoiceOver: keys `composer.send` ("Send") and `composer.cancelQuote` ("Remove quote").
- An input: no skeleton.

#### `FlowLayout` *(0.7.0)*
A `Layout` that wraps subviews to new lines like words: tags, badges, chips that should not
scroll. `FlowLayout(spacing:lineSpacing:) { ForEach(tags, id: \.self) { Badge($0) } }`.

#### `HeroSymbol` *(0.7.0)*
Large SF Symbol on a disc of its tint at 12%: the picture of `OnboardingPage` and
`PromptSheet`. `HeroSymbol(systemImage: "map", size: 96, tint: AppColors.success)`.
Decorative (hidden from VoiceOver).

#### `Rating` / `RatingPicker` *(0.4.0)*
Star rating. `Rating` displays with half stars (filled from .75, half from .25 of a star);
`RatingPicker` is the tap-to-rate input (whole stars, haptic on tap).

```swift
Rating(rating: summary.average, size: 12)
RatingPicker(rating: $draft.rating)
```

Default colour `AppColors.warning`, maximum 5. VoiceOver keys: `rating.value`, `rating.pick`
([localization-keys.md](localization-keys.md)).

#### `GradientOrbsBackground` *(1.5.0)*
Up to three soft, heavily blurred colour orbs (`Orb(color:weight:)`, heaviest first) at fixed positions; weight sets an orb's size and brightness, the first two blur deeper (44) than the third (28), blended `.screen` and rasterised once (`drawingGroup`). Static by design (animating it was the home screen's main jank). Put it behind a glass card, clipped to the card's shape; never inside `List` / `ForEach`. Tenra: `CategoryGradientBackground` (top expense categories → colours) is an adapter.

---

### Community & Progress Components *(1.12.0)*

Ported from Dalada with neutral names. The app keeps what loads and acts (photos behind signed
URLs, the reactions store, moderation, the achievement catalogue) and passes views and
strings in. Gallery: their sections (Rows, Cards, Actions, Media); snapshots: `CommunitySnapshotTests`.

#### `PersonRow`
Avatar (40), name (bodyEmphasis), a caption line under it (the @username, a status) and a
trailing slot. `PersonRow(name:subtitle:avatar:trailing:)` takes the app's avatar view;
without `avatar` it draws the initials (`Avatar`). A row that lives in a `List`: no padding. Dalada: friends, requests,
search, the people a trip is shared with.

`detail:` *(2.8.0)* adds a third line in the tertiary colour (the city). `style: .card` is the
person at the top of their profile: the avatar 64 pt (`AppIconSize.Tile.xl`), the name in `h4`,
the @username in bodySmall, `AppSpacing.lg` between avatar and text, in a card that pads itself
(`cardContentPadding` + `cardStyle`). Dalada: `ProfileHeader` is an adapter.

#### `CommentRow` and `MessageQuote`
A comment or a reply: a 32 pt avatar, the author, the time ("10 minutes ago") on the right
with a menu slot after it, the quoted message (`MessageQuote(title:text:)`: a grey bar, who,
three lines of what), the text (`AttributedString`, selectable, bodySmall) and an actions row
(caption font, 16 apart: reactions, "Reply", "edited"). The same `MessageQuote` is what
`MessageComposer` shows above the text being written.

```swift
CommentRow(author: "Timur", date: post.createdAt, text: MentionText.attributed(post.body),
           quote: quote, avatar: AppAvatar(path: post.author.avatarPath, size: CommentRowMetrics.avatarSize)) {
    ModerationMenu(…)
} actions: {
    ReactionButton(…)
    Button("Reply") { … }
}
```

#### `ThreadCard`
A discussion in a list (a card): the title (two lines), the start of the text (two lines,
caption, secondary), and a tertiary caption footer with the replies count (`bubble.left`),
the author and the last activity on the right.
`ThreadCard(title:preview:repliesCount:author:lastActivity:)`.

#### `ReviewCard`
A review (a card): author, `Rating` (12 pt stars), the time and a menu slot; a caption line
(when the place was visited); the text in an `ExpandableText` folded to four lines; a media
slot (photos) and an actions row (12 apart). `ReviewCard(author:rating:date:subtitle:text:menu:media:actions:)`.

#### `ReactionButton`
A symbol and a count under a post ("👍 12"), or a title ("Helpful · 3"); filled and in the
accent colour once the user has reacted, a selection haptic on tap, a tap area of at least
44 pt. With `action: nil` (one's own post, a guest) it is the outlined symbol and the count,
and nothing at zero. `ReactionButton(systemImage:selectedSystemImage:count:isSelected:title:accessibilityLabel:action:)`.
A control: no skeleton.

#### `AchievementMedal`, `AchievementTile`, `AchievementProgressRow`
- **Medal:** an SF Symbol in white on a disc of the achievement's colour once earned; a
  tertiary symbol on `bgMuted` until then. Decorative for VoiceOver.
- **Tile:** the medal, the title under it (caption, two lines, centred) and, while not earned,
  the progress text ("7 of 10", caption2, tertiary). For grids.
- **Progress row:** a 32 pt medal, "Up next:" (secondary), the title, the progress text on the
  right and a 6 pt `LinearProgressBar` under them.

#### `ChecklistRow`, `ChecklistSummaryRow`
- **Item:** `SelectionIndicator` (success tint), the title struck through and secondary once
  ticked, an optional tertiary mark on the right (`accessorySystemImage`, `accessoryLabel`);
  a tap calls `onToggle`.
- **Checklist in a list:** the title with a success seal once complete, a caption line with a
  calendar (the day it is for), a 6 pt bar (success when complete) and "12 of 20" under it; an
  empty list says "No items yet". Keys: `checklist.progress %lld %lld`, `checklist.empty`,
  `checklist.complete`, each replaceable by a parameter (Dalada keeps "Packed").

#### `StatsStrip`
Counters side by side in a card: the number (h4, tabular, shrinks to 60%) over its caption
(two lines, centred), equal widths; at accessibility text sizes two columns, so a caption is not
broken mid-word. `StatsStrip(items: [.init(value: "42", title: "days")])`.
For one figure with a trend, `StatTile`.

#### `StreakCard`
A streak in a card: a 24 pt symbol (accent while it runs, tertiary once it stopped), the title
and what to do next, the best result on the right with its caption.
`StreakCard(systemImage:isActive:title:subtitle:value:valueCaption:)`.

#### `ThumbnailCard`, `ThumbnailRow`, `ThumbnailPlaceholder`
Something with a picture: the picture slot (a photo, or `ThumbnailPlaceholder(systemImage:tint:)`,
a symbol on the pale tint), the title (bodyEmphasis) with an accent seal (`isVerified`) and a
bookmark (`isSaved`), and a details slot in caption secondary.
- **Card:** for carousels; the picture is 200 × 110 (`ThumbnailMetrics`), `AppRadius.md`, the
  bookmark an accent disc on its corner; no glass, no padding.
- **Row:** for lists; a 64 pt picture on the left, the title on two lines.
- VoiceOver: keys `thumbnail.verified` ("Verified"), `thumbnail.saved` ("Saved"), or
  `verifiedLabel` / `savedLabel`.

### Media, Sharing & Offline *(2.8.0)*

Ported from Dalada with neutral names; the app keeps loading (signed URLs, the photo cache, the
recorder, the download manager) and passes views and strings in. Gallery: Media, Sheets,
Navigation, Rows, Content; snapshots: `MediaSnapshotTests` (skeletons in `SkeletonsSnapshotTests`).

#### `PhotoTile`
A photo cropped to a square on `AppColors.bgMuted` (what shows while it loads), corners
`AppRadius.md`. `PhotoTile(size:cornerRadius:) { image }` takes the app's image view filling the
tile; `PhotoTile(image: UIImage?)` takes a loaded image, or shows `PhotoPlaceholderSymbol`
(the photo symbol, tertiary). `size: nil` fills the width and stays square (a grid cell); the
default is 88 (`PhotoTileMetrics.size`). Dalada: a picked photo's preview in forms.

#### `PhotoStrip`
Photo tiles in a horizontal scroll, `AppSpacing.sm` apart: `onOpen:` makes each a button (a
report's photos, a place's header at `size: 150`); `onRemove:` puts a remove button (22 pt
`xmark.circle.fill`, white on black 55%) on each tile's corner (photos picked for a form).
VoiceOver: `photo.open`, `photo.remove`, or `openLabel` / `removeLabel`.

#### `PhotoGrid`
Square photo cells in columns (3 by default), lazy: put it in a `ScrollView`. `style: .rounded`
(tiles `AppRadius.md`, `AppSpacing.xs` apart: a person's photos) or `.edgeToEdge` (square cells
2 pt apart: a gallery). `onReachEnd` fires as the last cell appears (the next page); `label`
gives each photo's VoiceOver name.

#### `PhotoCarousel`
A post's photos one at a time in a rounded 4:3 frame (`PhotoCarouselMetrics.aspectRatio`), paged
with dots when there are several; `onOpen` opens the photo. A `TabView(.page)` on `bgMuted`.

#### `PhotoViewer`
Photos full screen: black, dark scheme, paged, ✕ to close (`common.close`). Zoom *(new in the
port)*: pinch up to 4×, drag while zoomed (the drag is off at 1×, so a swipe turns the page),
double-tap to 2.5× and back, VoiceOver's zoom gesture. `caption:` adds a dark band at the
bottom (black 45%, white text) with "2 / 5" under it, and then the page dots go; `actions:` puts
a control in the top bar (report, block). Present it with `.fullScreenCover`, pass the photo
fitted (`.scaledToFit()`).

#### `ShareCardFrame`, `ShareCardStat`, `ShareCardFormat`, `ShareCardStyle`
A picture to share: `ShareCardFormat.story` (360 × 640) or `.post` (360 × 450), rendered at 3×
(1080 px). The frame lays the content out from the top, padded 28, in white, with the brand
(22 pt heavy rounded) and the site (11 pt, 70%) at the bottom; behind, the photo under a dark
gradient, or the style's gradient. `ShareCardStyle(top:bottom:accent:)` (`.standard`: graphite
with the accent) stays the same in light and dark: the picture leaves the app. `ShareCardStat`
is a number (24 pt bold rounded) over its caption (12 pt, 70%). Fixed sizes on purpose: the
card is an image, not a screen. Dalada: the trip, catch and place cards are its own content in
the frame, with its teal style.

#### `ShareCardSheet`
`ShareCardSheet(previewTitle:formats:load:message:card:)`: a segmented format picker
(`share.format`), the picture (drawn with `ImageRenderer` when the data arrives and when the
format changes), and a full-width share button (`share.send`) that sends it with `message`.
While `load` runs the preview is `ShareCardSkeleton`; `nil` shows `EmptyState(.error)` with
`share.failed`. Title: `share.title`, or `title:`.

#### `LiveSessionBar` and `.liveSessionAccessory`
A session going on (a recording): a pulsing `record.circle` in the destructive colour, or
`pause.circle.fill` in the warning colour when paused; the time since `startedAt`
(`H:MM:SS`, once a second); a detail in the secondary colour; a chevron up. bodyEmphasis,
padded `lg` horizontally. `.liveSessionAccessory(isEnabled:) { LiveSessionBar(…) }` shows it in
the tab bar's bottom accessory on iOS 26.1+ (`LiveSessionAccessory.isAvailable`); on 26.0 give
another way back. Dalada: `TripMiniPlayer` is an adapter.

#### `DownloadRow`
Something to download for offline use: the name (bodyEmphasis) and a caption line, then the
action. `Status`: `.available` and `.paused` (caption; download button), `.downloading(p)` (a
6 pt bar over the caption; pause button), `.downloaded` (accent check mark before the
caption; no action), `.failed` (caption in the destructive colour; download button). The app
writes the caption ("About 80 MB", "40% · 32 MB") and adds the swipe to delete. Vertical
padding `xxs`. VoiceOver: `download.start` / `download.pause`, or the labels it passes.

#### `ArticleBody`
An article's blocks, `AppSpacing.md` apart: `.heading(_, level:)` (title3 semibold or headline,
a header trait), `.paragraph`, `.bullets`, `.steps` (numbers in the accent), `.note` (an info
symbol and bodySmall text in a card). Inline Markdown inside a block (**bold**, *italic*,
links). The app parses its article format into blocks.

### Content Reveal (Loading Transitions)

#### `.contentReveal(isReady:delay:)`
Fades content in when `isReady` becomes true. Preserves view identity (no `if/else` branching).
Optional `delay` staggers multiple sections for a smooth cascading reveal.

```swift
// Single section
accountsSection
    .contentReveal(isReady: coordinator.isFastPathDone)

// Staggered reveal — sections fade in 50ms apart
historySection
    .contentReveal(isReady: coordinator.isFullyInitialized)
subscriptionsSection
    .contentReveal(isReady: coordinator.isFullyInitialized, delay: 0.05)
loansSection
    .contentReveal(isReady: coordinator.isFullyInitialized, delay: 0.1)
```

**Why not skeletons?** The previous `SkeletonLoadingModifier` used `if/else` branching which destroyed view identity — causing shimmer animation failures, UI jerk on content reveal, and layout recalculation spikes when multiple sections materialized simultaneously. `ContentRevealModifier` keeps content always in the hierarchy (just invisible) and uses simple opacity fade.

#### `.staggeredEntrance(delay:)`
Animates view entrance with scale + opacity pop-in. Used for facepile icon stacks.

```swift
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    Icon(source: item.iconSource, style: iconStyle)
        .staggeredEntrance(delay: Double(index) * AppAnimation.facepileStagger)
}
```

Used in: `StaticSubscriptionIconsView`, `LoanFacepileIconsView`.

#### `BlurSlideTransition` (text reveal)
Canonical transition for animated text appearance: insertion slides up from below + un-blurs + fades in; removal keeps sliding up + blurs + fades out. Lives in `Views/Components/Feedback/BlurSlideTransition.swift`. Use the presets — don't hand-tune parameters at call sites:

| Preset | Params | Use For |
|--------|--------|---------|
| `.blurSlideHero` | slide 24, blur 10 | Block-level text (onboarding hero title/subtitle) |
| `.blurSlideWord` | slide 18, blur 6 | Per-word streaming text (voice transcription). Lighter on purpose — many words can transition at once and per-word blur is the dominant GPU cost |

```swift
Text(phase.title)
    .id(index)
    .transition(.blurSlideHero)

// Per-word (see AnimatedTranscriptionText — stable word IDs ensure only NEW words animate)
Text(token.text)
    .transition(.blurSlideWord)
```

Used in: `OnboardingWelcomeStep`, `AnimatedTranscriptionText`.

#### `AccentGlow` (ambient edge glow)
Blurred gradient circle rising from a screen edge (`Views/Components/Feedback/AccentGlow.swift`). Static — no animation loop, no hit-testing, hidden from VoiceOver. Tunables in `GlowMetrics` (blur 120, 85% off-screen, hero intensity 0.45).

| Preset | Edge | Tint | Use For |
|--------|------|------|---------|
| `.onboardingAccentGlow()` | bottom, full intensity | `AppColors.accent` | Onboarding screen backgrounds |
| `.heroAccentGlow(icon:tint:)` | top, 0.45 intensity | Resolved from the hero icon | Entity-detail screens (apply to `EntityDetailScaffold`, pass the same `icon`/`tint` as the `HeroSection`) |

`heroAccentGlow` tint resolution: explicit `IconTint` colour (monochrome/hierarchical/palette) → that colour immediately; `.brandService` → dominant logo colour via `DominantColorExtractor` (async — glow renders with the fallback and cross-fades with `gentleSpring` when the brand colour arrives); otherwise `AppColors.accent`. Pure black/white logos yield no extractable accent — the fallback stays.

```swift
EntityDetailScaffold(... hero: { HeroSection(icon: liveCategory.iconSource, ...) })
    .heroAccentGlow(icon: liveCategory.iconSource, tint: .monochrome(liveCategory.color))
```

Used in: `OnboardingWelcomeStep` (bottom), Account/Category/Subscription/Deposit/Loan detail views (top).

---

## 4. View Patterns

### Edit View — Hero Style
Used by: `AccountEditView`, `SubscriptionEditView`, `CategoryEditView`, `DepositEditView`, `LoanEditView`

```
EditSheetContainer(wrapInForm: false)
└── ScrollView
    └── VStack(spacing: AppSpacing.xl)
        ├── EditableHeroSection(config: .accountHero)  // icon + title + balance
        ├── FormSection(.card, header: "Details") {
        │   ├── UniversalRow { ... }
        │   ├── Divider()
        │   ├── MenuPickerRow(...)
        │   ├── Divider()
        │   └── DatePickerRow(...)
        │   }
        └── FormSection(.card, header: "More") { ... }
```

### Edit View — Native Form
Used by: `LoanPaymentView`, `LoanRateChangeView`, `LoanEarlyRepaymentView`, `DepositRateChangeView`

```
EditSheetContainer(wrapInForm: true)
└── Form (auto-wrapped)
    ├── Section(header: "Basic Info") {
    │   ├── TextField(...)
    │   ├── Picker(...)
    │   └── Toggle(...)
    │   }
    ├── Section(header: "Details") {
    │   ├── DatePicker(...)
    │   └── TextField(...)
    │   }
    └── InlineStatusText(...)  // validation below sections
```

### Detail View
Used by: `SubscriptionDetailView`, `DepositDetailView`, `LoanDetailView`

```
ScrollView
└── VStack(spacing: AppSpacing.lg)
    ├── Card 1: Header (.cardStyle())
    │   └── Icon(.glassHero) + Title + Balance
    ├── Card 2: Info (.cardStyle())
    │   └── InfoRow list
    ├── Card 3: Stats (.cardStyle())
    │   └── InfoRow / custom rows
    ├── Actions Section
    │   ├── DSButton("…", fullWidth: true) { }
    │   └── DSButton("…", appearance: .secondary, fullWidth: true) { }
    └── .toolbar { Menu("...") { edit, delete, ... } }
```

Cards use staggered `.chartAppear(delay:)` for entrance animation.

### List View — Management
Used by: `AccountsManagementView`, `CategoriesManagementView`

```
List {
    ForEach(items) { item in
        CustomRow(item)
            .swipeActions(edge: .trailing) { delete }
    }
    .onMove { reorder }
}
.toolbar { Button("Add") { showAddSheet = true } }
.sheet(isPresented: $showAddSheet) { EditView() }
```

### List View — Scrollable Cards
Used by: `SubscriptionsListView`, `LoansListView`

```
ScrollView
└── VStack(spacing: AppSpacing.lg)
    ├── Optional summary card (.cardStyle())
    └── ForEach(items) { item in
            NavigationLink(value: destination) {
                ItemCard()
            }
            .chartAppear(delay: index * 0.05)
        }
```

### Transaction List (History)
```
List {
    ForEach(sections.prefix(visibleSectionLimit)) { section in
        Section {
            ForEach(section.transactions) { tx in
                TransactionCard(transaction: tx, styleData: preComputed, ...)
            }
        } header: {
            SectionHeader(section.dateKey, style: .card) {
                if total > 0 {
                    FormattedAmountText(amount: total, currency: cur, prefix: "-",
                                        fontSize: AppTypography.bodySmall, fontWeight: .semibold,
                                        color: AppColors.Text.tertiary)
                }
            }
        }
    }
    // Infinite scroll trigger
    if visibleSectionLimit < sections.count {
        ProgressView().onAppear { visibleSectionLimit += 100 }
    }
}
```

### Settings
```
List {
    SettingsGeneralSection(...)
    SettingsDataManagementSection(...)
    SettingsExportImportSection(...)
    SettingsDangerZoneSection(...)
}
```

Each section uses `UniversalRow(config: .settings)` with `.navigationRow {}` or `.actionRow(role:) {}`.

### Home Screen (Dashboard)
```
ScrollView
└── VStack(spacing: AppSpacing.lg)
    ├── AccountsCarousel (UniversalCarousel)
    ├── CashFlowCard (3-state: loading/empty/data)
    ├── CategoryGridView (adaptive grid of category chips)
    ├── SubscriptionsCardView (.cardStyle())
    └── LoansCardView (.cardStyle())
```

---

## 5. Decision Trees

### "Which input component?"

```
Amount input?
├── Hero-style (large, animated) → AnimatedAmountInput
└── Compact form row → FormTextField(keyboardType: .decimalPad)

Text input?
├── Hero title (large, animated) → AnimatedTitleInput
├── Multiline description → FormTextField(style: .multiline(min:max:))
├── Single-line form field → FormTextField(style: .standard)
└── A message sent at once (comment, reply) → MessageComposer

Date input?
├── Transaction (needs Yesterday/Today shortcuts) → DateButtons / .dateButtonsSafeArea()
└── Other (subscription start, deposit posting) → DatePickerRow

Single-select picker?
├── Few options (2-5) in form → MenuPickerRow
├── 2-4 exclusive modes → SegmentedPicker
└── Many options → NavigationLink to selection list

Currency?
└── CurrencySelectorView (inside EditableHeroSection, automatic)
```

### "Which row component?"

```
Inside FormSection(.card)?
└── Always use UniversalRow(config: .standard)
    ├── Read-only label+value → InfoRow (wrapper)
    ├── Picker → MenuPickerRow (wrapper)
    ├── Date → DatePickerRow (wrapper)
    └── Custom content → UniversalRow directly

Inside List (settings)?
└── UniversalRow(config: .settings)
    ├── With navigation → .navigationRow { }
    ├── With action → .actionRow(role:) { }
    └── With toggle → trailing: { Toggle(...) }

Transaction list row?
└── TransactionCard (NOT UniversalRow)

Balance list row (accounts, wallets)?
└── AmountRow(style: .list, value: .amount) (NOT UniversalRow)

Row with a limit (budget ring around the icon)?
└── AmountRow(style: .list, value: .limit) (NOT UniversalRow)

A part of a whole, an insight's item (amount on the trailing edge)?
└── AmountRow(value: .share / .amount), the info style on UniversalRow(.info)
```

### "Which container?"

```
Modal edit form?
└── EditSheetContainer
    ├── Entity edit (account/category/subscription/deposit/loan) → wrapInForm: false (hero-form)
    └── Simple action form (payment, rate change) → wrapInForm: true

Grouping form rows?
├── Inside hero-form → FormSection(.card)
├── Inside native Form → Section(header:)
└── Inside List → FormSection(.list) or Section

Horizontal scroll?
└── UniversalCarousel with appropriate preset

Card-style container?
└── VStack { ... }.cardStyle()
```

### "Which icon approach?"

```
Entity icon with styled background?
└── Icon(source:style:)
    ├── Account → .bankLogo(size:) or .bankLogoLarge(size:)
    ├── Category → .categoryIcon(size:) or .categoryCoin(size:)
    ├── Subscription → .serviceLogo(size:) or .glassHero(size:)
    └── Nil/unknown → .placeholder(size:)

Semantic UI indicator?
└── Image(systemName:) directly
    Examples: chevron.right, checkmark, xmark, plus, ellipsis
```

### "Which feedback component?"

```
Transient post-action result?
└── MessageBanner (.success/.error/.warning/.info)

A notice that stays on the screen or in a card?
└── StatusBanner (.info/.positive/.negative/.warning/.neutral; action → chevron)

Persistent form validation?
└── InlineStatusText (.error/.warning/.info/.success)

Entity lifecycle status?
└── StatusIndicatorBadge (.active/.paused/.archived/.pending)

No data to show?
└── EmptyState
    ├── Full screen → .standard
    ├── Inside card → .compact
    └── Error/failure → .error

Asking for a permission (notifications, location, camera)?
└── PromptSheet first, then the system alert from its async onPrimary
```

---

## 6. Formatting & Display

### Amount Formatting

#### Hard rule
**A money value MUST never reach the user without a canonical formatter.** No exceptions for "temporary" code, debug screens, prototypes, or previews that get committed. If you are about to render a `Double`/`Decimal` that represents money, use one of the entries in the decision tree below — nothing else.

#### Decision tree — what to use

```
Rendering a money amount?
├── Standalone view (card, header, list row's trailing amount, chart label)?
│   └── → FormattedAmountText(amount:currency:prefix:fontSize:fontWeight:color:)
│
├── Inside InfoRow / InfoRowConfig (label-value row in detail screens)?
│   ├── Single amount → InfoRow(... amount: X, currency: Y, prefix: "")
│   │                 → InfoRowConfig(... amount: X, currency: Y, prefix: "")
│   │   (renders FormattedAmountText internally, with `value:` fallback for VoiceOver)
│   │
│   └── Composite value ("X / Y (Z%)", "spent / budget", "+A · −B")?
│       → InfoRowConfig(... value: "<accessibility-fallback>", valueContent: AnyView(
│             HStack { FormattedAmountText(...); Text("/"); FormattedAmountText(...); ... }
│         ))
│       NEVER inline composite money rows as plain `Text("\(spent) / \(total)")` — the
│       individual amounts lose smart-decimal collapse and dimmed `.XX` styling, looking
│       inconsistent with adjacent rows.
│
├── Need a plain String (HeroSection.subtitle, composed sentence like "Scheduled: %@",
│   "X / Y (Z%)", accessibilityLabel)?
│   └── → Formatting.formatCurrencySmart(amount, currency:)
│
├── Input component (user typing an amount)?
│   └── → AmountInputView / AmountInput / AmountDigitDisplay / AnimatedAmountInput
│       (these use AmountInputFormatting internally — do not bypass)
│
├── Compact chart axis label?
│   └── → ChartAxisHelpers.formatCompact(amount)
│
├── Storage, CSV, search-match key, persistence?
│   └── → AmountFormatter.format(_:) / .parse(_:)
│
└── Hot-path List/ForEach where you need a NumberFormatter object?
    └── → AmountDisplayConfiguration.formatter (CACHED — never call .makeNumberFormatter())
```

#### Calculator amount input

`AmountInputView(calculatorModel:)` swaps the system keyboard for an in-app `CalculatorKeypad` driven by `CalculatorInputModel` (pure `Decimal` evaluator `ExpressionEvaluator` — `+ − × ÷`, no `=`, live result). Used in `TransactionAddModal`, `AccountActionView`, `TransactionEditView`, `LoanPaymentView`, `LoanEarlyRepaymentView`. (Entity-edit heroes via `EditableHeroSection` stay on the system keyboard — they're forms, not calculators.)

- Host owns `@State CalculatorInputModel`, places `CalculatorKeypad` via `.safeAreaInset(.bottom)`, and mirrors `calc.amountText → formData.amountText` with `.onChange` (validation/save/conversion keep reading the existing amount binding).
- Pre-fill via `CalculatorInputModel(seed:)` (at init) or `.seed(_:)` (in `onAppear`, for defaults computed late).
- ⚠️ **A form with BOTH the keypad AND an inline `FormTextField` (description) must coordinate focus or two keyboards stack.** Pattern: host `@FocusState descriptionFocused`; pass `externalFocus: $descriptionFocused` to the text field; show the keypad `if !descriptionFocused`; wire `AmountInputView(onCalculatorTap:)` to set it `false`. `FormTextField(externalFocus:)` is optional and defaults to internal focus (existing call sites unchanged).

#### Forbidden patterns (will be flagged in code review)

| Pattern | Why forbidden | Fix |
|---------|---------------|-----|
| `Text("\(amount) \(currency)")` | No grouping separator, no symbol lookup, no smart decimals | `FormattedAmountText(amount:currency:)` |
| `Text(String(format: "%.2f", amount))` | No currency, locale-deaf | `FormattedAmountText` or `formatCurrencySmart` |
| `Text(String(format: "%@%@", "+", Formatting.formatCurrency(...)))` | Manual sign composition | `FormattedAmountText(... prefix: "+")` or `formatCurrencySmart` + read sign from value |
| `NumberFormatter()` allocated inside `body`/`List`/`ForEach` | Per-frame allocation in hot path | `AmountDisplayConfiguration.formatter` |
| `Formatting.formatCurrency(...)` **for display** | Always shows `.00` ("14 924 515.00 ₸") — looks broken for round numbers | `formatCurrencySmart` (or `FormattedAmountText`). `formatCurrency` is reserved for accessibilityLabel and storage |
| `Decimal` / `NSDecimalNumber` rendered via interpolation | Same — no symbol, no grouping | Convert with `NSDecimalNumber(decimal:).doubleValue` and pass to a formatter |

#### Overflow: `AmountDisplayPolicy`

`FormattedAmountText` decides for itself what to do when the container is too narrow — no
call site should hand-shorten an amount.

| Policy | Behaviour | Where |
|---|---|---|
| `.adaptive` (**default**) | `ViewThatFits`: full number → "1,2 млн ₸" → "1 млн ₸" | everything by default |
| `.full` | never abbreviates | amount editors, calculator display |
| `.compact` | always abbreviated | very tight chrome |

Rules that make this safe:
- **A value that fits always renders in full**, so adopting `.adaptive` changed nothing on
  screens whose amounts already fitted. Never pre-shorten by calling
  `Formatting.formatCurrencyCompact` directly in a view.
- Abbreviations come from the system's compact notation
  (`Formatting.formatCurrencyCompact`), so unit names follow the reader's locale —
  including ja/ko, which group by 10 000 (万 / 억), not 1 000. A hand-rolled K/M table
  prints the wrong magnitude there. Pinned by `FormattingCompactTests`.
- A compact string can be **longer** than the full one ("10 тыс. ₸" vs "10 000 ₸"), so a
  candidate is offered only when it is actually shorter; otherwise the full text repeats
  in that slot. Never put an `if` inside `ViewThatFits` — an absent candidate becomes an
  `EmptyView`, which always "fits" and renders nothing.
- VoiceOver always reads the FULL amount (`accessibilityLabel`). An abbreviation is a
  layout concession, not a change of value.
- `.minimumScaleFactor` at the call site still applies, as the last resort after the
  smallest candidate.

#### Reference table

| Context | Function / Component | Decimals |
|---------|----------------------|----------|
| Standalone view display | **`FormattedAmountText`** | Smart (hides `.00`, dims `.XX`); abbreviates only when it doesn't fit |
| Abbreviated amount (fallback only) | `Formatting.formatCurrencyCompact(_:currency:)` | Localized compact ("1,2 млн ₸") |
| InfoRow / InfoRowConfig | **`init(... amount: currency:)`** | Smart (delegates to `FormattedAmountText`) |
| Composed display string | **`Formatting.formatCurrencySmart(_:currency:)`** | Smart (0 or 2) |
| Accessibility / VoiceOver / CSV | `Formatting.formatCurrency(_:currency:)` | Always 2 (legacy compat — DO NOT use for display) |
| Storage / parse | `AmountFormatter.format(_:)` / `.parse(_:)` | Always 2 |
| User typing | `AmountInputFormatting.displayAmount(for:)` | 0–2 |
| Chart axis (compact) | `ChartAxisHelpers.formatCompact(_:)` | Compact ("12K", "1.2M") |
| `NumberFormatter` instance in hot path | `AmountDisplayConfiguration.formatter` (cached) | Configured |

**Never call `AmountDisplayConfiguration.makeNumberFormatter()` in List/ForEach** — use `.formatter` (cached).

#### Sign and prefix

For signed deltas ("+1 200 ₸" / "−500 ₸"):
- **Negative is automatic** — `NumberFormatter` and `FormattedAmountText` already render `"-1 200 ₸"` for negative `Double`.
- **Positive needs explicit `prefix: "+"`** — pass `prefix: diff > 0 ? "+" : ""` to `FormattedAmountText` or `InfoRow(... amount:currency:prefix:)`.
- DO NOT compose with `String(format: "%@%@", "+", Formatting.formatCurrency(...))`.

For income/expense `+`/`−` styling in transaction lists, use `TransactionDisplayHelper.amountPrefix(for:)` + `TransactionDisplayHelper.amountColor(for:)` and pass results to `FormattedAmountText`.

### Currency Symbols

```swift
Formatting.currencySymbol(for: "KZT") // → "₸"
```

Supported: KZT→₸, USD→$, EUR→€, RUB→₽, GBP→£, CNY→¥, JPY→¥. Unknown → code string.

### Transaction Amount Color/Prefix

```swift
TransactionDisplayHelper.amountColor(for: .income)   // → .green
TransactionDisplayHelper.amountPrefix(for: .expense)  // → "-"
```

Deposit-aware overloads accept `targetAccountId`, `depositAccountId`, `isPlanned`.

### Date Formatting

| Formatter | Format | Use For |
|-----------|--------|---------|
| `DateFormatters.dateFormatter` | `yyyy-MM-dd` | Storage, parsing |
| `DateFormatters.displayDateFormatter` | `d MMMM` | Display ("10 March") |
| `DateFormatters.displayDateWithYearFormatter` | `d MMMM yyyy` | Display with year |
| `DateFormatters.timeFormatter` | `HH:mm` | Time display |

### Category Styling

Pre-compute at ForEach call site, not inside row views:

```swift
let styleData = CategoryStyleHelper.cached(
    category: tx.category,
    type: tx.type,
    customCategories: customCategories
)
// Pass styleData (Equatable struct) to TransactionCard
```

`CategoryStyleCache.shared` handles caching. Invalidate on category edit via `.invalidateCategory(_:type:)`.

---

## 7. Haptics

Use `HapticManager` for all haptic feedback:

| Event | Call |
|-------|------|
| Navigation tap, filter change | `HapticManager.selection()` |
| Sheet open, picker tap | `HapticManager.light()` |
| Save/confirm success | `HapticManager.success()` |
| Destructive action initiation | `HapticManager.warning()` |
| Validation failure | `HapticManager.error()` |
| Drag/reorder | `HapticManager.medium()` |

View modifier: `.hapticFeedback(.light)` attaches tap gesture haptic.

---

## 8. Remaining Native Form Views

The following views still use `EditSheetContainer(wrapInForm: true)` with native `Form`/`Section`. This is intentional — they are simple single-purpose forms (payment entry, rate change) where hero-style UI would be overkill:

- `LoanPaymentView` — single amount + date entry
- `LoanRateChangeView` — single rate + date entry
- `LoanEarlyRepaymentView` — amount + type selection
- `DepositRateChangeView` — single rate + date entry

All primary entity edit views (`Account`, `Subscription`, `Category`, `Deposit`, `Loan`) now use the hero-form pattern consistently.

---

## 9. Animation Guidelines

### Never use hardcoded springs

All animations must use `AppAnimation` constants. Never use inline `.spring(response:dampingFraction:)`.

| Context | Token |
|---------|-------|
| Validation errors, content toggles | `AppAnimation.contentSpring` |
| Amount changes, state transitions | `AppAnimation.gentleSpring` |
| Facepile icon entrance | `AppAnimation.facepileSpring` |
| Chart entrance (opacity+scale) | `AppAnimation.chartAppearAnimation` |
| Chart data updates | `AppAnimation.chartUpdateAnimation` |
| Chart selection banner | `AppAnimation.chartBannerFade` |
| Section fade-in on init | `AppAnimation.contentRevealAnimation` |
| Progress bar expansion | `AppAnimation.progressBarSpring` |
| Visible-overshoot bounce (button press) | `AppAnimation.adaptiveSpring` |

### Animation Modifiers

- **`.staggeredEntrance(delay:)`** — `scale(0.5→1.0)` + opacity pop-in. Use for facepile icons, overlapping avatar stacks. Delay per icon: `Double(index) * AppAnimation.facepileStagger`.
- **`.chartAppear(delay:)`** — `scale(0.94→1.0)` + opacity from bottom. Use for chart containers and card entrances in scrollable lists.
- **`.contentReveal(isReady:delay:)`** — opacity fade-in. Use for staggered section reveals during initialization (home, insights).
- **`.filterChipStyle(isSelected:)`** — includes animated selection transition via `contentSpring`.

### Card State Transitions (empty↔loaded)

Cards with empty/loaded states must animate the transition:

```swift
if items.isEmpty {
    EmptyState(...).transition(.opacity)
} else {
    loadedContent.transition(.opacity)
}
// Outside the conditional:
.animation(AppAnimation.gentleSpring, value: items.isEmpty)
```

### Reduce Motion

Movement-based decorative animations respect Reduce Motion. Two mechanisms:

- **Token layer** — Reduce Motion-aware variants (`adaptiveSpring`, `fastAnimation`, `chartAppearAnimation`, `chartUpdateAnimation`, `heroEntranceAnimation`, `donutSweepAnimation`, `progressFillAnimation`, etc.) return `.linear(duration: 0)` / `nil` when enabled. Route movement (scale/offset/width/arc sweeps) through these.
- **View layer** — for continuous or structural motion (voice glow, border beam, pulsing indicators, staggered card slides, banner scale/offset) read `@Environment(\.accessibilityReduceMotion)` so the view re-evaluates when the setting is toggled mid-session. Prefer this over the static `AppAnimation.isReduceMotionEnabled` read, which does not invalidate a running animation.

**Opacity-only fades are NOT gated** — they aid comprehension and contain no movement, so they should survive Reduce Motion (`chartBannerFade`, `ContentRevealModifier`, banner opacity). Reduce Motion means *fewer and gentler* motion, not zero feedback.

### Ambient motion (continuous redraw)

A `TimelineView`-driven animation that never ends — the voice glow's 30 fps mesh, the border
beam's display-rate sweep — is *ambient*: decorative, information-free, and paying a render
cost every frame it is on screen. Those views go through
[`AmbientMotionGate`](../Sources/DesignTokens/AmbientMotionGate.swift), which suspends them under
Reduce Motion **and**, on iOS 27, while `systemPrefersReducedResourceUsage` is true (the system
asking apps to back off under thermal or power pressure).

The gate hands its content a `Bool`; render a **static frame** when it is false (`EdgeGlow`
freezes at `t = 0`) rather than removing the view, so nothing shifts in layout. Put new
`TimelineView` decoration behind this gate instead of reading `accessibilityReduceMotion`
directly — the iOS 27 signal then comes for free. (DesignKit compiles the iOS 27 branch only
with the iOS 27 SDK — Xcode 27; built with Xcode 26 the gate honours Reduce Motion alone.)

---

## 10. cardStyle Padding Contract

`cardStyle()` = **pure visual only** (shape + material, NO padding). Never rely on it for spacing.

### Who owns which padding

| Kind of component | Inner padding | Horizontal inset | Examples |
|---|---|---|---|
| **Card**: has its own surface | Its own: `.padding(AppSpacing.lg)` before `.cardStyle()`, inside the component | — | `TotalsCard`, `LimitProgressCard`, `ComparisonCard`, `CashFlowCard`, `ScoreCard`, `FinanceCard`, `EmptyCard`, `InsightsStatCard`, `SectionHeader(style: .card)` |
| **Compact surface** | Its own, smaller | — | `MessageBanner` (`md`), `ChartSelectionBanner` (`lg` × `sm`) |
| **Row**: no surface, lives in a container | Vertical only, from its `RowConfiguration` preset | The container's: a card's `.cardContentPadding()`, `List` / `Form` insets, or `.screenPadding()` | `InfoRow`, `AmountRow` (info style), `NetAmountRow`, `ScheduleRow` (`.info`, 8) |
| **List row**: lives only in a `List` | None: the `List`'s row insets give both | `List` | `AmountRow(style: .list)` |
| **Row in a `FormSection`** | Vertical and horizontal (`.standard`: 12 × 16), since `FormSection`'s surface has none | — | `MenuPickerRow`, `DatePickerRow` |
| **Primitive** | None: the parent places it | — | `Badge`, `TrendBadge`, `FormattedAmountText`, `LinearProgressBar`, charts |

Outer spacing is never a component's: the screen insets with `.screenPadding()` and spaces cards with its stack's `spacing`.

A stack of rows in a card: `spacing: 0` with `Divider()`s between rows, or `AppSpacing.sm` without dividers (Tenra's detail list cards). The rows' own vertical padding does the rest.

### Rows own their padding

`RowConfiguration` presets:

| Preset | V padding | H padding |
|--------|-----------|-----------|
| `.standard` | 12 | 16 |
| `.info` | 8 | 0 |
| `.selectable` | 12 | 16 |
| `.sheetList` | 12 | 16 |
| `.settings` | 4 | 0 |

### Arbitrary content

VStack, HStack, custom cards must add `.padding(AppSpacing.lg)` (or the equivalent `.cardContentPadding()` helper) explicitly before `.cardStyle()`. Both are 16pt — there is no separate "compact card" inset.

### Why H:0 for `.info` and `.settings`

- **`.info` H:0** — InfoRow always lives inside a container with `.padding(.lg)` — adding own H padding would double it to 32pt
- **`.settings` H:0** — `List` / `Form` apply `listRowInsets` (16pt leading/trailing) automatically — rows inside must NOT add H padding

### Dividers inside cards

`.padding(.leading, AppSpacing.lg)` (16pt) to align with row content start.

---

## 11. AnimatedInputComponents Deep Dive

`Sources/DesignComponents/Amounts/AnimatedInputComponents.swift` contains:

| Component | Purpose |
|-----------|---------|
| `BlinkingCursor` | Animated cursor for text inputs |
| `AmountDigitDisplay` | Animated amount display using single `Text` with `.numericText()` transition |
| `AmountInput` | Self-contained amount input (`AmountDigitDisplay` + hidden `TextField` + focus management) |
| `AmountInputView` | Thin wrapper around `AmountInput` + currency selector + conversion display + error |

### Visual Digit Grouping via `AttributedString.kern`

⚠️ **Critical for `.numericText()` animation correctness.**

Space characters in the string shift character positions on grouping change ("1 234" → "12 345"), causing **multiple digits to animate**.

`AttributedString.kern` is a styling attribute **invisible to `.numericText()`** — the string stays "12345" but renders as "12 345". Only the actual typed/deleted digit animates.

Used in both `AmountDigitDisplay` and `AmountInputView` conversion display.

### Font Sizing

Via `.minimumScaleFactor(0.3)` — handles long amounts gracefully without clipping.

### `AmountInput` Configuration

- `baseFontSize`
- `color`
- `placeholderColor`
- `autoFocus`
- `showContextMenu`
- `onAmountChange`

### `AnimatedTitleInput`

Uses `contentTransition(.interpolate)` — **intentionally different** from `AmountDigitDisplay`'s `.numericText()`. Don't unify.

---

## 12. Amount Formatting Files

Three separate files with distinct purposes:

| File | Purpose | Decimal places |
|------|---------|----------------|
| `Sources/DesignSupport/AmountFormatter.swift` | Stored values: format/parse/validate; `minimumFractionDigits=2` | Always 2 ("1 234.50") |
| `Sources/DesignSupport/AmountDisplayConfiguration.swift` | Global formatter config. **Hot path: `.formatter`** (cached). `makeNumberFormatter()` creates new object — never call in `List`/`ForEach` | Configurable (default 2) |
| `Sources/DesignSupport/AmountInputFormatting.swift` | Input component mechanics: `cleanAmountString`, `displayAmount(for:)`, `groupDigits()`, `formatLargeNumber()` | 0–2 (no trailing zeros) |

### Cache Invalidation

⚠️ **`AmountDisplayConfiguration` cache invalidation**:

```swift
static var shared = Config() { didSet { _cache = nil } }
```

Mutating `shared.prop = x` also triggers `didSet` (Swift copies struct and reassigns).

---

*Last Updated: 2026-05-05*

*DesignKit adaptation: 2026-09-30 (from Tenra `74a12c5`).*
