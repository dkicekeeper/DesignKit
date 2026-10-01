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

Обозначения: ✓ есть · **+** добавлено в этом раунде (0.4.0–0.6.0) · ○ системный компонент iOS ·
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
| Ввод тегов (token field) | ✓ | ✓ | — | ✓ | ✓ | ✓ | ✗ пока не нужен ни одному приложению |

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
| Календарь месяца с отметками | — | ✓ | ✓ | — | ✓ | ✓ | ✗ кандидат: из Tenra `SubscriptionCalendarView` |
| Таймлайн (лента событий) | — | — | — | — | — | — | ✗ кандидат: чекины поездки, история |
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
| Запрос разрешения (до системного) | ✓ | — | — | — | — | — | ✓ `NotificationPermissionView` (тексты Tenra) — см. кандидаты |
| Онбординг | ✓ | — | — | — | — | ✓ | ✓ компоненты Tenra (3 шага) — см. кандидаты |

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

## Что добавлено в этом раунде

- **0.4.0** — из Dalada и Tenra: `BadgeView`, `TrendBadge`, `StatTile`, `AvatarView`,
  `RatingView` / `RatingPicker`, `ChipPicker`, `LinearProgressBar(value:)`, `SelectionIndicator(tint:)`.
- **0.5.0** — графики трендов на общей модели `ChartPoint`: `LineChart`, `BarChart`,
  `ChartSwitcher`, `HeroSparkline`, `Sparkline`, `ChartSelectionBanner`.
- **0.6.0** — пробелы по сравнению с крупными системами: `SkeletonView` / `.skeleton`,
  `LoadingButtonLabel`, `StepTracker`, `ToggleSettingsRow`, `AvatarGroup`, `ChipPicker` с
  множественным выбором и иконками, `ExpandableText`, `MessageBanner` с действием.

## Кандидаты на следующие раунды

Каждый — по «правилу двух» (CLAUDE.md): берём, когда нужен обоим приложениям.

1. **Календарь месяца с отметками по дням** — обобщить Tenra `SubscriptionCalendarView`
   (подписки) так, чтобы Dalada показывала в нём поездки и запреты.
2. **Экран запроса разрешения** — общий для `NotificationPermissionView` (Tenra) и
   `NotificationPrimerView` (Dalada): тексты параметрами, кнопки на `primaryButton` /
   `secondaryButton`. **Меняет вид экрана в Tenra — нужно решение.**
3. **Онбординг-пейджер** — общий для вводного экрана Dalada и онбординга Tenra (сейчас 3
   жёстких шага Tenra).
4. **Таймлайн** — лента событий: чекины поездки (Dalada), история изменений (Tenra).
5. **Ввод тегов** — когда появится в одном из приложений.
6. **Роли поверхностей** в `AppColors` — при третьем приложении или переработке тёмной темы.
