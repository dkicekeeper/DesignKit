# Moving to DesignKit 5.0

5.0.0 (2026-10) is a major release for one removal. 4.14.0 brought a few views from Tenra that
repeat what DesignKit already had. The owner chose to fold them in and drop the duplicate at once
rather than deprecate it. Nothing else is removed or renamed.

Dalada does not use `ListCard`, so it moves to 5.0 by changing the pin. Tenra changes its
assistant's cards.

## Removed

| Removed | Use | Why |
|---|---|---|
| `ListCard(title:content:)` | `FormSection(header:style: .glass)` | The same thing: an optional `SectionHeader` over a card of rows. The glass style draws it pixel for pixel (the `listCards` snapshots are unchanged), and it has `FormSection`'s `footer:` |
| `ListCardSkeleton(showsTitle:rows:)` | `FormSection(style: .glass) { ItemRowSkeleton() … }` | A container shows its rows' skeletons |

```swift
// 4.14
ListCard(title: "Payments") { rows }
// 5.0
FormSection(header: "Payments", style: .glass) { rows }
```

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
- `EdgeBackdrop`'s blur reaches four fifths of the backing and is deeper, under a lighter colour.
  Hide the system's scroll edge effect on that edge of the scroll view: as it comes, or `.soft`,
  it fades the content out under the bar before the backing blurs it. Tenra's chat:
  `.scrollEdgeEffectStyle(.soft, for: .top)` → `.scrollEdgeEffectHidden(true, for: .top)`.

## Checking an app

```bash
grep -rn "ListCard" --include=*.swift .
```

No output means the app builds on 5.0 unchanged. In Tenra (2026-10) it lists its assistant's
cards (`AssistantAttachmentCard`, `AssistantReplyView`).
