# Charts

Swift Charts patterns for `LineChart` / `BarChart` (multi-series), the `OrbChart` breakdown chart, and mini-charts.

> **Source.** Tenra's `docs/domains/charts.md` (Tenra `74a12c5`). Everything here ships in
> DesignKit: `OrbChart` + `DonutSlice`, `MiniDonut`, the progress family (`ProportionBar`,
> `LinearProgressBar`, `ProgressRing`, `AmountComparisonBar`), the Mini*/Hero* visuals,
> `HeroChartEffects`, `ChartZoomControls`, and since 0.5.0 the trend family — `LineChart`,
> `BarChart`, `ChartSwitcher`, `HeroSparkline`, `Sparkline`, `ChartSelectionBanner` — over a
> generic `ChartPoint` model (see **Trend charts** below). Tenra keeps adapters only
> (`PeriodDataPoint: ChartPoint`, `PeriodChartSeries` → `ChartSeries`).
>
> DesignKit difference: `DonutSlice.from(_:)` / `from(_:baseColor:)` are Tenra adapters over
> DesignKit's generic `DonutSlice.foldingSlivers(_:)` / `opacityStepped(_:baseColor:)`.

## Trend charts: `ChartPoint` + `ChartSeries` *(0.5.0)*

The chart family is generic over the point type:

```swift
// 1. A point: one bucket on the X axis. Only chartLabel is required.
extension MonthStats: ChartPoint {
    var chartLabel: String { key }          // unique category, also the selection key
    var chartAxisLabel: String { short }     // "JAN" under the tick
    var chartTitle: String { full }          // "January 2025" in the banner
    var chartDate: Date? { start }           // first future bucket gets the "Today" marker
}
// …or ChartValuePoint(label:axisLabel:title:date:values:) for plain data.

// 2. A series: how to read and colour a value.
let spending = ChartSeries<MonthStats>(id: "spending", name: "Expenses",
                                       coloring: .solid(AppColors.destructive)) { $0.expenses }
let net = ChartSeries<MonthStats>(id: "net", name: "Net",
                                  coloring: .signed(positive: AppColors.success, negative: AppColors.destructive),
                                  baseline: .signed) { $0.net }

// 3. A chart.
ChartSwitcher(dataPoints: months, series: [income, spending], valueFormat: .currency("KZT"))
LineChart(dataPoints: months, series: net)
HeroSparkline(dataPoints: months, series: spending, projectedValue: forecast, markExtremes: true)
Sparkline(dataPoints: months, series: net, height: 24)        // Canvas, for cards/feeds
```

| Piece | Meaning |
|---|---|
| `ChartColoring.solid(c)` | one colour for line, area, points, bars |
| `ChartColoring.signed(positive:negative:)` | colour by sign; the line gradient switches exactly at y = 0; dashed zero rule |
| `ChartBaseline.zero` / `.signed` | Y from 0, or allowed below 0 |
| `ChartValueFormat` | banner + VoiceOver: `.compact` ("75K"), `.currency("KZT")` (`FormattedAmountText`), `.custom { "\($0) km" }`. The Y axis is always compact. |
| `todayText`, `emptyTitle`, `emptyMessage` | texts; defaults are the keys `chart.today`, `chart.empty.title`, `chart.empty.message` |

Several series: `LineChart` overlays them (no fill under the lines), `BarChart` groups them
(`position(by:)`), the banner lists each value under the series' name with a dot (the chart's
legend), VoiceOver reads `name: value` per series.

### How the trend charts behave *(8.2.0, the owner's audit)*

`LineChart` and `BarChart` share one frame, `TrendChartFrame` (internal): the cache, the
selection, the window, the banner, the axes, the Audio Graph and the motion. Each chart draws
only its marks from a `TrendChartContext`.

- **The current period is selected.** It is the last point that does not start after now (the
  last point when the points have no dates). The banner above the plot always shows the
  selected period; a tap picks another, and a touch that lifts does not clear it (Swift Charts
  reports nil again; the frame keeps the last period it reported). The selected bars are in full
  colour, the others at `ChartMetrics.dimmedOpacity`; the line has a ruler, a halo and a ringed
  dot there.
