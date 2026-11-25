---
bump: patch
---
The Gallery finds a component by typing, previews each app as it is set up, and shows a component in a card or on colour.

### Gallery and tooling
- Search on the home screen: the component pages by name (a skeleton, a 1.x name with View and a `.ds` modifier find their component) and by a word of their summary, and the foundations by title.
- One menu of app presets instead of separate theme and surface menus: Tenra (indigo, glass), Dalada (green, grey cards), Platina (grey cards) and a custom accent from a colour picker with its surfaces.
- Platina's preset is Plasma (light `#D6006F`, dark `#FF4FA0`), the owner's choice for Platina's accent; docs/adoption.md tells Platina's session how to set it.
- Every page's canvas has a context beside its light and dark switch: on the page, in a card of the current surfaces, or on the accent with the hero's white tone. Snapshots of a page in a grey card and on colour (`GalleryPagesSnapshotTests.canvasContexts`).
