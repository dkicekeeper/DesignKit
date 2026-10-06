# DesignKit и крупные дизайн-системы: сравнение (октябрь 2026)

С чем сравнивали: **Apple HIG** (iOS 26), **Material Design 3** (Google), **Fluent 2** (Microsoft,
версия для iOS), **Carbon** (IBM), **Polaris** (Shopify), **Atlassian Design System**. Первые три —
мобильные, последние три — в основном веб, но набор компонентов у всех похож, и пробелы видны
сразу.

## Принцип: что DesignKit делает сам, а что берёт у iOS

DesignKit — дизайн-система поверх SwiftUI, а не замена ему. Системные контролы iOS уже выглядят
как часть платформы (Liquid Glass, Dynamic Type, VoiceOver, RTL), поэтому мы их **не дублируем**,
а используем со своими токенами: `Toggle`, `Picker`, `DatePicker`, `Stepper`, `Slider`, `Menu`,
`.sheet`, `.alert`, `.confirmationDialog`, `TabView`, `NavigationStack`, `.searchable`,
`ShareLink`, `PhotosPicker`, `ProgressView()` (спиннер), подсказки — `TipKit`.

Свой компонент нужен, когда системного нет или когда оба приложения должны выглядеть одинаково
там, где системный вид не подходит (карточки, строки, бейджи, графики, суммы).

Обозначения: ✓ есть · **+** добавлено в этих раундах (0.4.0–0.7.0) · ○ системный компонент iOS ·
— нет · ✗ нет, кандидат.

Таблицы составлены по публичным спискам компонентов систем. Названия и границы компонентов у всех
разные (у Carbon «Tile», у Atlassian «Lozenge», у Fluent «Pill button bar»), поэтому отметка
значит «есть близкий по назначению компонент», а не точное совпадение.

## Компоненты

### Действия

| Компонент | HIG | M3 | Fluent | Carbon | Polaris | Atlassian | DesignKit |
|---|---|---|---|---|---|---|---|
| Кнопка (основная / второстепенная) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `primaryButton()`, `secondaryButton()` |
| Кнопка в состоянии загрузки | — | — | — | ✓ | ✓ | ✓ | **+** `LoadingButtonLabel` |
| Иконка-кнопка / FAB | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `EntityActionButton`, `PlusTabLabel` |
| Сегменты / группа кнопок | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `SegmentedPickerView` |
| Меню, кнопка с меню | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ○ `Menu`; ✓ `UniversalFilterButton` |

### Ввод

| Компонент | HIG | M3 | Fluent | Carbon | Polaris | Atlassian | DesignKit |
|---|---|---|---|---|---|---|---|
| Текстовое поле, многострочное | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `FormTextField` (`.multiline`) |
| Поиск | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ○ `.searchable` |
| Чекбокс / радио | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `SelectionIndicator` (+ `tint`) |
| Строка с переключателем | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **+** `ToggleSettingsRow` |
| Чипсы: выбор одного | — | ✓ | ✓ | ✓ | ✓ | ✓ | **+** `ChipPicker` |
| Чипсы: фильтр из нескольких | — | ✓ | ✓ | ✓ | ✓ | ✓ | **+** `ChipPicker(selection: Set)` |
| Дата / время | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `DatePickerRow`, `DateButtonsView` |
| Слайдер, степпер | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ○ `Slider`, `Stepper` |
| Рейтинг | ✓ | — | — | — | — | — | **+** `RatingView`, `RatingPicker` |
| Цвет | ✓ | — | — | — | — | — | ✓ `ColorPickerRow` |
| Файл | ✓ | — | — | ✓ | ✓ | — | ✓ `DocumentPicker` |
| Ввод суммы, калькулятор | — | — | — | — | — | — | ✓ `CalculatorKeypad`, `AmountInput` (специфика финансов) |
| Ввод тегов (token field) | ✓ | ✓ | — | ✓ | ✓ | ✓ | **+** `TagInput` (0.7.0), `FlowLayout` для переноса чипсов |

### Отображение

