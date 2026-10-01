# DesignKit

A reusable SwiftUI design system extracted from the **Tenra** iOS app and shared with
**Dalada**. Tokens, components and motion rules are Tenra's (the reference implementation);
this package makes them versioned and reusable.

> Status: **0.x — pre-1.0.** Both apps consume the package (Tenra since 0.3.0) and pick up new
> releases automatically; design-system changes are made here.

## Run the Gallery

The Gallery is a standalone iOS app that renders the design system in isolation.

```bash
cd Gallery
xcodegen generate                 # the project is generated from project.yml
open Gallery.xcodeproj            # then Run (⌘R) on an iPhone simulator (iOS 26+)
```

Screens: **Colors, Typography (Inter), Spacing & Radius, Icon Sizes, Icons, Buttons, Cards &
Surfaces, Motion, Components, Forms & Settings, Inputs & Charts**.

The Gallery also ships to **TestFlight** on every DesignKit update in `main` — with a
Tenra / Dalada theme switch, so each app's accent can be checked on a device. Setup and details:
[docs/testflight.md](docs/testflight.md).

## Package layout

Three layered targets (each depends on the ones above it):

```
Sources/
├── DesignTokens/      AppColors, CategoryColors, AppSpacing, AppRadius, AppIconSize,
│                      AppTypography (+ bundled Inter), AppAnimation, AppModifiers,
│                      AppButton, AmbientMotionGate, DesignKitTheme, DesignKitFonts
├── DesignSupport/     IconSource, IconStyle, IconView, BrandLogoView, Formatting,
│                      AmountFormatter, AmountDisplayConfiguration, HapticManager,
│                      DominantColorExtractor, host hooks (logos, FX)
└── DesignComponents/  Cards, Charts, Feedback, Forms, Headers, Icons, Input, Rows
```

Highlights of `DesignComponents`: `FinanceCard`, `InsightsStatCard`, `HeroSection`,
`EditSheetContainer`, `FormSection`, `FormTextField`, `UniversalRow`, `InfoRow`, `MenuPickerRow`,
`UniversalCarousel`, `UniversalFilterButton`, `MessageBanner`, `EmptyStateView`,
`FormattedAmountText` (adaptive abbreviation), calculator keypad, `OrbChart`, `ProgressRing`,
`LinearProgressBar`, Mini*/Hero* gauges and bar pairs, `AccentGlow`, `BlurSlideTransition`,
`SiriGlowView`. Full inventory: [docs/design-system.md §0](docs/design-system.md).

## Using it in an app

```swift
// Package.swift
.package(url: "https://github.com/dkicekeeper/DesignKit", exact: "0.3.0")
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
builds the package, the Gallery and Dalada against every push.

Docs: [design-system.md](docs/design-system.md) · [charts.md](docs/charts.md) ·
[gotchas.md](docs/gotchas.md) · [localization-keys.md](docs/localization-keys.md) ·
[testflight.md](docs/testflight.md)

## Requirements

iOS 26+, Xcode 26 or 27, Swift 5 language mode. The Gallery project is generated from
`Gallery/project.yml` via [xcodegen](https://github.com/yonaskolb/XcodeGen).
