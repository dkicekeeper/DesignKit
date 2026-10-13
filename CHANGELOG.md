# Changelog

What changed in each DesignKit release, newest first, and how to move an app to it. The same text
is the release's GitHub Release notes and the Gallery's Updates screen.

Each release lists what applies to it, in this order:

- **Added**: new components, parameters, tokens and strings.
- **Changed**: what looks or behaves differently in an app after the bump.
- **Deprecated**: names that still build, with their replacement.
- **Removed**: names that are gone (major releases only).
- **Fixed**: bugs.
- **Migration**: what to change in an app, old → new, with code where the API changes.
- **Gallery and tooling**: the Gallery app, the tests and CI; nothing changes in an app.

Versions follow semantic versioning; apps pin an exact version. A release PR bumps `VERSION` and
adds its section here (CLAUDE.md, "API Stability & Versioning").

## 4.2.0 - 2026-10-13

A hero score at the top of a screen: a half gauge wider than the screen that runs out past both
edges, with a knob on the value, on a gradient of its colour.
[#56](https://github.com/dkicekeeper/DesignKit/pull/56)

### Added

- `HeroHalfGauge(style: .bleed)`: a circle wider than the view, only its top `span` degrees (130
  by default) visible, the arc cut by both edges. It takes the width it is offered (put it edge to
  edge, without `.screenPadding()`) and its height follows from that width. A knob (a white disc,
  the colour inside, a soft shadow) marks the value and rides the sweep; 0 and the maximum sit
  just inside the edges, so the knob shows whole. Zones and the norm are thin notches through the
  arc. `HeroHalfGaugeSkeleton(style:span:)`.
- `HeroHalfGauge(tone:)`: `.onSurface` (the default, as before) or `.onColor`, a white arc and a
  translucent white track for a coloured background.
- `ScoreGaugeCard(style: .hero)`: the top of a screen, not a card. The bleed gauge, the score in
  `AppTypography.display`, the grade and the trend in capsules under it, the subtitle below. With
  `tone: .onColor` (the default for the hero) it lies on a gradient of its colour that reaches up
  under the navigation bar and fades into the page; `.onSurface` draws on the page.
  `ScoreGaugeCardSkeleton(style:)`.
- `ScoreGaugeCard(showsMaximum:)` adds "/100" after the score, and `trend:`
  (`ScoreGaugeCard.Trend(direction:changePercent:caption:)`) a capsule "↗ +17.0% than last month";
  both work in the card too.
- `AppTypography.display`: Inter 72 pt semibold, scaling with `.largeTitle`, for the one number a
  screen is about.

### Migration

- Nothing changes until an app opts in: `style: .card` and `tone: .onSurface` are the defaults.
- A score at the top of a screen → the hero, edge to edge; cards below may rise over the fading
  end of its gradient:

```swift
ScrollView {
    VStack(spacing: AppSpacing.lg) {
        ScoreGaugeCard(score: 84, zoneTicks: [40, 70], grade: "Excellent", color: AppColors.success,
                       subtitle: "Your financial health", style: .hero, showsMaximum: true,
                       trend: .init(direction: .up, changePercent: 17, caption: "than last month"))
        cards
            .screenPadding()
            .padding(.top, -AppSpacing.xxl)
    }
}
```

### Gallery and tooling

- The `HeroHalfGauge` page has Style, Tone and Span controls; the `ScoreGaugeCard` page has Style,
  Tone, "Shows /100" and Trend, and "Open as a screen" shows the hero under a navigation bar with
  cards over its gradient. Typography lists `display`.

## 4.1.0 - 2026-10-13

Benchmark round 3: three things the major design systems have and the apps built by hand.
[#54](https://github.com/dkicekeeper/DesignKit/pull/54)

### Added

- `RatingSummary(average:count:distribution:countLabel:animatesOnAppear:)` (Cards: Content): the
  average in large digits, its stars and the review count, beside a bar per star from the top
  down, in a glass card. `distribution` counts the reviews per star, one star first; `countLabel`
  is the app's own line, so its plurals stay in its strings. `RatingSummarySkeleton(maximum:)`.
- `LoadMoreFooter(state:rows:onLoad:placeholder:)` (Status & Feedback): the end of a list that
  loads in pages. `LoadMoreState.more` asks for the next page as soon as the footer shows,
  `.loading` shows placeholders (`SkeletonRow` by default, or the rows' own skeleton),
  `.failed(message:)` shows the reason or "Couldn't load more" with Retry, `.end` shows nothing.
- `.onReachEnd(of:in:threshold:perform:)`: asks for the next page a few rows before the end, for
  feeds of tall cards.
- `limit:` on `MessageComposer` and `FormTextField`: a count ("980/1000") from 80% of the limit,
  red over it. The composer stops sending over the limit; the field does not cut the text.
- Strings `rating.bar`, `loadMore.failed`, `textInput.characterCount`.

### Migration

- Dalada's `ReviewSummaryView` → `RatingSummary`, the same pixels.
- A hand-made spinner or an `onAppear` on the last row → `LoadMoreFooter`; a failed page now
  shows Retry instead of being dropped.
- A hand-made character count → `limit:`.

```swift
List {
    ForEach(reviews) { ReviewRow(review: $0) }
    LoadMoreFooter(state: hasMore ? .more : .end, onLoad: loadMore) {
        ReviewCardSkeleton()
    }
}

MessageComposer(text: $text, placeholder: "Add a comment…", limit: 1000) { send() }
FormTextField(text: $bio, placeholder: "About you", style: .multiline(min: 3, max: 6), limit: 300)
```

## 4.0.0 - 2026-10-12

A major release that removes the last deprecated name; nothing else changes and no component
looks different. [#53](https://github.com/dkicekeeper/DesignKit/pull/53),
[migration guide](https://github.com/dkicekeeper/DesignKit/blob/main/docs/migration-4.0.md)

### Removed

- `SectionHeader.Style.list`, deprecated since 3.2.0: it was an alias of `.compact`.

### Migration

- `SectionHeader(title, style: .list)` → `SectionHeader(title, style: .compact)`, the same pixels.
  In a `List` or `Form` header the system insets it; on a screen add `.screenPadding()`.
- No deprecated API is left. To check an app (no output: it builds on 4.0 unchanged):

```sh
grep -rn "style: .list" --include=*.swift . | grep SectionHeader
```

## 3.7.0 - 2026-10-12

Deep hues for what an app draws over a map or a photo.
[#52](https://github.com/dkicekeeper/DesignKit/pull/52)

### Added

- `AppColors.Palette` (DesignTokens): 13 deep hues, `blue`, `indigo`, `violet`, `purple`, `pink`,
  `red`, `orange`, `ochre`, `green`, `emerald`, `teal`, `cyan` and `slate`, each with `.color`,
  `.uiColor` (UIKit, MapKit, MapLibre, Core Graphics) and `.rgb`.
- The values are the same in light and dark: a marker image drawn once keeps its colour, where a
  system colour such as `.systemTeal` resolves to the theme that was on.
- White on every hue is at least 3:1, the WCAG minimum for a symbol; all but `orange` (3.6) reach
  4.5. For markers, route and track lines and zone fills; text, status and chrome stay
  `AppColors.Text`, `.Status` and the accent.

### Migration

- A marker or a line in a system colour → a `Palette` hue. Dalada maps its place types, layers
  and zones onto the palette in `MapColors`.

```swift
// Before: resolves to the theme at style load; a white symbol on it is 2.2:1
let fill = UIColor.systemGreen
// 3.7.0: fixed in both themes; a white symbol on it is 5.0:1
let fill = AppColors.Palette.green.uiColor
```

## 3.6.0 - 2026-10-12

Audit round 5: three things the apps still drew by hand.
[#51](https://github.com/dkicekeeper/DesignKit/pull/51)

### Added

- `ItemRow` + `MetaLine` (Rows: Data): a row for an item of the app's own. A symbol on a pale
  circle (`.symbol`) or a bare glyph (`.glyph`), the title with an optional `Badge`, a two-line
  description, lines of facts (`MetaLine` of `MetaItem`s, joined by "·" or set side by side) and
  a trailing accessory. `style: .standard` is Dalada's trips, places, articles and gear, `.large`
  is Tenra's backups and subcategories; `titleFont:` keeps a title in another font.
  `ItemRowSkeleton`.
- `PendingItemCard` (Status & Feedback): an item waiting in an upload queue. The title, a running
  time, "waiting" or "couldn't upload" with the reason, async Retry and Delete (Delete asks
  first; `discardConfirmation:` words the question), and the item's content in a slot.
  `PendingItemCardSkeleton`.
- `CurrencyRow(_:isSelected:isLocked:)` (Amounts & Currency): `CurrencyList`'s row, now public;
  `isLocked` greys the check of an account's own currency.
- Strings `pending.waiting`, `pending.failed`, `common.retry`, `pending.discard`,
  `pending.discard.confirm`.

### Changed

- At accessibility text sizes a `MetaLine` puts its facts one under another, without dots (the
  1.3.0 rule): the facts under Dalada's trips, places, articles and catches stack.
- The "·" in Dalada's trip and gear rows has a fixed 4 pt spacing instead of a space character.
- The pending report card's title is one line; Tenra's subcategory row takes taps across its
  whole width.

### Migration

- Dalada: trip, place, article and gear rows → `ItemRow(style: .standard)`; the queued trip and
  report cards → `PendingItemCard`.
- Tenra: backup and subcategory rows → `ItemRow(style: .large)`; the quick-access currency rows →
  `CurrencyRow`.

```swift
ItemRow(trip.title, detail: trip.note,
        meta: [MetaLine([.text(trip.dateText), .label(trip.distanceText, systemImage: "figure.walk")])],
        leading: .symbol("map")) {
    DisclosureChevron()
}
```

## 3.5.1 - 2026-10-12

A patch release. [#50](https://github.com/dkicekeeper/DesignKit/pull/50)

### Fixed

- A search suggestion's subtitle takes up to two lines: at the largest text size "Reservoir ·
  70 km" lost the distance behind an ellipsis. The default size is unchanged.

### Gallery and tooling

- The `formSection` snapshot shows a time instead of a date: the system's compact `DatePicker`
  labelled the same date differently from day to day on the same runner.

## 3.5.0 - 2026-10-12

Search with suggestions, in the system's own suggestion list; the search itself stays the
system's. [#49](https://github.com/dkicekeeper/DesignKit/pull/49),
[#48](https://github.com/dkicekeeper/DesignKit/pull/48)

### Added

- `.dsSearchSuggestions(text:recent:suggestions:isLoading:limit:onSearch:onSelect:)`, after
  `.searchable`. With an empty field: the recent queries under "Recent", with Clear; a swipe
  removes one. While typing: up to 3 recent queries and up to `limit` (5) of the app's
  `SearchSuggestion`s that contain the text, the typed part in bold. A tap fills the field,
  records the query and hides the list until the text changes; ↖ fills the field to keep typing;
  `isLoading` draws skeleton lines.
- `RecentSearches` (DesignSupport): newest first, no duplicates, 8 by default, `RawRepresentable`
  for `@AppStorage`. `SearchMatch`.
- `SearchSuggestion`, `SearchSuggestionRow` (`.recent`), `SearchSuggestionsContent`,
  `SearchSuggestionRowSkeleton`.
- Five `search.*` strings.

### Migration

- Add the modifier after `.searchable`; the app keeps its `RecentSearches`:

```swift
@AppStorage("history.recentSearches") private var recent = RecentSearches()

List { … }
    .searchable(text: $query)
    .dsSearchSuggestions(text: $query, recent: $recent,
                         suggestions: categories.map { SearchSuggestion($0.name, icon: .sfSymbol($0.symbol)) })
```

### Gallery and tooling

- The home screen counts the components of each section from its pages; a component page lists
  the values of its `style:` parameter ("4 styles: default · compact · large · card").
- docs/design-system.md describes the apps' screens as they are built today.

## 3.4.0 - 2026-10-10

Amounts in proportional figures, and the hero glow in shades of one colour, as Tenra's owner
asked. [#46](https://github.com/dkicekeeper/DesignKit/pull/46)

### Added

- `AuroraBackground.palette(around:spread:)`: `spread` defaults to 60, so `AuroraBackground` and
  `VoiceWave` are unchanged.

### Changed

- `AppTypography.numbers(_:)` returns the style as it is: from 1.8.0 to 3.3.0 it added tabular
  figures, and every amount read as a monospaced font. `FormattedAmountText`,
  `AmountDigitDisplay`, `TrendBadge` and the chart readouts change.
- Counters that must keep their width while they change (`StatTile`, `StepperRow`,
  `CalculationCard`, `AvatarGroup`) keep `.monospacedDigit()` themselves, unchanged.
- `.accentGlow(style: .aurora)` (Tenra's `heroAccentGlow`) draws one colour in several shades,
  where it took hues ±30° and ±60° from the tint: a red icon's glow no longer turns orange and
  purple.

### Migration

- A number of the app's own that changes in place and must keep its width (a timer, a counter) →
  `.monospacedDigit()` on it: `AppTypography.numbers` no longer does it.

## 3.3.0 - 2026-10-09

`PackedCircleIcons`: a softer gloss, and two new styles, a fan of cards and an orbit.
[#47](https://github.com/dkicekeeper/DesignKit/pull/47)

### Added

- `PackedCircleIcons(style: .fan)`: playing cards fanned along an arc, the largest amount in the
  middle, in front and highest, the rest by amount to either side, smaller down to 0.8. A symbol
  is white on a card of its tint with corner pips; a logo sits on a white card with pips in its
  main colour; "+N" is a grey card. The cards are dealt one after another, and every 4.5 s a light
  runs across them.
- `PackedCircleIcons(style: .orbit)`: the largest amount is a marble in the middle; the rest turn
  on a slanted orbit once in 28 s, smaller and darker on the far side, passing behind the middle
  one.
- Both keep the 120 × 100 box, the order by amount and the "+N", and stand still under Reduce
  Motion, while the system saves resources and under `.designKitMotion(false)`.
  `PackedCircleIconsSkeleton(containerWidth:style:)` draws each.

### Changed

- `.glossy` shines less: highlight 0.9 → 0.62, rim light 0.7 → 0.42, coloured shadow 0.5 → 0.38,
  light from below 0.4 → 0.3 (`MarbleGlossMetrics`). Tenra's home cards change.

## 3.2.0 - 2026-10-09

`SectionHeader` shows symbols in every style, and `.list` is folded into `.compact`.
[#45](https://github.com/dkicekeeper/DesignKit/pull/45)

### Added

- `SectionHeader(_:systemImage:trailingSystemImage:tint:style:)`: `trailingSystemImage` sits right
  after the title, in the tertiary grey: `chevron.forward` for a header that leads somewhere
  (wrap it in a `NavigationLink`), `info.circle` for one that explains. `tint` colours both
  symbols.
- `.compact` shows the action at the end of the line, which `.list` dropped.
- `SectionHeaderSkeleton(showsIcon:)`.

### Changed

- `systemImage` shows in `.default`, `.compact` and `.card` too, in the title's font: it showed in
  `.large` only, and the other styles dropped it without a word.
- `.compact` has no padding of its own, as `.list` had (no app used `.compact`).
- Both symbols are hidden from VoiceOver, `.large`'s too (VoiceOver read the symbol's name).

### Deprecated

- `SectionHeader.Style.list` → `.compact`, the same label (removed in 4.0.0).

### Migration

- `style: .list` → `style: .compact`, no visual change.
- A header that passed `systemImage:` to `.default`, `.compact` or `.card` now shows it: remove
  the argument to keep the screen as it was.
- A `.compact` header on a screen, outside a `List` or `Form` → add `.screenPadding()`.

## 3.1.0 - 2026-10-09

Photos load with a skeleton, and Dalada's last form helpers.
[#44](https://github.com/dkicekeeper/DesignKit/pull/44)

### Added

- `RemotePhoto(key:url:contentMode:placeholderKey:)` (Media): a photo loaded by its address. A
  grey skeleton with the shimmer while it loads (or the small version under the shimmer when the
  app has it), then the photo comes into focus; the photo symbol with no URL or after a failure.
  `RemotePhotoSkeleton`.
- `DesignKitPhotoLoader` host hook (DesignSupport): `loader(key, url)` and `cached(key)`, so the
  app keeps its own cache, signed links and network. Without a loader, `RemotePhoto` downloads
  the URL itself and keeps nothing.
- `ActionRowLabel(_:systemImage:tint:titleColor:config:)` (Rows): the look of an action row as
  the label of a control that is not a `Button` (`PhotosPicker`, `ShareLink`, `Link`). Its init is
  `nonisolated`, since `PhotosPicker` builds its label off the main actor.
- `ChipPicker(inset:)`: a chip row inside a `FormSection` card; the title and the first chip line
  up with the card's rows, and the chips still scroll edge to edge.
- `RowConfiguration` is `Sendable`.

### Migration

- Dalada: its `RemotePhoto` (a spinner) → DesignKit's over its `PhotoCache`; `PickerRowLabel` →
  `ActionRowLabel`; `FormChipRow` → `ChipPicker(inset:)`.

```swift
// App.init()
DesignKitPhotoLoader.loader = { key, url in await PhotoCache.shared.image(for: key, url: url) }
DesignKitPhotoLoader.cached = { key in PhotoCache.shared.cachedImage(for: key) }
```

### Gallery and tooling

- Snapshot recording rebases the bot's commit and retries the push; a recording whose build
  failed fails the job.

## 3.0.0 - 2026-10-08

A major release: every name 2.x deprecated is removed, a card's glass is drawn behind its
content, and form rows for Dalada. [#43](https://github.com/dkicekeeper/DesignKit/pull/43),
[migration guide](https://github.com/dkicekeeper/DesignKit/blob/main/docs/migration-3.0.md)

### Added

- `StepperRow(icon:title:value:in:step:format:)`: a whole number in a form, its value on one line.
- `NavigationPickerRow(icon:title:selection:options:)`: a choice from a long list; it pushes
  checkmark rows, searchable past 12 options.
- `FormTextField(style: .row)` and `.rowMultiline(min:max:)`: a field that fills a `FormSection`
  row.
- `DatePickerRow(minDate:)`.
- `EditSheetContainer(isSaving:)`: a spinner in place of Save, Cancel disabled while saving;
  `saveTitle:` names the checkmark for VoiceOver ("Publish", "Send").
- `ToggleSettingsRow`, `ActionSettingsRow` and `CheckmarkRow` take `config:` (`.standard` pads
  them for a `FormSection` card); `icon` is optional on the toggle and action rows.

### Changed

- `cardStyle()` draws its Liquid Glass behind the content instead of applying it to the content.
  The glass blended each overlapping layer of the content into the ones under it, so markers over
  arcs looked translucent and labels on pale capsules shifted colour. The card itself is
  unchanged; its content keeps its exact colours.
- A glass shape inside a card keeps its own rim and sheen: `HeroBarPair`'s "now" bar in a
  `MetricCard` was a flat fill.
- `TransactionRow` at accessibility text sizes: the amounts go under the text instead of
  squeezing the title ("Groceri / es").

### Removed

- The `…View` names of 2.0: `AvatarView`, `BadgeView`, `ConvertedAmountView`,
  `AmountPercentageView`, `DateButtonsView`, `SegmentedPickerView`, `EmptyCardView`,
  `EmptyStateView`, `IconView`, `NotificationPermissionView`, `PackedCircleIconsView`,
  `RatingView`, `SectionHeaderView`, `SkeletonView` and their skeletons.
- `BalanceRow`, `BreakdownRow`, `InsightEntityRow`, `ProgressRingRow` and their skeletons.
- `DateSectionHeaderView`, `SettingsSectionHeaderView`, `FormattedAmountView`,
  `LoadingButtonLabel`, `BulkDeleteButton`, `EntityActionButton`, `PermissionPrimerView`,
  `PromptSheet(height:)`.
- `GradientOrbsBackground`, `Orb`, `SiriGlow`, `SiriWave`, `SiriGlowView`,
  `SiriWaveRecordingView`.
- `.appButton`, `.primaryButton`, `.secondaryButton`, `AppButtonAppearance`, `AppButtonRole`,
  `AppButtonSize`, `AppIconSize.Tile.xs`, `CategoryColors.hexColor(for:opacity:)`.

### Migration

Each removed name was deprecated in 2.x with a fix-it naming its replacement; the migration guide
has the full table. Neither app used a removed name when 3.0.0 shipped, so the move was the pin.

- The `…View` names → the same name without `View` (`IconView` → `Icon`).
- `BalanceRow`, `ProgressRingRow`, `BreakdownRow`, `InsightEntityRow` → `AmountRow` (2.1.0).
- `.primaryButton()` / `.secondaryButton()` / `.appButton` → `.dsButton()` /
  `.dsButton(.secondary)`, or `DSButton`.
- `LoadingButtonLabel` → `DSButton(isLoading:)`; `BulkDeleteButton` →
  `DSButton(role: .destructive, shape: .capsule)`; `EntityActionButton` →
  `DSButton(iconPlacement: .top)`.
- `SettingsSectionHeaderView` → `SectionHeader(style: .compact)`; `DateSectionHeaderView` →
  `SectionHeader(style: .card)`; `FormattedAmountView` → `FormattedAmountText`.
- `PermissionPrimerView` → `PromptSheet(detent: nil, dismissesOnAnswer: false)`.
- `GradientOrbsBackground` → `AuroraBackground(_ spots:)`; the `Siri*` names → `EdgeGlow(level:)`.
- `AppIconSize.Tile.xs` → `AppIconSize.xxl`; `CategoryColors.hexColor(for:)` → `color(for:)`.

## 2.9.0 - 2026-10-08

The last generic views Tenra drew itself, glossy `PackedCircleIcons`, and solid gauge markers.
[#42](https://github.com/dkicekeeper/DesignKit/pull/42)

### Added

- `TransactionRow`: a money movement. A 44 pt icon (a category symbol or a merchant logo, with an
  optional badge), the category with its details and account or a transfer between two accounts,
  the amounts on the trailing edge (an equivalent at 70%, a transfer's two legs); `isPending` dims
  a future one, and the icon can be a zoom source.
- `SnapCardPicker`: full-width cards in a snapping row; the centred card is the selection.
- `OptionCard`, `OptionCardPicker`: an option as a picture, with a check and an accent outline
  when chosen.
- `StreamingText`: text arriving word by word with a blur-slide; a refined word keeps its
  identity, and `highlights` tint ranges.
- `DateRangePickerSheet`: From and To calendars that keep the range valid, with Cancel and Apply.
- `.cascadeIn(index:)`: cards that arrive together fade in and rise 12 pt, 80 ms apart.
- `PagerArrows`: a chevron on each side of a paged content, disabled at the ends.
- `.progressOverlay(isPresented:title:message:)`: the screen dims under a material panel with a
  spinner, a title and a message.
- `FlowLayout(alignment:)` centres or right-aligns each row.
- `PackedCircleIcons(style: .flat)` keeps the previous look.
- Strings `button.apply`, `pager.previous`, `pager.next`, `timeFilter.*`.

### Changed

- `PackedCircleIcons` are glossy marbles: a white symbol on a marble of its colour, or the logo as
  the marble's skin, a highlight, a rim light and shade over both, a shadow of its colour under
  each. The marbles burst out one after another, then sway by up to 2 pt (still under Reduce
  Motion). Tenra's home cards change.

### Fixed

- `ScoreGaugeCard`'s zone markers were translucent: the card's glass blended the gauge's layers.
  `HeroHalfGauge` draws into one layer, so its markers are solid and its arc is its exact colour.

### Migration

- Tenra keeps thin adapters: `TransactionCardView` → `TransactionRow`, `AccountSelectorView` and
  `CategoryCardSelectorView` → `SnapCardPicker`, `HomeBackgroundPicker` → `OptionCardPicker`,
  `AnimatedTranscriptionText` → `StreamingText`, the custom period → `DateRangePickerSheet`, the
  backup overlay → `.progressOverlay`.
- To keep the old circles: `PackedCircleIcons(…, style: .flat)`.

## 2.8.0 - 2026-10-08

Photos, share pictures, a live session bar, downloads and articles from Dalada.
[#41](https://github.com/dkicekeeper/DesignKit/pull/41)

### Added

- `PhotoTile`, `PhotoStrip`, `PhotoGrid` (`.rounded`, `.edgeToEdge`) and `PhotoCarousel`: photos
  as tiles, a sideways row, a grid and a paged 4:3 frame.
- `PhotoViewer`: photos full screen, paged, with an optional caption band and a menu per photo;
  pinch to zoom up to 4×, drag while zoomed, double-tap, VoiceOver zoom.
- `ShareCardFrame`, `ShareCardStat`, `ShareCard.Format` and `ShareCard.Style`: a picture for
  Stories or a post. `ShareCardSheet`: pick a format, see the picture, share it.
- `LiveSessionBar` and `.liveSessionAccessory`: a pulsing recording dot, the running time, a
  detail and a chevron, in the tab bar's accessory (iOS 26.1).
- `DownloadRow`: something to download for offline use, in five states: available, downloading,
  paused, downloaded, failed.
- `ArticleBody`: an article's headings, paragraphs, lists and notes, with inline Markdown.
- `ChipPicker(allTitle:)`: an "All" chip in front, selected while nothing is picked.
- `PersonRow(detail:style:)`: a third line, and `style: .card` for the person at the top of
  their profile.
- Strings `photo.*`, `share.*`, `common.close`, `download.*`.

### Changed

- `ShareCardSheet` shows the card's skeleton while it loads, where Dalada's sheet had a spinner.
- The recording dot stops pulsing under Reduce Motion and `.designKitMotion(false)`.

### Migration

- Dalada: `PhotoDraftThumbnail` → `PhotoTile`; `ReportPhotoStrip`, `PhotoDraftStrip` →
  `PhotoStrip`; `PostPhotoCarousel` → `PhotoCarousel`; `PlacePhotoViewer` → `PhotoViewer`;
  `ShareCardFormat`, `ShareCardStyle` → `ShareCard.Format`, `ShareCard.Style`; `TripMiniPlayer` →
  `LiveSessionBar`; `OfflineRegionRow` → `DownloadRow`; `ArticleBlockView` → `ArticleBody`;
  `ProfileHeader` → `PersonRow(style: .card)`.

## 2.7.0 - 2026-10-08

Cards that use the effects of 2.3.0 and 2.6.0, off by default.
[#40](https://github.com/dkicekeeper/DesignKit/pull/40)

### Added

- `BalanceCard(isLive:)`: the amount is a `LiveAmountText`; it rolls up from zero when the card
  first appears and flashes green or red when the balance changes.
- `ScoreGaugeCard(decodesScore:)`, `ScoreCard(decodesScore:)`: the score is a `ScrambleText` that
  decodes as the card appears and whenever it changes. Leave it off in a lazy feed, where
  scrolling back to the card plays it again.

## 2.6.0 - 2026-10-08

Four effects for surfaces and moments; nothing changes in an app until it uses one.
[#39](https://github.com/dkicekeeper/DesignKit/pull/39)

### Added

- `.holographic(strength:)`: a holographic foil; rainbow bands slide across the surface as the
  finger moves, with a sheen where the light falls. Pairs with `.interactiveTilt`.
- `.transition(.dissolve)`: the view breaks into dust as it is removed (a fade under Reduce
  Motion), for deleting something the person owned.
- `ScrambleText(_:)`: each character flickers through random ones of its kind and settles, left
  to right; the final text sets the width, and VoiceOver reads it.
- `.spotlightAnchor(_:)` and `.spotlight(_:message:onTap:)`: a coach mark that dims the screen
  except a cut-out round one view, with a `Tooltip` beside it.
- The shaders ship compiled, so apps need no Metal Toolchain.

## 2.5.0 - 2026-10-08

Still light for backgrounds, drawn without blur: a moving background makes every glass card on
the screen redraw each frame. [#38](https://github.com/dkicekeeper/DesignKit/pull/38)

### Added

- `AuroraBackground(_ spots:)`: weighted pools of colour (`AuroraBackground.Spot(color:weight:)`)
  in a still 5×5 mesh; when the data changes it flows to its new shape in 0.6 s.
- `AuroraBackground(colors:intensity:motion:grain:)`: `motion: .drift`, as before, or `.still`.
- `.accentGlow(_:edge:intensity:style:drifts:)`: `.aurora`, the new default, is a band of mesh
  light in the tint and its neighbours; `.soft` keeps the blurred circle.
- `.grain(_:)`: a fine still grain against banding in smooth gradients on a dark screen.

### Changed

- `.accentGlow` draws the aurora band instead of a blurred circle (Tenra's `heroAccentGlow` and
  `onboardingAccentGlow`).
- `AuroraBackground` carries a fine grain.

### Deprecated

- `GradientOrbsBackground` → `AuroraBackground(_ spots:)`; `Orb(color:weight:)` →
  `AuroraBackground.Spot(color:weight:)` (removed in 3.0.0).

### Migration

- The old blurred glow, if a screen needs it: `.accentGlow(tint, style: .soft)`.

```swift
// Before
GradientOrbsBackground(categories.map { Orb(color: $0.color, weight: $0.share) })
// 2.5.0
AuroraBackground(categories.map { AuroraBackground.Spot(color: $0.color, weight: $0.share) })
```

## 2.4.0 - 2026-10-07

The voice made visible. [#37](https://github.com/dkicekeeper/DesignKit/pull/37)

### Added

- `VoiceWave(level:phase:style:)`: `.ribbons`, four ribbons of aurora light that rise with each
  syllable, or `.orb`, a liquid sphere whose rim ripples; `.thinking` settles it while the words
  are understood.
- `EdgeGlow(level:)`: light along the screen's edges that widens, brightens and speeds up with
  the voice; one Metal pass, no blur.
- `.thinkingShimmer(isActive:)`: a band of aurora colour runs through text while the app works
  ("Listening…").
- `.borderBeam(beams:)`: `beams: 2` runs a second comet opposite the first.
- The level is the app's microphone RMS, 0…1: both views smooth it (fast up, slow down) and
  breathe on their own without one.

### Changed

- `.borderBeam`: the comet runs along the border itself, at one speed and length on every side
  and corner, with a bright head and a fading tail (Tenra's voice-input cards).
- `SiriWave()` draws `EdgeGlow`: one shader pass instead of a blurred mesh recomputed 30 times a
  second (Tenra's voice input).

### Deprecated

- `SiriGlow`, `SiriWave`, `SiriGlowView`, `SiriWaveRecordingView` → `EdgeGlow` (removed in 3.0.0).

### Migration

```swift
// Before
.overlay { if isRecording { SiriWave() } }
// 2.4.0: follows the voice when it has the microphone's level
.overlay { if isRecording { EdgeGlow(level: recorder.level) } }
```

## 2.3.1 - 2026-10-07

A patch release. [#36](https://github.com/dkicekeeper/DesignKit/pull/36)

### Fixed

- `ProgressRing(celebratesCompletion: true)` drew the budget palette, so a goal at 100% was red
  next to its checkmark. A goal ring is one green hue at any fill and past 100%; budget rings are
  unchanged.

## 2.3.0 - 2026-10-07

Motion round 2: data that moves, moments of completion, haptics paired with motion, depth, and
one Metal effect. [#35](https://github.com/dkicekeeper/DesignKit/pull/35)

### Added

- `GlassActionMenu`: a floating Liquid Glass button that flows open into its actions.
- `LiveAmountText` and its skeleton: the digits roll up from zero on first appearance; a change
  flashes green or red.
- `.chartDrawIn(delay:)`: the chart is revealed from its leading edge, once.
- `.completionMoment(isComplete:tint:in:)`: a glow of the shape flares and fades with the success
  haptic.
- `ProgressRing(celebratesCompletion:)`: a goal ring; at 100% a checkmark draws itself in.
- `SkeletonReveal` and `.skeletonReveal`: the skeleton fades out while the content comes into
  focus from a light blur.
- `HapticCue` (`.hapticCue`, `HapticManager.play`): haptics by meaning: tap, select, tick,
  confirm, warn, fail, celebrate.
- `.scrollHero(parallax:fades:)`: a detail screen's hero stretches on pull, drifts slower and
  fades as it scrolls away.
- `.ripple(trigger:at:)` and `.rippleOnTap()`: a ripple through the view itself, a Metal effect
  that ships compiled.

### Changed

- `LineChart`, `BarChart` and `HeroSparkline` draw in from the left.
- Completing a checklist or reaching a `TargetProgressCard` target makes its bar glow once, with
  the success haptic.
- `FinanceCard` reveals its amount from the skeleton with a blur.
- `.celebration` plays the celebration pattern: success, then two rising taps.
- `SegmentedPicker` ticks as its segment moves; `SliderRow` ticks on every step, or at either end
  of a smooth slider.
- `HeroSymbol` and `EmptyState`'s icon are drawn in an SF Symbols 7 gradient of their tint.
- In `OnboardingPager` the hero symbol lags behind its page as it swipes.
- Under Reduce Motion the movement goes and the haptics stay.

## 2.2.0 - 2026-10-07

Motion and effects, rich but light; the rules are in
[docs/motion.md](https://github.com/dkicekeeper/DesignKit/blob/main/docs/motion.md).
[#34](https://github.com/dkicekeeper/DesignKit/pull/34)

### Added

- Springs by purpose: `AppAnimation.snappy` (an answer to a touch), `.smooth` (content moving),
  `.bouncy` (a confirmation) and `.expressive` (a moment that matters).
  `AppAnimation.motion(_:reduceMotion:)` returns `nil` when motion is off.
- `MotionBudget`: feedback 0.25 s, entrance 0.35 s, celebration 1.4 s, stagger 0.04 s per item
  and 0.3 s in total.
- `.designKitMotion(false)` stills all of DesignKit's motion below a view.
- SF Symbols in motion: `.drawOnAppear()`, `.symbolCue(_:trigger:)`, `.symbolCueOnAppear`,
  `.symbolPulse(_:isActive:)`, `.symbolMagicReplace()`.
- Transitions that know Reduce Motion: `.popIn`, `.riseIn`, `.textReveal` and
  `.textRevealOnAppear()`.
- Effects: `.celebration(trigger:)`, `.sparkleBurst(trigger:)`, `.shine(trigger:in:)`,
  `.attentionPulse(trigger:in:)`, `AuroraBackground`, `.interactiveTilt(in:)`, `.scrollReveal()`,
  `TypingIndicator` (string `typing.indicator`).

### Changed

- Symbols draw on in `HeroSymbol` (`PromptSheet`, onboarding), `EmptyState`, `StepTracker`'s done
  steps and a complete checklist.
- `DSButton`'s symbol bounces on every press; `MessageBanner` bounces on success and wiggles on an
  error or a warning; `EmptyState(.error)` wiggles.
- `AmountVisibilityToggle`, `SelectionIndicator` and `ReactionButton` change their symbol with
  Magic Replace; `TrendBadge`'s arrow replaces; `ReactionButton` sparkles.
- Still pictures don't change.

## 2.1.0 - 2026-10-07

`AmountRow` merges the four amount rows, and limit rows line up.
[#33](https://github.com/dkicekeeper/DesignKit/pull/33)

### Added

- `AmountRow`: one row with an icon, a name and money. `style: .list` (a `List` row, the name in
  `h4`, the value under it) or `.info` (`UniversalRow(.info)`, the value on the trailing edge,
  stacked at accessibility sizes); `leading:` `.icon`, `.tinted` or `.none`; `value:` `.amount`,
  `.share` or `.limit`; `detail:`, `accessory:` (`.chevron`, `.systemImage`) and `subtitle:` (text
  or a view). `AmountRowSkeleton(style:showsRing:showsDetail:)`.
- `CategoryColors.color(for:opacity:)`.

### Changed

- A `.limit` row keeps the ring's room (52 pt) around its icon with or without a limit: a
  category without a budget sat 8 pt to the left in a list of both.

### Deprecated

- `BalanceRow`, `ProgressRingRow`, `BreakdownRow`, `InsightEntityRow` and their skeletons →
  `AmountRow` (removed in 3.0.0).
- `CategoryColors.hexColor(for:opacity:)` → `color(for:opacity:)`: it returns a colour.

### Migration

```swift
// BalanceRow(iconSource: icon, title: name, amount: balance, currency: code, detail: detail)
AmountRow(name, leading: .icon(icon), value: .amount(balance, color: AppColors.Text.secondary),
          currency: code, style: .list, detail: detail)

// ProgressRingRow(iconSource: icon, color: tint, title: name, progress: progress, currency: code)
AmountRow(name, leading: .tinted(icon, tint), value: .limit(progress), currency: code, style: .list)

// BreakdownRow(iconSource: icon, color: tint, title: name, subtitle: s, amount: a, currency: code,
//              percentage: p, showsChevron: true)
AmountRow(name, subtitle: s, subtitleLineLimit: 1, leading: .tinted(icon, tint),
          value: .share(a, percentage: p), currency: code, accessory: .chevron)

// InsightEntityRow(iconSource: icon, title: name, subtitle: s, amount: a, currency: code,
//                  amountColor: c, amountCaption: caption)
AmountRow(name, subtitle: s, leading: .icon(icon), value: .amount(a, color: c, caption: caption),
          currency: code)
```

## 2.0.0 - 2026-10-07

A major release: one component per thing, names without `View`, and the fixes from the owner's
review. [#32](https://github.com/dkicekeeper/DesignKit/pull/32),
[migration guide](https://github.com/dkicekeeper/DesignKit/blob/main/docs/migration-2.0.md)

### Added

- `DSButton`: a title with an icon `.leading`, `.trailing`, `.top` (a tile) or `.only`;
  appearance, role and size; shape `.automatic`, `.capsule` or `.roundedRectangle`; `fullWidth`;
  `isLoading` (a spinner in the same width, taps blocked); haptics. `.dsButton(_:role:size:disabled:)`
  styles a hand-built label.
- `Tooltip` and `.tooltipAnchor(_:gap:)`: an opaque bubble with a tail.
- `SectionHeader` styles `.list` and `.card`.
- `PromptSheet`: an async `onPrimary` with a loading state, `detent`, `dismissesOnAnswer`.
- `AppIconSize.xxl` is a 40 pt glyph.

### Changed

- `PromptSheet` and the permission primers: a 104 pt symbol disc, an `h2` title, a `body` message,
  `DSButton`s and a `.medium` sheet (Tenra's rating survey was 340 pt with a 44 pt symbol).
- `SegmentedPicker`: no interactive glass over the system control, so a quick tap moves the
  selection.
- `AvatarGroup`: an opaque disc under each avatar; the one behind no longer shows through.
- `PackedCircleIcons`: a symbol on a pale disc of its tint, where it was grey.
- `HeroBarPair`: the tapped amount is in an opaque `Tooltip` touching the bar, where it was a pale
  pill 30 pt above it.

### Deprecated

- Names without `View`: `SectionHeaderView` → `SectionHeader`, `EmptyStateView` → `EmptyState`,
  `EmptyCardView` → `EmptyCard`, `AvatarView` → `Avatar`, `BadgeView` → `Badge`, `RatingView` →
  `Rating`, `SegmentedPickerView` → `SegmentedPicker`, `SkeletonView` → `Skeleton`, `IconView` →
  `Icon`, `PackedCircleIconsView` → `PackedCircleIcons`, `DateButtonsView` → `DateButtons`,
  `ConvertedAmountView` → `ConvertedAmount`, `AmountPercentageView` → `AmountPercentage`,
  `NotificationPermissionView` → `NotificationPermissionPrompt`, `SiriGlowView` → `SiriGlow`,
  `SiriWaveRecordingView` → `SiriWave`, and their skeletons.
- `.appButton` → `.dsButton`; `.primaryButton()` → `.dsButton()`; `.secondaryButton()` →
  `.dsButton(.secondary)`.
- `LoadingButtonLabel`, `BulkDeleteButton`, `EntityActionButton` → `DSButton`.
- `SettingsSectionHeaderView` → `SectionHeader(style: .list)`; `DateSectionHeaderView` →
  `SectionHeader(style: .card)`.
- `FormattedAmountView` → `FormattedAmountText`.
- `PermissionPrimerView` → `PromptSheet(detent: nil, dismissesOnAnswer: false)`;
  `PromptSheet(height:)` → `detent:`.
- `AppIconSize.Tile.xs` → `AppIconSize.xxl`.

### Removed

- `AppIconSize.avatar`, `categoryIcon`, `mega`, `budgetRing`, `ultra`, and the 1.x `xxl` (44) and
  `xxxl` (48), deprecated since 1.13.0.
- `BrandLogoView` → `Icon(source: .brandService(name))`.

### Migration

The guide has a `sed` for the renames and a table for each family. The usual cases:

```swift
// Before
Button { save() } label: { Text("Save").frame(maxWidth: .infinity) }.primaryButton()
// 2.0
DSButton("Save", fullWidth: true) { save() }

// Before
Button { save() } label: { LoadingButtonLabel("Save", systemImage: "checkmark", isLoading: isSaving) }
    .primaryButton(disabled: isSaving)
// 2.0
DSButton("Save", systemImage: "checkmark", isLoading: isSaving) { save() }

// Before
EntityActionButton(title: "Delete", systemImage: "trash", role: .destructive) { delete() }
// 2.0: the same pixels
DSButton("Delete", systemImage: "trash", iconPlacement: .top, role: .destructive) { delete() }

// Before
DateSectionHeaderView(dateKey: day)
// 2.0
SectionHeader(day, style: .card)
```

## 1.15.0 - 2026-10-07

An action at the end of a section header, `SliderRow`, and the components on the semantic
colours. [#31](https://github.com/dkicekeeper/DesignKit/pull/31)

### Added

- `SectionHeaderView(_:systemImage:style:trailing:)`: an action at the end of the line ("All" as
  a `NavigationLink`, a button, a spinner), in `bodySmall`, inside the style's padding.
  `SectionHeaderViewSkeleton(style:showsTrailing:)`.
- `SliderRow`: a title with an optional symbol, the value on the trailing edge, the slider and an
  optional hint; the app formats the value. `SliderRowSkeleton(showsHint:)`.

### Changed

- The components use the semantic colour groups (`AppColors.Background.base`, `.Text.primary`, …)
  instead of the flat names: the same values, no visual change.

### Migration

- Dalada's hand-made header lines → the `trailing:` slot; Tenra's `OpacitySliderRow` → an adapter
  over `SliderRow`.

```swift
SectionHeaderView("Trips") {   // SectionHeader since 2.0
    NavigationLink("All") { TripsList() }
}
```

## 1.14.0 - 2026-10-07

The "≈" line under `CurrencyAmountInput` is in the account's currency, and the latest input wins.
[#30](https://github.com/dkicekeeper/DesignKit/pull/30)

### Added

- `CurrencyAmountInput(…, equivalentCurrency:)`: the account's currency. An amount in another
  currency shows its value in the account's currency; an amount in the account's own foreign
  currency shows its base-currency value; an amount in the base currency shows no line. `nil`,
  the default, is the base currency, as before.

### Fixed

- When a conversion failed the line kept the previous number, and with no converter it spun
  forever; it now disappears when no rate comes back.
- Two updates could overwrite each other, so a slow older conversion replaced a newer one; only
  the latest input's result is kept.
- After a currency change the line shows the cached-rate value (`convertSync`) at once, or a
  spinner, never the old currency's number; it converts at once when it first appears.

### Migration

```swift
CurrencyAmountInput(amount: $amount, currency: $currency, baseCurrency: "KZT",
                    equivalentCurrency: account.currency, currencies: currencies)
```

## 1.13.0 - 2026-10-07

Gallery v2, icon sizes named like spacing, and sources by what they do.
[#29](https://github.com/dkicekeeper/DesignKit/pull/29)

### Added

- `AppIconSize` has two scales named like `AppSpacing`: glyphs `xs` 12, `sm` 16, `md` 20, `lg` 24,
  `xl` 32; tiles, an icon with its own backing, `AppIconSize.Tile.xs` 40, `sm` 44, `md` 48, `lg`
  52, `xl` 64, `xxl` 72, `xxxl` 80.

### Deprecated

- `AppIconSize.avatar`, `xxl` (44), `xxxl` (48), `categoryIcon`, `mega`, `budgetRing`, `ultra` →
  `AppIconSize.Tile` (removed in 2.0.0).
- `BrandLogoView` → `IconView(source: .brandService(name), style: .roundedSquare(size:))`, the
  same look (removed in 2.0.0).

### Migration

- `.avatar` → `Tile.xs` (40), `.xxl` → `Tile.sm` (44), `.xxxl` → `Tile.md` (48), `.categoryIcon`
  → `Tile.lg` (52), `.mega` → `Tile.xl` (64), `.budgetRing` → `Tile.xxl` (72), `.ultra` →
  `Tile.xxxl` (80). The fix-its do it; the values are the same.
- `primaryButton()` is `appButton()`, `secondaryButton()` is `appButton(.secondary)`, and `.bounce`
  is the press feedback of tappable cards and rows.

### Gallery and tooling

- Gallery v2: six foundations and 17 component sections, by what a component does
  ([docs/gallery-structure.md](https://github.com/dkicekeeper/DesignKit/blob/main/docs/gallery-structure.md)).
  Every component has a page with a header, a light and dark canvas, controls for its parameters,
  a state switch (Loading is its skeleton) and usage notes.
- `Sources/DesignComponents/` folders follow the sections. Module and type names are unchanged.

## 1.12.0 - 2026-10-07

`MessageComposer`, and the community and progress components from Dalada.
[#27](https://github.com/dkicekeeper/DesignKit/pull/27),
[#28](https://github.com/dkicekeeper/DesignKit/pull/28)

### Added

- `MessageComposer` and `MessageQuote`: Liquid Glass that grows to five lines, the send button
  inside it (grey while blank, a spinner while sending), the message being answered above the
  text with a × to remove it, the send error above the field; `.disabled(true)` greys it, the
  placeholder saying why. Strings `composer.send`, `composer.cancelQuote`.
- `PersonRow`, `CommentRow`, `ThreadCard`, `ReviewCard`, `ReactionButton`.
- `AchievementMedal`, `AchievementTile`, `AchievementProgressRow`.
- `ChecklistRow`, `ChecklistSummaryRow`, `StatsStrip`, `StreakCard`.
- `ThumbnailCard`, `ThumbnailRow`, `ThumbnailPlaceholder`.
- A skeleton for each. Strings `checklist.progress`, `checklist.empty`, `checklist.complete`,
  `thumbnail.verified`, `thumbnail.saved`.

### Changed

- Dalada's comments and replies share one layout, the reply's: the time on the right next to the
  menu, lines 4 pt apart instead of 2.
- The thumbnail placeholder uses `AppColors.pale`: 24% in dark instead of 12%.
- `StatsStrip` takes two columns at accessibility text sizes, so a caption no longer breaks
  mid-word.

### Migration

- Dalada: system rounded-border fields on a `.bar` → `MessageComposer` in `safeAreaBar`;
  `PostRow` → `CommentRow`, `ThreadRow` → `ThreadCard`, `ReviewRow` → `ReviewCard`,
  `ChecklistItemRow` → `ChecklistRow`, `ProfileStatsCard` → `StatsStrip`, `PlaceItemCard` and
  `PlaceItemRow` → `ThumbnailCard` and `ThumbnailRow`.

```swift
List { … }
    .safeAreaBar(edge: .bottom) {
        MessageComposer(text: $text, placeholder: "Add a comment…",
                        isSending: isSending, errorMessage: sendError) {
            Task { await send() }
        }
        .screenPadding()
        .padding(.bottom, AppSpacing.sm)
    }
```

## 1.11.0 - 2026-10-06

Thirty colours in the category colour picker. [#26](https://github.com/dkicekeeper/DesignKit/pull/26)

### Added

- `CategoryColors.pickerPalette`: 30 `#rrggbb` colours, `ColorPickerRow`'s default palette. The 14
  hash colours come first, in their order, then 16 new shades: sky, petrol, deep teal, forest,
  lime, olive, ochre, rust, maroon, berry, plum, deep violet, lavender, navy, slate, stone.

### Changed

- `ColorPickerRow` with the default palette shows 30 swatches instead of 14; the first 14 are
  unchanged. The hash palette stays at 14, so no category or avatar changes colour.

## 1.10.0 - 2026-10-06

A skeleton for every component, and the last components from Tenra. There is no 1.9.0.
[#25](https://github.com/dkicekeeper/DesignKit/pull/25)

### Added

- 65 skeletons, each `<Name>Skeleton` at the end of its component's file: the component's
  container and corner as they are, grey shapes for its text, amounts, icons and charts, one
  shimmer over the whole. `UniversalRowSkeleton` has presets for the settings, menu, date and
  checkmark rows.
- `AppRadius.soft` (12): the corner of a shape whose component has none.
- `.skeletonShimmer(false)` stops the shimmer; `SkeletonView.circle` and `.capsule`;
  `CategoryColors.paletteColors`.
- `CheckmarkRow`, `ProgressRingTileGrid` and its skeleton, `.carouselItemTransition()`.
- `EditableHero`, `IconPicker` (with `IconCatalog` in DesignSupport), `CurrencyPickerMenu`,
  `CurrencyAmountInput`, `CurrencyList`.
- Host hooks `DesignKitLogoCatalog` (the icon picker's brands) and
  `DesignKitCurrencyConverter.convertSync`.
- Strings `iconPicker.*`, `currency.*`, `common.changeIcon`.

### Changed

- `SkeletonView` and `SkeletonText` round with `AppRadius.soft` instead of `AppRadius.xs`.
- `RedactableAmount` loads with a skeleton line instead of the system redaction.
- `CashFlowCard`'s loading state is `CashFlowCardSkeleton`.

### Migration

- A loading state drawn with `.redacted` or a spinner → the component's skeleton.
- Tenra: its filter rows → `CheckmarkRow`, its category grid → `ProgressRingTileGrid`,
  `EditableHeroSection` → `EditableHero`, `IconPickerView` → `IconPicker`,
  `CurrencySelectorView` → `CurrencyPickerMenu`.

## 1.8.0 - 2026-10-06

Tabular amount digits, pale tinted containers, and hidden amounts in chart legends.
[#24](https://github.com/dkicekeeper/DesignKit/pull/24)

### Added

- `AppTypography.numbers(_:)`: a text style with tabular figures.
- `Formatting.hiddenAmount(currency:)`: "•••• ₸" for an amount an app writes into its own text
  under `.amountsHidden()`.

### Changed

- Amounts use tabular figures (proportional again since 3.4.0): `FormattedAmountText` and every
  card and row on it, `AmountDigitDisplay`, `TrendBadge`, `ChartSelectionBanner`, the
  `HeroProportionBar` legend and the `HeroBarPair` pill. Amounts in a column line up and are
  slightly wider.
- Every tinted background behind text or an icon is `AppColors.pale(_:)`, 12% in light and 24% in
  dark, where it was 10–15% by component: badges, the `TrendBadge` pill, `RecommendationBox`,
  `HeroSymbol`, avatar initials, `ActivityTimeline` markers, the round icons of
  `LimitProgressCard`, `BreakdownRow` and `ProgressRingRow`, the `ScoreGaugeCard` grade, the
  `TargetProgressCard` badge, the `HeroBarPair` pill, `MonthCalendar`'s today, `TagInput` chips
  and the calculator's operator keys. Dark mode shows the tints more strongly.
- The `HeroProportionBar` legend and the `HeroBarPair` pill hide their amounts under
  `.amountsHidden()`.

## 1.7.0 - 2026-10-06

Hidden amounts, an amount's sign and unit, `StatusBanner`, `SkeletonText`, `appButton` and
`fadeTruncation`. [#23](https://github.com/dkicekeeper/DesignKit/pull/23)

### Added

- `.amountsHidden(_:)` (DesignSupport): `FormattedAmountText` draws "•••• ₸", the unit kept, and
  VoiceOver reads "Hidden amount". `AmountVisibilityToggle`: an eye button that switches it.
- `FormattedAmountText(sign:currencyDisplay:)`: `AmountSign` `.automatic` (the default),
  `.always` (`+` / `−`) or `.never`; `AmountCurrencyDisplay` `.symbol` (the default), `.code`,
  `.systemImage` or `.numberOnly`.
- `Formatting.formatCompactNumber(_:maxFractionDigits:locale:)`.
- `StatusBanner(_:status:style:systemImage:action:)`: a persistent notice on its status's pale
  container.
- `SkeletonText(_:width:lines:)`: placeholder bars sized to a font's line height.
- `.appButton(_:role:size:disabled:)`: appearances primary, secondary and flat; roles normal,
  destructive and neutral; sizes large, medium and small.
- `.fadeTruncation(length:)`: a cut single line fades at its trailing edge instead of an ellipsis.
- Strings `amount.hidden`, `amount.hide`, `amount.show`.

### Migration

```swift
RootView()
    .amountsHidden(settings.hidesAmounts)
```

### Gallery and tooling

- A snapshot that differs from its reference is drawn once more in a new window before it fails:
  Liquid Glass sometimes drops a tall card's bottom shading for a whole render.
  [#22](https://github.com/dkicekeeper/DesignKit/pull/22)

## 1.6.0 - 2026-10-06

Semantic colours v2: colour tokens grouped by what they colour. Nothing changes on screen.
[#21](https://github.com/dkicekeeper/DesignKit/pull/21)

### Added

- `AppColors.Text`: `primary`, `secondary`, `tertiary`, `action`, `positive`, `negative`,
  `warning`, `onAccent`, and `…OnDark` and `…OnLight`, the same in both themes, for text on photos
  and gradients.
- `AppColors.Background`: `base`, `baseAlt`, `elevation1` to `elevation3`, `neutral1`, `neutral2`,
  `fill`, `fillOnDark`, `fillOnLight`, `overlayOnImage`.
- `AppColors.Status`: `info`, `positive`, `negative`, `warning`, `neutral` and their `…Pale`
  containers.
- `AppColors.Border`: `normal`, `opaque`, `selected`, `darkModeOnly`, `onDark`, `onLight`.
- `AppColors.pale(_:)`: a pale tint of any colour, 12% in light and 24% in dark.

### Migration

- The flat names are aliases of the groups, with the same values; move when convenient:
  `textPrimary` → `AppColors.Text.primary`, `textSecondary` → `Text.secondary`, `textTertiary` →
  `Text.tertiary`, `bgBase` → `AppColors.Background.base`, `bgCard` → `Background.neutral1`,
  `bgMuted` → `Background.neutral2`.
- `accent`, `destructive`, `success`, `warning` and `staticWhite` name roles and stay.

## 1.5.1 - 2026-10-06

A patch release. [#20](https://github.com/dkicekeeper/DesignKit/pull/20)

### Fixed

- `BalanceRow` and `ProgressRingRow` stack their amounts at accessibility text sizes, the 1.3.0
  rule: "185 000 ₸", "/ 250 000 ₸" and "(74%)" on three lines instead of "185… / 250… (74%)".
  Standard sizes are unchanged.

## 1.5.0 - 2026-10-06

Eight more Tenra components with context-neutral APIs.
[#19](https://github.com/dkicekeeper/DesignKit/pull/19)

### Added

- `BalanceCard` (Tenra's `AccountCard`), `SelectableBalanceCard` (`AccountRadioButton`),
  `BalanceRow` and `BalanceRow.Detail` (`AccountRow`), `ProgressRingRow` (`CategoryRow`),
  `ProgressRingTile` (`CategoryChip`), `LimitProgress`.
- `MetricCard` with `MetricCardValue`, `MetricCardTrend` and `MetricCardChartPlacement`
  (`InsightsCardView`).
- `GradientOrbsBackground` (`CategoryGradientBackground`).
- `PromptSheet` (`RatingSurveyView`), with its detent `height`, 340 by default.
- `SelectableBalanceCard` and `ProgressRingTile` carry the `.isSelected` trait.

### Changed

- `PromptSheet` uses `AppTypography`: the title `h3`, the message `bodySmall`, the buttons
  `bodyEmphasis` (Tenra's "Enjoying Tenra?" sheet used system fonts).

### Gallery and tooling

- One glass card per snapshot: Liquid Glass reflects a neighbouring card, differently from run to
  run. [#18](https://github.com/dkicekeeper/DesignKit/pull/18)

## 1.4.0 - 2026-10-05

One padding rule for rows. [#17](https://github.com/dkicekeeper/DesignKit/pull/17)

### Changed

- The rule ([docs/design-system.md](https://github.com/dkicekeeper/DesignKit/blob/main/docs/design-system.md)
  §10): a card pads itself; a row pads only vertically, from its `RowConfiguration` preset; a row
  in a `FormSection` takes `.standard` (12 × 16); a primitive does not pad. Outer spacing is the
  screen's.
- `ScheduleRow` pads 8 pt vertically, the `.info` preset; it had none.
- `NetAmountRow` pads 8 pt, the `.info` preset, instead of its own 12.

### Migration

- A stack of rows in a card: `spacing: 0` with `Divider()`s, or `AppSpacing.sm` without; the card
  pads with `.cardContentPadding()`.

## 1.3.0 - 2026-10-05

Side-by-side layouts stack at accessibility text sizes, as the HIG asks.
[#16](https://github.com/dkicekeeper/DesignKit/pull/16)

### Changed

- At AX1 to AX5 (`dynamicTypeSize.isAccessibilitySize`): `ComparisonCard` shows before, now and
  then the change, amounts in full ("120…" before); `TotalsCard` puts one total per line ("Expens
  / es" before); `InsightEntityRow` and `BreakdownRow` put the amount under the title;
  `MenuPickerRow` puts the selected value under the title, as iOS Settings does.
- Standard text sizes are unchanged.

### Gallery and tooling

- One page per component, with chips and a swipe to switch.
  [#15](https://github.com/dkicekeeper/DesignKit/pull/15)

## 1.2.0 - 2026-10-05

Eight Tenra components with context-neutral APIs; each layout moved as it was.
[#14](https://github.com/dkicekeeper/DesignKit/pull/14)

### Added

- `ComparisonCard` (Tenra's `PeriodComparisonCard`): before and now amounts with
  `TrendBadge(.changeIndicator)`, `increaseIsGood`, `flatThreshold`.
- `CashFlowCard` (`TransactionsSummaryCard`): `Totals(income:expenses:extra:)`, with empty and
  loading states.
- `ScoreGaugeCard` (`HealthScoreHeroCard`), `ScoreCard` (`HealthScoreCardView`).
- `TargetProgressCard` (`HealthComponentCard`): current against target over a bar, an explanation
  and a recommendation.
- `RecurringPaymentCard` (`SubscriptionCard`); `PayoffProgressCard` (`LoanCard`) with
  `Phase.inProgress` and `.done` and an `accessory` slot.
- `BreakdownRow`, `AmountPercentageView` (`CategoryBreakdownRow`).

## 1.1.0 - 2026-10-05

Six Tenra components with context-neutral APIs: every component that can be generic lives in
DesignKit, even if one app uses it. [#13](https://github.com/dkicekeeper/DesignKit/pull/13)

### Added

- `TotalsCard` (Tenra's `InsightsTotalsCard`): labelled totals side by side, each with an optional
  change badge.
- `LimitProgressCard` (`BudgetProgressRow`): an icon, a title and a percentage, a bar, "spent /
  limit" and a caption.
- `WeightBreakdownCard` (`HealthScoreWeightingCard`): a stacked bar of weighted parts and a
  legend.
- `CalculationCard` (`InsightFormulaCard`): "How it's calculated", with rows, the result, an
  explanation and a recommendation.
- `NetAmountRow` (`PeriodBreakdownRow`), `ScheduleRow` (`AmortizationScheduleRow`).

### Migration

- The app keeps a thin adapter under its old name that maps its model onto the component, so its
  call sites don't change; the layout is pixel-identical.

### Gallery and tooling

- Snapshot tests round 2, a Gallery specimen for every component, English strings in the Gallery,
  and a CI job that builds the package on Xcode 27. [#12](https://github.com/dkicekeeper/DesignKit/pull/12)

## 1.0.0 - 2026-10-03

The first major release: the API Tenra retired is removed.
[#11](https://github.com/dkicekeeper/DesignKit/pull/11)

### Removed

- `BudgetProgressBar`, `BudgetProgressCircle`, `ExpenseIncomeProgressBar`, `DonutChart`,
  `ChartDisplayMode`, `View.inlineFieldStyle(keyboard:maxWidth:)`, `View.inlineNoteStyle()`.

### Migration

- `BudgetProgressBar` → `LinearProgressBar(percentage:isOverBudget:color:)`.
- `BudgetProgressCircle` → `ProgressRing(progress:size:lineWidth:isOverBudget:)`.
- `ExpenseIncomeProgressBar` → `AmountComparisonBar(expenseAmount:incomeAmount:currency:)`.
- `DonutChart` → `OrbChart(slices:)` or `MiniDonut(slices:)`; `DonutSlice` stays.
- `.inlineFieldStyle(keyboard:maxWidth:)` → `FormTextField(style: .inline)`.
- `.inlineNoteStyle()` → `FormTextField(style: .inlineMultiline(min:max:))`.

### Gallery and tooling

- Snapshot tests: components in light, dark and large text against reference PNGs; CI fails on a
  visual difference. [#10](https://github.com/dkicekeeper/DesignKit/pull/10)

## 0.7.0 - 2026-10-02

A calendar, an onboarding pager, a shared permission primer, a timeline and tags.
[#9](https://github.com/dkicekeeper/DesignKit/pull/9)

### Added

- `PermissionPrimerView`: one pre-permission sheet, a `HeroSymbol`, a title and a message with
  Allow and Not now; Allow shows a spinner while the system alert is up.
- `OnboardingPager`, `OnboardingPage`, `HeroSymbol` (Dalada's intro); `OnboardingStepIndicator`
  and `OnboardingPageContainer` take `symbols:` and `stepSymbols:`.
- `MonthCalendar`, `CalendarRange`, `CalendarPeriod` (Tenra's subscription calendar): the app
  supplies the items, the markers and the header accessory.
- `ActivityTimeline`, `TimelineMarker`, `TagInput`, `FlowLayout`.
- `.skeletonLoadingLabel()`: VoiceOver reads "Loading" for a stack of skeleton shapes.
- Strings `calendar.showMonth`, `calendar.showWeek`, `tags.remove`.

### Changed

- Tenra's notification primer (`NotificationPermissionView`) uses the shared layout: the symbol on
  a disc, glass buttons, an `h3` title.
- Fallback category colours (`CategoryColors`) use an FNV-1a hash instead of `String.hashValue`:
  they change once with this release, then stay the same on every launch.

## 0.6.0 - 2026-10-01

Gaps found against Apple HIG, Material 3, Fluent 2, Carbon, Polaris and Atlassian
([docs/benchmark.md](https://github.com/dkicekeeper/DesignKit/blob/main/docs/benchmark.md)).
[#8](https://github.com/dkicekeeper/DesignKit/pull/8)

### Added

- `SkeletonView`, `SkeletonRow`, `.skeleton(isLoading:)`: loading placeholders with a shimmer
  that stops under Reduce Motion.
- `LoadingButtonLabel`: a spinner replaces the title and the button keeps its width.
- `StepTracker`: progress through steps, done, current and upcoming.
- `ToggleSettingsRow`, `AvatarGroup`, `ExpandableText`.
- `ChipPicker`: multiple selection (`Binding<Set<Option>>`) and an icon per chip.
- `MessageBanner(message:type:actionTitle:action:)`: an action such as "Undo" or "Retry".
- Strings `skeleton.loading`, `steps.position`, `text.more`, `text.less`.

## 0.5.0 - 2026-10-01

Trend charts over a generic `ChartPoint` model: Tenra's insight charts with the finance model
taken out. [#7](https://github.com/dkicekeeper/DesignKit/pull/7)

### Added

- `ChartPoint` (only `chartLabel` is required; `chartAxisLabel`, `chartTitle` and `chartDate` are
  optional), `ChartValuePoint`, `ChartSeries` (`.solid` or `.signed` colouring, a `.zero` or
  `.signed` baseline), `ChartValueFormat`.
- `LineChart`, `BarChart`: scrollable, a tap selects with a haptic and a banner, a Today marker,
  zoom.
- `ChartSwitcher` and `ChartZoomControls`, `HeroSparkline`, `Sparkline`, `ChartSelectionBanner`.
- Strings `chart.today`, `chart.empty.title`, `chart.empty.message`.

### Migration

```swift
extension MonthTotal: ChartPoint {
    var chartLabel: String { monthKey }
}

LineChart(dataPoints: totals,
          series: ChartSeries(id: "spent", name: "Spent", coloring: .solid(AppColors.expense)) { $0.spent })
```

## 0.4.0 - 2026-10-01

Display components each app drew itself. [#6](https://github.com/dkicekeeper/DesignKit/pull/6)

### Added

- `BadgeView` (Dalada's `RuleStatusBadge`): a capsule for a status, a tag or a counter, `.tinted`
  or `.filled`.
- `TrendBadge` (Tenra's `InsightTrendBadge`): an arrow and a signed percentage, `.pill`, `.inline`
  or `.changeIndicator`.
- `StatTile`, `AvatarView`, `RatingView` and `RatingPicker`, `ChipPicker` (Dalada's `TripStat`,
  `PersonAvatar`, `StarsView` and `StarPicker`, `ChipRow`).
- `SelectionIndicator(isSelected:tint:)`; `LinearProgressBar(value:color:height:animatesOnAppear:)`
  for plain 0…1 progress.
- Strings `rating.value`, `rating.pick`.

### Changed

- `LinearProgressBar` gives VoiceOver its percentage; nothing visual.

### Gallery and tooling

- The Gallery ships to TestFlight as "DesignKit Gallery".
  [#4](https://github.com/dkicekeeper/DesignKit/pull/4),
  [#5](https://github.com/dkicekeeper/DesignKit/pull/5)

## 0.3.0 - 2026-10-01

What Tenra needed to drop its own copy of the design system and consume DesignKit.
[#3](https://github.com/dkicekeeper/DesignKit/pull/3)

### Added

- `InsightsStatCard(…) { trend }`: a trend footer slot; the init without one still works.
- Public inits and fields for what a host app builds: `RowConfiguration`, `IconStyle`,
  `IconConfig`, `CurrencyInfo`, `AmountDisplayConfiguration`, `AmountFormatter`,
  `CalculatorInputModel`'s state and actions, the entrance and border modifiers.
- Unit tests for formatting, the expression evaluator and the calculator model, moved from Tenra.

### Gallery and tooling

- CI builds Tenra against the checkout, as it builds Dalada.

## 0.2.0 - 2026-09-30

The first release shared by Tenra and Dalada. [#1](https://github.com/dkicekeeper/DesignKit/pull/1),
[#2](https://github.com/dkicekeeper/DesignKit/pull/2)

### Added

- Tokens (colours, spacing, radius, icon sizes, Inter typography, animation), modifiers, button
  styles, icons, formatting, haptics and the components extracted from Tenra, synced with its
  `74a12c5`.
- `OrbChart` and `DonutSlice`, `ProgressRing`, `LinearProgressBar`, `AmountComparisonBar`, the
  Mini and Hero gauges and bars, `HeroSection`, `AccentGlow`, `MessageBanner`,
  `StatusIndicatorBadge`, `EditSheetContainer`, `UniversalCarousel`, `UniversalFilterButton`,
  `MenuPickerRow`, `SelectionIndicator`, `ColorPickerRow`.
- `DesignKitTheme.accent`: each app's brand accent behind `AppColors.accent`, indigo by default.
- Host hooks `DesignKitLogoLoader` and `DesignKitCurrencyConverter`.
- iOS 27 SDK APIs behind `#if compiler(>=6.4)`, so the package builds with Xcode 26 and 27.

### Deprecated

- `BudgetProgressBar`, `BudgetProgressCircle`, `ExpenseIncomeProgressBar`, `DonutChart`,
  `ChartDisplayMode`, retired in Tenra (removed in 1.0.0).

### Migration

```swift
// App.init()
DesignKitTheme.accent = Color("AccentColor")
DesignKitFonts.registerIfNeeded()
```

### Gallery and tooling

- CI builds the package, the Gallery and Dalada against the checkout; bumping `VERSION` cuts a
  release; the Gallery ships to TestFlight.
