# DesignKit

A reusable SwiftUI design system, extracted from the **Tenra** iOS app so it can be
shared, versioned, and grown across projects.

> Status: **v0 — visual-evaluation milestone.** The foundation (tokens, support,
> fonts) and a representative set of components are ported and render in the
> **Gallery** app. Tenra is **not** wired to this package yet — that comes after
> visual sign-off.

## Run the Gallery

The Gallery is a standalone iOS app that renders the design system in isolation.

```bash
open Gallery/Gallery.xcodeproj   # then Run (⌘R) on an iPhone simulator (iOS 26)
```

Or from the CLI:

```bash
cd Gallery
xcodebuild -project Gallery.xcodeproj -scheme Gallery \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

The Gallery has screens for **Colors, Typography (Inter), Spacing & Radius,
Icon Sizes, Icons, Buttons, Cards & Surfaces, Motion**, and **Components**.

## Package layout

Three layered targets (each depends on the one above):

```
Sources/
├── DesignTokens/      ← leaf, no deps
│   Colors, Spacing, Typography, Animation, Modifiers (cardStyle/glass), Button
│   + bundled Inter font  (DesignKitFonts.registerIfNeeded())
├── DesignSupport/     ← depends DesignTokens
│   Formatting, AmountFormatter, HapticManager, IconSource, IconStyle, IconView,
│   BrandLogoView (logo loading injected via DesignKitLogoLoader)
└── DesignComponents/  ← depends DesignTokens + DesignSupport
    FinanceCard, RedactableAmount, InsightsStatCard, RecommendationBox, EmptyCardView,
    UniversalRow, InfoRow, DisclosureChevron, EmptyStateView, InlineStatusText,
    FormattedAmountText, BudgetProgressBar, BudgetProgressCircle, ProportionBar,
    ExpenseIncomeProgressBar
```

## Using it in another project

```swift
// Package.swift
.package(path: "../DesignKit")                    // local during development
// or, once tagged:
.package(url: "<git-url>", from: "1.0.0")
```

```swift
import DesignTokens
import DesignComponents

DesignKitFonts.registerIfNeeded()                 // once at App.init()
FinanceCard(title: "Accounts", isEmpty: false, emptyTitle: "—", subtitle: "3 accounts") { … }
```

To show brand logos, inject a loader (DesignKit ships no networking):

```swift
DesignKitLogoLoader.loader = { brand in await MyLogoService.image(for: brand) }
```

## Not (yet) included

Domain-coupled components stay in their host app (they depend on Tenra models):
`TransactionCard`, `AccountRow`, `CategoryRow`, all `Loan*` forms, account/category
selectors, `HealthScoreBadge`, `InsightTrendBadge`, `MiniSparkline`, `DonutChart`,
`SegmentedPickerView` (these need their domain enums parameterized first).

## Requirements

iOS 26+, Xcode 26+, Swift 5 language mode. The Gallery project is generated from
`Gallery/project.yml` via [xcodegen](https://github.com/yonaskolb/XcodeGen).
