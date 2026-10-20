# Moving to DesignKit 7.0

7.0.0 (2026-10) is a major release for the owner's review of the rows and the icons. One row,
`UniversalRow(_:icon:value:hint:role:config:accessory:)`, is every row of a form card and a
settings list; the twelve rows that each did one thing are removed, at once, as both apps move in
the same step. Every icon is an `Icon`, and its size says what it is: under 44 pt a glyph with no
plate, from 44 pt a tile on its plate. The last deprecated names go too.

## The rows

The new row's `config` is `.standard` by default (a `FormSection` card); a row in a `List`
passes `.settings`, as the old settings rows did by default; a detail inside a padded container
passes `.info`, as `InfoRow` did. The icon is a glyph in the accent at 24 pt in every row.

| Removed | Use |
|---|---|
| `ToggleSettingsRow(icon:title:hint:iconColor:config:isOn:)` | `UniversalRow(title, icon:, iconColor:, hint:, config:, accessory: .toggle(isOn))` |
| `ActionSettingsRow(icon:title:iconColor:titleColor:isDestructive:config:action:)` | `UniversalRow(title, icon:, iconColor:, role: isDestructive ? .destructive : .standard, titleColor:, config:, accessory: .action(action))` |
| `ActionRowLabel(_:systemImage:tint:titleColor:config:)` | `UniversalRow(title, icon:, iconColor: tint, titleColor: titleColor ?? tint, config:)` with `.contentShape(Rectangle())`, as a `PhotosPicker`'s or `ShareLink`'s label (the init is `nonisolated`) |
| `NavigationSettingsRow(icon:title:value:iconColor:) { destination }` | `UniversalRow(title, icon:, iconColor:, value:, config: .settings, accessory: .navigation { destination })` |
| `CheckmarkRow(_:icon:value:isSelected:config:action:)` | `UniversalRow(title, leadingIcon: icon, value:, config:, accessory: .checkmark(isSelected:action:))` |
| `MenuPickerRow(icon:title:selection:options:)` | `UniversalRow(title, icon:, accessory: .menu(selection, options:))` |
| `NavigationPickerRow(icon:title:selection:options:style:)` | `UniversalRow(title, icon:, config: style == .list ? .settings : .standard, accessory: .picker(selection, options:))` |
| `DatePickerRow(icon:title:selection:displayedComponents:minDate:maxDate:)` | `UniversalRow(title, icon:, accessory: .date(selection, components:, from: minDate, through: maxDate))` |
| `StepperRow(icon:title:value:in:step:format:)` | `UniversalRow(title, icon:, accessory: .stepper(value, in:, step:, format:))` |
| `SliderRow(_:systemImage:value:in:step:valueText:hint:config:)` | `UniversalRow(title, icon:, hint:, config:, accessory: .slider(value, in:, step:, valueText:))` |
| `ColorPickerRow(selectedColorHex:title:palette:)` | `UniversalRow(title, accessory: .colors(selection, palette:))` (it pads itself now: drop the padding around it) |
| `InfoRow(icon:label:value:)`, `InfoRow(icon:label:amount:currency:prefix:)` | `UniversalRow(label, icon:, config: .info, accessory: .info(value))`, `.amount(amount, currency:, prefix:)` |
| `SliderRowSkeleton(showsHint:config:)`, `InfoRowSkeleton(showsIcon:)`, `ColorPickerRowSkeleton(swatches:)` | `UniversalRowSkeleton.slider(showsHint:config:)`, `.info(showsIcon:)`, `.colors(swatches:)` |

An app's convenience inits on a removed row (`extension MenuPickerRow where T == LoanType`) become
option lists for the accessory (`LoanType.menuOptions` passed to `.menu($type, options:)`).

```swift
// 6.1
FormSection {
    ToggleSettingsRow(icon: "moon.fill", title: "Quiet hours", config: .standard, isOn: $quiet)
    Divider().padding(.leading, AppSpacing.lg)
    MenuPickerRow(icon: "repeat", title: "Repeat", selection: $period, options: periods)
    Divider().padding(.leading, AppSpacing.lg)
    ActionSettingsRow(icon: "trash", title: "Delete", isDestructive: true, config: .standard) { delete() }
}
// 7.0
FormSection {
    UniversalRow("Quiet hours", icon: "moon.fill", accessory: .toggle($quiet))
    Divider().padding(.leading, AppSpacing.lg)
    UniversalRow("Repeat", icon: "repeat", accessory: .menu($period, options: periods))
    Divider().padding(.leading, AppSpacing.lg)
    UniversalRow("Delete", icon: "trash", role: .destructive, accessory: .action { delete() })
}
```

## The icons

Under 44 pt an `Icon` is a glyph: the symbol at its size, edge to edge, no plate, growing with the
text size (`scalesWithText: false` in a control of a fixed size). From 44 pt it is a tile: a plate
(the style's colour, else `Background.neutral1`, or its glass) and 20 % of the side around the
symbol to 63 pt, 25 % from 64 pt. A logo fills its shape at any size.

- A symbol of a component or an app is an `Icon`: `Image(systemName: "checkmark").font(.system(size: 16))`
  → `Icon("checkmark", size: AppIconSize.sm, scalesWithText: false)`; a symbol set in a text
  style → `Icon(name, size:)` at the style's size (caption → `xs`, bodySmall → `sm`, body → `md`).
  It takes the colour around it (`tint: .inherit`), so `.foregroundStyle` and symbol effects work
  as on an `Image`.
- Where iOS draws the symbol, it stays an `Image` / `Label`: a toolbar's item, a menu's or context
  menu's item, a swipe action, a tab, a segmented picker's segment, a symbol inside a line of text.
- An icon that says something on its own (a status, "Saved") gets
  `.accessibilityElement(children: .ignore).accessibilityLabel(…)`: an `Icon` is decorative.

## The rest

| Removed | Use |
|---|---|
| `StatusIndicatorBadge(status:font:)`, `StatusIndicatorBadgeSkeleton(font:)` | `size:` with an `AppIconSize` (`md` for the old default) |
| `PackedCircleIconsStyle.fan` (drawn as the shelf since 4.4.0) | `.shelf` |

## What looks different

- Row icons are 24 pt everywhere and their symbols the full 24 pt (19.2 before), so the titles of
  a card line up. A date row's title is in DesignKit's type with the picker on the trailing edge.
- Glyphs under 44 pt have no grey plate; tiles from 44 pt always have one, `EmptyState`'s symbol
  included.
- A few symbols moved to the nearest size of the scale (CHANGELOG.md, 7.0.0).