| Компонент | HIG | M3 | Fluent | Carbon | Polaris | Atlassian | DesignKit |
|---|---|---|---|---|---|---|---|
| Аватар | — | — | ✓ | — | ✓ | ✓ | **+** `AvatarView` |
| Группа аватаров | — | — | ✓ | — | — | ✓ | **+** `AvatarGroup`; ✓ `PackedCircleIconsView` (облако) |
| Бейдж / тег / лозенж | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **+** `BadgeView`, `TrendBadge`; ✓ `StatusIndicatorBadge` |
| Карточка | — | ✓ | ✓ | ✓ | ✓ | — | ✓ `cardStyle()`, `FinanceCard`, `InsightsStatCard` |
| Показатель (KPI) | — | — | — | — | — | — | **+** `StatTile` (паттерн дашбордов; нужен Dalada) |
| Строка списка | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `UniversalRow`, `InfoRow`, строки настроек |
| Заголовок секции | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `SectionHeaderView`, `DateSectionHeaderView` |
| «Показать ещё» для текста | — | — | — | — | — | — | **+** `ExpandableText` (паттерн App Store; отзывы и статьи Dalada) |
| Раскрывающийся блок | ✓ | ✓ | — | ✓ | ✓ | ✓ | ○ `DisclosureGroup` |
| Пустое состояние / ошибка | — | — | — | ✓ | ✓ | ✓ | ✓ `EmptyStateView` (`.error` с «Повторить») |
| Карусель | — | ✓ | — | — | — | — | ✓ `UniversalCarousel` |
| Графики | ✓ | — | — | ✓ | ✓ | — | ✓ `OrbChart`, датчики; **+** `LineChart`, `BarChart`, `ChartSwitcher`, `Sparkline`, `HeroSparkline` |
| Календарь месяца с отметками | — | ✓ | ✓ | — | ✓ | ✓ | **+** `MonthCalendar` (0.7.0, из Tenra `SubscriptionCalendarView`) |
| Таймлайн (лента событий) | — | — | — | — | — | — | **+** `ActivityTimeline` (0.7.0) |
| Таблица данных | — | — | — | ✓ | ✓ | ✓ | — на телефоне это список |

### Обратная связь и загрузка

| Компонент | HIG | M3 | Fluent | Carbon | Polaris | Atlassian | DesignKit |
|---|---|---|---|---|---|---|---|
| Тост / снэкбар | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `MessageBanner` |
| Снэкбар с действием («Отменить») | — | ✓ | ✓ | ✓ | ✓ | ✓ | **+** `MessageBanner(actionTitle:action:)` |
| Сообщение в потоке / баннер | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `InlineStatusText`, `RecommendationBox` |
| Полоса и кольцо прогресса | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `LinearProgressBar` (**+** `value:`), `ProgressRing` |
| Спиннер | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ○ `ProgressView()` |
| Скелетон (заглушка загрузки) | — | — | ✓ | ✓ | ✓ | ✓ | **+** `SkeletonView`, `SkeletonRow`, `.skeleton(isLoading:)` |
| Шаги процесса | — | — | — | ✓ | — | ✓ | **+** `StepTracker` |
| Подсказка / тултип / коучмарк | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ○ `TipKit` |
| Диалог, шторка | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ○ системные; ✓ `EditSheetContainer` |
| Запрос разрешения (до системного) | ✓ | — | — | — | — | — | **+** `PermissionPrimerView` (0.7.0, общий для обоих приложений) |
| Онбординг | ✓ | — | — | — | — | ✓ | **+** `OnboardingPager`, `OnboardingPage`, `HeroSymbol` (0.7.0); ✓ шаги Tenra |

### Навигация

Таб-бар, навбар, сайдбар, индикатор страниц, нижняя панель — системные (○). DesignKit добавляет
только `PlusTabLabel` (вкладка-действие «+»). Хлебные крошки и пагинация — веб, на iOS не нужны.

## Токены

| | Крупные системы | DesignKit |
|---|---|---|
| Цвета | Роли: поверхность / контейнер / текст / акцент / статусы (M3: ~30 ролей) | `AppColors`: фоны (`bgBase`, `bgCard`, `bgMuted`), текст (3 уровня), акцент (настраивается, `DesignKitTheme.accent`), статусы (`success`, `warning`, `destructive`), финансовые (`income`, `expense`, `transfer`, `planned`), палитра категорий |
| Типографика | 10–15 стилей, Dynamic Type | `AppTypography`: 10 стилей (h1–h4, body, bodySmall, caption…), Inter, Dynamic Type |
| Отступы | 4/8-pt сетка | `AppSpacing`, 4-pt сетка |
| Скругления | 4–6 ступеней | `AppRadius` |
| Анимация | Токены длительности и кривых (M3 motion, Fluent motion) | `AppAnimation`, уважение Reduce Motion, `AmbientMotionGate` |
| Глубина | Тени / elevation | Liquid Glass (`glassEffect`) вместо теней |

Токены по составу на уровне крупных систем. Отличие — цветовые роли «контейнеров» (M3
`surfaceContainer…`) у нас сведены к трём фонам. Для двух приложений этого хватает, а с третьим
приложением или тёмной темой с несколькими уровнями поверхностей стоит добавить роли.

## Что добавлено в этих раундах

- **0.4.0** — из Dalada и Tenra: `BadgeView`, `TrendBadge`, `StatTile`, `AvatarView`,
  `RatingView` / `RatingPicker`, `ChipPicker`, `LinearProgressBar(value:)`, `SelectionIndicator(tint:)`.
- **0.5.0** — графики трендов на общей модели `ChartPoint`: `LineChart`, `BarChart`,
  `ChartSwitcher`, `HeroSparkline`, `Sparkline`, `ChartSelectionBanner`.
