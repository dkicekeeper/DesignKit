# Motion & Effects

DesignKit's motion is meant to be rich but light: every movement says something, ends before the
eye starts waiting, costs as little as the system allows, and stands still when the person or the
device asks. This page is the rule book and the catalogue (2.2.0, 2.3.0). The Gallery's
**Motion** and **Effects** sections play every item.

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
6. **Pair with haptics, not sound.** The touch and the picture say the same thing at the same
   moment: a selection tick as the segment moves, the celebration pattern with the confetti
   (`HapticCue`, §7). The haptic stays when the motion is off.

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
| `.symbolColorRenderingMode(.gradient)` (no motion, 2.3.0) | SF Symbols 7 gradient of the tint, for depth | `HeroSymbol`, `EmptyState`'s icon |
| `ProgressRing(celebratesCompletion: true)` (2.3.0) | a checkmark draws itself in at 100 %; the ring is green at any fill (2.3.1) | goal rings |

Loops go through `AmbientMotionGate`; all of them stop under Reduce Motion and
`.designKitMotion(false)`, drawing the symbol still in its final state.

## 5. Transitions

| Transition | Movement | Under Reduce Motion | For |
|---|---|---|---|
| `.popIn` | grows from 92 % + fade | fade | a chip, a badge, a toast, a tooltip, `TypingIndicator` |
| `.riseIn` | rises 12 pt, sharpens from a 4 pt blur + fade | fade | a card, a section, a banner |
| `.textReveal` | glyph by glyph: rise, sharpen, fade | whole-text fade | text that arrives: an insight, an answer |
| `.skeletonReveal` / `SkeletonReveal(isLoading:)` (2.3.0) | comes into focus from an 8 pt blur, 98 % → 100 % + fade, while the skeleton fades out | cross-fade | content replacing its skeleton; `FinanceCard`'s amount |
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
| `.borderGlow` (1.x) | a static halo round a card | see its docs | "working on it" |

**2.9.0: text that arrives, cards that cascade, marbles**

| Effect | What | Cost | Use |
|---|---|---|---|
| `StreamingText(_:highlights:)` | words arrive one by one, each sliding in out of a blur (`.blurSlideWord`); a word that stays in place keeps its identity, so a refined transcript does not replay | one short transition per new word | a live transcript, text a model is writing |
| `.cascadeIn(index:)` | cards that arrive together fade in and rise 12 pt, `index × 80 ms` apart (gentle spring); under Reduce Motion the same cadence without the rise | one transition per card | the cards a result brings (Tenra's voice input) |
| `PackedCircleIcons` (`.glossy`) | the marbles burst out of the middle one after another with a little overshoot, then sway by up to 2 pt, each on its own beat | one spring per marble, then a repeating ease on an offset | the circles of a home card |

**2.6.0: surfaces and moments**

| Effect | What | Cost | Use |
|---|---|---|---|
| `.holographic(strength:)` | a holographic foil: rainbow bands slide as the finger moves, a sheen where the light falls | one Metal colour effect, redrawn only while the finger moves | a medal, a premium card; with `.interactiveTilt` |
| `.transition(.dissolve)` | the view breaks into dust as it is removed, its edge glowing; inserted, the dust gathers | one Metal layer effect, only during the transition | deleting something the person owned |
| `ScrambleText(_:)` | each character flickers through random ones of its kind and settles, left to right | 30 fps for 0.7 s, then paused | a result just worked out: a total, a code, a score (`ScoreGaugeCard`/`ScoreCard(decodesScore:)`, 2.7.0) |
| `.spotlightAnchor(_:)` + `.spotlight(_:message:)` | the screen dims except a cut-out round one view, with a `Tooltip` beside it; the cut-out moves on a spring | one shape, animated only when it moves | a new feature, the steps of a tour |

**2.5.0: still light for backgrounds**

| Effect | What | Cost | Use |
|---|---|---|---|
| `AuroraBackground(_ spots:)` | weighted pools of colour, each sized and brightened by its weight, sampled into a 5×5 mesh; still by default, flowing into a change of data in 0.6 s. Replaces `GradientOrbsBackground` (deprecated) | one mesh, no blur, drawn once | a home screen's background under Liquid Glass |
| `.accentGlow(style: .aurora)` (the default) | a band of mesh light in the tint and its neighbours, fading inwards; `drifts:` moves it | one mesh, no blur (the `.soft` style blurred a circle by 120 pt) | heroes of detail screens, onboarding |
| `.grain(_:)` | a fine, still grain against banding | one colour effect, the same every frame | built into `AuroraBackground` and the aurora glow |

**Backgrounds under Liquid Glass hold still.** A glass surface recomputes its blur from what is
behind it; a background that moves makes every glass card on the screen redraw each frame. So
the backgrounds of everyday screens (`AuroraBackground(_ spots:)`, `heroAccentGlow`) are still,
and drift is for screens seen briefly (onboarding, a paywall).

**2.4.0: the voice, and work in progress**

| Effect | What | Cost | Use |
|---|---|---|---|
| `VoiceWave(level:phase:style:)` | `.ribbons`: four ribbons of aurora light rising with each syllable, each on its own beat; `.orb`: a liquid mesh-gradient sphere whose rim ripples and glow swells. `.thinking` settles it with a light running through | one Canvas, up to 60 fps, only on screen | the picture by the microphone while a person speaks |
| `EdgeGlow(level:)` | light along the screen's edges: aurora colours flow round the rim; the voice widens, brightens and speeds it. Replaced `SiriGlow` / `SiriWave` (removed in 3.0.0) | one Metal colour effect, no blur, 30 fps | the screen while the app listens |
| `.borderBeam(beams:)` | a comet runs along the border itself (one speed and length on every side), a bloom at its head, a fading tail, a faint spill on the edge | one Canvas, display rate while active | a card being worked on |
| `.thinkingShimmer(isActive:)` | a band of aurora colour runs through text | one masked gradient, 30 fps | "Listening…", "Analysing…" |

The voice level is the app's (its microphone's RMS, 0…1). `VoiceWave` and `EdgeGlow` smooth it
themselves, fast up and slow down, so speech swells instead of flickering; without a level they
breathe on their own.

