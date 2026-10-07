# Motion & Effects

DesignKit's motion is meant to be rich but light: every movement says something, ends before the
eye starts waiting, costs as little as the system allows, and stands still when the person or the
device asks. This page is the rule book and the catalogue (2.2.0). The Gallery's **Motion** and
**Effects** sections play every item.

## 1. Principles

1. **Motion has a job.** It answers a touch (feedback), shows where something came from or went
   (continuity), tells that something changed (state), or marks a moment (celebration). Motion
   with no job is decoration, and decoration is the first thing to cut.
2. **Quick and interruptible.** Springs, not fixed curves: a spring picks up from wherever it is
   when a new change comes, so a fast second tap never waits for the first animation.
3. **One hero at a time.** A screen has at most one expressive movement in view; the rest is
   snappy or smooth. Celebrations are rare: a burst on every tap stops meaning anything.
4. **The system first.** SF Symbols' own animations, `contentTransition(.numericText())`, zoom
   navigation transitions and `scrollTransition` cost almost nothing and look native. Reach for
   custom drawing only for what the system does not do.
5. **Stillness is a feature.** Under Reduce Motion movement turns into a dissolve; loops stop
   while the system asks apps to save resources; `.designKitMotion(false)` stills a subtree.
6. **Pair with haptics, not sound.** A celebration plays the success haptic, a destructive
   `DSButton` the warning one. The haptic stays when the motion is off.

## 2. Springs by purpose

| Token | Feels | Use for |
|---|---|---|
| `AppAnimation.snappy` | 0.25 s, no bounce | The answer to a touch: a toggle, a selection, a chip, a press |
| `AppAnimation.smooth` | 0.35 s, no overshoot | Content that changes or moves: a value, a list, a layout |
| `AppAnimation.bouncy` | 0.4 s, small overshoot | A playful confirmation: added, liked, done |
| `AppAnimation.expressive` | 0.55 s, bounce 0.3 | A moment that matters: a goal reached, a hero's first appearance |

`AppAnimation.motion(_:reduceMotion:isEnabled:)` returns `nil` when motion is off. The older
tokens (`contentSpring`, `gentleSpring`, `heroSpring`, `progressBarSpring`, …) keep working for
the components that use them.

## 3. Budgets (`MotionBudget`)

| Budget | Value | |
|---|---|---|
| `feedback` | 0.25 s | a press, a toggle, a selection |
| `entrance` | 0.35 s | something entering: a card, a sheet's content, a banner |
| `celebration` | 1.4 s | a burst, start to fade-out |
| `stagger` | 0.04 s | between neighbours in a staggered entrance |
| `maxStagger` | 0.3 s | the whole stagger: later items arrive together (`staggerDelay(_:)`) |

## 4. SF Symbols in motion

A symbol effect is the cheapest motion there is: the system draws it, it follows the symbol's
layers, and it never touches layout. DesignKit names them by meaning:

| Modifier | Effect | Where DesignKit uses it |
|---|---|---|
| `.drawOnAppear(delay:)` | Draw On (SF Symbols 7, iOS 26); symbols without draw data simply appear | `HeroSymbol` (`PromptSheet`, onboarding pages), `EmptyState`, `StepTracker`'s done steps, `ChecklistSummaryRow`'s seal |
| `.symbolCue(.bounce, trigger:)` | Bounce | `DSButton` (every press), `ReactionButton`, `SelectionIndicator`, a success `MessageBanner` |
| `.symbolCue(.wiggle, trigger:)` | Wiggle | an error or warning `MessageBanner`, `EmptyState(style: .error)` |
| `.symbolCueOnAppear(_:delay:)` | one cue after appearing | the banners above |
| `.symbolPulse(.breathe, isActive:)` | Breathe (loop) | something live: recording, sharing a location |
| `.symbolPulse(.working, isActive:)` | Variable colour, iterative (loop) | work in progress: syncing, searching |
| `.symbolMagicReplace()` | Magic Replace | `AmountVisibilityToggle` (eye ↔ eye.slash), `SelectionIndicator`, `ReactionButton` (outline ↔ fill) |
| `.contentTransition(.symbolEffect(.replace))` | Replace | `TrendBadge`'s arrow |

