# Структура DesignKit и Gallery

Как устроены разделы крупных дизайн-систем, и как по этим принципам разложены компоненты
DesignKit: в Gallery, в `docs/design-system.md` и в папках `Sources/DesignComponents/`.
Решение владельца (октябрь 2026): одна раскладка по назначению компонента вместо разделов,
которые росли по мере переноса из приложений.

## Что было не так

- Раздел «Components» — 38 страниц подряд, без порядка: карточки, строки, заголовки и баннеры
  вперемешку.
- Одни и те же виды компонентов в разных разделах: карточки в «Components», «Balances»,
  «Badges & Stats», «Community»; строки в «Components», «Forms», «Balances», «Community»,
  «Patterns»; графики в «Inputs & Charts», «Trend Charts», «Balances».
- Скелетоны — отдельным экраном, а не состоянием своего компонента.
- Параметры компонента не переключаются: на странице один-два готовых примера.
- Заголовок и описание стоят вплотную к компоненту и сливаются с ним.
- В исходниках то же: `FormattedAmountText` и `SelectableBalanceCard` лежат в `Input/`,
  `SiriGlowView` в `Charts/`, `PlusTabLabel` в `Feedback/`, `IconPicker` в `Icons/`.

## Как устроены крупные системы

| Система | Разделы компонентов | Принцип |
|---|---|---|
| Apple HIG | Content · Layout and organization · Menus and actions · Navigation and search · Presentation · Selection and input · Status · System experiences | по назначению: что компонент делает для человека |
| Material 3 | Actions · Communication · Containment · Navigation · Selection · Text inputs | по назначению; карточки, списки, листы — «Containment» |
| Atlassian | Forms and inputs · Images and icons · Labels · Layout and structure · Loading · Messaging · Navigation · Overlays and layering · Primitives · Status indicators · Text and data display | по назначению, мельче; отдельно «Primitives» и «Loading» |
| Ant Design | General · Layout · Navigation · Data Entry · Data Display · Feedback · Other | по назначению; ввод и отображение данных разведены |

Общее у всех:
1. **Основы отдельно от компонентов**: цвета, типографика, отступы, иконки, движение.
2. **Разделы по назначению, а не по форме и не по приложению**: «действия», «ввод», «выбор»,
   «статус», «навигация», «отображение данных». Где компонент живёт в приложении (баланс,
   сообщество), на раздел не влияет.
3. **Один вид компонента — в одном разделе**: все кнопки вместе, все поля ввода вместе.
   Карточки и списки — контейнеры (Material: Containment, Atlassian: Layout and structure).
4. **Раздел — 5–15 компонентов.** Больше — делят (Ant: Data Entry 18 и Data Display 21 —
   самые крупные, и их читать труднее всего).
5. **Страница компонента**: название и одна фраза о назначении → живой пример → параметры
   и состояния (Storybook controls у Atlassian, Polaris, Carbon) → правила использования.
   Скелетон, ошибка, пусто, выключено — **состояния компонента** на его странице. Отдельный
   раздел «Loading» (Atlassian) — только для примитивов: spinner, skeleton, progress bar.

## Новая раскладка

Основы (6): **Colors**, **Typography**, **Spacing & Radius**, **Icon Sizes**, **Surfaces**
(`cardStyle`, `formCardStyle`, `filterChipStyle`, стекло), **Motion** (кривые, длительности,
появление контента, `AmbientMotionGate`).

Компоненты (16 разделов, 4–13 страниц в каждом):

