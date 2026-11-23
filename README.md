# DesignKit

A reusable SwiftUI design system extracted from the **Tenra** iOS app and shared with
**Dalada**. Tokens, components and motion rules are Tenra's (the reference implementation);
this package makes them versioned and reusable.

> Status: **8.x.** Both apps consume the package (Tenra since 0.3.0) and pick up new releases
> automatically; design-system changes are made here. A third app, Platina, is in development;
> 8.12.0's grey surfaces instead of Liquid Glass (`DesignKitTheme.surface = .fill`) are for it. What each version added and changed, and
> how to move an app to it: [CHANGELOG.md](CHANGELOG.md).

## Run the Gallery

The Gallery is a standalone iOS app that renders the design system in isolation.

```bash
cd Gallery
xcodegen generate                 # the project is generated from project.yml
open Gallery.xcodeproj            # then Run (⌘R) on an iPhone simulator (iOS 26+)
```

Screens: **Updates** (the changelog, with links to the components each release names), six
foundations and 17 component sections by what a component does
([docs/gallery-structure.md](docs/gallery-structure.md)); every component has a page with
controls for its parameters and states.

The Gallery also ships to **TestFlight** on every DesignKit update in `main`, with a
Tenra / Dalada theme switch (each app's accent) and a Glass / Fill surfaces switch (8.12.0), so
both can be checked on a device. Setup and details:
[docs/testflight.md](docs/testflight.md).

## Package layout

Three layered targets (each depends on the ones above it):

```
Sources/
├── DesignTokens/      AppColors, CategoryColors, AppSpacing, AppRadius, AppIconSize,
│                      AppTypography (+ bundled Inter), AppAnimation, AppMotion, AppModifiers,
│                      SurfaceStyle (glass or a grey fill), DSButtonStyle (.dsButton),
│                      AmbientMotionGate, DesignKitTheme, DesignKitFonts
├── DesignSupport/     IconSource, IconStyle, Icon, Formatting, AmountFormatter,
│                      AmountDisplayConfiguration, HapticManager, DominantColorExtractor,
│                      host hooks (logos, FX)
└── DesignComponents/  by what a component does: Actions, TextInput, Selection, Amounts, Rows,
                       Cards, Charts, Progress, Feedback, Navigation, Media, Content, Sheets, Effects
```

Highlights of `DesignComponents`: `FinanceCard`, `InsightsStatCard`, `HeroSection`,
`EditSheetContainer`, `FormSection`, `CardList`, `FormTextField`, `UniversalRow` (every form and settings row),
`UniversalCarousel`, `UniversalFilterButton`, `MessageBanner`, `EmptyState`,
`FormattedAmountText` (adaptive abbreviation), calculator keypad, `OrbChart`, `ProgressRing`,
`LinearProgressBar`, Mini*/Hero* gauges and bar pairs, `AccentGlow`, `BlurSlideTransition`,
`EdgeGlow`. Full inventory: [docs/design-system.md §0](docs/design-system.md).

## Using it in an app

```swift
// Package.swift
.package(url: "https://github.com/dkicekeeper/DesignKit", exact: "8.12.0")
// during development, point at a local checkout instead:
.package(path: "../DesignKit")
```

```swift
import DesignTokens
import DesignSupport
import DesignComponents

@main
struct MyApp: App {
    init() {
        DesignKitTheme.accent = .teal                  // brand accent (default: indigo)
        DesignKitTheme.surface = .fill                 // grey cards, no glass (default: .glass)
        DesignKitFonts.registerIfNeeded()              // Inter
        DesignKitLogoLoader.loader = { brand in await MyLogoService.image(for: brand) }
        DesignKitCurrencyConverter.convert = { amount, from, to in
            await MyRates.convert(amount, from: from, to: to)
        }
    }
    // …
}
```

DesignKit ships no networking, FX or string tables: logos and currency conversion come through
the hooks above, and localized strings resolve in the app's own bundle
([docs/localization-keys.md](docs/localization-keys.md)).

## Working on DesignKit

Read [CLAUDE.md](CLAUDE.md) first — what belongs here, how to port a component from an app, API
stability and versioning rules, Xcode 26/27 compatibility. CI (`.github/workflows/ci.yml`)
builds the package, the Gallery, Tenra and Dalada against every push, runs the unit and snapshot
tests ([docs/snapshots.md](docs/snapshots.md)) and checks the changelog and the component
reference.

Docs: [CHANGELOG.md](CHANGELOG.md) · [design-system.md](docs/design-system.md) ·
[components.md](docs/components.md) · [agents.md](docs/agents.md) · [charts.md](docs/charts.md) ·
[motion.md](docs/motion.md) · [gotchas.md](docs/gotchas.md) ·
[localization-keys.md](docs/localization-keys.md) · [snapshots.md](docs/snapshots.md) ·
[testflight.md](docs/testflight.md) · [gallery-structure.md](docs/gallery-structure.md) ·
[adoption.md](docs/adoption.md) · [benchmark.md](docs/benchmark.md); moving an app across a
major: `docs/migration-X.0.md` (2.0 to 8.0)

## Requirements

iOS 26+, Xcode 26 or 27, Swift 5 language mode. The Gallery project is generated from
`Gallery/project.yml` via [xcodegen](https://github.com/yonaskolb/XcodeGen).
