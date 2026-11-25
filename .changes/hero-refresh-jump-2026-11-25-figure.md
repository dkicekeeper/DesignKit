---
bump: patch
---
A picture hero's figure no longer jumps when a screen is pulled to refresh. Found by the owner on Platina's game screen.

### Fixed

- `.heroScrollEdge()`: pulled far enough, a `.refreshable` screen's spinner adds its height to the scroll view's top inset while the content stays under the finger. The hero read it as taller bars, so the figure of `.heroBackground(picture:subject:)` dropped by the spinner's height mid-pull while the picture behind it did not. The bars' inset now grows only while the content is not pulled down, and the scroll is counted from it, so the figure and the picture stretch together through the refresh.
