---
status: idea
type: feature
priority: 3
size: m
created: 2026-11-26
updated: 2026-11-26
---
# A data palette: AppColors.Data for several series

Benchmark round 4 (Astryx), candidate 13 in [benchmark.md](../benchmark.md), to do when an app asks for it. Astryx has 10 categorical series colours in a fixed order, 9 sequential scales of 5 steps and a neutral for axes. Here the caller passes a series colour (`ChartColoring`), `CalendarHeatmap` takes five opacities of one colour, and there is no set for several series in order. Proposed: `AppColors.Data` (`categorical(_:)`, `sequential(_:step:)`, `neutral`).
