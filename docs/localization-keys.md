# Localization keys used by DesignKit

DesignKit ships no string tables. Components resolve `String(localized:)` (and the
`LocalizedStringKey`s of `EntityStatus`) in the **host app's main bundle**, so every key a
screen uses must exist in the app's `Localizable.strings` / `Localizable.xcstrings` — in every
locale the app ships. A missing key renders as the raw key (e.g. `tab.close`), except where the
component passes a `defaultValue` (shown in the last column).

The keys and their translations come from Tenra's string tables (11 locales) — copy them from
`Tenra/<locale>.lproj/Localizable.strings` when an app starts using a component. When you add
a component that introduces a key, add a row here in the same commit. The `rating.*` keys came
from Dalada (ru / kk / en in `ios/Dalada/Localizable.xcstrings`).

The Gallery is a host app too: `Gallery/Gallery/Localizable.xcstrings` holds the English value
of every key below, so its specimens, its TestFlight build and the snapshot references show
text, not keys. A new key goes there as well.

| Key | Used by | Default value |
|---|---|---|
| `amount.hidden` | FormattedAmountText under `.amountsHidden()` (VoiceOver) | `Hidden amount` |
| `amount.hide` | AmountVisibilityToggle (VoiceOver, amounts shown) | `Hide amounts` |
| `amount.show` | AmountVisibilityToggle (VoiceOver, amounts hidden) | `Show amounts` |
| `bulk.deleteCount` | BulkDeleteButton | — |
| `button.cancel` | EditSheetContainer, ImportProgressSheet | — |
| `button.copy` | AnimatedInputComponents | — |
| `button.paste` | AnimatedInputComponents | — |
| `button.save` | EditSheetContainer | — |
| `calculator.add` | CalculatorKeypad | `Plus` |
| `calculator.backspace` | CalculatorKeypad | `Delete` |
| `calculator.clearHint` | CalculatorKeypad | `Press and hold to clear` |
| `calculator.divide` | CalculatorKeypad | `Divide` |
| `calculator.multiply` | CalculatorKeypad | `Multiply` |
| `calculator.separator` | CalculatorKeypad | `Decimal separator` |
| `calculator.subtract` | CalculatorKeypad | `Minus` |
| `calendar.showMonth` | MonthCalendar (VoiceOver action on the header) | `Show month` |
| `calendar.showWeek` | MonthCalendar (VoiceOver action on the header) | `Show week` |
| `chart.empty.message` | LineChart, BarChart, ChartSwitcher (default `emptyMessage`) | — |
| `chart.empty.title` | LineChart, BarChart, ChartSwitcher (default `emptyTitle`) | — |
| `chart.today` | LineChart, BarChart, ChartSwitcher (default `todayText`) | — |
| `common.cancel` | DateButtonsView | — |
| `common.changeIcon` | EditableHero (VoiceOver on the icon) | `Change icon` |
| `common.color` | ColorPickerRow | — |
| `common.select` | DateButtonsView | — |
| `common.startDate` | DatePickerRow | — |
| `currency.all` | CurrencyList | `All Currencies` |
| `currency.conversion.approximate` | CurrencyAmountInput | `≈` |
| `currency.customizeAction` | CurrencyPickerMenu (with `onCustomize`) | `Customize…` |
| `currency.noResults.description` | CurrencyList (search found nothing) | `Try a different name or code.` |
| `currency.noResults.title` | CurrencyList (search found nothing) | `No currencies found` |
| `currency.popular` | CurrencyList | `Popular` |
| `currency.searchPrompt` | CurrencyList | `Search currency` |
| `currency.title` | EditableHero (the pushed currency list's title) | `Currency` |
| `date.choose` | DateButtonsView | — |
| `date.selectDate` | DateButtonsView | — |
| `date.today` | DateButtonsView | — |
| `date.yesterday` | DateButtonsView | — |
| `iconPicker.brandDomainHint` | IconPicker (logo search) | `Enter brand domain (e.g. netflix.com)` |
| `iconPicker.entertainment` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Entertainment` |
| `iconPicker.foodAndDrinks` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Food & Drinks` |
| `iconPicker.frequentlyUsed` | IconPicker | `Frequently Used` |
| `iconPicker.group.beauty` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Beauty & Care` |
| `iconPicker.group.celebrations` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Gifts & Holidays` |
| `iconPicker.group.educationWork` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Education & Work` |
| `iconPicker.group.family` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Family & People` |
| `iconPicker.group.nature` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Nature & Weather` |
| `iconPicker.group.pets` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Pets` |
| `iconPicker.group.services` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Services & Tools` |
| `iconPicker.group.sports` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Sports` |
| `iconPicker.group.symbols` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Symbols` |
| `iconPicker.group.tech` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Tech & Communication` |
| `iconPicker.group.travel` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Travel` |
| `iconPicker.health` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Health` |
| `iconPicker.homeAndUtilities` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Home & Utilities` |
| `iconPicker.iconsTab` | IconPicker | `Icons` |
| `iconPicker.logosTab` | IconPicker | `Logos` |
| `iconPicker.moneyAndFinance` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Money & Finance` |
| `iconPicker.onlineSearch` | IconPicker (logo search) | `Online` |
| `iconPicker.searchIcons` | IconPicker | `Search icons` |
| `iconPicker.searchOnline` | IconPicker (logos tab) | `Search brand logo...` |
| `iconPicker.shopping` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Shopping` |
| `iconPicker.suggestions` | IconPicker (logo search) | `Suggestions` |
| `iconPicker.title` | IconPicker | `Select Image` |
| `iconPicker.transport` | IconCatalog group title (`IconCatalogGroup.localizedTitle`) | `Transport` |
| `iconStyle.preset.categoryIcon` | IconStyle | — |
| `iconStyle.preset.placeholder` | IconStyle | — |
| `iconStyle.preset.serviceLogo` | IconStyle | — |
| `iconStyle.shape.circle` | IconStyle | — |
| `iconStyle.shape.roundedSquare` | IconStyle | — |
| `iconStyle.shape.square` | IconStyle | — |
| `iconStyle.tint.hierarchical` | IconStyle | — |
| `iconStyle.tint.monochrome` | IconStyle | — |
| `iconStyle.tint.original` | IconStyle | — |
| `iconStyle.tint.palette` | IconStyle | — |
| `insights.chart.bar` | ChartZoomControls | — |
| `insights.chart.line` | ChartZoomControls | — |
| `insights.other` | OrbChart | — |
| `notification.permission.allow` | NotificationPermissionView | — |
| `notification.permission.description` | NotificationPermissionView | — |
| `notification.permission.skip` | NotificationPermissionView | — |
| `notification.permission.title` | NotificationPermissionView | — |
| `onboarding.cta.skip` | OnboardingPageContainer; OnboardingPager (default `skipTitle`) | `Skip` (OnboardingPager) |
| `onboarding.stepIndicator.label` | OnboardingStepIndicator | — |
| `progress.importing` | ImportProgressSheet | — |
| `rating.pick %lld %lld` | RatingPicker (VoiceOver: "4 out of 5") | — |
| `rating.value %@ %lld` | RatingView (VoiceOver: "Rated 4.3 out of 5") | — |
| `skeleton.loading` | `.skeleton(isLoading:)`, `.skeletonLoadingLabel()`, every component skeleton (`…Skeleton`, 1.10.0), `RedactableAmount` while loading, LoadingButtonLabel, `CashFlowCard`'s default `loadingLabel` (VoiceOver) | `Loading` |
| `status.active` | StatusIndicatorBadge | — |
| `status.archived` | StatusIndicatorBadge | — |
| `status.paused` | StatusIndicatorBadge | — |
| `status.pending` | StatusIndicatorBadge | — |
| `steps.position` | StepTracker (VoiceOver: "Step 2 of 4", args `%lld %lld`) | `Step %lld of %lld` |
| `tab.add` | PlusTabLabel | — |
| `tab.close` | PlusTabLabel | — |
| `tags.remove` | TagInput (VoiceOver on a tag's ×, arg `%@`) | `Remove %@` |
| `text.less` | ExpandableText | `Less` |
| `text.more` | ExpandableText | `More` |

Regenerate the table after changing components:

```bash
grep -rhoE 'String\(localized: "[^"]+"' Sources | sort -u
```
