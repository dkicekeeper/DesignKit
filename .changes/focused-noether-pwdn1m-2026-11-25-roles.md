---
bump: minor
---
Colours by role: every colour has one name, named for where it goes. The flat names of 1.x and the finance colours are deprecated, accent text reads at 4.5:1, and the colours of named things become `AppColors.Data`.

### Added
- `AppColors.Background.page`, `.card`, `.sheet` and `.floating`: the screen, an opaque grey surface (the card of `SurfaceStyle.fill`, a banner's base, a panel), a sheet, a tooltip or popover. Today's colours under names that say where they go.
- `AppColors.Background.container` and `.containerStrong` (`SurfaceContainer`): a shape inside a card (a field, a plate, a chip; a track, a skeleton), opaque on glass and translucent on a grey card as before; `SurfaceStyle.container` / `.containerStrong` where a `Color` is needed.
- `AppColors.Data`: `color(for:opacity:)`, `paletteIndex(for:)`, `palette` and `pickerPalette`, the colours of anything with a name, and `series`, eight colours for a chart's series with neighbours at least 45 degrees apart.
- `AmountComparisonBar(incomeColor:)`, `PayoffProgressCard(progressColor:)`, `ScheduleRow(doneColor:)`: the app's own colour of money in.

### Changed
- `AppColors.Text.action` is the accent made readable (`readable(accent)`): links, text buttons, chosen labels and icons in a line in `MessageComposer`, `PickerCarousel`, the "Today" of `LineChart` and `BarChart`, `MessageBubble`'s retry, `CalculatorKeypad`'s operators, `ArticleBody`, `ExpandableText`, `StepTracker`, `ThumbnailCard`, `SearchablePicker`, `OptionCardPicker`, `ReactionButton`, `MonthCalendar`'s today, `PagerArrows` and `DateRangePickerSheet`. Tenra's indigo is a step lighter on a dark card, Dalada's green a step deeper on a light one; Platina's accent reads as it is.
- `TrendBadge`'s rise, `AmountComparisonBar`, `PayoffProgressCard` and `ScheduleRow`'s "paid" mark default to `Status.positive` (the system green) instead of Tenra's income green; Tenra passes its own. `AmountComparisonBar`'s income amount is its colour made readable.
- `CurrencyList`'s sections are `cardStyle()` cards on the caller's page (glass, or grey under `SurfaceStyle.fill`), not white cards on the grouped grey.
- Under `SurfaceStyle.fill`, a logo's plate, `MessageComposer`'s idle buttons, `TypingIndicator`'s bubble, an unearned `AchievementMedal` and the placeholder behind a loading photo in `PhotoTile` and `PhotoCarousel` follow the surface like every other container (a translucent grey on a grey card).

### Deprecated
- `AppColors.bgBase`, `bgCard`, `bgMuted`, `textPrimary`, `textSecondary`, `textTertiary`, `staticWhite`, `destructive`, `success`, `warning`, `planned` → the groups (`Background.page`, `.card`, `.containerStrong`, `Text.*`, `Text.primaryOnDark`, `Status.*`).
- `AppColors.income`, `incomeText`, `expense`, `transfer` → the app's own colours (Tenra: `DesignKitBridge.swift`).
- `AppColors.Background.base`, `elevation1`, `elevation2`, `elevation3`, `neutral1`, `neutral2`, `fill` → `page`, `sheet`, `floating`, `card`, `container`, `containerStrong`.
- `SurfaceStyle.neutral1` / `.neutral2` → `.container` / `.containerStrong`; `.surfaceNeutral1` / `.surfaceNeutral2` and `SurfaceNeutral` → `AppColors.Background.container` / `.containerStrong`.
- `CategoryColors` → `AppColors.Data`.

### Migration
- Nothing breaks: the old names keep their values and warn with their replacement until 9.0.0. To move now, run the 9.0.0 rewrites (`scripts/migrations/9.0.0.json`, docs/migration-9.0.md):

```bash
python3 <DesignKit>/scripts/migrate.py --from vNext --to 9.0.0 --source <App> --apply
```

- Tenra defines its finance colours next to its adapters, under names of its own, and passes them:

```swift
extension Color {
    static let income = Color(red: 0.13, green: 0.70, blue: 0.37)
    static let transfer = Color(red: 0.0, green: 0.75, blue: 0.85)
}
AmountComparisonBar(expenseAmount: spent, incomeAmount: earned, currency: "KZT", incomeColor: .income)
```

### Gallery and tooling
- The Colors screen shows the roles, the accent and `AppColors.Data`; the flat names and the finance colours are gone from it. The Gallery passes Tenra's income and transfer colours as an app would.
- `scripts/migrations/9.0.0.json` and docs/migration-9.0.md: the rewrites and notes for the colour names; `docs/design-system.md` opens its Colors section with which colour goes where.
