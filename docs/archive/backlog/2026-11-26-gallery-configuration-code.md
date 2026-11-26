---
status: done
type: feature
priority: 3
size: m
created: 2026-11-26
updated: 2026-11-26
pr: 129
---
# Gallery: the code of a page's current configuration

Benchmark round 4 (Astryx), candidate 23 in [benchmark.md](../benchmark.md), to do when an app asks for it. The SwiftUI call with the chosen parameters and "Copy" on a component page.

Done in #129: the code of the current configuration with Copy (`ComponentPage(code:)`, `SwiftCode`) and cases from life (`cases:`) on the 40 most used pages, the parameters from docs/components.json on every page, and the canvas's bar (app, text size, direction, width); design in [archive/plans/2026-11-26-gallery-p2-p3-design.md](../plans/2026-11-26-gallery-p2-p3-design.md). The other pages get code and cases when they are next touched (`.github/scripts/gallery_coverage.py` lists them).
