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
| `DesignTokens` | `AppColors` (grouped `Text` / `Background` / `Status` / `Border` since 1.6.0, `pale(_:)`, flat 1.x aliases), `CategoryColors`, `AppSpacing`, `AppRadius`, `AppIconSize`, `AppTypography`, `AppAnimation`, `AppModifiers` (`cardStyle`, `formCardStyle`, `filterChipStyle`, paddings, `chartAppear`, `staggeredEntrance`, inline field styles), `AppButton` (`primaryButton`, `secondaryButton`, `.bounce`), `AmbientMotionGate`, `DesignKitTheme`, `DesignKitFonts` (Inter) |
| `DesignSupport` | `IconSource`, `IconStyle`/`IconTint`, `IconView`, `BrandLogoView`, `Formatting`, `AmountFormatter`, `AmountDisplayConfiguration`, `AmountInputFormatting`, `ExpressionEvaluator`, `CurrencyInfo`, `HapticManager`, `DominantColorExtractor`, host hooks (`DesignKitLogoLoader`, `DesignKitCurrencyConverter`), `amountsHidden` (1.7.0), `matchedTransitionSourceIfPresent`, `swipeActionsContainerIfAvailable` |
| `DesignComponents` | everything in §3 not marked *app-side*, plus the chart family in §0.2 |

Coverage against Apple HIG, Material 3, Fluent 2, Carbon, Polaris and Atlassian, and the next
candidates: [benchmark.md](benchmark.md).

### 0.1 Host-app hooks

DesignKit ships no networking, persistence or FX. A host app wires these once, in `App.init()`:

| Hook | Default | Wire to |
|---|---|---|
| `DesignKitTheme.accent` | `.indigo` | Brand accent behind `AppColors.accent`. Also set the asset-catalog `AccentColor` to the same colour (system chrome never reads `AppColors`). |
| `DesignKitFonts.registerIfNeeded()` | — | Call once; registers the bundled Inter variable fonts. |
| `DesignKitLogoLoader.loader` | `nil` → fallback icon | Brand-logo images for `IconSource.brandService` (`BrandLogoView`, `IconView`, `heroAccentGlow`). |
| `DesignKitCurrencyConverter.convert` | `nil` → nothing rendered | FX for `ConvertedAmountView` / `HeroSection(showBaseConversion:)`. |
| Localization keys | raw key shown | Components resolve `String(localized:)` in the **host app's** main bundle. The full key list is in [localization-keys.md](localization-keys.md). |

### 0.2 Charts in DesignKit

**Trend charts (0.5.0)** over the generic `ChartPoint` / `ChartSeries` model: `LineChart`, `BarChart`, `ChartSwitcher`, `HeroSparkline`, `Sparkline`, `ChartSelectionBanner`, `ChartValuePoint`, `ChartValueFormat`. `OrbChart` (+ `DonutSlice`, `DonutSlice.foldingSlivers`, `DonutSlice.opacityStepped`), `MiniDonut`, `ProportionBar`, `LinearProgressBar`, `ProgressRing` (+ `LimitProgress`, 1.5.0), `AmountComparisonBar`, `MiniProportionBar` / `HeroProportionBar`, `MiniHalfGauge` / `HeroHalfGauge`, `MiniMilestoneGauge` / `HeroMilestoneGauge`, `MiniBarPair` / `HeroBarPair`, `HeroChartEffects` (`chartGlow`, `materialize`, `glassBar`), `ChartZoomControls` + `ChartStyle`, `SiriGlowView`, `SiriWaveRecordingView`. See [charts.md](charts.md).

**Removed in 1.0** (retired from Tenra 2026-07, deprecated in DesignKit until then): `BudgetProgressBar` → `LinearProgressBar`, `BudgetProgressCircle` → `ProgressRing`, `ExpenseIncomeProgressBar` → `AmountComparisonBar`, `DonutChart` + `ChartDisplayMode` → `OrbChart` / `MiniDonut`.

### 0.3 App-side (documented here, not in DesignKit)

These depend on app models/services. Port one only after replacing the dependency with a
generic input or a host hook (see [CLAUDE.md](../CLAUDE.md) → *Porting a component*).

- **Tenra models** (`Transaction`, `Account`, `CustomCategory`, `RecurringSeries`, loans, deposits): `TransactionCard`, `BudgetSettingsSection`, `EntityDetailScaffold`, `GroupedTransactionList`, `CategoryStyleHelper` / `CategoryStyleCache`, `TransactionDisplayHelper`, `CategoryDisplay`.
- **`PeriodDataPoint` adapters** (Tenra): `PeriodDataPoint: ChartPoint`, `PeriodChartSeries` → `ChartSeries`, and convenience inits keeping the old call sites (`granularity:`, `currency:`). `PeriodBreakdownRow` and `ChartAxisHelpers`' period labels stay app-side.
- **Tenra services**: `EditableHeroSection` + `IconPickerView` / `IconCatalog` (logo registry), `CurrencySelectorView` / `AmountInputView` (settings + FX), `DateFormatters`, `FastDateParser`.
- **Domain convenience inits / adapters**: `MenuPickerRow where T == RecurringFrequency / LoanType / ReminderOption`, `StatusIndicatorBadge`'s `RecurringSeries.entityStatus`, `DonutSlice.from([CategoryBreakdownItem])`, Tenra's `InsightTrendBadge` (`InsightTrend` → `TrendBadge`), Tenra's adapters under the old names of the components ported in 1.1.0–1.5.0 (`AccountRow` → `BalanceRow`, `CategoryRow` → `ProgressRingRow`, `CategoryChip` → `ProgressRingTile`, `BudgetProgressRow` → `LimitProgressCard`, …), Dalada's `RuleStatusBadge` (`RuleStatus` → `BadgeView`).

