---
status: ready
type: bug
priority: 1
size: s
created: 2026-11-26
updated: 2026-11-26
---
# Gallery badges: .dsRefreshable names no app

Why: CI's `Gallery badges` job fails on every run since Dalada and Platina started using
`.dsRefreshable`: its Gallery page names no app, so `main` and every PR show a red check.

Done when:
- the page of `.dsRefreshable` / `RefreshIndicator` in `Gallery/Gallery/Screens/FeedbackScreen.swift`
  names Dalada and Platina (`gallery_badges.py fix` does it);
- `python3 .github/scripts/gallery_badges.py check` passes against the three apps' `main`.

Notes: the job's output on 2026-11-26: "badge none, used by dalada, platina".
