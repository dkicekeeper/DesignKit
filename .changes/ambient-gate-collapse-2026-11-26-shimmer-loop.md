---
bump: patch
---
A fix for 8.22.0's off-screen gate: a skeleton's shimmer or a border beam scrolled out of sight no longer starts and stops without end, which hung the screen it was on.

### Fixed

- `AmbientMotionGate`: a view with no size gives no answer and the gate keeps what it had. A skeleton's shimmer and a border beam drew nothing while stopped, so the gate read them as near, started them, read them as far and stopped them again, in the same layout pass and without end. In Platina a screen pushed onto a navigation stack while pictures were still loading (their placeholders shimmer) hung for good, its memory growing; elsewhere the loop kept the main thread busy every frame.
- `.shimmer()` and `.borderBeam` keep their frame with a clear view while stopped, so the gate measures where they are.

### Gallery and tooling

- Unit tests for `AmbientViewport` (`AmbientViewportTests`): no size gives no answer, near and far down, across and in nested scroll views.
- docs/design-system.md: a loop with nothing to show while stopped keeps its frame.
- `SurfaceStyle`'s Gallery page names Tenra too, whose code uses it.