- **The window is centred on it.** `ChartWindow` puts the selected period in the middle of the
  `visiblePoints / zoom` categories on screen; near the end it adds empty categories after the
  last point (labels with an invisible prefix, no axis text, never selectable), so the latest
  period does not sit against the screen's edge. A series that fits the window is shown whole,
  without padding. The window is set by `chartScrollPosition(initialX:)` when a chart is made,
  so taps move the selection, not the window; a new chart (new periods, another zoom: the
  chart's `.id`) is centred on the selected period again.
- **A period that is not over** (`ChartPoint.chartIsPartial`): its bar fades towards its end,
  the line's stretch into it is dashed (a series of its own, `ChartPartialSeries`) with no fill
  under it (the fill is a monotone curve, the stretch a straight dash: a fill under it bulged
  past the dash), the banner adds "so far" (`chart.partial`). Only the unfinished periods at the end of the series turn the
  line dashed.
- **Motion.** The chart fades in (no scale); the line is traced in (`.chartDrawIn`, 0.7 s, its
  mask taken away once drawn), the bars rise from zero (a data change inside one
  `withAnimation`, which Swift Charts interpolates: no mask, no per-frame work). New values
  under the same periods move the marks (`.animation(chartUpdateAnimation, value: cache.key)`);
  new periods or a zoom cross-fade to a new chart. `ChartSwitcher` turns the entrance off once
  the style changed (`chartPlaysEntrance`), and keeps the selection in its own state.
- **Data read once.** `ChartPointCache` is keyed by a hash of the points (their `Hashable`,
  values included when synthesized) and the series ids, and holds every series' values, the
  titles, the VoiceOver texts, the current and unfinished periods. A tap or a scroll never calls
  a series' value closure. Before 8.2.0 the key was the count and the first and last labels: new
  values under the same labels kept the old Y domain, and the new peak was clipped.
- **VoiceOver.** One element per value: the period's title (with the series' name when there are
  several) and the value in the chart's format; fills, rules and halos are hidden. The Audio
  Graph (`ChartAudioGraph`) reads the same titles and values.

Tenra's insight series map onto this: spending / avg-daily → `.solid(destructive)`, income →
`.solid(success)`, cash flow → `.signed(success, destructive)` + `.signed`, wealth →
`.solid(accent)` + `.signed`, line width 2.5.

## 2026-07 charts refactor — rename map

Feature-bound names replaced with reusable ones (old → new; grep for the new name):

| Old | New |
|---|---|
| `SpendingOrbChart` | `OrbChart` (renders income breakdowns too) |
| `PeriodLineChart` + `IncomeExpenseLineChart` | `LineChart` (multi-series; income/expense = `series: [.income, .spending]`) |
| `PeriodBarChart` + `IncomeExpenseBarChart` | `BarChart` (multi-series, grouped via `position(by:)`) |
| `PeriodChartSwitcher` / `IncomeExpenseChartSwitcher` / `PeriodTrendChartSwitcher` | `ChartSwitcher` |
| `PeriodLineChartSeries` | `PeriodChartSeries` (kept the Period prefix — bound to `PeriodDataPoint`) |
| `BudgetProgressBar` | `LinearProgressBar` (also renders health scores) |
| `BudgetProgressCircle` | `ProgressRing` |
| `ExpenseIncomeProgressBar` | `AmountComparisonBar` (now built on `ProportionBar`) |

`ChartZoomControls` extracted to its own file (also hosts the shared `ChartStyle` bar/line enum). `ChartDisplayMode` deleted (dead code).

### Multi-series period charts (the 4→2 merge)

`LineChart` and `BarChart` take `series: [PeriodChartSeries]` (single-value convenience inits exist). The income/expense overlay is NOT a separate chart — it's `[.income, .spending]`: both cases already carried the needed styles in the enum, so the former `IncomeExpenseLineChart`/`IncomeExpenseBarChart`/`IncomeExpenseChartSwitcher` were deleted.

