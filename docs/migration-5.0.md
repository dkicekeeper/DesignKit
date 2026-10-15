# Moving to DesignKit 5.0

5.0.0 (2026-10) is a major release for two removals. 4.14.0 had brought a few views from Tenra
that repeat what DesignKit already had. The owner chose to fold them in and drop the duplicates
at once rather than deprecate them. The same release puts `EdgeBackdrop`'s blur where it works.
Nothing else is removed or renamed.

Dalada used neither removed name, so it moves to 5.0 by changing the pin. Tenra changes two
things, listed below.

## Removed

| Removed | Use | Why |
|---|---|---|
| `ListCard(title:content:)` | `FormSection(header:style: .glass)` | The same thing: an optional `SectionHeader` over a card of rows. The glass style draws it pixel for pixel (`listCards` snapshots unchanged), and it has `FormSection`'s `footer:` |
| `ListCardSkeleton(showsTitle:rows:)` | `FormSection(style: .glass) { ItemRowSkeleton() … }` | A container shows its rows' skeletons |
| `.edgeBackdrop(_:color:)` (on the bar's content) | `.scrollEdgeBackdrop(_:color:)` on the scroll view, before its `safeAreaBar` | Behind a `safeAreaBar`'s content the material lies apart from the scrolling content and has nothing to blur: on a device there was no blur, only the colour |

`EdgeBackdrop` itself stays, for a bar laid over content in one stack (a `ZStack`).

```swift
// 4.14
ListCard(title: "Payments") { rows }
ScrollView { thread }
    .scrollEdgeEffectStyle(.soft, for: .top)
    .safeAreaBar(edge: .top) { header.edgeBackdrop(.top) }

// 5.0
FormSection(header: "Payments", style: .glass) { rows }
ScrollView { thread }
    .scrollEdgeBackdrop(.top)          // hides the system's scroll edge effect on that edge
    .safeAreaBar(edge: .top) { header }
```

## Changed in the same release

- `PickerCarousel` runs on `SnapCardPicker(style: .centered(width:))`. It waits for a measured row
  before its first scroll, so a focused option set before it appears is centred. Its look and API
  are as before.
- `OptionCard`'s outline is 2 pt (3 pt before), as `PickerCarousel`'s and `IconPicker`'s: one
  `.selectionOutline(_:cornerRadius:)` for every option a person picks.
- `AmountEntrySheet`'s bar is `EditSheetContainer`'s: its ✕ is read as Cancel (it was Close), and
  ✓ plays the light haptic before the save's own.
- `NavigationSettingsRow(icon:title:value:)`: `value:` before the chevron, and the icon may be
  `nil`. `NavigationPickerRow(style: .list)` is that row.
- `FormSection` leaves out an empty `header`.

## Checking an app

```bash
grep -rn "ListCard\|\.edgeBackdrop(" --include=*.swift .
```

No output means the app builds on 5.0 unchanged. In Tenra (2026-10) it lists its assistant's
cards (`AssistantAttachmentCard`, `AssistantReplyView`) and the chat's bar (`AssistantChatView`).
