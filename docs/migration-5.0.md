# Moving to DesignKit 5.0

5.0.0 (2026-10) is a major release for two removals. 4.14.0 brought a few views from Tenra that
repeat what DesignKit already had; the owner chose to fold them in and drop the duplicate at once
rather than deprecate it. And `EdgeBackdrop` goes: compared on a device with the system's scroll
edge effect, the owner chose the system's hard one for a bar over a chat. Nothing else is removed
or renamed.

Dalada uses neither, so it moves to 5.0 by changing the pin. Tenra changes its assistant's cards
and its chat's bar.

## Removed

| Removed | Use | Why |
|---|---|---|
| `ListCard(title:content:)` | `FormSection(header:style: .glass)` | The same thing: an optional `SectionHeader` over a card of rows. The glass style draws it pixel for pixel (the `listCards` snapshots are unchanged), and it has `FormSection`'s `footer:` |
| `ListCardSkeleton(showsTitle:rows:)` | `FormSection(style: .glass) { ItemRowSkeleton() … }` | A container shows its rows' skeletons |
| `EdgeBackdrop`, `.edgeBackdrop(_:color:)`, `EdgeBackdropMetrics` | The system's scroll edge effect, `.scrollEdgeEffectStyle(.hard, for: .top)` on the scroll view under the bar | The owner compared them in Tenra's chat layout on an iOS 27 device and chose the system's hard one; the hand-drawn blur and colour are not needed |

```swift
// 4.14
ListCard(title: "Payments") { rows }
thread
    .scrollEdgeEffectStyle(.soft, for: .top)
    .safeAreaBar(edge: .top) { ten.frame(maxWidth: .infinity).edgeBackdrop(.top) }
// 5.0
FormSection(header: "Payments", style: .glass) { rows }
thread
    .scrollEdgeEffectStyle(.hard, for: .top)
    .safeAreaBar(edge: .top) { ten.frame(maxWidth: .infinity) }
```

Present the chat from the screen, not from a row inside a scroll view: a screen presented with
`.fullScreenCover` from inside a scroll view draws no scroll edge effect under its own bar
(docs/gotchas.md).

## Changed in the same release

- `PickerCarousel` runs on `SnapCardPicker(style: .centered(width:))`, its own row moved there as
  it was. Its look, behaviour and API are as before.
- `OptionCard`'s outline is 2 pt (3 pt before), as `PickerCarousel`'s and `IconPicker`'s: one
  `.selectionOutline(_:cornerRadius:)` for every option a person picks.
- `AmountEntrySheet`'s bar is `EditSheetContainer`'s: its close button is read as Cancel (it was
  Close), and its save button plays the light haptic before the save's own.
- `NavigationSettingsRow(icon:title:value:)`: `value:` before the chevron, and the icon may be
  `nil`. `NavigationPickerRow(style: .list)` is that row.
- `FormSection` leaves out an empty `header`.

## Checking an app

```bash
grep -rnE "ListCard|EdgeBackdrop|edgeBackdrop" --include=*.swift .
```

No output means the app builds on 5.0 unchanged. In Tenra (2026-10) it lists its assistant's
cards (`AssistantAttachmentCard`, `AssistantReplyView`) and its chat (`AssistantChatView`).