- Marks always pass `series: .value("Type", s.seriesKey)` + `stacking: .unstacked` (line) / `position(by:)` when grouped (bar).
- The banner is generic: one `ChartSelectionBanner.Entry` per series (with its name since 8.2.0), so any combination of series works.
- Selection halos: multi-series skips zero-valued points (halo at the baseline reads as noise; before 8.2.0 it skipped negative ones too); single-series always highlights.
- Adding a `PeriodChartSeries` case: also set `seriesKey` (mark grouping) — plus the ~9 style switches listed below.

`ChartSwitcher` (segmented bar/line picker + `ChartZoomControls`; zoom and, since 8.2.0, the selected period live here, passed down as bindings) wraps the pair everywhere: InsightsSummaryDetailView (`[.income, .spending]`, default `.bar`), InsightDetailView periodTrend details (single series, default `.line`). Charts no longer own a zoom toolbar — standalone use gets `.constant(1.0)`. The length of a period (week, month) is the app's global granularity, not the chart's: zoom only changes how many periods fit on screen.

### Y-domain headroom (peak clipping)

⚠️ Both full-size charts pad the Y domain by **~6% of the span** (and below the floor when the domain goes negative) — without it the peak `PointMark`/bar top sits exactly on the plot edge and renders clipped. Keep the headroom when touching `fullYDomain`.

⚠️ **Gradient styles must use the UNPADDED envelope, not the padded domain.** `lineStyle`/`areaStyle` gradients resolve against the mark's own bounds (the raw data envelope) — computing the cashFlow `zeroRatio` from the padded `fullYDomain` shifts the green→red transition above the true zero line (renders as a red band over y=0 when negatives exist). `LineChart.fullChart` passes `styleEnvelope = min(yMin,0)...max(yMax,1)` to the style builders and the padded `domain` only to `chartYScale`.

### Progress components & entrance animation

`ProportionBar` (base two-segment primitive), `LinearProgressBar` (percentage + overshoot), `ProgressRing`, `AmountComparisonBar` (ProportionBar + amount labels) all share the sweep-from-zero entrance pattern: `@State` display value + `onAppear`/`onChange` + Reduce Motion → `.linear(duration: 0)`.

