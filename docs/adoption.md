# Where the apps could use more of DesignKit

A list for the app sessions (5.2.0, the owner's review): DesignKit components no app uses yet, and
screens that load without the reveal the rest of the app has. Each line is a proposal, not a
decision; the app's session decides and does the work in the app. When an app starts using a
component, CI's `Gallery badges` job asks for the Gallery page's `apps:` to name it
([gallery-structure.md](gallery-structure.md)).

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
| `Tooltip` | Home's categories on the first launch | the map's buttons on the first open, through `.spotlight` (a `Tooltip`'s tail is always at its centre, so it cannot point at a corner button) |
| `StepTracker` | the CSV import | a new place in three steps |
| `HeroSymbol` | the import tab, the CSV result | its placeholder screens (`EmptyState { HeroSymbol }`, seven screens) |
| `OnboardingStepIndicator` | inside DesignKit's onboarding containers | after the first sign-in: consent, then the username |
| `TypingIndicator` | Ten until the first word of a reply | |
| `LiveAmountText`, `SpentBudgetText` | the balance after a transaction, a category's budget | |
| `.sparkleBurst` | money put towards a goal | |
| `AvatarGroup` | | a trip's members in one row with their names, a tap opens the list (initials only: `AvatarGroup` takes names) |
| `TagInput`, `FlowLayout` | | gear tags with suggestions and `maxTags: 10`; the gear filter's chips and a place's badges |

`ChartSelectionBanner`, `ChartZoomControls`, `.chartDrawIn` and `AmountComparisonBar` reach
Tenra's screens inside DesignKit's charts and `CashFlowCard`.

## Components no app uses

Some are used inside other DesignKit components (`AmountInput` in `EditableHero`, `VoiceWave` in
`VoiceOrbButton`): an app gets them there and needs them on their own only for a screen of its
own. Unused, without a place proposed yet: `AmountVisibilityToggle` (Tenra hides amounts its own
way), `AmountDigitDisplay`, `AmountPercentage`, `AnimatedTitleInput` (inside `EditableHero`),
`.attentionPulse`, `.grain`, `.accentGlow`, `.ripple`, `.dissolve`, `.textReveal`,
`.scrollReveal`, `.staggeredEntrance`, `.hapticCue`, `ScrambleText`.

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