Loops go through `AmbientMotionGate`; all of them stop under Reduce Motion and
`.designKitMotion(false)`, drawing the symbol still in its final state.

## 5. Transitions

| Transition | Movement | Under Reduce Motion | For |
|---|---|---|---|
| `.popIn` | grows from 92 % + fade | fade | a chip, a badge, a toast, a tooltip, `TypingIndicator` |
| `.riseIn` | rises 12 pt, sharpens from a 4 pt blur + fade | fade | a card, a section, a banner |
| `.textReveal` | glyph by glyph: rise, sharpen, fade | whole-text fade | text that arrives: an insight, an answer |
| `.blurSlideHero` / `.blurSlideWord` | slide + blur (1.x) | — | a block of text replacing another; streaming words |
| zoom navigation (`matchedTransitionSourceIfPresent`) | system | system | a row or card opening its detail |

Insert with a spring: `withAnimation(AppAnimation.bouncy) { isShown = true }`.

## 6. Effects

| Effect | What | Cost | Use |
|---|---|---|---|
| `.celebration(trigger:colors:)` | confetti from the view, success haptic | one Canvas for 1.4 s, paths from the time | a goal reached, a debt paid off, an achievement, a trip finished |
| `.sparkleBurst(trigger:tint:)` | a ring of sparkles | one Canvas for 0.7 s | a like, a reaction, a favourite (built into `ReactionButton`) |
| `.shine(trigger:in:)` | a band of light sweeps across a shape once | one gradient for 0.8 s | a card just added, a premium badge |
| `.attentionPulse(trigger:in:tint:)` | two rings spread and fade | two strokes for 0.9 s | a new feature, a control to notice |
| `AuroraBackground(colors:intensity:)` | a drifting 3×3 mesh gradient | one GPU pass, 30 fps while allowed | a premium screen, a paywall, an onboarding |
| `.interactiveTilt(in:maxAngle:)` | tilts towards the finger with a glare | a gesture and two 3D transforms | a medal, a card on its own detail screen (not in a scrolling list) |
| `.scrollReveal()` | settles in at the viewport's edges | `scrollTransition`, no state | the rows and cards of a `ScrollView` |
| `.textRevealOnAppear()` | text written in glyph by glyph | one `TextRenderer` pass while it plays | an insight's summary, a result |
| `TypingIndicator` | three dots in a wave | 30 fps while allowed | a reply on its way, an assistant thinking |
| `.borderBeam` / `.borderGlow`, `SiriGlow`, `SiriWave`, `GradientOrbsBackground`, `.accentGlow` (1.x) | ambient light | see their docs | "working on it", AI and voice states, hero backgrounds |

## 7. Reduce Motion, resources and tests

- **Reduce Motion**: movement goes, fades stay (`.popIn`, `.riseIn`, `.textReveal`), bursts and
  shine do not play (haptics do), symbol effects draw the final state, loops stop.
- **Ambient loops** (`AuroraBackground`, `TypingIndicator`, `.symbolPulse`, the 1.x beams and
  glows) run inside `AmbientMotionGate`: off under Reduce Motion and, on iOS 27, while the system
  prefers reduced resource usage. They draw one still frame instead, with the same layout.
- **`.designKitMotion(false)`** stills all of DesignKit's motion below it: snapshot tests set it,
  an app can offer it as "reduce effects".
- **Snapshots** therefore show every component in its final, still state.

## 8. Performance rules

- Prefer system effects (symbol effects, content transitions, `scrollTransition`) to custom ones.
- A one-shot effect exists only while it plays; nothing waits in the background.
- Compute paths from the time (`TimelineView` + `Canvas`), not from per-frame state.
- Loops at 30 fps unless they track a finger; never a display-rate timer for decoration.
- No animated blur radius on large areas; a blur is for small, short-lived layers (a glyph, a
  4 pt rise).
- `drawingGroup()` only for many overlapping layers drawn every frame.
