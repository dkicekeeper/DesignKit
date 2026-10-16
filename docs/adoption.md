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
