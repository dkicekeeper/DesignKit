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
| `FoundationsSnapshotTests` | typography scale, primary / secondary / loading buttons, `cardStyle`, filter chips, Dalada's accent through `DesignKitTheme.accent` |
| `RowsSnapshotTests` | `UniversalRow`, `ActionSettingsRow`, `ToggleSettingsRow`, `InfoRow`, `SectionHeaderView`, `SelectionIndicator` |
| `FormsSnapshotTests` | `FormSection`, `DatePickerRow`, `MenuPickerRow`, `SettingsSectionHeaderView`, `HeroSection` |
| `IconsSnapshotTests` | `IconView` (category, circle, rounded square, glass hero, placeholder, brand fallback), `BrandLogoView`, `PackedCircleIconsView` |
| `CardsSnapshotTests` | `FinanceCard`, `RedactableAmount`, `EmptyCardView`, `InsightsStatCard`, `InsightEntityRow`, `UniversalCarousel`, `UniversalFilterButton` |
| `FeedbackSnapshotTests` | `EmptyStateView` (3 styles), `MessageBanner`, `InlineStatusText`, `RecommendationBox`, `StepTracker`, `OnboardingStepIndicator`, `PermissionPrimerView`, `OnboardingPage` |
| `DisplaySnapshotTests` | `BadgeView`, `TrendBadge`, `StatusIndicatorBadge`, `StatTile`, `AvatarView`, `AvatarGroup`, `RatingView`, `ActivityTimeline`, `MonthCalendar`, `ExpandableText`, `FlowLayout`, `HeroSymbol` |
| `ChartsSnapshotTests` | `LinearProgressBar`, `ProgressRing`, `AmountComparisonBar`, `FormattedAmountText`, `Sparkline`, `LineChart`, `BarChart`, `HeroSparkline`, `OrbChart`, `MiniDonut`, `ProportionBar`, `MiniProportionBar`, `HeroProportionBar`, `HeroHalfGauge`, `MiniHalfGauge`, `HeroMilestoneGauge`, `MiniMilestoneGauge`, `HeroBarPair`, `MiniBarPair` |
| `SummarySnapshotTests` | `TotalsCard`, `LimitProgressCard`, `WeightBreakdownCard`, `CalculationCard`, `NetAmountRow`, `ScheduleRow`, `ComparisonCard`, `CashFlowCard` (loaded, empty), `RecurringPaymentCard`, `PayoffProgressCard`, `BreakdownRow`, `AmountPercentageView` |
| `ScoresSnapshotTests` | `ScoreGaugeCard`, `ScoreCard`, `TargetProgressCard` |
| `InputsSnapshotTests` | `SegmentedPickerView`, `ChipPicker` (single / several), `RatingPicker`, `FormTextField`, `TagInput`, `CalculatorKeypad`, `AmountDigitDisplay`, `FormattedAmountView`, `SpentBudgetText`, `PlusTabLabel`, `BulkDeleteButton`, `EntityActionButton` |

Appearances (`SnapshotAppearance`): `light`, `dark`, and `largeText` (light at accessibility
text size AX2, which catches truncation and clipping). References live in
`Gallery/SnapshotTests/__Snapshots__/<File>/<test>.<appearance>.png`.

Not covered on purpose:
- views that animate continuously on a clock, so no two frames match: `SiriGlowView`,
  `SiriWaveRecordingView`, `AccentGlow`, `.borderBeam()`, and the skeleton shimmer
  (`SkeletonView`, `SkeletonRow`, `.skeleton`, the loading state of `CashFlowCard`). Reduce
  Motion stops the shimmer, but SwiftUI does not let a test set it (`accessibilityReduceMotion`
  is read-only);
- views whose content depends on today's date: `DateButtonsView`, `DateSectionHeaderView`;
- `ConvertedAmountView` (and `RecurringPaymentCard`'s converted line), which waits for the host
  app's currency converter;
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
  More button, would otherwise be cut off at the top and bottom), then captures until two
  frames in a row are identical (Liquid Glass animates its shadow for a moment). The PNG is the
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

## CI

The `Snapshot tests` job in `.github/workflows/ci.yml` runs `scripts/snapshot-tests.sh` on
every push and PR. On a failure it uploads the images that differ as the `failing-snapshots`
artifact. Open them next to the references in the PR's diff.

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
