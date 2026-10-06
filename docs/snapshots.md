# Snapshot tests

The unit tests check logic. The snapshot tests check the **look**: every component listed below
is rendered and compared, pixel by pixel within a small tolerance, with a reference PNG in the
repo. A change that moves an edge, changes a colour, a font or a text, or clips a label at a
large text size fails CI, and the PR shows the new image next to the old one.

Tenra's look is the reference for both apps. So a visual change to a shared component is a
decision, not a side effect. With these tests it shows up as changed PNGs in the PR, and nobody
has to catch it on a device.

## What is covered

`Gallery/SnapshotTests/`, one file per area. Each test draws a group of variants in the
appearances it lists:

| File | Components |
|---|---|
| `FoundationsSnapshotTests` | typography scale, `AppTypography.numbers` (proportional vs tabular), primary / secondary buttons (enabled, disabled), the `appButton` matrix, `.fadeTruncation()`, `cardStyle`, filter chips, Dalada's accent through `DesignKitTheme.accent` |
| `RowsSnapshotTests` | `CheckmarkRow`, `UniversalRow`, `ActionSettingsRow`, `ToggleSettingsRow`, `InfoRow`, `SectionHeaderView`, `SelectionIndicator` |
| `FormsSnapshotTests` | `EditableHero` (amount, no currency chip), `FormSection`, `DatePickerRow`, `MenuPickerRow`, `SettingsSectionHeaderView`, `HeroSection` |
| `IconsSnapshotTests` | `IconView` (category, circle, rounded square, glass hero, placeholder, brand fallback), `BrandLogoView`, `PackedCircleIconsView` |
| `CardsSnapshotTests` | `FinanceCard`, `RedactableAmount`, `EmptyCardView`, `InsightsStatCard`, `InsightEntityRow`, `UniversalCarousel`, `UniversalFilterButton` |
| `FeedbackSnapshotTests` | `StatusBanner` (5 statuses, compact, with an action), `EmptyStateView` (3 styles), `MessageBanner`, `InlineStatusText`, `RecommendationBox`, `StepTracker`, `OnboardingStepIndicator`, `PermissionPrimerView`, `OnboardingPage` |
| `DisplaySnapshotTests` | `BadgeView`, `TrendBadge`, `StatusIndicatorBadge`, `StatTile`, `AvatarView`, `AvatarGroup`, `RatingView`, `ActivityTimeline`, `MonthCalendar`, `ExpandableText`, `FlowLayout`, `HeroSymbol` |
| `ColorsSnapshotTests` | every semantic colour token (`AppColors.Text`, `.Background`, `.Border`, `.Status`, `pale(_:)`): a swatch each, light and dark |
| `ChartsSnapshotTests` | `LinearProgressBar`, `ProgressRing`, `AmountComparisonBar`, `FormattedAmountText`, `Sparkline`, `LineChart`, `BarChart`, `HeroSparkline`, `OrbChart`, `MiniDonut`, `ProportionBar`, `MiniProportionBar`, `HeroProportionBar`, `HeroHalfGauge`, `MiniHalfGauge`, `HeroMilestoneGauge`, `MiniMilestoneGauge`, `HeroBarPair`, `MiniBarPair` |
| `SummarySnapshotTests` | `TotalsCard`, `LimitProgressCard`, `WeightBreakdownCard`, `CalculationCard`, `NetAmountRow`, `ScheduleRow`, `ComparisonCard`, `CashFlowCard` (loaded, empty), `RecurringPaymentCard`, `PayoffProgressCard`, `BreakdownRow`, `AmountPercentageView` |
| `ScoresSnapshotTests` | `ScoreGaugeCard`, `ScoreCard`, `TargetProgressCard` |
| `BalancesSnapshotTests` | `BalanceCard`, `SelectableBalanceCard`, `BalanceRow`, `ProgressRingRow`, `ProgressRingTile`, `ProgressRingTileGrid`, `MetricCard` (mini chart, none, bottom chart), `GradientOrbsBackground`, `PromptSheet` |
| `SkeletonsSnapshotTests` | every component skeleton (1.10.0): each card skeleton on its own, rows, charts, gauges and bars, badges, icons, amounts, headers, timeline, the community and progress components (1.12.0); the shimmer is stopped (`.skeletonShimmer(false)` in the renderer) |
| `CommunitySnapshotTests` | `PersonRow`, `CommentRow` (with a quote and actions), `ThreadCard`, `ReviewCard`, `ReactionButton`, `AchievementTile`, `AchievementProgressRow`, `ChecklistRow`, `ChecklistSummaryRow`, `StatsStrip`, `StreakCard`, `ThumbnailCard`, `ThumbnailRow` (1.12.0) |
| `InputsSnapshotTests` | `FormattedAmountText` sign and unit, hidden amounts (`.amountsHidden`, `AmountVisibilityToggle`, the `HeroProportionBar` legend), `CurrencyPickerMenu` and `CurrencyAmountInput` (calculator display, error), `SegmentedPickerView`, `ChipPicker` (single / several), `RatingPicker`, `FormTextField`, `TagInput`, `MessageComposer` (empty, quote and error, disabled), `CalculatorKeypad`, `AmountDigitDisplay`, `FormattedAmountView`, `SpentBudgetText`, `PlusTabLabel`, `BulkDeleteButton`, `EntityActionButton` |

