# Where the apps could use more of DesignKit

A list for the app sessions (5.2.0, the owner's review): DesignKit components no app uses yet, and
screens that load without the reveal the rest of the app has. Each line is a proposal, not a
decision; the app's session decides and does the work in the app. When an app starts using a
component, CI's `Gallery badges` job asks for the Gallery page's `apps:` to name it
([gallery-structure.md](gallery-structure.md)).

Tenra took its part of the list on 2026-10-17
([Tenra#79](https://github.com/dkicekeeper/Tenra/pull/79)); what is left below is Dalada's, and
what neither app has a place for yet.

## Skeleton to content without `.skeletonReveal`

Both apps put `.transition(.skeletonReveal)` on about ten screens where a skeleton gives way to the
content. These load without it (found in October 2026):

- **Dalada:** achievements, the catch and check-in forms, close friends, comments, community.

Tenra's `LinkPaymentsView` and `InsightsView` (its feed's first load) reveal since Tenra#79.

## Components no app uses

Some are used inside other DesignKit components (`AmountInput` in `EditableHero`, `VoiceWave` in
`VoiceOrbButton`): an app gets them there and needs them on their own only for a screen of its
own.

| Component | Dalada |
|---|---|
| `StatusBanner` | offline maps |
| `Tooltip` | the map's buttons |
| `StepTracker` | adding a place |
| `HeroSymbol` | empty screens |
| `OnboardingStepIndicator` | the introduction |
| `AvatarGroup` | a trip's members |
| `TagInput`, `FlowLayout` | gear and place tags |

Tenra uses `StatusBanner` (import, saving and backup errors), `HeroSymbol` (the import tab and
the CSV result), `StepTracker` (the CSV import), `Tooltip` (Home's categories on the first
launch), `TypingIndicator` (Ten until the first word of a reply), `LiveAmountText` (the balance
after a transaction), `SpentBudgetText` (a category's budget) and `.sparkleBurst` (money put
towards a goal). `ChartSelectionBanner`, `ChartZoomControls`, `.chartDrawIn`,
`AmountComparisonBar` and `OnboardingStepIndicator` reach its screens inside DesignKit's charts,
`CashFlowCard` and onboarding containers.

Also unused, without a place proposed yet: `AmountVisibilityToggle` (Tenra hides amounts its own
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