- **0.6.0** — пробелы по сравнению с крупными системами: `SkeletonView` / `.skeleton`,
  `LoadingButtonLabel`, `StepTracker`, `ToggleSettingsRow`, `AvatarGroup`, `ChipPicker` с
  множественным выбором и иконками, `ExpandableText`, `MessageBanner` с действием.
- **0.7.0** — кандидаты прошлого раунда: `PermissionPrimerView` (общий экран запроса
  разрешения, меняет вид экрана в Tenra), `OnboardingPager` / `OnboardingPage` / `HeroSymbol`,
  `MonthCalendar` / `CalendarRange` (из Tenra), `ActivityTimeline`, `TagInput`, `FlowLayout`;
  `OnboardingStepIndicator(symbols:)`; стабильные цвета категорий (`CategoryColors.paletteIndex`).
- **1.0.0** — первая мажорная версия: удалены устаревшие API, которые не использует ни одно
  приложение (`BudgetProgressBar`, `BudgetProgressCircle`, `ExpenseIncomeProgressBar`,
  `DonutChart`, `ChartDisplayMode`, `inlineFieldStyle`, `inlineNoteStyle`). Снапшот-тесты
  покрывают внешний вид компонентов (docs/snapshots.md).
- **1.1.0** — первая партия переноса из Tenra (компоненты, которые нужны только Tenra, с нейтральными
  именами): `TotalsCard`, `LimitProgressCard`, `WeightBreakdownCard`, `CalculationCard`,
  `NetAmountRow`, `ScheduleRow`. Модели Tenra в них не попали: Tenra передаёт данные через
  переходники.
- **1.2.0** — вторая партия: `ComparisonCard`, `CashFlowCard`, `ScoreGaugeCard`, `ScoreCard`,
  `TargetProgressCard`, `RecurringPaymentCard`, `PayoffProgressCard`, `BreakdownRow`,
  `AmountPercentageView`. В Tenra остались переходники со старыми именами.
- **1.3.0** — крупный шрифт (AX1–AX5): `ComparisonCard`, `TotalsCard`, `InsightEntityRow`,
  `BreakdownRow` и `MenuPickerRow` раскладываются в столбик вместо обрезки и переносов посреди
  слова. На обычных размерах вид прежний.
- **1.4.0** — единое правило отступов (design-system.md §10): `ScheduleRow` и `NetAmountRow`
  получили вертикальный отступ пресета строк `.info` (8), как остальные строки.
- **1.5.0** — третья партия: `BalanceCard`, `SelectableBalanceCard`, `BalanceRow`,
  `ProgressRingRow`, `ProgressRingTile` (с `LimitProgress`), `MetricCard`,
  `GradientOrbsBackground`, `PromptSheet`. В Tenra остались переходники со старыми именами.
- **1.5.1** — крупный шрифт в новых строках: в `BalanceRow` сумма начисления встаёт под подпись,
  в `ProgressRingRow` «потрачено», «/ лимит» и доля идут тремя строками вместо «185… / 250…».
- **1.6.0** — семантические цвета v2: группы `AppColors.Text`, `.Background` (уровни `base` /
  `elevation1–3`, нейтральные контейнеры, заливки), `.Status` (со светлыми `…Pale`), `.Border`;
  модификаторы `OnDark` / `OnLight` (одинаковы в обеих темах); `AppColors.pale(_:)`. Старые плоские
  имена — псевдонимы, цвета не изменились.
- **1.7.0** — суммы: скрытие (`.amountsHidden()`, «•••• ₸» во всех `FormattedAmountText`, кнопка
  `AmountVisibilityToggle`), знак `sign: .always` с настоящим минусом «−», валюта кодом, символом
  SF или без неё (`currencyDisplay`); `StatusBanner` (уведомление, которое остаётся на экране, по
  устройству как `RecommendationBox`); `SkeletonText` (заглушка строки по стилю текста);
  `appButton(вид, роль, размер)` поверх системных стилей Liquid Glass; `.fadeTruncation()`.

Для 1.6.0–1.7.0 смотрели и на дизайн-систему TUI Т-Банка (Figma): как референс устройства токенов
и списка состояний, а не как образец внешнего вида. Вид остаётся своим: Liquid Glass, Inter,
системные цвета iOS.

## Кандидаты на следующие раунды

С октября 2026 правило «двух потребителей» отменено (решение владельца): в DesignKit идёт любой
компонент, который можно сделать общим, с нейтральным именем и API, даже если он нужен одному
приложению. Кандидаты 1–5 прошлого раунда (календарь, запрос разрешения, онбординг, таймлайн,
теги) вошли в 0.7.0.

1. ~~**Роли поверхностей** в `AppColors`~~ — сделано в 1.6.0 (`AppColors.Background`: `base`,
   `baseAlt`, `elevation1–3`, `neutral1–2`, `fill`). Компоненты переходят на них постепенно.
2. **Поиск с подсказками** (недавние запросы, подсказки под `.searchable`) — если оба приложения
   придут к одинаковому виду.