Appearances (`SnapshotAppearance`): `light`, `dark`, and `largeText` (light at accessibility
text size AX2, which catches truncation and clipping). References live in
`Gallery/SnapshotTests/__Snapshots__/<File>/<test>.<appearance>.png`.

Not covered on purpose:
- views that animate continuously on a clock, so no two frames match: `SiriGlowView`,
  `SiriWaveRecordingView`, `AccentGlow`, `.borderBeam()`, and the spinner of
  `LoadingButtonLabel(isLoading: true)`. Skeletons are covered since 1.10.0: the renderer
  stops their shimmer with `.skeletonShimmer(false)` (Reduce Motion would too, but SwiftUI
  does not let a test set it; `accessibilityReduceMotion` is read-only). `.skeleton(isLoading:)`
  is not: its shapes are the system's redaction;
- views whose content depends on today's date: `DateButtonsView`, `DateSectionHeaderView`;
- full-screen pickers with a search in the navigation bar: `IconPicker`, `CurrencyList`;
- `ConvertedAmountView`, `RecurringPaymentCard`'s converted line and `CurrencyAmountInput`'s
  "≈" line (its snapshot is in the base currency, so without the line), which wait for the
  host app's currency converter;
- containers whose look is the system's (`EditSheetContainer` is a `Form` in a navigation bar)
  or that show the host app's localized strings (`ImportProgressSheet`,
  `OnboardingPageContainer`, `NotificationPermissionView`);
- screens that need app data.

All of them have a specimen in the Gallery.

## How it works

- The tests are a unit-test target **hosted in the Gallery app** (`Gallery/project.yml`,
  `GallerySnapshotTests`). Each component is put in its own `UIWindow` in the app's scene and
  drawn with `drawHierarchy`, so Liquid Glass, materials and UIKit-backed controls (switches,
  segmented pickers, text fields) render as on a device. A test bundle without a host app
  cannot do that.
- `assertComponentSnapshot(_:width:appearances:)` (`SnapshotSupport.swift`) wraps the view:
  360 pt wide, `AppSpacing.lg` around it, `AppColors.bgBase` behind, animations off, US
  English locale. It waits 1.5 s for `onAppear` and layout, measures the view again and
  resizes the window if it grew (a view that measures itself, like `ExpandableText` adding its
  More button, would otherwise be cut off at the top and bottom; the log lists those as
  `SNAPSHOT-RESIZED <test>.<appearance>: <old> → <new> pt`), then captures every 0.4 s
  until three frames in a row are identical, for up to 8 s (Liquid Glass animates its shadow
  for a moment; two frames were not enough between stacked cards, whose shadows can hold still
  for one interval and move again). A snapshot that never settles prints
  `SNAPSHOT-UNSETTLED <test>.<appearance>` to the log. When the run compares (not when it
  records), a render that differs from its reference is drawn once more in a new window and
  only the second one is asserted (`SNAPSHOT-RETRY <test>.<appearance>` in the log): Liquid
  Glass now and then draws a tall card without the shading along its bottom edge for a whole
  render (October 2026, about one tall-card render in 25 at large text; a probe showed the
  shading either there from the first frame for 10 s, or not). The comparison is as strict as
  before; a real change differs twice and fails. The PNG is the
  component's own frame: the shadow glass casts around a card falls outside it, and the
  simulator renders that shadow a little differently from run to run, while the component's
  own pixels do not change. Then it compares with
  [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)
  (`precision: 0.995, perceptualPrecision: 0.98`: anti-aliasing noise passes, a moved edge
  does not). Images are 2x whatever the simulator.