⚠️ **`animatesOnAppear: false` in lazy containers** (`AmountRow`'s limit ring, `ProgressRingTile`, the `MetricCard` feed) — `onAppear` re-fires each time a lazy row re-materialises during scroll, replaying the sweep. Detail screens and one-off cards keep the default `true`.

**`ProgressRing` color model** — a static full-circle "trajectory" `AngularGradient` (green ≤45% → warning by 80% → destructive at 100%; over-budget = warning→red) revealed by the animated `trim`. The tip color tracks the fill level continuously with zero interpolation code — do NOT reintroduce threshold-snapped solid colors; gradient stops are progress fractions and must NOT be tied to the animated display value (stops aren't animatable).

**`ProgressRing` trim-start inset** — round stroke caps protrude half a lineWidth beyond the trimmed path, so a trim starting at 0 bleeds counter-clockwise past 12 o'clock and paints the green start cap over the red arc tip at ~100% (2026-07 bug). The trim start is inset by `(lineWidth / 2) / (π × size)` (clamped to `end / 2` so tiny progress still renders) — do NOT "simplify" it back to `.trim(from: 0, ...)`.

## Native Scroll Pattern

Use **native `chartScrollableAxes`** instead of wrapping `Chart{}` in `ScrollView`:

```swift
.chartScrollableAxes(.horizontal)
.chartXVisibleDomain(length: visibleCount)
.chartScrollPosition(x: $binding)  // OR .chartScrollPosition(initialX: ...)
```

Better per-frame than `ScrollView { Chart }` with `defaultScrollAnchor`.

## Bleed-to-Edge Scrollable Charts

Scrollable charts must be **bleed-to-edge** — without `.screenPadding()` on parent, otherwise plot area is clipped and the first point sticks to the screen edge. Apply padding to header/list neighbours, NOT to the chart itself.

## Gesture Conflicts

### MagnifyGesture vs NavigationStack swipe-back

⚠️ **`MagnifyGesture` conflicts with NavigationStack swipe-back** — on detail pages, do NOT use pinch zoom. Replace with `+/-` buttons.

If `MagnifyGesture` is unavoidable, attach `.simultaneousGesture(...)` so native chart gestures (selection) aren't intercepted.

### Horizontal paging vs swipe-back

⚠️ **For swipeable horizontal paging inside a pushed detail, use `TabView(.page(indexDisplayMode:))`, NOT a custom horizontal `DragGesture`.** A `DragGesture` fights the NavigationStack edge swipe-to-go-back (the user gets inconsistent paging vs. dismiss). TabView paging consumes content-area horizontal swipes; edge-back still works from the screen edge. Precedent: `PagedCategoryBreakdownView` in `InsightDetailView.swift`.

### Adding a series

A new series is a `ChartSeries` value (id, name, colouring, baseline, value closure) — no
switches to touch. In Tenra, a new `PeriodChartSeries` case needs one more arm in its
`chart` mapping (exhaustive switch, compiler-checked).

### Custom tap selection blocks scroll

⚠️ **Custom tap selection blocks scroll on `chartScrollableAxes` charts**: `chartOverlay { Color.clear.contentShape(...) ... }` absorbs touches at SwiftUI hit-testing layer, before gesture arbitration — `simultaneousGesture` / `onTapGesture(coordinateSpace:)` don't help.

For tap selection on scrollable charts use **only** `chartXSelection(value:)`.

## Chart Selection

### value + range simultaneously

`chartXSelection(value:)` + `chartXSelection(range:)` together — **value=tap, range=long-press-drag**, no conflict.

⚠️ **Both bindings must be set simultaneously**, otherwise one overrides the other.

### `chartScrollPosition(x:)` requires non-optional `Plottable`

For `String?` wrap via `Binding<String>` with fallback to initial label.

### Setter race during range-selection

⚠️ Apple calls `chartScrollPosition.setter` during `chartXSelection(range:)` drag → if scroll position controls dynamic Y → bars jump.

**Solution**: block setter and **freeze dynamic Y** while `selectedRange != nil`.

## Multi-Series AreaMark

`AreaMark` **stacks by default** — for overlay (income vs expense) you need `series:` PLUS `stacking: .unstacked` together.

Without `series:`, two areas merge into one zigzag-series between x-points.

## Axis Labels

### Collision resolution

```swift
AxisValueLabel(collisionResolution: .greedy(minimumSpacing: 6))
```

Standard label thinning when dates collide. Apply everywhere `AxisMarks { }` uses String x-axis.

### Initial position: the selected period in the middle *(8.2.0)*

```swift
let window = ChartWindow(labels: cache.labels, centerIndex: selected, zoomScale: zoomScale)
Chart { … }
    .chartXScale(domain: window.categories)          // labels + empty ones after the last
    .chartXVisibleDomain(length: window.visibleCount)
    .chartScrollPosition(initialX: window.leadingLabel)
```

Until 8.2.0 the window opened on the last `visibleCount` points, so the latest period sat
against the screen's right edge. `chartXVisibleDomain(length: N)` for category axis shows N
categories regardless of frame width — no `GeometryReader` needed; derive `visibleCount` from
`zoomScale` only.

### `chartScrollPosition(initialX:)` is stable

For one-shot trailing-anchor when no other re-anchor sources exist (static yDomain, no `chartScrollPosition(x: $binding)`).

The `x: $binding` form re-anchors viewport on body re-eval — caused "x-axis flips on tap" bug.

## Category X-axis Order

⚠️ **First-occurrence across marks in declaration order.**

Lock via `chartXScale(domain: dataPoints.map { $0.label })` AND put conditional/selection marks AFTER `ForEach(dataPoints)`. A selection `RuleMark` declared first silently reorders the axis (tap-flips-date bug).

## Conditional Styling

`AnyShapeStyle` for conditional gradient/color on `LineMark.foregroundStyle()` — allows switching between solid and `LinearGradient` without overload conflicts.

## Selection Banner Anti-Jump

`LineChart` and `BarChart` always show their banner (8.2.0), so nothing comes and goes and the
plot never moves. `HeroSparkline`'s banner still comes and goes: it sits in a fixed slot
(`chartBannerSlotStyle`) with an opacity transition, 64 pt at the default text size and scaled
with Dynamic Type (`@ScaledMetric`; a fixed 56 pt before, less than the banner itself).

## Reusable Components

### ChartZoomControls

`ChartZoomControls(zoomScale: $zoomScale, range:)` — `+/-` buttons with step ×1.5, own file `Charts/ChartZoomControls.swift` (also hosts `ChartStyle`). Used in `ChartSwitcher` (picker left, zoom right in HStack). The owner keeps the magnifiers (8.2.0 audit): the dates follow the app's global granularity.

### Chart support (internal)

The trend charts share `Charts/ChartSupport.swift` and `Charts/TrendChartFrame.swift`:

- `ChartPointCache` — keyed by a hash of the points and the series ids: labels, titles, every series' values and VoiceOver texts, label→index, label→axis label, yMin/yMax, today label, the current period, the unfinished ones
- `rebuildChartCacheIfNeeded(_:points:series:format:)` — one O(N) pass per data change, the only place the value closures run
- `ChartWindow` — the window centred on a period, with empty categories after the last point
- `TrendChartFrame` — the frame of `LineChart` and `BarChart` (selection, window, banner, axes, Audio Graph, motion)
- `.chartCategoryXAxis(labelMap:)` / `.chartCompactYAxis()` (about four values, a dashed grid)
- `.chartXLabelSelectionWithFeedback($selectedValueLabel)` (HeroSparkline; haptic via `HapticManager.selection()`)
- `.chartBannerSlotStyle(animationKey:)` (HeroSparkline's banner that comes and goes)
- `.chartSelectionAnnouncement(_:)` + `chartAnnouncementText(...)`, `chartBannerEntries(...)`, `ChartAudioGraph`
- `ChartMetrics` — the sizes, opacities and dashes in one place

A new chart in DesignKit plugs into these — don't reimplement inline.

### Body-time cache priming

`let _ = rebuildCacheIfNeeded()` at the top of `body` runs synchronously before any cache-reading getter.

⚠️ **`.onAppear` fires AFTER the first body-eval** — cold cache returns defaults on the first frame.

### ChartSelectionBanner

`ChartSelectionBanner(title:note:entries:format:)` — one `Entry(value:color:showsDot:label:)` per
value (Tenra's former `.dual` = two dotted entries, `.single` = one undotted; `label:` names the
series, 8.2.0). Capitalises the title's first character; `note` follows it in the secondary
colour ("so far"); `format` as in the charts. Values roll from one period to the next
(`numericText`). `ChartSelectionBannerSkeleton(values:)` is its placeholder.

## Compact Mode

⚠️ **No compact mode** on `BarChart` / `LineChart` / `ChartSwitcher`.

For insight-feed compact charts use **Canvas-based** `MiniSparkline` / `MiniDonut` (~50× cheaper to instantiate than Apple Charts).

**Insight mini-visuals & `Insight.cardVisual`** (2026-07 visual refresh): generators set a purpose-built `InsightCardVisual` (`barPair` / `halfGauge` / `ring` / `donut` / `budgetBars` / `milestoneGauge`) with ready-to-draw values; `InsightsCardView.miniChart` renders it and falls back to the legacy detailData-derived chart when nil. `cardVisual` is part of `Insight ==` (value-based equality gotcha). Shared visual grammar: **solid fill = fact, translucent/dashed = forecast (`barPair(isProjection:)`, `LinearProgressBar(projectedPercentage:)`), muted gray = comparison base, tick = norm/target marker (limit tick = destructive)**. All minis are **centered in their 120pt card slot** (2026-07 UX pass — MiniBarPair used to right-align). `MiniBarPair` — pairwise was/now metrics (MoM, YoY, price increase, subscription growth, spending forecast). `MiniHalfGauge` — value vs norm tick on a RELATIVE scale `max(value × 1.15, norm × 2)` (spike, large tx, savings rate vs 20%, budget headroom spent-vs-budget) **plus an absolute mode** (`maxValue:`, no tick — the health score card, mini sibling of HeroHalfGauge's absolute mode); it is NOT a % -of-limit ring — that's `ProgressRing` (absolute scale, now with optional `showsTrack`; the `.ring` cardVisual case is currently unused by generators — budget headroom moved to `.halfGauge` because a ring next to the wealth donut read as a second donut). `budgetBars` — up to 3 thin `LinearProgressBar`s (overspend shows top-3 offenders; projectedOverspend passes `projectedPercentage` → forecast mode: scale `max(projected, 110)`, translucent projection segment, destructive limit tick at 100%). `MiniMilestoneGauge` — discrete segmented scale with target tick (emergency fund months, 3 of 6). `.sparkline(points:series:projectedValue:markExtremes:)` — MiniSparkline with generator-shaped points (NO card-side tail slice): dashed projection tail + hollow endpoint (projectedBalance), min/max extreme dots over FULL history (period records), custom per-category points (categoryTrend — points MUST carry real axis labels; HeroSparkline plots them on a category x-axis where empty labels collapse into one category). `MiniProportionBar` (`.proportionBar([DonutSlice])`) — stacked composition bar (recurring total: top-3 + other); flat bar, not a second donut, so adjacent feed cards stay visually distinct. All Canvas-based (no Apple Charts in feed cards), text-free (localization-free, `accessibilityHidden` — card text carries semantics).

**Hero visuals & the wow toolkit** (2026-07 visual refresh, detail screens): `InsightDetailView.heroChartSection` renders a full-size hero from the SAME `cardVisual` payload the feed mini draws — **every mini has a DEDICATED hero component, never the Mini\* view scaled up**: `HeroHalfGauge` (also the health-score hero, absolute 0–100 mode with `zoneTicks`; tap replays the sweep), `HeroBarPair` (tap a bar → its amount in a `Tooltip` above it, 2.0.0), `HeroMilestoneGauge` (tap replays the fill wave), `HeroSparkline` (real Swift Charts view — tap selection + `ChartSelectionBanner` like LineChart, plus dashed projection tail to a synthetic "→" category and min/max extreme PointMarks; non-scrollable, needs `currency`), `HeroProportionBar` (animated stacked bar + tappable legend rows: color dot / name / share % / amount — the legend is what makes the composition readable; labels/amounts are data-driven, no localization keys). All heroes take **`entranceDelay`** — `InsightDetailView` passes 0.5s so entrance animations start AFTER the zoom `navigationTransition` settles (animating during the transition made the hero visibly jump the moment the push completed; do not set it back to 0). Shared effects live in [HeroChartEffects.swift](../Sources/DesignComponents/Progress/HeroChartEffects.swift): `chartGlow()` (colour-matched blurred self-copy underlay — OrbChart's orbShadow generalised; static blur, follows trim/shape animations for free), `materialize(delay:)` (spring pop + sharpen-out-of-blur, Reduce-Motion aware), `glassBar(cornerRadius:)` (iOS 26 Liquid Glass, no-op fallback). Layer discipline: data = thin crisp elements, wow = soft underlays; NEVER animate a blur radius per-frame. **`HeroHalfGauge(style: .bleed)`** *(4.2.0)*: a circle wider than the view, of which only the top `span` degrees (130 by default) show, so the arc runs out past both edges and is cut there; the view takes the width it is offered (put it edge to edge, without `.screenPadding()`) and its height follows from that width (`BleedGaugeGeometry`: radius = width / (2·sin(span/2)), capped at a 560 pt arc on wide screens). 0 and the maximum sit just inside the edges so the knob (a white disc a little wider than the stroke, the colour inside, a soft shadow) always shows whole; the sweep moves the knob along the arc. Zones and the norm are thin notches cut through the track and the arc (`destinationOut`, so the background shows through). Drawn in one `Canvas` (one layer, so a glass card cannot blend it). `tone: .onColor` draws a white arc and a translucent white track for a coloured background (no glow); `.onSurface` keeps the arc's colour and glow. `ScoreGaugeCard(style: .hero)` is built on it. **On colour** *(4.5.0)*: inside `.heroBackground(color)` in dark mode (design-system.md, "Hero background"; in light mode it is a pale tint and the heroes draw as on the page, 4.5.1) every hero reads `\.heroTone == .onColor` and draws in white: `HeroHalfGauge` (without an explicit `tone:`), `HeroBarPair` (a white bar, the earlier one translucent white), `HeroSparkline` (a white line over a white fade, white points, translucent white axes via `chartCategoryXAxis(labelMap:tone:)` / `chartCompactYAxis(tone:)`), `HeroMilestoneGauge` (white segments on translucent white, a white target), `HeroProportionBar` (segments in white a step fainter after the largest, the legend in white). `ChartSelectionBanner` keeps its glass card, which reads on colour. Gauge/bar heroes stay text-free (header/formula card carries numbers); HeroSparkline's banner and HeroProportionBar's legend surface data-driven values only. `ring`/`budgetBars`/`donut` payloads deliberately have NO hero (their details already render full-size sections).

**`MiniSparkline` shows the recent tail, not the full series** (2026-07): `InsightsCardView.sparklineTail` slices `.periodTrend` points to the last 12 weeks / 12 months / 8 quarters before passing them in — the full all-time series at 120×60pt renders as noise, and one historical outlier flattens recent dynamics (y-domain follows the visible slice). The DETAIL view still receives the full series (insights.md contract — don't move the slice into the generators). The sparkline also draws a "you are here" dot on the last point (plot rect inset by `endDotRadius`) and, for `.cashFlow` with negatives in range, a dashed zero baseline.

(`ChartDisplayMode` was dead code and deleted in the 2026-07 charts refactor.)

## Breakdown Chart (OrbChart)

⚠️ **`DonutChart` is gone** (retired from Tenra 2026-07, removed from DesignKit in 1.0) — [`OrbChart`](../Sources/DesignComponents/Charts/OrbChart.swift) is the full-size category/subcategory breakdown chart (a blended glass "orb" + thin perimeter arcs + centred `%` labels). `DonutSlice` and its slice-shaping helpers (`foldingSlivers` — merge <5% into "Other", drop a <3% tail; `opacityStepped`) live in that file now, NOT a `DonutChart.swift`. `MiniDonut` still backs compact feed charts.
- **Params**: `showLabels`, `centerIcon` (white glyph in the sphere centre) + `showsCenterIcon`, `size`, `animatesOnAppear`.
- **Motion highlight**: `CMMotionManager` device-motion drives the specular glint. No Info.plist usage string needed (only pedometer/activity require one); Simulator `isDeviceMotionAvailable == false` → static no-op; neutral pose captured on first reading. 30 Hz updates isolated in a child view so only it invalidates.
- **Staggered entrance**: one `@State` flip + per-layer `.animation(anim.delay(i·step), value: entered)` — see the SwiftUI note in [gotchas.md](gotchas.md).

## Mini-Charts in Scroll Feeds

⚠️ **Mini-charts in scroll feeds → Canvas, not `Chart{}`**: Apple Charts per-card instantiation hitches `LazyVStack` section materialization at ~5ms per chart.

For compact sparklines/donuts inside cards, use `Canvas`-based components:
- [MiniDonut.swift](../Sources/DesignComponents/Progress/MiniDonut.swift)
- [Sparkline.swift](../Sources/DesignComponents/Charts/Sparkline.swift) (Tenra's former MiniSparkline)

## Performance Anti-Patterns

### Animation on hot paths

⚠️ **`.animation(value:)` on scroll/zoom-dependent state = hot-path catastrophe**: every scroll event triggers spring → animation accumulation → lag. Apple Charts already smoothly interpolate — no spring needed on top.

### `String(localized:)` in body

⚠️ **`String(localized:)` in hot-path body of chart = anti-pattern**: each scroll frame recreates the localized string. Cache in `@State` / `static let` outside `body` or use stable string keys for `position(by:)`.

### Heavy work per render

Anything per point (a value closure, `chartTitle` with a `DateFormatter`, a `Dictionary` build,
an amount's text) goes into `ChartPointCache`, built once per data change; otherwise a tap or a
zoom redoes it for every point. Tenra's average-daily series computes calendar days in its value
closure: before 8.2.0 every tap ran it three times per point (area, line, point marks).
