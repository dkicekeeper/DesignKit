# Migrating to DesignKit 2.0

2.0.0 is a major release because it removes names that were deprecated in 1.13.0 and changes how
some shared components look. Everything else renamed in 2.0 is still there as a deprecated name:
old code builds, with a warning and an Xcode fix-it that names the replacement.

## 1. Removed (fix before bumping)

| Removed | Use |
|---|---|
| `AppIconSize.avatar` | `AppIconSize.xxl` (40) |
| `AppIconSize.xxl` **as 44** / `AppIconSize.xxxl` (48) | `AppIconSize.Tile.sm` / `AppIconSize.Tile.md`. `xxl` still exists but is 40 pt now |
| `AppIconSize.categoryIcon`, `.mega`, `.budgetRing`, `.ultra` | `AppIconSize.Tile.lg`, `.xl`, `.xxl`, `.xxxl` |
| `BrandLogoView(brandName:size:)` | `Icon(source: .brandService(name), style: .roundedSquare(size:))` |

A search for `AppIconSize.xxl` before bumping shows whether code still means 44 by it (it was
deprecated, renamed `Tile.sm`, in 1.13.0). Neither app uses it.

## 2. Renamed (deprecated, still builds)

Components are named for what they are, without `View` or `App` (owner's decision, 2026-10). The
tokens keep their prefix (`AppColors`, `AppSpacing`, `AppRadius`, `AppIconSize`,
`AppTypography`, `AppAnimation`): a token namespace is not a view, and the plain names clash with
SwiftUI.

| Before 2.0 | 2.0 |
|---|---|
| `SectionHeaderView`, `SectionHeaderViewSkeleton` | `SectionHeader`, `SectionHeaderSkeleton` |
| `EmptyStateView` | `EmptyState` |
| `EmptyCardView` | `EmptyCard` |
| `AvatarView`, `AvatarViewSkeleton` | `Avatar`, `AvatarSkeleton` |
| `BadgeView`, `BadgeViewSkeleton` | `Badge`, `BadgeSkeleton` |
| `RatingView`, `RatingViewSkeleton` | `Rating`, `RatingSkeleton` |
| `SegmentedPickerView` | `SegmentedPicker` |
| `SkeletonView` | `Skeleton` |
| `IconView`, `IconViewSkeleton` | `Icon`, `IconSkeleton` |
| `PackedCircleIconsView`, `PackedCircleIconsViewSkeleton` | `PackedCircleIcons`, `PackedCircleIconsSkeleton` |
| `DateButtonsView` | `DateButtons` |
| `SiriGlowView` | `SiriGlow` |
| `SiriWaveRecordingView` | `SiriWave` |
| `ConvertedAmountView` | `ConvertedAmount` |
| `AmountPercentageView` | `AmountPercentage` |
| `NotificationPermissionView` | `NotificationPermissionPrompt` |
| `AppIconSize.Tile.xs` | `AppIconSize.xxl` (40 pt is a glyph: a tile starts at `Tile.sm`, 44) |
| `AppButtonAppearance`, `AppButtonRole`, `AppButtonSize` | `DSButtonAppearance`, `DSButtonRole`, `DSButtonSize` (also `DSButton.Appearance`, …) |
| `.appButton(_:role:size:disabled:)` | `.dsButton(_:role:size:disabled:)` |

Mechanically (the inits are the same):

```sh
sed -i '' -E \
  -e 's/\bSectionHeaderView(Skeleton)?\b/SectionHeader\1/g' \
  -e 's/\bEmptyStateView\b/EmptyState/g' -e 's/\bEmptyCardView\b/EmptyCard/g' \
  -e 's/\bAvatarView(Skeleton)?\b/Avatar\1/g' -e 's/\bBadgeView(Skeleton)?\b/Badge\1/g' \
  -e 's/\bRatingView(Skeleton)?\b/Rating\1/g' -e 's/\bSegmentedPickerView\b/SegmentedPicker/g' \
  -e 's/\bSkeletonView\b/Skeleton/g' -e 's/\bIconView(Skeleton)?\b/Icon\1/g' \
  -e 's/\bPackedCircleIconsView(Skeleton)?\b/PackedCircleIcons\1/g' \
  -e 's/\bDateButtonsView\b/DateButtons/g' -e 's/\bSiriGlowView\b/SiriGlow/g' \
  -e 's/\bSiriWaveRecordingView\b/SiriWave/g' -e 's/\bConvertedAmountView\b/ConvertedAmount/g' \
  -e 's/\bAmountPercentageView\b/AmountPercentage/g' \
  -e 's/\bNotificationPermissionView\b/NotificationPermissionPrompt/g' \
  -e 's/AppIconSize\.Tile\.xs\b/AppIconSize.xxl/g' \
  -e 's/\bAppButton(Appearance|Role|Size)\b/DSButton\1/g' -e 's/\.appButton\(/.dsButton(/g' \
  $(git ls-files '*.swift')
```

Check an app's own types first: a type of its own named `Icon`, `Badge`, `Avatar`, `Rating` or
`Skeleton` would make the short name ambiguous (Tenra and Dalada have none).

## 3. Replaced by a parameter (deprecated, still builds)

### Buttons → `DSButton`

| Before 2.0 | 2.0 |
|---|---|
| `Button { } label: { Text("Save").frame(maxWidth: .infinity) }.primaryButton()` | `DSButton("Save", fullWidth: true) { }` |
| `.primaryButton(disabled: d)` on a hand-built label | `.dsButton(disabled: d)` |
| `.secondaryButton()` | `.dsButton(.secondary)` / `DSButton(…, appearance: .secondary)` |
| `Button { } label: { LoadingButtonLabel("Save", systemImage: "checkmark", isLoading: s) }.primaryButton(disabled: s)` | `DSButton("Save", systemImage: "checkmark", isLoading: s) { }` |
| `BulkDeleteButton(count: n) { }` | `DSButton(String(format: String(localized: "bulk.deleteCount"), n), role: .destructive, shape: .capsule, fullWidth: true) { }` `.font(AppTypography.bodyEmphasis)` `.screenPadding().padding(.bottom, AppSpacing.lg)` |
| `EntityActionButton(title:systemImage:role:action:)` | `DSButton(title, systemImage:, iconPlacement: .top, role: .destructive or .normal) { }` |

`EntityActionButton` → `DSButton(iconPlacement: .top)` draws the same pixels. `BulkDeleteButton`
padded its title 4 pt above and below inside the capsule, so it was 8 pt taller; `DSButton` uses
the control's own height.

### Section headers → `SectionHeader` styles

| Before 2.0 | 2.0 |
|---|---|
| `SettingsSectionHeaderView(title: t)` | `SectionHeader(t, style: .list)` |
| `DateSectionHeaderView(dateKey: d)` | `SectionHeader(d, style: .card)` |
| `DateSectionHeaderView(dateKey: d, amount: a, currency: c)` | `SectionHeader(d, style: .card) { if a > 0 { FormattedAmountText(amount: a, currency: c, prefix: "-", fontSize: AppTypography.bodySmall, fontWeight: .semibold, color: AppColors.Text.tertiary) } }` |
| `DateSectionHeaderViewSkeleton()` | `SectionHeaderSkeleton(style: .card, showsTrailing: true)` |

### Amounts

| Before 2.0 | 2.0 |
|---|---|
| `FormattedAmountView(amount:currency:prefix:color:)` | `FormattedAmountText(amount:currency:prefix:color:)`: the same view, its defaults are `body` and `.semibold` |

### Sheets → `PromptSheet`

| Before 2.0 | 2.0 |
|---|---|
| `PermissionPrimerView(systemImage:title:message:allowTitle:laterTitle:onAllow:onLater:)` | `PromptSheet(systemImage:title:message:primaryTitle:secondaryTitle:detent: nil, dismissesOnAnswer: false, onPrimary:onSecondary:)` |
| `PromptSheet(…, height: h, onPrimary:onSecondary:)` | `PromptSheet(…, onPrimary:onSecondary:)` (`.medium`), or `detent: .height(h)` |

## 4. Visual changes

Every consumer sees these on its next bump; the re-recorded snapshot PNGs in the release PR
show each one.

- **`PromptSheet`** (Tenra's rating survey): a 104 pt symbol disc instead of a 44 pt symbol,
  `h2` title and `body` message (were `h3` / `bodySmall`), `DSButton`s, a `.medium` sheet
  instead of 340 pt. Permission primers (`PermissionPrimerView`, `NotificationPermissionPrompt`):
  `h2` title and `body` message.
- **`SegmentedPicker`**: the system control without the interactive glass layer over it, which
  took the touch (a quick tap did not move the selection).
- **`AvatarGroup`**: an opaque disc under each avatar's pale initials; the avatar behind no
  longer shows through.
- **`PackedCircleIcons`**: a symbol sits on a pale disc of its tint (was grey).
- **`HeroBarPair`**: the tapped bar's amount is in an opaque `Tooltip` with a tail, right above
  the bar (was a pale capsule 30 pt above it, through which the content behind showed).

## 5. New

- `DSButton` and `.dsButton` (docs/design-system.md §2 "Buttons", §3 "DSButton").
- `Tooltip` and `.tooltipAnchor(_:gap:)` (§3 "Tooltip").
- `SectionHeader` styles `.list` and `.card`; `SectionHeaderSkeleton` for both.
- `PromptSheet`'s async `onPrimary`, `detent` and `dismissesOnAnswer`.
- `AppIconSize.xxl` (40 pt glyph).

## 6. 2.1.0

| Before 2.1 | 2.1 |
|---|---|
| `BalanceRow(iconSource:title:amount:currency:detail:trailingSystemImage:…)` | `AmountRow(title, leading: .icon(iconSource), value: .amount(amount, color: AppColors.Text.secondary), currency:, style: .list, detail:, accessory: .systemImage(name))` |
| `ProgressRingRow(iconSource:color:title:progress:currency:placeholder:…)` | `AmountRow(title, leading: .tinted(iconSource, color), value: .limit(progress, placeholder:), currency:, style: .list)` |
| `BreakdownRow(iconSource:color:title:subtitle:amount:currency:percentage:showsChevron:)` | `AmountRow(title, subtitle:, subtitleLineLimit: 1, leading: .tinted(iconSource, color), value: .share(amount, percentage:), currency:, accessory: .chevron)` |
| `InsightEntityRow(iconSource:title:subtitle:amount:currency:amountColor:amountCaption:)` | `AmountRow(title, subtitle:, leading: .icon(iconSource), value: .amount(amount, color:, caption:), currency:)` (`.none` for a `nil` icon) |
| `BalanceRowSkeleton(showsDetail:)`, `ProgressRingRowSkeleton()`, `BreakdownRowSkeleton()`, `InsightEntityRowSkeleton()` | `AmountRowSkeleton(style: .list, showsDetail:)`, `(style: .list, showsRing: true)`, `(style: .info)` |
| `BalanceRow.Detail` | `AmountRow.Detail` |
| `CategoryColors.hexColor(for:opacity:)` | `CategoryColors.color(for:opacity:)` |

The old rows are deprecated wrappers that draw the same pixels, with one change: a limit row
without a limit keeps the ring's room around its icon (52 pt), so it lines up with the rows that
have one (its icon and name were 8 pt to the left, the row 8 pt shorter).
