# Moving to DesignKit 3.0

3.0.0 (2026-10) is a major release for two reasons:
- **Removed names:** it removes every name that 2.x deprecated.
- **Colours in cards:** it changes how a card's content meets its glass.

Neither Tenra nor Dalada used a removed name when it shipped, so both moved to 3.0 by changing
the pin. The visual change shows in every card.

## Visual changes

| What | Before | 3.0.0 |
|---|---|---|
| `cardStyle()` | `.glassEffect` applied to the card's content: the glass blended each layer of the content into the layers under it (darker in light mode, lighter in dark). A marker over an arc looked translucent, a label over its pale capsule changed colour, overlapping shapes shifted. | The glass is drawn behind the content (`.background { Color.clear.glassEffect(…) }`). The card itself (its background, edge, corners) is the same; the content inside keeps its exact colours, as it looks outside a card. |
| `TransactionRow` at accessibility text sizes | The amounts sat beside the text and took so much width that the title broke mid-word ("Groceri / es"). | The amounts go under the text, leading, as `AmountRow` and the other rows have done since 1.3.0. |

Snapshots: every card whose content overlaps (rings, capsules, charts, marbles, gauges) is
re-recorded in the 3.0.0 PR; the PNG diffs show the colour shift.

## New (additive)

- **`StepperRow(icon:title:value:in:step:format:)`:** a whole number in a form, for Dalada's
  forms.
- **`EditSheetContainer(isSaving:)`:** a spinner stands in for Save, and Cancel is disabled
  while the save runs.
- **`ToggleSettingsRow` and `ActionSettingsRow` without an icon:** `icon` defaults to `nil`,
  for a row in a form that carries no symbol.

## Removed names and their replacements

**2.0 renames** (the `…View` names): use the name without `View`.

| Removed | Use |
|---|---|
| `AvatarView`, `AvatarViewSkeleton` | `Avatar`, `AvatarSkeleton` |
| `BadgeView`, `BadgeViewSkeleton` | `Badge`, `BadgeSkeleton` |
| `ConvertedAmountView`, `AmountPercentageView` | `ConvertedAmount`, `AmountPercentage` |
| `DateButtonsView`, `SegmentedPickerView` | `DateButtons`, `SegmentedPicker` |
| `EmptyCardView`, `EmptyStateView` | `EmptyCard`, `EmptyState` |
| `IconView`, `IconViewSkeleton` | `Icon`, `IconSkeleton` |
| `NotificationPermissionView` | `NotificationPermissionPrompt` |
| `PackedCircleIconsView`, `PackedCircleIconsViewSkeleton` | `PackedCircleIcons`, `PackedCircleIconsSkeleton` |
| `RatingView`, `RatingViewSkeleton` | `Rating`, `RatingSkeleton` |
| `SectionHeaderView`, `SectionHeaderViewSkeleton` | `SectionHeader`, `SectionHeaderSkeleton` |
| `SkeletonView` | `Skeleton` |

**Components merged or replaced:**

| Removed | Use |
|---|---|
| `BalanceRow`, `BalanceRowSkeleton` | `AmountRow(title, leading: .icon(source), value: .amount(amount, color: AppColors.Text.secondary), currency:, style: .list, detail:, accessory: .systemImage(name))`, `AmountRowSkeleton(style: .list, showsDetail:)` |
| `ProgressRingRow`, `ProgressRingRowSkeleton` | `AmountRow(title, leading: .tinted(source, color), value: .limit(progress, placeholder:), currency:, style: .list)`, `AmountRowSkeleton(style: .list, showsRing: true)` |
| `BreakdownRow`, `BreakdownRowSkeleton` | `AmountRow(title, subtitle:, subtitleLineLimit: 1, leading: .tinted(source, color), value: .share(amount, percentage:), currency:, accessory: .chevron)`, `AmountRowSkeleton(style: .info)` |
| `InsightEntityRow`, `InsightEntityRowSkeleton` | `AmountRow(title, subtitle:, leading: .icon(source), value: .amount(amount, color:, caption:), currency:)`, `AmountRowSkeleton(style: .info)` |
| `SettingsSectionHeaderView` | `SectionHeader(title, style: .list)` |
| `DateSectionHeaderView`, `DateSectionHeaderViewSkeleton` | `SectionHeader(label, style: .card) { the day's total }`, `SectionHeaderSkeleton(style: .card, showsTrailing:)` |
| `FormattedAmountView` | `FormattedAmountText(amount:currency:prefix:color:)` (its defaults are body, semibold) |
| `LoadingButtonLabel` | `DSButton(title, systemImage:, isLoading:, fullWidth:)` |
| `BulkDeleteButton` | `DSButton(title, role: .destructive, shape: .capsule, fullWidth: true)` |
| `EntityActionButton` | `DSButton(title, systemImage:, iconPlacement: .top, role:)` |
| `PermissionPrimerView` | `PromptSheet(systemImage:title:message:primaryTitle:secondaryTitle:detent: nil, dismissesOnAnswer: false, onPrimary:onSecondary:)` |
| `PromptSheet(…, height:, …)` | `PromptSheet(…, detent:, dismissesOnAnswer:, …)`; `.medium` by default |
| `GradientOrbsBackground(_:)` | `AuroraBackground(_ spots:)`; `Orb(color:weight:)` becomes `AuroraBackground.Spot(color:weight:)` |
| `SiriGlow`, `SiriWave`, `SiriGlowView`, `SiriWaveRecordingView` | `EdgeGlow(level:)` |

**Tokens and styles:**

| Removed | Use |
|---|---|
| `.appButton(_:role:size:disabled:)` | `.dsButton(_:role:size:disabled:)` |
| `.primaryButton(disabled:)` | `.dsButton(disabled:)`, or `DSButton` |
| `.secondaryButton()` | `.dsButton(.secondary)`, or `DSButton(appearance: .secondary)` |
| `AppButtonAppearance`, `AppButtonRole`, `AppButtonSize` | `DSButtonAppearance`, `DSButtonRole`, `DSButtonSize` |
| `AppIconSize.Tile.xs` (40) | `AppIconSize.xxl` |
| `CategoryColors.hexColor(for:opacity:)` | `CategoryColors.color(for:opacity:)` |

## Checking an app

Search the app for the removed names (the left columns above). If nothing matches, the move is
the pin. The Gallery dropped the `GradientOrbsBackground` page and its snapshot.
