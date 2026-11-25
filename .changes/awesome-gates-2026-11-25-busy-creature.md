---
bump: minor
---
The creature shows what it is busy with: four new moods for the steps of an assistant's work, each a shape of the swarm with the eyes on the work. It reads clearly on a white page, its thinking rings carry comets, its listening rides two waves, its avatar reads when small, and it and every other ambient loop stop while scrolled out of sight.

### Added

- `ParticleCreature.Mood.searching`: the swarm stands as a globe of rows and a beam sweeps round it like a radar's; what it reaches swells and lights up, then fades behind it, so it reads in ink on a white page too. The eyes follow the beam. For a search, a lookup.
- `ParticleCreature.Mood.calculating`: on the same globe, rounds of three quarter turns of its bands and the three turned back, each with a little click; when the round comes out right the core flares and the eyes smile. The eyes on the band that turns. For sums, a forecast, a check.
- `ParticleCreature.Mood.connecting`: about thirty particles become nodes linked by lines of light, pulses hop from node to node along the links and light the nodes they leave and reach; the rest is a faint sphere. The eyes follow a pulse. For a sync, a tool, a change being made.
- `ParticleCreature.Mood.writing`: a ribbon of lanes runs round the sphere behind a pen point, its line staying where it was written, bright at the pen and fading behind it; the rest is a faint sphere. Lids lowered, the eyes on the pen. For a reply on its way.

### Changed

- `ParticleCreature` `.thinking`: a few comets of particles run round each ring of the gyroscope over a faint track that barely moves (the whole ring turned as one before), so the spin reads on a white page too.
- `ParticleCreature` `.listening` without a `level:`: two waves at their own pace, the particles on their crests nearer, larger and brighter.
- `ParticleCreature(style: .compact)` under 45 pt: fewer, larger particles (48 at 24 pt, 90 from about 45 pt as before), their size shrinking more slowly than the sphere's, so a small avatar shows its dots.
- `ParticleCreature` on a light page reads clearly on white: every colour is inked to a luminance cap, so a particle of middle depth is at least 3.2:1 on white in every mood (2.1 to 3.1 before) and a cyan or a yellow reads like a violet; the outline holds all round the sphere, the sphere is a faint disc of its colour, the dots are a fifth larger, the haze is closer and stronger and the shadow deeper. Under Increase Contrast it is inked more strongly still (5.1:1). Dark mode is unchanged.
- `ParticleCreature` in dark mode: the rim's glow and the answer's waves glow through a radial gradient instead of a blur drawn every frame; the same fall-off, less work each frame.
- `AmbientMotionGate`, and every view behind it (`ParticleCreature`, `AuroraBackground`, `TypingIndicator`, `.thinkingShimmer`, `EdgeGlow`, `VoiceWave`, `LiveSessionBar`, `PackedCircleIcons`, skeletons' shimmer and the rest): a view scrolled more than half a scroll view's size out of sight, down or across, stops and draws its still frame; it starts again before it comes back into sight.

### Migration

- A `switch` over `ParticleCreature.Mood` without a `default` needs the four new cases; map them to what the app shows for each step:

```swift
case .searching, .calculating, .connecting, .writing: // the busy moods
```

- To use them, give each step of the assistant its mood beside its words (docs/adoption.md): `.searching` while it looks through data, `.calculating` for sums, `.connecting` while a tool changes data or a sync runs, `.writing` once the reply is being written, `.thinking` for the rest.

### Gallery and tooling

- `ParticleCreature`'s page offers the four moods, with notes on them and on the comets, and a do and a don't; a snapshot of the busy moods in the hero and the avatar (`particleCreatureBusy`, light and dark).
- Unit tests for the busy geometry (`ParticleCreatureBusyTests`): the globe holds every particle, a round of sums comes out exactly as it began, the pulses travel without jumps, every spot stays in the creature's square; and for the ink (`CreatureInkTests`): a light colour is taken down to its contrast on white, keeping its hue.
- docs/design-system.md, docs/motion.md and docs/snapshots.md describe the moods, the comets, the gate's new signal and the glow without a blur; docs/adoption.md proposes the moods for Tenra's and Platina's assistants.
