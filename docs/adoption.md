# Where the apps could use more of DesignKit

A list for the app sessions (5.2.0, the owner's review): DesignKit components no app uses yet, and
screens that load without the reveal the rest of the app has. Each line is a proposal, not a
decision; the app's session decides and does the work in the app. When an app starts using a
component, CI's `Gallery badges` job asks for the Gallery page's `apps:` to name it
([gallery-structure.md](gallery-structure.md)); it reads Tenra, Dalada and, since 8.16.1, Platina.

Checked against the three apps' `main` on 2026-11-24 (Tenra at DesignKit 8.11.0, Dalada at 8.12.0,
Platina at 8.14.0).

Both apps took their part of the list in October 2026: Tenra on 2026-10-17
([Tenra#79](https://github.com/dkicekeeper/Tenra/pull/79)), Dalada the same day (its `main`,
0919342, TestFlight build 140). What is left is what neither app has a place for yet.

## Skeleton to content without `.skeletonReveal`

None known. Tenra's `LinkPaymentsView` and `InsightsView` (its feed's first load) and Dalada's
achievements, the photos of its catch and check-in forms, close friends, comments and community
(reviews, threads, a thread's page, the review form) reveal since then.

## Where the list's components went

| Component | Tenra | Dalada |
|---|---|---|
| `StatusBanner` | import, saving and backup errors | offline maps: no network, areas that failed to download (a tap retries), mobile data |
| `Tooltip` | through `.spotlight`: Home's categories on the first launch, Save in a new transaction, the voice input | the map's buttons on the first open, through `.spotlight` (a `Tooltip`'s tail was always at its centre; 5.5.0 adds `arrowAlignment:`, and `.spotlight`'s tail now stays over a corner button) |
| `StepTracker` | the CSV import | a new place in three steps |
| `HeroSymbol` | the import tab, the CSV result | its placeholder screens (`EmptyState { HeroSymbol }`, seven screens) |
| `OnboardingStepIndicator` | inside DesignKit's onboarding containers | after the first sign-in: consent, then the username |
| `TypingIndicator` | no longer: the assistant's step in words under `.thinkingShimmer`, Ten thinking over the thread | (Platina: Plati until its reply) |
| `LiveAmountText`, `SpentBudgetText` | the balance after a transaction, a category's budget | |
| `.sparkleBurst` | money put towards a goal | |
| `AvatarGroup` | | a trip's members in one row with their names, a tap opens the list (initials; with 5.5.0 its `PersonAvatar` can go in the group's `avatar:` slot for photos) |
| `TagInput`, `FlowLayout` | | gear tags with suggestions and `maxTags: 10`; the gear filter's chips and a place's badges |

`ChartSelectionBanner`, `ChartZoomControls`, `.chartDrawIn` and `AmountComparisonBar` reach
Tenra's screens inside DesignKit's charts and `CashFlowCard`.

## Components no app uses

Some are used inside other DesignKit components (`AmountInput` in `EditableHero`, `VoiceWave` in
`VoiceOrbButton`, `Tooltip` in `.spotlight`, `ChartSelectionBanner`, `ChartZoomControls` and
`.chartDrawIn` in the charts, `AmountComparisonBar` in `CashFlowCard`, `SquareImageCropper` in
`IconPicker`'s Photo tab): an app gets them there and needs them on their own only for a screen of
its own. Unused, without a place proposed yet: `AmountVisibilityToggle` (Tenra hides amounts its
own way), `AmountDigitDisplay`, `AmountPercentage`, `AnimatedTitleInput` (inside `EditableHero`),
`.attentionPulse`, `.grain`, `.accentGlow`, `.ripple`, `.dissolve` (Dalada took it in 2.7.0 and has
dropped it since), `.textReveal`, `.staggeredEntrance`, `.hapticCue`, `ScrambleText`.
`.scrollReveal` is Tenra's since this list was first written.

## 8.9.0: proposals for the new components

Benchmark round 4 (docs/benchmark.md, against Meta's Astryx) added these. Where they went by
2026-11-24, and what is still a proposal:

| Component | Tenra | Dalada | Platina |
|---|---|---|---|
| `InfoTip` | proposed: the Financial Health score and its parts, an insight's rolling average or forecast, "spent per day" | proposed: a route's difficulty, a rating, a streak's rule | proposed: a trophy's rarity (the share of players who earned it) |
| `RelativeTime` | uses it | uses it | uses it |
| `SearchablePicker` | proposed: a transaction's category and subcategory (with "Create"), link payments | proposed: a trip's gear (several, with "Create"), a place's type | uses it |
| `MessageBubble(markdown:time:status:)` | `MessageBubble` with plain text; proposed: Ten's answers in Markdown, the time under a message | proposed: a thread's messages with time and "Read" | Plati's answers in Markdown |
| `ConversationDivider` | proposed: the chat's days, "Ten changed the budget" | proposed: a thread's days, "Alex joined" | uses it |
| `AccessibilityAnnouncer` | proposed: "Saved", "Imported 120 transactions", a sync that finished | uses it | uses it |
| `AppColors.Status.*Text`, `AppColors.readable` | proposed: its own status texts on tints (a category's badge) | proposed: rule statuses, map legends on a tint | proposed: a trophy's grade on its tint |
| `scripts/designkit_lint.py` | runs it in CI and after each pin bump | the same | runs it in CI |
| `scripts/sync_agents_block.py` | its CLAUDE.md, after each pin bump in `designkit.yml` | the same | its CLAUDE.md carries the block; moves its pin by hand |

## Platina

Platina (2026-11, a PlayStation trophy tracker) draws all of its interface with DesignKit, on the
grey surfaces (`DesignKitTheme.surface = .fill`, 8.12.0) and in a column on the iPad and the Mac
(`.readableWidth()`, 8.13.0); the Gallery's pages carry its badge since 8.16.1. The first app to
use `SearchablePicker`, `ConversationDivider`, `MessageBubble(markdown:)`, `.readableWidth()` and
`.heroBackground(clearHeight:picture:)` (its game screen, 8.14.0); its profile puts its sections
side by side on an iPad (`AppLayout.cardColumns`) and its play days in a `CalendarHeatmap`. Not used
yet, where it could: `InfoTip` by a trophy's rarity.

## Ten (ParticleCreature) in Tenra

Since Tenra#79 Tenra's code uses all of the creature: both styles, `CreatureGlyph` (tab, toolbar,
menu), every accessory, `.creatureAmbience`, touches, every mood, every emotion of its speech and
every gesture. Where the 5.3.0 additions went:

| Added | In Tenra |
|---|---|
| `.working(progress:)` | while a statement is read, from the importer's pages |
| `haptic: true` | the gestures of the chat's reactions |
| `.creatureFollowsTilt()` | Ten on Home |
| `ParticleCreature.image` | insight notifications and the weekly digest (Tenra has no widget) |

And the moods the list proposed: `.listening` with the voice level in the voice sheet's title,
`.proud`, `.surprised`, `.love` and `.wink` for the assistant's new reply moods (a shake for an
empty answer; `.surprised` also at a spending spike or a large expense), `.glyph` with a money
card's currency sign, `.determined` after three tools, `.sleepy` late at night, `.perk` at a new
"Ten writes" card.
