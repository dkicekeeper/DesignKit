---
bump: minor
---
A counter of a `StatsStrip` can explain itself: `info:` puts an `InfoTip` after its caption. Platina's trophy screen explains a trophy's share of players this way, and Platina is the first app to use `InfoTip`.

### Added

- `StatsStrip.Item(value:title:info:infoTitle:)`: `info:` is the text of an `InfoTip` after the counter's caption, on its first line (what the number means, where it comes from); `infoTitle:` is the tip's heading, the counter's full name when the caption is only a unit ("Share of players" over "1.8% of players"). VoiceOver reads the counter, then the tip as a button of its own. Without `info:` a counter looks and reads as before.

### Gallery and tooling

- `StatsStrip`'s page explains its first counter with a switch, and a note on `info:`; a snapshot of a counter with its tip (`statsStripWithInfo`, light, dark and large text).
- `InfoTip`'s page carries Platina's badge: its profile explains the share of players over its rarest trophies. `gallery_badges.py` counts the `.infoTip` modifier as a use of `InfoTip`.
- docs/adoption.md: Platina's `InfoTip` and readable colours in use (a trophy row's metal and earned date in `AppColors.readable` and `Status.positiveText`).
