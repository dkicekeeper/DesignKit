# Moving to DesignKit 9.0

9.0.0 removes the colour names deprecated in vNext, when no app uses them any more. Until then
they compile with a warning that names the replacement. Run the rewrites first:

    python3 <DesignKit>/scripts/migrate.py --from <your version> --to 9.0.0 --source <App>          # what would change
    python3 <DesignKit>/scripts/migrate.py --from <your version> --to 9.0.0 --source <App> --apply  # change it

then build, and follow the `// TODO(DesignKit 9.0)` notes it leaves where a person decides.

## Colours by role

Every colour has one name, named for where it goes (docs/design-system.md, "Colors"). Only the
accent stays flat.

| Removed | Use |
|---|---|
| `AppColors.textPrimary` / `textSecondary` / `textTertiary` | `AppColors.Text.primary` / `.secondary` / `.tertiary` |
| `AppColors.staticWhite` | `AppColors.Text.primaryOnDark` |
| `AppColors.destructive` / `success` / `warning` | `AppColors.Status.negative` / `.positive` / `.warning` (`…Text` as text) |
| `AppColors.planned` | `AppColors.Status.info` |
| `AppColors.bgBase`, `Background.base` | `AppColors.Background.page` |
| `AppColors.bgCard`, `Background.neutral1` | `Background.card` for an opaque grey surface; `Background.container` for a shape inside a card |
| `AppColors.bgMuted`, `Background.neutral2` | `Background.containerStrong` (`SurfaceStyle.containerStrong` where a `Color` is needed) |
| `Background.fill` | `Background.container` |
| `Background.elevation1` / `elevation3` | `Background.sheet` / `.floating` |
| `Background.elevation2` | `Background.sheet` or `.floating` |
| `.surfaceNeutral1` / `.surfaceNeutral2`, `SurfaceNeutral` | `AppColors.Background.container` / `.containerStrong` (`SurfaceContainer`) |
| `SurfaceStyle.neutral1` / `.neutral2` | `SurfaceStyle.container` / `.containerStrong` |
| `CategoryColors.color(for:)`, `.paletteIndex(for:)`, `.pickerPalette`, `.paletteColors` | `AppColors.Data.color(for:)`, `.paletteIndex(for:)`, `.pickerPalette`, `.palette` |

## Finance colours

`AppColors.income`, `incomeText`, `expense` and `transfer` were Tenra's. An app with money in it
defines its own, next to its other adapters, under names of its own (an `AppColors.income` of the
app's would be ambiguous with DesignKit's until 9.0.0), and passes them to the components:

```swift
// Tenra, DesignKitBridge.swift
extension Color {
    static let income = Color(red: 0.13, green: 0.70, blue: 0.37)
    static let incomeText = AppColors.readable(.income)
    static let transfer = Color(red: 0.0, green: 0.75, blue: 0.85)
}

AmountComparisonBar(expenseAmount: spent, incomeAmount: earned, currency: "KZT", incomeColor: .income)
PayoffProgressCard(…, progressColor: .income) { … }
ScheduleRow(…, doneColor: .income, isDone: true)
TrendBadge(direction: .up, changePercent: 8, color: .income)
```

Without them the components use `Status.positive`.

## Pull to refresh

`.refreshable { … }` → `.dsRefreshable { … }`, the same closure. The rewrite does it.
