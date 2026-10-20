# Moving to DesignKit 6.0

6.0.0 (2026-10) is a major release for one change, the owner's review of Tenra's background
screen: `OptionCardPicker` is a carousel of large previews and nothing else. The list of cards
(`style: .list`, `OptionCard`) and 5.2.0's row of small cards under one preview are gone; each
option is now its own large preview, the centred one the choice, the neighbours peeking at the
sides. Nothing else is removed or renamed.

Dalada does not use the picker, so it moves to 6.0 by changing the pin. Tenra drops one argument
from its `HomeBackgroundPicker`.

## Removed

| Removed | Use | Why |
|---|---|---|
| `OptionCardPicker(…, style:, …)`, `OptionCardPicker.Style`, `OptionCardPickerStyle` (`.list`, `.carousel`) | `OptionCardPicker(…)` without `style:` | The carousel is its only look, so there is nothing to choose |
| `OptionCard(title:isSelected:artwork:)` | `OptionCardPicker` | It was the list's card; no app used it on its own |
| `OptionCardSkeleton()` | `OptionCardPickerSkeleton()` | The list's card |
| `OptionCardCarouselSkeleton()` | `OptionCardPickerSkeleton()` | The same placeholder, renamed for the picker: three previews, the side ones smaller and paler |

```swift
// 5.5
OptionCardPicker(HomeBackgroundMode.allCases, selection: $mode, style: .carousel,
                 title: { $0.localizedTitle }) { mode in
    preview(mode)
} settings: { mode in
    settings(mode)
}
// 6.0
OptionCardPicker(HomeBackgroundMode.allCases, selection: $mode, title: { $0.localizedTitle }) { mode in
    preview(mode)
} settings: { mode in
    settings(mode)
}
```

## What looks different

- No row of small cards: each option is a 180 × 270 preview in a phone's shape (160 × 240 for
  the one preview before), its name under it, in the accent for the chosen one, which has the
  accent outline. Swipe the previews, or tap a neighbour, to choose.
- Only the chosen preview moves; the neighbours stand still, as the small cards did.
- The settings stay under the carousel. Put them in DesignKit's form rows: a `FormSection` of
  `ActionRowLabel` (as a `PhotosPicker`'s label), `ToggleSettingsRow`, `SliderRow` and
  `ActionSettingsRow` with the `.standard` config, `Divider().padding(.leading, AppSpacing.lg)`
  between them. `SliderRow` takes `config:` since 6.1.0; before that it had no side padding in a
  card.
