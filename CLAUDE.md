# DesignKit — Project Guide for Claude

SwiftUI design system shared by **Tenra** (personal finance, the reference implementation) and
**Dalada** (outdoor trips). One package, three layered targets, a Gallery app, no app logic.

## Quick Start

```bash
# Build the package (no Xcode project needed — xcodebuild reads Package.swift).
# Scheme: DesignKit-Package or DesignKit — `xcodebuild -list` shows which.
xcodebuild build -scheme DesignKit-Package -destination 'generic/platform=iOS Simulator' -quiet

# Gallery (showcase app). The .xcodeproj is generated from Gallery/project.yml:
cd Gallery && xcodegen generate
xcodebuild build -project Gallery.xcodeproj -scheme Gallery \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -quiet
```

Code is often written in a Linux container where SwiftUI cannot compile. **CI is the compiler
there**: `.github/workflows/ci.yml` builds the package, the Gallery, and **Dalada against this
checkout** on macOS for every push to `main` and `claude/**`. Push, then read the job logs.

## Package Layout

```
Sources/
├── DesignTokens/      leaf — colors, spacing, radius, icon sizes, typography (Inter), animation,
│                      modifiers, button styles, AmbientMotionGate, DesignKitTheme, fonts
├── DesignSupport/     → DesignTokens — icons (IconSource/IconStyle/IconView/BrandLogoView),
│                      formatting, haptics, DominantColorExtractor, host hooks
└── DesignComponents/  → DesignTokens + DesignSupport — Cards, Charts, Feedback, Forms,
                       Headers, Icons, Input, Rows
Gallery/               showcase app (xcodegen); every public component has a specimen
docs/                  design-system.md, charts.md, gotchas.md, localization-keys.md
```

Dependencies only point down the list. One product, `DesignKit`, exports all three modules;
consumers `import DesignTokens` / `DesignSupport` / `DesignComponents` as needed.

## Consumers

| App | How it depends | Notes |
|---|---|---|
| Dalada | `ios/Packages/DaladaKit/Package.swift`, pinned by `revision:` (→ version tags from 0.2.0) | Swift 6, iOS 26, Xcode 26 in CI; uses tokens, `cardStyle`, buttons, `EmptyStateView`, `SectionHeaderView`, `RecommendationBox`, `PlusTabLabel` |
| Tenra | not wired yet — keeps its own copy of the design system in `Tenra/Utils` + `Tenra/Views/Components` | Reference implementation. Migration to this package is planned; until then DesignKit is synced FROM Tenra (see *Sync log*) |

A consumer only sees a DesignKit change when it bumps its pin. CI's `dalada` job builds Dalada
against the current checkout, so a change that would break Dalada fails here first.

## Source of Truth & Sync

- **Now:** Tenra's design system is the reference. DesignKit is updated by syncing from Tenra:
  three-way merge per file (base = the Tenra commit of the previous sync, theirs = Tenra `main`,
  ours = DesignKit), keeping DesignKit's `public` API and parameterization. Record every sync
  below.
- **After Tenra consumes DesignKit:** DesignKit is the only place design-system code lives. Apps
  add or change components by PR here (develop with Xcode's local package override: drag the
  local DesignKit folder into the app's project), CI builds every consumer, merge → tag →
  consumers bump.

### Sync log

| Date | Tenra commit | Notes |
|---|---|---|
| 2026-06-10 | `4392be3` (2026-06-04) | v0 extraction |
| 2026-09-30 | `74a12c5` (2026-09-26) | 20 changed files merged; 36 new files (components, charts, helpers); 5 retired components deprecated; docs ported |

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

Host hooks (set once in `App.init()`): `DesignKitTheme.accent`, `DesignKitFonts.registerIfNeeded()`,
`DesignKitLogoLoader.loader`, `DesignKitCurrencyConverter.convert`. Add a new hook (same shape:
a `public static var` closure/value in `DesignSupport` or `DesignTokens`, documented default)
rather than importing an app type.

## Porting a Component (checklist)

1. Copy the file into the matching `Sources/DesignComponents/<Group>/` folder; drop `#Preview`
   blocks (the Gallery replaces them) and add `import DesignTokens` / `import DesignSupport`.
2. `public` on the type, `body`, nested types used in the API, and protocol requirements
   (`id`, `body(content:)`, `==`). Write an explicit `public init` — memberwise inits are internal.
3. Replace app dependencies per the decision tree above. Leave a one-line comment naming what
   stayed in the app.
4. Add a Gallery specimen (existing screen file, or a new one + `xcodegen generate`).
5. Add any new `String(localized:)` key to `docs/localization-keys.md`.
6. Update `docs/design-system.md` (§0 inventory + the component's section).
7. Push; CI must be green on the package, Gallery and Dalada jobs.

## API Stability & Versioning

- Semantic versioning with git tags (`0.2.0`, …). Consumers pin a version (`exact:` or
  `.upToNextMinor(from:)`), never a branch.
- **Never remove or rename public API in a minor release.** Deprecate with
  `@available(*, deprecated, message: "… Use X.")` naming the replacement; remove only in the
  next major, once no consumer uses it. Tenra retiring a component is not a reason to delete it
  here.
- Visual changes to shared components land in every consumer on its next bump — call them out in
  the release notes.

## Toolchains & Language

- iOS 26+, Swift 5 language mode (`swiftLanguageModes: [.v5]`), no default MainActor isolation.
- Must compile with **Xcode 26 and Xcode 27**: iOS 27 SDK APIs go behind
  `#if compiler(>=6.4)` **and** `#available(iOS 27, *)`.
- Tokens that nonisolated app code reads are `nonisolated`.

## Known Gaps / Follow-ups

- `PeriodDataPoint` chart family (`LineChart`, `BarChart`, `ChartSwitcher`, `MiniSparkline`,
  `HeroSparkline`, `ChartSelectionBanner`, period helpers) is not ported — needs a generic series
  model. The `InsightsStatCard` trend sparkline waits on it.
- `EditableHeroSection`, `IconPickerView`/`IconCatalog`, `CurrencySelectorView`,
  `AmountInputView` depend on Tenra services (logo registry, settings, FX).
- `CategoryColors.hexColor(for:)` hashes with `String.hashValue`, which is seeded per process —
  fallback colours are not stable across launches (inherited from Tenra).

## Reference Docs

| Working on… | Read first |
|---|---|
| Tokens, modifiers, any component, amount formatting, animation rules | [docs/design-system.md](docs/design-system.md) |
| Charts, progress, gauges, OrbChart, Swift Charts patterns | [docs/charts.md](docs/charts.md) |
| Package traps (public API, Xcode 26/27, bundles) and SwiftUI layout traps | [docs/gotchas.md](docs/gotchas.md) |
| Localized strings used by components | [docs/localization-keys.md](docs/localization-keys.md) |
