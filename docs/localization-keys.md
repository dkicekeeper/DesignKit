# Localization keys used by DesignKit

DesignKit ships no string tables. Components resolve `String(localized:)` (and the
`LocalizedStringKey`s of `EntityStatus`) in the **host app's main bundle**, so every key a
screen uses must exist in the app's `Localizable.strings` / `Localizable.xcstrings` — in every
locale the app ships. A missing key renders as the raw key (e.g. `tab.close`), except where the
component passes a `defaultValue` (shown in the last column).

The keys and their translations come from Tenra's string tables (11 locales) — copy them from
`Tenra/<locale>.lproj/Localizable.strings` when an app starts using a component. When you add
a component that introduces a key, add a row here in the same commit.

| Key | Used by | Default value |
|---|---|---|
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
| `common.cancel` | DateButtonsView | — |
| `common.color` | ColorPickerRow | — |
| `common.select` | DateButtonsView | — |
| `common.startDate` | DatePickerRow | — |
| `date.choose` | DateButtonsView | — |
| `date.selectDate` | DateButtonsView | — |
| `date.today` | DateButtonsView | — |
| `date.yesterday` | DateButtonsView | — |
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
| `onboarding.cta.skip` | OnboardingPageContainer | — |
| `onboarding.stepIndicator.label` | OnboardingStepIndicator | — |
| `progress.importing` | ImportProgressSheet | — |
| `status.active` | StatusIndicatorBadge | — |
| `status.archived` | StatusIndicatorBadge | — |
| `status.paused` | StatusIndicatorBadge | — |
| `status.pending` | StatusIndicatorBadge | — |
| `tab.add` | PlusTabLabel | — |
| `tab.close` | PlusTabLabel | — |

Regenerate the table after changing components:

```bash
grep -rhoE 'String\(localized: "[^"]+"' Sources | sort -u
```
