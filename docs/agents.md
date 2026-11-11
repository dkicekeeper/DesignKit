# DesignKit for an app's agent

The short version of DesignKit's rules for a session working in Tenra or Dalada (8.9.0, benchmark
round 4: Astryx's `init`, which writes such a block into an app's AGENTS.md). Each app's
**DesignKit update** workflow puts this file into the app's CLAUDE.md between the
`designkit:agents` markers when it moves the pin (`scripts/sync_agents_block.py`), so it always
matches the version the app builds with. Do not edit the block in the app; change it here.

## Look a component up

- `docs/components.md` in the DesignKit checkout: one entry per component (`### Name`), what it is
  for, its initialisers, rules, do and don't, its skeleton. `docs/components.json` is the same as
  data. The full rules: `docs/design-system.md`.
- The Gallery app (TestFlight) shows every component with its parameters and states.
- A missing component goes to DesignKit by PR (CLAUDE.md, "Porting a component"); the app keeps a
  thin adapter over its model.

## The rules

1. Tokens, never raw values: `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`,
   `AppIconSize`, `AppAnimation` / `AppMotion`. Status text is `AppColors.Status.*Text` (4.5:1);
   a colour of your own as text is `AppColors.readable(color)` on `AppColors.pale(color)`.
2. Every symbol is an `Icon`: a glyph under 44 pt, a tile on its plate from 44 pt. iOS's own bars,
   menus, tabs and segments, and a symbol inside a line of text, stay `Image` / `Label`.
3. A form or settings list is `FormSection` glass cards of `UniversalRow(_:icon:accessory:)`; the
   section draws the dividers. No system `Form`.
4. A list of things a person keeps is a `CardList`: a tap opens, a long press shows Edit and
   Delete, the toolbar selects, reorders and adds. No swipe actions.
5. Every view that shows data has a skeleton (`<Name>Skeleton`); a list that loads pages ends in
   `LoadMoreFooter`.
6. An outcome that comes and goes is spoken: `MessageBanner` and the failure states of
   DesignKit's components do it; an app's own outcome calls `AccessibilityAnnouncer.announce(_:)`.
7. Motion through DesignKit (`AppMotion` springs, `.popIn`, `.riseIn`, effects); everything stops
   under Reduce Motion and `.designKitMotion(false)`.

## What a screen needs → the component

| Need | Component |
|---|---|
| A button | `DSButton` (`.dsButton` for a custom label) |
| A form, settings | `FormSection` + `UniversalRow(accessory: .toggle / .menu / .picker / .date / .stepper / .slider / .navigation / .action / .info)` |
| A list of the person's things | `CardList` (a card per item, or rows in one card), `ItemRow` + `MetaLine` |
| Pick from a long list, with search and "Create" | `SearchablePicker` |
| Pick from a few | `UniversalRow(accessory: .menu)`, `ChipPicker`, `SegmentedPicker` |
| A section title | `SectionHeader` |
| Money | `FormattedAmountText`, `AmountRow`, `AmountInput` / `CurrencyAmountInput`, `LiveAmountText` |
| When something happened, how long it runs | `RelativeTime` (`.relative`, `.elapsed`, `.clock`) |
| Explain a number | `InfoTip` / `.infoTip(_:title:)` |
| A value over what was tapped, a coachmark | `Tooltip`, `.spotlight` |
| A state that lasts | `StatusBanner` |
| An outcome that comes and goes | `MessageBanner` |
| Nothing here, or loading failed | `EmptyState` (`.error` with Retry) |
| Loading | the component's `<Name>Skeleton`, `.skeletonReveal` when it gives way |
| A chat | `MessageBubble` (`markdown:`, `time:`, `status:`), `ConversationDivider`, `MessageComposer`, `TypingIndicator`, `SuggestionChips` |
| Charts | `LineChart`, `BarChart`, `ChartSwitcher`, `Sparkline`, `OrbChart`, `CalendarHeatmap` (docs/charts.md) |
| Progress | `ProgressRing`, `LinearProgressBar`, `LimitProgressCard`, `StepTracker` |
| People | `Avatar`, `AvatarGroup`, `PersonRow`, `CommentRow` |
| Photos | `RemotePhoto`, `PhotoTile`, `PhotoGrid`, `PhotoCarousel`, `PhotoViewer` |
| Edit sheet | `EditSheetContainer`, `EditableHero`, `AmountEntrySheet` |
| A moment of success | `.celebration`, `.completionMoment` |

## Check before pushing

```bash
python3 <DesignKit>/scripts/designkit_lint.py all --source <the app's Swift folders>
```

`tokens` finds raw design values, swipe actions and the system `Form` (against the app's
`scripts/design-lint-baseline.json`); `section-rows` finds section rows without their own padding
or divider inset. A major DesignKit version: `scripts/migrate.py --from <old> --to <new> --source …`
rewrites what it can and leaves `TODO(DesignKit X.0)` where `docs/migration-X.0.md` needs a person.