| Раздел | Компоненты | Аналог |
|---|---|---|
| **Actions** | `appButton` (весь набор вида × роли × размера), `.bounce`, `LoadingButtonLabel`, `EntityActionButton`, `BulkDeleteButton`, `ReactionButton`, `AmountVisibilityToggle`, `UniversalFilterButton` | M3 Actions, HIG Menus and actions |
| **Text Input** | `FormTextField`, `AnimatedTitleInput`, `MessageComposer`, `TagInput` | M3 Text inputs |
| **Selection** | `SegmentedPickerView`, `ChipPicker`, `RatingPicker`, `SelectionIndicator`, `DateButtonsView`, `IconPicker` | M3 Selection, HIG Selection and input |
| **Amounts & Currency** | `AmountInput`, `CalculatorKeypad`, `CalculatorAmountDisplay`, `AmountDigitDisplay`, `CurrencyAmountInput`, `CurrencyPickerMenu`, `CurrencyList`, `FormattedAmountText`, `FormattedAmountView`, `ConvertedAmountView`, `SpentBudgetText`, `AmountPercentageView`, `RedactableAmount` | своя область DesignKit (у Polaris — Money) |
| **Rows: Settings & Forms** | `UniversalRow`, `InfoRow`, `NavigationSettingsRow`, `ToggleSettingsRow`, `ActionSettingsRow`, `MenuPickerRow`, `DatePickerRow`, `ColorPickerRow`, `CheckmarkRow`, `DisclosureChevron` | M3 Lists |
| **Rows: Data** | `BalanceRow`, `BreakdownRow`, `ProgressRingRow`, `InsightEntityRow`, `NetAmountRow`, `ScheduleRow`, `PersonRow`, `CommentRow`, `ChecklistRow`, `ChecklistSummaryRow`, `ThumbnailRow` | M3 Lists, Ant Data Display |
| **Cards: Money** | `BalanceCard`, `SelectableBalanceCard`, `FinanceCard`, `CashFlowCard`, `TotalsCard`, `ComparisonCard`, `RecurringPaymentCard`, `CalculationCard`, `WeightBreakdownCard` | M3 Containment |
| **Cards: Progress & Stats** | `LimitProgressCard`, `TargetProgressCard`, `PayoffProgressCard`, `ScoreCard`, `ScoreGaugeCard`, `MetricCard`, `InsightsStatCard`, `StatTile`, `StatsStrip`, `StreakCard`, `ProgressRingTile`, `ProgressRingTileGrid` | Ant Statistic, Data Display |
| **Cards: Content** | `ThreadCard`, `ReviewCard`, `ThumbnailCard`, `RecommendationBox`, `EmptyCardView` | M3 Containment |
| **Charts** | `LineChart`, `BarChart`, `ChartSwitcher`, `HeroSparkline`, `Sparkline`, `OrbChart`, `ChartSelectionBanner`, `ChartZoomControls` | HIG Content (Charts) |
| **Progress & Gauges** | `LinearProgressBar`, `ProgressRing`, `ProportionBar`, `MiniProportionBar`, `HeroProportionBar`, `AmountComparisonBar`, `MiniDonut`, `MiniHalfGauge`, `HeroHalfGauge`, `MiniMilestoneGauge`, `HeroMilestoneGauge`, `MiniBarPair`, `HeroBarPair` | HIG Status (gauges, progress) |
| **Status & Feedback** | `BadgeView`, `TrendBadge`, `StatusIndicatorBadge`, `StatusBanner`, `MessageBanner`, `InlineStatusText`, `EmptyStateView`, `StepTracker`, `ImportProgressSheet`, примитивы скелетонов (`SkeletonView`, `SkeletonText`, `SkeletonRow`) | M3 Communication, Atlassian Messaging + Loading |
| **Headers & Navigation** | `SectionHeaderView`, `SettingsSectionHeaderView`, `DateSectionHeaderView`, `HeroSection`, `UniversalCarousel`, `OnboardingStepIndicator`, `PlusTabLabel` | M3 Navigation, HIG Navigation and search |
| **Media & Identity** | `IconView` (символы, картинки, логотипы брендов), `AvatarView`, `AvatarGroup`, `HeroSymbol`, `PackedCircleIconsView`, `AchievementMedal`, `AchievementTile`, `AchievementProgressRow`, `ThumbnailPlaceholder` | Atlassian Images and icons |
| **Content & Layout** | `ExpandableText`, `ActivityTimeline`, `MonthCalendar`, `FlowLayout`, `FormSection`, `EditSheetContainer`, `EditableHero` | HIG Layout and organization |
| **Sheets & Flows** | `PromptSheet`, `PermissionPrimerView`, `NotificationPermissionView`, `OnboardingPager`, `OnboardingPage`, `LoopOnboardingHero` | HIG Presentation, M3 Containment (sheets) |
| **Effects** | `GradientOrbsBackground`, `SiriGlowView`, `SiriWaveRecordingView`, `.accentGlow`, `.borderBeam` / `.borderGlow` | — (своё: Liquid Glass, Siri) |

Правило для нового компонента: раздел выбирается по тому, **что компонент делает**
(действие, ввод, выбор, показ данных, статус, навигация), а если это строка или карточка — по
виду контейнера (Rows, Cards). Карточки и строки делятся на подразделы, когда их больше 12.

## Страница компонента в Gallery

Сверху вниз, каждый блок отделён:

1. **Шапка**: название, одна фраза о назначении, с какой версии, кто использует (Tenra,
   Dalada). Отделена от примера линией и отступом.
2. **Пример** на холсте (светлая подложка с рамкой): компонент в текущих параметрах.
3. **Параметры**: переключатели, сегменты, ползунки — то, что принимает компонент.
   Первая строка — **состояние**: обычное, загрузка (скелетон компонента), пусто, ошибка,
   выключено — какие есть у компонента.
4. **Как использовать**: пара строк из `design-system.md`, если есть правило.

Экрана «Skeletons» больше нет: скелетон — состояние «Loading» на странице своего компонента.
Снапшот-тесты скелетонов остаются как были.

## Папки исходников

`Sources/DesignComponents/` раскладывается так же, как Gallery: `Actions/`, `TextInput/`,
`Selection/`, `Amounts/`, `Rows/`, `Cards/`, `Charts/`, `Progress/`, `Feedback/`,
`Navigation/`, `Media/`, `Content/`, `Sheets/`, `Effects/`. Модуль один, так что перенос файла
API не меняет.
