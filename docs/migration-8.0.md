# Moving to DesignKit 8.0

8.0.0 (2026-10) is a major release for the owner's review of the apps' screens: one look,
Tenra's Analytics and Finances everywhere. A screen is a white page of Liquid Glass sections and
cards, in forms, settings and lists alike; a row is 56 pt with one divider under its text; a
section's title is bold in sentence case; and every list of the things a person keeps has the
same actions. `FormSection`'s `style:` and `SectionHeader`'s `.compact` are removed at once, as
both apps move in the same step.

## Sections

`FormSection` is a glass card (`cardStyle()`, Material up to 7.x) that pads its rows at the sides
and draws the dividers between them itself.

| Removed | Use |
|---|---|
| `FormSection(header:footer:style: .card) { … }` | `FormSection(header:footer:) { … }` |
| `FormSection(header:footer:style: .glass) { … }` (`ListCard` before 5.0.0) | `FormSection(header:footer:) { … }`: the rows now have a divider between them and no `sm` gap |
| `Divider()` / `Divider().padding(.leading, AppSpacing.lg)` between a section's rows | nothing: the section draws a `RowDivider` under the upper row's text |
| `SectionHeader(_:style: .compact)` | `SectionHeader(_:)` (`.default`, bold in sentence case, no padding of its own; with `.screenPadding()` on a screen) |
| `SectionHeaderSkeleton(style: .compact)` | `SectionHeaderSkeleton()` |

A custom row in a section with something before its text (a tile, a check) says where its text
starts, so the divider starts there too: `.rowDividerInset(AppIconSize.Tile.sm + AppSpacing.md)`.
A `UniversalRow` does it on its own; a `UniversalRow` inside a `PhotosPicker`'s or a `Button`'s
label does not pass it out, so put the modifier on the picker.

The card pads every row at the sides, so a row's own side padding inside a section goes
(`.padding(.horizontal, AppSpacing.lg)` on a custom row, `.padding(AppSpacing.md)` around a
`SegmentedPicker` → `.padding(.vertical, AppSpacing.md)`). Content that scrolls under the card's
edges takes the card's whole width with `.fullWidthRow()`: `ChipPicker(inset:)` does it on its
own, a `VStack` of them or a photo strip with `.contentMargins` says it.

```swift
// 7.x
FormSection(header: "Payment") {
    UniversalRow("Repeat", icon: "repeat", accessory: .menu($period, options: periods))
    Divider().padding(.leading, AppSpacing.lg)
    UniversalRow(config: .standard) { Text("Bank") } trailing: {
        FormTextField(text: $bank, placeholder: "Bank name", style: .inline)
    }
}

// 8.0
FormSection(header: "Payment") {
    UniversalRow("Repeat", icon: "repeat", accessory: .menu($period, options: periods))
    UniversalRow("Bank", icon: "building.columns", accessory: .textField($bank, placeholder: "Bank name"))
}
```

## Rows

`RowConfiguration.standard` is 16 pt above and below and none at the sides (12 × 16 before): a row
is 56 pt with its 24 pt icon, and the card it is in pads it. A `.standard` row on a bare
`cardStyle()` stack needs `.padding(.horizontal, AppSpacing.lg)` on the stack, or the stack
becomes a `FormSection`. `.settings` (a `List`'s row) and `.info` (a detail in a padded card) are
as they were.

`RowAccessory.textField(_:placeholder:keyboard:)` (new) is a value typed on the trailing edge, in
place of a hand-built `UniversalRow { … } trailing: { FormTextField(style: .inline) }`.

## Screens

A settings screen, a filter screen or any `List` of grouped rows becomes a `ScrollView` of
`FormSection`s:

```swift
// 7.x
List {
    Section(header: SectionHeader("Notifications", style: .compact)) {
        UniversalRow("Reminders", icon: "bell", config: .settings, accessory: .toggle($remind))
    }
}

// 8.0
ScrollView {
    VStack(spacing: AppSpacing.xl) {
        FormSection(header: "Notifications") {
            UniversalRow("Reminders", icon: "bell", accessory: .toggle($remind))
        }
    }
    .screenPadding()
}
```

## Lists of things

A list of accounts, deposits, loans, debts, goals, categories or subscriptions (Dalada: trips,
places, gear) is a `CardList` with the toolbar every list shares. Swipe actions go: a long press
shows the item's menu (Edit, Delete with a confirmation), the toolbar selects several to delete
and changes the order.

```swift
// 7.x
List {
    ForEach(accounts) { account in
        NavigationLink(value: account) { AccountRow(account) }
            .swipeActions { Button("Delete", role: .destructive) { … } }
    }
    .onMove(perform: moveAccounts)
}
.environment(\.editMode, $editMode)

// 8.0
@State private var mode: CardListMode = .browsing
@State private var selection: Set<Account.ID> = []

ScrollView {
    CardList(accounts, mode: mode, selection: $selection, onMove: moveAccounts) { account in
        NavigationLink(value: account) { AccountCardContent(account) }
            .buttonStyle(.plain)
            .contextMenu { editButton(account); deleteButton(account) }
    }
    .screenPadding()
}
.cardListToolbar(mode: $mode, selection: $selection, allIDs: accounts.map(\.id),
                 addLabel: "New account", onAdd: addAccount, onDeleteSelected: confirmDeleteSelected)
```

A list whose order is fixed by a sort (subcategories by name or by use) passes no `onMove` and
`canReorder: false`; a short list of rows takes `layout: .section`.
