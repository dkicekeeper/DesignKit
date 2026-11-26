---
bump: patch
---
The Gallery helps choose a component for a screen: its page shows the code of what the controls set, ready data from life in one tap and the component's parameters, and its canvas switches the app, the text size, the direction and the width. The Gallery runs on an iPad and a Mac. Nothing changes in an app.

### Gallery and tooling

- Every component page's canvas has a bar: the app whose accent and surfaces it shows (Tenra, Dalada, Platina; the home screen's preset, switched without leaving the page), the text size (the device's, or xS to AX5), right to left, and on a wide screen the width (a phone's, a screen's readable column, the whole page). The size, the direction and the width hold for every page, so a section reads in AX3 or right to left by paging through it; the home screen's menu puts them back.
- Every page lists its component's parameters from docs/components.json, an initialiser at a time, each parameter with its type and default; the file goes in the Gallery's bundle, as CHANGELOG.md does.
- The 40 pages of the components the apps use most show the code of the current configuration (`ComponentPage(code:)`, built with `SwiftCode`, the defaults left out, with Copy) and three to five cases from life (`ComponentPage(cases:)`): a long name, zero, a huge amount, no photo, offline. CI's Changelog job lists the pages without them in its summary (`.github/scripts/gallery_coverage.py`); the others get them when they are next touched.
- The Gallery runs on an iPad and, as an app for iPad, on a Mac: the home screen is a sidebar beside the open section, and a wide page puts its cases and controls beside the canvas.
- Unit tests for the code (`SwiftCode`) and for reading the parameters of every signature in the reference (`GalleryCodeTests`); the snapshots of whole Gallery pages show the canvas's bar.