- swift-snapshot-testing is a dependency of the **Gallery project only**. The DesignKit package
  has no dependencies, so Tenra and Dalada never fetch it.
- Tests run one at a time (`@Suite(.serialized)` on `ComponentSnapshots`).
- Glass needs room and a screen. The window holds 24 pt of plain background around the
  captured area (glass bends what lies just outside a card's edge) and must fit on the
  screen: where it does not, glass and its shadow render differently from run to run. A
  360 pt component is exactly the Pro Max's 440 pt; a test whose window does not fit fails
  with "does not fit the screen", so split it or narrow it.

**One Liquid Glass card per snapshot.** Glass reflects what lies next to it: a card beside or
under another shows a faint copy of its neighbour's content along the edge and in the gap. That
reflection is stable within a run but appears in some runs and not in others, so a test that
puts two glass cards side by side failed now and then with nothing changed (`financeCards`,
`scoreCards`, `statCards` in October 2026; `messageComposer`, three glass fields in a column,
settled half a pixel apart from run to run). Give each glass card its own snapshot with
`assertComponentSnapshot(_:named:…)` (`<test>.<named>-<appearance>.png`); a row of chips or
buttons that belongs together stays one snapshot.

## CI

The `Snapshot tests` job in `.github/workflows/ci.yml` runs `scripts/snapshot-tests.sh` on
every push and PR. On a failure it uploads the images that differ as the `failing-snapshots`
artifact. Open them next to the references in the PR's diff. The job log has the same in
text: the library's message for each failing image (which reference, how much it differs)
under "Snapshot differences", and each failing image base64-encoded between
`BEGIN-SNAPSHOT-PNG <path>` and `END-SNAPSHOT-PNG` (decode with `base64 -d`).

The job pins **Xcode 26.6** and picks **iPhone 17 Pro Max** on the newest installed iOS
runtime. References depend on the iOS runtime (glass, text rendering). So moving the pin is
its own PR, together with re-recorded references.

## Recording and updating references

References are recorded on CI, not on a laptop, so they match what CI compares with:

1. Push the branch.
2. Run the **CI** workflow manually on that branch (Actions → CI → Run workflow, or the API)
   with `record_snapshots`:
   - `missing`: only tests that have no reference yet (a new test or appearance);
   - `failed`: only references that differ (after an intentional visual change);
   - `all`: every reference (after moving the Xcode pin).
3. The snapshot job commits the PNGs to the branch (`test(snapshots): record references`).
   That push does not start CI, so run CI on the branch again with `record_snapshots: never`,
   or push again. It must be green.
4. Review the changed PNGs in the PR. They **are** the visual change. Call it out in the
   release notes, since it lands in both apps.

Recording is ignored on `main`: references change only through a PR.

Locally, on a Mac with the same Xcode: `scripts/snapshot-tests.sh` compares, and
`SNAPSHOT_TESTING_RECORD=failed scripts/snapshot-tests.sh` records. A Mac with another Xcode or
another runtime records slightly different pixels, so commit references recorded by CI.

## Adding a test

```swift
extension ComponentSnapshots.Display {
    @Test func myBadge() async {
        await assertComponentSnapshot(
            HStack { MyBadge("New"); MyBadge("Old", style: .muted) },
            appearances: [.light, .dark, .largeText]
        )
    }
}
```

- Show the variants side by side in one test: fewer images, the same coverage.
- No dates from the clock, no network, no random data. Pass fixed values, like
  `CalendarRange(today:calendar:)` in `monthCalendar()` and the chart points without dates.
- Turn off entrance animations where the component has a switch (`animatesOnAppear: false`).
- Texts are passed in. Keys from the host bundle would render as raw keys.
- Then run CI with `record_snapshots: missing`.
