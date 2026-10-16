# Where the apps could use more of DesignKit

A list for the app sessions (5.2.0, the owner's review): DesignKit components no app uses yet, and
screens that load without the reveal the rest of the app has. Each line is a proposal, not a
decision; the app's session decides and does the work in the app. When an app starts using a
component, CI's `Gallery badges` job asks for the Gallery page's `apps:` to name it
([gallery-structure.md](gallery-structure.md)).

## Skeleton to content without `.skeletonReveal`

Both apps put `.transition(.skeletonReveal)` on about ten screens where a skeleton gives way to the
content. These load without it (found in October 2026):

- **Tenra:** `LinkPaymentsView`, `InsightsView` (it fades in with `.contentReveal` instead).
- **Dalada:** achievements, the catch and check-in forms, close friends, comments, community.

## Components no app uses

Some are used inside other DesignKit components (`AmountInput` in `EditableHero`, `VoiceWave` in
`VoiceOrbButton`): an app gets them there and needs them on their own only for a screen of its
own.

| Component | Tenra | Dalada |
|---|---|---|
| `TypingIndicator` | Ten "types" until the first word of a reply | |
| `StatusBanner` | import and sync errors | offline maps |
| `Tooltip` | hints on the first launch | the map's buttons |
| `StepTracker` | the CSV import's steps | adding a place |
| `ChartSelectionBanner`, `ChartZoomControls` | the insights' charts | |
| `AmountComparisonBar`, `SpentBudgetText` | a budget against what was spent | |
| `LiveAmountText` | the balance after a transaction | |
| `HeroSymbol` | "Import finished" | empty screens |
| `OnboardingStepIndicator` | onboarding | the introduction |
| `.chartDrawIn` | the first appearance of a chart | |
| `.sparkleBurst` | a contribution to a goal | |
| `AvatarGroup` | | a trip's members |
| `TagInput`, `FlowLayout` | | gear and place tags |

Also unused, without a place proposed yet: `AmountVisibilityToggle` (Tenra hides amounts its own
way), `AmountDigitDisplay`, `AmountPercentage`, `AnimatedTitleInput` (inside `EditableHero`),
`.attentionPulse`, `.grain`, `.accentGlow`, `.ripple`, `.dissolve`, `.textReveal`,
`.scrollReveal`, `.staggeredEntrance`, `.hapticCue`, `ScrambleText`.

## Ten (ParticleCreature) in Tenra

What Tenra's code uses of the creature (October 2026): both styles, `CreatureGlyph` (tab,
toolbar, menu), every accessory, `.creatureAmbience`, touches; the moods `idle`, `thinking`,
`answering`, `happy`, `celebrating`, `worried`, `sad`, `confused`, `asleep`; the emotions `calm`,
`joy`, `thought`, `whisper`, `worry`, `dizzy`; the gestures `nod`, `hop`, `wave`, `point`,
`flinch`, `shrug`. Where the rest could go:

| Unused | Where |
|---|---|
| `.listening` (with `level:`) | while the person dictates to Ten from the field's microphone |
| `.love` | when the person thanks Ten (a reply mood the assistant does not have yet) |
| `.proud` | a contribution to a goal, days in a row, a budget kept |
| `.surprised` | an unusually large expense, an anomaly |
| `.determined` | a long run of tools, in place of `.thinking` |
| `.wink` | a tip, a joke |
| `.glyph("₸")` | an answer about a total, the import |
| `.sleepy` | late in the evening, with the whisper it already uses |
| `.working(progress:)` (5.3.0) | the CSV import, a sync |
| `.shake` | "found nothing" |
| `.perk` | a new notice from Ten |
| emotion `.sad` | a line about a loss |
| `haptic: true` (5.3.0) | the gestures of the chat's reactions |
| `.creatureFollowsTilt()` (5.3.0) | Ten's home |
| `ParticleCreature.image` (5.3.0) | a widget, a notification from Ten |