---

## 1. Design Tokens

All tokens live in `Sources/DesignTokens/`. Never use raw values — always reference the token.

### Colors (`AppColors`)

**Semantic colours v2 (1.6.0)**: tokens are grouped by what they colour and named *group / name / modifier* (`AppColors.Text.secondaryOnDark`, `AppColors.Status.warningPale`). Every token has a doc comment saying where it goes; the Gallery's Colors page shows them with their use.

Modifiers:
- **`OnDark` / `OnLight`**: the same value in both themes, for content on photos, gradients and coloured headers (a trip photo in Dalada, `GradientOrbsBackground`, an accent hero).
- **`Pale`**: a tinted container behind status text, badges and icons. `AppColors.pale(_:)` makes one from any colour (a category colour too): 12% in light, 24% in dark. Since 1.8.0 every tinted container in DesignKit uses it, so they are equally strong everywhere: `BadgeView` (tinted), `TrendBadge` (pill), `RecommendationBox`, `HeroSymbol`, `AvatarView` (initials), `ActivityTimeline` markers, the `ScoreGaugeCard` grade and `TargetProgressCard` badge, `HeroBarPair`'s amount pill, `MonthCalendar`'s today, `TagInput` chips and the calculator's operator keys. Progress tracks and chart fills are not containers and keep their own opacity.
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

**Flat names (1.x)** stay as aliases of the groups, with the same values: `bgBase` = `Background.base`, `bgCard` = `Background.neutral1`, `bgMuted` = `Background.neutral2`, `textPrimary` / `textSecondary` / `textTertiary` = `Text.*`, `destructive` = `Status.negative`, `success` = `Status.positive`, `warning` = `Status.warning`, `staticWhite` = `Text.primaryOnDark`, `planned` = `Status.info`. New code uses the groups; the components move over in later releases, where a move changes nothing visible or is called out.

| Token | Value | Use For |
|-------|-------|---------|
| `accent` | `DesignKitTheme.accent` (default `.indigo`) | Interactive elements, primary CTA tint. Per-app brand value — set `DesignKitTheme.accent` in `App.init()`. The host app's asset-catalog `AccentColor` must be the SAME colour — it drives system chrome (active tab tint, default buttons, search cursor). Keep the two in sync: an empty AccentColor silently falls back to system blue (Tenra shipped that until 2026-08-26). Tenra: system indigo (light 0x5856D6 / dark 0x5E5CE6). |
| `income` | RGB(0.13, 0.70, 0.37) | Income amounts (deliberately distinct from `success`) |
| `expense` | `.primary` | Expense amounts — deliberately NOT red (see comment in AppColors.swift) |
| `transfer` | Cyan-teal | Internal transfer amounts |
| `planned` | `.blue` (= `Status.info`) | Future/planned transactions |

For archived/inactive UI use `Color(.systemGray)` directly — there is no dedicated token.

**Category colors:** `CategoryColors.hexColor(for:opacity:)` — 14-color hex palette hashed by name. DesignKit has no custom-category override; Tenra keeps its `customCategories:` / store-backed overloads app-side. The slot is `CategoryColors.paletteIndex(for:)`, an FNV-1a hash of the name: the same on every launch and device (since 0.7.0; before that it used `String.hashValue`, which Swift seeds per process, so the colour changed between launches).

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

For full circles use `.infinity` inline (rare — only avatars/icon backgrounds use it). For values between tokens (8pt chips, 6pt compact corners) inline the numeric literal — no token.

### Icon Sizes (`AppIconSize`)

| Token | Value | Use For |
|-------|-------|---------|
| `sm` | 16 | Inline icons in text |
| `md` | 20 | Toolbar, list default |
| `lg` | 24 | Emphasized list icons, `UniversalRow` leading icons |
| `xl` | 32 | Bank logos in rows |
| `avatar` | 40 | Subscription icons in rows |
| `xxl` | 44 | Category circles (QuickAdd) |
| `xxxl` | 48 | Hero icons (empty states) |
| `categoryIcon` | 52 | Category row icons |
| `mega` | 64 | Category coins, large display icons |
| `budgetRing` | 72 | Budget ring (coin + 8pt stroke space) |
| `ultra` | 80 | Hero icons, large action buttons (voice input) |

### Container Sizes

