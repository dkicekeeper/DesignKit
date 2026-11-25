---
bump: minor
---
Rings and discs that cut a shape out of a card take the card's colour, so grey cards show no white rings.

### Added
- `.surfaceBackground` (`SurfaceBackground`) and `EnvironmentValues.surfaceBackground`: the colour of the surface under a view, the page's or, inside a `cardStyle()` card under `SurfaceStyle.fill`, the card's grey. For a ring or a disc that cuts a shape out of whatever lies under it.

### Fixed
- `AvatarGroup`, `MonthCalendar`'s markers, `LineChart`'s forecast ring and selected point, `HeroSparkline`'s forecast point, the ticks of `HeroHalfGauge` and `MiniHalfGauge`, `TransactionRow`'s badge and the halo of `ParticleCreature`'s words drew their ring in the page's colour: white rings on a grey `.fill` card (Dalada, Platina). They follow the surface now; glass cards look as before. DesignKit's sheets (`EditSheetContainer`, `PromptSheet`, `DateRangePickerSheet`, `ShareCardSheet`) start again on the page, so a sheet presented from a row in a card does not take the card's grey.

### Gallery and tooling
- Snapshots of `AvatarGroup` and `MonthCalendar` (`DisplaySnapshotTests.knockoutsOnGreyCard`) and of a `LineChart` with a forecast (`ChartsSnapshotTests.forecastOnGreyCard`) on a grey card.