**2.3.0: data, completion and depth**

| Effect | What | Cost | Use |
|---|---|---|---|
| `LiveAmountText` | the digits roll up from zero on first appearance; a change flashes green (up) or red (down) for 0.7 s | `numericText` of `FormattedAmountText`; one short sleep ends the flash | a hero balance, a total that just updated (`BalanceCard(isLive:)`, 2.7.0) |
| `.chartDrawIn(delay:)` | the chart is revealed from its leading edge once, with a soft front edge | one mask, 0.9 s | built into `LineChart`, `BarChart`, `HeroSparkline`; any Swift Chart |
| `.completionMoment(isComplete:tint:in:)` | when `isComplete` turns true: a glow of the shape flares and fades, the success haptic plays | one blurred shape for 0.8 s | `ProgressRing(celebratesCompletion:)`, `ChecklistSummaryRow`'s and `TargetProgressCard`'s bars; any goal |
| `GlassActionMenu` | a floating glass button flows open into its actions (Liquid Glass morph, `glassEffectID`) | the system's | the add button of a screen |
| `.scrollHero(parallax:fades:)` | stretches when pulled down; drifts slower and fades as it scrolls away | one `visualEffect`, no re-render | the image or header at the top of a detail screen |
| onboarding parallax | in an `OnboardingPager` each page's `HeroSymbol` lags behind as it swipes, shrinking and fading a little | one `visualEffect` | built in |
| `.ripple(trigger:at:)` / `.rippleOnTap()` | a ripple through the view itself, like water | a Metal layer effect, only while it plays (1.6 s) | a moment that deserves it: a goal reached, a big confirmation. The heaviest effect here: never on every button |

**Ripple and its shaders.** The shader sources are `Shaders/Ripple.metal` (after Apple's WWDC24
sample) `Shaders/EdgeGlow.metal` (2.4.0), `Shaders/Grain.metal` (2.5.0), `Shaders/Holographic.metal`
and `Shaders/Dissolve.metal` (2.6.0). The package does not compile it: Xcode 26's Metal Toolchain is an optional ~700 MB
download, missing on some CI runners, and every app would need it. Instead
`.github/workflows/shaders.yml` runs `Shaders/build.sh` on a branch where a shader changed and
commits two libraries to `Sources/DesignComponents/Resources/Shaders`:
`DesignKitShaders-iphoneos.metallib` and `DesignKitShaders-iphonesimulator.metallib`.
`ShaderLibraryTests` checks that the library is in the bundle and that the GPU accepts each
shader. To add a shader: put the `.metal` file in `Shaders/`, push, wait for the workflow's
commit, pull.

## 7. Haptics (`HapticCue`, 2.3.0)

| Cue | Feedback | Built into |
|---|---|---|
| `.tap` | light impact | |
| `.select` | selection | `SegmentedPicker` (with `ChipPicker`, `Rating`, `IconPicker`, which play it already) |
| `.tick` | rigid impact, 0.7 | `SliderRow`: every step of a stepped slider, either end of a smooth one |
| `.confirm` | success | `.completionMoment` |
| `.warn` | warning | |
| `.fail` | error | |
| `.celebrate` | success, then two rising taps (0.18 s, 0.32 s) | `.celebration` |

`.hapticCue(.select, trigger: selection)` plays with a change of state, `HapticManager.play(.confirm)`
from an action. Haptics are not motion: Reduce Motion and `.designKitMotion(false)` leave them
on; the system's own switch turns them off.

## 8. Reduce Motion, resources and tests

- **Reduce Motion**: movement goes, fades stay (`.popIn`, `.riseIn`, `.textReveal`,
  `.skeletonReveal`), bursts, shine, glows and ripples do not play (haptics do), symbol effects
  draw the final state, loops stop, amounts show their value without rolling or flashing,
  charts are there at once, parallax stops (`.scrollHero` keeps its stretch: it follows the
  finger).
- **Ambient loops** (`AuroraBackground`, `TypingIndicator`, `.symbolPulse`, `LiveSessionBar`'s
  recording dot, `PackedCircleIcons`' swaying marbles, the 1.x beams and glows) run inside `AmbientMotionGate`: off under Reduce Motion and, on iOS 27, while the system
  prefers reduced resource usage. They draw one still frame instead, with the same layout.
- **`.designKitMotion(false)`** stills all of DesignKit's motion below it: snapshot tests set it,
  an app can offer it as "reduce effects".
- **Snapshots** therefore show every component in its final, still state.

## 9. Performance rules

- Prefer system effects (symbol effects, content transitions, `scrollTransition`) to custom ones.
- A one-shot effect exists only while it plays; nothing waits in the background.
- Compute paths from the time (`TimelineView` + `Canvas`), not from per-frame state.
- Loops at 30 fps unless they track a finger; never a display-rate timer for decoration.
- No animated blur radius on large areas; a blur is for small, short-lived layers (a glyph, a
  4 pt rise, one card coming into focus for 0.45 s). Never a whole screen, never in a loop.
- A Metal shader runs only while its effect plays (`layerEffect(isEnabled:)`), and ships
  compiled (§6, "Ripple and its shaders").
- Scroll-driven effects read geometry in `visualEffect`, never into `@State` per frame.
- `drawingGroup()` only for many overlapping layers drawn every frame.