There is no `AppSize` enum. Component-local sizes (cursor height/width, voice button diameter, CSV preview heights, etc.) live as numeric literals at use-site or as `private` constants in the component file. This is deliberate — global tokens are for 3+ shared use sites; everything else is local.

### Typography (`AppTypography`)

All use Inter variable font with Dynamic Type scaling:

| Token | Size | Weight | Use For |
|-------|------|--------|---------|
| `h1` | 34 | bold | Screen titles |
| `h2` | 28 | semibold | Detail view balances |
| `h3` | 24 | semibold | Section titles (Insights) |
| `h4` | 20 | semibold | Card headers, `EmptyStateView` titles |
| `bodyEmphasis` | 18 | semibold | Row names, button labels, section subheaders |
| `body` | 18 | regular | Default text |
| `bodySmall` | 16 | regular | Secondary text, subtitles |
| `caption` | 14 | regular | Timestamps, metadata, section headers |
| `caption2` | 12 | regular | Non-critical decorative text only |

For dynamic-size amount inputs use `Font.custom(AppTypography.fontFamily, …)` directly — that's the one place the family name is exposed.

**Numbers (1.8.0).** `AppTypography.numbers(_:)` is any of the styles above with tabular figures (every digit equally wide): amounts in a column line up and a number that changes (`.numericText()`) keeps its width. `FormattedAmountText`, `AmountDigitDisplay` (the amount input), `TrendBadge` percentages, `ChartSelectionBanner` readouts and the chart legend and pill amounts use it; `StatTile`, `CalculationCard` and `AvatarGroup` already used `.monospacedDigit()`. Use it for any other figure that changes or stacks: `Text(count, format: .number).font(AppTypography.numbers(AppTypography.h3))`.

