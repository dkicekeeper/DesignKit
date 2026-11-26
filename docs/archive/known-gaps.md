# Known gaps and follow-ups, as they were recorded in CLAUDE.md until 2026-11-26

History. What was still open on that day is in `docs/backlog/`.

- Audit round 4 (2026-10, owner-approved) found the last generic views in the apps: Dalada's
  photos, share pictures, session bar, downloads, articles, "All" chips and profile card went
  into 2.8.0; Tenra's transaction row, card pickers, streaming transcript, date-range sheet,
  option cards, card cascade, pager arrows and progress overlay into 2.9.0. After that,
  nothing generic is known to be left. Tenra keeps screens over its models (filter sheets, home
  sections, transaction lists, entity detail screens, the lock screen, `PremiumLockedView` by
  the owner's choice) and its date parsing; Dalada keeps its sign-in card, map layers, weather
  and rules views.
- DesignKit 3.0.0 (2026-10) removed every deprecated name (no app used one), drew `cardStyle()`'s
  glass behind the content and added the form pieces Dalada's forms needed (`StepperRow`,
  `NavigationPickerRow`, `FormTextField(.row)`, `EditSheetContainer(isSaving:)`)
  ([docs/migration-3.0.md](../migration-3.0.md)).
- Audit round 5 (2026-10, owner-approved) found three more things the apps drew by hand:
  the item row (Dalada's trips, places, articles, gear; Tenra's backups, subcategories) became
  `ItemRow` + `MetaLine`, Dalada's queued-item card `PendingItemCard`, and `CurrencyList`'s row
  the public `CurrencyRow` (Tenra's quick-access currencies), all in 3.6.0.
- Dalada's map drew its place types, layers and zones in system colours (some white symbols at
  2.2:1, and a marker image keeps the theme it was drawn in): 3.7.0's `AppColors.Palette` gives
  fixed deep hues with `UIColor`; Dalada maps its types and layers onto them in `MapColors`.
- DesignKit 4.0.0 (2026-10) removed the last deprecated name, `SectionHeader.Style.list`
  (`.compact` since 3.2.0); nothing else changed ([docs/migration-4.0.md](../migration-4.0.md)).
  No deprecated API is left.
- Benchmark round 3 (2026-10, owner-approved) after 4.0.0: `RatingSummary` (Dalada's reviews
  block), `LoadMoreFooter` + `.onReachEnd` (paged lists in both apps) and `limit:` character
  counts on `MessageComposer` / `FormTextField`, all in 4.1.0.
- The hero score (4.2.0, owner-approved from a reference): `ScoreGaugeCard(style: .hero)` over
  `HeroHalfGauge(style: .bleed)`, a gauge wider than the screen with a knob, on a gradient of its
  colour (`tone: .onColor`) or on the page; `AppTypography.display` for its number. Tenra's
  Financial Health screen uses it.
- Insight details on colour (4.5.0, owner-approved): `.heroBackground(color)` behind any hero
  with its pieces in white (`\.heroTone`), `.heroScrollEdge()` on the screen's scroll view so
  the colour reaches the top of the screen, and `ScoreGaugeCard(amount:)`. Tenra's insight
  details open on the colour of their tone. 4.5.1 (owner's review on a device): the gradient
  starts at the screen's top edge, is a pale tint with black text in light mode (deep with
  white in dark mode), and a long amount shrinks inside the arc.
- The assistant as a character (2026-10, the owner's plan): 4.10.0 speech and gestures (words of
  light that fly out of the mouth with an emotion; a comic bubble was tried and dropped by the
  owner), 4.11.0 thoughts in pictures and a life of its own, 4.12.0 eight accessories of light.
  In Tenra (its #62) Ten daydreams of the person's data (the next payment, a goal, rising
  spending, a debt due) and earns its accessories by days in a row in Tenra and by goals; 4.13.0's
  `EmptyState` artwork puts it in Tenra's empty lists, saying a line and pointing at the button.
