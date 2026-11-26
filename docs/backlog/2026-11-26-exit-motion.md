---
status: idea
type: feature
priority: 3
size: m
created: 2026-11-26
updated: 2026-11-26
---
# An exit motion: AppMotion.exit

Benchmark round 4 (Astryx), candidate 14 in [benchmark.md](../benchmark.md), to do when an app asks for it. Astryx has its own curve and duration for leaving (175 ms, accelerating, no bounce) and a rule: a tooltip and a menu vanish at once, leaving retraces the entrance. Here the springs are by purpose and there is none for leaving. Proposed: `AppMotion.exit` and a section in motion.md.