**Accessibility text sizes (AX1–AX5).** Side-by-side layouts stack when `dynamicTypeSize.isAccessibilitySize` (Apple's HIG rule): a row of columns or a "title …… value" row does not truncate values or break words mid-word, it puts them one under another. Standard sizes keep the side-by-side layout untouched — branch on `isAccessibilitySize`, don't rework the regular layout. Since 1.3.0: `ComparisonCard` (before, now, change), `TotalsCard` (one total per line), `InsightEntityRow` and `BreakdownRow` (the amount under the title), `MenuPickerRow` (the value under the title); since 1.5.1 `BalanceRow` (a detail's amount under its text) and `ProgressRingRow` (spent, "/ limit" and the share on three lines). Snapshot tests check AX2 (`largeText`).

### Animations (`AppAnimation`)

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
| `.borderBeam(isActive:colors:cornerRadius:lineWidth:duration:)` | Animated glowing beam traveling around the border via rotating `AngularGradient`. Two-layer (sharp + blurred glow). `TimelineView`-driven; ticks only while `isActive == true`. Reduce-Motion aware | Highlighting cards during transient active states (voice recognition preview, focus, processing). Match `cornerRadius` to the underlying card |

**`.fadeTruncation(fadeLength:)`** *(1.7.0)*: one line that fades out over 24 pt at its trailing edge instead of ending in "…", only when it does not fit. For names in carousels and tiles. RTL-aware.

### Button Styles (`AppButton`)

| Style | Visual | Usage |
|-------|--------|-------|
| `.primaryButton(disabled:)` | `.glassProminent` + `.tint(AppColors.accent)` + `.controlSize(.large)` | Primary CTA. Sizing follows label — wrap with `.frame(maxWidth: .infinity)` for full-width |
| `.secondaryButton()` | `.glass` + `.controlSize(.large)` | Cancel, Back, secondary actions |
| `.buttonStyle(.bounce)` | Scale 0.96 on press | Interactive card taps (non-glass) |
| `.appButton(_:role:size:disabled:)` *(1.7.0)* | appearance `.primary` (`.glassProminent`) / `.secondary` (`.glass`) / `.flat` (`.borderless`) × role `.normal` (accent; none on secondary) / `.destructive` (`Status.negative`) / `.neutral` (`Text.primary`) × size `.large` / `.medium` / `.small` (control sizes) | The full matrix. `.appButton()` = `.primaryButton()`, `.appButton(.secondary)` = `.secondaryButton()`. Loading: `LoadingButtonLabel` in the label + `disabled: isLoading` |

⚠️ **For destructive buttons, do NOT use `.primaryButton()`** — it forces `.tint(AppColors.accent)` which silently overrides `role: .destructive` (button looks accent-colored instead of red). Since 1.7.0 use `.appButton(role: .destructive)`; before it, the native styles directly: `.buttonStyle(.glassProminent).tint(AppColors.destructive).controlSize(.large)` with `Button(role: .destructive, ...)`. See [BulkDeleteButton.swift](../Sources/DesignComponents/Input/BulkDeleteButton.swift) and [EntityActionButton.swift](../Sources/DesignComponents/Input/EntityActionButton.swift).

**Group adjacent glass elements in `GlassEffectContainer`** (glass can't sample other glass → inconsistent rendering otherwise). Use it for rows of `.glass`/`.glassProminent` buttons or clusters of `.glassEffect()` views; set its `spacing:` to match the stack spacing. Used ungated in app code (app target = iOS 26). Precedents: `EntityDetailScaffold` action bar, `DateButtonsView`, `ChartZoomControls`. Leaf components that still support pre-iOS-26 (`CategoryChip`, `SegmentedPickerView`) gate glass with `#available(iOS 26)` + `.ultraThinMaterial` fallback.

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

#### `EditableHeroSection` *(app-side, Tenra)*
**Purpose:** Animated hero section for entity edit views.

```swift
EditableHeroSection(
    iconSource: $iconSource,
    title: $name,
    balance: $balance,        // only if config.showBalance
    currency: $currency,      // only if config.showCurrency
    selectedColor: $colorHex, // only if config.showColorPicker
    titlePlaceholder: "Name",
    config: .accountHero
)
```

| Preset | Shows |
|--------|-------|
| `.accountHero` | Balance + Currency |
| `.categoryHero` | Color picker |
| `.subscriptionHero` | Balance + Currency |

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
| **Leading icon — content rows** | `AppIconSize.xxl` (44) | BalanceRow, ProgressRingRow, BreakdownRow, InsightEntityRow, LimitProgressCard |
| **Leading icon — form rows** | `AppIconSize.lg` (24) | InfoRow, MenuPickerRow, DatePickerRow |
| **Leading icon — settings rows** | `AppIconSize.md` (20) | ActionSettingsRow, NavigationSettingsRow |
| **HStack spacing (icon ↔ content)** | `AppSpacing.md` (12) | All rows |
| **Inner VStack (title ↔ subtitle)** | `AppSpacing.xs` (4) | Never `xxs` |
| **Title — management lists** | `AppTypography.h4` (20 semibold) | BalanceRow, ProgressRingRow (larger touch lists) |
| **Title — detail / breakdown rows** | `AppTypography.body` (18) or `bodyEmphasis` (18 semibold) | Insights detail rows. Use the `bodyEmphasis` **token** — never `body` + `.fontWeight(.semibold)` |
| **Subtitle / secondary line** | `AppTypography.bodySmall` (16) / `AppColors.textSecondary` | One token for all secondary subtitles |
| **Trailing amount** | `FormattedAmountText` (default body/semibold) | Never hand-format money |
| **Horizontal inset** | per-row `.screenPadding()` | Rows declare `hPad 0` (UniversalRow `.info`) and own their inset at the call site, so the full width — incl. padding — is tappable inside `NavigationLink`. Lists do NOT wrap the whole `VStack` (would double-pad self-padding `SectionHeaderView(.large)`) |
| **Navigation chevron (outside `List`)** | `DisclosureChevron` | `chevron.forward` (RTL-aware) + tertiary. Never hand-roll `chevron.right` |

**Shared row sub-components:** `AmountPercentageView` (amount + %), `SpentBudgetText` (spent / budget), `DisclosureChevron`, `NetAmountRow`, `LimitProgressCard`. Reuse before building a new row.

#### `InfoRow`
Read-only label + value. Wrapper for `UniversalRow(config: .info)`.

```swift
InfoRow(icon: "calendar", label: "Next Payment", value: "March 15, 2026")
```

Use in: detail views for metadata display. NOT for editable fields.

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

#### `BreakdownRow` *(1.2.0)*
One part of a breakdown on `UniversalRow(.info)`: a 44 pt circle icon tinted with `color`, the title and an optional one-line subtitle, `AmountPercentageView` (the amount over "42.0%") and, with `showsChevron: true`, a `DisclosureChevron` (wrap the row in a `NavigationLink`). `AmountPercentageView` is public for other rows. Tenra: `CategoryBreakdownRow` (category name, subcategories) is an adapter.

#### `BalanceRow` *(1.5.0)*
A named balance in a `List`: `IconView` (44 pt, the zoom-transition source with `transitionSourceID` / `transitionNamespace`), the name (h4), the amount (bodySmall, secondary), an optional `Detail` caption line ("Posting: 30 Oct  ·  " followed by an amount in `AppColors.planned`) and an optional secondary `trailingSystemImage` (a lock). At accessibility text sizes the detail's amount goes under its text, which drops a trailing "·". No padding: the list's row insets place it; the tap (`Button` + `.plain`) and `.swipeActions` stay at the call site. Tenra: `AccountRow` (account, deposit interest copy, delete) is an adapter.

#### `ProgressRingRow` *(1.5.0)*
A row whose icon wears a progress ring: a 44 pt circle icon tinted with `color` inside a 3 pt `ProgressRing` (`LimitProgress`; no ring when `nil`), the name (h4), then `SpentBudgetText` (semibold, destructive when over) and "(74%)", or `placeholder` ("No budget set") without a limit; at accessibility text sizes the spent amount, "/ limit" and the share go on three lines. A `List` row like `BalanceRow`: no padding, tap and swipe at the call site. Tenra: `CategoryRow` (category, budget, the over-budget haptic) is an adapter.

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

Use in: subscription/deposit/loan form sections. NOT for transaction dates (use `DateButtonsView`).

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
    PackedCircleIconsView(items: ...)
}
```

- **`RedactableAmount`** — hero amount that shows a redacted placeholder while an async (FX) total computes, then cross-fades. Use for cards whose total needs conversion (accounts, deposits, subscriptions).
- Don't reintroduce the inline `HStack(.top, md) → VStack(.leading, lg) → title → if isEmpty …` shell in a new finance card — wrap `FinanceCard`.

#### `RecommendationBox`
Tinted "lightbulb + advice" callout (icon + text on `color.opacity(0.10)`, `AppRadius.md`). Shared by `CalculationCard` and `TargetProgressCard`. Use for any card-bottom recommendation line.

#### `EmptyCardView`
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
Money in against money out: the title (h3), `AmountComparisonBar` and an optional extra line (`Totals.extra`, e.g. "Planned"). `isEmpty` shows `EmptyCardView` with the same title; `totals == nil` shows a skeleton in the card's shape (`loadingLabel` for VoiceOver, key `skeleton.loading` by default). The three states cross-fade with `AppAnimation.gentleSpring`. Tenra: `TransactionsSummaryCard` (home screen) is an adapter.

#### `ScoreGaugeCard` *(1.2.0)*
A score as a hero: `HeroHalfGauge` (220 pt, 16 pt line, `zoneTicks`) with the score (h1 bold) and a grade capsule inside, both with `materialize`, and a centred subtitle below. `score == nil` leaves the gauge empty and shows "—". Tenra: `HealthScoreHeroCard` (grade colour, grade-band copy) is an adapter.

#### `ScoreCard` *(1.2.0)*
A score in the insight feed: title, grade and "72 / 100" on the left, a 120 pt `MiniHalfGauge` on the trailing edge (the same footprint as the feed cards' mini charts). Tenra: `HealthScoreCardView` is an adapter.

#### `TargetProgressCard` *(1.2.0)*
One metric against a target: icon, title and a grey capsule badge ("Weight 30%"), a summary line, "Current" (h2 bold) next to "Target", a `LinearProgressBar` (red below a third, amber below two thirds, green above, unless `progressColor` is set), an explanation and a `RecommendationBox`. `isMuted` dims the card to 60%. Tenra: `HealthComponentCard` (the health-score parts) is an adapter.

#### `RecurringPaymentCard` *(1.2.0)*
A recurring payment: `IconView` (44 pt), the name, the amount, the amount in `baseCurrency` when it differs (`ConvertedAmountView`, so the host's `DesignKitCurrencyConverter`), a caption ("Next charge on 12 Oct") and a `StatusIndicatorBadge`. Tenra: `SubscriptionCard` (recurring series, next-charge date) is an adapter.

#### `PayoffProgressCard` *(1.2.0)*
Something being paid off: icon, name (h4) and subtitle with an `accessory` view on the right (a type badge), "left ……… total" over an income-tinted `ProgressView`, and a footer: `.inProgress(nextDate:remainingCaption:)` (calendar mark + date, "18 left") or `.done(caption:)` (check mark + "Closed 15 Jun 2026"). Tenra: `LoanCard` is an adapter; its `LoanTypeBadge` stays in Tenra and goes in the accessory.

#### `BalanceCard` *(1.5.0)*
A named balance sized for a carousel: `IconView` (44 pt), the name (h4) and the amount (bodySmall semibold), `AppSpacing.sm` apart, padded `lg` on `cardStyle`. Navigation, `glassEffectID` and `matchedTransitionSource` go on it at the call site. Tenra: `AccountCard` (accounts carousel) is an adapter.

#### `MetricCard` *(1.5.0)*
One metric in a feed: a one-line title (secondary), a statement of up to three lines (bodyEmphasis), the value (`.amount` through `FormattedAmountText` or pre-formatted `.text`, h2 bold) with an optional unit and a `TrendBadge(.pill)` that drops under the value when both do not fit (`ViewThatFits`). An optional chart: `.trailing` overlays it at 120 × 120 pt on the trailing edge and the text keeps 128 pt clear; `.bottom` puts it full width under the text. Without a chart the text takes the full width. `Value`, `Trend` and `ChartPlacement` are typealiases of the top-level `MetricCardValue`, `MetricCardTrend` and `MetricCardChartPlacement`, so one value can feed cards with different charts. `ScoreCard` shares the mini-chart footprint. Tenra: `InsightsCardView` (the insight model and which mini chart each insight gets) is an adapter.

---

### Icon Components

#### `IconView`
**The single rendering engine for all entity icons.**

```swift
// Auto-style (convenience)
IconView(source: .sfSymbol("star.fill"), size: AppIconSize.xl)

// Explicit style
IconView(source: .bankLogo(.kaspi), style: .bankLogo(size: AppIconSize.xl))
```

**When to use `IconView`:** Entity/category icons with styled backgrounds — accounts, categories, subscriptions, brand logos.

**When to use `Image(systemName:)` directly:** Semantic UI indicators — chevron, checkmark, xmark, toolbar actions, inline arrows.

**Accessibility:** `IconView.body` has `accessibilityHidden(true)` — it is always decorative within its parent row/card. The parent element owns the accessibility label. Do not override this unless `IconView` is the sole content of an interactive element with no other text.

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

#### `DateButtonsView`
Yesterday / Today / Calendar picker for transaction forms.

```swift
// As safe-area bottom bar:
.dateButtonsSafeArea(selectedDate: $date, onSave: { saveDate($0) })
```

Use for: transaction entry/edit forms only. For other date fields use `DatePickerRow`.

#### `CurrencySelectorView` *(app-side, Tenra)*
Currency symbol menu button styled as filter chip.

```swift
CurrencySelectorView(selectedCurrency: $currency, availableCurrencies: ["KZT", "USD", "EUR"])
```

Use in: `EditableHeroSection` (automatic when `config.showCurrency`). Not standalone.

---

#### `ChipPicker` *(0.4.0)*
One or none from a horizontally scrolling row of chips; tapping the selected chip clears it.

```swift
ChipPicker("Weather", options: Weather.allCases, selection: $draft.weather) { $0.title }
```

Chips use `filterChipStyle(isSelected:)`. A fixed 2–4 way switch → `SegmentedPickerView`; a
filter that opens a menu → `UniversalFilterButton`.

Several at once (0.6.0): pass a `Binding<Set<Option>>`; optional `systemImage:` per chip.

```swift
ChipPicker(options: PlaceType.allCases, selection: $types, systemImage: { $0.systemImage }) { $0.title }
```

#### `LoadingButtonLabel` *(0.6.0)*
Button label that swaps its title for a spinner while an action runs, keeping the width.

```swift
Button { Task { await save() } } label: {
    LoadingButtonLabel("Save", isLoading: isSaving).frame(maxWidth: .infinity)
}
.primaryButton(disabled: isSaving)
```

#### `ToggleSettingsRow` *(0.6.0)*
The settings row with a switch, next to `NavigationSettingsRow` and `ActionSettingsRow`.

```swift
ToggleSettingsRow(icon: "bell", title: "Reminders", isOn: $remindersOn)
ToggleSettingsRow(icon: "location", title: "Share location", hint: "Friends see your trip", isOn: $shares)
```

VoiceOver focuses the switch (title as label, `hint` as hint).

#### `SelectionIndicator(isSelected:tint:)`
Check circle for multi-select and checklist rows; the row carries the label and the
`.isSelected` trait. `tint` (0.4.0, default accent) colours the filled check: `AppColors.success`
for a done checklist item, `textTertiary` for one that is already owned and disabled.

#### `SelectableBalanceCard` *(1.5.0)*
One option of a "pick a balance" list: a full-width card with `IconView` (44 pt), the name (body, secondary) and the amount (body semibold), outlined in `AppColors.accent` (2 pt, `gentleSpring`) when `isSelected`, `.bounce` on press, `.isSelected` trait. Tenra: `AccountRadioButton` (balance from its store) is an adapter.

#### `ProgressRingTile` *(1.5.0)*
A picker-grid tile: the name (bodyEmphasis, one line) over a 64 pt Liquid Glass circle with the symbol (h2) in `color`, the glass tinted with `color` at 30% when `isSelected`, and an optional 4 pt `ProgressRing` (72 pt) around it. As tall with a ring as without, so grid rows line up. VoiceOver label and hint at the call site. Tenra: `CategoryChip` (category style lookup) is an adapter.

### Feedback & Status Components

#### `StatusBanner` *(1.7.0)*
A notice that stays in the layout, built like `RecommendationBox` (icon, wrapping text, a tinted `AppRadius.md` box) and coloured by status: `status:` `.info` / `.positive` / `.negative` / `.warning` / `.neutral` (icon and `AppColors.Status.*Pale` box), `style:` `.standard` (bodySmall, on a screen) or `.compact` (caption, inside a card). With an `action` it is a `.bounce` button with a `DisclosureChevron`. VoiceOver reads it as one element. For a message that comes and goes use `MessageBanner`; for one line under a field, `InlineStatusText`.

```swift
StatusBanner("Card expires on 30 Nov", status: .warning)
StatusBanner("Statement is ready", status: .info) { showStatement() }
```

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

#### `SkeletonText` *(1.7.0)*
A text-line placeholder in a given style: `SkeletonText(AppTypography.h4, width: 140)`, `SkeletonText(AppTypography.bodySmall, lines: 2)` (the last of several lines is 60% wide). The line is as tall as the style's own line, so it grows with Dynamic Type; the bar is 70% of it. Shimmers like `SkeletonView`. A whole component as its own placeholder stays `.skeleton(isLoading:)`, which redacts every text and image in place.

#### `SkeletonView` / `SkeletonRow` / `.skeleton(isLoading:)` *(0.6.0)*
Loading placeholders instead of a spinner: grey shapes in the layout of the content that is
coming, with a slow shimmer (static under Reduce Motion, via `AmbientMotionGate`).

```swift
if isLoading { ForEach(0..<5) { _ in SkeletonRow() } }          // list rows
SkeletonView(height: 160)                                       // an image
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

#### `PermissionPrimerView` *(0.7.0)*
Our explanation before a system permission alert (HIG "Requesting permission"): `HeroSymbol`,
title, message, Allow and Not now. Shared by both apps; fits a `.medium` sheet.

```swift
PermissionPrimerView(
    systemImage: "bell.badge",
    title: String(localized: "push.primer.title"), message: String(localized: "push.primer.body"),
    allowTitle: String(localized: "push.primer.allow"), laterTitle: String(localized: "push.primer.later"),
    onAllow: { await requestPermission(); isPresented = false },
    onLater: { isPresented = false }
)
.presentationDetents([.medium])
```

It does not dismiss itself. While `onAllow` runs the Allow button shows a spinner. Show it at
the moment of first use (first check-in, first subscription), not at launch.
`NotificationPermissionView` is the same view with Tenra's `notification.permission.*` texts
that dismisses itself (since 0.7.0 it has this layout: symbol on a disc, glass buttons).

#### `OnboardingPager` / `OnboardingPage` *(0.7.0)*
First-launch introduction: swipeable pages with dots, Skip at the top, the page's buttons at
the bottom. The app owns the pages enum and `selection`.

```swift
OnboardingPager(pages: Intro.allCases, selection: $page,
                canSkip: { $0 != .location }, onSkip: finish) { page in
    OnboardingPage(systemImage: page.symbol, title: page.title, message: page.text)
} actions: { page in
    Button { next() } label: { Text("Next").frame(maxWidth: .infinity) }.primaryButton()
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

#### `BadgeView` *(0.4.0)*
Capsule with short text and an optional SF Symbol: a status, a tag or a counter.

```swift
BadgeView("Seasonal ban", color: AppColors.destructive)                       // .tinted: text on a 12 % tint
BadgeView("3", systemImage: "person.badge.plus", color: AppColors.destructive, style: .filled)
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

#### `EmptyStateView`
Empty/error state display.

```swift
EmptyStateView(
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

#### `PromptSheet` *(1.5.0)*
A short question in a small sheet: a 44 pt symbol in the accent colour, the title and message centred, a filled accent primary button and a plain secondary one; either answer runs its closure and closes the sheet. Sets its own detent (`height`, 340 pt) and drag indicator. Type: title `h3`, message `bodySmall`, buttons `bodyEmphasis` (Tenra's sheet used system fonts until 1.5.0). Tenra: `RatingSurveyView` (rating service, feedback e-mail) is an adapter.

---

### Display Components

#### `FormattedAmountText`
Currency amount with smart decimal hiding and numeric transition.

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

**Hidden amounts (1.7.0).** `.amountsHidden(_:)` (DesignSupport; environment `amountsHidden`) hides every `FormattedAmountText` below it, and so every card, row and badge built on it: "•••• ₸" (the number and sign go, the unit stays), VoiceOver reads "Hidden amount" (`amount.hidden`). Since 1.8.0 also the legend amounts of `HeroProportionBar` and the tap pill of `HeroBarPair`. Amount inputs and chart axes are not hidden. An amount the app writes into its own text reads the environment value and shows `Formatting.hiddenAmount(currency:)` ("•••• ₸"):

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

#### `SectionHeaderView`
Section header text with four styles.

```swift
SectionHeaderView("Transactions", style: .default)       // bodyEmphasis
SectionHeaderView("March 10", style: .emphasized)         // bodySmall semibold
SectionHeaderView("SETTINGS", style: .compact)            // caption uppercase
SectionHeaderView("Spending", systemImage: "chart.bar", style: .insights) // h3 + icon
```

#### `DateSectionHeaderView`
Transaction list date group header with optional daily total.

```swift
DateSectionHeaderView(dateKey: "2026-03-10", amount: 45000.0, currency: "KZT")
```

#### `ProgressRing`
Circular progress arc for budget consumption.

```swift
ProgressRing(progress: 0.75, size: AppIconSize.categoryIcon, isOverBudget: false)
```

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

#### `AvatarView` *(0.4.0)*
Round avatar: the photo when there is one, otherwise initials on a 15 % tint.

```swift
AvatarView(name: profile.displayName ?? profile.username)          // AppIconSize.avatar (40)
AvatarView(name: "Ayan Seitkali", size: 64)                         // h3 initials above 48 pt
AvatarView(name: name, image: Image(uiImage: photo))
```

Decorative for VoiceOver: put the name in the row next to it. Several faces in a cluster →
`PackedCircleIconsView`.

#### `AvatarGroup` *(0.6.0)*
Overlapping avatars with "+N" for the rest; each has a ring in the background colour.

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
    IconView(source: sub.iconSource, size: AppIconSize.md)
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

#### `FlowLayout` *(0.7.0)*
A `Layout` that wraps subviews to new lines like words: tags, badges, chips that should not
scroll. `FlowLayout(spacing:lineSpacing:) { ForEach(tags, id: \.self) { BadgeView($0) } }`.

#### `HeroSymbol` *(0.7.0)*
Large SF Symbol on a disc of its tint at 12%: the picture of `OnboardingPage` and
`PermissionPrimerView`. `HeroSymbol(systemImage: "map", size: 96, tint: AppColors.success)`.
Decorative (hidden from VoiceOver).

#### `RatingView` / `RatingPicker` *(0.4.0)*
Star rating. `RatingView` displays with half stars (filled from .75, half from .25 of a star);
`RatingPicker` is the tap-to-rate input (whole stars, haptic on tap).

```swift
RatingView(rating: summary.average, size: 12)
RatingPicker(rating: $draft.rating)
```

Default colour `AppColors.warning`, maximum 5. VoiceOver keys: `rating.value`, `rating.pick`
([localization-keys.md](localization-keys.md)).

#### `GradientOrbsBackground` *(1.5.0)*
Up to three soft, heavily blurred colour orbs (`Orb(color:weight:)`, heaviest first) at fixed positions; weight sets an orb's size and brightness, the first two blur deeper (44) than the third (28), blended `.screen` and rasterised once (`drawingGroup`). Static by design (animating it was the home screen's main jank). Put it behind a glass card, clipped to the card's shape; never inside `List` / `ForEach`. Tenra: `CategoryGradientBackground` (top expense categories → colours) is an adapter.

---

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
    IconView(source: item.iconSource, style: iconStyle)
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
    │   └── IconView(.glassHero) + Title + Balance
    ├── Card 2: Info (.cardStyle())
    │   └── InfoRow list
    ├── Card 3: Stats (.cardStyle())
    │   └── InfoRow / custom rows
    ├── Actions Section
    │   ├── Button { }.primaryButton()
    │   └── Button { }.secondaryButton()
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
            DateSectionHeaderView(dateKey: section.dateKey, amount: total, currency: cur)
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
└── Single-line form field → FormTextField(style: .standard)

Date input?
├── Transaction (needs Yesterday/Today shortcuts) → DateButtonsView / .dateButtonsSafeArea()
└── Other (subscription start, deposit posting) → DatePickerRow

Single-select picker?
├── Few options (2-5) in form → MenuPickerRow
├── 2-4 exclusive modes → SegmentedPickerView
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
└── BalanceRow (custom, NOT UniversalRow)

Row with a limit (budget ring around the icon)?
└── ProgressRingRow (custom, NOT UniversalRow)
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
└── IconView(source:style:)
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
└── EmptyStateView
    ├── Full screen → .standard
    ├── Inside card → .compact
    └── Error/failure → .error

Asking for a permission (notifications, location, camera)?
└── PermissionPrimerView first, then the system alert from onAllow
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
    EmptyStateView(...).transition(.opacity)
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

The gate hands its content a `Bool`; render a **static frame** when it is false (`SiriGlowView`
freezes the mesh at `t = 0`) rather than removing the view, so nothing shifts in layout. Put new
`TimelineView` decoration behind this gate instead of reading `accessibilityReduceMotion`
directly — the iOS 27 signal then comes for free. (DesignKit compiles the iOS 27 branch only
with the iOS 27 SDK — Xcode 27; built with Xcode 26 the gate honours Reduce Motion alone.)

---

## 10. cardStyle Padding Contract

`cardStyle()` = **pure visual only** (shape + material, NO padding). Never rely on it for spacing.

### Who owns which padding

| Kind of component | Inner padding | Horizontal inset | Examples |
|---|---|---|---|
| **Card**: has its own surface | Its own: `.padding(AppSpacing.lg)` before `.cardStyle()`, inside the component | — | `TotalsCard`, `LimitProgressCard`, `ComparisonCard`, `CashFlowCard`, `ScoreCard`, `FinanceCard`, `EmptyCardView`, `InsightsStatCard`, `DateSectionHeaderView` |
| **Compact surface** | Its own, smaller | — | `MessageBanner` (`md`), `ChartSelectionBanner` (`lg` × `sm`) |
| **Row**: no surface, lives in a container | Vertical only, from its `RowConfiguration` preset | The container's: a card's `.cardContentPadding()`, `List` / `Form` insets, or `.screenPadding()` | `InfoRow`, `InsightEntityRow`, `BreakdownRow`, `NetAmountRow`, `ScheduleRow` (`.info`, 8) |
| **List row**: lives only in a `List` | None: the `List`'s row insets give both | `List` | `BalanceRow`, `ProgressRingRow` |
| **Row in a `FormSection`** | Vertical and horizontal (`.standard`: 12 × 16), since `FormSection`'s surface has none | — | `MenuPickerRow`, `DatePickerRow` |
| **Primitive** | None: the parent places it | — | `BadgeView`, `TrendBadge`, `FormattedAmountText`, `LinearProgressBar`, charts |

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

`Sources/DesignComponents/Input/AnimatedInputComponents.swift` contains:

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