- DesignKit 5.0.0 (2026-10, the owner's review of 4.14.0's ports): what repeated existing
  components was folded in and the duplicates removed at once, not deprecated. `ListCard` became
  `FormSection(style: .glass)`; `PickerCarousel` runs on `SnapCardPicker(style: .centered(width:))`;
  `AmountEntrySheet` on `EditSheetContainer`; `NavigationPickerRow(.list)` on
  `NavigationSettingsRow(value:)`; one `.selectionOutline` (2 pt) for every picked option. And
  `EdgeBackdrop` went: compared on a device, the owner chose the system's hard scroll edge effect
  for a bar over a chat ([docs/migration-5.0.md](../migration-5.0.md); what the comparison
  taught about the system's effect is in docs/gotchas.md).
- The owner's review of the Gallery (5.2.0, 2026-10): fourteen fixes (`DateRangePickerSheet`'s
  own calendar, `OptionCardPicker(style: .carousel)`, message entrances, `CreatureGlyph`'s eyes
  cut out of its core, …), CI's `Gallery badges` job, and [docs/adoption.md](../adoption.md):
  the components no app uses and where they could go. 5.3.0 gave Ten its answering ring and
  waves, `.working(progress:)`, its eyes on the phone's tilt, gesture haptics and a still
  picture. Both apps took their part of the list (Tenra's #79, which uses every mood, emotion and
  gesture of Ten; Dalada's 0919342). What Dalada then asked for is 5.5.0: `Tooltip(arrowAlignment:)`
  for a corner button (and `.spotlight`'s tail over its view by the screen's edge), and
  `AvatarGroup(_:avatar:)`, a slot for the app's own avatar view with the photo.
- DesignKit 6.0.0 (2026-10, the owner's review of Tenra's background screen): `OptionCardPicker`
  is a carousel of large previews only; `style:` (`.list`, `.carousel`), `OptionCard` and the row
  of small cards under one preview went, and its settings are DesignKit's form rows
  ([docs/migration-6.0.md](../migration-6.0.md)).
- DesignKit 6.1.0 (2026-10, the owner's review of Tenra's background settings on a device):
  `SliderRow(config:)` pads it in a `FormSection` card, and `AuroraBackground(_ spots:)` shows
  its colours bright (denser pools, hues meeting in OKLab with their chroma, a 9×9 mesh, colours
  read as linear light); the Gallery shows settings rows in a card or a `List` with their config.
- DesignKit 7.0.0 (2026-10, the owner's review of the rows and icons): one row,
  `UniversalRow(_:icon:value:hint:role:config:accessory:)`, for every form card and settings
  list (a switch, a menu, a list, a date, a stepper, a slider, a check, a screen, an action, a
  value); the twelve rows that each did one of these are removed, both apps moved in the same
  step. And the icon rule: every symbol is an `Icon`, a glyph under 44 pt, a tile on its plate
  from 44 pt; row icons are 24 pt in forms and lists alike. `PackedCircleIconsStyle.fan` went
  too: no deprecated API is left ([docs/migration-7.0.md](../migration-7.0.md)).
- DesignKit 8.0.0 (2026-10, the owner's review of the apps' screens): one look, Tenra's
  Analytics and Finances everywhere. Every section is a Liquid Glass `FormSection` on the white
  page (Material and `style:` gone), rows are 56 pt with one `RowDivider` under their text, a
  section's title is bold in sentence case (`SectionHeader.Style.compact` removed), and the
  things a person keeps are a `CardList` (a card per item, or rows in one card) with one set of
  actions: a tap opens, a long press shows Edit and Delete, the toolbar selects, reorders and
  adds; no swipe actions ([docs/migration-8.0.md](../migration-8.0.md)). Both apps move their
  forms, lists and `List` screens in the same step.
- DesignKit 8.1.0 (2026-10, the owner's look at Tenra after 8.0.0): the rows made for a `List`
  are rows of a glass section. `ItemRow` pads itself 12 pt and `ChecklistRow` 8 pt above and
  below (`verticalPadding: 0` in a spaced stack or a `List`), and both start the divider under
  their text; a link around a row keeps its inset to its label, so it takes
  `.rowDividerInset(ItemRowStyle.standard.symbolDividerInset)`. Both apps' `section_rows_lint.py`
  (CI) fails on a section row without its own vertical padding and on a linked icon row without
  `.rowDividerInset`.
- DesignKit 8.3.0 (2026-10, the owner's audit of the trend charts): `LineChart`, `BarChart` and
  `ChartSwitcher` open on the current period, selected and centred in the window (empty periods
  after the last one), the banner always above them naming the series; `ChartPoint.chartIsPartial`
  marks a period that is not over; one `TrendChartFrame` under both charts reads the data once.
  The zoom magnifiers stay: the period's length is the app's global granularity (docs/charts.md).
  Then the owner's whole list of additions: forecasts, a year ago, average and limit lines,
  records, a picked stretch, a selection that follows the scroll, stacked bars, a glow in dark
  mode, the entrance on new periods, and `CalendarHeatmap`. After the owner tried them: the
  scroll that follows a ruler no longer redraws the chart under the finger (it shook), the
  person turns the extras on and off in a `ChartSwitcher` menu kept for every chart
  (`.chartDisplayOptions`), Tenra keeps its `OrbChart` over stacked bars, and `MiniBars` draws
  the weekdays on Tenra's new "By day" insight card.
- Benchmark round 4 (2026-11, against Meta's Astryx, the owner approved the whole plan): 8.9.0.
  Status text reads at WCAG AA (`AppColors.readable`, `Status.*Text`, `ContrastTests`); 8.10.0
  (the owner's decision on the rest): white text sits on `AppColors.accentFill` (Tenra's indigo
  deeper in dark mode, Dalada's green deeper) and income text is `readable(income)`,
  outcomes are spoken (`AccessibilityAnnouncer`), `InfoTip`, `RelativeTime`, `SearchablePicker`,
  Markdown replies with time and status, `ConversationDivider`; for the apps, one lint
  (`scripts/designkit_lint.py`), migrations for a major (`scripts/migrate.py`), the agent block
  (docs/agents.md) and the component reference (docs/components.md). Moving the apps onto the lint
  and the block is their sessions' step (docs/adoption.md).
- Surfaces without glass (8.12.0, the owner's request for Platina): `DesignKitTheme.surface = .fill`
  draws cards, sections, chips, tiles and icon plates as an opaque grey on the white page, and the
  neutral shapes inside them as translucent fills (`AppColors.Background.container` /
  `.containerStrong`, 8.21.0; `.surfaceNeutral1` / `.surfaceNeutral2` before).
  Buttons and floating chrome stay glass. Platina (its #1) and Dalada (its #77, 1.0.4) use
  `.fill`; Tenra keeps the default `.glass`.
- Large screens (8.13.0, for Platina on the iPad and the Mac): `.readableWidth()` keeps a screen's
  content to a centred column (`AppLayout.readableWidth`, 720 pt, growing with the text size), and
  `AppLayout.cardColumns()` puts cards side by side in the wide column (1120 pt). No checks for
  the device; list and detail is the system's `NavigationSplitView` (docs/design-system.md §4).
- A hero on a picture (8.14.0, for Platina's game screen, the owner's reference a film's page in
  Apple's TV app): `.heroBackground(clearHeight:picture:)` lays art edge to edge from the screen's
  top, sharp in the hero's room, then blurred and darkened into its own colours under the hero's
  white text and buttons (the dark scheme in both modes), the bar light over it;
  `.heroScrollEdge(isHeroUnderBar:)` lets a screen keep the bar's title empty while the hero
  shows it.
- A main column and a side column (8.15.0, the owner's review of Platina's large-screen mockup:
  an iPad, a Mac window, an unfolded iPhone Duo): `AdaptiveColumns { main } side: { cards }
  narrow: { the phone's layout }` puts summaries beside a detail screen's main column where
  `AppLayout.mainColumnMinWidth` + gap + `AppLayout.sideColumnWidth` fit (764 pt, scaled with the
  text size), and the phone's layout where not; the width the view gets decides, so a panel
  beside the screen switches it too. `CardList(layout: .grid)` puts the things a person keeps side
  by side there. And after the owner's look at 8.14.0's hero on a device: the picture stretches
  when pulled down and lags behind the content when scrolled, and waits for its `RemotePhoto`
  with a still dark fill (`RemotePhotoLoading.still`) instead of a shimmer.
- A hero in two layers (8.17.0, the owner's review of Platina's mockup with three games):
  `.heroBackground(clearHeight:picture:subject:)` stands a cut-out figure (a game's hero
  character) in front of its backdrop, as wide as the screen just under the bars on a phone, with
  a parallax of its own; `RemotePhotoLoading.hidden` keeps a figure that is loading or failed
  out of sight.
- What the creature is busy with (8.22.0, the owner's request from a reference of dotted
  "thinking" orbs, drawn afresh on Ten's engine, nothing copied): `ParticleCreature.Mood`
  `.searching` (a beam over a globe of rows), `.calculating` (bands turning and turning back),
  `.connecting` (a network with pulses), `.writing` (a ribbon behind a pen), the eyes on the work;
  their geometry is pure Foundation in `ParticleCreatureBusy.swift`, unit-tested. `.thinking`'s
  rings got comets, the avatar fewer, larger dots when small, the dark rim's glow a gradient
  instead of a per-frame blur, and `AmbientMotionGate` stops every ambient loop scrolled out of
  sight. The apps' step-to-mood mapping is proposed in docs/adoption.md. And on a white page
  (the owner's request in the same PR) Ten is inked to a luminance cap (`CreatureInkStrength`,
  stronger under Increase Contrast), with an outline all round, a faint disc for a body and
  larger dots.
- Search with suggestions (the last benchmark candidate) is 3.5.0's `.dsSearchSuggestions`: the
  lines live in the system's suggestion list under `.searchable`, so Tenra's "system search
  only" rule holds. New candidates go in [docs/benchmark.md](../benchmark.md) first.
- What is next (2026-11-24, the docs and Gallery audit of 8.17.1): benchmark round 4's P3
  candidates, each when an app asks for it (docs/benchmark.md 13 a data palette, 14 an exit
  motion, 15 spacing that grows with Dynamic Type, 20 `FormSection(isExpanded:)`,
  `FlowLayout(maxRows:)`, a banner over a sheet, a status dot on `Avatar`, 23 the code of a page's
  configuration in the Gallery), the assistant's list of actions once Tenra shows one, anatomy on
  the pages of composite cards and rows (Platina's CI job here, the issue template, 28, and the
  Gallery's Patterns of whole screens, 24, came in 8.17.4, and Platina's own DesignKit update
  workflow on 2026-11-25); the adoption proposals in [docs/adoption.md](../adoption.md) for the
  app sessions.
- Release numbers given at merge (2026-11, the owner's decision after parallel sessions'
  PRs collided on numbers and on `VERSION`, CHANGELOG.md and docs/components.md): a PR declares
  its release in `.changes/`, the bot numbers, writes and tags it on `main`
  ([docs/releasing.md](../releasing.md)). The PRs open at the switch (#109, #110, #111, #112)
  went out the old way first; one still open the old way (#105) moves its section into a note.
